# 分析：DeciderPROMETHEE 在调用 RMCDA 前可能导致 rownames 重复的操作

## 代码流程分析

### 步骤 1: 获取性能矩阵
```r
# DeciderPROMETHEE::compute_ranking_choice() 第160行
A <- task$get_perf()  # already has row/col names from TaskDecision
```

**`get_perf()` 的实现**（TaskDecision.R 第287-310行）：
```r
get_perf = function(alt_name = NULL, crit_name = NULL) {
  perf <- self$task_data$perf
  if (is.null(perf)) {
    stop("Performance matrix (perf) is not available in task_data")
  }
  
  # If no arguments, return full matrix
  if (is.null(alt_name) && is.null(crit_name)) {
    return(perf)  # ⚠️ 直接返回，不进行任何修改
  }
  ...
}
```

**分析**：
- `get_perf()` **直接返回** `self$task_data$perf`，**不进行任何修改**
- 如果 `perf` 的 rownames 有重复，会直接传递到 `A`

### 步骤 2: 检查重复（不修改数据）
```r
# 第172-173行
private$check_duplicated_alternatives(A, alt)  # 只检查，不修改
private$check_constant_criteria(A, crit)       # 只检查，不修改
```

**分析**：
- 这两个函数**只检查，不修改**数据
- 如果 `A` 的 rownames 有重复，这里会报错（如果检查正确）

### 步骤 3: 转换方向（关键步骤！）
```r
# 第175行
A_conv <- private$convert_directions_for_rmcda(A, d, crit)
```

**`convert_directions_for_rmcda()` 的实现**（第127-148行）：
```r
convert_directions_for_rmcda = function(A, d, crit) {
  A_conv <- as.matrix(A)
  storage.mode(A_conv) <- "numeric"
  
  # Explicitly preserve rownames/colnames to prevent loss during conversion
  if (!is.null(rownames(A))) {
    rownames(A_conv) <- rownames(A)  # ⚠️ 直接复制，不检查重复！
  }
  if (!is.null(colnames(A))) {
    colnames(A_conv) <- colnames(A)
  }
  
  for (j in seq_along(crit)) {
    if (d[j] == "min") {
      A_conv[, j] <- -A_conv[, j]
    }
  }
  A_conv
}
```

**⚠️ 潜在问题**：
- `rownames(A_conv) <- rownames(A)` **直接复制** rownames，**不检查是否重复**
- 如果 `A` 的 rownames 有重复，会**直接复制**到 `A_conv`
- 虽然 `check_duplicated_alternatives()` 应该已经检查过了，但**检查是在转换之前**进行的

### 步骤 4: 验证 rownames（在调用 RMCDA 之前）
```r
# 第188-190行
if (length(unique(rownames(A_conv))) != length(rownames(A_conv))) {
  stop("A_conv has duplicate rownames. RMCDA will merge rows with duplicate names, causing flow length mismatch.")
}
```

**分析**：
- 这里**检查** `A_conv` 的 rownames 是否重复
- 如果重复，会报错
- 但问题是：**为什么 `A_conv` 的 rownames 会重复？**

## 可能导致 rownames 重复的原因

### 原因 1: `task$get_perf()` 返回的矩阵 rownames 已经有重复

**场景**：
```r
# TaskDecision$initialize() 第137行
rownames(perf) <- self$task_data$alt

# 如果 self$task_data$alt 有重复（虽然理论上不应该）
alt <- c("A1", "A2", "A1")  # 重复的 "A1"
rownames(perf) <- alt  # ⚠️ 直接设置，会产生重复的 rownames！

# 但是，validate() 应该会检查 alt 的唯一性（第195行）
if (anyDuplicated(self$task_data$alt) > 0 || any(self$task_data$alt == "")) {
  stop("alternatives must be unique and non-empty")
}
```

**问题**：
- `rownames(perf) <- self$task_data$alt` 在 `validate()` **之前**执行（第137行 vs 第161行）
- 如果 `alt` 有重复，`validate()` 会报错，**不会创建对象**
- 所以理论上，`perf` 的 rownames **不应该**有重复

### 原因 2: `as.matrix(A)` 可能改变 rownames（不太可能）

