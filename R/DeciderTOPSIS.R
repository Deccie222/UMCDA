#' DeciderTOPSIS Class
#'
#' @description
#' TOPSIS (Technique for Order Preference by Similarity to Ideal Solution) algorithm
#' implementation for Multi-Criteria Decision Analysis.
#'
#' @format An R6 class inheriting from \code{\link{Decider}}.
#'
#' @inheritSection Decider Methods
#'
#' @details
#' TOPSIS ranks alternatives based on their distance to the ideal positive solution
#' and distance from the ideal negative solution. Supports ranking, sorting, and choice tasks.
#'
#' @seealso \code{\link{Decider}}, \code{\link{DeciderPROMETHEE}}
#'
#' @examples
#' \dontrun{
#' data(cars, package = "mcdaHub")
#' decider <- DeciderTOPSIS$new()
#' task <- TaskRanking$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
#' result <- decider$solve(task)
#' }
#'
#' @export
DeciderTOPSIS <- R6::R6Class(
  "DeciderTOPSIS",
  inherit = Decider,

  public = list(
    #' @description
    #' Create a new DeciderTOPSIS object
    #'
    #' @return A DeciderTOPSIS object.
    initialize = function() {
      super$initialize()
    }
  ),

  private = list(
    # Compute MCDA results using TOPSIS method (internal implementation)
    # Returns named numeric vector of alternative scores (relative closeness to ideal solution)
    compute = function(task) {
      # Check required fields before computation
      if (task$type %in% c("ranking", "choice")) {
        private$check_ranking_choice_fields(task)
        return(private$compute_ranking_choice(task))
      } else if (task$type == "sorting") {
        private$check_sorting_fields(task)
        return(private$compute_sorting(task))
      } else {
        stop(sprintf("Unsupported task type '%s' in DeciderTOPSIS", task$type))
      }
    },

    # ---------------------------------------------------------
    # Check required fields for ranking/choice tasks
    # ---------------------------------------------------------
    check_ranking_choice_fields = function(task) {
      missing_fields <- character(0)
      
      if (is.null(task$task_data$crit)) {
        missing_fields <- c(missing_fields, "crit")
      }
      if (is.null(task$task_data$alt)) {
        missing_fields <- c(missing_fields, "alt")
      }
      if (is.null(task$task_data$perf)) {
        missing_fields <- c(missing_fields, "perf")
      }
      if (is.null(task$task_data$weight)) {
        missing_fields <- c(missing_fields, "weight")
      }
      if (is.null(task$task_data$direction)) {
        missing_fields <- c(missing_fields, "direction")
      }
      
      if (length(missing_fields) > 0) {
        stop(sprintf(
          "DeciderTOPSIS requires the following fields for %s tasks, but missing: %s",
          task$type,
          paste(missing_fields, collapse = ", ")
        ))
      }
    },

    # ---------------------------------------------------------
    # Check required fields for sorting tasks
    # ---------------------------------------------------------
    check_sorting_fields = function(task) {
      missing_fields <- character(0)
      
      if (is.null(task$task_data$crit)) {
        missing_fields <- c(missing_fields, "crit")
      }
      if (is.null(task$task_data$alt)) {
        missing_fields <- c(missing_fields, "alt")
      }
      if (is.null(task$task_data$perf)) {
        missing_fields <- c(missing_fields, "perf")
      }
      if (is.null(task$task_data$weight)) {
        missing_fields <- c(missing_fields, "weight")
      }
      if (is.null(task$task_data$direction)) {
        missing_fields <- c(missing_fields, "direction")
      }
      if (is.null(task$task_data$cat_names)) {
        missing_fields <- c(missing_fields, "cat_names")
      }
      if (is.null(task$task_data$prof)) {
        missing_fields <- c(missing_fields, "prof")
      }
      # internal_profiles is auto-generated from cat_names, no need to check
      
      if (length(missing_fields) > 0) {
        stop(sprintf(
          "DeciderTOPSIS requires the following fields for sorting tasks, but missing: %s",
          paste(missing_fields, collapse = ", ")
        ))
      }
    },

    # ---------------------------------------------------------
    # Validate inputs for RMCDA::apply.TOPSIS
    # Only checks RMCDA-specific requirements (rownames/colnames must exist)
    # Basic data validation (matrix type, numeric, NA, dimensions) is done by TaskDecision$validate()
    # ---------------------------------------------------------
    validate_topsis_inputs = function(A, w, alt, crit) {
      # Check rownames and colnames are set (required by RMCDA)
      # TaskDecision$validate() only checks if rownames/colnames match when they exist,
      # but RMCDA requires them to exist and be non-empty
      if (is.null(rownames(A)) || any(rownames(A) == "")) {
        stop("A must have rownames set. They cannot be empty.")
      }
      if (is.null(colnames(A)) || any(colnames(A) == "")) {
        stop("A must have colnames set. They cannot be empty.")
      }
      
      # Check rownames match alternatives
      if (length(rownames(A)) != length(alt) || !all(rownames(A) %in% alt)) {
        stop(sprintf("A rownames do not match alternatives. Expected: %s", paste(alt, collapse = ", ")))
      }
      
      # Check colnames match criteria
      if (length(colnames(A)) != length(crit) || !all(colnames(A) %in% crit)) {
        stop(sprintf("A colnames do not match criteria. Expected: %s", paste(crit, collapse = ", ")))
      }
      
      # Check for zero columns (TOPSIS-specific: would cause division by zero in normalization)
      # This is algorithm-specific and not checked by TaskDecision
      col_sums_sq <- colSums(A^2)
      if (any(col_sums_sq == 0)) {
        zero_cols <- which(col_sums_sq == 0)
        stop(sprintf("A has zero-variance columns (all values are zero) for criteria: %s. This will cause division by zero in normalization.",
                     paste(colnames(A)[zero_cols], collapse = ", ")))
      }
    },

    # ---------------------------------------------------------
    # Convert performance matrix to handle min directions
    # For min direction criteria, negate the values so that
    # original minimum (best) becomes maximum after negation
    # ---------------------------------------------------------
    convert_directions_for_rmcda = function(A, d, alt, crit) {
      # Deep copy to avoid modifying original matrix
      A_converted <- as.matrix(A)
      storage.mode(A_converted) <- "numeric"
      rownames(A_converted) <- rownames(A)
      colnames(A_converted) <- colnames(A)
      
      # For min direction criteria, negate the values
      for (j in seq_len(ncol(A))) {
        if (d[j] == "min") {
          A_converted[, j] <- -A_converted[, j]
        } else if (d[j] != "max") {
          stop(sprintf("Invalid direction '%s' for criterion %s", d[j], crit[j]))
        }
      }
      
      return(A_converted)
    },

    # ---------------------------------------------------------
    # TOPSIS for ranking / choice using RMCDA package
    # ---------------------------------------------------------
    compute_ranking_choice = function(task) {
      if (!requireNamespace("RMCDA", quietly = TRUE)) {
        stop("RMCDA package is required for TOPSIS computation.")
      }

      # Deep copy perf to avoid RMCDA modifying original matrix
      A <- as.matrix(task$get_perf())
      storage.mode(A) <- "numeric"
      rownames(A) <- task$alt_names()
      colnames(A) <- task$crit_names()

      w  <- as.numeric(task$task_data$weight)
      d  <- as.character(task$task_data$direction)
      alt <- task$alt_names()
      crit <- task$crit_names()

      # Validate inputs before processing
      private$validate_topsis_inputs(A, w, alt, crit)
      
      # Convert min direction criteria to max by negating values
      # This is the only modification to the data - we don't change RMCDA's algorithm
      A_converted <- private$convert_directions_for_rmcda(A, d, alt, crit)
      
      # After conversion, validate again to ensure no issues
      # (conversion might introduce issues if original data had problems)
      if (anyNA(A_converted) || any(!is.finite(A_converted))) {
        stop("Data conversion resulted in invalid values. Please check your input data.")
      }
      
      # Call RMCDA::apply.TOPSIS
      # Note: RMCDA package expects all criteria to be in max direction
      # We've already converted min criteria by negating values in A_converted
      score <- RMCDA::apply.TOPSIS(
        A = A_converted,
        w = w
      )
      
      # Ensure score has names matching alt order
      if (is.null(names(score))) {
        if (length(score) == length(alt)) {
          names(score) <- alt
        } else {
          stop(sprintf("score length (%d) does not match alt length (%d)", 
                       length(score), length(alt)))
        }
      } else {
        # Reorder to match alt order (in case RMCDA returns different order)
        if (all(alt %in% names(score))) {
          score <- score[alt]
        }
      }

      # Store state (empty for now, can be extended if needed)
      self$state <- list()

      return(score)
    },

    # ---------------------------------------------------------
    # TOPSIS for sorting using RMCDA package
    # Combines alternatives and profiles, then applies TOPSIS
    # ---------------------------------------------------------
    compute_sorting = function(task) {
      if (!requireNamespace("RMCDA", quietly = TRUE)) {
        stop("RMCDA package is required for TOPSIS computation.")
      }

      # Deep copy A
      A <- as.matrix(task$get_perf())
      storage.mode(A) <- "numeric"
      rownames(A) <- task$alt_names()
      colnames(A) <- task$crit_names()

      # Deep copy P
      P <- as.matrix(task$task_data$prof)
      storage.mode(P) <- "numeric"
      # rownames(P) will be handled later based on internal_profiles
      colnames(P) <- task$crit_names()

      w <- as.numeric(task$task_data$weight)
      d <- as.character(task$task_data$direction)
      alt <- task$alt_names()
      crit <- task$crit_names()
      
      # Get profile names
      prof_names <- if (!is.null(task$internal_profiles)) {
        task$internal_profiles
      } else if (!is.null(rownames(P)) && all(rownames(P) != "")) {
        rownames(P)
      } else {
        n_prof <- nrow(P)
        paste0("p", seq_len(n_prof))
      }
      
      n_alt  <- nrow(A)
      n_prof <- nrow(P)
      
      # Validate inputs
      # Check P matrix
      if (!is.matrix(P) || !is.numeric(P)) {
        stop("prof must be a numeric matrix")
      }
      if (ncol(P) != length(crit)) {
        stop(sprintf("prof matrix columns (%d) do not match number of criteria (%d)",
                     ncol(P), length(crit)))
      }
      if (nrow(P) != length(prof_names)) {
        stop(sprintf("prof matrix rows (%d) do not match number of profiles (%d)",
                     nrow(P), length(prof_names)))
      }
      
      # Check P has rownames and colnames
      if (is.null(rownames(P)) || any(rownames(P) == "")) {
        rownames(P) <- prof_names
      }
      if (is.null(colnames(P)) || any(colnames(P) == "")) {
        colnames(P) <- crit
      }
      
      # 1. Combine alternatives and profiles into one matrix
      # This allows TOPSIS to compute scores for both in the same space
      M <- rbind(A, P)
      row_ids <- c(alt, prof_names)
      rownames(M) <- row_ids
      colnames(M) <- crit
      
      # 2. Validate combined matrix
      private$validate_topsis_inputs(M, w, row_ids, crit)
      
      # 3. Convert min direction criteria to max by negating values
      M_converted <- private$convert_directions_for_rmcda(M, d, row_ids, crit)
      
      # After conversion, validate again
      if (anyNA(M_converted) || any(!is.finite(M_converted))) {
        stop("Data conversion resulted in invalid values. Please check your input data.")
      }
      
      # 4. Call RMCDA::apply.TOPSIS on combined matrix
      # This computes TOPSIS scores for both alternatives and profiles
      score_all <- RMCDA::apply.TOPSIS(
        A = M_converted,
        w = w
      )
      
      # 5. Split scores into alternatives and profiles
      score_alt  <- score_all[seq_len(n_alt)]
      score_prof <- score_all[n_alt + seq_len(n_prof)]
      
      # Ensure names are set correctly
      names(score_alt)  <- alt
      names(score_prof) <- prof_names
      
      # 6. Store state
      self$state <- list(
        prof_flow = score_prof
      )

      return(score_alt)
    }
  )
)
