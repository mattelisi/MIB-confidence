rm(list=ls())

library(tidyverse)
library(fs)
library(mlisi)
hablar::set_wd_to_script_path()

# -----------------------------------------------------------------------------
# Behavioural data

# Define the base path
base_path <- "../data/96ml"

# Find all files matching the pattern '96ml##' in subfolders
file_paths <- dir_ls(base_path, recurse = TRUE, regexp = "/96ml\\d+$")

# Read and combine all files into a single dataset
d <- file_paths %>%
  lapply(read_delim, delim = "\t", col_types = cols()) %>%
  bind_rows()

# Print a preview of the combined dataset
print(d)

# save the combined dataset to a file
# write_csv(d, "combined_data.csv")

colnames(d)

binomSEM <- function (v){
  n <- sum(!is.na(v))
  sqrt((mean(v, na.rm=TRUE) * (1 - mean(v, na.rm=TRUE)))/n)
}

dag <- d %>%
  group_by(dim_onset) %>%
  summarise(accuracy_value=mean(acc, na.rm=TRUE),
         accuracy_se = binomSEM(acc),
         confidence_value = mean(conf_rating, na.rm=TRUE),
         confidence_se = bootMeanSE(conf_rating)) %>%
  pivot_longer(
    cols = -dim_onset, 
    names_to = c("measure", "type"), # Separate column name into two parts
    names_sep = "_", # Split column names at '_'
    values_to = "value"
  ) %>%
  pivot_wider(
    names_from = type, # Pivot 'type' back into separate columns
    values_from = value
  )

# plot
dag %>%
  mutate(dim_onset=ifelse(measure=="accuracy", dim_onset+0.125, dim_onset-0.125)) %>%
  ggplot(aes(x=dim_onset,
             y=value,
             ymin=value-se,
             ymax=value+se,
             color=measure))+
  geom_point()+
  geom_errorbar(width=0)+
  geom_line()+
  coord_cartesian(xlim=c(0,10), ylim=c(1/3, 1))+
  geom_hline(yintercept=1/3, lty=2)+
  theme_classic()+
  labs(x="lead time (seconds)", y="")


# -----------------------------------------------------------------------------
# gaze data

# Define the base path
gaze_path <- "../gazedata"

# Find all files matching the pattern '96ml##_gaze'
file_paths <- dir_ls(gaze_path, recurse = TRUE, regexp = "96ml\\d{2}_gaze$")

# Print the matching file paths
print(file_paths)

# Read and combine all files into a single dataset
gaze_d <- file_paths %>%
  lapply(read_delim, delim = "\t", col_types = cols()) %>%
  bind_rows()

gaze_d <- read_delim(file_paths[7])


