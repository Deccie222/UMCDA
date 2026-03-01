# R Package Data Folders: `data/` vs `data-raw/`

## Overview

In R package development, there are two standard folders for handling datasets:

1. **`data/`** - Contains the final dataset files (`.rda`) that will be included in the package
2. **`data-raw/`** - Contains scripts and source files used to create the datasets (excluded from package)

## `data/` Folder

### Purpose
- Contains the **final, processed dataset files** that users will load with `data()`
- Files in this folder are **included in the package** when it's built
- These are the binary `.rda` files that contain the actual data

### Contents
- **`.rda` files**: Binary R data files (e.g., `mobile_phones.rda`, `suppliers.rda`)
- **`.R` files**: Documentation files for each dataset (e.g., `mobile_phones.R`)

### Example Structure
```
data/
├── mobile_phones.rda          # Binary data file (included in package)
├── mobile_phones.R             # Documentation (included in package)
├── suppliers.rda               # Binary data file
├── suppliers.R                 # Documentation
├── student_evaluation.rda     # Binary data file
└── student_evaluation.R        # Documentation
```

### How Users Access
```r
library(mcdaHub)
data(mobile_phones)  # Loads mobile_phones.rda
```

## `data-raw/` Folder

### Purpose
- Contains **development scripts** used to create/process the datasets
- Files in this folder are **excluded from the package** (via `.Rbuildignore`)
- These are source files, not final data files

### Contents
- **`.R` scripts**: Scripts that generate the datasets (e.g., `create_datasets.R`)
- **Source data files**: CSV, Excel, or other raw data files (if any)
- **Processing scripts**: Data cleaning, transformation scripts

### Example Structure
```
data-raw/
└── create_datasets.R           # Script to generate .rda files (excluded)
```

### Why Excluded?
- These are development tools, not needed by end users
- Keeps the package size smaller
- Prevents exposing internal data processing logic
- Specified in `.Rbuildignore`: `^data-raw/`

## Workflow

### Step 1: Create Data in `data-raw/`
```r
# In data-raw/create_datasets.R
mobile_phones <- list(
  alt = c("Mobile 1", "Mobile 2", ...),
  crit = c("Price", "Memory", ...),
  # ... create the data
)

# Save to data/ folder
save(mobile_phones, file = "../data/mobile_phones.rda", compress = "xz")
```

### Step 2: Document in `data/`
```r
# In data/mobile_phones.R
#' Mobile Phone Selection Dataset
#'
#' @description
#' A toy dataset for ranking mobile phones...
#'
#' @format A list containing...
"mobile_phones"
```

### Step 3: Package Includes Only `data/`
- When building the package, only `data/` folder is included
- `data-raw/` is excluded via `.Rbuildignore`
- Users get the `.rda` files and documentation, but not the creation scripts

## Why This Separation?

### Benefits

1. **Clean Package**: End users only get the final data, not development scripts
2. **Reproducibility**: Source scripts are kept in version control for future updates
3. **Smaller Package Size**: Development scripts don't bloat the package
4. **Standard Practice**: Follows R package development best practices

### Comparison

| Aspect | `data/` | `data-raw/` |
|--------|---------|-------------|
| Included in package? | ✅ Yes | ❌ No |
| Contains `.rda` files? | ✅ Yes | ❌ No |
| Contains documentation? | ✅ Yes | ❌ No |
| Contains creation scripts? | ❌ No | ✅ Yes |
| Users can access? | ✅ Yes | ❌ No |
| Version controlled? | ✅ Yes | ✅ Yes |

## Current Package Structure

```
mcdaHub/
├── data/                      # ✅ Included in package
│   ├── mobile_phones.rda      # Final dataset (binary)
│   ├── mobile_phones.R        # Documentation
│   ├── suppliers.rda
│   ├── suppliers.R
│   ├── student_evaluation.rda
│   └── student_evaluation.R
│
└── data-raw/                  # ❌ Excluded from package
    └── create_datasets.R      # Development script
```

## When to Use Each

### Use `data/` for:
- Final dataset files (`.rda`)
- Dataset documentation (`.R` files with roxygen2 comments)
- Any files that end users need

### Use `data-raw/` for:
- Scripts that generate datasets
- Raw source data files (CSV, Excel, etc.)
- Data processing/cleaning scripts
- Any development-only files

## Summary

- **`data/`**: Final datasets that ship with the package (users can use `data()`)
- **`data-raw/`**: Development scripts to create those datasets (excluded from package)

This separation keeps the package clean and follows R package development best practices! 📦

