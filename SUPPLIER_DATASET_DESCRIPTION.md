# Supplier 数据集详细描述

## 一、数据集概述

**supplier** 是一个用于演示 AHP（层次分析法）的 toy 数据集，专门设计用于供应商选择决策场景。该数据集使用成对比较矩阵（pairwise comparison matrices）来表示决策者的判断，适用于 AHP 排序和选择任务。

## 二、应用场景

**决策问题**：供应商选择（Supplier Selection）

**决策背景**：在采购决策中，需要从多个供应商中选择最佳供应商，考虑多个评估准则。

## 三、数据结构

### 3.1 基本组件

数据集是一个包含以下 4 个组件的列表：

```r
supplier <- list(
  alt = ...,        # 替代方案名称
  crit = ...,       # 准则名称
  pair_crit = ...,  # 准则成对比较矩阵
  pair_alt = ...    # 替代方案成对比较矩阵列表
)
```

### 3.2 替代方案（Alternatives）

**数量**：3 个供应商

**名称**：
- `Supplier_A`
- `Supplier_B`
- `Supplier_C`

**供应商特征**（基于成对比较结果）：
- **Supplier_A**：高质量、高价格、良好交付
- **Supplier_B**：中等质量、中等价格、优秀交付
- **Supplier_C**：低质量、低价格、交付较慢

### 3.3 评估准则（Criteria）

**数量**：3 个准则

**名称**：
- `Quality`（质量）
- `Price`（价格）
- `Delivery`（交付）

**准则说明**：
- **Quality**：产品/服务质量，越高越好（max 方向）
- **Price**：成本考虑，越低越好（min 方向，但在 AHP 中通过成对比较矩阵体现）
- **Delivery**：交付时间和可靠性，越快越好（min 方向，但在 AHP 中通过成对比较矩阵体现）

## 四、成对比较矩阵

### 4.1 AHP 标度说明

数据集使用标准的 AHP 成对比较标度：

| 数值 | 含义 |
|------|------|
| 1 | 同等重要 |
| 2 | 稍微重要 |
| 3 | 明显重要 |
| 4 | 强烈重要 |
| 5 | 极端重要 |
| 1/2, 1/3, 1/4, 1/5 | 表示列元素比行元素更重要 |

### 4.2 准则成对比较矩阵（pair_crit）

**矩阵维度**：3 × 3

**矩阵内容**：
```
            Quality  Price  Delivery
Quality      1       3       4
Price       1/3      1       2
Delivery    1/4     1/2      1
```

**解释**：
- **Quality vs Price**：Quality 比 Price 明显重要（3），表示质量比价格更重要
- **Quality vs Delivery**：Quality 比 Delivery 强烈重要（4），表示质量比交付更重要
- **Price vs Delivery**：Price 比 Delivery 稍微重要（2），表示价格比交付稍微重要

**准则重要性排序**：
1. Quality（最重要）
2. Price（次重要）
3. Delivery（第三重要）

**计算得到的准则权重**（通过 AHP 特征向量法）：
- Quality: 约 0.625
- Price: 约 0.239
- Delivery: 约 0.136

### 4.3 替代方案成对比较矩阵（pair_alt）

**结构**：包含 3 个矩阵的列表，每个矩阵对应一个准则

#### 4.3.1 Quality 准则下的比较矩阵

**矩阵维度**：3 × 3

**矩阵内容**：
```
            Supplier_A  Supplier_B  Supplier_C
Supplier_A      1          2          3
Supplier_B     1/2         1          2
Supplier_C     1/3        1/2         1
```

**解释**：
- Supplier_A 的质量最好（比 Supplier_B 稍微好，比 Supplier_C 明显好）
- Supplier_B 的质量中等（比 Supplier_C 稍微好）
- Supplier_C 的质量较差

**质量排序**：Supplier_A > Supplier_B > Supplier_C

#### 4.3.2 Price 准则下的比较矩阵

**矩阵维度**：3 × 3

**矩阵内容**：
```
            Supplier_A  Supplier_B  Supplier_C
Supplier_A      1         1/2        1/3
Supplier_B      2          1         1/2
Supplier_C      3          2          1
```

**解释**：
- Supplier_C 的价格最低（比 Supplier_B 稍微低，比 Supplier_A 明显低）
- Supplier_B 的价格中等（比 Supplier_A 稍微低）
- Supplier_A 的价格较高

**价格排序**（从低到高）：Supplier_C < Supplier_B < Supplier_A

**注意**：在 AHP 中，对于 min 方向的准则（如价格），通过成对比较矩阵直接体现相对优劣，无需转换。

#### 4.3.3 Delivery 准则下的比较矩阵

