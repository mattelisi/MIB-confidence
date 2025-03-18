# process gaze data
rm(list=ls())
hablar::set_wd_to_script_path()
library(tidyverse)
library(zoo)
library(mlisi)

d <- read_csv("./merged_gaze_data.csv")

# tobii timing is in microseconds
(d$device_time_stamp[60] - d$device_time_stamp[59])/1000

# length of baseline window based on RT
floor(min(d$tResp_1, na.rm=T) / (1/60))

# prep
d$trial_label <- paste(d$block, d$trial_n, sep="_")
d$pupil_avg <- (d$pupil_L_diameter + d$pupil_R_diameter)/2
d$evento <- as.character(d$events)
d$device_time_stamp <- d$device_time_stamp/1000 # transform in ms


# Function to process pupil data per participant
process_pupil_data <- function(d_i) {
  results <- list()
  
  for (pid in unique(d_i$PID)) {
    d_participant <- d_i %>% filter(PID == pid)
    
    for (acc_value in c(0,1)) {
      for (dim_value in c(2,5,8)) {
        
        d_subset <- d_participant %>%
          filter(acc == acc_value, dim_onset == dim_value)
        
        trial_labels <- unique(d_subset$trial_label)
        n_trials <- length(trial_labels)
        
        length_window <- 400
        
        pupil_matrix <- matrix(NA, nrow = n_trials, ncol = length_window)
        time_matrix <- matrix(NA, nrow = n_trials, ncol = length_window)
        
        for (i in seq_along(trial_labels)) {
          trial_data <- d_subset %>% filter(trial_label == trial_labels[i])
          
          # Interpolate missing pupil values
          if(any(is.na(trial_data$pupil_avg))){
            pupil_filled <- fillGap(trial_data$pupil_avg, sp = 1/60, max = 50, type = "linear")
          }
          
          # Baseline correction
          idx_bs_end <- 45 # which(trial_data$evento == "5")[1]
          baseline <- mean(pupil_filled[1:idx_bs_end], na.rm = TRUE)
          pupil_corrected <- pupil_filled - baseline
          
          # Align timestamps
          response_time <- trial_data$device_time_stamp[which(trial_data$evento == "5")[1]]
          aligned_time <- trial_data$device_time_stamp - response_time
          
          # Store values (ensuring they fit within length)
          index_1 <- which(abs(aligned_time+600)==min(abs(aligned_time+600)))
          index_2 <- min(index_1+(length_window-1), length(pupil_corrected))
          
          len <- length(pupil_corrected[index_1:index_2])
          pupil_matrix[i, 1:len] <- pupil_corrected[index_1:index_2]
          time_matrix[i, 1:len] <- aligned_time[index_1:index_2]
        }
        
        # Compute mean signal and standard error
        mean_signal <- colMeans(pupil_matrix, na.rm = TRUE)
        se_signal <- apply(pupil_matrix, 2, function(x) sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x))))
        
        time_v <- seq(-600, (-600+(length_window-1)*(1/60)*1000), by=(1/60)*1000)
        
        results[[length(results) + 1]] <- data.frame(
          time = time_v,
          mean_signal = filtCMA(mean_signal, 15), # smooth individual here
          se_signal = se_signal,
          acc = acc_value,
          dim_onset = dim_value,
          PID = pid
        )
      }
    }
  }
  return(bind_rows(results))
}

# Process data for all participants
df_results <- process_pupil_data(d)
str(df_results)

# Plot results
df_results %>%
  group_by(time, acc, dim_onset) %>%
  summarise(se = mlisi::se(mean_signal),
            pa = mean(mean_signal, na.rm=T)) -> dag_plot

# smooth mean traces
fW <- 15 # duration of moving average is fW * (1/60) seconds
dag_plot$pa[dag_plot$dim_onset==2 & dag_plot$acc==0] <- filtCMA(dag_plot$pa[dag_plot$dim_onset==2 & dag_plot$acc==0], fW)
dag_plot$pa[dag_plot$dim_onset==5 & dag_plot$acc==0] <- filtCMA(dag_plot$pa[dag_plot$dim_onset==5 & dag_plot$acc==0], fW)
dag_plot$pa[dag_plot$dim_onset==8 & dag_plot$acc==0] <- filtCMA(dag_plot$pa[dag_plot$dim_onset==8 & dag_plot$acc==0], fW)


dag_plot$pa[dag_plot$dim_onset==2 & dag_plot$acc==1] <- filtCMA(dag_plot$pa[dag_plot$dim_onset==2 & dag_plot$acc==1], fW)
dag_plot$pa[dag_plot$dim_onset==5 & dag_plot$acc==1] <- filtCMA(dag_plot$pa[dag_plot$dim_onset==5 & dag_plot$acc==1], fW)
dag_plot$pa[dag_plot$dim_onset==8 & dag_plot$acc==1] <- filtCMA(dag_plot$pa[dag_plot$dim_onset==8 & dag_plot$acc==1], fW)

dag_plot %>%
ggplot(aes(x = time/1000, y = pa, color = factor(acc), fill = factor(acc))) +
  geom_line(size = 1) +
  geom_ribbon(aes(ymin = pa - se, ymax = pa + se), alpha = 0.2, size=NA) +
  facet_wrap(~dim_onset) +
  geom_vline(xintercept=0, lty=2) +
  labs(x = "Time (s)", y = "Pupil size change (mm)", color = "Accuracy", fill = "Accuracy") +
  theme_minimal()

ggsave("pa_resp_onset.pdf", width=9, height=2.7)


########################################################################

# Plot results
df_results %>%
  group_by(time, acc) %>%
  summarise(se = mlisi::se(mean_signal),
            pa = mean(mean_signal, na.rm=T)) -> dag_plot

# smooth 
fW <- 15
dag_plot$pa[ dag_plot$acc==0] <- filtCMA(dag_plot$pa[dag_plot$acc==0], fW)
dag_plot$pa[ dag_plot$acc==1] <- filtCMA(dag_plot$pa[dag_plot$acc==1], fW)

dag_plot %>%
  ggplot(aes(x = time/1000, y = pa, color = factor(acc), fill = factor(acc))) +
  geom_line(size = 1) +
  geom_ribbon(aes(ymin = pa - se, ymax = pa + se), alpha = 0.2, size=NA) +
  geom_vline(xintercept=0, lty=2) +
  labs(x = "Time (s)", y = "Pupil size change (mm)", color = "Accuracy", fill = "Accuracy") +
  theme_minimal()

ggsave("pa_resp.pdf", width=4, height=2.7)
