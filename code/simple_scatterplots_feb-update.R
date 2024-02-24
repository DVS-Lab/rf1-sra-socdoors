# set working directory
setwd("~/Desktop")
maindir <- getwd()
datadir <- file.path("~/Documents/Github/rf1-sra-socdoors/code")

# load packages
library("readxl")
library("ggplot2")
library("ggpubr")

# import data
data <- read_excel("~/Documents/Github/rf1-sra-socdoors/code/SfNCovariatesSubListR.xlsx")
bardata <- read_excel("~/Documents/Github/rf1-sra-socdoors/code/SfNCovariatesSubListBAR.xlsx")
dataMSPSS <- read_excel("~/Documents/Github/rf1-sra-socdoors/code/SfNCovariatesSubListmspss.xlsx")
istart <- read_excel("~/Desktop/projects/manuscript_draft_istart/istart_vars-2.xlsx")

# Social Reward [Social (win>loss) > Monetary (win>loss)] X Age
scatter <- ggplot(data,aes(x=Age,y=social_reward))+
  geom_point()+
  geom_smooth(method=lm, se=TRUE, level=0.99, fullrange=TRUE, linetype="dashed", colour="gray")+
  labs(x="Age",y="Social Reward")+
  stat_cor(method="pearson")
scatter + scale_color_hue() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))

# PPI; MSPSS x Age scatter plot
scatter <- ggplot(dataMSPSS,aes(x=Age,y=precuneus, col=MSPSS))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, formula= y ~ x, level=0.99, se=TRUE, fullrange=TRUE, linetype="dashed", )+ #formula= y ~ x+I(x^2)
labs(x="Age",y="VS-Precuneus Connectivity (Win > Loss)")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))

# NPPI-DMN; DMN-Frontal Pole Connectivity x Age
scatter <- ggplot(data,aes(x=Age,y=frontalPole))+
  geom_point()+
  geom_smooth(method=lm, se=TRUE, level=0.99, fullrange=TRUE, linetype="dashed", colour="black")+
  labs(x="Age",y="Frontal Pole")+
  stat_cor(method="pearson")
scatter + scale_color_hue() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                    panel.background = element_blank(), axis.line = element_line(colour = "black"))

# OAFEM x Age scatter plot
scatter <- ggplot(data,aes(x=Age,y=TPJ, col=OAFEM))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, formula= y ~ x, level=0.99, se=TRUE, fullrange=TRUE, linetype="dashed")+ #formula= y ~ x+I(x^2)
  labs(x="Age",y="TPJ Activation (Win > Loss)")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))

# Age Histogram
# Layout to split the screen
layout(mat = matrix(c(1,2),2,1, byrow=TRUE),  height = c(1,8))

# Draw the boxplot and the histogram 
par(mar=c(0, 3.1, 1.1, 2.1))
boxplot(data$Age , horizontal=TRUE , xaxt="n" , col=c("#CCCCCC") , frame=F)
par(mar=c(4, 3.1, 1.1, 2.1))
hist(data$Age , col=c("#333366") , border=F , main="" , xlab="Age")



# ISTART Substance Use Histogram
# Layout to split the screen
layout(mat = matrix(c(1,2),2,1, byrow=TRUE),  height = c(1,8))

# Draw the boxplot and the histogram 
par(mar=c(0, 3.1, 1.1, 2.1))
boxplot(istart$SU , horizontal=TRUE , xaxt="n" , col=c("#CCCCCC") , frame=F)
par(mar=c(4, 3.1, 1.1, 2.1))
hist(istart$SU , col=c("#333366") , border=F , main="" , xlab="Substance Use")








# Deprecated: VS Bar Plot
p<-ggplot(data=bardata, aes(x=Condition, y=VS, fill=color)) +
  geom_bar(stat="identity")+
  labs(y="VS Activation")+
  geom_errorbar(aes(ymin=VS-se, ymax=VS+se), width=.2, position=position_dodge(.9))+
  theme_minimal()
p

# OAFEM Histogram
h<-hist(data$oafem_total)+
  labs(x="OAFEM Score")
h













#----------------------------------------------------------------------------------
# Left: Eig vs. Non-Eig


# Right: Eig vs. Non-Eig
scatter <- ggplot(data,aes(x=fullRight,y=fullRightEig))+
  geom_point()+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", colour="gray")+
  labs(x="Right Non-Eig",y="Right Eig")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
# https://r-graph-gallery.com/ggplot2-color.html

## Left Hemi, Ipsilateral: Crus I ~ GSR
# Cluster tstat 8 (SU-neg) TPJ
model1 <- lm(leftIpsiCrusI ~
               tsnr + fd_mean + GSR, data=data)
summary(model1)

# Partial Residual Plot
crModel <- crPlots(model1, 
                   smooth=FALSE, 
                   pch=20,
                   col="black",
                   bg="black",
                   col.lines="gray",
                   lwd=1,
                   grid=FALSE
)

