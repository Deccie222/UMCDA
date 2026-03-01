#' TaskResult Class
#'
#' @description
#' Abstract base class for Multi-Criteria Decision Analysis (MCDA) results.
#' This class stores the raw results and metadata from decision algorithms.
#'
#' @format An R6 abstract class that must be subclassed.
#'
#' @field task_type Character string indicating task type ("ranking", "sorting", or "choice").
#' @field raw_result Numeric vector of raw algorithm results (one value per alternative).
#' @field metadata List containing task and algorithm-specific state information.
#'
#' @section Methods:
#' \describe{
#'   \item{\code{initialize(task_type, raw_result, metadata)}}{Create a new TaskResult object}
#' }
#'
#' @details
#' This class is typically not instantiated directly. Subclasses like
#' \code{\link{ResultRanking}} are created by \code{Decider$solve()} methods.
#'
#' @seealso \code{\link{ResultRanking}}, \code{\link{ResultSorting}}, \code{\link{ResultChoice}}
#'
#' @import R6
#'
#' @export
TaskResult <- R6::R6Class(
  "TaskResult",
  public = list(
    task_type = NULL,
    raw_result = NULL,
    metadata = NULL,

    #' @description
    #' Create a new TaskResult object
    #'
    #' @param task_type Character string. Task type ("ranking", "sorting", or "choice").
    #' @param raw_result Numeric vector. Raw algorithm results (one value per alternative).
    #' @param metadata List. Task and algorithm-specific state information. Default: empty list.
    #'
    #' @return A TaskResult object.
    initialize = function(task_type, raw_result, metadata = list()) {
      self$task_type <- task_type
      self$raw_result <- raw_result
      self$metadata <- metadata
    }
  )
)

