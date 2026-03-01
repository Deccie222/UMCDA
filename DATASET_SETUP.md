# Dataset Setup Instructions

## Problem

The R CMD check is failing because the dataset files (`.rda`) have not been generated yet. The dataset documentation files (`.R`) exist, but the actual data files need to be created.

## Solution

### Step 1: Generate Dataset Files

In R console, run:

```r
# Set working directory to package root
setwd("E:/mcdaHub/mcdaHub")

# Generate datasets
source("data-raw/create_datasets.R")
```

Or use the helper script:

```r
source("generate_datasets.R")
```

This will create three `.rda` files in the `data/` directory:
- `data/mobile_phones.rda`
- `data/suppliers.rda`
- `data/student_evaluation.rda`

### Step 2: Verify Datasets

```r
# Load package in development mode
devtools::load_all(".")

# Test datasets
data(mobile_phones)
data(suppliers)
data(student_evaluation)

# Verify they loaded correctly
str(mobile_phones)
str(suppliers)
str(student_evaluation)
```

### Step 3: Regenerate Documentation

```r
# Regenerate all documentation
devtools::document()
```

### Step 4: Run R CMD Check

```r
# Check the package
devtools::check()
```

## Important Notes

1. **Dataset files must be generated before building the package**
   - The `.rda` files are binary data files that contain the actual datasets
   - The `.R` files in `data/` are only documentation

2. **Dataset files are included in the package**
   - Once generated, the `.rda` files will be included when you build the package
   - Users can then use `data(mobile_phones)` after installing the package

3. **The `data-raw/` directory is excluded from the package**
   - This directory contains development scripts only
   - It's excluded via `.Rbuildignore`

## Troubleshooting

### Error: "object 'mobile_phones' not found"

**Cause**: Dataset files (`.rda`) have not been generated.

**Solution**: Run `source("data-raw/create_datasets.R")` to generate the files.

### Warning: "No dataset created in 'envir'"

**Cause**: The `.rda` files don't exist or are corrupted.

**Solution**: 
1. Delete any existing `.rda` files in `data/`
2. Regenerate them using `source("data-raw/create_datasets.R")`
3. Verify they were created: `list.files("data/", pattern = "\\.rda$")`

### Note: "Non-standard files/directories found"

**Cause**: Image files (`.png`) in the root directory.

**Solution**: These are now excluded via `.Rbuildignore`. If they still appear, delete them manually.

