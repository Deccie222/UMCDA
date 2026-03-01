# Test suite for TaskSorting class

# Setup test data
alt <- c("A1", "A2", "A3")
crit <- c("Cost", "Quality")
perf <- matrix(c(100, 200, 150, 8, 9, 7), nrow = 3, ncol = 2)
w <- c(0.5, 0.5)
d <- c("min", "max")
cat_names <- c("Low", "Medium", "High")
prof <- matrix(c(10, 20, 30, 40), nrow = 2, ncol = 2)

test_that("TaskSorting can be created with traditional sorting data", {
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof,
    perf = perf,
    weight = w,
    direction = d
  )
  
  expect_s3_class(task, "TaskSorting")
  expect_s3_class(task, "TaskDecision")
  expect_equal(task$type, "sorting")
  expect_equal(task$cat_names, cat_names)
  expect_equal(task$internal_profiles, c("p1", "p2"))
})

test_that("TaskSorting automatically generates internal_profiles", {
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof
  )
  
  expect_equal(length(task$internal_profiles), length(cat_names) - 1)
  expect_equal(task$internal_profiles, c("p1", "p2"))
})

test_that("TaskSorting validates cat_names", {
  # Missing cat_names
  expect_error(
    TaskSorting$new(alt = alt, crit = crit),
    "cat_names must be provided"
  )
  
  # Duplicate cat_names
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = c("Low", "Low", "High"),
      prof = prof
    ),
    "cat_names must be unique"
  )
  
  # NA in cat_names
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = c("Low", NA, "High"),
      prof = prof
    ),
    "cat_names must be unique"
  )
  
  # Less than 2 categories
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = "Low",
      prof = prof
    ),
    "At least 2 categories"
  )
})

test_that("TaskSorting validates prof matrix", {
  # prof must be a matrix if provided
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = cat_names,
      prof = c(10, 20, 30, 40)  # Not a matrix
    ),
    "prof must be a matrix"
  )
  
  # prof must be numeric
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = cat_names,
      prof = matrix(c("a", "b", "c", "d"), nrow = 2, ncol = 2)
    ),
    "prof must be a numeric matrix"
  )
  
  # prof dimensions must match
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = cat_names,
      prof = matrix(c(10, 20), nrow = 1, ncol = 2)  # Wrong number of rows
    ),
    "prof must have one row per internal profile"
  )
  
  expect_error(
    suppressWarnings(
      TaskSorting$new(
        alt = alt,
        crit = crit,
        cat_names = cat_names,
        prof = matrix(c(10, 20, 30), nrow = 2, ncol = 1)  # Wrong number of columns
      )
    ),
    "prof must have one column per criterion"
  )
})

test_that("TaskSorting validates judge_alt_profile for AHPSort", {
  # Valid judge_alt_profile
  judge_alt_profile <- data.frame(
    criterion = rep(crit, each = 6),
    alt = rep(rep(alt, each = 2), 2),
    profile = rep(c("p1", "p2"), 6),
    value = c(5, 3, 7, 5, 3, 1, 7, 5, 5, 3, 3, 1)
  )
  
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    pair_crit = pair_crit,
    judge_alt_profile = judge_alt_profile
  )
  
  expect_s3_class(task, "TaskSorting")
  expect_equal(task$judge_alt_profile, judge_alt_profile)
  
  # Missing required columns
  expect_error(
    {
      # Create a data.frame with missing 'profile' column
      # Use expand.grid to create proper structure
      test_df <- expand.grid(
        criterion = crit,
        alt = alt,
        stringsAsFactors = FALSE
      )
      test_df$value <- 1
      TaskSorting$new(
        alt = alt,
        crit = crit,
        cat_names = cat_names,
        judge_alt_profile = test_df
      )
    },
    "judge_alt_profile must contain"
  )
  
  # Invalid profile names
  expect_error(
    {
      # Create a data.frame with invalid profile names
      # Use expand.grid to create proper structure
      test_df <- expand.grid(
        criterion = crit,
        alt = alt,
        stringsAsFactors = FALSE
      )
      test_df$profile <- "invalid"
      test_df$value <- 1
      TaskSorting$new(
        alt = alt,
        crit = crit,
        cat_names = cat_names,
        judge_alt_profile = test_df
      )
    },
    "judge_alt_profile.*profile must use internal profiles"
  )
})

test_that("TaskSorting requires either prof or judge_alt_profile", {
  # Neither provided
  expect_error(
    TaskSorting$new(
      alt = alt,
      crit = crit,
      cat_names = cat_names
    ),
    "Either prof or judge_alt_profile must be provided"
  )
  
  # Both provided (should work)
  judge_alt_profile <- data.frame(
    criterion = rep(crit, each = 6),
    alt = rep(rep(alt, each = 2), 2),
    profile = rep(c("p1", "p2"), 6),
    value = c(5, 3, 7, 5, 3, 1, 7, 5, 5, 3, 3, 1)
  )
  
  pair_crit <- matrix(c(1, 2, 0.5, 1), nrow = 2, ncol = 2)
  
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof,
    pair_crit = pair_crit,
    judge_alt_profile = judge_alt_profile
  )
  
  expect_s3_class(task, "TaskSorting")
})

test_that("TaskSorting assign_rule works", {
  task1 <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof,
    assign_rule = "pessimistic"
  )
  expect_equal(task1$assign_rule, "pessimistic")
  
  task2 <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof,
    assign_rule = "optimistic"
  )
  expect_equal(task2$assign_rule, "optimistic")
})

test_that("TaskSorting inherits TaskDecision methods", {
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof
  )
  
  expect_equal(task$n_alt(), 3)
  expect_equal(task$n_crit(), 2)
  expect_equal(task$alt_names(), alt)
  expect_equal(task$crit_names(), crit)
})

test_that("TaskSorting can be used with Decider", {
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = prof,
    perf = perf,
    weight = w,
    direction = d
  )
  
  decider <- DeciderTOPSIS$new()
  result <- decider$solve(task)
  
  expect_s3_class(result, "ResultSorting")
  expect_equal(result$task_type, "sorting")
  expect_equal(length(result$raw_result), task$n_alt())
})
