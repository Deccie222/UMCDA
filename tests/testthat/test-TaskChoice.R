# Test suite for TaskChoice class (interface tests only)

# Setup test data
alt <- c("A1", "A2", "A3")
crit <- c("Cost", "Quality")
perf <- matrix(c(100, 200, 150, 8, 9, 7), nrow = 3, ncol = 2)
weight <- c(0.5, 0.5)
direction <- c("min", "max")

test_that("TaskChoice can be created", {
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  expect_s3_class(task, "TaskChoice")
  expect_s3_class(task, "TaskDecision")
  expect_equal(task$type, "choice")
})

test_that("TaskChoice automatically sets type to choice", {
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  expect_equal(task$type, "choice")
})

test_that("TaskChoice inherits all TaskDecision methods", {
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  
  # Test inherited methods work
  expect_equal(task$n_alt(), 3)
  expect_equal(task$n_crit(), 2)
  expect_equal(task$alt_names(), alt)
  expect_equal(task$crit_names(), crit)
  expect_true(is.matrix(task$get_perf()))
})

test_that("TaskChoice interface is consistent with TaskDecision", {
  task <- TaskChoice$new(
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
  # Note: set_perf, set_w, set_d, get_w, get_d have been removed from TaskDecision
})

test_that("TaskChoice can be used with Decider solve()", {
  task <- TaskChoice$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction
  )
  decider <- DeciderTOPSIS$new()
  
  # solve() should accept TaskChoice and create ResultChoice
  result <- decider$solve(task)
  
  expect_s3_class(result, "TaskResult")
  expect_equal(result$task_type, "choice")
  expect_equal(length(result$raw_result), task$n_alt())
})







