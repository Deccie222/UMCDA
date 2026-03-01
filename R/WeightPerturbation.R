#' WeightPerturbation Class
#'
#' @description
#' A class for performing One-At-A-Time (OAT) weight perturbation
#' and evaluating ranking stability. Provides rank matrix extraction,
#' rank trajectory plots, rank SD plots, and correlation heatmaps.
#'
#' @field task TaskRanking object. The ranking task to analyze.
#' @field decider Decider object. The decider algorithm to use.
#' @field perturb_rg Numeric. Range of perturbation (0.1 <= range <= 0.5). Default: 0.1.
#' @field perturb_n Integer. Number of perturbation steps per criterion (50 <= n <= 200). Default: 100.
#' @field orig_rslt ResultRanking object. Result with original weights.
#' @field perturb_w Matrix. All perturbed weight sets (scenarios × criteria).
#' @field perturb_rslt List. ResultRanking objects for each perturbation.
#'
#' @details
#' This class implements OAT weight perturbation for sensitivity analysis.
#' It supports all Decider types including DeciderTOPSIS, DeciderPROMETHEE, and DeciderAHP.
#' For DeciderPROMETHEE and DeciderAHP, the RMCDA package must be installed.
#'
#' The class includes special handling for numerical stability:
#' - Stable minimum weight (1e-3) to avoid underflow issues
#' - Floating-point stabilization (round to 6 decimals)
#' - Direction normalization (trimws)
#'
#' @seealso \code{\link{TaskRanking}} for creating ranking tasks.
#'   \code{\link{Decider}} for available decider algorithms.
#'
#' @examples
#' \dontrun{
#' # Load toy dataset
#' data(cars, package = "mcdaHub")
#' 
#' # Create a ranking task
#' task <- TaskRanking$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
#'
#' # Create a decider
#' decider <- DeciderTOPSIS$new()
#'
#' # Perform sensitivity analysis
#' wp <- WeightPerturbation$new(
#'   task = task,
#'   decider = decider,
#'   perturb_rg = 0.3,
#'   perturb_n = 51
#' )
#'
#' # Run analysis
#' wp$weight_perturb()
#'
#' # Extract results
#' rank_mat <- wp$perturb_rank()
#' wp$perturb_stab_plot(type = "trajectory")
#' wp$perturb_stab_plot(type = "sd")
#' }
#'
#' @import R6
#'
#' @export
WeightPerturbation <- R6::R6Class(
  "WeightPerturbation",
  public = list(
    task = NULL,
    decider = NULL,
    perturb_rg = NULL,
    perturb_n = NULL,

    orig_rslt = NULL,
    perturb_w = NULL,
    perturb_rslt = NULL,

    #' @description
    #' Create a new WeightPerturbation object
    #'
    #' @param task TaskRanking object. The ranking task to analyze.
    #' @param decider Decider object (or subclass). The decider algorithm to use.
    #' @param perturb_rg Numeric. Range of perturbation (0.1 <= range <= 0.5). Default: 0.1.
    #' @param perturb_n Integer. Number of perturbation steps per criterion (50 <= n <= 200). Default: 100.
    #'
    #' @return A WeightPerturbation object.
    initialize = function(task, decider, perturb_rg = 0.1, perturb_n = 100) {
      if (!inherits(task, "TaskRanking")) {
        stop("task must be a TaskRanking object.")
      }
      if (!inherits(decider, "Decider")) {
        stop("decider must be a Decider object.")
      }
      if (!is.numeric(perturb_rg) || length(perturb_rg) != 1) {
        stop("perturb_rg must be a single numeric value.")
      }
      if (perturb_rg < 0.1 || perturb_rg > 0.5) {
        stop("perturb_rg must be between 0.1 and 0.5.")
      }

      perturb_n <- as.integer(perturb_n)
      if (perturb_n < 50 || perturb_n > 200) {
        stop("perturb_n must be between 50 and 200.")
      }

      self$task <- task
      self$decider <- decider
      self$perturb_rg <- perturb_rg
      self$perturb_n <- perturb_n
    },

    #' @description
    #' Run OAT weight perturbation analysis
    #'
    #' @details
    #' This method:
    #' \itemize{
    #'   \item Solves the task with original weights (baseline)
    #'   \item Generates perturbed weight sets using OAT method
    #'   \item Solves the task for each perturbed weight set
    #' }
    #'
    #' If the decider is DeciderPROMETHEE or DeciderAHP and RMCDA package is not installed,
    #' a clear error message is provided.
    #'
    #' @return Invisibly returns self.
    weight_perturb = function() {
      tryCatch({
        self$orig_rslt <- self$decider$solve(self$task)
      }, error = function(e) {
        decider_name <- class(self$decider)[1]
        stop(sprintf("Failed to solve task with %s: %s",
                     decider_name, conditionMessage(e)), call. = FALSE)
      })

      self$perturb_w <- private$generate_oat_weights()
      n <- nrow(self$perturb_w)

      self$perturb_rslt <- vector("list", n)
      for (i in seq_len(n)) {
        tryCatch({
          task_copy <- private$copy_task(self$perturb_w[i, ])
          self$perturb_rslt[[i]] <- self$decider$solve(task_copy)
        }, error = function(e) {
          self$perturb_rslt[[i]] <- NULL
          warning(sprintf("Perturbation %d failed: %s", i, conditionMessage(e)))
        })
      }

      invisible(self)
    },

    #' @description
    #' Extract rank matrix (scenarios × alternatives)
    #'
    #' @details
    #' Returns a matrix where each row represents a perturbation scenario and
    #' each column represents an alternative. Values are ranks (1 = best).
    #'
    #' @return Matrix with dimensions (scenarios × alternatives).
    perturb_rank = function() {
      if (is.null(self$orig_rslt) || is.null(self$perturb_rslt)) {
        stop("weight_perturb() must be called first.")
      }

      alts <- self$orig_rslt$ranking_table$alt
      n <- length(self$perturb_rslt)

      mat <- matrix(NA, nrow = n, ncol = length(alts))
      colnames(mat) <- alts

      for (i in seq_len(n)) {
        if (!is.null(self$perturb_rslt[[i]])) {
          r <- self$perturb_rslt[[i]]$ranking_table
          if (all(alts %in% r$alt)) {
            mat[i, r$alt] <- r$rank
          }
        }
      }

      mat
    },

    #' @description
    #' Plot rank stability (trajectory or SD)
    #'
    #' @param type Character string. Type of stability plot:
    #'   \itemize{
    #'     \item \code{"trajectory"}: Rank trajectory plot showing how ranks change across scenarios
    #'     \item \code{"sd"}: Standard deviation of ranks across scenarios
    #'   }
    #'
    #' @details
    #' Creates visualizations of rank stability across perturbation scenarios.
    #' Requires \code{ggplot2} and \code{tidyr} packages.
    #'
    #' @return ggplot2 plot object.
    perturb_stab_plot = function(type = c("trajectory", "sd")) {
      type <- match.arg(type)
      rank_mat <- self$perturb_rank()

      if (!requireNamespace("ggplot2", quietly = TRUE)) {
        stop("ggplot2 is required.")
      }
      if (!requireNamespace("tidyr", quietly = TRUE)) {
        stop("tidyr is required.")
      }

      if (type == "trajectory") {
        df <- as.data.frame(rank_mat)
        df$scenario <- seq_len(nrow(df))

        df_long <- tidyr::pivot_longer(
          df, cols = -scenario,
          names_to = "alternative", values_to = "rank"
        )

        return(
          ggplot2::ggplot(df_long, ggplot2::aes(
            x = scenario, y = rank, color = alternative
          )) +
            ggplot2::geom_line() +
            ggplot2::scale_y_reverse() +
            ggplot2::theme_minimal() +
            ggplot2::labs(title = "Rank Trajectory", x = "Scenario", y = "Rank")
        )
      }

      if (type == "sd") {
        sd_vals <- apply(rank_mat, 2, sd, na.rm = TRUE)
        df <- data.frame(alternative = names(sd_vals), sd = sd_vals)

        return(
          ggplot2::ggplot(df, ggplot2::aes(x = alternative, y = sd, fill = alternative)) +
            ggplot2::geom_col() +
            ggplot2::theme_minimal() +
            ggplot2::labs(title = "Rank Stability (SD)", x = "Alternative", y = "SD") +
            ggplot2::theme(legend.position = "none")
        )
      }
    },

    #' @description
    #' Compute rank correlation matrix between perturbation scenarios
    #'
    #' @param method Character string. Correlation method: "spearman" (default),
    #'   "kendall", or "pearson".
    #'
    #' @details
    #' Computes pairwise correlations between perturbation scenarios based on
    #' alternative ranks. Each scenario is treated as a variable, and correlations
    #' are computed across alternatives.
    #'
    #' @return Correlation matrix with dimensions (scenarios × scenarios).
    perturb_rank_corr = function(method = "spearman") {
      allowed_methods <- c("spearman", "kendall", "pearson")
      if (!method %in% allowed_methods) {
        stop("Invalid method.")
      }

      mat <- self$perturb_rank()
      complete_rows <- rowSums(!is.na(mat)) > 0
      if (sum(complete_rows) < 2) {
        stop("Need at least 2 successful perturbations.")
      }

      mat <- mat[complete_rows, , drop = FALSE]
      cor(t(mat), method = method, use = "pairwise.complete.obs")
    },

    #' @description
    #' Plot correlation heatmap
    #'
    #' @param method Character string. Correlation method: "spearman" (default),
    #'   "kendall", or "pearson".
    #'
    #' @details
    #' Creates a heatmap showing rank correlations between different perturbation
    #' scenarios. Requires \code{pheatmap} package.
    #'
    #' @return pheatmap object.
    perturb_corr_heatmap = function(method = "spearman") {
      if (!requireNamespace("pheatmap", quietly = TRUE)) {
        stop("pheatmap is required.")
      }

      corr <- self$perturb_rank_corr(method)
      corr_vals <- corr[!is.na(corr)]

      if (length(corr_vals) > 0) {
        rng <- range(corr_vals)
        if (diff(rng) < 1e-10) {
          breaks <- seq(rng[1] - 0.01, rng[2] + 0.01, length.out = 100)
        } else {
          breaks <- unique(seq(rng[1], rng[2], length.out = 100))
        }
      } else {
        breaks <- NULL
      }

      pheatmap::pheatmap(
        corr,
        main = paste("Rank Correlation Heatmap (", method, ")", sep = ""),
        breaks = breaks,
        cluster_rows = TRUE,
        cluster_cols = TRUE
      )
    }
  ),

  private = list(

    generate_oat_weights = function() {
      w0 <- as.numeric(self$task$task_data$weight)
      k <- length(w0)
      crit_names <- self$task$crit_names()

      min_weight <- 1e-3
      steps <- seq(-self$perturb_rg, self$perturb_rg, length.out = self$perturb_n)
      weights_list <- list()

      idx <- 1
      for (j in seq_len(k)) {
        for (s in steps) {
          w <- as.numeric(w0)

          w[j] <- w0[j] * (1 + s)
          if (w[j] < min_weight) w[j] <- min_weight
          if (w[j] > 1 - min_weight) w[j] <- 1 - min_weight

          remaining_weight <- 1 - w[j]
          original_remaining <- 1 - w0[j]

          if (original_remaining > min_weight) {
            scale_factor <- remaining_weight / original_remaining
            w[-j] <- as.numeric(w0[-j]) * scale_factor
          } else {
            w[-j] <- remaining_weight / (k - 1)
          }

          w <- w / sum(w)
          w <- round(w, 6)
          names(w) <- NULL

          weights_list[[idx]] <- w
          idx <- idx + 1
        }
      }

      do.call(rbind, weights_list)
    },

    copy_task = function(new_weights) {
      new_weights <- as.numeric(new_weights)
      names(new_weights) <- NULL

      direction <- as.character(self$task$task_data$direction)
      direction <- trimws(direction)

      TaskRanking$new(
        alt = self$task$task_data$alt,
        crit = self$task$task_data$crit,
        perf = self$task$task_data$perf,
        weight = new_weights,
        direction = direction
      )
    }
  )
)
