# clear workspace
rm(list=ls())
hablar::set_wd_to_script_path()

library(tidyverse)
library(fs)
library(stringr)

# the data are in the the local subolder 'data'
data_path <- "../data/"
folder_paths <- dir_ls(data_path)
folder_names <- dir(data_path)


# Iterate over all folder paths
d_all <- {}
for (i in seq_along(folder_paths)) {
  
  folder_path <- folder_paths[i]
  folder_name <- folder_names[i]  # Extract corresponding folder name
  
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
    suffix <- str_pad(sub, width = 2, pad = "0")  # Ensure subfolder is 2 digits
    
    # Select files matching the pattern (case-insensitive)
    selected_files <- files[str_detect(str_to_lower(files), 
                                       str_c("^", str_to_lower(prefix), suffix, "$"))]
    
    # Load the selected files (Replace this with actual file loading code)
    if (length(selected_files) > 0) {
      for (file in selected_files) {
        file_path <- str_c(subfolder_path, "/", file)
        message("Loading file: ", file_path)
        
        d_i <- read_delim(file_path, delim = "\t", col_types = cols())
        d_i$PID <- prefix
        d_i$session <- file
        
        d_pid <- rbind(d_pid, d_i)
        
      }
    }
  }
  
  d_all <- rbind(d_pid, d_all)
}

# ------------------------------------------------------------------------------------
str(d_all)

library(lme4)
d_all$dim_onset <- factor(d_all$dim_onset)
mm <- glmer(acc ~ dim_onset + (1 | PID), family=binomial("logit"), data=d_all)
summary(mm)


library(mlisi)
binomSEM <- function (v){
  n <- sum(!is.na(v))
  sqrt((mean(v, na.rm=TRUE) * (1 - mean(v, na.rm=TRUE)))/n)
}

dag <- d_all %>%
  filter(!is.nan(d_all$angle_chosen)) %>%
  group_by(dim_onset, PID) %>%
  summarise(accuracy_value=mean(acc, na.rm=TRUE),
            accuracy_se = binomSEM(acc),
            confidence_value = mean(conf_rating, na.rm=TRUE),
            confidence_se = bootMeanSE(conf_rating)) 


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

library(patchwork)
pl1 + pl2


dag_conf <- d_all %>%
  filter(!is.nan(d_all$angle_chosen)) %>%
  group_by(dim_onset, PID, acc) %>%
  summarise(confidence_value = mean(conf_rating, na.rm=TRUE),
            confidence_se = bootMeanSE(conf_rating)) 

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

###

dag$dim_onset <- factor(dag$dim_onset)
m_aov <- aov(accuracy_value ~ dim_onset + Error(PID/dim_onset), data=dag)
summary(m_aov)


conf_aov <- aov(confidence_value ~ dim_onset + Error(PID), data=dag)
summary(conf_aov)

conf2_aov <- aov(confidence_value ~ dim_onset*acc + Error(PID), data=dag_conf)
summary(conf2_aov)


# 
# #%>%
#   # pivot_longer(
#   #   cols = -dim_onset, 
#   #   names_to = c("measure", "type"), # Separate column name into two parts
#   #   names_sep = "_", # Split column names at '_'
#   #   values_to = "value"
#   # ) %>%
#   # pivot_wider(
#   #   names_from = type, # Pivot 'type' back into separate columns
#   #   values_from = value
#   # )
# 
# # plot
# dag %>%
#   mutate(dim_onset=ifelse(measure=="accuracy", dim_onset+0.125, dim_onset-0.125)) %>%
#   ggplot(aes(x=dim_onset,
#              y=value,
#              ymin=value-se,
#              ymax=value+se,
#              color=measure))+
#   geom_point()+
#   geom_errorbar(width=0)+
#   geom_line()+
#   coord_cartesian(xlim=c(0,10), ylim=c(1/3, 1))+
#   geom_hline(yintercept=1/3, lty=2)+
#   theme_classic()+
#   labs(x="lead time (seconds)", y="")




