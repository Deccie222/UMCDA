ResultChoice = R6::R6Class(
  "ResultChoice",
  inherit = TaskResult,
  public = list(
    best_alternative = NULL,
    initialize = function(algorithm_id, raw_result, output) {
      super$initialize(algorithm_id, "choice", raw_result, output)
      self$best_alternative = output
    }
  )
)
