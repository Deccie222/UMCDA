# Script to verify datasets are correctly saved
# Run this from the package root directory

cat("=== Verifying Dataset Files ===\n\n")

# Check if .rda files exist
datasets <- c("cars", "supplier", "employee", "investment_ahp", "investment_ahpsort")
data_dir <- "data"

for (ds in datasets) {
  rda_file <- file.path(data_dir, paste0(ds, ".rda"))
  r_file <- file.path(data_dir, paste0(ds, ".R"))
  
  cat(sprintf("Checking %s:\n", ds))
  cat(sprintf("  .rda file exists: %s\n", file.exists(rda_file)))
  cat(sprintf("  .R file exists: %s\n", file.exists(r_file)))
  
  if (file.exists(rda_file)) {
    # Try to load it
    env <- new.env()
    result <- tryCatch({
      load(rda_file, envir = env)
      exists(ds, envir = env)
    }, error = function(e) {
      cat(sprintf("  ERROR loading: %s\n", conditionMessage(e)))
      FALSE
    })
    
    if (result) {
      cat(sprintf("  ✓ Dataset loads successfully\n"))
      obj <- get(ds, envir = env)
      cat(sprintf("  ✓ Object type: %s\n", class(obj)))
      if (is.list(obj)) {
        cat(sprintf("  ✓ List elements: %s\n", paste(names(obj), collapse = ", ")))
      }
    } else {
      cat(sprintf("  ✗ Dataset failed to load\n"))
    }
  }
  cat("\n")
}

cat("=== Verification Complete ===\n")
