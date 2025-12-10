DeciderTOPSIS <- R6::R6Class(
  "DeciderTOPSIS",
  inherit = Decider,
  public = list(

    initialize = function(param_set = list()) {
      self$param_set <- param_set
    },

    compute = function(task) {
      A <- task$get_perf()   # performance matrix
      w <- task$w            # criteria weights

      # --- 1. Normalize performance matrix ---
      norm.A <- t(t(A) / sqrt(colSums(A^2)))

      # --- 2. Apply weights ---
      norm.A <- sweep(norm.A, 2, w, FUN = "*")

      # --- 3. Determine positive & negative ideal solutions ---
      ideal.pos <- apply(norm.A, 2, max)
      ideal.neg <- apply(norm.A, 2, min)

      # --- 4. Calculate distances to ideal solutions ---
      S.pos <- sqrt(rowSums((norm.A - matrix(ideal.pos, nrow(norm.A), ncol(norm.A), TRUE))^2))
      S.neg <- sqrt(rowSums((norm.A - matrix(ideal.neg, nrow(norm.A), ncol(norm.A), TRUE))^2))

      # --- 5. Compute TOPSIS score ---
      score <- S.neg / (S.pos + S.neg)

      # --- 存储中间结果到 state ---
      self$state <- list(
        norm.A     = norm.A,
        ideal.pos  = ideal.pos,
        ideal.neg  = ideal.neg,
        S.pos      = S.pos,
        S.neg      = S.neg
      )

      # --- 返回最终结果 (TOPSIS score) ---
      return(score)
    }
  )
)