# Non-Residualized Left Ipsi Crus I ~ GSR
scatter <- ggplot(data,aes(x=GSR,y=leftIpsiCrusI))+
  geom_point()+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", colour="gray")+
  labs(x="GSR",y="Left Ipsi Crus I")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))

## Heatmap for correlations between GSR and tsnr/fd_mean within tasks

doors <- data.frame(df_socialdoors$tsnrDoors, df_socialdoors$fdmeanDoors, df_socialdoors$GSRDoors)
socialdoors <- data.frame(df_socialdoors$tsnrSD, df_socialdoors$fdmeanSD, df_socialdoors$GSRSD)
ugdg <- data.frame(df_mid$tsnrUGDG, df_mid$fdmeanUGDG, df_mid$GSRUGDG)
mid <- data.frame(df_mid$tsnrMID, df_mid$fdmeanMID, df_mid$GSRMID)
sharedreward <- data.frame(df_sr$tsnrSR, df_sr$fdmeanSR, df_sr$GSRSR)

# Doors GSR ~ tsnr & fdmean
scatter <- ggplot(df_socialdoors, aes(x=fdmeanDoors, y=GSRDoors))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
scatter <- ggplot(df_socialdoors, aes(x=tsnrDoors, y=GSRDoors))+
  geom_point()+
  geom_point(shape=20,color="white")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "gray"))

# Socialdoors GSR ~ tsnr & fdmean
scatter <- ggplot(df_socialdoors, aes(x=fdmeanSD, y=GSRSD))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
scatter <- ggplot(df_socialdoors, aes(x=tsnrSD, y=GSRSD))+
  geom_point()+
  geom_point(shape=20,color="white")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "gray"))

# MID GSR ~ tsnr & fdmean
scatter <- ggplot(df_mid, aes(x=fdmeanMID, y=GSRMID))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
scatter <- ggplot(df_mid, aes(x=tsnrMID, y=GSRMID))+
  geom_point()+
  geom_point(shape=20,color="white")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "gray"))

# UGDG GSR ~ tsnr & fdmean
scatter <- ggplot(df_mid, aes(x=fdmeanUGDG, y=GSRUGDG))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
scatter <- ggplot(df_mid, aes(x=tsnrUGDG, y=GSRUGDG))+
  geom_point()+
  geom_point(shape=20,color="white")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "gray"))

# SR GSR ~ tsnr & fdmean
scatter <- ggplot(df_sr, aes(x=fdmeanSR, y=GSRSR))+
  geom_point()+
  geom_point(shape=1,color="black")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "black"))
scatter <- ggplot(df_sr, aes(x=tsnrSR, y=GSRSR))+
  geom_point()+
  geom_point(shape=20,color="white")+
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE, linetype="dashed", color="gray")+
  labs(x="GSR",y="fd_mean")+
  stat_cor(method="pearson")
scatter + scale_color_grey() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                     panel.background = element_blank(), axis.line = element_line(colour = "gray"))


###############################################################################
## Heat map of all correlations:
cormat <- round(cor(doors),2)
head(cormat)
get_lower_tri<-function(cormat){
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}
upper_tri <- get_upper_tri(cormat)
upper_tri
melted_cormat <- melt(upper_tri, na.rm = TRUE)
head(melted_cormat)
melted_cormat
ggheatmap <- ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "black")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Simple Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()
ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.5, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))

## Heat map of all correlations:
cormat <- round(cor(socialdoors),2)
head(cormat)
get_lower_tri<-function(cormat){
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}
upper_tri <- get_upper_tri(cormat)
upper_tri
melted_cormat <- melt(upper_tri, na.rm = TRUE)
head(melted_cormat)
melted_cormat
ggheatmap <- ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "black")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Simple Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()
ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.5, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))

## Heat map of all correlations:
cormat <- round(cor(ugdg),2)
head(cormat)
get_lower_tri<-function(cormat){
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}
upper_tri <- get_upper_tri(cormat)
upper_tri
melted_cormat <- melt(upper_tri, na.rm = TRUE)
head(melted_cormat)
melted_cormat
ggheatmap <- ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "black")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Simple Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()
ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.5, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))

## Heat map of all correlations:
cormat <- round(cor(mid),2)
head(cormat)
get_lower_tri<-function(cormat){
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}
upper_tri <- get_upper_tri(cormat)
upper_tri
melted_cormat <- melt(upper_tri, na.rm = TRUE)
head(melted_cormat)
melted_cormat
ggheatmap <- ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "black")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Simple Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()
ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.5, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))

## Heat map of all correlations:
cormat <- round(cor(sharedreward),2)
head(cormat)
get_lower_tri<-function(cormat){
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
get_upper_tri <- function(cormat){
  cormat[lower.tri(cormat)]<- NA
  return(cormat)
}
upper_tri <- get_upper_tri(cormat)
upper_tri
melted_cormat <- melt(upper_tri, na.rm = TRUE)
head(melted_cormat)
melted_cormat
ggheatmap <- ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "black")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Simple Pearson\nCorrelation") +
  theme_minimal()+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()
ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.5, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))
