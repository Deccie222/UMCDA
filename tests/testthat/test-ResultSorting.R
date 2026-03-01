# Test suite for ResultSorting class

test_that("ResultSorting can be created", {
  raw_result <- c(A1 = 0.8, A2 = 0.6, A3 = 0.4)
  metadata <- list(
    task = NULL,
    prof_flow = NULL
  )
  
  result <- ResultSorting$new(raw_result, metadata)
  
  expect_s3_class(result, "ResultSorting")
  expect_s3_class(result, "TaskResult")
  expect_equal(result$task_type, "sorting")
  expect_equal(length(result$raw_result), 3)
})

test_that("ResultSorting requires named raw_result", {
  raw_result <- c(0.8, 0.6, 0.4)  # Unnamed
  metadata <- list()
  
  expect_error(
    ResultSorting$new(raw_result, metadata),
    "requires named raw_result"
  )
  
  raw_result <- c(0.8, 0.6, 0.4)
  names(raw_result) <- c("A1", "", "A3")  # Empty name
  expect_error(
    ResultSorting$new(raw_result, metadata),
    "requires named raw_result"
  )
})

test_that("ResultSorting creates sorting_table", {
  raw_result <- c(A1 = 0.8, A2 = 0.6, A3 = 0.4)
  metadata <- list()
  
  result <- ResultSorting$new(raw_result, metadata)
  
  expect_s3_class(result$sorting_table, "data.frame")
  expect_equal(nrow(result$sorting_table), 3)
  expect_true("alt" %in% colnames(result$sorting_table))
  expect_true("value" %in% colnames(result$sorting_table))
})

test_that("ResultSorting assigns categories when metadata available", {
  alt <- c("A1", "A2", "A3")
  crit <- c("C1", "C2")
  cat_names <- c("Low", "Medium", "High")
  
  # Create a task
  task <- TaskSorting$new(
    alt = alt,
    crit = crit,
    cat_names = cat_names,
    prof = matrix(c(10, 20, 30, 40), nrow = 2, ncol = 2),
    perf = matrix(c(100, 200, 150, 8, 9, 7), nrow = 3, ncol = 2),
    weight = c(0.5, 0.5),
    direction = c("min", "max")
  )
  
  # Create result through decider
  decider <- DeciderTOPSIS$new()
  result <- decider$solve(task)
  
  expect_false(is.null(result$categories))
  expect_equal(length(result$categories), length(alt))
  expect_true("category" %in% colnames(result$sorting_table))
  expect_true(all(result$categories %in% cat_names))
})

test_that("ResultSorting handles missing prof_flow gracefully", {
  raw_result <- c(A1 = 0.8, A2 = 0.6, A3 = 0.4)
  metadata <- list(
    task = NULL,
    prof_flow = NULL
  )
  
  result <- ResultSorting$new(raw_result, metadata)
  
  expect_null(result$categories)
  expect_false("category" %in% colnames(result$sorting_table))
})

test_that("ResultSorting print method works", {
  raw_result <- c(A1 = 0.8, A2 = 0.6, A3 = 0.4)
  metadata <- list()
  
  result <- ResultSorting$new(raw_result, metadata)
  
  expect_output(print(result), "ResultSorting")
  expect_output(print(result), "alt")
})

