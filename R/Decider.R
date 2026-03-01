#' Decider Class
#'
#' @description
#' Abstract base class for Multi-Criteria Decision Analysis (MCDA) algorithms.
#' This class defines the interface for decision-making algorithms such as TOPSIS
#' and PROMETHEE.
#'
#' @format An R6 abstract class that must be subclassed.
#'
#' @field state List containing algorithm state and intermediate calculations.
#'
#' @section Methods:
#' \describe{
#'   \item{\code{initialize()}}{Create a new Decider object}
#'   \item{\code{solve(task)}}{Solve a TaskDecision and return a TaskResult}
#' }
#'
#' @details
#' The \code{solve()} method implements the template method pattern:
#' 1. Validates the task
#' 2. Calls internal private \code{compute()} method (implemented by subclasses)
#' 3. Creates the appropriate Result subclass
#' 4. Returns the result
#'
#' The \code{compute()} method is private and should not be called directly by users.
#' Use \code{solve()} instead, which provides the complete workflow including validation
#' and result object creation.
#'
#' @seealso \code{\link{DeciderTOPSIS}}, \code{\link{DeciderPROMETHEE}}
#'
#' @import R6
#'
#' @examples
#' \dontrun{
#' # Decider is abstract and cannot be instantiated directly
#' # Use subclasses instead:
#' data(cars, package = "mcdaHub")
#' decider <- DeciderTOPSIS$new()
#' task <- TaskRanking$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
#' result <- decider$solve(task)
#' }
#'
#' @export
Decider <- R6::R6Class(
  "Decider",
  public = list(
    state = NULL,

    #' @description
    #' Create a new Decider object
    #'
    #' @return A Decider object.
    initialize = function() {
      self$state <- list()
    },

    #' @description
    #' Solve a TaskDecision and return a TaskResult
    #'
    #' @param task TaskDecision object (or subclass: TaskRanking, TaskChoice, TaskSorting).
    #'
    #' @details
    #' This method implements the template method pattern:
    #' \enumerate{
    #'   \item Validates the task
    #'   \item Calls \code{compute()} (implemented by subclasses)
    #'   \item Creates the appropriate Result subclass
    #'   \item Returns the result
    #' }
    #'
    #' @return TaskResult object (ResultRanking, ResultChoice, or ResultSorting).
    solve = function(task) {
      # Type check: must be a TaskDecision or subclass
      if (!inherits(task, "TaskDecision")) {
        stop("solve() expects a TaskDecision (or subclass) object as 'task'")
      }

      # Reset state before each computation to avoid contamination
      self$state <- list()
      
      raw_result <- private$compute(task)
      self$state$task <- task
      
      # Store algorithm name in metadata (extract from class name, e.g., "DeciderTOPSIS" -> "topsis")
      class_name <- class(self)[1]
      if (grepl("^Decider", class_name)) {
        algorithm_name <- tolower(sub("^Decider", "", class_name))
        self$state$algorithm_name <- algorithm_name
      }

      # Validate raw_result
      if (!is.numeric(raw_result)) {
        stop("compute() must return a numeric vector")
      }

      # Ensure length matches number of alternatives
      if (length(raw_result) != task$n_alt()) {
        stop("compute() result length must equal number of alternatives")
      }

      # Ensure names exist; fallback to task$alt_names()
      if (is.null(names(raw_result))) {
        names(raw_result) <- task$alt_names()
      }

      # Disallow NA or non-finite values
      if (anyNA(raw_result) || !all(is.finite(raw_result))) {
        stop("compute() returned NA or non-finite values")
      }

      # Dispatch result type
      if (task$type == "ranking") {
        return(ResultRanking$new(raw_result, metadata = self$state))
      } else if (task$type == "sorting") {
        return(ResultSorting$new(raw_result, metadata = self$state))
      } else if (task$type == "choice") {
        return(ResultChoice$new(raw_result, metadata = self$state))
      } else {
        stop("Unsupported task type")
      }
    }
  ),

  private = list(
    # Abstract method: compute raw results (internal implementation)
    # This method must be implemented in subclasses. It should return a named
    # numeric vector with one value per alternative.
    compute = function(task) {
      stop("compute() must be implemented in subclass")
    }
  )
)

