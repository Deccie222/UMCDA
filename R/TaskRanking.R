TaskRanking <- R6::R6Class(
  "TaskRanking",
  inherit = TaskDecision,
  public = list(
    initialize = function(alt, crit, perf, w = NULL, d = NULL) {
      super$initialize(alt, crit, perf, w, d, type = "ranking")
    }
  )
)
