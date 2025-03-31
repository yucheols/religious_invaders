#####  decadal range vis in europe and north america

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(terra)
library(sf)
library(tidyterra)
library(dplyr)
library(ggplot2)
library(ggpubr)

# get session info
sessionInfo()

#####  part 1 ::: europe range ----------
# load a europe elevation raster 
eu_base <- rast('data/envs/europe/elev.tif')
plot(eu_base)


#####  part 2 ::: north america range ----------


#####  part 3 ::: combine plots ----------