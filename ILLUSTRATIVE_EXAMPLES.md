# mcdaHub 示例总结

基于包中三个 toy datasets 的完整示例说明。

## 一、数据集概览

### 1.1 cars 数据集

**场景**：汽车选择决策
- **替代方案**：5 款汽车（Economic, Sport, Luxury, TouringA, TouringB）
- **准则**：3 个（Price, Consumption, Power）
- **数据格式**：性能矩阵 + 权重 + 方向
- **适用算法**：TOPSIS, PROMETHEE
- **适用任务**：Ranking, Choice, Sorting

**数据特点**：
- Price: min（越低越好）
- Consumption: min（越低越好）
- Power: max（越高越好）
- 包含配置文件（prof）用于排序任务

### 1.2 supplier 数据集

**场景**：供应商选择决策
- **替代方案**：3 个供应商（Supplier_A, Supplier_B, Supplier_C）
- **准则**：3 个（Quality, Price, Delivery）
- **数据格式**：成对比较矩阵（pair_crit, pair_alt）
- **适用算法**：AHP
- **适用任务**：Ranking, Choice

**数据特点**：
- 使用 AHP 成对比较矩阵
- Quality 最重要，Price 次之，Delivery 第三
- Supplier_A: 高质量高价格
- Supplier_B: 中等质量中等价格，优秀交付
- Supplier_C: 低质量低价格

### 1.3 employee 数据集

**场景**：员工绩效评估
- **替代方案**：4 名员工（Employee_1 到 Employee_4）
- **准则**：3 个（Productivity, Teamwork, Innovation）
- **数据格式**：成对比较矩阵 + 长格式判断数据（judge_alt_profile）
- **适用算法**：AHPSort
- **适用任务**：Sorting

**数据特点**：
- 使用 AHPSort 方法
- 3 个类别：Poor, Average, Good
- 包含替代方案与配置文件的成对比较
- Productivity 最重要，Innovation 次之，Teamwork 第三

## 二、示例分类

### 2.1 基础算法示例

#### 示例 1：TOPSIS 排序任务（cars）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建排序任务
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 使用 TOPSIS 求解
decider <- DeciderTOPSIS$new()
result <- decider$solve(task)

# 查看结果
print(result)
```

**输出**：排序表，显示每款汽车的 TOPSIS 分数和排名

#### 示例 2：PROMETHEE 排序任务（cars）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建排序任务
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 使用 PROMETHEE 求解
decider <- DeciderPROMETHEE$new()
result <- decider$solve(task)

# 查看结果
print(result)
```

**输出**：排序表，显示每款汽车的净流量（net flow）和排名

#### 示例 3：AHP 排序任务（supplier）

```r
library(mcdaHub)
data(supplier, package = "mcdaHub")

# 创建排序任务
task <- TaskRanking$new(
  alt = supplier$alt,
  crit = supplier$crit,
  pair_crit = supplier$pair_crit,
  pair_alt = supplier$pair_alt
)

# 使用 AHP 求解
decider <- DeciderAHP$new()
result <- decider$solve(task)

# 查看结果
print(result)
```

**输出**：排序表，显示每个供应商的 AHP 分数和排名

### 2.2 选择任务示例

#### 示例 4：TOPSIS 选择任务（cars）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建选择任务
task_choice <- TaskChoice$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 使用 TOPSIS 求解
decider <- DeciderTOPSIS$new()
result_choice <- decider$solve(task_choice)

# 查看结果
print(result_choice)
```

**输出**：选择表，标识最佳汽车

#### 示例 5：AHP 选择任务（supplier）

```r
library(mcdaHub)
data(supplier, package = "mcdaHub")

# 创建选择任务
task_choice <- TaskChoice$new(
  alt = supplier$alt,
  crit = supplier$crit,
  pair_crit = supplier$pair_crit,
  pair_alt = supplier$pair_alt
)

# 使用 AHP 求解
decider <- DeciderAHP$new()
result_choice <- decider$solve(task_choice)

# 查看结果
print(result_choice)
```

**输出**：选择表，标识最佳供应商

### 2.3 分类任务示例

#### 示例 6：TOPSIS 分类任务（cars）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建分类任务
task_sorting <- TaskSorting$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction,
  cat_names = cars$cat_names,
  prof = cars$prof
)

# 使用 TOPSIS 求解
decider <- DeciderTOPSIS$new()
result_sorting <- decider$solve(task_sorting)

# 查看结果
print(result_sorting)
```

**输出**：分类表，显示每款汽车被分配到的类别（bad/good）

#### 示例 7：AHPSort 分类任务（employee）

