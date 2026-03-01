# 设置 cars 数据集

## 问题
如果遇到 `data(cars, package = "mcdaHub")` 警告说没有这个数据集，请按以下步骤操作：

## 解决方案

### 方法 1：重新生成文档并重新安装包（推荐）

在 R 中运行：

```r
# 设置工作目录
setwd("E:/mcdaHub/UMCDA")

# 重新生成文档（这会更新 NAMESPACE 和 .Rd 文件）
devtools::document()

# 重新安装包
devtools::install()

# 重新加载包
library(mcdaHub)

# 现在应该可以加载数据了
data(cars, package = "mcdaHub")
```

### 方法 2：使用开发模式加载（开发时推荐）

在 R 中运行：

```r
# 设置工作目录
setwd("E:/mcdaHub/UMCDA")

# 重新生成文档
devtools::document()

# 使用 load_all 加载开发版本（不需要重新安装）
devtools::load_all()

# 现在应该可以加载数据了
data(cars, package = "mcdaHub")
```

### 方法 3：直接加载数据文件（临时方案）

如果上述方法都不行，可以临时直接加载：

```r
# 直接加载 .rda 文件
load("E:/mcdaHub/UMCDA/data/cars.rda")
```

## 验证

运行以下命令验证数据集是否正确加载：

```r
# 检查数据是否存在
exists("cars")

# 查看数据结构
str(cars)

# 查看数据内容
cars
```

## 注意事项

1. 确保 `data/cars.rda` 文件存在
2. 确保 `R/data-cars.R` 文件存在且格式正确
3. 每次修改数据文件后，都需要重新生成文档和重新安装/加载包

