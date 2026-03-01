#' DeciderPROMETHEE Class
#'
#' @description
#' PROMETHEE (Preference Ranking Organization Method for Enrichment Evaluations)
#' algorithm implementation for Multi-Criteria Decision Analysis.
#' Uses the \code{RMCDA::apply.PROMETHEE} function for computation.
#'
#' @format An R6 class inheriting from \code{\link{Decider}}.
#'
#' @inheritSection Decider Methods
#'
#' @details
#' PROMETHEE uses preference functions and net flows to rank alternatives.
#' Supports ranking, sorting, and choice tasks. For sorting tasks, uses FlowSort algorithm.
#'
#' The implementation:
#' \itemize{
#'   \item Converts "min" direction criteria to "max" by negating values
#'   \item Checks for duplicated alternatives and constant criteria
#'   \item Uses RMCDA::apply.PROMETHEE with type "II" for computation
#'   \item Returns net flow scores for ranking/choice tasks
#'   \item Returns alternative flows and profile flows for sorting tasks
#' }
#'
#' For ranking and choice tasks, only net flow is returned and stored.
#' For sorting tasks, profile flows are stored in \code{state} for category assignment.
#'
#' @seealso \code{\link{Decider}}, \code{\link{DeciderTOPSIS}}, \code{\link{DeciderAHP}}
#'
#' @examples
#' \dontrun{
#' data(cars, package = "mcdaHub")
#' decider <- DeciderPROMETHEE$new()
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
DeciderPROMETHEE <- R6::R6Class(
  "DeciderPROMETHEE",
  inherit = Decider,
  public = list(
    #' @description
    #' Create a new DeciderPROMETHEE object
    #'
    #' @return A DeciderPROMETHEE object.
    initialize = function() {
      super$initialize()
    }
  ),

  private = list(

    # ---------------------------------------------------------
    # Dispatcher
    # ---------------------------------------------------------
    compute = function(task) {
      if (task$type %in% c("ranking", "choice")) {
        private$check_ranking_choice_fields(task)
        private$compute_ranking_choice(task)
      } else if (task$type == "sorting") {
        private$check_sorting_fields(task)
        private$compute_sorting(task)
      } else {
        stop(sprintf("Unsupported task type '%s' in DeciderPROMETHEE", task$type))
      }
    },

    # ---------------------------------------------------------
    # Required fields
    # ---------------------------------------------------------
    check_ranking_choice_fields = function(task) {
      missing_fields <- character(0)
      if (is.null(task$task_data$crit))      missing_fields <- c(missing_fields, "crit")
      if (is.null(task$task_data$alt))       missing_fields <- c(missing_fields, "alt")
      if (is.null(task$task_data$perf))      missing_fields <- c(missing_fields, "perf")
      if (is.null(task$task_data$weight))    missing_fields <- c(missing_fields, "weight")
      if (is.null(task$task_data$direction)) missing_fields <- c(missing_fields, "direction")
      if (length(missing_fields) > 0) {
        stop(sprintf(
          "DeciderPROMETHEE requires the following fields for %s tasks, but missing: %s",
          task$type,
          paste(missing_fields, collapse = ", ")
        ))
      }
    },

    check_sorting_fields = function(task) {
      missing_fields <- character(0)
      if (is.null(task$task_data$crit))       missing_fields <- c(missing_fields, "crit")
      if (is.null(task$task_data$alt))        missing_fields <- c(missing_fields, "alt")
      if (is.null(task$task_data$perf))       missing_fields <- c(missing_fields, "perf")
      if (is.null(task$task_data$weight))     missing_fields <- c(missing_fields, "weight")
      if (is.null(task$task_data$direction))  missing_fields <- c(missing_fields, "direction")
      if (is.null(task$task_data$cat_names))  missing_fields <- c(missing_fields, "cat_names")
      if (is.null(task$task_data$prof))       missing_fields <- c(missing_fields, "prof")
      if (length(missing_fields) > 0) {
        stop(sprintf(
          "DeciderPROMETHEE requires the following fields for sorting tasks, but missing: %s",
          paste(missing_fields, collapse = ", ")
        ))
      }
    },

    # ---------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------
    check_duplicated_alternatives = function(A, alt) {
      if (!is.null(rownames(A))) {
        if (any(duplicated(rownames(A)))) {
          dup_rownames <- unique(rownames(A)[duplicated(rownames(A))])
          stop(sprintf(
            "Performance matrix has duplicate rownames: %s.",
            paste(dup_rownames, collapse = ", ")
          ))
        }
      }

      # Check for duplicate content (by comparing rows)
      # Convert to matrix for easier comparison
      A_num <- as.matrix(A)
      storage.mode(A_num) <- "numeric"
      
      # Check if all rows are identical (compare all rows to the first row)
      if (nrow(A_num) > 1) {
        first_row <- as.vector(A_num[1, , drop = TRUE])
        all_same <- TRUE
        for (i in 2:nrow(A_num)) {
          current_row <- as.vector(A_num[i, , drop = TRUE])
          if (length(current_row) != length(first_row) || !all(current_row == first_row)) {
            all_same <- FALSE
            break
          }
        }
        if (all_same) {
          stop("All alternatives have identical performance values.")
        }
      }
      
      # Check for partial duplicates using data.frame (duplicated() works better on data.frame)
      df <- as.data.frame(A, stringsAsFactors = FALSE)
      dup_logical <- duplicated(df)
      if (any(dup_logical)) {
        dup <- alt[dup_logical]
        stop(sprintf(
          "Performance matrix contains duplicated alternatives: %s.",
          paste(dup, collapse = ", ")
        ))
      }
    },

    check_constant_criteria = function(A, crit) {
      v <- apply(A, 2, var)
      if (any(v == 0)) {
        const <- crit[v == 0]
        stop(sprintf(
          "Criteria %s are constant across all alternatives.",
          paste(const, collapse = ", ")
        ))
      }
    },

    convert_directions_for_rmcda = function(A, d, crit) {
      A_conv <- as.matrix(A)
      storage.mode(A_conv) <- "numeric"

      if (!is.null(rownames(A))) rownames(A_conv) <- rownames(A)
      if (!is.null(colnames(A))) colnames(A_conv) <- colnames(A)

      for (j in seq_along(crit)) {
        if (d[j] == "min") {
          A_conv[, j] <- -A_conv[, j]
        }
      }
      A_conv
    },

    # ---------------------------------------------------------
    # Ranking / choice (clean version: only net.flow)
    # ---------------------------------------------------------
    compute_ranking_choice = function(task) {
      if (!requireNamespace("RMCDA", quietly = TRUE)) {
        stop("RMCDA package is required for PROMETHEE computation.")
      }

      alt  <- task$alt_names()
      crit <- task$crit_names()
      A    <- task$get_perf()

      w <- as.numeric(task$task_data$weight)
      # Ensure w is a pure numeric vector without any attributes
      w <- as.vector(w)
      names(w) <- NULL
      attributes(w) <- NULL
      d <- as.character(task$task_data$direction)

      private$check_duplicated_alternatives(A, alt)
      private$check_constant_criteria(A, crit)

      A_conv <- private$convert_directions_for_rmcda(A, d, crit)

      # Ensure weights length matches number of criteria
      if (length(w) != length(crit)) {
        stop(sprintf("Weight length (%d) does not match number of criteria (%d)", 
                     length(w), length(crit)))
      }

      # Suppress warnings from RMCDA::apply.PROMETHEE internal sweep() function
      # These warnings ("longer object length is not a multiple of shorter object length")
      # are due to RMCDA package implementation and do not affect functionality
      result <- suppressWarnings(
        RMCDA::apply.PROMETHEE(
          A       = A_conv,
          weights = w,
          type    = "II"
        )
      )

      net.flow <- result[[3]]

      if (length(net.flow) != length(alt)) {
        stop(sprintf(
          "RMCDA returned net.flow length %d but expected %d.",
          length(net.flow), length(alt)
        ))
      }

      net.flow <- as.numeric(net.flow)
      names(net.flow) <- alt

      # 不保存 entering / leaving flow
      self$state <- list()

      net.flow
    },

    # ---------------------------------------------------------
    # Sorting (FlowSort) — unchanged
    # ---------------------------------------------------------
    compute_sorting = function(task) {
      if (!requireNamespace("RMCDA", quietly = TRUE)) {
        stop("RMCDA package is required for PROMETHEE computation.")
      }

      alt  <- task$alt_names()
      crit <- task$crit_names()

      A <- task$get_perf()
      P <- as.matrix(task$task_data$prof)
      storage.mode(P) <- "numeric"
      colnames(P) <- crit

      w <- as.numeric(task$task_data$weight)
      # Ensure w is a pure numeric vector without any attributes
      w <- as.vector(w)
      names(w) <- NULL
      attributes(w) <- NULL
      d <- as.character(task$task_data$direction)

      n_alt  <- length(alt)
      n_prof <- nrow(P)
      
      # Ensure weights length matches number of criteria
      if (length(w) != length(crit)) {
        stop(sprintf("Weight length (%d) does not match number of criteria (%d)", 
                     length(w), length(crit)))
      }

      if (is.null(rownames(P)) || all(rownames(P) == "")) {
        if (!is.null(task$internal_profiles)) {
          rownames(P) <- task$internal_profiles
        } else {
          rownames(P) <- paste0("p", seq_len(n_prof))
        }
      }
      prof_names <- rownames(P)

      private$check_duplicated_alternatives(A, alt)
      private$check_constant_criteria(A, crit)

      all_items <- rbind(A, P)
      all_names <- c(alt, prof_names)
      rownames(all_items) <- all_names
      colnames(all_items) <- crit

      all_items_conv <- private$convert_directions_for_rmcda(all_items, d, crit)

      # Suppress warnings from RMCDA::apply.PROMETHEE internal sweep() function
      # These warnings ("longer object length is not a multiple of shorter object length")
      # are due to RMCDA package implementation and do not affect functionality
      result_all <- suppressWarnings(
        RMCDA::apply.PROMETHEE(
          A       = all_items_conv,
          weights = w,
          type    = "II"
        )
      )

      net_flows_all <- result_all[[3]]
      names(net_flows_all) <- all_names

      alt_flows  <- net_flows_all[seq_len(n_alt)]
      prof_flows <- net_flows_all[(n_alt + 1):length(all_names)]

      internal_profiles <- task$internal_profiles
      names(prof_flows) <- internal_profiles

      self$state <- list(
        prof_flow = prof_flows
      )

      alt_flows
    }
  )
)
