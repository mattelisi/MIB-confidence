# clear workspace
rm(list=ls())
hablar::set_wd_to_script_path()

library(tidyverse)
library(fs)
library(stringr)

# -----------------------------------------------------------------------------
# load data and build dataset

# the data are in the the local subolder 'data'
data_path <- base_path <- "../data/"
folder_paths <- dir_ls(data_path)
folder_names <- dir(data_path)


# Iterate over all folder paths
d_all <- {}
for (i in seq_along(folder_paths)) {
  
  folder_path <- folder_paths[i]
  
  # Get the numbered subfolders
  subfolders <- dir(folder_path)
  
  d_pid <- {}
  
  # Iterate over subfolders
  for (sub in subfolders) {
    
    subfolder_path <- str_c(folder_path, "/", sub)
    
    # List files inside the subfolder
    files <- dir(subfolder_path)
    
    # Construct expected prefix and suffix
    prefix <- str_sub(folder_path, 9, 12)  #
    suffix <- str_pad(sub, width = 2, pad = "0")  # ubfolder is 2 digits
    
    # Select files matching the pattern (case-insensitive)
    selected_files <- files[str_detect(str_to_lower(files), 
                                       str_c("^", str_to_lower(prefix), suffix, "$"))]
    
    # Load the files
    if (length(selected_files) > 0) {
      for (file in selected_files) {
        file_path <- str_c(subfolder_path, "/", file)
        message("Loading file: ", file_path)
        
        d_i <- read_delim(file_path, delim = "\t", col_types = cols())
        d_i$PID <- prefix
        d_i$session <- sub
        
        d_pid <- rbind(d_pid, d_i)
        
      }
    }
  }
  
  d_all <- rbind(d_pid, d_all)
}

#
str(d_all)


d_all$session <- as.numeric(d_all$session)
d_all$block_c <- NA
for(i in unique(d_all$PID)){
  v <- d_all$block[d_all$PID==i]
  v0 <- v
  for(b in 2:length(v)){
    if(v0[b]<v0[b-1]){
      v[b:length(v)] <- v[b:length(v)] + v0[b-1]
    }
  }
  d_all$block_c[d_all$PID==i] <- v
  v <- NULL
}

write_csv(d_all, "MIB_data_all.csv")
str(d_all)

d_all <- read_csv("MIB_data_all.csv")

# -----------------------------------------------------------------------------
# prepare averaged datasets

# custom function to compute binomial standard error
binomSEM <- function (v){
  n <- sum(!is.na(v))
  sqrt((mean(v, na.rm=TRUE) * (1 - mean(v, na.rm=TRUE)))/n)
}

# custom function to compute bootstrapped standard error
bootMeanSE <- function (v, nsim = 1000, ...){
  bootmean <- function(v, i) mean(v[i], na.rm = T, ...)
  bootRes <- boot::boot(v, bootmean, nsim)
  return(sd(bootRes$t, na.rm = T))
}

# average dataset 1: average accuracy and confidence as a function of lead time (dim_onset)
dagb <- d_all %>%
  filter(!is.nan(d_all$angle_chosen)) %>%
  group_by(block_c, PID) %>%
  summarise(accuracy_value=mean(acc, na.rm=TRUE),
            accuracy_se = binomSEM(acc),
            confidence_value = mean(conf_rating, na.rm=TRUE),
            confidence_se = bootMeanSE(conf_rating)) 
write_csv(dagb, "MIB_averaged_block.csv")

# dag <- d_all %>%
#   filter(!is.nan(d_all$angle_chosen)) %>%
#   group_by(block_c, PID) %>%
#   summarise(accuracy_value=mean(acc, na.rm=TRUE),
#             accuracy_se = binomSEM(acc),
#             confidence_value = mean(conf_rating, na.rm=TRUE),
#             confidence_se = bootMeanSE(conf_rating)) 
# write_csv(dagb, "MIB_averaged_block.csv")


dag <- d_all %>%
  #filter(block_c>=4) %>%
  filter(!is.nan(d_all$angle_chosen)) %>%
  group_by(dim_onset, PID) %>%
  summarise(accuracy=mean(acc, na.rm=TRUE),
            accuracy_se = binomSEM(acc),
            confidence = mean(conf_rating, na.rm=TRUE),
            confidence_se = bootMeanSE(conf_rating)) 
write_csv(dag, "MIB_averaged.csv")


# Pivoting the data wider
dag_wide <- dag %>%
  pivot_wider(names_from = dim_onset, values_from = c(accuracy, accuracy_se, confidence, confidence_se), 
              names_glue = "{.value}_dim{dim_onset}")

# Print the transformed dataframe
str(dag_wide)
write_csv(dag_wide, "MIB_averaged_wideSPSS.csv")

