# Create dataset files for mcdaHub package
# This script creates the .rda files in the data/ directory
# Run this in R: source("create_data_files.R")

# Dataset 1: Cars
cars <- list(
  # 所有替代方案
  alt = c("Economic", "Sport", "Luxury", "TouringA", "TouringB"),
  
  # 所有指标
  crit = c("Price", "Consumption", "Power"),
  
  # 性能矩阵 (5 x 3)
  perf = matrix(
    c(
      15000, 7.5,  50,    
      29000, 9.0, 110,    
      38000, 8.5,  90,   
      26000, 9.0,  75,   
      25500, 7.0,  85    
    ),
    nrow = 5,
    ncol = 3,
    byrow = TRUE,
    dimnames = list(
      c("Economic", "Sport", "Luxury", "TouringA", "TouringB"),
      c("Price", "Consumption", "Power")
    )
  ),
  
  # 权重
  weight = c(0.4, 0.3, 0.3),
  
  # 优化方向
  direction = c("min", "min", "max"),
  
  # Sorting 专用部分
  cat_names = c("bad", "good"),       # 分类名称
  prof = matrix(          # limiting profile（FlowSort 示例）
    c(23000, 8, 80),
    nrow = 1,
    ncol = 3,
    byrow = TRUE,
    dimnames = list(
      "p1",  # internal profile name
      c("Price", "Consumption", "Power")
    )
  )
)

# Dataset 3: Supplier Selection AHP (for AHP ranking/choice tasks)
# Scenario: Selecting the best supplier based on multiple criteria
supplier <- list(
  # 所有替代方案（供应商）- 简化为3个
  alt = c("Supplier_A", "Supplier_B", "Supplier_C"),
  
  # 所有指标（评估准则）- 简化为3个
  crit = c("Quality", "Price", "Delivery"),
  
  # 准则之间的成对比较矩阵 (4 x 4)
  # 矩阵值表示：行准则相对于列准则的重要性
  # 1 = 同等重要, 2 = 稍微重要, 3 = 明显重要, 4 = 强烈重要, 5 = 极端重要
  # 小于1的值表示列准则更重要
  # Quality 最重要，Price 次之，Delivery 相对次要
  pair_crit = matrix(
    c(
      1,    3,    4,     # Quality vs (Quality, Price, Delivery)
      1/3,  1,    2,     # Price vs (Quality, Price, Delivery)
      1/4,  1/2,  1      # Delivery vs (Quality, Price, Delivery)
    ),
    nrow = 3,
    ncol = 3,
    byrow = TRUE,
    dimnames = list(
      c("Quality", "Price", "Delivery"),
      c("Quality", "Price", "Delivery")
    )
  ),
  
  # 每个准则下替代方案之间的成对比较矩阵列表
  pair_alt = list(
    # 准则1: Quality (质量越高越好)
    matrix(
      c(
        1,    2,    3,     # Supplier_A vs all
        1/2,  1,    2,     # Supplier_B vs all
        1/3,  1/2,  1      # Supplier_C vs all
      ),
      nrow = 3,
      ncol = 3,
      byrow = TRUE,
      dimnames = list(
        c("Supplier_A", "Supplier_B", "Supplier_C"),
        c("Supplier_A", "Supplier_B", "Supplier_C")
      )
    ),
    
    # 准则2: Price (价格越低越好)
    matrix(
      c(
        1,    1/2,  1/3,   # Supplier_A vs all
        2,    1,    1/2,   # Supplier_B vs all
        3,    2,    1      # Supplier_C vs all
      ),
      nrow = 3,
      ncol = 3,
      byrow = TRUE,
      dimnames = list(
        c("Supplier_A", "Supplier_B", "Supplier_C"),
        c("Supplier_A", "Supplier_B", "Supplier_C")
      )
    ),
    
    # 准则3: Delivery (交付时间越短越好)
    matrix(
      c(
        1,    1/2,  2,     # Supplier_A vs all
        2,    1,    3,     # Supplier_B vs all
        1/2,  1/3,  1      # Supplier_C vs all
      ),
      nrow = 3,
      ncol = 3,
      byrow = TRUE,
      dimnames = list(
        c("Supplier_A", "Supplier_B", "Supplier_C"),
        c("Supplier_A", "Supplier_B", "Supplier_C")
      )
    )
  )
)

