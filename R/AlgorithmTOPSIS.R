AlgorithmTOPSIS = R6::R6Class(
  "AlgorithmTOPSIS",
  inherit = Algorithm,
  public = list(
    initialize = function(param_set = list()) {
      super$initialize(id = "topsis", param_set = param_set)
    },

    compute = function(task) {
      A <- task$get_perf()
      w <- task$w

      if (length(w) != ncol(A)) {
        stop("The dimensions of the weight vector and matrix do not match. Unable to proceed.")
      }

      # Normalize the matrix
      normalized.A <- t(t(A) / sqrt(colSums(A^2)))
      # Apply weights
      normalized.A <- normalized.A * w

      # Distances to positive and negative ideal solutions
      S.pos <- sqrt(rowSums((t(t(normalized.A) - apply(normalized.A, 2, max)))^2))
      S.neg <- sqrt(rowSums((t(t(normalized.A) - apply(normalized.A, 2, min)))^2))

      # Closeness scores
      performance.score <- S.neg / (S.pos + S.neg)
      names(performance.score) <- task$alt

      return(performance.score)
    },

    interpret = function(scores, output_type, params) {
      if (output_type == "ranking") {
        return(sort(scores, decreasing = TRUE))
      } else if (output_type == "sorting") {
        thresholds <- params$thresholds
        return(cut(scores, breaks = thresholds, labels = FALSE))
      } else if (output_type == "choice") {
        return(names(which.max(scores)))
      }
    }
  )
)
