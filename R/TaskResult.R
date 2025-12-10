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

      # 构造统一的表格输出
      if (self$task_type == "ranking") {
        df <- data.frame(
          alt    = names(self$raw_result),
          result = rank(-self$raw_result, ties.method = "first"), # 排序值
          score  = if (!is.null(self$metadata$score)) self$metadata$score else NULL,
          netflows = if (!is.null(self$metadata$netflows)) self$metadata$netflows else NULL,
          stringsAsFactors = FALSE
        )
        print(df)

      } else if (self$task_type == "sorting") {
        df <- data.frame(
          alt    = names(self$output),
          result = self$output,  # 分类结果
          score  = if (!is.null(self$metadata$score)) self$metadata$score else NULL,
          stringsAsFactors = FALSE
        )
        print(df)

      } else if (self$task_type == "choice") {
        df <- data.frame(
          alt    = names(self$raw_result),
          result = ifelse(names(self$raw_result) == self$output, "chosen", ""),
          score  = if (!is.null(self$metadata$score)) self$metadata$score else NULL,
          stringsAsFactors = FALSE
        )
        print(df)

      } else {
        cat("Unknown task type\n")
        print(self$raw_result)
      }
    }
  )
)

