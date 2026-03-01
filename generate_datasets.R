# Quick script to generate datasets
# Run this in R: source("generate_datasets.R")

# Source the dataset creation script
source("data-raw/create_datasets.R")

cat("\n✓ All datasets have been generated!\n")
cat("You can now run:\n")
cat("  devtools::document()\n")
cat("  devtools::check()\n")

