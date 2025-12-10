AlgorithmPROMETHEE = R6::R6Class(
  "AlgorithmPROMETHEE",
  inherit = Algorithm,
  public = list(
    initialize = function(param_set = list(type = "II")) {
      super$initialize(id = "promethee", param_set = param_set)
    },

    compute = function(task) {
      A <- task$get_perf()
      weights <- task$w
      type <- if (!is.null(self$param_set$type)) self$param_set$type else "II"


      colMaxs <- apply(A, 2, function(x) max(x, na.rm = TRUE))
      colMins <- apply(A, 2, function(x) min(x, na.rm = TRUE))
      processed.A <- t(apply(A, 1, function(row) {
        (row - colMins) / (colMaxs - colMins)
      }))

      # pairwise differences
      pairwise.diff.all <- function(mat.data) {
        n <- nrow(mat.data)
        result <- list()
        for (i in 1:n) {
          for (j in 1:n) {
            if (i != j) {
              diff <- mat.data[i, ] - mat.data[j, ]
              result[[paste("D(M", i, "-M", j, ")", sep = "")]] <- diff
            }
          }
        }
        return(do.call(rbind, result))
      }

      pairwise.diffs <- pairwise.diff.all(processed.A)
      pairwise.diffs[pairwise.diffs < 0] <- 0
      processed.A <- sweep(pairwise.diffs, 2, weights, `*`)
      pairwise.vector <- rowSums(processed.A) / sum(weights)

      row.names <- unique(unlist(lapply(names(pairwise.vector), function(x) strsplit(x, "-")[[1]])))
      row.names <- gsub("D\\(|\\)", "", row.names)

      n <- length(row.names)
      preference.matrix <- matrix(NA, nrow = n, ncol = n, dimnames = list(row.names, row.names))

      for (pair in names(pairwise.vector)) {
        elements <- unlist(strsplit(gsub("D\\(|\\)", "", pair), "-"))
        row_name <- elements[1]
        col_name <- elements[2]
        preference.matrix[row_name, col_name] <- pairwise.vector[pair]
      }

      diag(preference.matrix) <- NA
      preference.matrix <- preference.matrix[1:nrow(A), 1:ncol(A)]
      numeric.matrix <- matrix(as.numeric(preference.matrix),
                               nrow = nrow(preference.matrix),
                               ncol = ncol(preference.matrix))

      if (type == "II") {
        leaving.flow <- rowMeans(numeric.matrix, na.rm = TRUE)
        entering.flow <- colMeans(numeric.matrix, na.rm = TRUE)
        net.out.ranking <- leaving.flow - entering.flow
        return(list(leaving.flow = leaving.flow,
                    entering.flow = entering.flow,
                    net.out.ranking = net.out.ranking))
      } else if (type == "I") {
        leaving.flow <- rowSums(numeric.matrix, na.rm = TRUE)
        entering.flow <- colSums(numeric.matrix, na.rm = TRUE)
        net.out.ranking <- leaving.flow - entering.flow
        return(list(leaving.flow = leaving.flow,
                    entering.flow = entering.flow,
                    net.out.ranking = net.out.ranking))
      } else {
        stop("Invalid type. Must be 'I' or 'II'.")
      }
    },

    interpret = function(result, output_type, params) {
      phi <- result$net.out.ranking
      if (output_type == "ranking") {
        return(sort(phi, decreasing = TRUE))
      } else if (output_type == "sorting") {
        thresholds <- params$thresholds
        return(cut(phi, breaks = thresholds, labels = FALSE))
      } else if (output_type == "choice") {
        return(names(which.max(phi)))
      }
    }
  )
)
