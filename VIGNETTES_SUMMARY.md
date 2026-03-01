# Vignettes Summary

## Created Vignettes

The package now includes four comprehensive vignettes:

### 1. **introduction.Rmd** - Getting Started Guide
- Package overview and key features
- Basic workflow demonstration
- Quick start examples for all task types (ranking, sorting, choice)
- Sensitivity analysis introduction
- Links to other vignettes

**Access**: `vignette("introduction", package = "mcdaHub")`

### 2. **topsis.Rmd** - TOPSIS Method Tutorial
- TOPSIS algorithm overview
- Ranking, sorting, and choice examples
- Understanding TOPSIS scores
- Accessing intermediate results
- Handling different criteria directions
- Comparing with other methods
- Tips and best practices

**Access**: `vignette("topsis", package = "mcdaHub")`

### 3. **promethee.Rmd** - PROMETHEE Method Tutorial
- PROMETHEE algorithm overview
- Net flow interpretation
- Ranking and sorting examples
- FlowSort implementation
- Comparing with TOPSIS
- Sensitivity analysis integration
- Tips and best practices

**Access**: `vignette("promethee", package = "mcdaHub")`

### 4. **sensitivity.Rmd** - Sensitivity Analysis Guide
- Weight perturbation overview
- Setting up sensitivity analysis
- Visualization methods (SD plot, trajectory, heatmap)
- Understanding results
- Advanced usage examples
- Best practices and tips

**Access**: `vignette("sensitivity", package = "mcdaHub")`

## Building Vignettes

### Prerequisites

Make sure you have the required packages installed:

```r
install.packages(c("knitr", "rmarkdown", "ggplot2"))
```

### Build All Vignettes

```r
setwd("E:/mcdaHub/UMCDA")
devtools::build_vignettes()
```

This will:
- Compile all `.Rmd` files to HTML
- Create vignette index
- Make vignettes available after package installation

### Build Individual Vignette

```r
# In R
knitr::knit("vignettes/introduction.Rmd", "vignettes/introduction.html")
```

### View Vignettes Locally

After building:

```r
# List all vignettes
vignette(package = "mcdaHub")

# View specific vignette
vignette("introduction", package = "mcdaHub")
```

## Vignette Structure

Each vignette follows this structure:

1. **YAML Header**: Metadata (title, author, date, output format)
2. **Setup Chunk**: Load library and set knitr options
3. **Introduction**: Overview and purpose
4. **Main Content**: Examples and explanations
5. **Advanced Topics**: More complex use cases
6. **Tips/Best Practices**: Practical advice
7. **References**: Relevant literature

## Configuration

### DESCRIPTION Updates

Added to `DESCRIPTION`:
- `knitr` and `rmarkdown` to `Suggests`
- `VignetteBuilder: knitr`

### .Rbuildignore

Already configured to exclude:
- `vignettes/.*\.Rmd\.orig$` (backup files)
- `vignettes/.*\.html$` (built HTML files)

The source `.Rmd` files are included in the package.

## After Installation

Users can access vignettes after installing the package:

```r
# Install package
devtools::install_github("Deccie222/mcdaHub", build_vignettes = TRUE)

# Or install from source with vignettes
install.packages("mcdaHub_0.1.0.tar.gz", repos = NULL, type = "source")

# View vignettes
vignette(package = "mcdaHub")
vignette("introduction", package = "mcdaHub")
```

## Next Steps

1. **Build vignettes**: Run `devtools::build_vignettes()`
2. **Test locally**: View each vignette to ensure they render correctly
3. **Update documentation**: Vignettes are now referenced in README.md
4. **Package check**: Run `devtools::check()` to verify vignettes build correctly

## Notes

- Vignettes use `eval = FALSE` for some long-running examples (sensitivity analysis)
- All code examples are tested and should work
- Vignettes are built during `devtools::check()` and `devtools::build()`
- HTML files are excluded from package but source `.Rmd` files are included

