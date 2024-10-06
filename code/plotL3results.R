# set working directory
maindir <- file.path("~/Documents/Github/rf1-sra-socdoors")
codedir <- file.path("~/Documents/Github/rf1-sra-socdoors/code")

# Load necessary libraries
library("readxl")
library("ggplot2")
library("ggpubr")
library("tidyverse")
library("reshape2")
library("ppcor")
library("dplyr")
library("ggcorrplot")
library("psych")
library("dplyr")
library("tidyr")
library("writexl")

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
data_model3 <- data_filtered %>% dplyr::select(sub_id_rf1_data, sub_age, mspss_sum, oafem_total)
data_model4 <- data_filtered %>% dplyr::select(sub_id_rf1_data, sub_age, nbs_adult_sum, oafem_total)

# Clean up dataframes
data_model2_clean <- data_model2 %>%
  mutate(across(everything(), ~ ifelse(is.nan(.), NA, .))) %>%  # Convert NaNs to NAs
  drop_na()  # Remove rows with any NA values
data_model3_clean <- data_model3 %>%
  mutate(across(everything(), ~ ifelse(is.nan(.), NA, .))) %>%  # Convert NaNs to NAs
  drop_na()  # Remove rows with any NA values
data_model4_clean <- data_model4 %>%
  mutate(across(everything(), ~ ifelse(is.nan(.), NA, .))) %>%  # Convert NaNs to NAs
  drop_na()  # Remove rows with any NA values
################################################################################

# Calculate the median of the nbs_adult_sum column
median_nbs_adult_sum <- median(data_model2_clean$nbs_adult_sum, na.rm = TRUE)

# Create the new column nbs_adult_sum_split based on the median split
data_model2_clean <- data_model2_clean %>%
  mutate(nbs_adult_sum_split = ifelse(nbs_adult_sum <= median_nbs_adult_sum, "low", "high"))

# Check the new dataframe to see the new column
str(data_model2_clean)

# Define the path to the text file
text_file_path <- file.path("~/Documents/Github/rf1-sra-socdoors/imaging_plots/_thresh_corrp_tstat9_act.txt")

# Extract the file name without the extension and remove leading underscore (if any)
file_name <- sub("^_", "", tools::file_path_sans_ext(basename(text_file_path)))

# Read in the text file without a header
new_data <- read.table(text_file_path, header = FALSE, stringsAsFactors = FALSE)

# Name the column after the file name (without the leading underscore)
colnames(new_data) <- file_name

# Check the structure of new_data to ensure it's correct
str(new_data)

# Append new_data to data_model2_clean
data_model2_clean <- bind_cols(data_model2_clean, new_data)

# Check the final dataframe structure
str(data_model2_clean)

# Fig: Age X Need to Belong X Left LPFC Act (Social (win>loss) > Monetary (win>loss)) 
scatter <- ggplot(data_model2_clean, aes(x=sub_age, y=thresh_corrp_tstat9_act, col=nbs_adult_sum_split))+
  geom_point()+
  geom_point(shape=1)+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", fill="lightgray")+
  labs(x="Age",y="Left LPFC Activation\nSocial (win>loss) >\nMonetary (win>loss)", col="Need to Belong\n(NBS)")
  #labs(x="Age",y="Left LPFC Activation\nSocial (win>loss) >\nMonetary (win>loss)", col="Need to Belong\n(NBS)")+
  #stat_cor(method="pearson")
scatter + scale_color_manual(values = c("black", "gray")) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "gray"))
################################################################################

# Set file path for the CSV
csv_file <- "~/Documents/Github/rf1-sra-socdoors/code/filteredfunc_diff_VS_model-4_act.csv"

# Read the new CSV file without a header
new_data <- read.csv(csv_file, header = FALSE, check.names = FALSE)

# Assign a name to the column (since it had no header)
colnames(new_data) <- "filteredfunc_diff_VS_model_4_act"

data_model4_clean <- bind_cols(data_model4_clean, new_data)

# Create a median split of nbs_adult_sum and group into 'High' and 'Low'
data_model4_clean <- data_model4_clean %>%
  mutate(nbs_adult_sum_group = ifelse(nbs_adult_sum >= median(nbs_adult_sum, na.rm = TRUE), "High", "Low"))

# Generate the scatterplot
scatterplot <- ggplot(data_model4_clean, aes(x = oafem_total, y = filteredfunc_diff_VS_model_4_act, col = nbs_adult_sum_group)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, linetype = "dashed") +
  labs(x = "Financial Exploitation\n(OAFEM)", y = "VS activation\n Social (win>loss) >\nMonetary (win>loss)") +
  scale_color_manual(values = c("black", "gray"), name = "Need to Belong") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"))

# Print the plot
print(scatterplot)
################################################################################

# Load necessary libraries
library(dplyr)
library(ggplot2)

# Set file path for the CSV
csv_file <- "~/Documents/Github/rf1-sra-socdoors/code/filteredfunc_diff_VS_model-3_act.csv"

