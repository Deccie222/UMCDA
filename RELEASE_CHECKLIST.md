# R Package Release Checklist

## After `devtools::check()` Passes

Once `devtools::check()` shows **0 errors** (warnings and notes may be acceptable), follow these steps:

---

## Step 1: Final Verification ✅

### 1.1 Update NEWS.md Date
```r
# Edit NEWS.md and replace placeholder date
# Change: "Version 0.1.0 (2024-01-XX)"
# To:     "Version 0.1.0 (2024-12-XX)"  # Use actual date
```

### 1.2 Verify All Tests Pass
```r
devtools::test()
# Should show: [ PASS 114+ ]
```

### 1.3 Final Check
```r
devtools::check()
# Should show: 0 errors ✔
```

---

## Step 2: Build the Package 📦

### 2.1 Build Source Package
```r
devtools::build()
# Creates: mcdaHub_0.1.0.tar.gz
```

### 2.2 Build Binary Package (Windows)
```r
devtools::build(binary = TRUE)
# Creates: mcdaHub_0.1.0.zip (Windows)
```

**Location**: Files will be in the parent directory (`E:\mcdaHub\`)

---

## Step 3: Install and Test Locally 🧪

### 3.1 Install from Source
```r
devtools::install()
# Or: install.packages("E:/mcdaHub/mcdaHub_0.1.0.tar.gz", repos = NULL, type = "source")
```

### 3.2 Test Installation
```r
library(mcdaHub)
packageVersion("mcdaHub")  # Should show: 0.1.0

# Test basic functionality
data(mobile_phones)
task <- TaskRanking$new(
  alt = mobile_phones$alt,
  crit = mobile_phones$crit,
  perf = mobile_phones$perf,
  weight = mobile_phones$weight,
  direction = mobile_phones$direction
)
decider <- DeciderTOPSIS$new()
result <- decider$solve(task)
print(result)
```

---

## Step 4: Version Control & Git 📝

### 4.1 Check Git Status
```bash
git status
```

### 4.2 Commit All Changes
```bash
git add .
git commit -m "Release version 0.1.0

- Initial release of mcdaHub package
- Implements TOPSIS, PROMETHEE, and AHP algorithms
- Includes weight perturbation analysis
- Three toy datasets included
- Comprehensive test suite"
```

### 4.3 Create Version Tag
```bash
git tag -a v0.1.0 -m "Release version 0.1.0"
```

### 4.4 Push to GitHub
```bash
git push origin main
git push origin v0.1.0  # Push the tag
```

---

## Step 5: GitHub Release 🚀

### 5.1 Create Release on GitHub

1. Go to: https://github.com/Deccie222/mcdaHub/releases
2. Click **"Create a new release"**
3. **Tag**: Select `v0.1.0` (or create new tag)
4. **Title**: `mcdaHub v0.1.0 - Initial Release`
5. **Description**:
   ```markdown
   ## mcdaHub v0.1.0 - Initial Release
   
   ### Features
   - ✅ TOPSIS, PROMETHEE, and AHP algorithms
   - ✅ Support for ranking, sorting, and choice tasks
   - ✅ Weight perturbation analysis
   - ✅ Three toy datasets included
   - ✅ Comprehensive test suite
   
   ### Installation
   ```r
   # From GitHub
   devtools::install_github("Deccie222/mcdaHub")
   
   # Or from source
   install.packages("mcdaHub_0.1.0.tar.gz", repos = NULL, type = "source")
   ```
   
   ### Documentation
   See [README.md](https://github.com/Deccie222/mcdaHub/blob/main/README.md)
   ```

6. **Attach Files**:
   - Upload `mcdaHub_0.1.0.tar.gz` (source package)
   - Upload `mcdaHub_0.1.0.zip` (binary package, if built)

7. Click **"Publish release"**

---

## Step 6: Update Documentation (Optional) 📚

### 6.1 Create Vignette (Optional)
```r
# Create vignettes/ directory
usethis::use_vignette("introduction")
# Write comprehensive tutorial
```

### 6.2 Update README.md
- Add installation instructions
- Add badges (build status, version, etc.)
- Add more examples

---

## Step 7: Submit to CRAN (Optional) 🌐

**⚠️ Only if you want to publish on CRAN**

### 7.1 Pre-submission Checklist
- [ ] All tests pass
- [ ] `devtools::check()` shows 0 errors, 0 warnings
- [ ] Documentation is complete
- [ ] Examples run without errors
- [ ] LICENSE file exists
- [ ] No non-ASCII characters in code
- [ ] NEWS.md is formatted correctly

### 7.2 Additional Checks
```r
# Run CRAN-specific checks
devtools::check(cran = TRUE)

# Check reverse dependencies (if any)
devtools::revdep_check()
```

### 7.3 Submit to CRAN
1. Go to: https://cran.r-project.org/submit.html
2. Upload `mcdaHub_0.1.0.tar.gz`
3. Fill out submission form
4. Wait for review (can take 1-2 weeks)

---

## Quick Command Summary

```r
# 1. Final check
devtools::check()

# 2. Build package
devtools::build()                    # Source
devtools::build(binary = TRUE)       # Binary (Windows)

# 3. Install locally
devtools::install()

# 4. Test
devtools::test()
library(mcdaHub)
# ... test code ...

# 5. Git (in terminal)
git add .
git commit -m "Release v0.1.0"
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin main
git push origin v0.1.0
```

---

## File Locations After Build

```
E:\mcdaHub\
├── mcdaHub/                   # Source package
│   ├── R/
│   ├── data/
│   └── ...
│
└── mcdaHub_0.1.0.tar.gz       # Source package (for distribution)
    mcdaHub_0.1.0.zip          # Binary package (Windows)
```

---

## Common Issues

### Issue: Build fails
**Solution**: Check for syntax errors, missing dependencies

### Issue: Installation fails
**Solution**: Ensure all dependencies are installed

### Issue: Tests fail after installation
**Solution**: Re-run `devtools::test()` and fix issues

### Issue: Git tag already exists
**Solution**: Delete and recreate: `git tag -d v0.1.0 && git tag -a v0.1.0 -m "Release v0.1.0"`

---

## Next Steps After Release

1. **Monitor Issues**: Check GitHub issues regularly
2. **Collect Feedback**: Gather user feedback
3. **Plan Next Version**: Start planning v0.2.0 features
4. **Update Documentation**: Keep docs up to date
5. **Maintain Package**: Fix bugs, add features

---

## Version Numbering

- **Major.Minor.Patch** (e.g., 0.1.0)
- **0.x.x**: Development/initial release
- **1.0.0**: First stable release
- **x.y.z**: Increment based on changes:
  - **Patch** (z): Bug fixes
  - **Minor** (y): New features, backward compatible
  - **Major** (x): Breaking changes

---

**🎉 Congratulations on your package release!**

