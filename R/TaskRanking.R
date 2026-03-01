#' TaskRanking Class
#'
#' @description
#' Task class for ranking problems in Multi-Criteria Decision Analysis.
#' Inherits from \code{\link{TaskDecision}} and automatically sets task type to "ranking".
#'
#' @format An R6 class inheriting from \code{TaskDecision}.
#'
#' @inheritSection TaskDecision Methods
#'
#' @details
#' This is a convenience class for ranking tasks. It automatically sets
#' \code{type = "ranking"} when initializing. All other functionality is
#' inherited from \code{TaskDecision}.
#'
#' @seealso \code{\link{TaskDecision}} for base class documentation.
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
#' }
#'
#' @export
TaskRanking <- R6::R6Class(
  "TaskRanking",
  inherit = TaskDecision,
  public = list(
    #' @description
    #' Create a new TaskRanking object
    #'
    #' @param ... Individual fields as named arguments.
    #'   See \code{\link{TaskDecision}} for available fields.
    #'
    #' @return A TaskRanking object.
    #'
    #' @examples
    #' \dontrun{
#' data(cars, package = "mcdaHub")
#' task <- TaskRanking$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
    #' }
    initialize = function(...) {
      # Pass all arguments to parent class, explicitly setting type = "ranking"
      # This ensures all named arguments (alt, crit, perf, weight, direction, etc.)
      # are properly passed through
      super$initialize(..., type = "ranking")
    },

    #' @description
    #' Print task information
    #'
    #' @param ... Additional arguments passed to print methods.
    #'
    #' @return Invisibly returns self.
    print = function(...) {
      cat("<TaskRanking>\n")
      cat(sprintf("Alternatives (%d): %s\n",
                  self$n_alt(),
                  paste(self$task_data$alt, collapse = ", ")))
      cat(sprintf("Criteria (%d): %s\n",
                  self$n_crit(),
                  paste(self$task_data$crit, collapse = ", ")))

      if (!is.null(self$task_data$weight)) {
        cat("Weights:\n")
        weights_df <- data.frame(
          criterion = self$task_data$crit,
          weight = self$task_data$weight,
          stringsAsFactors = FALSE
        )
        print(weights_df, row.names = FALSE)
      }

      if (!is.null(self$task_data$direction)) {
        cat("\nDirections:\n")
        dirs_df <- data.frame(
          criterion = self$task_data$crit,
          direction = self$task_data$direction,
          stringsAsFactors = FALSE
        )
        print(dirs_df, row.names = FALSE)
      }

      if (!is.null(self$task_data$perf)) {
        cat("\nPerformance matrix:\n")
        print(self$task_data$perf)
      }

      invisible(self)
    }
  )
)


