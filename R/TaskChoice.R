#' TaskChoice Class
#'
#' @description
#' Task class for choice problems in Multi-Criteria Decision Analysis.
#' Inherits from \code{\link{TaskDecision}} and automatically sets task type to "choice".
#'
#' @format An R6 class inheriting from \code{TaskDecision}.
#'
#' @inheritSection TaskDecision Methods
#'
#' @details
#' This is a convenience class for choice tasks. It automatically sets
#' \code{type = "choice"} when initializing. All other functionality is
#' inherited from \code{TaskDecision}.
#'
#' @seealso \code{\link{TaskDecision}} for base class documentation.
#'
#' @examples
#' \dontrun{
#' # Load toy dataset
#' data(cars, package = "mcdaHub")
#' 
#' # Create a choice task
#' task <- TaskChoice$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
#' }
#'
#' @export
TaskChoice <- R6::R6Class(
  "TaskChoice",
  inherit = TaskDecision,
  public = list(
    #' @description
    #' Create a new TaskChoice object
    #'
    #' @param ... Individual fields as named arguments.
    #'   See \code{\link{TaskDecision}} for available fields.
    #'
    #' @return A TaskChoice object.
    #'
    #' @examples
    #' \dontrun{
    #' data(cars, package = "mcdaHub")
    #' task <- TaskChoice$new(
    #'   alt = cars$alt,
    #'   crit = cars$crit,
    #'   perf = cars$perf,
    #'   weight = cars$weight,
    #'   direction = cars$direction
    #' )
    #' }
    initialize = function(...) {
      super$initialize(..., type = "choice")
    },
    
    #' @description
    #' Print task information
    #'
    #' @param ... Additional arguments passed to print methods.
    #'
    #' @return Invisibly returns self.
    print = function(...) {
      cat("<TaskChoice>\n")
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
