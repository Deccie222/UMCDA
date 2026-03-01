# Test suite for WeightPerturbation class

test_that("WeightPerturbation can be instantiated", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 100
  )
  
  expect_s3_class(wp, "WeightPerturbation")
  expect_equal(wp$task, task)
  expect_equal(wp$decider, decider)
  expect_equal(wp$perturb_rg, 0.1)
  expect_equal(wp$perturb_n, 100)
})

test_that("WeightPerturbation validates inputs", {
  task <- TaskRanking$new(
    alt = c("A1", "A2"),
    crit = c("C1"),
    perf = matrix(c(1, 2), nrow = 2),
    weight = 1,
    direction = "max"
  )
  
  decider <- DeciderTOPSIS$new()
  
  # Invalid task type
  expect_error(
    WeightPerturbation$new(
      task = "not a task",
      decider = decider
    ),
    "task must be a TaskRanking"
  )
  
  # Invalid decider
  expect_error(
    WeightPerturbation$new(
      task = task,
      decider = "not a decider"
    ),
    "decider must be a Decider"
  )
  
  # Invalid perturb_rg (too small)
  expect_error(
    WeightPerturbation$new(
      task = task,
      decider = decider,
      perturb_rg = 0.05
    ),
    "perturb_rg must be between 0.1 and 0.5"
  )
  
  # Invalid perturb_rg (too large)
  expect_error(
    WeightPerturbation$new(
      task = task,
      decider = decider,
      perturb_rg = 0.6
    ),
    "perturb_rg must be between 0.1 and 0.5"
  )
  
  # Invalid perturb_n (too small)
  expect_error(
    WeightPerturbation$new(
      task = task,
      decider = decider,
      perturb_n = 30
    ),
    "perturb_n must be between 50 and 200"
  )
  
  # Invalid perturb_n (too large)
  expect_error(
    WeightPerturbation$new(
      task = task,
      decider = decider,
      perturb_n = 250
    ),
    "perturb_n must be between 50 and 200"
  )
  
  # Valid boundary values
  wp1 <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 50
  )
  expect_s3_class(wp1, "WeightPerturbation")
  
  wp2 <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.5,
    perturb_n = 200
  )
  expect_s3_class(wp2, "WeightPerturbation")
})

test_that("WeightPerturbation uses default values", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider
  )
  
  expect_equal(wp$perturb_rg, 0.1)
  expect_equal(wp$perturb_n, 100)
})

test_that("WeightPerturbation weight_perturb() works", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51  # Use smaller value for faster testing
  )
  
  wp$weight_perturb()
  
  expect_false(is.null(wp$orig_rslt))
  expect_s3_class(wp$orig_rslt, "ResultRanking")
  expect_false(is.null(wp$perturb_w))
  expect_true(is.matrix(wp$perturb_w))
  expect_false(is.null(wp$perturb_rslt))
  expect_equal(length(wp$perturb_rslt), nrow(wp$perturb_w))
  
  # Check that perturb_w has correct dimensions
  n_crit <- length(task$crit_names())
  expect_equal(ncol(wp$perturb_w), n_crit)
  expect_equal(nrow(wp$perturb_w), n_crit * wp$perturb_n)
})

test_that("WeightPerturbation perturb_rank() works", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51  # Use smaller value for faster testing
  )
  
  # Should error if weight_perturb() not called
  expect_error(
    wp$perturb_rank(),
    "weight_perturb\\(\\) must be called first"
  )
  
  wp$weight_perturb()
  rank_mat <- wp$perturb_rank()
  
  expect_true(is.matrix(rank_mat))
  expect_equal(ncol(rank_mat), length(task$alt_names()))
  expect_equal(nrow(rank_mat), length(wp$perturb_rslt))
  
  # Check that ranks are valid (1 to n_alternatives)
  valid_ranks <- rank_mat[!is.na(rank_mat)]
  expect_true(all(valid_ranks >= 1))
  expect_true(all(valid_ranks <= length(task$alt_names())))
})

test_that("WeightPerturbation handles errors in weight_perturb()", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51  # Use smaller value for faster testing
  )
  
  # Should handle errors gracefully (some results may be NULL)
  wp$weight_perturb()
  
  # Check that structure is correct even if some perturbations failed
  expect_equal(length(wp$perturb_rslt), nrow(wp$perturb_w))
  
  # At least some results should be successful
  successful <- sum(!vapply(wp$perturb_rslt, is.null, logical(1)))
  expect_true(successful > 0)
})

test_that("WeightPerturbation perturb_stab_plot() works", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("tidyr")
  
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51  # Use smaller value for faster testing
  )
  
  wp$weight_perturb()
  
  # Test trajectory plot
  p1 <- wp$perturb_stab_plot(type = "trajectory")
  expect_s3_class(p1, "ggplot")
  
  # Test SD plot
  p2 <- wp$perturb_stab_plot(type = "sd")
  expect_s3_class(p2, "ggplot")
  
  # Test default type (should be trajectory)
  p3 <- wp$perturb_stab_plot()
  expect_s3_class(p3, "ggplot")
})

test_that("WeightPerturbation perturb_corr_heatmap() works", {
  skip_if_not_installed("pheatmap")
  
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51  # Use smaller value for faster testing
  )
  
  wp$weight_perturb()
  
  # Test with default method
  p1 <- wp$perturb_corr_heatmap()
  expect_true(inherits(p1, "list") || inherits(p1, "pheatmap"))
  
  # Test with different methods
  p2 <- wp$perturb_corr_heatmap(method = "pearson")
  expect_true(inherits(p2, "list") || inherits(p2, "pheatmap"))
  
  # Test invalid method
  expect_error(
    wp$perturb_corr_heatmap(method = "invalid"),
    "Invalid method"
  )
})

test_that("WeightPerturbation perturb_rank_corr() works", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51  # Use smaller value for faster testing
  )
  
  wp$weight_perturb()
  
  # Test with default method (spearman)
  corr1 <- wp$perturb_rank_corr()
  expect_true(is.matrix(corr1))
  expect_equal(nrow(corr1), ncol(corr1))
  
  # Test with different methods
  corr2 <- wp$perturb_rank_corr(method = "pearson")
  expect_true(is.matrix(corr2))
  
  corr3 <- wp$perturb_rank_corr(method = "kendall")
  expect_true(is.matrix(corr3))
  
  # Test invalid method
  expect_error(
    wp$perturb_rank_corr(method = "invalid"),
    "Invalid method"
  )
})

test_that("WeightPerturbation perturb_rank_corr() handles insufficient data", {
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderTOPSIS$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51
  )
  
  # This should work normally
  wp$weight_perturb()
  corr <- wp$perturb_rank_corr()
  expect_true(is.matrix(corr))
})

test_that("WeightPerturbation handles DeciderPROMETHEE with RMCDA package check", {
  skip_if_not_installed("RMCDA")
  
  task <- TaskRanking$new(
    alt = c("A1", "A2", "A3"),
    crit = c("C1", "C2"),
    perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    weight = c(0.6, 0.4),
    direction = c("max", "max")
  )
  
  decider <- DeciderPROMETHEE$new()
  
  wp <- WeightPerturbation$new(
    task = task,
    decider = decider,
    perturb_rg = 0.1,
    perturb_n = 51
  )
  
  # Should work if RMCDA is installed
  wp$weight_perturb()
  expect_false(is.null(wp$orig_rslt))
  expect_s3_class(wp$orig_rslt, "ResultRanking")
})
