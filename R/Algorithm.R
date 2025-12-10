Algorithm = R6::R6Class(
  "Algorithm",
  public = list(
    id = NULL,
    param_set = NULL,

    initialize = function(id, param_set = list()) {
      self$id = id
      self$param_set = param_set
    },

    compute = function(task) {
      stop("compute() must be implemented in subclass")
    },

    interpret = function(result, output_type, params) {
      stop("interpret() must be implemented in subclass")
    }
  )
)
