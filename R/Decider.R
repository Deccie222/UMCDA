Decider = R6::R6Class(
  "Decider",
  public = list(
    param_set = NULL,
    state = NULL,

    initialize = function(param_set = list()) {
      self$param_set = param_set
    },

    solve = function(task) {
      raw_result <- self$compute(task)

      if (task$type == "ranking") {
        return(ResultRanking$new(raw_result, metadata = self$state))
      } else if (task$type == "sorting") {
        return(ResultSorting$new(raw_result, metadata = self$state))
      } else if (task$type == "choice") {
        return(ResultChoice$new(raw_result, metadata = self$state))
      } else {
        stop("Unsupported task type")
      }
    },


    compute = function(task) {
      stop("compute() must be implemented in subclass")
    }
  )
)

TaskResult <- R6::R6Class(
  "TaskResult",
  public = list(
    task_type = NULL,
    raw_result = NULL,
    metadata = NULL,

    initialize = function(task_type, raw_result, metadata = list()) {
      self$task_type <- task_type
      self$raw_result <- raw_result
      self$metadata <- metadata
    },

    print = function(...) {
      cat("TaskResult\n")
      cat("Task type:", self$task_type, "\n")
      cat("Raw result:\n")
      print(self$raw_result)
      if (!is.null(self$metadata) && length(self$metadata) > 0) {
        cat("Metadata:\n")
        print(self$metadata)
      }
    }
  )
)


ResultRanking <- R6::R6Class(
  "ResultRanking",
  inherit = TaskResult,
  public = list(
    ranking_table = NULL,

    initialize = function(raw_result, metadata = list()) {
      super$initialize("ranking", raw_result, metadata)

      df <- data.frame(
        alt    = names(raw_result),
        result = rank(-raw_result, ties.method = "first"),
        value  = as.numeric(raw_result),
        stringsAsFactors = FALSE
      )

      rownames(df) <- NULL
      self$ranking_table <- df
    },

    print = function(...) {
      cat("ResultRanking\n")
      print(self$ranking_table)
    }
  )
)
