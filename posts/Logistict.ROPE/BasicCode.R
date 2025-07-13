# ==========================================
# STREAMLINED SPAM DETECTION WITH PCA
# ==========================================

# Load required libraries
library(tidyverse)
library(peRspective)
library(pROC)
library(FactoMineR)

# Load data directly from Kaggle
Dataset <- RKaggle::get_dataset(dataset = "ysfbil/exais-sms-dataset")

# ==========================================
# DATA PREPARATION
# ==========================================

# Clean column names and prepare for analysis
dataset_clean <- Dataset %>%
  rename(
    status = Status,
    is_spam = Spam,
    message = Message
  ) %>%
  mutate(
    text_id = paste0("msg_", row_number()),
    # Basic text features
    word_count = str_count(message, "\\w+"),
    word_count_sq = word_count^2,
    exclamation_count = str_count(message, "!"),
    x_count = str_count(message, "X+"),
    is_spam = factor(is_spam, levels = c(0, 1),
                            labels = c("ham", "spam"))
  )

# ==========================================
# PERSPECTIVE API SCORING (COMMENTED FOR SPEED)
# ==========================================

# Get emotion scores from Perspective API
# This section is commented out to save time during development
# Uncomment when ready to run full analysis

# perspective_scores <- dataset_clean %>%
#   prsp_stream(
#     text = message,
#     text_id = text_id,
#     score_model = c("THREAT", "TOXICITY", "INSULT", "SPAM",
#                    "INFLAMMATORY", "INCOHERENT", "UNSUBSTANTIAL",
#                    "FLIRTATION", "PROFANITY"),
#     safe_output = TRUE,
#     verbose = TRUE
#   )

# For development, load pre-saved scores or create dummy data

# ==========================================
# MERGE AND CLEAN DATA
# ==========================================

# When using real Perspective scores, merge like this:
scored_data <- dataset_clean %>%
  left_join(perspective_scores, by = "text_id") %>%
  filter(!(has_error = (!is.na(error) & error != "No Error"))) %>%
  mutate(across(c("THREAT", "TOXICITY", "INSULT", "SPAM",
                  "INFLAMMATORY", "INCOHERENT", "UNSUBSTANTIAL",
                  "FLIRTATION", "PROFANITY"), ~replace_na(.x, 0))) %>%
  select(-c("SPAM", "FLIRTATION"))

# ==========================================
# PCA
# ==========================================
pca_result <- PCA(scored_data %>% select(THREAT:PROFANITY), 
                  ncp = 3, graph = FALSE)

loadings <- pca_result$var$coord           # FactoMineR stores them here
round(loadings, 2)

pca_scores <- as_tibble(pca_result$ind$coord) %>%      # rows = messages
  set_names(c("pc_aggression", "pc_inflammatory", "pc_incoherence")) %>%
  mutate(text_id = scored_data$text_id)

model_data <- scored_data %>%          # still has word-level features
  select(-THREAT:-PROFANITY) %>%       # raw Perspective cols no longer needed
  left_join(pca_scores, by = "text_id")


# ==========================================
# LOGISTIC REGRESSION MODEL
# ==========================================

# Build the model with PCA interaction and word count effects
# The interaction between PC1 and PC2 captures how aggression and spam characteristics
# combine differently than their individual effects would suggest
# The word count polynomial captures the non-linear relationship with message length
model <- glm(
  is_spam ~ (scale(pc_aggression) + scale(pc_incoherence)) * 
    (scale(word_count) + scale(exclamation_count)), 
  data = model_data,
  family = binomial(link = "logit"), 
  control = list(maxit = 100, epsilon = 1e-8))


# Model summary shows coefficient estimates and significance

summary(model)

# ==========================================
# MODEL EVALUATION
# ==========================================

# Get predictions and calculate AUC
predictions <- predict(model, type = "response")
roc_result <- roc(model_data$is_spam, predictions)
auc_value <- auc(roc_result)

# Simple confusion matrix at 0.5 threshold
predicted_class <- ifelse(predictions > 0.5, 1, 0)
confusion_matrix <- table(Actual = model_data$is_spam, 
                          Predicted = predicted_class)

# Calculate basic metrics
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
precision <- confusion_matrix[2,2] / sum(confusion_matrix[,2])
recall <- confusion_matrix[2,2] / sum(confusion_matrix[2,])

# Print evaluation results
print(paste("AUC:", round(auc_value, 3)))
print(paste("Accuracy:", round(accuracy, 3)))
print(confusion_matrix)

