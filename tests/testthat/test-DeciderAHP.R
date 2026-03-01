# Test suite for DeciderAHP class

test_that("DeciderAHP can be instantiated", {
  decider <- DeciderAHP$new()
  expect_s3_class(decider, "DeciderAHP")
  expect_s3_class(decider, "Decider")
})

test_that("DeciderAHP requires pair_crit and pair_alt for ranking", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2")
  
  # Missing pair_crit
  # Create valid AHP matrices: diagonal=1, reciprocal pairs
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_alt = list(m1, m2)
  )
  
  decider <- DeciderAHP$new()
  expect_error(
    decider$solve(task),
    "pair_crit"
  )
  
  # Missing pair_alt
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit
  )
  
  expect_error(
    decider$solve(task),
    "pair_alt"
  )
})

test_that("DeciderAHP requires rownames and colnames for pair_crit and pair_alt", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2")
  
  # pair_crit without rownames/colnames
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit,
    pair_alt = list(m1, m2)
  )
  
  decider <- DeciderAHP$new()
  
  # Should error because RMCDA requires rownames/colnames
  expect_error(
    decider$solve(task),
    "rownames"
  )
})

test_that("DeciderAHP can solve ranking task", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2", "C3")  # Use 3 criteria to avoid CI/RI = NA for 2x2 matrix
  
  # Create 3x3 pair_crit matrix with valid consistency
  pair_crit <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 0.25,
    2, 4, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  # Create valid AHP matrices: diagonal=1, reciprocal pairs
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  m3 <- matrix(c(
    1, 3, 2,
    1/3, 1, 0.5,
    0.5, 2, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m3) <- alt
  colnames(m3) <- alt
  
  pair_alt <- list(m1, m2, m3)
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit,
    pair_alt = pair_alt
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultRanking")
  expect_equal(length(result$raw_result), length(alt))
  expect_equal(names(result$raw_result), alt)
})

test_that("DeciderAHP can solve choice task", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2", "C3")  # Use 3 criteria to avoid CI/RI = NA for 2x2 matrix
  
  # Create 3x3 pair_crit matrix with valid consistency
  pair_crit <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 0.25,
    2, 4, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  m3 <- matrix(c(
    1, 3, 2,
    1/3, 1, 0.5,
    0.5, 2, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m3) <- alt
  colnames(m3) <- alt
  
  pair_alt <- list(m1, m2, m3)
  
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit,
    pair_alt = pair_alt
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultChoice")
  expect_equal(length(result$raw_result), length(alt))
  expect_equal(names(result$raw_result), alt)
})

test_that("DeciderAHP requires pair_crit and judge_alt_profile for sorting", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2")
  cat_names <- c("Low", "Medium", "High")
  
  # Missing pair_crit
  judge_alt_profile <- data.frame(
    criterion = rep(crit, each = 6),
    alt = rep(rep(alt, each = 2), 2),
    profile = rep(c("p1", "p2"), 6),
    value = c(5, 3, 7, 5, 3, 1, 7, 5, 5, 3, 3, 1)
  )
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    judge_alt_profile = judge_alt_profile
  )
  
  decider <- DeciderAHP$new()
  expect_error(
    decider$solve(task),
    "pair_crit"
  )
  
  # Missing judge_alt_profile
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  prof <- matrix(c(10, 20, 30, 40), nrow = 2, ncol = 2)
  rownames(prof) <- c("p1", "p2")
  colnames(prof) <- crit
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    pair_crit = pair_crit,
    prof = prof
  )
  
  # Should not use AHPSort if judge_alt_profile is missing
  # (will fall back to ranking mode, which will fail)
  expect_error(
    decider$solve(task),
    "pair_alt"
  )
})

test_that("DeciderAHP can solve AHPSort task", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2")
  cat_names <- c("Low", "Medium", "High")
  
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  judge_alt_profile <- data.frame(
    criterion = rep(crit, each = 6),
    alt = rep(rep(alt, each = 2), 2),
    profile = rep(c("p1", "p2"), 6),
    value = c(5, 3, 7, 5, 3, 1, 7, 5, 5, 3, 3, 1)
  )
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    pair_crit = pair_crit,
    judge_alt_profile = judge_alt_profile,
    prof_order = c("p1", "p2"),
    assign_rule = "pessimistic"
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultSorting")
  expect_equal(length(result$raw_result), length(alt))
  expect_equal(names(result$raw_result), alt)
  expect_false(is.null(result$categories))
  expect_equal(length(result$categories), length(alt))
})

