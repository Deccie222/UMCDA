TaskDecision <- R6::R6Class(
  "TaskDecision",
  public = list(
    crit = NULL,      # criteria
    alt = NULL,       # alternatives
    perf = NULL,      # performance matrix
    w = NULL,         # weights (numeric, positive, sum to 1)
    d = NULL,         # directions (vector of "max"/"min")
    type = NULL,      # problem type

    initialize = function(alt, crit, perf,
                          w = NULL,
                          d = NULL,
                          type = c("ranking", "sorting", "choice"),
                          normalize_weights = TRUE) {
      self$alt <- alt
      self$crit <- crit

      perf <- as.matrix(perf)

      if (nrow(perf) == length(alt) && ncol(perf) == length(crit)) {
        rownames(perf) <- alt
        colnames(perf) <- crit
      } else {
        stop("perf dimensions do not match alt/crit")
      }

      self$perf <- perf
      self$w <- w
      self$d <- d
      self$type <- match.arg(type)

      self$validate(normalize_weights = normalize_weights)
    },

    validate = function(normalize_weights = TRUE) {
      stopifnot(nrow(self$perf) == length(self$alt))
      stopifnot(ncol(self$perf) == length(self$crit))

      if (!is.numeric(self$perf)) stop("perf must be numeric matrix")
      if (anyNA(self$perf)) stop("perf contains NA/NaN")
      if (!all(is.finite(self$perf))) stop("perf contains non-finite values (Inf/-Inf)")

      if (anyDuplicated(self$alt) > 0 || any(self$alt == "")) stop("alternatives must be unique and non-empty")
      if (anyDuplicated(self$crit) > 0 || any(self$crit == "")) stop("criteria must be unique and non-empty")

      if (!is.null(self$d)) {
        if (length(self$d) != length(self$crit)) stop("directions length must match criteria")
        if (anyNA(self$d)) stop("directions contain NA")
        if (!all(self$d %in% c("max", "min"))) stop("directions only allow 'max' or 'min'")
      }

      if (!is.null(self$w)) {
        if (length(self$w) != length(self$crit)) stop("weights length must match criteria")
        if (anyNA(self$w)) stop("weights contain NA")
        if (!is.numeric(self$w)) stop("weights must be numeric")
        if (!all(self$w > 0)) stop("weights must be positive")
        s <- sum(self$w)
        if (!is.finite(s) || s <= 0) stop("weights sum must be finite positive")
        if (normalize_weights) {
          self$w <- self$w / s
        } else {
          if (abs(s - 1) > 1e-8) stop("weights not normalized (sum != 1) and normalize_weights = FALSE")
        }
      }

      stopifnot(!is.null(self$type))
      invisible(self)
    },

    n_alt = function() length(self$alt),
    n_crit = function() length(self$crit),

    get_perf = function() self$perf,

    update_perf = function(perf, normalize_weights = TRUE) {
      perf <- as.matrix(perf)
      if (nrow(perf) == length(self$alt) && ncol(perf) == length(self$crit)) {
        rownames(perf) <- self$alt
        colnames(perf) <- self$crit
      } else if (nrow(perf) == length(self$crit) && ncol(perf) == length(self$alt)) {
        perf <- t(perf)
        rownames(perf) <- self$alt
        colnames(perf) <- self$crit
        message("perf input is criteria × alternatives, auto-transposed to alternatives × criteria")
      } else {
        stop("perf dimensions do not match alt/crit")
      }
      self$perf <- perf
      self$validate(normalize_weights = normalize_weights)
      invisible(self)
    },

    alt_names = function() self$alt,
    crit_names = function() self$crit,

    subset_alt = function(selected_alt) {
      idx <- match(selected_alt, self$alt)
      if (any(is.na(idx))) stop("subset_alt contains non-existent alternative")
      self$perf[idx, , drop = FALSE]
    },

    subset_crit = function(selected_crit) {
      idx <- match(selected_crit, self$crit)
      if (any(is.na(idx))) stop("subset_crit contains non-existent criterion")
      self$perf[, idx, drop = FALSE]
    },

    filter = function(selected_alt, normalize_weights = TRUE) {
      idx <- match(selected_alt, self$alt)
      if (any(is.na(idx))) stop("filter contains non-existent alternative")
      self$alt <- self$alt[idx]
      self$perf <- self$perf[idx, , drop = FALSE]
      self$validate(normalize_weights = normalize_weights)
      invisible(self)
    },

    select = function(selected_crit, normalize_weights = TRUE) {
      idx <- match(selected_crit, self$crit)
      if (any(is.na(idx))) stop("select contains non-existent criterion")
      self$crit <- self$crit[idx]
      self$perf <- self$perf[, idx, drop = FALSE]
      if (!is.null(self$w)) self$w <- self$w[idx]
      if (!is.null(self$d)) self$d <- self$d[idx]
      self$validate(normalize_weights = normalize_weights)
      invisible(self)
    },

    rbind = function(name, values, normalize_weights = TRUE) {
      if (name %in% self$alt) stop("rbind: alternative name duplicated")
      stopifnot(length(values) == length(self$crit))
      values <- as.numeric(values)
      if (anyNA(values) || !all(is.finite(values))) stop("rbind: values must be finite numeric without NA")
      self$alt <- c(self$alt, name)
      new_row <- matrix(values, nrow = 1)
      colnames(new_row) <- self$crit
      rownames(new_row) <- name
      self$perf <- rbind(self$perf, new_row)
      self$validate(normalize_weights = normalize_weights)
      invisible(self)
    },

    cbind = function(name, values, normalize_weights = TRUE) {
      if (name %in% self$crit) stop("cbind: criterion name duplicated")
      stopifnot(length(values) == length(self$alt))
      values <- as.numeric(values)
      if (anyNA(values) || !all(is.finite(values))) stop("cbind: values must be finite numeric without NA")
      self$crit <- c(self$crit, name)
      new_col <- matrix(values, ncol = 1)
      colnames(new_col) <- name
      rownames(new_col) <- self$alt
      self$perf <- cbind(self$perf, new_col)
      if (!is.null(self$w)) {
        warning("weights length does not match criteria after cbind; please reset weights")
        self$w <- NULL
      }
      if (!is.null(self$d)) {
        warning("directions length does not match criteria after cbind; please reset directions")
        self$d <- NULL
      }
      self$validate(normalize_weights = normalize_weights)
      invisible(self)
    },

    set_w = function(weights, normalize_weights = TRUE) {
      if (anyNA(weights) || !is.numeric(weights)) stop("weights must be numeric without NA")
      if (length(weights) != length(self$crit)) stop("weights length must match criteria")
      if (!all(weights > 0)) stop("weights must be positive")
      self$w <- if (normalize_weights) weights / sum(weights) else weights
      if (!normalize_weights && abs(sum(self$w) - 1) > 1e-8) stop("weights not normalized (sum != 1) with normalize_weights = FALSE")
      invisible(self)
    },

    set_d = function(directions) {
      if (anyNA(directions)) stop("directions must not contain NA")
      if (length(directions) != length(self$crit)) stop("directions length must match criteria")
      if (!all(directions %in% c("max", "min"))) stop("directions only allow 'max' or 'min'")
      self$d <- directions
      invisible(self)
    }
  )
)
