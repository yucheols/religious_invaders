######  sample user-specified background points to be used in biomod2

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# load packages
library(terra)
library(sf)
library(ntbox)
library(dplyr)


####  fully global
# load occurrences
glob_occs <- read.csv('data/occs/global/global_occs_thin_30km.csv')
head(glob_occs)
nrow(glob_occs)

# load environmental layers
glob_envs <- rast(list.files(path = 'data/envs/global/allvars_global_processed/', pattern = '.tif$', full.names = T))
plot(glob_envs[[1]])

# plot points over the map
points(glob_occs[, c('long', 'lat')])

# make a 500km dissolved circular buffer around each points
glob_occs_sf <- st_transform(x = st_as_sf(x = glob_occs, coords = c('long', 'lat'), crs = crs(glob_envs)), crs = 3857)   # change to equal-area projection
glob_buff <- st_buffer(x = glob_occs_sf, dist = 500000) %>% st_union() %>% st_sf() %>% st_transform(crs = crs(glob_envs))
plot(glob_buff, border = 'blue', lwd = 3, add = T)

# create kde layer
glob_kde <- biaslayer(occs_df = glob_occs, longitude = 'long', latitude = 'lat', raster_mold = raster::raster(glob_envs[[1]]))
plot(glob_kde)

# export kde layer
writeRaster(glob_kde, 'data/kde/kde_full_glob.tif', overwrite = T)

# sample bg == sample 100x of occurrence points
bg_glob <- ENMwrap::bg_sampler(envs = glob_envs, n = nrow(glob_occs)*100, occs_list = list(glob_occs), bias.grid = glob_kde, method = 'bias.grid')
head()
nrow()

####  (global - N America)

####  (global - [N America + Africa])


####  North America
# load occurrences
na_occs <- read.csv('data/occs/north_america/north_america_occs_thin_30km.csv')
head(na_occs)
nrow(na_occs)

# load environmental layers
na_envs <- rast(list.files(path = 'data/envs/north_america/', pattern = '.tif$', full.names = T))
plot(na_envs[[1]])

# plot points over the map
points(na_occs[, c('long', 'lat')])

# make a 500km dissolved circular buffer around each points
na_occs_sf <- st_transform(x = st_as_sf(x = na_occs[, c('long', 'lat')], coords = c('long', 'lat'), crs = crs(na_envs)), crs = 3857)  # change to equal-area projection
na_buff <- st_buffer(x = na_occs_sf, dist = 500000) %>% st_union() %>% st_sf() %>% st_transform(crs = crs(na_envs))                                                                              # back to WGS84
plot(na_buff, border = 'blue', lwd = 3, add = T)

# create kde layer
na_kde <- biaslayer(occs_df = na_occs, longitude = 'long', latitude = 'lat', raster_mold = raster::raster(na_envs))
plot(na_kde)

# sample bg == sample 100x of occurrence points
bg_na <- ENMwrap::bg_sampler(envs = mask(na_envs, na_buff), n = nrow(na_occs)*100, occs_list = list(na_occs), bias.grid = na_kde, method = 'bias.grid')
head(bg_na)
nrow(bg_na)

plot(na_envs[[1]])
points(bg_na, col = 'yellow')

# export
write.csv(bg_na, 'data/bg/kde_biomod2/bg_namerica.csv')


####  Europe
# load occurrences
eu_occs <- read.csv('data/occs/europe/europe_occs_thin_30km.csv')
head(eu_occs)
nrow(eu_occs)

# load environmental layers
eu_envs <- rast(list.files(path = 'data/envs/europe/', pattern = '.tif$', full.names = T))
plot(eu_envs[[1]])

# plot points over the map
points(eu_occs[, c('long', 'lat')])

# make a 500km dissolved circular buffer around each points
eu_occs_sf <- st_transform(x = st_as_sf(x = eu_occs[, c('long', 'lat')], coords = c('long', 'lat'), crs = crs(eu_envs)), crs = 3857)
eu_buff <- st_buffer(x = eu_occs_sf, dist = 500000) %>% st_union() %>% st_sf() %>% st_transform(crs = crs(eu_envs))
plot(eu_buff, border = 'blue', lwd = 3, add = T)

# create kde layer
eu_kde <- biaslayer(occs_df = eu_occs[, c('long', 'lat')], longitude = 'long', latitude = 'lat', raster_mold = raster::raster(eu_envs[[1]]))
plot(eu_kde)

# sample bg == sample 100x of occurrence points
eu_bg <- ENMwrap::bg_sampler(envs = mask(eu_envs, eu_buff), n = nrow(eu_occs)*100, occs_list = list(eu_occs), bias.grid = eu_kde, method = 'bias.grid')
head(eu_bg)
nrow(eu_bg)

plot(eu_envs[[1]])
points(eu_bg, col = 'yellow')

# export
write.csv(eu_bg, 'data/bg/kde_biomod2/bg_europe.csv')
