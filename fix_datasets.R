# Script to fix dataset installation issues
# Run this in R from the package root directory (E:/mcdaHub/UMCDA)

cat("=== Fixing Dataset Installation ===\n\n")

# Step 1: Recreate datasets
cat("Step 1: Recreating datasets...\n")
source("data-raw/create_datasets.R")

# Step 2: Verify .rda files exist and can be loaded
cat("\nStep 2: Verifying dataset files...\n")
datasets <- c("cars", "supplier", "employee", "investment_ahp", "investment_ahpsort")
all_ok <- TRUE

for (ds in datasets) {
  rda_file <- file.path("data", paste0(ds, ".rda"))
  if (file.exists(rda_file)) {
    env <- new.env()
    tryCatch({
      load(rda_file, envir = env)
      if (exists(ds, envir = env)) {
        cat(sprintf("  ✓ %s: File exists and loads correctly\n", ds))
      } else {
        cat(sprintf("  ✗ %s: File exists but object not found\n", ds))
        all_ok <- FALSE
      }
    }, error = function(e) {
      cat(sprintf("  ✗ %s: Error loading - %s\n", ds, conditionMessage(e)))
      all_ok <- FALSE
    })
  } else {
    cat(sprintf("  ✗ %s: File does not exist\n", ds))
    all_ok <- FALSE
  }
}

if (!all_ok) {
  cat("\n✗ Some datasets failed verification. Please check the create_datasets.R script.\n")
  stop("Dataset verification failed")
}

# Step 3: Uninstall old package
cat("\nStep 3: Uninstalling old package...\n")
if ("package:mcdaHub" %in% search()) {
  detach("package:mcdaHub", unload = TRUE)
  cat("  ✓ Detached package\n")
}

if ("mcdaHub" %in% rownames(installed.packages())) {
  remove.packages("mcdaHub")
  cat("  ✓ Removed package\n")
}

# Step 4: Clean and rebuild
cat("\nStep 4: Cleaning and rebuilding...\n")
devtools::clean_dll()
devtools::clean_vignettes()
cat("  ✓ Cleaned DLL and vignettes\n")

# Step 5: Regenerate documentation
cat("\nStep 5: Regenerating documentation...\n")
devtools::document()
cat("  ✓ Documentation regenerated\n")

# Step 6: Reinstall package
cat("\nStep 6: Reinstalling package...\n")
devtools::install()
cat("  ✓ Package reinstalled\n")

# Step 7: Test datasets
cat("\nStep 7: Testing datasets...\n")
library(mcdaHub)

for (ds in datasets) {
  tryCatch({
    data(list = ds, package = "mcdaHub", envir = environment())
    if (exists(ds, envir = environment())) {
      cat(sprintf("  ✓ %s: Successfully loaded\n", ds))
    } else {
      cat(sprintf("  ✗ %s: Failed to load\n", ds))
    }
  }, error = function(e) {
    cat(sprintf("  ✗ %s: Error - %s\n", ds, conditionMessage(e)))
  })
}

cat("\n=== Fix Complete ===\n")
cat("\nNow test with:\n")
cat("  library(mcdaHub)\n")
cat("  data(cars, package = 'mcdaHub')\n")
cat("  exists('cars')\n")

