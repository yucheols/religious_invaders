#####  filter occurrence points to match the temporal resolution between the point dataset and climate dataset 

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(111)

# load packages
library(SDMtune)
library(dplyr)
library(terra)
library(tidyterra)
library(ggplot2)


###  Europe
# load elevation basemap and resample to 30km
eu <- rast('data/envs/europe/elev.tif')
eu <- terra::aggregate(x = eu, fact = 6)
plot(eu)

# load raw occurrence points
eu_occs <- read.csv('data/occs/europe/europe_occs_raw.csv') %>% dplyr::select(-1)
head(eu_occs)

# check years
unique(sort(eu_occs$year))

# grab points between 1970 and 2020
eu_occs_filt <- eu_occs %>% dplyr::filter(between(eu_occs$year, 1970, 2020))

# thin occurrence points
eu_thin <- SDMtune::thinData(coords = eu_occs_filt, env = eu, x = 'long', y = 'lat', verbose = T, progress = T)
nrow(eu_thin)

# export filtered and thinned points
write.csv(eu_thin, 'data/occs/europe/europe_occs_filtered_thinned_30km.csv')


###  North America
# load elevation basemap and resample to 30km
na <- rast('data/envs/north_america/elev.tif')
na <- terra::aggregate(x = na, fact = 6)
plot(na)

# load raw occurrence points
na_occs <- read.csv('data/occs/north_america/north_america_occs_raw.csv') %>% dplyr::select(-1)
head(na_occs)

# check years
unique(sort(na_occs$year))

# grab points between 1980 and 2010
na_occs_filt <- na_occs %>% dplyr::filter(between(na_occs$year, 1970, 2020))

# thin occurrence points
na_thin <- SDMtune::thinData(coords = na_occs_filt, env = na, x = 'long', y = 'lat', verbose = T, progress = T)
nrow(na_thin)

# export filtered and thinned points
write.csv(na_thin, 'data/occs/north_america/north_america_occs_filtered_thin_30km.csv')
