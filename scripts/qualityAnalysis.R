cat("\014") # clears console
rm(list = ls()) # clears global environment
try(dev.off(dev.list()["RStudioGD"]), silent = TRUE) # clears plots 
try(p_unload(p_loaded(), character.only = TRUE), silent = TRUE) # clears packages
options(scipen = 100) # disables scientific notation for entire R

# ------------------------------------------
# 0. Load Required Libraries
# ------------------------------------------
install.packages(c("tidyverse", "rpart", "rpart.plot", "randomForest", 
                   "caret", "rattle", "iml", "mlr", "lime", "plumber"))

library(tidyverse)
library(rpart)
library(rpart.plot)
library(randomForest)
library(caret)
library(rattle)
library(iml)
library(mlr)
library(lime)
library(plumber)

# ------------------------------------------
# 1. Load and Clean Data
# ------------------------------------------
df <- read.csv("quality-scores-explanation-codes-and-scores.csv", stringsAsFactors = FALSE)

df_clean <- df %>% select(-ends_with("_code"))
df_clean$grade <- as.factor(df_clean$grade)
df_clean$division <- as.factor(df_clean$division)
df_clean$store_type <- as.factor(df_clean$store_type)
df_clean$recorded_at <- as.POSIXct(df_clean$recorded_at, format="%Y-%m-%dT%H:%M:%S", tz="UTC")

essential <- c("usability", "metadata", "freshness", "completeness", "accessibility", "score")
df_filtered <- df_clean %>% filter(if_all(all_of(essential), ~ !is.na(.) & . > 0))

df_filtered <- df_filtered %>%
  mutate(service_group = case_when(
    grepl("Transit|Transportation|Parking", division, ignore.case = TRUE) ~ "Transportation",
    grepl("Health|Public Health|Shelter", division, ignore.case = TRUE) ~ "Health Services",
    grepl("Police|Fire|Paramedic", division, ignore.case = TRUE) ~ "Public Safety",
    grepl("Planning|Development|Heritage", division, ignore.case = TRUE) ~ "Urban Planning",
    grepl("Finance|Revenue|Accounting", division, ignore.case = TRUE) ~ "Financial Services",
    grepl("Clerk|Licensing|Legal|Registrar", division, ignore.case = TRUE) ~ "Administrative Services",
    grepl("Water|Energy|Waste", division, ignore.case = TRUE) ~ "Utilities / Environment",
    grepl("Parks|Forestry|Recreation", division, ignore.case = TRUE) ~ "Recreation / Environment",
    grepl("Housing|Social Services|Employment", division, ignore.case = TRUE) ~ "Social Services",
    grepl("Technology|Information|IT", division, ignore.case = TRUE) ~ "Technology / IT",
    grepl("Diversity|Equity|Human Rights", division, ignore.case = TRUE) ~ "Community Services",
    TRUE ~ "Others"
  ))

df_filtered$service_group <- as.factor(df_filtered$service_group)

# ------------------------------------------
# 2. Train/Test Split
# ------------------------------------------
set.seed(123)
index <- createDataPartition(df_filtered$grade, p = 0.75, list = FALSE)
train_data <- df_filtered[index, ]
test_data <- df_filtered[-index, ]

# ------------------------------------------
# 3. Perfect Splits Calculation & Barplot
# ------------------------------------------
number.perfect.splits <- apply(
  X = df_filtered %>% select(-grade, -division, -store_type, -recorded_at,-X_id, -score),
  MARGIN = 2,
  FUN = function(col) {
    t <- table(df_filtered$grade, col)
    sum(t == 0)
  }
)

order <- order(number.perfect.splits, decreasing = TRUE)
number.perfect.splits <- number.perfect.splits[order]

par(mar = c(10,2,2,2))
barplot(number.perfect.splits,
        main = "Number of perfect splits vs feature",
        xlab = "", ylab = "Perfect Splits", las = 2, col = "skyblue")

# ------------------------------------------
# 4. Decision Tree with Penalty Matrix & Pruning
# ------------------------------------------
penalty.matrix <- matrix(c(
  0, 1, 5,
  1, 0, 2,
  10, 2, 0
), nrow = 3, byrow = TRUE)

dt_model <- rpart(grade ~ usability + metadata + freshness + completeness + accessibility ,
                  data = train_data,
                  parms = list(loss = penalty.matrix),
                  method = "class")

rpart.plot(dt_model, type = 4, extra = 104, fallen.leaves = TRUE)

# Prune using optimal complexity parameter
cp.optim <- dt_model$cptable[which.min(dt_model$cptable[,"xerror"]),"CP"]
dt_model <- prune(dt_model, cp = cp.optim)

# Test the model
pred_dt <- predict(dt_model, test_data, type = "class")
confusionMatrix(pred_dt, test_data$grade)

# Export rules
rules <- unlist(asRules(dt_model))
writeLines(rules, "decision_tree_rules.txt")

# ------------------------------------------
# 5. Random Forest with Tuning
# ------------------------------------------
control <- trainControl(method = "cv", number = 5)
tune_grid <- expand.grid(mtry = c(2, 3, 4, 5))

rf_model <- caret::train(
  grade ~ usability + metadata + freshness + completeness + accessibility + service_group,
  data = train_data,
  method = "rf",
  trControl = control,
  tuneGrid = tune_grid,
  metric = "Accuracy"
)

pred_rf <- predict(rf_model, test_data)
confusionMatrix(pred_rf, test_data$grade)
varImpPlot(rf_model$finalModel)

# ------------------------------------------
# 6. SHAP Interpretation
# ------------------------------------------
train_subset <- train_data %>% 
  select(usability, metadata, freshness, completeness, accessibility, service_group, grade)

task <- makeClassifTask(data = train_subset, target = "grade")
library(mlr)

# 1. Define task
train_subset <- train_data %>% 
  select(usability, metadata, freshness, completeness, accessibility, service_group, grade)

task <- makeClassifTask(data = train_subset, target = "grade")

# 2. Define learner with probability output
rf_learner <- makeLearner("classif.randomForest", predict.type = "prob", ntree = 200)

# 3. Train the model (mlr::train)
rf_fit <- mlr::train(rf_learner, task)

# 4. SHAP interpretation using iml package
library(iml)

predictor <- Predictor$new(
  model = rf_fit,
  data = train_subset[, -which(names(train_subset) == "grade")],
  y = train_subset$grade,
  type = "prob"
)

# Global feature importance
imp <- FeatureImp$new(predictor, loss = "ce")
plot(imp)

# SHAP for a single test instance
shap <- Shapley$new(predictor, x.interest = test_data[1, c("usability", "metadata", "freshness", "completeness", "accessibility", "service_group")])
plot(shap)

