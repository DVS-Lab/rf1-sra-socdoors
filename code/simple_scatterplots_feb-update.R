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
data <- cbind(braindata,agedata)

# VS Social Reward [Social (win>loss) > Monetary (win>loss)] X Age
scatter <- ggplot(data,aes(x=Age,y=V1))+
  geom_point()+
  geom_smooth(method=lm, se=TRUE, level=0.99, fullrange=TRUE, linetype="dashed", colour="gray")+
  labs(x="Age",y="Social Reward (VS)")+
  stat_cor(method="pearson")
scatter + scale_color_hue() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
