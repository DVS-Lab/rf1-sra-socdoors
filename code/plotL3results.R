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

data_model2_clean <- data_model2 %>%
  mutate(across(everything(), ~ ifelse(is.nan(.), NA, .))) %>%  # Convert NaNs to NAs
  drop_na()  # Remove rows with any NA values

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
  labs(x="Age",y="Left LPFC Activation\nSocial (win>loss) > Monetary (win>loss)", col="Need to Belong\n(NBS)")
  #labs(x="Age",y="Left LPFC Activation\nSocial (win>loss) > Monetary (win>loss)", col="Need to Belong\n(NBS)")+
  #stat_cor(method="pearson")
scatter + scale_color_manual(values = c("black", "gray")) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "gray"))