```r
library(mcdaHub)
data(employee, package = "mcdaHub")

# 创建分类任务
task_sorting <- TaskSorting$new(
  alt = employee$alt,
  crit = employee$crit,
  cat_names = employee$cat_names,
  pair_crit = employee$pair_crit,
  judge_alt_profile = employee$judge_alt_profile,
  prof_order = employee$prof_order,
  assign_rule = "pessimistic"
)

# 使用 AHP (AHPSort) 求解
decider <- DeciderAHP$new()
result_sorting <- decider$solve(task_sorting)

# 查看结果
print(result_sorting)
```

**输出**：分类表，显示每名员工被分配到的绩效类别（Poor/Average/Good）

### 2.4 算法比较示例

#### 示例 8：TOPSIS vs PROMETHEE（cars）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建排序任务
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 使用 TOPSIS 求解
decider_topsis <- DeciderTOPSIS$new()
result_topsis <- decider_topsis$solve(task)
print(result_topsis)

# 使用 PROMETHEE 求解
decider_promethee <- DeciderPROMETHEE$new()
result_promethee <- decider_promethee$solve(task)
print(result_promethee)

# 比较算法相关性
analyzer <- AlgoRankCorrelation$new(
  task = task,
  decider = list(decider_topsis, decider_promethee)
)
corr <- analyzer$calculate()
print(analyzer)
```

**输出**：
- 两个算法的排序结果
- 算法间的 Spearman 相关性矩阵

### 2.5 敏感性分析示例

#### 示例 9：权重扰动分析（cars + PROMETHEE）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建排序任务
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 创建决策器
decider_promethee <- DeciderPROMETHEE$new()

# 创建权重扰动分析对象
wp <- WeightPerturbation$new(
  task = task,
  decider = decider_promethee,
  perturb_rg = 0.3,    # 30% 扰动范围
  perturb_n = 51       # 每个准则 51 个扰动点
)

# 执行扰动分析
wp$weight_perturb()

# 提取排序矩阵
rank_mat <- wp$perturb_rank()

# 可视化排序稳定性（标准差）
wp$perturb_stab_plot(type = "sd")

# 可视化排序轨迹
wp$perturb_stab_plot(type = "trajectory")

# 计算相关性矩阵
corr <- wp$perturb_rank_corr(method = "spearman")

# 可视化相关性热图
wp$perturb_corr_heatmap()
```

**输出**：
- 排序矩阵（场景 × 替代方案）
- 排序稳定性图（标准差）
- 排序轨迹图
- 相关性矩阵和热图

#### 示例 10：权重扰动分析（cars + TOPSIS）

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 创建排序任务
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 创建决策器
decider_topsis <- DeciderTOPSIS$new()

# 创建权重扰动分析对象
wp <- WeightPerturbation$new(
  task = task,
  decider = decider_topsis,
  perturb_rg = 0.2,    # 20% 扰动范围
  perturb_n = 100      # 每个准则 100 个扰动点
)

# 执行扰动分析
wp$weight_perturb()

# 可视化
wp$perturb_stab_plot(type = "trajectory")
wp$perturb_stab_plot(type = "sd")
```

**输出**：TOPSIS 算法的排序稳定性分析

## 三、数据集与示例映射表

| 数据集 | 适用算法 | 适用任务类型 | 特殊功能 |
|--------|---------|-------------|---------|
| **cars** | TOPSIS, PROMETHEE | Ranking, Choice, Sorting | 敏感性分析、算法比较 |
| **supplier** | AHP | Ranking, Choice | 成对比较矩阵 |
| **employee** | AHPSort | Sorting | 长格式判断数据 |

## 四、示例使用场景

### 4.1 教学场景

1. **基础算法学习**：
   - 示例 1-3：展示不同算法的基本使用
   - 示例 4-5：展示选择任务
   - 示例 6-7：展示分类任务

2. **算法比较**：
   - 示例 8：展示如何比较不同算法

3. **敏感性分析**：
   - 示例 9-10：展示权重扰动分析

### 4.2 研究场景

1. **算法性能评估**：
   - 使用示例 8 比较不同算法
   - 使用示例 9-10 进行敏感性分析

2. **方法验证**：
   - 使用不同数据集验证算法实现

### 4.3 实际应用场景

1. **汽车选择**（cars）：
   - 个人购车决策
   - 车队管理

2. **供应商选择**（supplier）：
   - 采购决策
   - 供应商评估

3. **员工评估**（employee）：
   - 绩效管理
   - 人才分类

## 五、完整工作流示例

### 5.1 完整的决策分析流程

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 步骤 1：创建任务
task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 步骤 2：使用多个算法求解
decider_topsis <- DeciderTOPSIS$new()
decider_promethee <- DeciderPROMETHEE$new()

result_topsis <- decider_topsis$solve(task)
result_promethee <- decider_promethee$solve(task)

# 步骤 3：比较算法结果
analyzer <- AlgoRankCorrelation$new(
  task = task,
  decider = list(decider_topsis, decider_promethee)
)
corr <- analyzer$calculate()
print(analyzer)

# 步骤 4：敏感性分析
wp <- WeightPerturbation$new(
  task = task,
  decider = decider_promethee,
  perturb_rg = 0.3,
  perturb_n = 51
)
wp$weight_perturb()

# 步骤 5：可视化结果
wp$perturb_stab_plot(type = "trajectory")
wp$perturb_stab_plot(type = "sd")
wp$perturb_corr_heatmap()
```

