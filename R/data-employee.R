#' Employee Performance AHPSort Dataset
#'
#' @description
#' A toy dataset for AHPSort (AHP-based sorting) tasks.
#' Contains 4 employee alternatives evaluated on 3 criteria using pairwise comparison matrices
#' and long-format comparison data for sorting into performance categories.
#' This dataset represents an employee performance evaluation scenario in human resource management.
#'
#' @format A list with the following components:
#' \describe{
#'   \item{alt}{Character vector. Alternative names: "Employee_1" through "Employee_4"}
#'   \item{crit}{Character vector. Criterion names: "Productivity", "Teamwork", "Innovation"}
#'   \item{cat_names}{Character vector. Category names: c("Poor", "Average", "Good")}
#'   \item{pair_crit}{Numeric matrix (3 x 3). Pairwise comparison matrix for criteria.
#'     Values represent the relative importance of row criterion over column criterion.
#'     Must have rownames and colnames matching \code{crit}.}
#'   \item{judge_alt_profile}{Data.frame. Long-format pairwise comparison data between
#'     alternatives and profiles. Contains columns:
#'     \itemize{
#'       \item \code{criterion}: Criterion name
#'       \item \code{alt}: Alternative name
#'       \item \code{profile}: Profile name (internal names: p1, p2)
#'       \item \code{value}: Comparison value (AHP scale)
#'     }}
#'   \item{prof_order}{Character vector. Profile order: c("p1", "p2")}
#' }
#'
#' @details
#' This dataset is designed for demonstrating AHPSort sorting tasks using
#' \code{DeciderAHP}. The scenario involves classifying employees into performance categories
#' based on:
#' \itemize{
#'   \item **Productivity**: Work output and efficiency (most important criterion)
#'   \item **Innovation**: Creativity and problem-solving ability (second most important)
#'   \item **Teamwork**: Collaboration and team contribution
#' }
#'
#' The dataset includes three performance categories:
#' \itemize{
#'   \item **Poor**: Below average performance
#'   \item **Average**: Meets basic expectations
#'   \item **Good**: Exceeds expectations
#' }
#'
#' The \code{judge_alt_profile} data.frame contains comparisons between each employee
#' and two limiting profiles (p1: Poor-Average boundary, p2: Average-Good boundary)
#' for each criterion. The comparison values follow the AHP scale where:
#' \itemize{
#'   \item Value < 1: Employee performs worse than profile (assigned to lower category)
#'   \item Value > 1: Employee performs better than profile (assigned to higher category)
#' }
#'
#' Employee performance profiles (based on comparisons):
#' \itemize{
#'   \item **Employee_1**: Poor productivity, Average teamwork, Good innovation
#'   \item **Employee_2**: Average productivity, Good teamwork, Average innovation
#'   \item **Employee_3**: Good productivity, Poor teamwork, Good innovation
#'   \item **Employee_4**: Average-Good productivity, Average teamwork, Poor innovation
#' }
#'
#' @examples
#' data(employee, package = "mcdaHub")
#'
#' # AHPSort sorting example
#' decider <- DeciderAHP$new()
#' task <- TaskSorting$new(
#'   alt = employee$alt,
#'   crit = employee$crit,
#'   cat_names = employee$cat_names,
#'   pair_crit = employee$pair_crit,
#'   judge_alt_profile = employee$judge_alt_profile,
#'   prof_order = employee$prof_order,
#'   assign_rule = "pessimistic"
#' )
#' result <- decider$solve(task)
#'
#' @seealso \code{\link{supplier}} for AHP ranking/choice tasks.
#'   \code{\link{DeciderAHP}} for AHP algorithm implementation.
#'
#' @source Created for mcdaHub package demonstration purposes
#'
#' @keywords datasets
"employee"

