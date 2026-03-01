# Test Coverage Summary

This document summarizes the test coverage for the mcdaHub (Multi-Criteria Decision Analysis) R package.

## Test Files Overview

### Core Classes

1. **test-Decider.R** - Tests for the abstract `Decider` base class
   - Abstract class instantiation (should fail)
   - `solve()` method validation
   - Task type validation
   - Result dispatch based on task type
   - State management
   - Result validation (length, names, NA/Inf checks)

2. **test-DeciderTOPSIS.R** - Tests for `DeciderTOPSIS` implementation
   - Class instantiation
   - `solve()` method correctness (tests internal compute() logic)
   - Max/min criteria handling
   - Mixed criteria scenarios
   - State storage (intermediate results)
   - Edge cases (zero-variance, identical alternatives)
   - Integration with `solve()` and `ResultRanking`
   - Single alternative/criterion handling

3. **test-DeciderPROMETHEE.R** - Tests for `DeciderPROMETHEE` implementation
   - Class instantiation
   - `solve()` method correctness (tests internal compute() logic)
   - Max/min criteria handling (with direction transformation)
   - Pairwise preference computation
   - Netflow calculation (leaving - entering flow)
   - Preference matrix properties
   - State storage (intermediate results)
   - Edge cases (zero-variance, identical alternatives)
   - Integration with `solve()` and `ResultRanking`
   - Single alternative/criterion handling

4. **test-TaskDecision.R** - Tests for the base `TaskDecision` class
   - Object creation with valid inputs
   - Parameter validation (weights, directions, dimensions)
   - Data type validation (numeric, NA, Inf)
   - Uniqueness validation (alternatives, criteria)
   - Weight normalization (default and optional)
   - Task type handling (ranking, sorting, choice)
   - Accessor methods (`n_alt`, `n_crit`, `alt_names`, `crit_names`)
   - `get_perf()` (full matrix and single value)
   - `set_perf()` (with auto-transpose)
   - `set_w()` and `set_d()` methods
   - `get_w()` and `get_d()` methods
   - Data frame input support
   - Edge cases (single alternative/criterion)
   - Manual validation

5. **test-TaskRanking.R** - Tests for `TaskRanking` subclass
   - Class instantiation
   - Automatic type setting to "ranking"
   - Inheritance of all `TaskDecision` methods
   - `print()` method
   - Weight normalization options
   - Integration with `DeciderTOPSIS` and `DeciderPROMETHEE`
   - Interface consistency

6. **test-ResultRanking.R** - Tests for `ResultRanking` result class
   - Object creation with valid raw_result
   - Named vector requirement
   - Ranking table structure and correctness
   - Ranking order (higher value = better rank)
   - Tie handling
   - Metadata storage
   - `print()` method
   - Integration with `DeciderTOPSIS` and `DeciderPROMETHEE`
   - Edge cases (single alternative, many alternatives)
   - Negative values handling (e.g., PROMETHEE netflow)

### Subclass Interface Tests

7. **test-TaskChoice.R** - Interface tests for `TaskChoice` subclass
   - Class instantiation
   - Type setting to "choice"
   - Inheritance verification
   - Integration with `Decider.solve()`

8. **test-TaskSorting.R** - Interface tests for `TaskSorting` subclass
   - Class instantiation
   - Type setting to "sorting"
   - Categories handling (`set_categories()`)
   - Category validation
   - Inheritance verification
   - Integration with `Decider.solve()`

## Test Coverage Statistics

### By Component

| Component | Test Cases | Coverage |
|-----------|------------|----------|
| `Decider` (abstract) | 7 | API validation |
| `DeciderTOPSIS` | 13 | Full algorithm logic |
| `DeciderPROMETHEE` | 14 | Full algorithm logic |
| `TaskDecision` | 20+ | Complete functionality |
| `TaskRanking` | 10 | Interface + inheritance |
| `ResultRanking` | 11 | Complete functionality |
| `TaskChoice` | 5 | Interface only |
| `TaskSorting` | 8 | Interface only |

### Test Categories

- **Unit Tests**: Individual method and class functionality
- **Integration Tests**: Cross-class interactions (Task → Decider → Result)
- **Validation Tests**: Input validation and error handling
- **Edge Case Tests**: Zero-variance, identical values, single alternatives
- **Interface Tests**: Inheritance and method accessibility

## Running Tests

```r
# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-DeciderTOPSIS.R")

# Run tests with coverage
devtools::test_coverage()
```

## Test Principles

1. **Fail-Fast**: Tests validate inputs early and provide clear error messages
2. **Isolation**: Each test is independent and can run in any order
3. **Completeness**: Tests cover both happy paths and error cases
4. **Readability**: Test names clearly describe what is being tested
5. **Maintainability**: Tests use consistent setup data and patterns

## Notes

- `TaskChoice` and `TaskSorting` currently have minimal tests (interface only) as they are not fully implemented
- All abstract base classes (`Decider`, `TaskDecision`, `TaskResult`) cannot be instantiated directly
- Result classes (`ResultRanking`, `ResultChoice`, `ResultSorting`) are tested primarily through integration with Deciders
- Edge cases include: single alternatives, single criteria, identical values, zero-variance criteria







