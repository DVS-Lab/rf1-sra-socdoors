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
data_model2 <- data_filtered %>% dplyr::select(sub_id_rf1_data, sub_age, nbs_adult_sum, fevs_sum)