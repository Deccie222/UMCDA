# Test suite for TaskRanking class

# Setup test data
alt <- c("A1", "A2", "A3")
crit <- c("Cost", "Quality", "Time")
perf <- matrix(
  c(100, 200, 150,   # Cost
    8,   9,   7,      # Quality
    5,   3,   4),     # Time
  nrow = 3, ncol = 3, byrow = FALSE
)
weight <- c(0.4, 0.4, 0.2)
direction <- c("min", "max", "min")

test_that("TaskRanking can be created", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  expect_s3_class(task, "TaskRanking")
  expect_s3_class(task, "TaskDecision")
  expect_equal(task$type, "ranking")
})

test_that("TaskRanking automatically sets type to ranking", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  expect_equal(task$type, "ranking")
})

test_that("TaskRanking inherits all TaskDecision methods", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  # Test inherited methods work
  expect_equal(task$n_alt(), 3)
  expect_equal(task$n_crit(), 3)
  expect_equal(task$alt_names(), alt)
  expect_equal(task$crit_names(), crit)
  expect_true(is.matrix(task$get_perf()))
})

test_that("TaskRanking print() method works", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  # Should not throw error
  expect_output(print(task), "TaskRanking")
})

test_that("TaskRanking print() displays correct information", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  output <- capture.output(print(task))
  
  # Check key information is displayed
  expect_true(any(grepl("A1|A2|A3", paste(output, collapse = ""))))
  expect_true(any(grepl("Cost|Quality|Time", paste(output, collapse = ""))))
})

test_that("TaskRanking normalizes weights by default", {
  # With normalization (default) - unnormalized weights should be normalized
  unnormalized <- c(2, 3, 1)  # Sum = 6
  task1 <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = unnormalized,
    direction = direction
  )
  expect_equal(sum(task1$task_data$weight), 1)
  expect_equal(task1$task_data$weight, unnormalized / sum(unnormalized))
  
  # Already normalized weights should remain normalized
  task2 <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  expect_equal(sum(task2$task_data$weight), 1)
  expect_equal(task2$task_data$weight, weight)
})

test_that("TaskRanking can be used with DeciderTOPSIS", {
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
  expect_equal(result$task_type, "ranking")
  expect_equal(length(result$raw_result), 3)
})

test_that("TaskRanking can be used with DeciderPROMETHEE", {
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
  expect_equal(result$task_type, "ranking")
  expect_equal(length(result$raw_result), 3)
})

test_that("TaskRanking maintains all TaskDecision functionality", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  # Test get methods
  expect_equal(task$get_perf("A1", "Cost"), 100)
  expect_equal(task$alt_names(), alt)
  expect_equal(task$crit_names(), crit)
  expect_equal(task$n_alt(), 3)
  expect_equal(task$n_crit(), 3)
})

test_that("TaskRanking requires at least 2 alternatives", {
  # Single alternative should fail
  expect_error(
    TaskRanking$new(
      alt = "A1",
      crit = "Cost",
      perf = matrix(100, nrow = 1, ncol = 1),
      weight = 1,
      direction = "min"
    ),
    "At least 2 alternatives"
  )
})

test_that("TaskRanking interface is consistent with TaskDecision", {
  task <- TaskRanking$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  # All TaskDecision public methods should be accessible
  expect_true(is.function(task$initialize))
  expect_true(is.function(task$validate))
  expect_true(is.function(task$get_perf))
  expect_true(is.function(task$n_alt))
  expect_true(is.function(task$n_crit))
  expect_true(is.function(task$alt_names))
  expect_true(is.function(task$crit_names))
  expect_true(is.function(task$print))
  # Note: set_perf, set_w, set_d, get_w, get_d have been removed from TaskDecision
})
