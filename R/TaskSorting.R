#' TaskSorting Class
#'
#' @description
#' A class for defining sorting-type MCDA tasks.
#' Supports both traditional sorting (with \code{prof} matrix) and AHPSort
#' (with \code{judge_alt_profile}).
#' \code{TaskSorting} is used to define sorting tasks where alternatives are
#' assigned to predefined categories. It supports:
#' \itemize{
#'   \item Traditional sorting methods (TOPSIS, PROMETHEE) using a profile matrix
#'   \item AHPSort method using pairwise comparison data in long format
#' }
#'
#' @details
#' For traditional sorting, provide:
#' \itemize{
#'   \item \code{alt}, \code{crit}: Basic MCDA components
#'   \item \code{cat_names}: Category names (e.g., \code{c("Low", "Medium", "High")})
#'   \item \code{prof}: Numeric matrix (profiles × criteria)
#' }
#'
#' For AHPSort, provide:
#' \itemize{
#'   \item \code{alt}, \code{crit}: Basic MCDA components
#'   \item \code{cat_names}: Category names
#'   \item \code{pair_crit}: Pairwise comparison matrix for criteria
#'   \item \code{judge_alt_profile}: Long-format data.frame with columns
#'     \code{criterion}, \code{alt}, \code{profile}, \code{value}
#' }
#'
#' The \code{internal_profiles} field is automatically generated from \code{cat_names}
#' as \code{c("p1", "p2", ..., "p(n-1)")} where n is the number of categories.
#'
#' @field cat_names Character vector. Category names (e.g., \code{c("Low", "Medium", "High")}).
#'   Must have at least 2 categories.
#' @field prof Numeric matrix or NULL. Profile matrix (profiles × criteria).
#'   Optional for AHPSort, required for traditional sorting.
#' @field assign_rule Character string. Assignment rule: \code{"pessimistic"} (default)
#'   or \code{"optimistic"}.
#' @field judge_alt_profile Data.frame or NULL. Long-format data for AHPSort with columns:
#'   \code{criterion}, \code{alt}, \code{profile}, \code{value}.
#'   Optional for traditional sorting, required for AHPSort.
#' @field internal_profiles Character vector. Auto-generated profile names
#'   (e.g., \code{c("p1", "p2", "p3")}). Automatically created from \code{cat_names}.
#'
#' @param ... Named arguments passed to \code{TaskDecision$initialize()}.
#'   Must include at least \code{alt} and \code{crit}.
#' @param cat_names Character vector. Category names. Must be unique and non-NA.
#' @param prof Numeric matrix or NULL. Profile matrix. If provided, must be a numeric matrix
#'   with \code{nrow(prof) == length(cat_names) - 1} and \code{ncol(prof) == length(crit)}.
#' @param assign_rule Character string. Assignment rule: \code{"pessimistic"} or \code{"optimistic"}.
#'   Default: \code{"pessimistic"}.
#' @param judge_alt_profile Data.frame or NULL. Long-format data for AHPSort.
#'   Must contain columns: \code{criterion}, \code{alt}, \code{profile}, \code{value}.
#'   The \code{profile} column must use values from \code{internal_profiles} (p1, p2, ...).
#'
#' @return A \code{TaskSorting} object.
#'
#' @export
#'
#' @seealso \code{\link{TaskDecision}} for base class methods and fields.
#'   \code{\link{DeciderAHP}} for AHPSort algorithm implementation.
#'   \code{\link{DeciderTOPSIS}}, \code{\link{DeciderPROMETHEE}} for traditional sorting methods.
#'
#' @examples
#' \dontrun{
#' # Traditional sorting task using cars dataset
#' data(cars, package = "mcdaHub")
#' task <- TaskSorting$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction,
#'   cat_names = cars$cat_names,
#'   prof = cars$prof,
#'   assign_rule = "pessimistic"
#' )
#' 
#' # AHPSort task using investment_ahpsort dataset
#' data(investment_ahpsort, package = "mcdaHub")
#' task_ahp <- TaskSorting$new(
#'   alt = investment_ahpsort$alt,
#'   crit = investment_ahpsort$crit,
#'   cat_names = investment_ahpsort$cat_names,
#'   pair_crit = investment_ahpsort$pair_crit,
#'   judge_alt_profile = investment_ahpsort$judge_alt_profile,
#'   prof_order = investment_ahpsort$prof_order,
#'   assign_rule = "pessimistic"
#' )
#' }
TaskSorting <- R6::R6Class(
  "TaskSorting",
  inherit = TaskDecision,

  public = list(
    cat_names = NULL,
    prof = NULL,
    assign_rule = NULL,
    judge_alt_profile = NULL,
    internal_profiles = NULL,

    #' @description
    #' Create a new TaskSorting object
    #'
    #' @param ... Named arguments passed to TaskDecision$initialize().
    #'   Must include at least alt and crit.
    #' @param cat_names Character vector. Category names. Must be unique and non-NA.
    #' @param prof Numeric matrix or NULL. Profile matrix. If provided, must be a numeric matrix.
    #' @param assign_rule Character string. Assignment rule: "pessimistic" or "optimistic".
    #'   Default: "pessimistic".
    #' @param judge_alt_profile Data.frame or NULL. Long-format data for AHPSort.
    #'
    #' @return A TaskSorting object.
    initialize = function(...,
                          cat_names = NULL,
                          prof = NULL,
                          assign_rule = c("pessimistic", "optimistic"),
                          judge_alt_profile = NULL) {

      dots <- list(...)
      
      dots$cat_names <- cat_names %||% dots$cat_names
      # For prof: if explicitly provided as parameter (even as NULL), use it
      # This allows explicit NULL to override any prof in dots (needed for AHPSort)
      if (!missing(prof)) {
        dots$prof <- prof  # Explicitly provided prof (even if NULL) overrides dots$prof
      }
      # If prof parameter not provided, dots$prof (if exists) will be used
      dots$judge_alt_profile <- judge_alt_profile %||% dots$judge_alt_profile

      do.call(super$initialize, c(dots, list(type = "sorting")))

      self$assign_rule <- match.arg(assign_rule)

      # Step 1: Category names (required)
      if (is.null(self$task_data$cat_names)) {
        stop("cat_names must be provided for sorting tasks")
      }
      self$cat_names <- self$task_data$cat_names

      # Step 2: Auto-generate internal profiles (p1, p2, p3, ...)
      n_prof <- length(self$cat_names) - 1
      if (n_prof < 1) stop("At least 2 categories are required")
      self$internal_profiles <- paste0("p", seq_len(n_prof))

      # Step 3: User-provided prof (optional for traditional sorting)
      # prof must be a matrix if provided, no type conversion
      if (is.null(self$task_data$prof)) {
        self$prof <- NULL
      } else {
        # prof is provided - must be a matrix
        if (!is.matrix(self$task_data$prof)) {
          stop("prof must be a matrix. No automatic type conversion is performed.")
        }
        # Check if numeric
        if (!is.numeric(self$task_data$prof)) {
          stop("prof must be a numeric matrix")
        }
        self$prof <- self$task_data$prof
      }
      
      # Step 4: judge_alt_profile (AHPSort)
      self$judge_alt_profile <- self$task_data$judge_alt_profile

      private$validate_sorting()
    }
  ),

  private = list(
    validate_sorting = function() {
      
      # Step 1: Validate category names
      if (!is.character(self$cat_names) ||
          anyNA(self$cat_names) ||
          anyDuplicated(self$cat_names)) {
        stop("cat_names must be unique, non-NA character vector")
        }

      # Step 2: Validate internal profiles generation
      if (length(self$internal_profiles) != length(self$cat_names) - 1) {
        stop("Internal profile generation failed")
      }

      # Step 3: Validate judge_alt_profile (AHPSort)
      jap <- self$judge_alt_profile
      if (!is.null(jap)) {

        required_cols <- c("criterion", "alt", "profile", "value")
        if (!all(required_cols %in% colnames(jap))) {
          stop("judge_alt_profile must contain: criterion, alt, profile, value")
        }

        # Profile column must use internal profiles (p1, p2, p3, ...)
        if (!all(jap$profile %in% self$internal_profiles)) {
          stop(sprintf(
            "judge_alt_profile$profile must use internal profiles: %s",
            paste(self$internal_profiles, collapse = ", ")
          ))
        }

        # Completeness check: all combinations must be present
        expected <- expand.grid(
          criterion = self$task_data$crit,
          alt = self$task_data$alt,
          profile = self$internal_profiles,
          stringsAsFactors = FALSE
        )

        jap_key <- paste(jap$criterion, jap$alt, jap$profile)
        exp_key <- paste(expected$criterion, expected$alt, expected$profile)

        missing <- setdiff(exp_key, jap_key)
        if (length(missing) > 0) {
          stop("judge_alt_profile is missing required comparisons")
        }
      }

      # Step 4: Validate prof (optional for traditional sorting)
      if (!is.null(self$prof)) {
        # prof should already be validated as matrix in initialize()
        # Just check dimensions here

        if (nrow(self$prof) != length(self$internal_profiles)) {
          stop("prof must have one row per internal profile (p1,p2,p3...)")
        }

        rownames(self$prof) <- self$internal_profiles

        if (ncol(self$prof) != length(self$task_data$crit)) {
          stop("prof must have one column per criterion")
        }
      }

      # Step 5: At least one of prof or judge_alt_profile must be provided
      if (is.null(self$prof) && is.null(self$judge_alt_profile)) {
        stop("Either prof or judge_alt_profile must be provided")
      }

      invisible(self)
    }
  )
)
