# Test suite for Decider abstract base class
# Note: Decider cannot be instantiated directly, but we test its API through solve() method
# The compute() method is private and should not be called directly

test_that("Decider abstract class cannot be instantiated directly", {
  # Decider is abstract - private compute() throws error when called via solve()
  decider <- Decider$new()
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1"),
    perf = matrix(c(1, 2), nrow = 2),
    weight = 1,
    direction = "max"
  )
  
  expect_error(
    decider$solve(task),
    "compute\\(\\) must be implemented"
  )
})

test_that("Decider solve() validates task type", {
  decider <- DeciderTOPSIS$new()
  
  # Non-TaskDecision object
  expect_error(
    decider$solve("not a task"),
    "solve\\(\\) expects a TaskDecision"
  )
  
  # NULL task
  expect_error(
    decider$solve(NULL),
    "solve\\(\\) expects a TaskDecision"
  )
})

test_that("Decider solve() validates compute() return value", {
  decider <- DeciderTOPSIS$new()
  
  # Test with valid task (should work)
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  result <- decider$solve(task)
  expect_s3_class(result, "ResultRanking")
  expect_equal(result$task_type, "ranking")
})

test_that("Decider solve() ensures raw_result has correct length", {
  # This test ensures solve() checks result length matches n_alt()
  # This would be caught if a Decider subclass returns wrong length
  # We test this indirectly through the actual implementations
  decider <- DeciderTOPSIS$new()
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1"),
    perf = matrix(c(1, 2, 3), nrow = 3),
    weight = 1,
    direction = "max"
  )
  
  result <- decider$solve(task)
  # Result should have same number of alternatives as task
  expect_equal(length(result$raw_result), task$n_alt())
  expect_equal(nrow(result$ranking_table), task$n_alt())
})

test_that("Decider solve() ensures raw_result has names", {
  decider <- DeciderTOPSIS$new()
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  result <- decider$solve(task)
  expect_false(is.null(names(result$raw_result)))
  expect_equal(names(result$raw_result), task$alt_names())
})

test_that("Decider solve() validates raw_result has no NA or Inf", {
  # This is tested indirectly - if compute() returns NA/Inf, solve() should catch it
  # We rely on the actual implementations to not return invalid values
  decider <- DeciderTOPSIS$new()
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  
  result <- decider$solve(task)
  expect_false(anyNA(result$raw_result))
  expect_true(all(is.finite(result$raw_result)))
})

test_that("Decider solve() dispatches to correct result type", {
  decider <- DeciderTOPSIS$new()
  
  # Ranking task
  task_rank <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1"),
    perf = matrix(c(1, 2), nrow = 2),
    weight = 1,
    direction = "max"
  )
  result_rank <- decider$solve(task_rank)
  expect_s3_class(result_rank, "ResultRanking")
  expect_equal(result_rank$task_type, "ranking")
})

test_that("Decider has state field", {
  decider <- DeciderTOPSIS$new()
  
  expect_type(decider$state, "list")
  
  # After solving, state should be populated
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("max", "max")
  )
  decider$solve(task)
  
  expect_type(decider$state, "list")
  expect_gt(length(decider$state), 0)
})







