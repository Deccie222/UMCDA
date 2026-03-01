#' TaskDecision Class
#'
#' @description
#' Base class for Multi-Criteria Decision Analysis (MCDA) tasks.
#' Stores alternatives, criteria, performance matrix, weights, and directions.
#' This class is typically not instantiated directly; use subclasses like
#' \code{\link{TaskRanking}} instead.
#'
#' @format An R6 class with the following fields and methods:
#'
#' @field type Character string indicating task type ("ranking", "sorting", or "choice").
#' @field task_data List containing all task data (alt, crit, perf, weight, direction, pair_crit, pair_alt, etc.).
#'
#' @section Methods:
#' \describe{
#'   \item{\code{initialize(..., type)}}{Create a new TaskDecision object}
#'   \item{\code{validate()}}{Validate all data and constraints}
#'   \item{\code{get_perf(alt_name, crit_name)}}{Get performance matrix or single value}
#'   \item{\code{n_alt()}}{Get number of alternatives}
#'   \item{\code{n_crit()}}{Get number of criteria}
#'   \item{\code{alt_names()}}{Get alternative names}
#'   \item{\code{crit_names()}}{Get criterion names}
#' }
#'
#' @details
#' The class uses a unified \code{task_data} list as a pure data container to store task data.
#' Available fields include:
#' \itemize{
#'   \item \code{alt}: Character vector of alternative names (required)
#'   \item \code{crit}: Character vector of criterion names (required)
#'   \item \code{perf}: Performance matrix (alternatives × criteria) (optional)
#'   \item \code{weight}: Criterion weights vector (optional)
#'   \item \code{direction}: Optimization directions ("max" or "min") (optional)
#'   \item \code{pair_crit}: Pairwise comparison matrix for criteria (AHP) (optional)
#'   \item \code{pair_alt}: List of pairwise comparison matrices for alternatives (AHP) (optional)
#'   \item \code{cat_names}: Category names for sorting tasks (required for sorting)
#'   \item \code{prof}: Profile matrix for sorting tasks (optional, must be matrix type)
#'   \item \code{judge_alt_profile}: Judgments for AHPSort (optional, long-format data.frame)
#'   \item \code{cat_count}, \code{cat_structure}, \code{prof_order}: Deprecated fields,
#'         no longer required (internal_profiles auto-generated from cat_names)
#' }
#' 
#' \code{task_data} serves as a pure data container with no enforced combination rules.
#' The \code{validate()} method only validates each field individually (dimensions, types, values),
#' without checking for required combinations. It is up to the algorithms (Decider classes)
#' to determine which fields are required for their specific methods.
#'
#' @seealso \code{\link{TaskRanking}} for ranking tasks.
#'
#' @import R6
#'
#' @export
TaskDecision <- R6::R6Class(
  "TaskDecision",
  public = list(
    type = NULL,
    task_data = NULL,

    #' @description
    #' Create a new TaskDecision object
    #'
    #' @param ... Individual fields as named arguments:
    #'   \itemize{
    #'     \item \code{alt}: Character vector of alternative names (must be unique, required)
    #'     \item \code{crit}: Character vector of criterion names (must be unique, required)
    #'     \item \code{perf}: Numeric matrix of performance values (optional)
    #'     \item \code{weight}: Numeric vector of criterion weights (optional)
    #'     \item \code{direction}: Character vector of optimization directions (optional)
    #'     \item \code{pair_crit}: Pairwise comparison matrix for criteria (optional)
    #'     \item \code{pair_alt}: List of pairwise comparison matrices for alternatives (optional)
    #'   }
    #' @param type Task type: "ranking", "sorting", or "choice".
    #'
    #' @return A TaskDecision object.
    #'
    #' @examples
    #' task <- TaskDecision$new(
    #'   alt = c("A1", "A2", "A3"),
    #'   crit = c("C1", "C2"),
    #'   perf = matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2),
    #'   weight = c(0.5, 0.5),
    #'   direction = c("max", "max"),
    #'   type = "ranking"
    #' )
    initialize = function(..., type = c("ranking", "sorting", "choice")) {
      
      # Get all arguments
      dots <- list(...)
      
        # Extract special parameters that should not be in task_data
        special_params <- c("type")
        data_list <- dots[!names(dots) %in% special_params]
        
        # Update special parameters if provided in dots
        if ("type" %in% names(dots)) {
          type <- dots$type
        }
      
      # Validate that arguments are provided
      if (length(data_list) == 0) {
        stop("At least 'alt' and 'crit' must be provided as named arguments")
      }
      
      # Validate that all arguments are named
      if (is.null(names(dots)) || any(names(dots) == "")) {
        stop("All arguments must be named. Use format: alt = ..., crit = ..., etc.")
      }
      
      # Validate field names (check for typos and invalid fields)
      private$validate_field_names(data_list)
      
      # Validate alt and crit are required
      if (is.null(data_list$alt)) {
        stop("alt is required (provide as 'alt' argument)")
      }
      if (is.null(data_list$crit)) {
        stop("crit is required (provide as 'crit' argument)")
      }
      
      self$type <- match.arg(type)
      
      # Initialize task_data with all allowed fields (fixed structure)
      allowed_fields <- private$get_allowed_fields()
      self$task_data <- setNames(vector("list", length(allowed_fields)), allowed_fields)
      
      # Fill task_data with user-provided values
      for (field in names(data_list)) {
        if (field %in% allowed_fields) {
          self$task_data[[field]] <- data_list[[field]]
        }
      }
      
      # Process perf matrix if provided
      if (!is.null(self$task_data$perf)) {
        perf <- as.matrix(self$task_data$perf)
        if (nrow(perf) == length(self$task_data$alt) && ncol(perf) == length(self$task_data$crit)) {
          rownames(perf) <- self$task_data$alt
          colnames(perf) <- self$task_data$crit
          self$task_data$perf <- perf
        } else {
          stop("perf dimensions do not match alt/crit")
        }
      }
      
      # Normalize weights if provided (before validation)
      if (!is.null(self$task_data$weight)) {
        # Ensure weight is a pure numeric vector (not a matrix row with dim attribute)
        self$task_data$weight <- as.numeric(self$task_data$weight)
        weight_sum <- sum(self$task_data$weight)
        if (abs(weight_sum - 1) > 1e-8 && weight_sum > 0) {
          self$task_data$weight <- as.numeric(self$task_data$weight / weight_sum)
        }
      }
      
      # Ensure direction is a pure character vector
      if (!is.null(self$task_data$direction)) {
        self$task_data$direction <- as.character(self$task_data$direction)
      }
      
      # Validate all data
      self$validate()
    },

    #' @description Validate task data
    #' @return Invisibly returns self.
    #' @details
    #' Validates dimensions, data types, uniqueness, and constraints for each field individually.
    #' Automatically called during initialization.
    #' This method only validates the fields themselves, without enforcing any combination rules.
    #' task_data serves as a pure data container.
    validate = function() {
      # Validate basic constraints for required fields
      if (is.null(self$task_data$alt)) {
        stop("alt is required in task_data")
      }
      if (is.null(self$task_data$crit)) {
        stop("crit is required in task_data")
      }
      
      # Validate alt and crit data types
      if (!is.character(self$task_data$alt)) {
        stop("alt must be a character vector")
      }
      if (!is.character(self$task_data$crit)) {
        stop("crit must be a character vector")
      }
      
      # Validate alt and crit uniqueness and non-empty
      if (anyNA(self$task_data$alt)) {
        stop("alt contains NA values")
      }
      if (anyNA(self$task_data$crit)) {
        stop("crit contains NA values")
      }
      if (anyDuplicated(self$task_data$alt) > 0 || any(self$task_data$alt == "")) {
        stop("alternatives must be unique and non-empty")
      }
      if (anyDuplicated(self$task_data$crit) > 0 || any(self$task_data$crit == "")) {
        stop("criteria must be unique and non-empty")
      }
      
      # Validate minimum number of criteria (at least 1)
      if (length(self$task_data$crit) < 1) {
        stop("At least 1 criterion is required")
      }
      
      # Validate minimum number of alternatives (at least 2 for comparison)
      if (length(self$task_data$alt) < 2) {
        stop("At least 2 alternatives are required for comparison")
      }
      
      # Validate perf matrix dimensions (if provided)
      if (!is.null(self$task_data$perf)) {
        perf <- as.matrix(self$task_data$perf)
        if (nrow(perf) != length(self$task_data$alt)) {
          stop("perf nrow must match length of alt")
        }
        if (ncol(perf) != length(self$task_data$crit)) {
          stop("perf ncol must match length of crit")
        }
      }
      
      # Validate each data type in task_data individually (only if present)
      if (!is.null(self$task_data$perf)) {
        private$validate_perf()
      }
      
      if (!is.null(self$task_data$weight)) {
        private$validate_weight()
      }
      
      # Validate weight and direction length consistency (if both provided)
      # This check must come BEFORE validate_direction() because validate_direction()
      # will set default direction if missing, which would mask the length mismatch error
      if (!is.null(self$task_data$weight) && !is.null(self$task_data$direction)) {
        if (length(self$task_data$weight) != length(self$task_data$direction)) {
          stop(sprintf(
            "weight and direction must have the same length. weight length: %d, direction length: %d",
            length(self$task_data$weight), length(self$task_data$direction)
          ))
        }
      }
      
      # Always validate direction (will set default if missing)
      private$validate_direction()
      
      if (!is.null(self$task_data$pair_crit)) {
        private$validate_pair_crit()
      }
      
      if (!is.null(self$task_data$pair_alt)) {
        private$validate_pair_alt()
      }
      
      # Validate consistency between pair_crit and pair_alt (for AHP)
      if (!is.null(self$task_data$pair_crit) && !is.null(self$task_data$pair_alt)) {
        pair_crit_dim <- nrow(self$task_data$pair_crit)
        pair_alt_length <- length(self$task_data$pair_alt)
        if (pair_alt_length != pair_crit_dim) {
          stop(sprintf(
            "pair_alt list length (%d) must match pair_crit matrix dimension (%d) for AHP method",
            pair_alt_length, pair_crit_dim
          ))
        }
      }
      
      # Validate type field
      stopifnot(!is.null(self$type))
      invisible(self)
    },

    #' @description Get number of alternatives
    #' @return Integer count of alternatives.
    n_alt = function() length(self$task_data$alt),

    #' @description Get number of criteria
    #' @return Integer count of criteria.
    n_crit = function() length(self$task_data$crit),

    #' @description Get performance matrix or single performance value
    #' @param alt_name Optional. Alternative name for single value lookup.
    #' @param crit_name Optional. Criterion name for single value lookup.
    #' @return If no arguments: full performance matrix. If both arguments provided: single numeric value.
    #' @examples
    #' task$get_perf()  # Get full matrix
    #' task$get_perf("A1", "C1")  # Get single value
    get_perf = function(alt_name = NULL, crit_name = NULL) {
      perf <- self$task_data$perf
      if (is.null(perf)) {
        stop("Performance matrix (perf) is not available in task_data")
      }
      
      # If no arguments, return full matrix
      if (is.null(alt_name) && is.null(crit_name)) {
        return(perf)
      }
      # If both arguments provided, return single value
      if (!is.null(alt_name) && !is.null(crit_name)) {
        alt_idx <- match(alt_name, self$task_data$alt)
        crit_idx <- match(crit_name, self$task_data$crit)
        if (is.na(alt_idx)) {
          stop(sprintf("alternative '%s' not found", alt_name))
        }
        if (is.na(crit_idx)) {
          stop(sprintf("criterion '%s' not found", crit_name))
        }
        return(perf[alt_idx, crit_idx])
      }
      stop("get_perf() requires either no arguments (full matrix) or both alt_name and crit_name (single value)")
    },

    #' @description Get alternative names
    #' @return Character vector of alternative names.
    alt_names = function() self$task_data$alt,

    #' @description Get criterion names
    #' @return Character vector of criterion names.
    crit_names = function() self$task_data$crit
  ),

  private = list(
    get_allowed_fields = function() {
      c("alt", "crit", "perf", "weight", "direction", 
        "pair_crit", "pair_alt", "cat_names", "cat_count", 
        "prof", "prof_order", "judge_alt_profile")
    },
    
    validate_field_names = function(data_list) {
      allowed_fields <- private$get_allowed_fields()
      provided_fields <- names(data_list)
      invalid_fields <- provided_fields[!provided_fields %in% allowed_fields]
      
      if (length(invalid_fields) > 0) {
        stop(sprintf(
          "Invalid field name(s): %s. Allowed fields are: %s",
          paste(invalid_fields, collapse = ", "),
          paste(allowed_fields, collapse = ", ")
        ))
      }
    },
    
    validate_perf = function() {
      perf <- self$task_data$perf
      if (is.null(perf)) return(invisible(self))
      
      # Validate dimensions
      if (nrow(perf) != length(self$task_data$alt)) {
        stop("perf nrow must match length of alt")
      }
      if (ncol(perf) != length(self$task_data$crit)) {
        stop("perf ncol must match length of crit")
      }
      
      # Validate data type and values
      if (!is.numeric(perf)) stop("perf must be numeric matrix")
      if (anyNA(perf)) stop("perf contains NA/NaN")
      if (!all(is.finite(perf))) stop("perf contains non-finite values (Inf/-Inf)")
      
      # Validate row and column names if provided
      if (!is.null(rownames(perf)) && !all(rownames(perf) == "")) {
        if (!all(rownames(perf) %in% self$task_data$alt)) {
          stop("perf rownames must match alt names")
        }
      }
      if (!is.null(colnames(perf)) && !all(colnames(perf) == "")) {
        if (!all(colnames(perf) %in% self$task_data$crit)) {
          stop("perf colnames must match crit names")
        }
      }
      
      invisible(self)
    },
    
    validate_weight = function() {
      weight <- self$task_data$weight
      if (is.null(weight)) return(invisible(self))
      
      # Validate basic properties
      if (length(weight) != length(self$task_data$crit)) {
        stop("weight length must match criteria")
      }
      if (anyNA(weight)) stop("weight contains NA")
      if (!is.numeric(weight)) stop("weight must be numeric")
      if (!all(weight > 0)) stop("weight must be positive")
      
      # Validate normalization (sum should be 1)
      weight_sum <- sum(weight)
      if (abs(weight_sum - 1) > 1e-8) {
        stop(sprintf(
          "weight must be normalized (sum = 1). Current sum = %.10f. Please normalize the weights.",
          weight_sum
        ))
      }
      
      invisible(self)
    },
    
    validate_direction = function() {
      direction <- self$task_data$direction
      if (is.null(direction)) {
        # Default to all "max" if not provided
        self$task_data$direction <- as.character(rep("max", length(self$task_data$crit)))
        return(invisible(self))
      }
      
      # Ensure direction is a pure character vector
      direction <- as.character(direction)
      
      # Validate directions if provided
      if (length(direction) != length(self$task_data$crit)) {
        stop("direction length must match criteria")
      }
      if (anyNA(direction)) stop("direction contains NA")
      if (!all(direction %in% c("max", "min"))) {
        stop("direction only allow 'max' or 'min'")
      }
      
      # Store back as pure character vector
      self$task_data$direction <- direction
      
      invisible(self)
    },

    validate_pair_crit = function() {
      pair_crit <- self$task_data$pair_crit
      if (is.null(pair_crit)) return(invisible(self))
      
      # Validate type and structure
      if (!is.matrix(pair_crit)) stop("pair_crit must be a matrix")
      if (!is.numeric(pair_crit)) stop("pair_crit must be numeric")
      if (nrow(pair_crit) != ncol(pair_crit)) {
        stop("pair_crit must be a square matrix")
      }
      if (nrow(pair_crit) != length(self$task_data$crit)) {
        stop(sprintf("pair_crit dimensions (%dx%d) must match number of criteria (%d)",
                     nrow(pair_crit), ncol(pair_crit), length(self$task_data$crit)))
      }
      
      # Validate values
      if (anyNA(pair_crit)) stop("pair_crit contains NA/NaN")
      if (!all(is.finite(pair_crit))) stop("pair_crit contains non-finite values (Inf/-Inf)")
      
      # AHP-specific validations
      # 1. All values must be positive (AHP requirement)
      if (any(pair_crit <= 0)) {
        stop("pair_crit contains non-positive values. AHP requires all pairwise comparison values to be > 0")
      }
      
      # 2. Diagonal elements should be 1
      diag_vals <- diag(pair_crit)
      if (!all(abs(diag_vals - 1) < 1e-10)) {
        stop("pair_crit diagonal elements must be 1 (AHP requirement)")
      }
      
      # 3. Check reciprocity: a_ij * a_ji should equal 1 (allow small numerical error)
      n <- nrow(pair_crit)
      for (i in seq_len(n)) {
        for (j in seq_len(n)) {
          if (i != j) {
            product <- pair_crit[i, j] * pair_crit[j, i]
            if (abs(product - 1) > 1e-6) {
              stop(sprintf(
                "pair_crit violates reciprocity: A[%d,%d] * A[%d,%d] = %.10f (expected 1.0). AHP requires reciprocal pairs.",
                i, j, j, i, product
              ))
            }
          }
        }
      }
      
      invisible(self)
    },
    
    validate_pair_alt = function() {
      pair_alt <- self$task_data$pair_alt
      if (is.null(pair_alt)) return(invisible(self))
      
      # Validate type and structure
      if (!is.list(pair_alt)) stop("pair_alt must be a list")
      if (length(pair_alt) != length(self$task_data$crit)) {
        stop(sprintf("pair_alt must have length equal to number of criteria (%d), got %d",
                     length(self$task_data$crit), length(pair_alt)))
      }
      
      # Validate each matrix element (following pair_crit validation pattern)
      for (i in seq_along(pair_alt)) {
        mat <- pair_alt[[i]]
        
        # Check if element is NULL
        if (is.null(mat)) {
          stop(sprintf("pair_alt[[%d]] is NULL", i))
        }
        
        # Validate type and structure (following pair_crit pattern)
        if (!is.matrix(mat)) {
          stop(sprintf("pair_alt[[%d]] must be a matrix", i))
        }
        if (!is.numeric(mat)) {
          stop(sprintf("pair_alt[[%d]] must be numeric", i))
        }
        if (nrow(mat) != ncol(mat)) {
          stop(sprintf("pair_alt[[%d]] must be a square matrix", i))
        }
        if (nrow(mat) != length(self$task_data$alt)) {
          stop(sprintf("pair_alt[[%d]] dimensions (%dx%d) must match number of alternatives (%d)",
                       i, nrow(mat), ncol(mat), length(self$task_data$alt)))
        }
        
        # Validate values (following pair_crit pattern)
        if (anyNA(mat)) {
          stop(sprintf("pair_alt[[%d]] contains NA/NaN", i))
        }
        if (!all(is.finite(mat))) {
          stop(sprintf("pair_alt[[%d]] contains non-finite values (Inf/-Inf)", i))
        }
        
        # AHP-specific validations (same as pair_crit)
        # 1. All values must be positive (AHP requirement)
        if (any(mat <= 0)) {
          stop(sprintf("pair_alt[[%d]] contains non-positive values. AHP requires all pairwise comparison values to be > 0", i))
        }
        
        # 2. Diagonal elements should be 1
        diag_vals <- diag(mat)
        if (!all(abs(diag_vals - 1) < 1e-10)) {
          stop(sprintf("pair_alt[[%d]] diagonal elements must be 1 (AHP requirement)", i))
        }
        
        # 3. Check reciprocity: a_ij * a_ji should equal 1 (allow small numerical error)
        n_alt <- nrow(mat)
        for (ii in seq_len(n_alt)) {
          for (jj in seq_len(n_alt)) {
            if (ii != jj) {
              product <- mat[ii, jj] * mat[jj, ii]
              if (abs(product - 1) > 1e-6) {
                stop(sprintf(
                  "pair_alt[[%d]] violates reciprocity: A[%d,%d] * A[%d,%d] = %.10f (expected 1.0). AHP requires reciprocal pairs.",
                  i, ii, jj, jj, ii, product
                ))
              }
            }
          }
        }
      }
      
      invisible(self)
    }
  )
)

