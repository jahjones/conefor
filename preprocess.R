# 02/5/2019
# Josh Jones

#########################################
# Conefor distance between each node ####
# for each combination on a unix system #
# in parallel
#########################################

# usage: Rscript conefor_linux_sonia.r 2 Corsica_CCM21.csv 5 10 DdamL DdamLS

# requires external executable 'conefor2.7.3Linux' available from XXXXX

# install.packages("tidyverse")
# install.packages("igraph")
# install.packages("data.tree")
# install.packages("data.table")
# install.packages("iterpc")

library(tidyverse)
library(igraph)
library(data.tree)
library(parallel)
library(iterpc)

########################################################
# only currently works with 2 metrics and 2 distances
########################################################

args <- commandArgs(trailingOnly = TRUE)
cat(args, sep = "\n")

ncores <- as.numeric(args[1]) # format 1
catchpath <- args[2] # format Corsica_CCM21.csv
distance1 <- args[3] # format 1
distance2 <- args[4] # format 10
metric1 <- args[5] # format DdamL
metric2 <- args[6] # format DdamL

# ncores <- 2
# catchpath <- "./derived_data/FR_C_ZHYD_v5_withinonly.csv"
# distance1 <- 5
# distance2 <- 10
# metric1 <- "DdamL"
# metric2 <- "DdamLS"

# create directories
dirs <- c('/coneforTemp', '/coneforOut')
lapply(dirs, function(x) dir.create(file.path(getwd(), x), showWarnings = FALSE))

#########################################
# set these depending on what outputs and distances to calculate
metrics <- c(metric1, metric2)
distances <- as.numeric(c(distance1, distance2)) # set how many distance thresholds to run
#########################################

# load data
catch <- read_csv(catchpath)
catch <- catch %>%
  select(barriers, Outlet, riv_m, slope_mean, Node, nextNode, area_km2) %>%
  mutate(count = ifelse(is.na(barriers), 0, barriers),
         densityArea = ifelse(count == 0, 0, (count/area_km2)),
         densityRiv = ifelse(count == 0, 0, count/(riv_m/1000)),
         damL = ifelse(riv_m == 0, 0, sqrt(count)/(riv_m/1000)),
         DdamL = ifelse(damL == 0, 0, (damL - min(na.omit(damL)))/(max(na.omit(damL)) - min(damL))),
         DdamLS = ifelse(DdamL == 0, 0 ,DdamL/sqrt(slope_mean)),
         nextdownid = ifelse(nextNode == -9999, -9999, nextNode))

# par it down to two basins to try running in parallel
df <- catch %>%
  select(Node, nextdownid, DdamL, DdamLS, Outlet) %>%
  filter(!is.na(nextdownid)) %>%
  rename(parent_id = Node,
         id = nextdownid) %>%
  mutate(DdamLS = 1-DdamLS, # as dIIC is a quality measure, the inverse dam density of the segments is used
         DdamL = 1-DdamL) # as dIIC is a quality measure...
  # filter(Outlet == 'DSO0207615' | Outlet == 'DSO0207130')

# list of all outlet catchments
outlets <- unique(df$Outlet)

getNodePath <- function(metric, outlet) {
  paste0('./coneforTemp/node_', metric, '_', outlet, '.txt')
}

getConPath <- function(outlet) {
  paste0('./coneforTemp/connection_', outlet, '.txt')
}

generate_connection_file <- function(outlet) {

  conPath <- getConPath(outlet)

  if(!file.exists(conPath)){
    message('Generate connection file for outlet ', outlet)

                                        # find all unique permutations of nodes
    dfi <- filter(df, Outlet == outlet)

    message('...generating nodes...')

    I <- iterpc(table(unique(dfi$parent_id)), 2, labels = dfi$parent_id, replace = F, ordered = F)
    nodePerms <- as.data.frame(getall(I)) %>%
      mutate(nodei = as.character(V1),
             nodej = as.character(V2)) %>%
      select(-V1, -V2)

    message('...generating permutations...')

                                        # connection distances
    connection <- as.data.frame(distances(graph_from_data_frame(dfi))) %>%
      rownames_to_column("nodei") %>%
      gather(key = "nodej",
             value = "distance",
             -nodei)

                                        # only keep the connections that aren't duplicates or unwanted rubbish
    connection <- left_join(nodePerms, connection, by = c("nodei" = "nodei", "nodej" = "nodej"))

    message('...writing...')
    write_delim(connection, conPath, delim = " ", na = "NA", append = FALSE,
                col_names = FALSE, quote_escape = "double")
  }
}

# for each outlet, distance and metric calculate nodes,
# connections and run conefor
generate_node_file <- function(args) { # list of outlets, dist. and metrics
  
  outlet <- args[1]
  metric <- args[2]

  # node file for conefor
  nodePath <- getNodePath(metric, outlet)

  if(!file.exists(nodePath)){
    message('Write node file for outlet ', outlet, ' with metric ', metric)
    nodes.df <- df %>%
      filter(Outlet == outlet) %>%
      select(parent_id, metric)

    write_delim(nodes.df, nodePath, delim = " ", na = "NA", append = FALSE,
                col_names = FALSE, quote_escape = "double")
  }

}

start <- Sys.time()

# create the list of scenarios to run through
args <- expand.grid(outlets, distances, metrics)
colnames(args) <- c("outlets", "distances", "metrics")

getPrefixString <- function (distance, metric, outlet) {
  paste0("dIIC", distance, metric, "_", outlet)
}

# Generate input files
out <- apply(expand.grid(outlets, metrics), 1, generate_node_file)
out <- map(outlets, generate_connection_file)

args$conPath <- getConPath(args$outlets)
args$nodePath <- getNodePath(args$metric, args$outlet)
args$prefixString <- getPrefixString(args$distances, args$metric, args$outlet)

output <- select(args, nodePath, conPath, distances, prefixString)

write_csv(output, 'dIICoutlets.csv')

end <- Sys.time()
end - start
print('Preprocess finished')

quit()