test_that("DeciderAHP stores metadata in state for ranking/choice", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2", "C3")  # Use 3 criteria to avoid CI/RI = NA for 2x2 matrix
  
  # Create 3x3 pair_crit matrix with valid consistency
  pair_crit <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 0.25,
    2, 4, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  m3 <- matrix(c(
    1, 3, 2,
    1/3, 1, 0.5,
    0.5, 2, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m3) <- alt
  colnames(m3) <- alt
  
  pair_alt <- list(m1, m2, m3)
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit,
    pair_alt = pair_alt
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  expect_type(decider$state, "list")
  
  # For ranking tasks, DeciderAHP stores:
  # - crit_weights: criteria weights vector
  # - crit_alt_unweighted: unweighted alternatives matrix
  # - crit_alt_weighted: weighted alternatives matrix
  # - ci_cr: consistency ratio
  expect_true("crit_weights" %in% names(decider$state))
  expect_true("crit_alt_unweighted" %in% names(decider$state))
  expect_true("crit_alt_weighted" %in% names(decider$state))
  expect_true("ci_cr" %in% names(decider$state))
  
  # Check dimensions
  expect_equal(length(decider$state$crit_weights), length(crit))
  expect_equal(dim(decider$state$crit_alt_unweighted), c(length(crit), length(alt)))
  expect_equal(dim(decider$state$crit_alt_weighted), c(length(crit), length(alt)))
  
  # Also check metadata in result
  expect_type(result$metadata, "list")
  expect_true("crit_weights" %in% names(result$metadata))
  expect_true("crit_alt_unweighted" %in% names(result$metadata))
  expect_true("crit_alt_weighted" %in% names(result$metadata))
  expect_true("ci_cr" %in% names(result$metadata))
})

test_that("DeciderAHP stores prof_flow in state for sorting", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2")
  cat_names <- c("Low", "Medium", "High")
  
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  judge_alt_profile <- data.frame(
    criterion = rep(crit, each = 6),
    alt = rep(rep(alt, each = 2), 2),
    profile = rep(c("p1", "p2"), 6),
    value = c(5, 3, 7, 5, 3, 1, 7, 5, 5, 3, 3, 1)
  )
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    pair_crit = pair_crit,
    judge_alt_profile = judge_alt_profile,
    prof_order = c("p1", "p2"),
    assign_rule = "pessimistic"
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  state <- decider$state
  expect_type(state, "list")
  
  # For sorting (AHPSort), state should contain prof_flow
  expect_true("prof_flow" %in% names(state))
  expect_type(state$prof_flow, "double")
  expect_true(length(state$prof_flow) > 0)
})

test_that("DeciderAHP solve() returns ResultRanking for ranking task", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2", "C3")  # Use 3 criteria to avoid CI/RI = NA for 2x2 matrix
  
  # Create 3x3 pair_crit matrix with valid consistency
  pair_crit <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 0.25,
    2, 4, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  m3 <- matrix(c(
    1, 3, 2,
    1/3, 1, 0.5,
    0.5, 2, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m3) <- alt
  colnames(m3) <- alt
  
  pair_alt <- list(m1, m2, m3)
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit,
    pair_alt = pair_alt
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultRanking")
  expect_s3_class(result, "TaskResult")
  expect_equal(result$task_type, "ranking")
  expect_equal(length(result$raw_result), task$n_alt())
})

test_that("DeciderAHP solve() preserves metadata", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2", "C3")  # Use 3 criteria to avoid CI/RI = NA for 2x2 matrix
  
  # Create 3x3 pair_crit matrix with valid consistency
  pair_crit <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 0.25,
    2, 4, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(pair_crit) <- crit
  colnames(pair_crit) <- crit
  
  m1 <- matrix(c(
    1, 2, 0.5,
    0.5, 1, 1/3,
    2, 3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m1) <- alt
  colnames(m1) <- alt
  
  m2 <- matrix(c(
    1, 0.5, 2,
    2, 1, 3,
    0.5, 1/3, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m2) <- alt
  colnames(m2) <- alt
  
  m3 <- matrix(c(
    1, 3, 2,
    1/3, 1, 0.5,
    0.5, 2, 1
  ), nrow = 3, ncol = 3, byrow = TRUE)
  rownames(m3) <- alt
  colnames(m3) <- alt
  
  pair_alt <- list(m1, m2, m3)
  
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    pair_crit = pair_crit,
    pair_alt = pair_alt
  )
  
  decider <- DeciderAHP$new()
  result <- decider$solve(task)
  
  # Metadata should exist
  expect_type(result$metadata, "list")
  expect_true("algorithm_name" %in% names(result$metadata))
  expect_equal(result$metadata$algorithm_name, "ahp")
  
  # Metadata should contain AHP-specific fields
  expect_true("crit_weights" %in% names(result$metadata))
  expect_true("crit_alt_unweighted" %in% names(result$metadata))
  expect_true("crit_alt_weighted" %in% names(result$metadata))
  expect_true("ci_cr" %in% names(result$metadata))
})