# Dataset 4: Employee Performance AHPSort (for AHPSort sorting tasks)
# Scenario: Classifying employees into performance categories
employee <- list(
  # 所有替代方案（员工）- 简化为4个
  alt = c("Employee_1", "Employee_2", "Employee_3", "Employee_4"),
  
  # 所有指标（评估维度）- 简化为3个
  crit = c("Productivity", "Teamwork", "Innovation"),
  
  # 分类名称（绩效等级）- 简化为3个类别
  cat_names = c("Poor", "Average", "Good"),
  
  # 准则之间的成对比较矩阵 (3 x 3)
  # Productivity 最重要，Innovation 次之，Teamwork 相对次要
  pair_crit = matrix(
    c(
      1,    3,    1/2,   # Productivity vs (Productivity, Teamwork, Innovation)
      1/3,  1,    1/4,   # Teamwork vs (Productivity, Teamwork, Innovation)
      2,    4,    1      # Innovation vs (Productivity, Teamwork, Innovation)
    ),
    nrow = 3,
    ncol = 3,
    byrow = TRUE,
    dimnames = list(
      c("Productivity", "Teamwork", "Innovation"),
      c("Productivity", "Teamwork", "Innovation")
    )
  ),
  
  # AHPSort 长格式数据：替代方案与 profile 的成对比较
  # 3个类别需要2个profile: p1 (Poor-Average边界), p2 (Average-Good边界)
  judge_alt_profile = data.frame(
    criterion = c(
      rep("Productivity", 8),  # 4 employees × 2 profiles
      rep("Teamwork", 8),
      rep("Innovation", 8)
    ),
    alt = rep(rep(c("Employee_1", "Employee_2", "Employee_3", "Employee_4"), each = 2), 3),
    profile = rep(rep(c("p1", "p2"), 4), 3),
    value = c(
      # Productivity
      rep(c(1/2, 1/3), 1),  # Employee_1: Poor (< p1, < p2)
      rep(c(2, 1), 1),      # Employee_2: Average (> p1, < p2)
      rep(c(3, 2), 1),      # Employee_3: Good (> p1, > p2)
      rep(c(2.5, 1.5), 1),  # Employee_4: Average-Good边界 (> p1, > p2)
      
      # Teamwork
      rep(c(1.5, 1), 1),    # Employee_1: Average (> p1, < p2)
      rep(c(2.5, 1.5), 1),  # Employee_2: Good (> p1, > p2)
      rep(c(1/2, 1/3), 1),  # Employee_3: Poor (< p1, < p2)
      rep(c(2, 1), 1),      # Employee_4: Average (> p1, < p2)
      
      # Innovation
      rep(c(2.5, 1.5), 1),  # Employee_1: Good (> p1, > p2)
      rep(c(1.5, 1), 1),    # Employee_2: Average (> p1, < p2)
      rep(c(3, 2), 1),      # Employee_3: Good (> p1, > p2)
      rep(c(1/2, 1/3), 1)   # Employee_4: Poor (< p1, < p2)
    ),
    stringsAsFactors = FALSE
  ),
  
  # Profile 顺序
  prof_order = c("p1", "p2")
)

# Save datasets
if (!dir.exists("data")) {
  dir.create("data")
}

save(cars, file = "data/cars.rda", compress = "xz")
save(supplier, file = "data/supplier.rda", compress = "xz")
save(employee, file = "data/employee.rda", compress = "xz")

cat("Dataset files created successfully!\n")
cat("Files created:\n")
cat("  - data/cars.rda\n")
cat("  - data/supplier.rda\n")
cat("  - data/employee.rda\n")

