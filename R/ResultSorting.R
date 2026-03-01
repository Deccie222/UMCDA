#' ResultSorting Class
#'
#' @description
#' A class for storing and displaying sorting task results.
#' \code{ResultSorting} stores the results of a sorting task, including:
#' \itemize{
#'   \item Raw scores for each alternative
#'   \item Assigned categories for each alternative
#'   \item A sorting table combining scores and categories
#' }
#'
#' Categories are assigned based on profile flows and the assignment rule
#' (pessimistic or optimistic) specified in the task.
#'
#' @field categories Named character vector. Category assignments for each alternative.
#'   Names are alternative names, values are category names.
#' @field sorting_table Data.frame. A table with columns:
#'   \code{alt} (alternative name), \code{value} (score), \code{category} (assigned category).
#'
#' @param raw_result Numeric vector. Raw scores for each alternative.
#'   Must be named with alternative names.
#' @param metadata List. Metadata from the decider, including:
#'   \itemize{
#'     \item \code{task}: The \code{TaskSorting} object
#'     \item \code{prof_flow}: Profile flow scores (named vector)
#'     \item Other algorithm-specific metadata
#'   }
#'
#' @return A \code{ResultSorting} object.
#'
#' @export
#'
#' @seealso \code{\link{TaskResult}} for base class methods and fields.
#'   \code{\link{TaskSorting}} for creating sorting tasks.
#'
#' @examples
#' # Create a sorting task and solve it
#' task <- TaskSorting$new(
#'   alt = c("A1", "A2", "A3"),
#'   crit = c("Cost", "Quality"),
#'   cat_names = c("Low", "Medium", "High"),
#'   prof = matrix(c(10, 20, 30, 40), nrow = 2, ncol = 2),
#'   perf = matrix(c(100, 200, 150, 8, 9, 7), nrow = 3, ncol = 2),
#'   weight = c(0.5, 0.5),
#'   direction = c("min", "max")
#' )
#'
#' decider <- DeciderTOPSIS$new()
#' result <- decider$solve(task)
#'
#' # Access results
#' result$categories
#' result$sorting_table
#' print(result)
ResultSorting <- R6::R6Class(
  "ResultSorting",
  inherit = TaskResult,

  public = list(
    categories = NULL,
    sorting_table = NULL,

    #' @description
    #' Create a new ResultSorting object
    #'
    #' @param raw_result Named numeric vector. Raw algorithm results (one value per alternative).
    #' @param metadata List. Task and algorithm-specific state information. Must contain:
    #'   \itemize{
    #'     \item \code{task}: The TaskSorting object
    #'     \item \code{prof_flow}: Profile flow scores (named vector)
    #'   }
    #'
    #' @return A ResultSorting object.
    initialize = function(raw_result, metadata = list()) {

      super$initialize("sorting", raw_result, metadata)

      vals <- as.numeric(raw_result)
      alts <- names(raw_result)

      if (is.null(alts) || any(alts == "")) {
        stop("ResultSorting requires named raw_result with non-empty alternative names")
      }

      categories <- private$assign_categories(raw_result, metadata)
      self$categories <- categories

      df <- data.frame(
        alt = alts,
        value = vals,
        stringsAsFactors = FALSE
      )

      if (!is.null(categories)) {
        df$category <- categories[alts]
      }

      rownames(df) <- NULL
      self$sorting_table <- df
    },

    #' @description
    #' Print sorting results
    #'
    #' @param ... Additional arguments passed to print methods.
    #'
    #' @return Invisibly returns self.
    print = function(...) {
      cat("ResultSorting\n")
      print(self$sorting_table)
    }
  ),

  private = list(

    assign_categories = function(raw_result, metadata) {

      task <- metadata$task
      if (is.null(task) || !inherits(task, "TaskSorting")) {
        return(NULL)
      }

      prof_flow <- metadata$prof_flow
      if (is.null(prof_flow)) {
        return(NULL)
      }

      cat_names <- task$task_data$cat_names
      internal_profiles <- task$internal_profiles  # Auto-generated profiles (p1, p2, p3...)
      assign_rule <- task$assign_rule  # assign_rule is an instance field, not in task_data

      # ---- Step 1: reorder profiles according to internal_profiles ----
      # Ensure prof_flow names match internal_profiles
      if (!all(internal_profiles %in% names(prof_flow))) {
        stop("prof_flow names do not match internal_profiles")
      }
      prof_flow <- prof_flow[internal_profiles]

      # ---- Step 2: Category assignment based on profile flows ----
      # This logic is used by all sorting methods (TOPSIS, PROMETHEE, AHPSort)
      # categories: C1 (best), C2, ..., Cn (worst)
      # profiles: p1 (best boundary), p2, ..., p(n-1)

      n_cat <- length(cat_names)
      n_prof <- length(prof_flow)

      if (n_prof != n_cat - 1) {
        stop(sprintf("Number of profiles (%d) must equal number_of_categories - 1 (%d) for sorting tasks.",
                     n_prof, n_cat - 1))
      }

      categories <- character(length(raw_result))
      names(categories) <- names(raw_result)

      for (i in seq_along(raw_result)) {

        score <- raw_result[i]

        if (assign_rule == "pessimistic") {

          # find highest category whose profile <= score
          assigned <- n_cat  # default worst category

          for (p in seq_len(n_prof)) {
            if (score >= prof_flow[p]) {
              assigned <- p
              break
            }
          }

          categories[i] <- cat_names[assigned]

        } else if (assign_rule == "optimistic") {

          # find first category whose profile >= score
          assigned <- 1  # default best category

          for (p in seq_len(n_prof)) {
            if (score < prof_flow[p]) {
              assigned <- p + 1
              break
            }
          }

          categories[i] <- cat_names[assigned]
        }
      }

      return(categories)
    }
  )
)
