# mcdaHub News

## Version 0.1.0 (2024-12-XX)

### Initial Release

- **Core Features**:
  - Implemented TOPSIS, PROMETHEE, and AHP algorithms
  - Support for ranking, sorting, and choice tasks
  - Full AHPSort implementation with CSV input support
  - Weights perturbation analysis
  - Comprehensive validation and error checking

- **Classes**:
  - `TaskDecision`, `TaskRanking`, `TaskSorting`, `TaskChoice`
  - `DeciderTOPSIS`, `DeciderPROMETHEE`, `DeciderAHP`
  - `ResultRanking`, `ResultSorting`, `ResultChoice`
  - `WeightPerturbation` (formerly `Evaluator`, originally `WeightsPerturbation`)

- **Documentation**:
  - Complete roxygen2 documentation for all exported classes
  - Four comprehensive vignettes: introduction, TOPSIS, PROMETHEE, and sensitivity analysis
  - Three toy datasets included:
    - `suppliers`: For TOPSIS, PROMETHEE, and sensitivity analysis
    - `investment_ahp`: For AHP ranking and choice tasks
    - `investment_ahpsort`: For AHPSort sorting tasks
  - Comprehensive test suite with testthat
  - Updated examples using included datasets

