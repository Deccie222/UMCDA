# Quick test to check if datasets are installed
# Run this after installing the package

cat("=== Testing Dataset Installation ===\n\n")

# Check if package is installed
if (!requireNamespace("mcdaHub", quietly = TRUE)) {
  stop("Package mcdaHub is not installed. Please run: devtools::install()")
}

cat("✓ Package is installed\n\n")

# Get package path
pkg_path <- system.file(package = "mcdaHub")
cat("Package path:", pkg_path, "\n\n")

# Check if data directory exists
data_dir <- file.path(pkg_path, "data")
cat("Data directory:", data_dir, "\n")
cat("Data directory exists:", dir.exists(data_dir), "\n\n")

if (dir.exists(data_dir)) {
  # List files in data directory
  data_files <- list.files(data_dir, pattern = "\\.rda$")
  cat("Files in data directory:\n")
  for (f in data_files) {
    cat("  -", f, "\n")
  }
  cat("\n")
  
  # Try to load each dataset
  datasets <- c("cars", "supplier", "employee", "investment_ahp", "investment_ahpsort")
  for (ds in datasets) {
    cat(sprintf("Testing %s:\n", ds))
    
    # Method 1: data() function
    env1 <- new.env()
    tryCatch({
      data(list = ds, package = "mcdaHub", envir = env1)
      if (exists(ds, envir = env1)) {
        cat(sprintf("  ✓ data() method: Success\n"))
      } else {
        cat(sprintf("  ✗ data() method: Object not found\n"))
      }
    }, error = function(e) {
      cat(sprintf("  ✗ data() method: Error - %s\n", conditionMessage(e)))
    })
    
    # Method 2: Direct load from file
    rda_file <- file.path(data_dir, paste0(ds, ".rda"))
    if (file.exists(rda_file)) {
      env2 <- new.env()
      tryCatch({
        load(rda_file, envir = env2)
        if (exists(ds, envir = env2)) {
          cat(sprintf("  ✓ Direct load: Success\n"))
        } else {
          cat(sprintf("  ✗ Direct load: Object not found\n"))
        }
      }, error = function(e) {
        cat(sprintf("  ✗ Direct load: Error - %s\n", conditionMessage(e)))
      })
    } else {
      cat(sprintf("  ✗ Direct load: File not found\n"))
    }
    cat("\n")
  }
} else {
  cat("✗ Data directory does not exist!\n")
  cat("This means datasets were not installed with the package.\n")
  cat("Please check:\n")
  cat("  1. data/ directory exists in source package\n")
  cat("  2. .rda files exist in data/ directory\n")
  cat("  3. Run devtools::install() to reinstall\n")
}

cat("=== Test Complete ===\n")

