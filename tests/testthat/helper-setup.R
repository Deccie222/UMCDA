# Helper file for test setup
# This file is automatically sourced before tests run
# See: https://testthat.r-lib.org/articles/special-files.html

# Source all R files to ensure classes are available
# Note: In a proper package build, classes would be loaded via NAMESPACE
# This ensures tests can run even without full package installation

# Get the package root directory (where R/ folder is located)
# In testthat, we're in tests/testthat/, so go up two levels
package_root <- normalizePath(file.path(getwd(), "..", ".."))
r_dir <- file.path(package_root, "R")

if (dir.exists(r_dir)) {
  r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)
  for (r_file in r_files) {
    source(r_file, local = FALSE)
  }
}

