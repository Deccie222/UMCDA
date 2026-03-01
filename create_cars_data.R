# Create cars dataset file
# Run this in R: source("create_cars_data.R")

# Dataset: Cars
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

# Ensure data directory exists
if (!dir.exists("data")) {
  dir.create("data")
}

# Save dataset
save(cars, file = "data/cars.rda", compress = "xz")

cat("cars.rda file created successfully!\n")
cat("File location: data/cars.rda\n")

