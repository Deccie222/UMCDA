# 分析：为什么会出现 `entering.flow length (%d) does not match alt length` 错误

## 问题描述

在 `DeciderPROMETHEE::compute_ranking_choice()` 中，调用 `RMCDA::apply.PROMETHEE()` 后，返回的 `entering.flow` 长度与 `alt` 长度不匹配。

## 数据流分析

### 1. TaskDecision 初始化阶段

```r
# TaskDecision$initialize() (第133-143行)
if (!is.null(self$task_data$perf)) {
  perf <- as.matrix(self$task_data$perf)
  if (nrow(perf) == length(self$task_data$alt) && ncol(perf) == length(self$task_data$crit)) {
    rownames(perf) <- self$task_data$alt  # ✅ 设置 rownames
    colnames(perf) <- self$task_data$crit  # ✅ 设置 colnames
    self$task_data$perf <- perf
  }
}
```

**关键点**：
- `TaskDecision` 会**强制设置** `rownames(perf) <- alt` 和 `colnames(perf) <- crit`
- 即使输入的 `perf` 矩阵已经有 rownames/colnames，也会被**覆盖**

### 2. DeciderPROMETHEE 获取矩阵

```r
# DeciderPROMETHEE::compute_ranking_choice() (第137-139行)
alt  <- task$alt_names()
crit <- task$crit_names()
A    <- task$get_perf()  # 获取矩阵，已经有 rownames/colnames
```

**关键点**：
- `A` 矩阵的 rownames 应该等于 `alt`
- `A` 矩阵的 colnames 应该等于 `crit`

### 3. 验证阶段

```r
# 第151-152行
private$check_duplicated_alternatives(A, alt)  # 检查重复行（基于内容）
private$check_constant_criteria(A, crit)       # 检查常数准则
```

**关键点**：
- `check_duplicated_alternatives()` 使用 `as.data.frame(A)` 和 `duplicated(df)` 检查
- 这个检查**只检查内容重复**，不检查 rownames 重复

### 4. 方向转换阶段

```r
# convert_directions_for_rmcda() (第116-127行)
convert_directions_for_rmcda = function(A, d, crit) {
  A_conv <- as.matrix(A)           # ✅ 保留 rownames/colnames
  storage.mode(A_conv) <- "numeric"
  for (j in seq_along(crit)) {
    if (d[j] == "min") {
      A_conv[, j] <- -A_conv[, j]
    }
  }
  A_conv  # 返回的矩阵应该保留 rownames/colnames
}
```

**关键点**：
- `as.matrix(A)` **会保留** dimnames（rownames 和 colnames）
- 转换后的 `A_conv` 应该有正确的 rownames/colnames

### 5. RMCDA 调用阶段

```r
# 第159-163行
result <- RMCDA::apply.PROMETHEE(
  A       = A_conv,    # 传入转换后的矩阵
  weights = w,
  type    = "II"
)
```

**关键点**：
- `RMCDA::apply.PROMETHEE` 接收矩阵 `A_conv`
- `RMCDA` 内部可能会：
  1. **根据 rownames 处理数据**：如果 rownames 有重复，可能会合并行
  2. **删除常数准则**：虽然我们已经检查，但 `RMCDA` 可能使用不同的判断标准
  3. **修改 rownames**：根据内部逻辑生成新的 rownames

## 可能的原因

### 原因 1：RMCDA 内部合并了重复的 rownames

**场景**：
- 虽然 `check_duplicated_alternatives()` 检查了内容重复
- 但如果 `A_conv` 的 rownames 有重复（即使内容不同），`RMCDA` 可能会合并这些行

**示例**：
```r
# 假设输入
alt <- c("A1", "A2", "A3")
A <- matrix(c(1,2,3, 4,5,6, 7,8,9), nrow=3)
rownames(A) <- c("A1", "A1", "A3")  # A1 和 A2 的 rownames 都是 "A1"（错误情况）

# TaskDecision 会覆盖为：
rownames(A) <- c("A1", "A2", "A3")  # ✅ 正确

# 但如果 TaskDecision 没有正确设置，或者后续被修改：
rownames(A_conv) <- c("A1", "A1", "A3")  # ❌ 重复的 rownames

# RMCDA 可能会合并前两行，导致返回的流向量只有 2 个元素
```

**检查点**：
- `convert_directions_for_rmcda()` 是否正确保留了 rownames？
- 是否有其他地方修改了 rownames？

### 原因 2：RMCDA 内部删除了常数准则

**场景**：
- 虽然 `check_constant_criteria()` 检查了方差为 0 的准则
- 但 `RMCDA` 可能使用不同的判断标准（例如，考虑数值精度）

**示例**：
```r
# 假设有一个准则的值非常接近（但不是完全相等）
A <- matrix(c(1, 1.0000001, 1.0000002,  # 几乎常数
              2, 3, 4),                  # 变化
            nrow=3, ncol=2)

# check_constant_criteria() 可能不会检测到（因为 var > 0）
# 但 RMCDA 内部可能会认为这是常数并删除
```

**检查点**：
- `check_constant_criteria()` 的阈值是否合适？
- 是否应该使用更严格的检查（例如，检查标准差或范围）？

