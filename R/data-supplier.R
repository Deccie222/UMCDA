#' Supplier Selection AHP Dataset
#'
#' @description
#' A toy dataset for AHP (Analytic Hierarchy Process) ranking and choice tasks.
#' Contains 3 supplier alternatives evaluated on 3 criteria using pairwise comparison matrices.
#' This dataset represents a supplier selection scenario in procurement decision-making.
#'
#' @format A list with the following components:
#' \describe{
#'   \item{alt}{Character vector. Alternative names: "Supplier_A", "Supplier_B", "Supplier_C"}
#'   \item{crit}{Character vector. Criterion names: "Quality", "Price", "Delivery"}
#'   \item{pair_crit}{Numeric matrix (3 x 3). Pairwise comparison matrix for criteria.
#'     Values represent the relative importance of row criterion over column criterion.
#'     Must have rownames and colnames matching \code{crit}.}
#'   \item{pair_alt}{List of numeric matrices. Pairwise comparison matrices for alternatives
#'     under each criterion. List length equals number of criteria. Each matrix is (3 x 3)
#'     with rownames and colnames matching \code{alt}.}
#' }
#'
#' @details
#' This dataset is designed for demonstrating AHP ranking and choice tasks using
#' \code{DeciderAHP}. The scenario involves selecting the best supplier based on:
#' \itemize{
#'   \item **Quality**: Product/service quality (most important criterion)
#'   \item **Price**: Cost considerations (second most important)
#'   \item **Delivery**: Delivery time and reliability
#' }
#'
#' The pairwise comparison matrices follow the AHP scale:
#' \itemize{
#'   \item 1 = Equal importance
#'   \item 2 = Slightly more important
#'   \item 3 = Moderately more important
#'   \item 4 = Strongly more important
#'   \item 5 = Extremely more important
#'   \item Values < 1 indicate the column element is more important
#' }
#'
#' Supplier characteristics (based on pairwise comparisons):
#' \itemize{
#'   \item **Supplier_A**: High quality, high price, good delivery
#'   \item **Supplier_B**: Good quality, medium price, excellent delivery
#'   \item **Supplier_C**: Low quality, low price, slow delivery
#' }
#'
#' @examples
#' data(supplier, package = "mcdaHub")
#'
#' # Ranking example
#' decider <- DeciderAHP$new()
#' task <- TaskRanking$new(
#'   alt = supplier$alt,
#'   crit = supplier$crit,
#'   pair_crit = supplier$pair_crit,
#'   pair_alt = supplier$pair_alt
#' )
#' result <- decider$solve(task)
#'
#' # Choice example
#' task_choice <- TaskChoice$new(
#'   alt = supplier$alt,
#'   crit = supplier$crit,
#'   pair_crit = supplier$pair_crit,
#'   pair_alt = supplier$pair_alt
#' )
#' result_choice <- decider$solve(task_choice)
#'
#' @seealso \code{\link{employee}} for AHPSort sorting tasks.
#'   \code{\link{DeciderAHP}} for AHP algorithm implementation.
#'
#' @source Created for mcdaHub package demonstration purposes
#'
#' @keywords datasets
"supplier"