# average dataset 1: confidence as a function of lead time (dim_onset) and accuracy
dag_conf <- d_all %>%
  filter(!is.nan(d_all$angle_chosen)) %>%
  group_by(dim_onset, PID, acc) %>%
  summarise(confidence = mean(conf_rating, na.rm=TRUE),
            confidence_se = bootMeanSE(conf_rating)) 
write_csv(dag_conf, "MIB_averaged_2.csv")


# Pivoting the data wider with both dim_onset and acc as part of the column names
dag_wide2 <- dag_conf %>%
  pivot_wider(names_from = c(dim_onset, acc), 
              values_from = c(confidence, confidence_se), 
              names_glue = "{.value}_dim{dim_onset}_acc{acc}")

str(dag_wide2)

write_csv(dag_wide2, "MIB_averaged_2_wideSPSS.csv")


# -----------------------------------------------------------------------------
# plots
library(patchwork)

pl1 <- dag %>%
  group_by(dim_onset) %>%
  summarise(accuracy = mean(accuracy_value),
            se = bootMeanSE(accuracy_value)) %>%
  ggplot(aes(x=dim_onset, y=accuracy))+
  geom_line()+
  geom_point(size=3)+
  geom_errorbar(aes(ymin=accuracy-se, 
                    ymax=accuracy+se),
                width=0) +
  geom_hline(yintercept=1/3, lty=3) +
  ggtitle("accuracy")

pl2 <- dag %>%
  group_by(dim_onset) %>%
  summarise(confidence = mean(confidence_value),
            se = bootMeanSE(confidence_value)) %>%
  ggplot(aes(x=dim_onset, y=confidence))+
  geom_line()+
  geom_point(size=3)+
  geom_errorbar(aes(ymin=confidence-se, 
                    ymax=confidence+se),
                width=0) +
  geom_hline(yintercept=1/3, lty=3) +
  ggtitle("confidence")

pl3 <- dag_conf %>%
  group_by(dim_onset, acc) %>%
  summarise(confidence = mean(confidence_value),
            se = bootMeanSE(confidence_value)) %>%
  mutate(acc = factor(acc)) %>%
  ggplot(aes(x=dim_onset, y=confidence, color=acc, group=acc))+
  geom_line()+
  geom_point(size=3)+
  geom_errorbar(aes(ymin=confidence-se, 
                    ymax=confidence+se),
                width=0) +
  geom_hline(yintercept=1/3, lty=3) +
  ggtitle("confidence")

pl1 + pl2 + pl3


ggsave("combined_plot.pdf", width=9, height=2.8)


block_acc <- dagb %>% group_by(block_c) %>%
  filter(block_c<=9) %>%
  summarise(accuracy = mean(accuracy_value),
            se = bootMeanSE(accuracy_value)) %>%
  ggplot(aes(x=block_c, y=accuracy))+
  geom_line()+
  geom_point(size=3)+
  geom_errorbar(aes(ymin=accuracy-se, 
                    ymax=accuracy+se),
                width=0) +
  geom_hline(yintercept=1/3, lty=3) +
  coord_cartesian(ylim=c(0.2,1))+
  labs(x="block")

block_conf <- dagb %>% group_by(block_c) %>%
  filter(block_c<=9) %>%
  summarise(confidence = mean(confidence_value),
            se = bootMeanSE(confidence_value)) %>%
  ggplot(aes(x=block_c, y=confidence))+
  geom_line()+
  geom_point(size=3)+
  geom_errorbar(aes(ymin=confidence-se, 
                    ymax=confidence+se),
                width=0) +
  geom_hline(yintercept=1/3, lty=3) +
  coord_cartesian(ylim=c(0.2,1))+
  labs(x="block")

block_acc + block_conf 
ggsave("block_plot.pdf", width=8, height=2.8)

# -----------------------------------------------------------------------------
# repeated measures ANOVA
dag$dim_onset <- factor(dag$dim_onset)
m_aov <- aov(accuracy_value ~ dim_onset + Error(PID/dim_onset), data=dag)
summary(m_aov)

conf_aov <- aov(confidence_value ~ dim_onset + Error(PID), data=dag)
summary(conf_aov)

conf2_aov <- aov(confidence_value ~ dim_onset*acc + Error(PID), data=dag_conf)
summary(conf2_aov)

# -----------------------------------------------------------------------------
# multilevel logistic regression
library(lme4)
library(lmerTest)
d_all$dim_onset <- factor(d_all$dim_onset)
mm <- glmer(acc ~ dim_onset + (1 | PID), family=binomial("logit"), data=d_all)
summary(mm)


mmc1 <- lmer(conf_rating ~ dim_onset + (1 | PID), data=d_all)
summary(mmc1)


mmc2 <- lmer(conf_rating ~ dim_onset*acc + (1 | PID), data=d_all)
summary(mmc2)

anova(mmc1, mmc2)