### 原因 3：RMCDA 返回的流向量没有正确的 names

**场景**：
- `RMCDA::apply.PROMETHEE` 返回的流向量可能没有 names
- 或者 names 与输入的 rownames 不匹配

**代码处理**（第192-209行）：
```r
# align names
if (is.null(names(net.flow)))      names(net.flow)      <- alt
if (is.null(names(leaving.flow)))  names(leaving.flow)  <- alt
if (is.null(names(entering.flow))) names(entering.flow) <- alt

# 检查 names 是否覆盖所有 alt
if (!all(alt %in% names(net.flow))) {
  stop("Names of net.flow do not cover all alternatives.")
}
```

**关键点**：
- 如果 `RMCDA` 返回的流向量**长度不匹配**，即使设置了 names，也无法通过后续的 `[alt]` 索引

### 原因 4：convert_directions_for_rmcda 丢失了 rownames

**潜在问题**：
- 虽然 `as.matrix(A)` 应该保留 dimnames，但在某些情况下可能会丢失
- 例如，如果 `A` 是一个 data.frame 或特殊类型的对象

**检查**：
```r
# 在 convert_directions_for_rmcda() 中，应该显式保留 rownames/colnames
convert_directions_for_rmcda = function(A, d, crit) {
  A_conv <- as.matrix(A)
  storage.mode(A_conv) <- "numeric"
  
  # ✅ 显式保留 rownames/colnames
  rownames(A_conv) <- rownames(A)
  colnames(A_conv) <- colnames(A)
  
  # ... 方向转换 ...
  
  A_conv
}
```

## 建议的修复方案

### 方案 1：在 convert_directions_for_rmcda 中显式保留 rownames/colnames

```r
convert_directions_for_rmcda = function(A, d, crit) {
  A_conv <- as.matrix(A)
  storage.mode(A_conv) <- "numeric"
  
  # 显式保留 rownames/colnames（防止丢失）
  if (!is.null(rownames(A))) {
    rownames(A_conv) <- rownames(A)
  }
  if (!is.null(colnames(A))) {
    colnames(A_conv) <- colnames(A)
  }
  
  for (j in seq_along(crit)) {
    if (d[j] == "min") {
      A_conv[, j] <- -A_conv[, j]
    } else if (d[j] != "max") {
      stop(sprintf("Invalid direction '%s' for criterion %s", d[j], crit[j]))
    }
  }
  
  A_conv
}
```

### 方案 2：在调用 RMCDA 之前验证 rownames/colnames

```r
# 在 compute_ranking_choice() 中，调用 RMCDA 之前
A_conv <- private$convert_directions_for_rmcda(A, d, crit)

# 验证 rownames/colnames
if (is.null(rownames(A_conv)) || any(rownames(A_conv) == "")) {
  stop("A_conv must have non-empty rownames before calling RMCDA")
}
if (is.null(colnames(A_conv)) || any(colnames(A_conv) == "")) {
  stop("A_conv must have non-empty colnames before calling RMCDA")
}
if (length(unique(rownames(A_conv))) != length(rownames(A_conv))) {
  stop("A_conv has duplicate rownames. This will cause RMCDA to merge rows.")
}
if (!all(rownames(A_conv) == alt)) {
  stop("A_conv rownames do not match alt. Expected: ", paste(alt, collapse=", "))
}
if (!all(colnames(A_conv) == crit)) {
  stop("A_conv colnames do not match crit. Expected: ", paste(crit, collapse=", "))
}
```

### 方案 3：改进 check_duplicated_alternatives 以检查 rownames 重复

```r
check_duplicated_alternatives = function(A, alt) {
  # 检查 rownames 重复（即使内容不同，RMCDA 也可能合并）
  if (!is.null(rownames(A))) {
    if (any(duplicated(rownames(A)))) {
      dup_rownames <- rownames(A)[duplicated(rownames(A))]
      stop(sprintf(
        "Performance matrix has duplicate rownames: %s. RMCDA will merge rows with duplicate names.",
        paste(unique(dup_rownames), collapse = ", ")
      ))
    }
  }
  
  # 检查内容重复（原有逻辑）
  df <- as.data.frame(A, stringsAsFactors = FALSE)
  dup_logical <- duplicated(df)
  if (any(dup_logical)) {
    dup <- alt[dup_logical]
    stop(sprintf(
      "Performance matrix contains duplicated alternatives: %s. RMCDA merges identical rows, causing flow length mismatch.",
      paste(dup, collapse = ", ")
    ))
  }
}
```

## 总结

最可能的原因是：
1. **`convert_directions_for_rmcda()` 没有显式保留 rownames/colnames**，导致在某些情况下丢失
2. **`RMCDA::apply.PROMETHEE` 内部根据 rownames 处理数据**，如果 rownames 有重复或不符合预期，可能会合并行或修改结构
3. **缺少对 rownames 重复的检查**，只检查了内容重复

建议：
- 在 `convert_directions_for_rmcda()` 中显式保留 rownames/colnames
- 在调用 `RMCDA` 之前验证 rownames/colnames 的正确性和唯一性
- 改进 `check_duplicated_alternatives()` 以同时检查 rownames 重复和内容重复

