#' ResultRanking Class
#'
#' @description
#' Result class for ranking problems in Multi-Criteria Decision Analysis.
#' Inherits from \code{\link{TaskResult}} and provides ranking-specific functionality.
#'
#' @format An R6 class inheriting from \code{TaskResult}.
#'
#' @field ranking_table Data frame containing alternatives, values, and ranks.
#'
#' @section Methods:
#' \describe{
#'   \item{\code{initialize(raw_result, metadata)}}{Create a new ResultRanking object}
#'   \item{\code{print()}}{Print the ranking results}
#' }
#'
#' @details
#' The ranking table contains:
#' \itemize{
#'   \item \code{alt}: Alternative names
#'   \item \code{value}: Algorithm scores/values
#'   \item \code{rank}: Ranking (1 = best, higher numbers = worse)
#' }
#'
#' @seealso \code{\link{TaskResult}}, \code{\link{TaskRanking}}
#'
#' @export
ResultRanking <- R6::R6Class(
  "ResultRanking",
  inherit = TaskResult,
  public = list(
    ranking_table = NULL,

    #' @description
    #' Create a new ResultRanking object
    #'
    #' @param raw_result Named numeric vector. Raw algorithm results (one value per alternative).
    #' @param metadata List. Task and algorithm-specific state information. Default: empty list.
    #'
    #' @return A ResultRanking object.
    initialize = function(raw_result, metadata = list()) {
      # raw_result has already been validated by Decider$solve:
      # numeric, no NA, and with names
      super$initialize("ranking", raw_result, metadata)

      # Ensure it is a named numeric vector
      vals <- as.numeric(raw_result)
      alts <- names(raw_result)

      if (is.null(alts) || any(alts == "")) {
        stop("ResultRanking requires named raw_result with non-empty alternative names")
      }

      # Store number of alternatives (internal use)
      private$n_alternatives <- length(raw_result)

      df <- data.frame(
        alt    = alts,
        value  = vals,
        rank = rank(-vals, ties.method = "first"),
        stringsAsFactors = FALSE
      )

      rownames(df) <- NULL
      self$ranking_table <- df
    },

    #' @description
    #' Print ranking results
    #'
    #' @param ... Additional arguments passed to print methods.
    #'
    #' @return Invisibly returns self.
    print = function(...) {
      cat("ResultRanking\n")
      print(self$ranking_table)
    }
  ),

  private = list(
    n_alternatives = NULL
  )
)
