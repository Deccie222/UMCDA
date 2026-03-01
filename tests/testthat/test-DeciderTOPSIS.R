# Test suite for DeciderTOPSIS class

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

test_that("DeciderTOPSIS can be instantiated", {
  decider <- DeciderTOPSIS$new()
  expect_s3_class(decider, "DeciderTOPSIS")
  expect_s3_class(decider, "Decider")
  expect_type(decider$state, "list")
})

test_that("DeciderTOPSIS solve() returns valid score vector", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  score <- result$raw_result
  
  # Check return type
  expect_type(score, "double")
  expect_equal(length(score), task$n_alt())
  
  # Check names
  expect_false(is.null(names(score)))
  expect_equal(names(score), alt)
  
  # Check values are valid
  expect_false(anyNA(score))
  expect_true(all(is.finite(score)))
  
  # TOPSIS score should be in [0, 1]
  expect_true(all(score >= 0))
  expect_true(all(score <= 1))
})

test_that("DeciderTOPSIS handles max criteria correctly", {
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
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  score <- result$raw_result
  
  # A2 should have higher score (better quality)
  expect_gt(score["A2"], score["A1"])
})

test_that("DeciderTOPSIS handles min criteria correctly", {
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
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  score <- result$raw_result
  
  # A1 should have higher score (lower cost is better)
  expect_gt(score["A1"], score["A2"])
})

test_that("DeciderTOPSIS handles mixed max/min criteria", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  score <- result$raw_result
  
  # Should return valid scores for all alternatives
  expect_equal(length(score), 3)
  expect_equal(names(score), alt)
  expect_true(all(score >= 0 & score <= 1))
})

test_that("DeciderTOPSIS state contains task and algorithm_name for ranking/choice", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  
  state <- decider$state
  expect_type(state, "list")
  
  # For ranking/choice, state contains task and algorithm_name (added by Decider$solve())
  # but not other intermediate results
  expect_true("task" %in% names(state))
  expect_true("algorithm_name" %in% names(state))
  expect_equal(state$algorithm_name, "topsis")
})

test_that("DeciderTOPSIS stores prof_flow in state for sorting", {
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
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  
  state <- decider$state
  expect_type(state, "list")
  
  # For sorting, state should contain prof_flow
  expect_true("prof_flow" %in% names(state))
  expect_type(state$prof_flow, "double")
  expect_true(length(state$prof_flow) > 0)
})

test_that("DeciderTOPSIS handles zero-variance criteria", {
  # Criteria with same values for all alternatives
  perf_constant <- matrix(
    c(100, 100, 100,  # Constant cost
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
  decider <- DeciderTOPSIS$new()
  
  # Should not throw error (RMCDA handles this)
  expect_error(result <- decider$solve(task), NA)
  score <- result$raw_result
  expect_equal(length(score), 3)
})

test_that("DeciderTOPSIS handles identical alternatives", {
  # All alternatives have same performance
  perf_identical <- matrix(
    rep(c(100, 8), each = 3),
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
  decider <- DeciderTOPSIS$new()
  
  # Should handle gracefully (all scores equal or very close)
  result <- decider$solve(task)
  score <- result$raw_result
  expect_equal(length(score), 3)
  expect_true(all(is.finite(score)))
})

test_that("DeciderTOPSIS solve() returns ResultRanking", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultRanking")
  expect_s3_class(result, "TaskResult")
  expect_equal(result$task_type, "ranking")
  expect_equal(length(result$raw_result), task$n_alt())
})

test_that("DeciderTOPSIS solve() preserves metadata", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  
  # Metadata should exist
  expect_type(result$metadata, "list")
  expect_true("algorithm_name" %in% names(result$metadata))
  expect_equal(result$metadata$algorithm_name, "topsis")
})

test_that("DeciderTOPSIS handles single alternative", {
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
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  score <- result$raw_result
  expect_equal(length(score), 1)
  expect_equal(names(score), "A1")
  expect_true(is.finite(score))
})

test_that("DeciderTOPSIS handles single criterion", {
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
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  score <- result$raw_result
  expect_equal(length(score), 3)
  expect_equal(names(score), alt)
  
  # With single min criterion, lowest cost should have highest score
  expect_equal(unname(which.max(score)), which.min(c(100, 200, 150)))
})

test_that("DeciderTOPSIS requires rownames and colnames for RMCDA", {
  # Create perf matrix without rownames/colnames
  perf_no_names <- matrix(
    c(100, 200, 150,
      8,   9,   7),
    nrow = 3, ncol = 2, byrow = FALSE
  )
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf_no_names,
    weight = weight,
    direction = direction
  )
  
  decider <- DeciderTOPSIS$new()
  
  # DeciderTOPSIS sets rownames/colnames automatically, so this should work
  # The validation happens after setting rownames/colnames, so empty rownames/colnames
  # in the input are replaced with proper names
  result <- decider$solve(task)
  expect_s3_class(result, "ResultRanking")
})

test_that("DeciderTOPSIS can solve choice task", {
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultChoice")
  expect_equal(length(result$raw_result), task$n_alt())
})

test_that("DeciderTOPSIS can solve sorting task", {
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
  decider <- DeciderTOPSIS$new()
  
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultSorting")
  expect_equal(length(result$raw_result), task$n_alt())
})
