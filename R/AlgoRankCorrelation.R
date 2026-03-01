#' AlgoRankCorrelation Class
#'
#' @description
#' A class for computing rank correlation matrices between multiple MCDA algorithm results.
#' This class takes a \code{TaskRanking} and a list of \code{Decider} objects, solves the task
#' with each decider, and computes pairwise correlations between their rankings using Spearman
#' correlation. It is useful for comparing results from different MCDA methods.
#'
#' @field task TaskRanking object. The ranking task to analyze.
#' @field decider List of Decider objects. The decider algorithms to compare (at least 2 required).
#' @field correlation_matrix Matrix. The computed correlation matrix.
#'
#' @details
#' This class supports all Decider types including DeciderTOPSIS, DeciderPROMETHEE, and DeciderAHP.
#' For DeciderPROMETHEE and DeciderAHP, the RMCDA package must be installed.
#'
#' The class uses task cloning to prevent contamination when multiple deciders operate on the same task.
#' If a decider fails to solve the task, it is skipped with a warning message, and the correlation
#' is computed using only the successful deciders (at least 2 required).
#'
#' @seealso \code{\link{TaskRanking}} for creating ranking tasks.
#'   \code{\link{Decider}} for available decider algorithms.
#'   \code{\link[stats]{cor}} for correlation computation.
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
#' # Create deciders
#' decider1 <- DeciderTOPSIS$new()
#' decider2 <- DeciderPROMETHEE$new()
#' decider3 <- DeciderAHP$new()
#'
#' # Create correlation analyzer
#' analyzer <- AlgoRankCorrelation$new(
#'   task = task,
#'   decider = list(decider1, decider2, decider3)
#' )
#'
#' # Calculate correlation matrix
#' corr <- analyzer$calculate()
#' print(analyzer)
#' }
#'
#' @import R6
#'
#' @export
AlgoRankCorrelation <- R6::R6Class(
  "AlgoRankCorrelation",
  public = list(
    task = NULL,
    decider = NULL,
    correlation_matrix = NULL,

    #' @description
    #' Create a new AlgoRankCorrelation object
    #'
    #' @param task TaskRanking object. The ranking task to analyze.
    #' @param decider List of Decider objects. At least 2 deciders are required.
    #'   Each element must inherit from \code{Decider}.
    #'
    #' @return An AlgoRankCorrelation object.
    initialize = function(task, decider) {
      if (!inherits(task, "TaskRanking")) {
        stop("task must be a TaskRanking object. AlgoRankCorrelation only supports ranking tasks.")
      }

      if (!is.list(decider)) {
        stop("decider must be a list")
      }

      if (length(decider) < 2) {
        stop("decider must contain at least 2 Decider objects")
      }

      if (!all(vapply(decider, function(x) inherits(x, "Decider"), logical(1)))) {
        stop("All elements in decider must inherit from Decider")
      }

      self$task <- task
      self$decider <- decider
    },

    #' @description
    #' Calculate correlation matrix between algorithm rankings
    #'
    #' @details
    #' This method:
    #' \itemize{
    #'   \item Solves the task with each decider to get ResultRanking objects
    #'   \item Extracts rankings from all ResultRanking objects
    #'   \item Validates that all results contain the same alternatives
    #'   \item Computes pairwise Spearman correlations between rankings
    #'   \item Uses algorithm names from metadata if available
    #' }
    #'
    #' If a decider fails to solve the task, it is skipped with a warning message.
    #' At least 2 successful deciders are required to compute correlations.
    #'
    #' @return Correlation matrix with dimensions (algorithms × algorithms).
    calculate = function() {
      # Solve task with each decider separately, allowing some to fail
      results <- list()
      successful_deciders <- list()

      for (i in seq_along(self$decider)) {
        d <- self$decider[[i]]
        decider_name <- class(d)[1]

        task_clone <- self$task$clone()

        res <- tryCatch({
          # PROMETHEE / AHP may produce many warnings, suppress them here
          suppressWarnings(d$solve(task_clone))
        }, error = function(e) {
          # Don't stop, just skip this decider
          message(sprintf(
            "AlgoRankCorrelation: decider %s failed and will be skipped. Reason: %s",
            decider_name, conditionMessage(e)
          ))
          NULL
        })

        if (!is.null(res)) {
          results[[length(results) + 1]] <- res
          successful_deciders[[length(successful_deciders) + 1]] <- d
        }
      }

      # Need at least 2 successful deciders to compute correlation
      if (length(results) < 2) {
        stop("AlgoRankCorrelation: fewer than 2 deciders produced valid results. Cannot compute correlation.")
      }

      # Extract rankings
      rank_list <- lapply(results, function(res) {
        if (!inherits(res, "ResultRanking")) {
          stop("All successful deciders must return ResultRanking objects for ranking tasks")
        }
        tbl <- res$ranking_table
        r <- tbl$rank
        names(r) <- tbl$alt
        r
      })

      # Validate that alternatives are consistent
      alt_sets <- lapply(rank_list, names)
      if (!all(vapply(alt_sets, function(x) identical(x, alt_sets[[1]]), logical(1)))) {
        stop("All successful deciders must produce results with the same alternatives in the same order")
      }

      # Construct rank matrix (alternatives × algorithms)
      rank_mat <- do.call(cbind, rank_list)

      # Try to extract algorithm names from metadata
      algorithm_names <- vapply(results, function(res) {
        if (!is.null(res$metadata) && !is.null(res$metadata$algorithm_name)) {
          return(res$metadata$algorithm_name)
        }
        return(NA_character_)
      }, character(1))

      if (all(!is.na(algorithm_names))) {
        colnames(rank_mat) <- algorithm_names
      } else {
        decider_names <- vapply(successful_deciders, function(d) {
          class_name <- class(d)[1]
          if (grepl("^Decider", class_name)) {
            return(tolower(sub("^Decider", "", class_name)))
          }
          return(class_name)
        }, character(1))
        colnames(rank_mat) <- decider_names
      }

      # Compute Spearman correlation matrix (algorithms × algorithms)
      corr <- stats::cor(rank_mat, method = "spearman", use = "pairwise.complete.obs")

      # Set row and column names
      if (all(!is.na(algorithm_names))) {
        rownames(corr) <- algorithm_names
        colnames(corr) <- algorithm_names
      } else {
        decider_names <- vapply(successful_deciders, function(d) {
          class_name <- class(d)[1]
          if (grepl("^Decider", class_name)) {
            return(tolower(sub("^Decider", "", class_name)))
          }
          return(class_name)
        }, character(1))
        rownames(corr) <- decider_names
        colnames(corr) <- decider_names
      }

      self$correlation_matrix <- corr
      return(corr)
    },

    #' @description
    #' Print correlation matrix
    #'
    #' @param ... Additional arguments passed to print methods.
    #'
    #' @return Invisibly returns self.
    print = function(...) {
      if (is.null(self$correlation_matrix)) {
        cat("AlgoRankCorrelation\n")
        cat("Correlation matrix not computed yet. Call calculate() first.\n")
      } else {
        cat("AlgoRankCorrelation\n")
        cat("Method: spearman\n")
        cat("Correlation Matrix:\n")
        print(self$correlation_matrix)
      }
      invisible(self)
    }
  )
)
