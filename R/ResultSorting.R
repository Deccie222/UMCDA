ResultSorting = R6::R6Class(
  "ResultSorting",
  inherit = TaskResult,
  public = list(
    categories = NULL,
    initialize = function(algorithm_id, raw_result, output) {
      super$initialize(algorithm_id, "sorting", raw_result, output)
      self$categories = output
    }
  )
)
