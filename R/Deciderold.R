Decider = R6::R6Class(
  "Decider",
  public = list(
    id = NULL,          # Algorithm unique identifier (dictionary key)
    algorithm = NULL,   # Algorithm object (AlgorithmXXX)
    param_set = NULL,   # Hyperparameter set
    state = NULL,       # Algorithm state after execution

    initialize = function(id, algorithm, param_set = list()) {
      self$id = id
      self$algorithm = algorithm
      self$param_set = param_set
    },

    set_params = function(params) {
      self$param_set <- modifyList(self$param_set, params)
    },

    get_params = function() {
      return(self$param_set)
    },

    decide = function(task) {
      result <- self$algorithm$compute(task)
      output <- self$algorithm$interpret(result,
                                         self$param_set$output_type,
                                         self$param_set)
      self$state <- list(result = result, output = output)
      return(output)
    },

    print = function(...) {
      cat("Decider:", self$id, "\n")
      cat("Algorithm:", class(self$algorithm)[1], "\n")
      cat("Params:", paste(names(self$param_set), collapse = ", "), "\n")
    }
  )
)