**矩阵维度**：3 × 3

**矩阵内容**：
```
            Supplier_A  Supplier_B  Supplier_C
Supplier_A      1         1/2         2
Supplier_B      2          1          3
Supplier_C     1/2        1/3         1
```

**解释**：
- Supplier_B 的交付最快（比 Supplier_A 稍微快，比 Supplier_C 明显快）
- Supplier_A 的交付中等（比 Supplier_C 明显快）
- Supplier_C 的交付较慢

**交付排序**（从快到慢）：Supplier_B > Supplier_A > Supplier_C

## 五、数据特征总结

### 5.1 供应商综合特征

基于成对比较矩阵，三个供应商的特征如下：

| 供应商 | Quality | Price | Delivery | 综合特征 |
|--------|---------|-------|----------|---------|
| **Supplier_A** | 最高 | 最高 | 中等 | 高质量高价格型 |
| **Supplier_B** | 中等 | 中等 | 最快 | 平衡型，优秀交付 |
| **Supplier_C** | 最低 | 最低 | 最慢 | 低成本低质量型 |

### 5.2 决策权衡

该数据集设计用于展示以下决策权衡：

1. **质量 vs 价格**：Supplier_A 提供最高质量但价格最高，Supplier_C 价格最低但质量最低
2. **交付 vs 其他**：Supplier_B 在交付方面表现突出
3. **综合平衡**：Supplier_B 在三个准则上相对平衡

### 5.3 预期结果

基于准则权重（Quality 最重要）和替代方案在各准则下的表现：

- **Supplier_A** 可能在综合评估中排名第一（因为质量最重要，且 Supplier_A 质量最好）
- **Supplier_B** 可能排名第二（平衡表现，且交付优秀）
- **Supplier_C** 可能排名第三（虽然价格最低，但质量最差，而质量权重最高）

**注意**：实际结果取决于 AHP 算法的计算，包括局部优先级和全局优先级的聚合。

## 六、使用场景

### 6.1 适用任务类型

- **Ranking**：对三个供应商进行完整排序
- **Choice**：从三个供应商中选择最佳供应商

### 6.2 适用算法

- **AHP**（Analytic Hierarchy Process）：专门设计用于 AHP 方法

### 6.3 不适用场景

- **TOPSIS**：需要性能矩阵（perf），不适用
- **PROMETHEE**：需要性能矩阵（perf），不适用
- **Sorting**：需要类别定义和配置文件，不适用

## 七、数据验证

### 7.1 一致性检查

AHP 方法会计算一致性比率（Consistency Ratio, CR）：
- CR < 0.1：判断一致性可接受
- CR ≥ 0.1：判断一致性不足，需要重新评估

### 7.2 矩阵性质

所有成对比较矩阵满足：
- **互反性**：如果 A 比 B 重要程度为 x，则 B 比 A 重要程度为 1/x
- **对角线为 1**：每个元素与自身比较为同等重要（1）

## 八、数据使用示例

### 8.1 排序任务

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

### 8.2 选择任务

```r
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

## 九、数据集设计意图

### 9.1 教学目的

1. **展示 AHP 方法**：演示如何使用成对比较矩阵进行决策
2. **理解层次结构**：展示准则权重和替代方案优先级的计算
3. **实际应用场景**：供应商选择是常见的 MCDA 应用场景

### 9.2 研究目的

1. **算法验证**：验证 AHP 算法的实现
2. **一致性分析**：分析判断的一致性
3. **敏感性分析**：可以用于权重敏感性分析

### 9.3 实际应用

1. **采购决策**：实际供应商选择决策
2. **供应商评估**：供应商绩效评估
3. **合同选择**：合同授予决策

## 十、与其他数据集的对比

| 特征 | supplier | cars | employee |
|------|----------|------|----------|
| **数据格式** | 成对比较矩阵 | 性能矩阵 | 成对比较矩阵 + 长格式 |
| **适用算法** | AHP | TOPSIS, PROMETHEE | AHPSort |
| **任务类型** | Ranking, Choice | Ranking, Choice, Sorting | Sorting |
| **替代方案数** | 3 | 5 | 4 |
| **准则数** | 3 | 3 | 3 |

## 十一、总结

**supplier** 数据集是一个精心设计的 AHP 示例数据集，具有以下特点：

1. **完整性**：包含准则比较和替代方案比较的完整数据
2. **真实性**：基于真实的供应商选择场景
3. **教学性**：清晰展示 AHP 方法的应用
4. **可验证性**：可以验证 AHP 算法的正确性

该数据集为 AHP 方法的学习、研究和应用提供了良好的起点。

