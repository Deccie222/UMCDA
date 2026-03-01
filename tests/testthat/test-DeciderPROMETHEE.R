# Test suite for DeciderPROMETHEE class

# Setup test data
alt <- c("A1", "A2", "A3")
crit <- c("Cost", "Quality")
perf <- matrix(
  c(100, 200, 150,   # Cost
    8,   9,   7),     # Quality
  nrow = 3, ncol = 2, byrow = FALSE
)
rownames(perf) <- alt
colnames(perf) <- crit
weight <- c(0.6, 0.4)
direction <- c("min", "max")  # Minimize cost, maximize quality

test_that("DeciderPROMETHEE can be instantiated", {
  decider <- DeciderPROMETHEE$new()
  expect_s3_class(decider, "DeciderPROMETHEE")
  expect_s3_class(decider, "Decider")
  expect_type(decider$state, "list")
})

test_that("DeciderPROMETHEE solve() returns valid netflow vector", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  netflow <- result$raw_result
  
  # Check return type
  expect_type(netflow, "double")
  expect_equal(length(netflow), task$n_alt())
  
  # Check names
  expect_false(is.null(names(netflow)))
  expect_equal(names(netflow), alt)
  
  # Check values are valid
  expect_false(anyNA(netflow))
  expect_true(all(is.finite(netflow)))
  
  # Netflow can be negative, zero, or positive
  expect_true(all(is.finite(netflow)))
})

test_that("DeciderPROMETHEE handles max criteria correctly", {
  skip_if_not_installed("RMCDA")
  # Skip single criterion tests as RMCDA::apply.PROMETHEE has issues with single criterion
  skip("RMCDA::apply.PROMETHEE cannot handle single criterion (causes 'dims' cannot be of length 0 error)")
  
  perf_max <- matrix(c(8, 9), nrow = 2, ncol = 1)
  rownames(perf_max) <- c("A1", "A2")
  colnames(perf_max) <- "Quality"
  
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("Quality"),
    perf = perf_max,
    weight = 1,
    direction = "max"
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  netflow <- result$raw_result
  
  # A2 should have higher netflow (better quality)
  expect_gt(netflow["A2"], netflow["A1"])
})

test_that("DeciderPROMETHEE handles min criteria correctly", {
  skip_if_not_installed("RMCDA")
  # Skip single criterion tests as RMCDA::apply.PROMETHEE has issues with single criterion
  skip("RMCDA::apply.PROMETHEE cannot handle single criterion (causes 'dims' cannot be of length 0 error)")
  
  perf_min <- matrix(c(100, 200), nrow = 2, ncol = 1)
  rownames(perf_min) <- c("A1", "A2")
  colnames(perf_min) <- "Cost"
  
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("Cost"),
    perf = perf_min,
    weight = 1,
    direction = "min"
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  netflow <- result$raw_result
  
  # A1 should have higher netflow (lower cost is better)
  expect_gt(netflow["A1"], netflow["A2"])
})

test_that("DeciderPROMETHEE handles mixed max/min criteria", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  netflow <- result$raw_result
  
  # Should return valid netflow for all alternatives
  expect_equal(length(netflow), 3)
  expect_equal(names(netflow), alt)
  expect_true(all(is.finite(netflow)))
})

test_that("DeciderPROMETHEE state contains task and algorithm_name for ranking/choice", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  
  state <- decider$state
  expect_type(state, "list")
  
  # For ranking/choice, state contains task and algorithm_name (added by Decider$solve())
  # but not leaving.flow or entering.flow (not stored anymore)
  expect_true("task" %in% names(state))
  expect_true("algorithm_name" %in% names(state))
  expect_equal(state$algorithm_name, "promethee")
  expect_false("leaving.flow" %in% names(state))
  expect_false("entering.flow" %in% names(state))
})

test_that("DeciderPROMETHEE stores prof_flow in state for sorting", {
  # Create sorting task
  # For 2 categories (Low, High), we need 1 profile (p1)
  prof <- matrix(c(120, 7.5), nrow = 1, ncol = 2, byrow = TRUE)
  rownames(prof) <- c("p1")
  colnames(prof) <- crit
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    cat_names = c("Low", "High"),
    prof = prof,
    assign_rule = "pessimistic"
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  
  state <- decider$state
  expect_type(state, "list")
  
  # For sorting, state should contain prof_flow
  expect_true("prof_flow" %in% names(state))
  expect_type(state$prof_flow, "double")
  expect_true(length(state$prof_flow) > 0)
})


test_that("DeciderPROMETHEE rejects constant criteria", {
  # Criteria with same values for all alternatives (zero variance)
  perf_constant <- matrix(
    c(100, 100, 100,  # Constant cost (zero variance)
      8,   9,   7),    # Varying quality
    nrow = 3, ncol = 2, byrow = FALSE
  )
  rownames(perf_constant) <- alt
  colnames(perf_constant) <- crit
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf_constant,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  # Constant criteria are detected by check_constant_criteria() before calling RMCDA
  # This prevents RMCDA from removing criteria and causing flow length mismatch
  expect_error(
    decider$solve(task),
    "constant across all alternatives"
  )
})

