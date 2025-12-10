DeciderPROMETHEE <- R6::R6Class(
  "DeciderPROMETHEE",
  inherit = Decider,
  public = list(
    initialize = function(param_set = list()) {
      self$param_set <- param_set
    },

    compute = function(task) {
      A <- task$get_perf()   # performance matrix
      w <- task$w            # criteria weights

      # --- 1. Normalize performance matrix ---
      colMaxs <- apply(A, 2, max, na.rm = TRUE)
      colMins <- apply(A, 2, min, na.rm = TRUE)
      processed.A <- t(apply(A, 1, function(row) {
        (row - colMins) / (colMaxs - colMins)
      }))

      # --- 2. Pairwise differences (use alt names) ---
      n <- nrow(processed.A)
      result <- list()
      for (i in 1:n) {
        for (j in 1:n) {
          if (i != j) {
            diff <- processed.A[i, ] - processed.A[j, ]
            result[[paste("D(", task$alt[i], "-", task$alt[j], ")", sep = "")]] <- diff
          }
        }
      }
      pairwise.diffs <- do.call(rbind, result)
      pairwise.diffs[pairwise.diffs < 0] <- 0

      # --- 3. Apply weights ---
      weighted.diffs <- sweep(pairwise.diffs, 2, w, `*`)
      pairwise.vector <- rowSums(weighted.diffs) / sum(w)

      # --- 4. Build preference matrix ---
      preference.matrix <- matrix(NA_real_, nrow = n, ncol = n,
                                  dimnames = list(task$alt, task$alt))
      for (pair in names(pairwise.vector)) {
        elements <- unlist(strsplit(gsub("D\\(|\\)", "", pair), "-"))
        row_name <- elements[1]
        col_name <- elements[2]
        preference.matrix[row_name, col_name] <- pairwise.vector[pair]
      }
      diag(preference.matrix) <- NA
      numeric.matrix <- matrix(as.numeric(preference.matrix),
                               nrow = nrow(preference.matrix),
                               ncol = ncol(preference.matrix),
                               dimnames = dimnames(preference.matrix))

      # --- 5. PROMETHEE II flows ---
      leaving.flow <- rowMeans(numeric.matrix, na.rm = TRUE)
      entering.flow <- colMeans(numeric.matrix, na.rm = TRUE)
      net.out.ranking <- leaving.flow - entering.flow

      # --- 存储中间结果到 state ---
      self$state <- list(
        processed.A       = processed.A,
        pairwise.diffs    = pairwise.diffs,
        weighted.diffs    = weighted.diffs,
        pairwise.vector   = pairwise.vector,
        preference.matrix = preference.matrix,
        numeric.matrix    = numeric.matrix,
        leaving.flow      = leaving.flow,
        entering.flow     = entering.flow
      )

      # --- 返回最终结果 (numeric 向量，带 alt 名字) ---
      return(net.out.ranking)
    }
  )
)
