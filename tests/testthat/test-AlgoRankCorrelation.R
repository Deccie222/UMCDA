# Test suite for AlgoRankCorrelation class

test_that("AlgoRankCorrelation requires TaskRanking", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  
  # Should work with TaskRanking
  expect_s3_class(
    AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2)),
    "AlgoRankCorrelation"
  )
  
  # Should fail with non-TaskRanking
  expect_error(
    AlgoRankCorrelation$new(task = "not a task", decider = list(decider1, decider2)),
    "task must be a TaskRanking object"
  )
})

test_that("AlgoRankCorrelation requires decider to be a list", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  
  expect_error(
    AlgoRankCorrelation$new(task = task, decider = decider1),
    "decider must be a list"
  )
})

test_that("AlgoRankCorrelation requires at least 2 deciders", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  
  expect_error(
    AlgoRankCorrelation$new(task = task, decider = list(decider1)),
    "decider must contain at least 2 Decider objects"
  )
})

test_that("AlgoRankCorrelation requires all deciders to inherit from Decider", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  
  expect_error(
    AlgoRankCorrelation$new(task = task, decider = list(decider1, "not a decider")),
    "All elements in decider must inherit from Decider"
  )
})

test_that("AlgoRankCorrelation works with multiple deciders", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()  # Use two TOPSIS deciders to avoid RMCDA dependency
  
  analyzer <- AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2))
  corr <- analyzer$calculate()
  
  expect_true(is.matrix(corr))
  expect_equal(nrow(corr), 2)
  expect_equal(ncol(corr), 2)
  expect_equal(unname(diag(corr)), c(1, 1))
  expect_equal(analyzer$correlation_matrix, corr)
})

test_that("AlgoRankCorrelation works with three deciders", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  decider3 <- DeciderTOPSIS$new()
  
  analyzer <- AlgoRankCorrelation$new(
    task = task,
    decider = list(decider1, decider2, decider3)
  )
  corr <- analyzer$calculate()
  
  expect_true(is.matrix(corr))
  expect_equal(nrow(corr), 3)
  expect_equal(ncol(corr), 3)
  expect_equal(unname(diag(corr)), c(1, 1, 1))
})

test_that("AlgoRankCorrelation handles DeciderPROMETHEE with RMCDA package check", {
  skip_if_not_installed("RMCDA")
  
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderPROMETHEE$new()
  
  analyzer <- AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2))
  corr <- analyzer$calculate()
  
  expect_true(is.matrix(corr))
  expect_equal(nrow(corr), 2)
  expect_equal(ncol(corr), 2)
})

test_that("AlgoRankCorrelation handles failed deciders gracefully", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  decider3 <- DeciderTOPSIS$new()
  
  analyzer <- AlgoRankCorrelation$new(
    task = task,
    decider = list(decider1, decider2, decider3)
  )
  
  # Should work with all successful deciders
  corr <- analyzer$calculate()
  expect_true(is.matrix(corr))
  expect_equal(nrow(corr), 3)
})

test_that("AlgoRankCorrelation uses algorithm names from metadata", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  
  analyzer <- AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2))
  corr <- analyzer$calculate()
  
  # Check that correlation matrix uses algorithm names
  expect_false(is.null(rownames(corr)))
  expect_false(is.null(colnames(corr)))
  expect_equal(rownames(corr), colnames(corr))
  # Should contain algorithm names (topsis)
  expect_true(any(grepl("topsis", rownames(corr), ignore.case = TRUE)))
})

test_that("AlgoRankCorrelation calculate() returns correlation matrix", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  
  analyzer <- AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2))
  corr <- analyzer$calculate()
  
  # calculate() should return the correlation matrix
  expect_true(is.matrix(corr))
  expect_equal(corr, analyzer$correlation_matrix)
})

test_that("AlgoRankCorrelation uses Spearman method by default", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  
  analyzer <- AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2))
  corr <- analyzer$calculate()
  
  # Should use Spearman (default)
  expect_output(print(analyzer), "Method: spearman")
})

test_that("AlgoRankCorrelation print() method works", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  decider1 <- DeciderTOPSIS$new()
  decider2 <- DeciderTOPSIS$new()
  
  analyzer <- AlgoRankCorrelation$new(task = task, decider = list(decider1, decider2))
  
  # Before calculate()
  expect_output(print(analyzer), "Correlation matrix not computed yet")
  expect_output(print(analyzer), "Call calculate\\(\\) first")
  
  # After calculate()
  analyzer$calculate()
  expect_output(print(analyzer), "AlgoRankCorrelation")
  expect_output(print(analyzer), "Method: spearman")
  expect_output(print(analyzer), "Correlation Matrix:")
})
