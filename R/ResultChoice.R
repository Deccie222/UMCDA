#' ResultChoice Class
#'
#' @description
#' Result class for choice problems in Multi-Criteria Decision Analysis.
#' Inherits from \code{\link{TaskResult}} and provides choice-specific functionality.
#'
#' @format An R6 class inheriting from \code{TaskResult}.
#'
#' @field choice Character vector of chosen alternative(s) (those with maximum value).
#' @field choice_table Data frame containing all alternatives with their values and choice status.
#'
#' @section Methods:
#' \describe{
#'   \item{\code{initialize(raw_result, metadata)}}{Create a new ResultChoice object}
#'   \item{\code{print()}}{Print the choice results}
#' }
#'
#' @details
#' The choice table contains:
#' \itemize{
#'   \item \code{alt}: Alternative names
#'   \item \code{value}: Algorithm scores/values
#'   \item \code{is_choice}: Logical indicating if alternative was chosen
#' }
#'
#' @seealso \code{\link{TaskResult}}, \code{\link{TaskChoice}}
#'
#' @export
ResultChoice <- R6::R6Class(
  "ResultChoice",
  inherit = TaskResult,
  public = list(
    choice = NULL,
    choice_table = NULL,

    #' @description
    #' Create a new ResultChoice object
    #'
    #' @param raw_result Named numeric vector. Raw algorithm results (one value per alternative).
    #' @param metadata List. Task and algorithm-specific state information. Default: empty list.
    #'
    #' @return A ResultChoice object.
    initialize = function(raw_result, metadata = list()) {
      # raw_result has already been validated by Decider$solve()
      super$initialize("choice", raw_result, metadata)

      vals <- as.numeric(raw_result)
      alts <- names(raw_result)

      if (is.null(alts) || any(alts == "")) {
        stop("ResultChoice requires named raw_result with non-empty alternative names")
      }

      # Find maximum value(s)
      max_val <- max(vals)
      chosen <- alts[vals == max_val]

      # Save choice
      self$choice <- chosen

      # Optional: save full table (for debugging or visualization)
      df <- data.frame(
        alt   = alts,
        value = vals,
        is_choice = alts %in% chosen,
        stringsAsFactors = FALSE
      )
      rownames(df) <- NULL
      self$choice_table <- df
    },

    #' @description
    #' Print choice results
    #'
    #' @param ... Additional arguments passed to print methods.
    #'
    #' @return Invisibly returns self.
    print = function(...) {
      cat("ResultChoice\n")
      cat("Chosen alternative(s):\n")
      print(self$choice)
      cat("\nFull table:\n")
      print(self$choice_table)
    }
  )
)
