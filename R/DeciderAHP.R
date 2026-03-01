#' DeciderAHP Class
#'
#' @description
#' AHP-based solver for Multi-Criteria Decision Analysis tasks.
#' Supports both standard AHP for ranking/choice tasks and AHPSort for sorting tasks.
#' \code{DeciderAHP} implements the Analytic Hierarchy Process (AHP) method for MCDA.
#' It supports:
#' \itemize{
#'   \item Ranking / Choice: Standard AHP using pairwise comparison matrices
#'     (\code{pair_crit} and \code{pair_alt})
#'   \item Sorting: AHPSort method using long-format comparison data
#'     (\code{judge_alt_profile})
#' }
#'
#' @details
#' The AHP method uses pairwise comparisons to derive weights and priorities.
#' For ranking/choice tasks, it requires:
#' \itemize{
#'   \item \code{pair_crit}: Pairwise comparison matrix for criteria
#'   \item \code{pair_alt}: List of pairwise comparison matrices for alternatives
#'     (one matrix per criterion)
#' }
#'
#' For sorting tasks (AHPSort), it requires:
#' \itemize{
#'   \item \code{pair_crit}: Pairwise comparison matrix for criteria
#'   \item \code{judge_alt_profile}: Long-format data.frame with columns
#'     \code{criterion}, \code{alt}, \code{profile}, \code{value}
#' }
#'
#' @seealso \code{\link{Decider}} for base class documentation.
#'   \code{\link{TaskRanking}}, \code{\link{TaskChoice}}, \code{\link{TaskSorting}}
#'   for task types.
#'   \code{\link{supplier}} for AHP ranking/choice dataset.
#'   \code{\link{employee}} for AHPSort sorting dataset.
#'
#' @examples
#' # Ranking task with AHP (Supplier Selection scenario)
#' data(supplier, package = "mcdaHub")
#' decider <- DeciderAHP$new()
#' task <- TaskRanking$new(
#'   alt = supplier$alt,
#'   crit = supplier$crit,
#'   pair_crit = supplier$pair_crit,
#'   pair_alt = supplier$pair_alt
#' )
#' result <- decider$solve(task)
#' print(result)
#'
#' # Choice task with AHP
#' task_choice <- TaskChoice$new(
#'   alt = supplier$alt,
#'   crit = supplier$crit,
#'   pair_crit = supplier$pair_crit,
#'   pair_alt = supplier$pair_alt
#' )
#' result_choice <- decider$solve(task_choice)
#' print(result_choice)
#'
#' # AHPSort sorting task (Employee Performance scenario)
#' data(employee, package = "mcdaHub")
#' task_sorting <- TaskSorting$new(
#'   alt = employee$alt,
#'   crit = employee$crit,
#'   cat_names = employee$cat_names,
#'   pair_crit = employee$pair_crit,
#'   judge_alt_profile = employee$judge_alt_profile,
#'   prof_order = employee$prof_order,
#'   assign_rule = "pessimistic"
#' )
#' result_sorting <- decider$solve(task_sorting)
#' print(result_sorting)
#'
#' @export
DeciderAHP <- R6::R6Class(
  "DeciderAHP",
  inherit = Decider,

  public = list(
    #' @description
    #' Create a new DeciderAHP object
    #'
    #' @return A DeciderAHP object.
    initialize = function() {
      super$initialize()
    }
  ),

  private = list(
    # Compute MCDA results using AHP method (internal implementation)
    # Automatically selects the appropriate computation method:
    # - For TaskSorting with judge_alt_profile: uses AHPSort algorithm
    # - For TaskRanking or TaskChoice: uses standard AHP algorithm
    compute = function(task) {

      # Sorting mode with AHPSort data
      if (inherits(task, "TaskSorting") && !is.null(task$task_data$judge_alt_profile)) {
        private$check_sorting_fields(task)
        return(private$compute_sorting(task))
      }

      # Ranking / Choice mode
      private$check_ranking_choice_fields(task)
      return(private$compute_ranking_choice(task))
    },

    check_ranking_choice_fields = function(task) {
      missing_fields <- character(0)
      
      if (is.null(task$task_data$crit)) {
        missing_fields <- c(missing_fields, "crit")
      }
      if (is.null(task$task_data$alt)) {
        missing_fields <- c(missing_fields, "alt")
      }
      if (is.null(task$task_data$pair_crit)) {
        missing_fields <- c(missing_fields, "pair_crit")
      }
      if (is.null(task$task_data$pair_alt)) {
        missing_fields <- c(missing_fields, "pair_alt")
      }
      
      if (length(missing_fields) > 0) {
        stop(sprintf(
          "DeciderAHP requires the following fields for %s tasks, but missing: %s",
          task$type,
          paste(missing_fields, collapse = ", ")
        ))
      }
    },

    check_sorting_fields = function(task) {
      missing_fields <- character(0)
      
      if (is.null(task$task_data$cat_names)) {
        missing_fields <- c(missing_fields, "cat_names")
      }
      if (is.null(task$task_data$judge_alt_profile)) {
        missing_fields <- c(missing_fields, "judge_alt_profile")
      }
      if (is.null(task$task_data$pair_crit)) {
        missing_fields <- c(missing_fields, "pair_crit")
      }
      
      if (length(missing_fields) > 0) {
        stop(sprintf(
          "DeciderAHP requires the following fields for sorting tasks, but missing: %s",
          paste(missing_fields, collapse = ", ")
        ))
      }
      
      # Check that task has internal_profiles (auto-generated from cat_names)
      if (is.null(task$internal_profiles)) {
        stop("TaskSorting must have internal_profiles. This should be auto-generated from cat_names.")
      }
    },

    # ---------------------------------------------------------
    # Validate input matrices for RMCDA::apply.AHP
    # Only checks RMCDA-specific requirements (rownames/colnames must exist)
    # Basic data validation (matrix type, numeric, NA, dimensions, square matrix) is done by TaskDecision$validate()
    # ---------------------------------------------------------
    validate_ahp_inputs = function(pair_crit, pair_alt, crit, alt) {
      # Check rownames and colnames are set (required by RMCDA)
      # TaskDecision$validate() only checks if rownames/colnames match when they exist,
      # but RMCDA requires them to exist and be non-empty
      if (is.null(rownames(pair_crit)) || is.null(colnames(pair_crit)) || 
          any(rownames(pair_crit) == "") || any(colnames(pair_crit) == "")) {
        stop("pair_crit matrix must have rownames and colnames set. They cannot be empty.")
      }
      
      # Check names for alternative comparison matrices
      for (k in seq_along(pair_alt)) {
        if (is.null(rownames(pair_alt[[k]])) || is.null(colnames(pair_alt[[k]])) ||
            any(rownames(pair_alt[[k]]) == "") || any(colnames(pair_alt[[k]]) == "")) {
          stop(sprintf("pair_alt[[%d]] matrix must have rownames and colnames set. They cannot be empty.", k))
        }
      }
    },

    compute_ranking_choice = function(task) {
      if (!requireNamespace("RMCDA", quietly = TRUE)) {
        stop("RMCDA package is required for AHP computation.")
      }

      # Deep copy pair_crit to avoid RMCDA modifying original matrix
      A <- as.matrix(task$task_data$pair_crit)
      storage.mode(A) <- "numeric"
      rownames(A) <- rownames(task$task_data$pair_crit)
      colnames(A) <- colnames(task$task_data$pair_crit)

      # Deep copy pair_alt list (each matrix in the list)
      pair_alt <- lapply(task$task_data$pair_alt, function(mat) {
        mat_copy <- as.matrix(mat)
        storage.mode(mat_copy) <- "numeric"
        rownames(mat_copy) <- rownames(mat)
        colnames(mat_copy) <- colnames(mat)
        mat_copy
      })

      crit <- task$task_data$crit
      alt <- task$task_data$alt
      
      # Validate inputs before calling RMCDA
      # This checks RMCDA-specific requirements (rownames/colnames must exist)
      # Basic validation is done by TaskDecision$validate()
      private$validate_ahp_inputs(A, pair_alt, crit, alt)
      
      # Call RMCDA::apply.AHP
      # Returns: list(criteria.weight, criteria.alternatives.mat, weighted.scores.mat, alternative.score)
      result <- RMCDA::apply.AHP(
        A = A,
        comparing.competitors = pair_alt
      )
      
      # Extract results
      # result[[1]] = criteria.weight (list with CI/RI and weights vector)
      # result[[2]] = criteria.alternatives.mat (unweighted matrix)
      # result[[3]] = weighted.scores.mat (weighted matrix)
      # result[[4]] = alternative.score (final scores vector)
      if (!is.list(result) || length(result) < 4) {
        stop(sprintf(
          "RMCDA::apply.AHP returned unexpected result format. ",
          "Expected a list with at least 4 elements, got: %s",
          class(result)
        ))
      }
      
      criteria_weight <- result[[1]]
      criteria_alt_unweighted <- result[[2]]
      weighted_scores <- result[[3]]
      alt_scores <- result[[4]]
      
      # Ensure alt_scores has names matching alt order
      if (is.null(names(alt_scores))) {
        if (length(alt_scores) == length(alt)) {
          names(alt_scores) <- alt
        } else {
          stop(sprintf("alt_scores length (%d) does not match alt length (%d)", 
                       length(alt_scores), length(alt)))
        }
      } else {
        # Reorder to match alt order (in case RMCDA returns different order)
        if (all(alt %in% names(alt_scores))) {
          alt_scores <- alt_scores[alt]
        }
      }
      
      # Store state information
      # criteria_weight is a list: list(CI/RI, W) from find.weight()
      self$state <- list(
        crit_weights = criteria_weight[[2]],  # W: weights vector
        crit_alt_unweighted = criteria_alt_unweighted,
        crit_alt_weighted = weighted_scores,
        ci_cr = criteria_weight[[1]]  # CI/RI: consistency ratio
      )

      return(alt_scores)
    },

    compute_sorting = function(task) {

      # ---- Step 0: Extract data (validation already done in TaskSorting) ----
      jap <- task$task_data$judge_alt_profile
      alts <- task$task_data$alt
      crits <- task$task_data$crit
      
      # Get profile names from internal_profiles (auto-generated from cat_names)
      # prof matrix is not required since all comparisons are in judge_alt_profile
      if (is.null(task$internal_profiles)) {
        stop("AHPSort requires internal_profiles. This should be auto-generated from cat_names.")
      }
      profs <- task$internal_profiles
      
      n_alt  <- length(alts)
      n_prof <- length(profs)
      n_crit <- length(crits)

      # ---- Step 1: Compute criteria weights from pair_crit ----
      if (is.null(task$task_data$pair_crit)) {
        stop("AHPSort requires pair_crit to compute criteria weights.")
      }

      crit_res <- private$find_weight(task$task_data$pair_crit)
      crit_weights <- crit_res$weights
      
      # Validate crit_weights length matches criteria
      if (length(crit_weights) != n_crit) {
        stop(sprintf(
          "Criteria weights length (%d) does not match number of criteria (%d)",
          length(crit_weights), n_crit
        ))
      }
      names(crit_weights) <- crits

      # ---- Step 2: Build pairwise comparison matrices for each criterion ----
      # For each criterion, build a matrix containing all alternatives and profiles
      # Matrix structure: [alts + profs] × [alts + profs]
      local_priority_list <- list()

      for (cj in crits) {
        
        # Extract comparisons for this criterion
        df_j <- jap[jap$criterion == cj, ]
        
        if (nrow(df_j) == 0) {
          stop(sprintf("No comparisons found in judge_alt_profile for criterion '%s'", cj))
        }

        # Combine alternatives and profiles
        items <- c(alts, profs)
        m <- length(items)

        # Initialize comparison matrix (diagonal = 1, all others = 1 initially)
        M <- matrix(1, nrow = m, ncol = m)
        rownames(M) <- colnames(M) <- items

        # Fill in alt-profile comparisons from judge_alt_profile
        # Data validation is already done in TaskSorting, so we expect all values to exist
        for (i in seq_len(n_alt)) {
          alt_i <- alts[i]
          for (p in seq_len(n_prof)) {
            prof_p <- profs[p]

            # Find the comparison value (should exist due to TaskSorting validation)
            val <- df_j$value[df_j$alt == alt_i & df_j$profile == prof_p]
            
            if (length(val) == 0) {
              stop(sprintf(
                "Missing comparison for %s vs %s (criterion: %s) in judge_alt_profile. This should have been caught by TaskSorting validation.",
                alt_i, prof_p, cj
              ))
            } else if (length(val) > 1) {
              stop(sprintf(
                "Duplicate comparison for %s vs %s (criterion: %s) in judge_alt_profile. This should have been caught by TaskSorting validation.",
                alt_i, prof_p, cj
              ))
            }
            
            # Set comparison value and its reciprocal
            M[alt_i, prof_p] <- val
            M[prof_p, alt_i] <- 1 / val  # Reciprocal property (AHP requirement)
          }
        }
        
        # Alt-alt comparisons: not provided in judge_alt_profile, remain 1 (equal)
        # Profile-profile comparisons: not provided, remain 1 (equal, implicit consistency)
        # This is standard AHPSort: only alt-profile comparisons are provided

        # Compute local priorities using AHP eigenvector method
        res_j <- private$find_weight(M)
        local_priority_list[[cj]] <- res_j$weights
      }

      # ---- Step 3: Extract local priorities for alternatives ----
      # For each criterion, extract the priority values for alternatives only
      local_alt_mat <- matrix(NA_real_, nrow = n_crit, ncol = n_alt)
      rownames(local_alt_mat) <- crits
      colnames(local_alt_mat) <- alts

      for (k in seq_along(crits)) {
        cj <- crits[k]
        w_full <- local_priority_list[[cj]]
        
        # Ensure names are set correctly
        if (is.null(names(w_full))) {
          names(w_full) <- c(alts, profs)
        }
        
        # Extract alternative priorities
        local_alt_mat[k, ] <- w_full[alts]
      }

      # ---- Step 4: Extract local priorities for profiles ----
      # For each criterion, extract the priority values for profiles only
      local_prof_mat <- matrix(NA_real_, nrow = n_crit, ncol = n_prof)
      rownames(local_prof_mat) <- crits
      colnames(local_prof_mat) <- profs

      for (k in seq_along(crits)) {
        cj <- crits[k]
        w_full <- local_priority_list[[cj]]
        
        # Ensure names are set correctly
        if (is.null(names(w_full))) {
          names(w_full) <- c(alts, profs)
        }
        
        # Extract profile priorities
        local_prof_mat[k, ] <- w_full[profs]
      }

      # ---- Step 5: Weighted aggregation to get global scores ----
      # Global score = sum of (local priority × criterion weight) for each alternative/profile
      global_alt  <- as.numeric(t(local_alt_mat)  %*% crit_weights)
      global_prof <- as.numeric(t(local_prof_mat) %*% crit_weights)

      names(global_alt)  <- alts
      names(global_prof) <- profs
      
      # Validate results
      if (anyNA(global_alt) || !all(is.finite(global_alt))) {
        stop("Computed global alternative scores contain NA or non-finite values")
      }
      if (anyNA(global_prof) || !all(is.finite(global_prof))) {
        stop("Computed global profile scores contain NA or non-finite values")
      }

      # ---- Step 6: Store metadata for ResultSorting ----
      self$state$crit_weights <- crit_weights
      self$state$local_alt_mat <- local_alt_mat
      self$state$local_prof_mat <- local_prof_mat
      self$state$prof_flow <- global_prof
      self$state$global_scores <- global_alt
      self$state$local_priority_list <- local_priority_list  # Store full priorities for debugging

      return(global_alt)
    },

    find_weight = function(A) {

      norm.A <- t(t(A) / colSums(A))
      W <- rowMeans(norm.A)

      lambda_max <- mean((A %*% W) / W)
      n <- ncol(A)
      CI <- (lambda_max - n) / (n - 1)

      reference.RI <- data.frame(
        n = 2:10,
        RI = c(0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.51)
      )

      RI <- reference.RI$RI[reference.RI$n == n]
      if (length(RI) == 0) RI <- NA_real_

      ci_cr <- if (!is.na(RI) && RI > 0) CI / RI else NA_real_

      list(
        weights = W,
        ci_cr = ci_cr
      )
    }
  )
)

