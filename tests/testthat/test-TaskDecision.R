# Test suite for TaskDecision class

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

test_that("TaskDecision can be created with valid inputs", {
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "ranking"
  )

  expect_s3_class(task, "TaskDecision")
  expect_equal(task$task_data$alt, alt)
  expect_equal(task$task_data$crit, crit)
  expect_equal(task$type, "ranking")
  expect_equal(task$task_data$weight, weight / sum(weight))  # Weights are normalized by default
  expect_equal(task$task_data$direction, direction)
})

test_that("TaskDecision validates required parameters", {
  # Missing alt
  expect_error(
    TaskDecision$new(
      crit = crit,
      perf = perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "alt is required"
  )

  # Missing crit
  expect_error(
    TaskDecision$new(
      alt = alt,
      perf = perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "crit is required"
  )
})

test_that("TaskDecision validates dimension matching", {
  # Wrong perf dimensions
  wrong_perf <- matrix(1:9, nrow = 3, ncol = 3)
  expect_error(
    TaskDecision$new(
      alt = alt[1:2],
      crit = crit,
      perf = wrong_perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "perf dimensions do not match"
  )

  # Wrong weights length (will fail in validate_weight first, before length consistency check)
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = perf,
      weight = weight[1:2],
      direction = direction,
      type = "ranking"
    ),
    "weight length must match criteria"
  )

  # Wrong directions length
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = perf,
      weight = weight,
      direction = direction[1:2],
      type = "ranking"
    ),
    "weight and direction must have the same length"
  )
})

test_that("TaskDecision validates data types and values", {
  # Non-numeric performance matrix
  char_perf <- matrix(c("a", "b", "c", "d", "e", "f", "g", "h", "i"), nrow = 3, ncol = 3)
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = char_perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "perf must be numeric"
  )

  # NA values in performance matrix
  na_perf <- perf
  na_perf[1, 1] <- NA
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = na_perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "perf contains NA"
  )

  # Non-positive weights
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = perf,
      weight = c(0.5, -0.3, 0.2),
      direction = direction,
      type = "ranking"
    ),
    "weight must be positive"
  )

  # Invalid directions
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = perf,
      weight = weight,
      direction = c("max", "max", "invalid"),
      type = "ranking"
    ),
    "direction.*only allow"
  )
})

test_that("TaskDecision validates uniqueness", {
  # Duplicate alternatives
  expect_error(
    TaskDecision$new(
      alt = c("A1", "A1", "A2"),
      crit = crit,
      perf = perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "alt.*must be unique"
  )

  # NA in alternatives
  expect_error(
    TaskDecision$new(
      alt = c("A1", NA, "A3"),
      crit = crit,
      perf = perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "alt contains NA values"
  )

  # Duplicate criteria
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = c("Cost", "Cost", "Time"),
      perf = perf,
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "crit.*must be unique"
  )
})

test_that("TaskDecision normalizes weights by default", {
  # Weights are automatically normalized in initialize() before validate()
  unnormalized_w <- c(2, 3, 1)  # Sum = 6
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = unnormalized_w,
    direction = direction,
    type = "ranking"
  )

  expect_equal(sum(task$task_data$weight), 1)
  expect_equal(task$task_data$weight, unnormalized_w / sum(unnormalized_w))
})

test_that("TaskDecision handles different task types", {
  task_ranking <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "ranking"
  )
  expect_equal(task_ranking$type, "ranking")

  task_sorting <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "sorting"
  )
  expect_equal(task_sorting$type, "sorting")

  task_choice <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "choice"
  )
  expect_equal(task_choice$type, "choice")
})

test_that("TaskDecision accessor methods work correctly", {
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "ranking"
  )

  # Count methods
  expect_equal(task$n_alt(), 3)
  expect_equal(task$n_crit(), 3)

  # Name methods
  expect_equal(task$alt_names(), alt)
  expect_equal(task$crit_names(), crit)

  # Get performance matrix
  perf_matrix <- task$get_perf()
  expect_equal(perf_matrix, task$task_data$perf)
  expect_equal(dim(perf_matrix), c(3, 3))
  expect_equal(rownames(perf_matrix), alt)
  expect_equal(colnames(perf_matrix), crit)
})

test_that("TaskDecision get_perf returns single values correctly", {
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "ranking"
  )

  # Get single value
  value <- task$get_perf("A1", "Cost")
  expect_equal(value, 100)
  expect_type(value, "double")

  # Test different alternatives and criteria
  expect_equal(task$get_perf("A2", "Quality"), 9)
  expect_equal(task$get_perf("A3", "Time"), 4)

  # Test error for non-existent alternative
  expect_error(
    task$get_perf("A99", "Cost"),
    "alternative.*not found"
  )

  # Test error for non-existent criterion
  expect_error(
    task$get_perf("A1", "NonExistent"),
    "criterion.*not found"
  )
})

test_that("TaskDecision handles data.frame input for perf", {
  perf_df <- as.data.frame(perf)
  colnames(perf_df) <- crit

  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf_df,
    weight = weight,
    direction = direction,
    type = "ranking"
  )
  expect_s3_class(task, "TaskDecision")
  expect_equal(task$n_alt(), 3)
  expect_equal(task$n_crit(), 3)
})

test_that("TaskDecision matrix has correct row and column names", {
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "ranking"
  )

  perf_matrix <- task$get_perf()
  expect_equal(rownames(perf_matrix), alt)
  expect_equal(colnames(perf_matrix), crit)
})

test_that("TaskDecision validate method can be called manually", {
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = weight,
    direction = direction,
    type = "ranking"
  )

  # Should not throw error for valid task
  expect_silent(task$validate())

  # Modify task to invalid state and test validation
  task$task_data$perf[1, 1] <- NA
  expect_error(task$validate(), "perf contains NA")
})

test_that("TaskDecision handles edge cases", {
  # Single alternative (should fail - requires at least 2)
  expect_error(
    TaskDecision$new(
      alt = "A1",
      crit = crit,
      perf = matrix(c(100, 8, 5), nrow = 1, ncol = 3),
      weight = weight,
      direction = direction,
      type = "ranking"
    ),
    "At least 2 alternatives"
  )

  # Single criterion
  task2 <- TaskDecision$new(
    alt = alt,
    crit = "Cost",
    perf = matrix(c(100, 200, 150), nrow = 3, ncol = 1),
    weight = 1,
    direction = "min",
    type = "ranking"
  )
  expect_equal(task2$n_crit(), 1)
})

test_that("TaskDecision validates field names", {
  # Invalid field name
  expect_error(
    TaskDecision$new(
      alt = alt,
      crit = crit,
      perf = perf,
      weight = weight,
      direction = direction,
      invalid_field = "test",
      type = "ranking"
    ),
    "Invalid field name"
  )
})

test_that("TaskDecision validates weight normalization", {
  # Unnormalized weights should be automatically normalized in initialize()
  unnormalized <- c(0.4, 0.4, 0.1)  # Sum = 0.9
  task <- TaskDecision$new(
    alt = alt,
    crit = crit,
    perf = perf,
    weight = unnormalized,
    direction = direction,
    type = "ranking"
  )
  # Weights should be normalized automatically
  expect_equal(sum(task$task_data$weight), 1)
  expect_equal(task$task_data$weight, unnormalized / sum(unnormalized))
})
