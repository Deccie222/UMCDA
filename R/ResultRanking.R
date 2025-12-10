ResultRanking <- R6::R6Class(
  "ResultRanking",
  inherit = TaskResult,
  public = list(
    ranking_table = NULL,

    initialize = function(raw_result, output = NULL, metadata = list()) {
      super$initialize("ranking", raw_result, output, metadata)

      df <- data.frame(
        alt    = names(raw_result),
        result = rank(-raw_result, ties.method = "first"),
        stringsAsFactors = FALSE
      )

      if (!is.null(metadata$score)) {
        df$score <- metadata$score
      }
      if (!is.null(metadata$netflows)) {
        df$netflows <- metadata$netflows
      }

      rownames(df) <- NULL   # 去掉行名
      self$ranking_table <- df
    },

    print = function(...) {
      cat("ResultRanking\n")
      print(self$ranking_table)
    }
  )
)

