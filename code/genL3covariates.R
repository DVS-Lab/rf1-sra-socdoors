# set working directory
maindir <- file.path("~/Documents/Github/rf1-sra-socdoors")
codedir <- file.path("~/Documents/Github/rf1-sra-socdoors/code")

# Load necessary libraries
library(dplyr)
library(tidyr)
library(writexl)

# Read in the sublist_all.txt file
subs <- read.table(file.path(codedir, "sublist_all.txt"), header = FALSE, stringsAsFactors = FALSE)
# Convert subs to a vector
subs_vector <- subs$V1  # Assuming sub IDs are in the first column
# Read in the rf1_covariates_2024_09_09.csv file
data <- read.csv(file.path(codedir, "rf1_covariates_2024_09_09.csv"))
# Filter data to keep only rows with sub IDs present in the subs variable
data_filtered <- data %>% filter(sub_id_rf1_data %in% subs_vector)

# Specify model dataframes with different column combinations
data_model1 <- data_filtered %>% dplyr::select(sub_id_rf1_data, sub_age, nbs_adult_sum, fevs_sum)
data_model2 <- data_filtered %>% dplyr::select(sub_id_rf1_data, sub_age, mspss_sum, oafem_total)
data_model3 <- data_filtered %>% dplyr::select(sub_id_rf1_data, sub_age, nbs_adult_sum, oafem_total)
# Put all models in a list for easy iteration
models <- list(data_model1, data_model2, data_model3)

# Define a function that processes each model
process_model <- function(data, model_number) {
  
  # 1. Ensure NaN values are converted to NA
  data_clean <- data %>%
    mutate(across(everything(), ~ ifelse(is.nan(.), NA, .))) %>%  # Convert NaNs to NAs
    drop_na()  # Remove rows with any NA values
  
  # Check if any rows are left after drop_na()
  if (nrow(data_clean) == 0) {
    stop(paste("No data left after removing rows with missing values in model", model_number))
  }
  
  # 2. Write sub_id_rf1_data out as a separate .txt file
  write.table(data_clean$sub_id_rf1_data, 
              file = file.path(codedir, paste0("sublist_model-", model_number, ".txt")), 
              row.names = FALSE, col.names = FALSE)
  
  # 3. Mean-center all columns except for sub_id_rf1_data
  data_centered <- data_clean %>%
    mutate(across(-sub_id_rf1_data, scale, center = TRUE, scale = FALSE))  # Mean-center (no scaling)
  
  # 4. Create interaction terms for all combinations of mean-centered variables
  var_names <- colnames(data_centered)[-1]  # Exclude sub_id_rf1_data
  
  # Ensure there are valid variables to work with
  interaction_data <- data_centered
  
  # Check if variables have any non-NA values before calculating interaction terms
  for (i in 1:length(var_names)) {
    for (j in (i + 1):length(var_names)) {
      if (all(is.na(data_centered[[var_names[i]]])) || all(is.na(data_centered[[var_names[j]]]))) {
        next  # Skip interaction if one of the columns is fully NA
      }
      # Two-way interaction
      interaction_data[[paste0(var_names[i], "_x_", var_names[j])]] <- 
        data_centered[[var_names[i]]] * data_centered[[var_names[j]]]
      
      for (k in (j + 1):length(var_names)) {
        if (all(is.na(data_centered[[var_names[k]]]))) {
          next  # Skip if the third column is fully NA
        }
        # Three-way interaction
        interaction_data[[paste0(var_names[i], "_x_", var_names[j], "_x_", var_names[k])]] <- 
          data_centered[[var_names[i]]] * data_centered[[var_names[j]]] * data_centered[[var_names[k]]]
      }
    }
  }
  
  # 5. Write the processed data to an Excel file
  write_xlsx(interaction_data, file.path(codedir, paste0("design_model-", model_number, ".xlsx")))
  
  # Return the processed data
  return(interaction_data)
}

# Iterate over all models and process them
processed_models <- list()
for (i in 1:length(models)) {
  processed_models[[i]] <- process_model(models[[i]], i)
}

# processed_models now contains the interaction data for each model