## 六、数据集的详细说明

### 6.1 cars 数据集结构

```r
cars
├── alt: 替代方案名称（5 个）
├── crit: 准则名称（3 个）
├── perf: 性能矩阵（5 × 3）
├── weight: 权重向量（3 个）
├── direction: 方向向量（3 个）
├── cat_names: 类别名称（2 个）
└── prof: 配置文件矩阵（1 × 3）
```

### 6.2 supplier 数据集结构

```r
supplier
├── alt: 替代方案名称（3 个）
├── crit: 准则名称（3 个）
├── pair_crit: 准则成对比较矩阵（3 × 3）
└── pair_alt: 替代方案成对比较矩阵列表（3 个矩阵，每个 3 × 3）
```

### 6.3 employee 数据集结构

```r
employee
├── alt: 替代方案名称（4 个）
├── crit: 准则名称（3 个）
├── cat_names: 类别名称（3 个）
├── pair_crit: 准则成对比较矩阵（3 × 3）
├── judge_alt_profile: 长格式判断数据（data.frame）
└── prof_order: 配置文件顺序（2 个）
```

## 七、示例总结

### 7.1 按数据集分类

**cars 数据集支持**：
- TOPSIS ranking/choice/sorting
- PROMETHEE ranking/choice/sorting
- 敏感性分析
- 算法比较

**supplier 数据集支持**：
- AHP ranking
- AHP choice

**employee 数据集支持**：
- AHPSort sorting

### 7.2 按功能分类

**基础功能**：
- 3 个算法（TOPSIS, PROMETHEE, AHP）
- 3 个任务类型（Ranking, Choice, Sorting）
- 10+ 个基础示例

**高级功能**：
- 敏感性分析（权重扰动）
- 算法比较（相关性分析）
- 可视化（稳定性图、热图）

### 7.3 覆盖范围

- ✅ 所有主要算法
- ✅ 所有任务类型
- ✅ 分析工具
- ✅ 可视化功能
- ✅ 实际应用场景

## 八、使用建议

### 8.1 初学者

1. 从示例 1 开始（TOPSIS ranking）
2. 尝试示例 2（PROMETHEE ranking）
3. 尝试示例 3（AHP ranking）
4. 理解不同算法的差异

### 8.2 进阶用户

1. 尝试示例 8（算法比较）
2. 尝试示例 9（敏感性分析）
3. 修改参数，观察结果变化

### 8.3 研究人员

1. 使用示例 8 进行算法比较研究
2. 使用示例 9-10 进行敏感性分析研究
3. 基于这些示例开发新的分析方法

## 九、扩展示例

### 9.1 自定义权重

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

# 使用自定义权重
custom_weight <- c(0.5, 0.3, 0.2)  # 更重视价格

task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = custom_weight,
  direction = cars$direction
)

decider <- DeciderTOPSIS$new()
result <- decider$solve(task)
print(result)
```

### 9.2 多算法综合比较

```r
library(mcdaHub)
data(cars, package = "mcdaHub")

task <- TaskRanking$new(
  alt = cars$alt,
  crit = cars$crit,
  perf = cars$perf,
  weight = cars$weight,
  direction = cars$direction
)

# 创建多个决策器
decider1 <- DeciderTOPSIS$new()
decider2 <- DeciderPROMETHEE$new()
decider3 <- DeciderAHP$new()  # 如果可用

# 比较所有算法
analyzer <- AlgoRankCorrelation$new(
  task = task,
  decider = list(decider1, decider2)
)
corr <- analyzer$calculate()
print(analyzer)
```

## 十、总结

mcdaHub 包提供了三个精心设计的 toy datasets，支持：

1. **10+ 个基础示例**：涵盖所有算法和任务类型
2. **敏感性分析示例**：展示权重扰动分析
3. **算法比较示例**：展示多算法比较
4. **完整工作流**：从任务创建到结果分析

这些示例覆盖了包的所有主要功能，适用于教学、研究和实际应用。

