# Test suite for ResultRanking class

# Setup test data
alt <- c("A1", "A2", "A3")
crit <- c("Cost", "Quality")
perf <- matrix(c(100, 200, 150, 8, 9, 7), nrow = 3, ncol = 2)
weight <- c(0.5, 0.5)
direction <- c("min", "max")

test_that("ResultRanking can be created with valid raw_result", {
  raw_result <- c(A1 = 0.8, A2 = 0.5, A3 = 0.7)
  result <- ResultRanking$new(raw_result)
  
  expect_s3_class(result, "ResultRanking")
  expect_s3_class(result, "TaskResult")
  expect_equal(result$task_type, "ranking")
})

test_that("ResultRanking requires named raw_result", {
  # Unnamed vector should fail
  raw_result_unnamed <- c(0.8, 0.5, 0.7)
  expect_error(
    ResultRanking$new(raw_result_unnamed),
    "requires named raw_result"
  )
  
  # Empty names should fail
  raw_result_empty_names <- c(0.8, 0.5, 0.7)
  names(raw_result_empty_names) <- c("A1", "", "A3")
  expect_error(
    ResultRanking$new(raw_result_empty_names),
    "non-empty alternative names"
  )
})

test_that("ResultRanking creates correct ranking_table", {
  raw_result <- c(A1 = 0.8, A2 = 0.5, A3 = 0.7)
  result <- ResultRanking$new(raw_result)
  
  # Check ranking_table structure
  expect_s3_class(result$ranking_table, "data.frame")
  expect_equal(nrow(result$ranking_table), 3)
  expect_true(all(c("alt", "rank", "value") %in% names(result$ranking_table)))
  
  # Check ranking order (higher value = better rank = smaller rank number)
  # A1 has highest value (0.8), so should have rank 1
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A1"], 1)
  # A2 has lowest value (0.5), so should have rank 3
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A2"], 3)
})

test_that("ResultRanking ranking is correct for descending values", {
  raw_result <- c(A1 = 0.9, A2 = 0.1, A3 = 0.5)
  result <- ResultRanking$new(raw_result)
  
  # Should rank: A1 (best, rank 1), A3 (rank 2), A2 (worst, rank 3)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A1"], 1)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A3"], 2)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A2"], 3)
})

test_that("ResultRanking handles ties correctly", {
  # Two alternatives with same value
  raw_result <- c(A1 = 0.8, A2 = 0.8, A3 = 0.5)
  result <- ResultRanking$new(raw_result)
  
  # A1 and A2 should have same rank (ties.method = "first" means first occurrence gets lower rank)
  ranks <- result$ranking_table$rank
  names(ranks) <- result$ranking_table$alt
  expect_equal(unname(ranks["A1"]), 1)
  expect_equal(unname(ranks["A2"]), 2)  # With ties.method = "first", A2 gets rank 2
  expect_equal(unname(ranks["A3"]), 3)
})

test_that("ResultRanking stores metadata correctly", {
  metadata <- list(algorithm = "TOPSIS", some_data = 123)
  raw_result <- c(A1 = 0.8, A2 = 0.5, A3 = 0.7)
  result <- ResultRanking$new(raw_result, metadata = metadata)
  
  expect_equal(result$metadata, metadata)
  expect_equal(result$metadata$algorithm, "TOPSIS")
})

test_that("ResultRanking print() method works", {
  raw_result <- c(A1 = 0.8, A2 = 0.5, A3 = 0.7)
  result <- ResultRanking$new(raw_result)
  
  # Should not throw error
  expect_output(print(result), "ResultRanking")
  expect_output(print(result), "alt")
  expect_output(print(result), "rank")
  expect_output(print(result), "value")
})

test_that("ResultRanking can be created from DeciderTOPSIS output", {
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
  expect_equal(nrow(result$ranking_table), task$n_alt())
  expect_true(all(result$ranking_table$alt %in% task$alt_names()))
})

test_that("ResultRanking can be created from DeciderPROMETHEE output", {
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
  expect_equal(nrow(result$ranking_table), task$n_alt())
  expect_true(all(result$ranking_table$alt %in% task$alt_names()))
})

test_that("ResultRanking handles single alternative", {
  raw_result <- c(A1 = 0.8)
  result <- ResultRanking$new(raw_result)
  
  expect_equal(nrow(result$ranking_table), 1)
  expect_equal(result$ranking_table$rank, 1)
  expect_equal(result$ranking_table$alt, "A1")
  expect_equal(result$ranking_table$value, 0.8)
})

test_that("ResultRanking preserves raw_result", {
  raw_result <- c(A1 = 0.8, A2 = 0.5, A3 = 0.7)
  result <- ResultRanking$new(raw_result)
  
  expect_equal(result$raw_result, raw_result)
  expect_equal(names(result$raw_result), names(raw_result))
})

test_that("ResultRanking value column matches raw_result", {
  raw_result <- c(A1 = 0.8, A2 = 0.5, A3 = 0.7)
  result <- ResultRanking$new(raw_result)
  
  # Check that values in ranking_table match raw_result
  for (alt_name in names(raw_result)) {
    table_value <- result$ranking_table$value[result$ranking_table$alt == alt_name]
    expect_equal(unname(table_value), unname(raw_result[alt_name]))
  }
})

test_that("ResultRanking handles negative values (e.g., PROMETHEE netflow)", {
  # PROMETHEE netflow can be negative
  raw_result <- c(A1 = 0.5, A2 = -0.3, A3 = 0.1)
  result <- ResultRanking$new(raw_result)
  
  expect_equal(nrow(result$ranking_table), 3)
  # A1 should have highest rank (highest value)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A1"], 1)
  # A2 should have lowest rank (lowest value)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A2"], 3)
})

test_that("ResultRanking handles many alternatives", {
  n <- 10
  raw_result <- setNames(seq(1, 0, length.out = n), paste0("A", 1:n))
  result <- ResultRanking$new(raw_result)
  
  expect_equal(nrow(result$ranking_table), n)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == "A1"], 1)
  expect_equal(result$ranking_table$rank[result$ranking_table$alt == paste0("A", n)], n)
})







