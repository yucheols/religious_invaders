######  Multivar Env Similarity Surface == MESS

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(ntbox)
library(terra)
library(tidyterra)

###  MESS between native (Europe) and non-native (N America) ranges of M. religiosa
# load europe environment
envs_eu <- rast(list.files(path = 'data/envs/europe/', pattern = '.tif$', full.names = T))
envs_eu <- envs_eu[[c('bio1', 'bio2', 'bio12', 'bio15', 'cropland', 'elev', 'grassland', 'human_footprint', 'trees')]]
names(envs_eu)

# load North America environment
envs_na <- rast(list.files(path = 'data/envs/north_america/', pattern = '.tif$', full.names = T))
envs_na <- envs_na[[names(envs_eu)]]
names(envs_na)

# run mess
eu_na_mess <- ntb_mess(M_stack = raster::stack(envs_eu), G_stack = raster::stack(envs_na))
plot(eu_na_mess)

# plot