**场景**：
```r
# convert_directions_for_rmcda() 第128行
A_conv <- as.matrix(A)
```

**分析**：
- `as.matrix()` **应该保留** dimnames（rownames 和 colnames）
- 但在某些特殊情况下（例如，如果 `A` 是 data.frame 且行名有重复），可能会改变行为
- 不过，代码中已经显式设置了 `rownames(A_conv) <- rownames(A)`，所以这应该不是问题

### 原因 3: `storage.mode(A_conv) <- "numeric"` 可能影响 rownames（不太可能）

**场景**：
```r
# convert_directions_for_rmcda() 第129行
storage.mode(A_conv) <- "numeric"
```

**分析**：
- `storage.mode()` **不应该**影响 dimnames
- 但为了安全，代码中在设置 `storage.mode()` **之后**才设置 rownames（第133-134行）
- 所以这应该不是问题

### 原因 4: 列操作可能影响 rownames（不太可能）

**场景**：
```r
# convert_directions_for_rmcda() 第141-142行
for (j in seq_along(crit)) {
  if (d[j] == "min") {
    A_conv[, j] <- -A_conv[, j]  # 列操作
  }
}
```

**分析**：
- 列操作（`A_conv[, j] <- ...`）**不应该**影响 rownames
- 所以这应该不是问题

## 关键发现

### 问题所在：`convert_directions_for_rmcda()` 直接复制 rownames，不检查重复

**当前代码**（第133-134行）：
```r
if (!is.null(rownames(A))) {
  rownames(A_conv) <- rownames(A)  # ⚠️ 直接复制，不检查
}
```

**潜在问题**：
1. 如果 `A` 的 rownames 有重复（虽然理论上不应该），会**直接复制**到 `A_conv`
2. `check_duplicated_alternatives()` 在转换**之前**检查，但如果检查有遗漏，问题会传递到 `A_conv`
3. 虽然最后有检查（第188行），但**问题已经产生了**

### 为什么之前没有这个问题？

1. **之前的代码可能没有显式保留 rownames**
   - 如果 `as.matrix()` 丢失了 rownames，然后被错误地重新设置，可能会产生重复
   - 现在显式保留 rownames，但如果原始 rownames 有重复，会直接复制

2. **之前的检查可能不够严格**
   - `check_duplicated_alternatives()` 可能只检查内容重复，不检查 rownames 重复
   - 现在添加了 rownames 重复检查，但检查是在转换**之后**进行的

## 建议的修复

### 方案 1: 在 `convert_directions_for_rmcda()` 中检查 rownames 重复

```r
convert_directions_for_rmcda = function(A, d, crit) {
  A_conv <- as.matrix(A)
  storage.mode(A_conv) <- "numeric"
  
  # Check for duplicate rownames before copying
  if (!is.null(rownames(A))) {
    if (any(duplicated(rownames(A)))) {
      dup_rownames <- unique(rownames(A)[duplicated(rownames(A))])
      stop(sprintf(
        "Input matrix A has duplicate rownames: %s. This should not happen if TaskDecision validation passed.",
        paste(dup_rownames, collapse = ", ")
      ))
    }
    rownames(A_conv) <- rownames(A)
  }
  
  if (!is.null(colnames(A))) {
    colnames(A_conv) <- colnames(A)
  }
  
  # ... 方向转换 ...
  
  A_conv
}
```

### 方案 2: 确保 `check_duplicated_alternatives()` 在转换之前正确检查

当前代码已经在转换之前检查了（第172行），但可以确保检查更严格。

## 总结

**根本原因**：
- `convert_directions_for_rmcda()` **直接复制** rownames，不检查是否重复
- 如果输入的 `A` 的 rownames 有重复（虽然理论上不应该），会直接传递到 `A_conv`
- 虽然最后有检查，但问题已经在转换过程中产生了

**为什么之前没有这个问题**：
- 可能之前的代码没有显式保留 rownames，或者检查不够严格
- 现在显式保留 rownames，但如果原始 rownames 有重复，会直接复制

**建议**：
- 在 `convert_directions_for_rmcda()` 中，在复制 rownames 之前检查是否重复
- 这样可以**提前发现问题**，而不是等到最后才检查

