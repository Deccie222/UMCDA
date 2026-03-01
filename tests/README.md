# mcdaHub Test Suite

## Overview

This directory contains comprehensive test suites for the mcdaHub (Multi-Criteria Decision Analysis) R package. The tests are written using the `testthat` framework and cover all major components of the package.

## Test Files

### Core Algorithm Tests

1. **test-Decider.R**
   - Tests the abstract `Decider` base class
   - Validates `solve()` API and result dispatch
   - Tests error handling and validation

2. **test-DeciderTOPSIS.R**
   - Tests TOPSIS algorithm implementation
   - Validates score calculation for max/min criteria
   - Tests edge cases and state management

3. **test-DeciderPROMETHEE.R**
   - Tests PROMETHEE II algorithm implementation
   - Validates netflow calculation
   - Tests pairwise preference computation

### Task Classes Tests

4. **test-TaskDecision.R**
   - Tests the base `TaskDecision` class
   - Comprehensive validation testing
   - All accessor and mutator methods

5. **test-TaskRanking.R**
   - Tests `TaskRanking` subclass
   - Interface and inheritance verification
   - Integration with deciders

6. **test-TaskChoice.R**
   - Interface tests for `TaskChoice` subclass
   - Basic functionality verification

7. **test-TaskSorting.R**
   - Interface tests for `TaskSorting` subclass
   - Category handling tests

### Result Classes Tests

8. **test-ResultRanking.R**
   - Tests `ResultRanking` result class
   - Ranking table structure and correctness
   - Integration with both deciders

## Running Tests

### Using devtools (recommended)
```r
# Run all tests
devtools::test()

# Run with coverage report
devtools::test_coverage()
```

### Using testthat directly
```r
# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test file
testthat::test_file("tests/testthat/test-DeciderTOPSIS.R")
```

## Test Organization

- Each test file corresponds to a major class in the package
- Tests are organized by functionality (creation, validation, methods, integration)
- Edge cases are included for robustness
- Integration tests verify cross-class interactions

## Test Coverage

See [TEST_COVERAGE.md](TEST_COVERAGE.md) for detailed coverage statistics and breakdown.

## Notes

- All tests use the `testthat` framework
- Helper functions are in `helper-setup.R`
- Tests follow the `test_that("description", { code })` pattern
- Edge cases include: single alternatives/criteria, identical values, zero-variance







