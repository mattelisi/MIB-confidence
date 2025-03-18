# clear workspace
rm(list=ls())
hablar::set_wd_to_script_path()

library(tidyverse)
library(fs)
library(stringr)

# read non-gaze data
db <- read.csv("MIB_data_all.csv")
str(db)

# the data are in the the local subfolder 'gazedata'
data_path <- base_path <- "../gazedata/"
file_paths <- dir_ls(data_path)
# file_names <- dir(data_path)
file_names <- str_sub(file_paths, 13, 13+5)

# Extract unique IDs from db (force lowercase for matching)
unique_ids <- tolower(unique(db$ID))

# Extract the ID part from filenames (first 6 characters before "_gaze")
file_ids <- str_sub(file_names, 1, 6)

# Identify matching files (case insensitive)
matching_files <- file_paths[tolower(file_ids) %in% unique_ids]

# # debug
# file_path <- matching_files[1]
# df <- read_delim(file_path)

# Function to read data and add ID columns
read_gaze_file <- function(file_path) {
  df <- read_delim(file_path, show_col_types = FALSE) 
  id_value <- str_sub(basename(file_path), 1, 6)
  
  df <- df %>%
    mutate(
      ID = id_value,
      PID = str_sub(id_value, 1, 4),
      sessionID = str_sub(id_value, 5, 6)
    )
  
  return(df)
}

# Read and combine all matching files
# combined_data <- map_dfr(matching_files, read_gaze_file)

combined_data <- {}
for(i in seq_along(matching_files)){
  df <- read_gaze_file(matching_files[i])
  combined_data <- rbind(df, combined_data)
  cat(i,"\t",matching_files[i],"\n")
}

# 
str(combined_data)

# save the merged dataset
write_csv(combined_data, "./merged_gaze_data.csv")


