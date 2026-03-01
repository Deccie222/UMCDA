#' Cars Dataset
#'
#' @description
#' A toy dataset for Multi-Criteria Decision Analysis tasks (ranking, choice, sorting).
#' Contains 5 car alternatives evaluated on 3 criteria: Price, Consumption, and Power.
#'
#' @format A list with the following components:
#' \describe{
#'   \item{alt}{Character vector. Alternative names: "Economic", "Sport", "Luxury", "TouringA", "TouringB"}
#'   \item{crit}{Character vector. Criterion names: "Price", "Consumption", "Power"}
#'   \item{perf}{Numeric matrix. Performance matrix (5 x 3) with rownames as alternatives and colnames as criteria}
#'   \item{weight}{Numeric vector. Weights for criteria: c(0.4, 0.3, 0.3)}
#'   \item{direction}{Character vector. Optimization direction: c("min", "min", "max")}
#'   \item{cat_names}{Character vector. Category names for sorting: c("bad", "good")}
#'   \item{prof}{Numeric matrix. Limiting profile matrix (1 x 3) for FlowSort sorting}
#' }
#'
#' @details
#' This dataset is designed for demonstrating ranking, choice, and sorting tasks
#' using various MCDA algorithms (TOPSIS, PROMETHEE, etc.).
#'
#' - **Price**: Lower is better (min)
#' - **Consumption**: Lower is better (min)
#' - **Power**: Higher is better (max)
#'
#' The dataset includes a limiting profile for sorting tasks with two categories:
#' "bad" and "good".
#'
#' @examples
#' data(cars, package = "mcdaHub")
#'
#' # Ranking example
#' decider <- DeciderTOPSIS$new()
#' task <- TaskRanking$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
#' result <- decider$solve(task)
#'
#' # Choice example
#' task_choice <- TaskChoice$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction
#' )
#' result_choice <- decider$solve(task_choice)
#'
#' # Sorting example
#' task_sorting <- TaskSorting$new(
#'   alt = cars$alt,
#'   crit = cars$crit,
#'   perf = cars$perf,
#'   weight = cars$weight,
#'   direction = cars$direction,
#'   cat_names = cars$cat_names,
#'   prof = cars$prof
#' )
#' result_sorting <- decider$solve(task_sorting)
#'
#' @source Created for mcdaHub package demonstration purposes
#'
#' @keywords datasets
"cars"

