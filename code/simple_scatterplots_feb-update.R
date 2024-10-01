# set working directory
setwd("~/Desktop")
maindir <- getwd()
datadir <- file.path("~/Documents/Github/rf1-sra-socdoors/code")

# load packages
library("readxl")
library("ggplot2")
library("ggpubr")

# import data
braindata <- read.table("~/Documents/Github/rf1-sra-socdoors/derivatives/fsl/palm/L3_model-1_task-socialdoors_type-act_cnum-4_cname-win-loss/L3_task-socialdoors_mask-VS_type-act_n75_cnum-4_cname-win-loss_single-task.csv")
agedata <- read_excel("~/Documents/Github/rf1-sra-socdoors/derivatives/fsl/randomise/L3_model-1_task-socialdoors_type-act_cnum-4_cname-win-loss/randomise_design_n75-age.xlsx")
demdata <- read_excel("~/Documents/Github/rf1-sra-socdoors/code/rf1-sra-socdoors_data-tracker_n75.xlsx")
data <- cbind(braindata,agedata)

# VS Social Reward [Social (win>loss) > Monetary (win>loss)] X Age
scatter <- ggplot(data,aes(x=Age,y=V1))+
  geom_point()+
  geom_smooth(method=lm, se=TRUE, level=0.99, fullrange=TRUE, linetype="dashed", colour="gray")+
  labs(x="Age",y="Social Reward (VS)")+
  stat_cor(method="pearson")
scatter + scale_color_hue() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))

# Demographics data; Age
hist(demdata$Age,
     main="Dist. Age", xlab="Age")

# Gender
gender <- c(41.25, 55.00, 3.75)
glabels <- c("Male 41%", "Female 55%", "Nonbinary 4%")
pie(gender,glabels)

# Race
race <- c(53, 26, 11, 8, 3)
rlabels <- c("White 53%", "Black/African American 26%", "Asian 11%", 
             "Two or more 8%", "Prefer not to respond 3%")
pie(race,rlabels)