# Read the new CSV file without a header
new_data <- read.csv(csv_file, header = FALSE, check.names = FALSE)

# Assign a name to the column (since it had no header)
colnames(new_data) <- "filteredfunc_diff_VS_model_3_act"

# Ensure that the number of rows matches between data_model3_clean and new_data
if (nrow(data_model3_clean) == nrow(new_data)) {
  # Append the new data to the existing dataframe
  data_model3_clean <- bind_cols(data_model3_clean, new_data)
} else {
  stop("Row number mismatch between 'data_model3_clean' and the new CSV data.")
}

# Define the age groups (you can modify the age cutoff if needed)
age_cutoff <- 55
data_model3_clean <- data_model3_clean %>%
  mutate(age_group = ifelse(sub_age < age_cutoff, "Young", "Old"))

# Perform a median split on mspss_sum
median_mspss <- median(data_model3_clean$mspss_sum, na.rm = TRUE)
data_model3_clean <- data_model3_clean %>%
  mutate(mspss_group = ifelse(mspss_sum > median_mspss, "High", "Low"))

# Create the first scatterplot for the Young group
scatterplot_young <- ggplot(data_model3_clean %>% filter(age_group == "Young"),
                            aes(x = oafem_total, y = filteredfunc_diff_VS_model_3_act, col = mspss_group)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, linetype = "dashed") +
  labs(x = "OAFEM Total", y = "VS activation\n Social (win>loss) >\nMonetary (win>loss)", title = "Younger Adults") +
  scale_color_manual(values = c("black", "gray"), name = "Social\nSupport") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"))

# Create the second scatterplot for the Old group
scatterplot_old <- ggplot(data_model3_clean %>% filter(age_group == "Old"),
                          aes(x = oafem_total, y = filteredfunc_diff_VS_model_3_act, col = mspss_group)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, linetype = "dashed") +
  labs(x = "OAFEM Total", y = "VS activation\n Social (win>loss) >\nMonetary (win>loss)", title = "Older Adults") +
  scale_color_manual(values = c("black", "gray"), name = "Social\nSupport") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"))

# Print both plots
print(scatterplot_young)
print(scatterplot_old)

################################################################################

# Load necessary libraries
library(dplyr)
library(ggplot2)

# Set file path for the CSV
csv_file <- "~/Documents/Github/rf1-sra-socdoors/code/filteredfunc_diff_VS_model-3_nppi-dmn.csv"

# Read the new CSV file without a header
new_data <- read.csv(csv_file, header = FALSE, check.names = FALSE)

# Assign a name to the column (since it had no header)
colnames(new_data) <- "filteredfunc_diff_VS_model_3_nppi_dmn"

# Ensure that the number of rows matches between data_model3_clean and new_data
if (nrow(data_model3_clean) == nrow(new_data)) {
  # Append the new data to the existing dataframe
  data_model3_clean <- bind_cols(data_model3_clean, new_data)
} else {
  stop("Row number mismatch between 'data_model3_clean' and the new CSV data.")
}

# Define the age groups (you can modify the age cutoff if needed)
age_cutoff <- 55
data_model3_clean <- data_model3_clean %>%
  mutate(age_group = ifelse(sub_age < age_cutoff, "Young", "Old"))

# Perform a median split on mspss_sum
median_mspss <- median(data_model3_clean$mspss_sum, na.rm = TRUE)
data_model3_clean <- data_model3_clean %>%
  mutate(mspss_group = ifelse(mspss_sum > median_mspss, "High", "Low"))

# Create the first scatterplot for the Young group
scatterplot_young <- ggplot(data_model3_clean %>% filter(age_group == "Young"),
                            aes(x = oafem_total, y = filteredfunc_diff_VS_model_3_nppi_dmn, col = mspss_group)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, linetype = "dashed") +
  labs(x = "OAFEM Total", y = "DMN-VS connectivity\n Social (win>loss) >\nMonetary (win>loss)", title = "Younger Adults") +
  scale_color_manual(values = c("black", "gray"), name = "Social\nSupport") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"))

# Create the second scatterplot for the Old group
scatterplot_old <- ggplot(data_model3_clean %>% filter(age_group == "Old"),
                          aes(x = oafem_total, y = filteredfunc_diff_VS_model_3_act, col = mspss_group)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, linetype = "dashed") +
  labs(x = "OAFEM Total", y = "DMN-VS connectivity\n Social (win>loss) >\nMonetary (win>loss)", title = "Older Adults") +
  scale_color_manual(values = c("black", "gray"), name = "Social\nSupport") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"))

# Print both plots
print(scatterplot_young)
print(scatterplot_old)


# Create the second scatterplot for the Old group
scatterplot <- ggplot(data_model3_clean,
                          aes(x = sub_age, y = filteredfunc_diff_VS_model_3_act)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, linetype = "dashed", col="black") +
  labs(x = "Age", y = "VS Activation\n Social (win>loss) >\nMonetary (win>loss)") +
  scale_color_manual(values = c("black")) +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"))
print(scatterplot)