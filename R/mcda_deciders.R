mcda_deciders = new.env(parent = emptyenv())

register_decider = function(key, constructor) {
  assign(key, constructor, envir = mcda_deciders)
}

dcr = function(key, ...) {
  if (!exists(key, envir = mcda_deciders)) {
    stop(sprintf("Decider '%s' not found", key))
  }
  constructor = get(key, envir = mcda_deciders)
  constructor(...)
}

.onLoad = function(libname, pkgname) {
  register_decider("topsis", function(...) {
    Decider$new(
      id = "topsis",
      algorithm = AlgorithmTOPSIS$new(),
      param_set = list(...)
    )
  })
  register_decider("promethee", function(...) {
    Decider$new(
      id = "promethee",
      algorithm = AlgorithmPROMETHEE$new(),
      param_set = list(...)
      )
  })

}
