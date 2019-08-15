#!/usr/bin/env Rscript

# 19/07/2019
# Josh Jones

######################################
# Conefor tidy up   
######################################

# usage: Rscript tidyup.R 5 10 DdamL DdamL

library(dplyr)
library(purrr)
library(readr)

########################################################
# only currently works with 2 metrics and 2 distances
########################################################

args <- commandArgs(trailingOnly = TRUE)
cat(args, sep = "\n")

distance1 <- args[1] # format 1
distance2 <- args[2] # format 10
metric1 <- args[3] # format DdamL
metric2 <- args[4] # format DdamLS

# distance1 <- 5
# distance2 <-  10
# metric1 <- 'DdamL'
# metric2 <- 'DdamLS'

#########################################
# set these depending on what outputs and distances to calculate
metrics <- c(metric1, metric2)
distances <- as.numeric(c(distance1, distance2)) # set how many distance thresholds to run
#########################################

# bind different metrics

###
message('Collating dIIC1...')

pattern <- paste0("dIIC",distances[1], metrics[1], '_')

message('pattern = ', pattern)

filelist <- list.files(getwd(), pattern)

if (length(filelist) > 0) {
  dIIC1 <- lapply(filelist, read_tsv) %>% 
  bind_rows() %>%
  rename_at(vars(-Node), ~ paste0(.,distances[1], metrics[1])) %>%
  select(Node, paste0('dIIC', distances[1], metrics[1]))
}

##

###
message('Collating dIIC2...')

pattern <- paste0("dIIC",distances[1], metrics[2], '_')
message('pattern = ', pattern)

filelist <- list.files(getwd(), pattern)

if (length(filelist) > 0) {
  dIIC2 <- lapply(filelist, read_tsv) %>% bind_rows() %>%
  rename_at(vars(-Node), ~ paste0(.,distances[1], metrics[2])) %>%
  select(Node, paste0('dIIC', distances[1], metrics[2]))
}
###

###
message('Collating dIIC3...')

pattern <- paste0("dIIC",distances[2], metrics[2], '_')

filelist <- list.files(getwd(), pattern)

if (length(filelist) > 0) {
  dIIC3 <- lapply(filelist, read_tsv) %>% bind_rows() %>%
  rename_at(vars(-Node), ~ paste0(.,distances[2], metrics[2])) %>%
  select(Node, paste0('dIIC', distances[2], metrics[2]))
}
###

###
message('Collating dIIC4...')

pattern <- paste0("dIIC",distances[2], metrics[1], '_')

filelist <- list.files(getwd(), pattern)

if (length(filelist) > 0) {
  dIIC4 <- lapply(filelist, read_tsv) %>% bind_rows() %>%
  rename_at(vars(-Node), ~ paste0(.,distances[2], metrics[1]))%>%
  select(Node, paste0('dIIC', distances[2], metrics[1]))
}
###

dIICall <- list(dIIC1, dIIC2, dIIC3, dIIC4) %>% reduce(full_join, by = "Node")

# create directories and write merged output
dir.create(file.path(getwd(), '/coneforOutMerged'), showWarnings = FALSE)

timedate <- paste0(format(Sys.time(), "%H%M%S"), "_", Sys.Date())

message('Writing merged output...')

write_csv(dIICall, paste0("./coneforOutMerged/dIIC_", distances[1], distances[2], metrics[1], metrics[2], timedate,".csv"))

message('Finished tidying up.')

quit()