test_that("DeciderPROMETHEE rejects identical alternatives (all rows same)", {
  # All alternatives have same performance (all rows are identical)
  # Create a matrix where all rows are the same: [100, 8]
  perf_identical <- matrix(
    c(100, 8, 100, 8, 100, 8),
    nrow = 3, ncol = 2, byrow = TRUE
  )
  rownames(perf_identical) <- alt
  colnames(perf_identical) <- crit
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf_identical,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  # Identical alternatives are detected by check_duplicated_alternatives()
  # This prevents RMCDA from merging identical rows and causing flow length mismatch
  expect_error(
    decider$solve(task),
    "identical performance values|duplicated alternatives"
  )
})

test_that("DeciderPROMETHEE solve() returns ResultRanking", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultRanking")
  expect_s3_class(result, "TaskResult")
  expect_equal(result$task_type, "ranking")
  expect_equal(length(result$raw_result), task$n_alt())
})

test_that("DeciderPROMETHEE solve() preserves metadata", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  
  # Metadata should exist
  expect_type(result$metadata, "list")
  expect_true("algorithm_name" %in% names(result$metadata))
  expect_equal(result$metadata$algorithm_name, "promethee")
})

test_that("DeciderPROMETHEE handles single alternative", {
  # Skip this test - TaskDecision requires at least 2 alternatives
  skip("TaskDecision requires at least 2 alternatives")
  
  perf_single <- matrix(c(100, 8), nrow = 1, ncol = 2)
  rownames(perf_single) <- "A1"
  colnames(perf_single) <- crit
  
  task <- TaskRanking$new(
    alt = "A1",
    crit = crit,
    perf = perf_single,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  netflow <- result$raw_result
  expect_equal(length(netflow), 1)
  expect_equal(names(netflow), "A1")
  expect_true(is.finite(netflow))
})

test_that("DeciderPROMETHEE handles single criterion", {
  skip_if_not_installed("RMCDA")
  # Skip single criterion tests as RMCDA::apply.PROMETHEE has issues with single criterion
  skip("RMCDA::apply.PROMETHEE cannot handle single criterion (causes 'dims' cannot be of length 0 error)")
  
  perf_single_crit <- matrix(c(100, 200, 150), nrow = 3, ncol = 1)
  rownames(perf_single_crit) <- alt
  colnames(perf_single_crit) <- "Cost"
  
  task <- TaskRanking$new(
    alt = alt,
    crit = "Cost",
    perf = perf_single_crit,
    weight = 1,
    direction = "min"
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  netflow <- result$raw_result
  expect_equal(length(netflow), 3)
  expect_equal(names(netflow), alt)
  
  # With single min criterion, lowest cost should have highest netflow
  expect_equal(unname(which.max(netflow)), which.min(c(100, 200, 150)))
})

test_that("DeciderPROMETHEE works with TaskRanking (rownames/colnames set automatically)", {
  # Note: TaskRanking automatically sets rownames/colnames from alt/crit
  # DeciderPROMETHEE assumes TaskDecision has already set these
  # So even if input matrix has empty names, TaskRanking will set them
  perf_no_names <- matrix(
    c(100, 200, 150,
      8,   9,   7),
    nrow = 3, ncol = 2, byrow = FALSE
  )
  # No rownames/colnames set initially
  # TaskRanking will set them automatically
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf_no_names,
    weight = weight,
    direction = direction
  )
  
  decider <- DeciderPROMETHEE$new()
  
  # Should work because TaskRanking sets rownames/colnames
  result <- decider$solve(task)
  expect_s3_class(result, "ResultRanking")
  expect_equal(length(result$raw_result), length(alt))
  expect_equal(names(result$raw_result), alt)
})

test_that("DeciderPROMETHEE rejects partially duplicated alternatives", {
  # Create performance matrix with some duplicate rows (A1 and A2 are identical)
  perf_dup <- matrix(
    c(100, 100, 150,  # A1 and A2 are identical
      8,   8,   7),    # Same values
    nrow = 3, ncol = 2, byrow = FALSE
  )
  rownames(perf_dup) <- alt
  colnames(perf_dup) <- crit
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf_dup,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  # Partially duplicated alternatives are detected by check_duplicated_alternatives()
  # Uses data.frame to check content, not just rownames
  # This prevents RMCDA from merging identical rows and causing flow length mismatch
  expect_error(
    decider$solve(task),
    "duplicated alternatives"
  )
})

test_that("DeciderPROMETHEE can solve choice task", {
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultChoice")
  expect_equal(length(result$raw_result), task$n_alt())
})


test_that("DeciderPROMETHEE can solve sorting task", {
  # For 2 categories (Low, High), we need 1 profile (p1)
  prof <- matrix(c(120, 7.5), nrow = 1, ncol = 2, byrow = TRUE)
  rownames(prof) <- c("p1")
  colnames(prof) <- crit
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    cat_names = c("Low", "High"),
    prof = prof,
    assign_rule = "pessimistic"
  )
  decider <- DeciderPROMETHEE$new()
  
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultSorting")
  expect_equal(length(result$raw_result), task$n_alt())
})
