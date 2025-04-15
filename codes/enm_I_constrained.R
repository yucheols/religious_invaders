#####  ENM for M. religiosa calibrated on North America East, Central, and West == model at 5km scale 

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# increase java heap space
options(java.parameters = "-Xmx32G")

# load packages
library(terra)
library(sf)
library(ENMeval)
library(blockCV)
library(ntbox)
library(dplyr)

# session info
sessionInfo()


#####  part 1 ::: load data ----------
# load environmental variables == these are at 5km resolution
i.envs <- rast(list.files(path = 'data/envs/subset/north_america/', pattern = '.tif$', full.names = T))
print(i.envs)
plot(i.envs[[1]])