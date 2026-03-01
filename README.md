# mcdaHub: Unified Multi-Criteria Decision Analysis

[![R-CMD-check](https://github.com/Deccie222/mcdaHub/workflows/R-CMD-check/badge.svg)](https://github.com/Deccie222/mcdaHub/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive R package for Multi-Criteria Decision Analysis (MCDA) using R6 classes for object-oriented design. Provides multiple MCDA methods (TOPSIS, PROMETHEE, AHP) for ranking, sorting, and choice problems.

## Features

- **Multiple MCDA Methods**: TOPSIS, PROMETHEE II, and AHP/AHPSort
- **Task Types**: Ranking, Sorting, and Choice problems
- **Sensitivity Analysis**: Weight perturbation analysis tools
- **Algorithm Comparison**: Rank correlation analysis between different methods
- **Object-Oriented Design**: Clean R6 class hierarchy
- **Toy Datasets**: Ready-to-use example datasets

## Installation

### From GitHub (Development Version)

```r
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install from GitHub
devtools::install_github("Deccie222/mcdaHub")
```

### From Source

```r
# Clone the repository and install
devtools::install("path/to/mcdaHub")
```

## Quick Start

### Ranking Task with TOPSIS

```r
library(mcdaHub)

# Load toy dataset
data(cars, package = "mcdaHub")

# Create a ranking task
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# Solve using TOPSIS
decider <- DeciderTOPSIS$new()
result <- decider$solve(task)

# View results
print(result)
```

### Comparing TOPSIS and PROMETHEE

```r
# Load cars dataset
data(cars, package = "mcdaHub")

# Create a ranking task
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# Solve with TOPSIS
decider_topsis <- DeciderTOPSIS$new()
result_topsis <- decider_topsis$solve(task)
print(result_topsis)

# Solve with PROMETHEE
decider_promethee <- DeciderPROMETHEE$new()
result_promethee <- decider_promethee$solve(task)
print(result_promethee)
```

### AHP Ranking Task

```r
# Load AHP dataset
data(supplier, package = "mcdaHub")

# Create a ranking task
task <- TaskRanking$new(
  alt = supplier$alt,
  crit = supplier$crit,
  pair_crit = supplier$pair_crit,
  pair_alt = supplier$pair_alt
)

# Solve using AHP
decider <- DeciderAHP$new()
result <- decider$solve(task)
print(result)
```

### AHPSort Sorting Task

```r
# Load AHPSort dataset
data(employee, package = "mcdaHub")

# Create a sorting task
task <- TaskSorting$new(
  alt = employee$alt,
  crit = employee$crit,
  cat_names = employee$cat_names,
  pair_crit = employee$pair_crit,
  judge_alt_profile = employee$judge_alt_profile,
  prof_order = employee$prof_order,
  assign_rule = "pessimistic"
)

# Solve using AHP (AHPSort method)
decider <- DeciderAHP$new()
result <- decider$solve(task)
print(result)
```

### Sensitivity Analysis

```r
# Load toy dataset
data(cars, package = "mcdaHub")

# Create a ranking task
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# Perform sensitivity analysis
decider_promethee <- DeciderPROMETHEE$new()
wp <- WeightPerturbation$new(
  task = task,
  decider = decider_promethee,
  perturb_rg = 0.3,
  perturb_n = 51
)
wp$weight_perturb()

# View rank stability
rank_mat <- wp$perturb_rank()
wp$perturb_stab_plot(type = "sd")
```

### Algorithm Comparison

```r
# Load dataset
data(cars, package = "mcdaHub")

# Create a ranking task
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# Create multiple deciders
decider1 <- DeciderTOPSIS$new()
decider2 <- DeciderPROMETHEE$new()

# Compare algorithms
analyzer <- AlgoRankCorrelation$new(
  task = task,
  decider = list(decider1, decider2)
)
corr <- analyzer$calculate()
print(analyzer)
```

## Main Classes

### Task Classes
- `TaskDecision`: Base class for MCDA tasks
- `TaskRanking`: Ranking problems
- `TaskSorting`: Sorting problems
- `TaskChoice`: Choice problems

### Decider Classes (Algorithms)
- `DeciderTOPSIS`: TOPSIS method
- `DeciderPROMETHEE`: PROMETHEE II method
- `DeciderAHP`: AHP and AHPSort methods

### Result Classes
- `ResultRanking`: Ranking results
- `ResultSorting`: Sorting results
- `ResultChoice`: Choice results

### Analysis Tools
- `WeightPerturbation`: Sensitivity analysis through weight perturbation
- `AlgoRankCorrelation`: Compare rankings from different algorithms

## Documentation

- **Vignettes**: 
  - `vignette("01-task-classes", package = "mcdaHub")` - Creating Task objects
  - `vignette("02-decider-and-solve", package = "mcdaHub")` - Using Decider classes and solve()
  - `vignette("03-analysis-tools", package = "mcdaHub")` - Sensitivity analysis and algorithm comparison
- **Function Reference**: Run `?TaskRanking` or `?DeciderTOPSIS` for help
- **Examples**: See included toy datasets:
  - `cars`: For TOPSIS, PROMETHEE, and sensitivity analysis
  - `supplier`: For AHP ranking and choice tasks
  - `employee`: For AHPSort sorting tasks

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Wanting Zuo**
- Email: ttlucky625@gmail.com
- GitHub: [@Deccie222](https://github.com/Deccie222)

## Citation

If you use mcdaHub in your research, please cite:

```r
citation("mcdaHub")
```

## Acknowledgments

- Built with [R6](https://r6.r-lib.org/) for object-oriented programming
- Uses [RMCDA](https://cran.r-project.org/package=RMCDA) for MCDA algorithm implementations

## Support

- **Issues**: [GitHub Issues](https://github.com/Deccie222/mcdaHub/issues)
- **Email**: ttlucky625@gmail.com
