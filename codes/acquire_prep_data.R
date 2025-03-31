######  process occurrence and environmental input data for niche modeling

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(geodata)
library(ClimDatDownloadR)
library(rnaturalearth)
library(terra)
library(sf)
library(foster)
library(dplyr)
library(SDMtune)
library(ENMwrap)

# check loaded packages
sessionInfo()

# set random seed for reproducibility
set.seed(1122)

#####  part 1 ::: acquire spatial data ----------
# obtain occurrence data from GBIF == total of 89,769 occurrence points acquired
#occs <- geodata::sp_occurrence(genus = 'Mantis', species = 'religiosa', geo = T, removeZeros = T, download = T, path = 'data/occs')
#write.csv(occs, 'data/occs/occs_GBIF_raw_20250328.csv')

#nrow(occs)
#head(occs)

# acquire CHELSA global climate data == downloaded at 1km resolution
# download data
#ClimDatDownloadR::Chelsa.Clim.download(save.location = 'data/envs/global/', parameter = 'bio', bio.var = c(1:19), version.var = '2.1', clipping = F, 
#                                       clip.extent = c(-180, 180, -90, 90), buffer = 0, convert.files.to.asc = F, stacking.data = F, combine.raw.zip = F,
#                                       delete.raw.data = F, save.bib.file = T, save.download.table = T)

# acquire global elevation data == SRTM // from WordClim 2.1
#geodata::elevation_global(lon = c(-180, 180), lat = c(-90, 90), path = 'data/envs/global/elev/', res = 2.5)

# acquire global land cover data
#varnames <- c('trees', 'grassland', 'shrubs', 'cropland', 'built')

#for (i in 1:length(varnames)) {
#  geodata::landcover(var = varnames[[i]], path = 'data/envs/global/land/')
#}

# acquire global human footprint data, considering M.religiosa have been moved around the world due to human activities  
# original data == https://sedac.ciesin.columbia.edu/data/collection/wildareas-v3
#geodata::footprint(year = 2009, path = 'data/envs/global/human_footprint/')


#####  part 2 ::: process environmental data ----------

### Prep global scale data == load global scale layers & mask them to global polygon
# get global shapefile
world <- ne_countries(scale = 10, returnclass = 'sf')
plot(world)

# load bioclimatic variables
bio <- rast(list.files('data/envs/global/bio/ChelsaV2.1Climatologies/', pattern = '.tif$', full.names = T))
names(bio) = gsub('CHELSA_bio_0*([0-9]+)_.*', 'bio\\1', names(bio))

bio <- mask(bio, world)
plot(bio[[1]])

for (i in 1:nlyr(bio)) {
  writeRaster(bio[[i]], paste0('data/envs/global/bio/chelsa_global_masked/', names(bio)[i], '.tif'), overwrite = T)
}

# load elevation
elev <- rast('data/envs/global/elev/elevation/wc2.1_2.5m/wc2.1_2.5m_elev.tif')
names(elev) = 'elev'
plot(elev)

# load land cover
land <- rast(list.files(path = 'data/envs/global/land/landuse/', pattern = '.tif$', full.names = T))
names(land)
plot(land[[1]])

# human footprint
foot <- rast('data/envs/global/human_footprint/landuse/wildareas-v3-2009-human-footprint_geo.tif')
names(foot) = 'human_footprint'

foot <- mask(foot, world)
plot(foot)

writeRaster(foot, 'data/envs/global/human_footprint/landuse/global_human_footprint_masked.tif', overwrite = T)

### match pixel resolution & spatial extent
# load global variables
bio <- rast(list.files(path = 'data/envs/global/bio/chelsa_global_masked/', pattern = '.tif$', full.names = T))

elev <- rast('data/envs/global/elev/elevation/wc2.1_2.5m/wc2.1_2.5m_elev.tif')
names(elev) = 'elev'

land <- rast(list.files(path = 'data/envs/global/land/landuse/', pattern = '.tif$', full.names = T))
foot <- rast('data/envs/global/human_footprint/landuse/global_human_footprint_masked.tif')

plot(bio[[1]])
plot(elev)
plot(land[[1]])
plot(foot)

# check pixel resolutions
res(bio)
res(elev)
res(land)
res(foot)

# resample all variables other then elev to 5km // aggregation factor of n -> 1*n = 5, use n = 5
bio <- terra::aggregate(bio, fact = 5)
land <- terra::aggregate(land, fact = 5)
foot <- terra:: aggregate(foot, fact = 5)

# check spatial extents
ext(bio) == ext(land)
ext(bio) == ext(elev)
ext(bio) == ext(foot)

# match extents
bio <- matchResolution(raster::stack(bio), ref = raster::raster(elev)) %>% terra::rast()
land <- matchResolution(raster::stack(land), ref = raster::raster(elev)) %>% terra::rast()
foot <- matchResolution(raster::stack(foot), ref = raster::raster(foot)) %>% terra::rast()

# stack all variables
allvars_glob <- c(bio, elev, land, foot)
print(allvars_glob)
names(allvars_glob)

# export finished layers
for (i in 1:nlyr(allvars_glob)) {
  writeRaster(allvars_glob[[i]], paste0('data/envs/global/allvars_global_processed/', names(allvars_glob)[i], '.tif'), overwrite = T)
}

### prep Europe data
# define cropping extent
ext.eu <- c(-21.04427, 65.02733, 24.45223, 69.33504)

# crop
allvars_eu <- crop(allvars_glob, ext.eu)
plot(allvars_eu[[1]])

# export
for (i in 1:nlyr(allvars_eu)) {
  writeRaster(allvars_eu[[i]], paste0('data/envs/europe/', names(allvars_eu)[i], '.tif'), overwrite = T)
}

### prep North America data
# define cropping extent
ext.na <- c(-135.049811, -64.869317, 9.519825, 61.273774)

# crop
allvars_na <- crop(allvars_glob, ext.na)
plot(allvars_na[[1]])

# export
for (i in 1:nlyr(allvars_na)) {
  writeRaster(allvars_na[[i]], paste0('data/envs/north_america/', names(allvars_na)[i], '.tif'), overwrite = T)
}


#####  part 3 ::: process occurrence data ----------

### global occurrence data
# load data and get relevant columns
glob.occs <- read.csv('data/occs/occs_GBIF_raw_20250328.csv') %>% dplyr::select('lon', 'lat', 'continent')
glob.occs$species = 'Mantis religiosa'
glob.occs <- glob.occs[, c(4,1,2,3)]

colnames(glob.occs) = c('species', 'long', 'lat', 'continent')
head(glob.occs)

# export raw global occs
write.csv(glob.occs, 'data/occs/global/global_occs_raw.csv')

# spatially thin occurrence points == 30km thinning distance
# first resample a raster mold to 30km pixel res // 5*n = 30 ... n = 6
dist.ref <- terra::aggregate(allvars_glob[[1]], fact = 6)  

# thin // first thin with 30km ref raster & thin again with 5km ref raster
glob.occs.thin <- thinData(coords = glob.occs, env = dist.ref, x = 'long', y = 'lat')
glob.occs.thin <- thinData(coords = glob.occs.thin, env = allvars_glob[[1]], x = 'long', y = 'lat')

nrow(glob.occs.thin)
head(glob.occs.thin)

# export 
write.csv(glob.occs.thin, 'data/occs/global/global_occs_thin_30km.csv')


### europe occurrence points
# filter using continent column
eu.occs <- glob.occs %>% dplyr::filter(continent == 'EUROPE')

# export raw Europe occs
write.csv(eu.occs, 'data/occs/europe/europe_occs_raw.csv')

# spatially thin occurrence points == 30km thinning distance
# first resample a raster mold to 30km pixel res // 5*n = 30 ... n = 6
dist.ref.eu <- terra::aggregate(allvars_eu[[1]], fact = 6)

# thin // first thin with 30km ref raster & thin again with 5km ref raster
eu.occs.thin <- thinData(coords = eu.occs, env = dist.ref.eu, x = 'long', y = 'lat')
eu.occs.thin <- thinData(coords = eu.occs.thin, env = allvars_eu[[1]], x = 'long', y = 'lat')

nrow(eu.occs.thin)
head(eu.occs.thin)

# export
write.csv(eu.occs.thin, 'data/occs/europe/europe_occs_thin_30km.csv')


### north america occurrence points
# filter using continent column
na.occs <- glob.occs %>% dplyr::filter(continent == 'NORTH_AMERICA')

# export raw Europe occs
write.csv(na.occs, 'data/occs/north_america/north_america_occs_raw.csv')

# spatially thin occurrence points == 30km thinning distance
# first resample a raster mold to 30km pixel res // 5*n = 30 ... n = 6
dist.ref.na <- terra::aggregate(allvars_na[[1]], fact = 6)

# thin // first thin with 30km ref raster & thin again with 5km ref raster
na.occs.thin <- thinData(coords = na.occs, env = dist.ref.na, x = 'long', y = 'lat')
na.occs.thin <- thinData(coords = na.occs.thin, env = allvars_na[[1]], x = 'long', y = 'lat')

nrow(na.occs.thin)
head(na.occs.thin)

# export
write.csv(na.occs.thin, 'data/occs/north_america/north_america_occs_thin_30km.csv')


#####  part 4 ::: sample background points
# check nrow of thinned occurrences == [global: 7260], [europe: 4619], [north america: 2059]
nrow(glob.occs.thin)
nrow(eu.occs.thin)
nrow(na.occs.thin)

# draw 300km buffer around each occs set
buf <- buff_maker(occs_list = list(glob.occs.thin, eu.occs.thin, na.occs.thin), envs = raster::raster(allvars_glob[[1]]), buff_dist = 300000)
glimpse(buf)

# check global buffers
plot(allvars_glob[['elev']])
points(glob.occs.thin[, c('long', 'lat')], col = 'red')
plot(buf[[1]], add = T, lwd = 3)

# check europe buffers
plot(allvars_eu[['elev']])
points(eu.occs.thin[, c('long', 'lat')], col = 'red')
plot(buf[[2]], add = T, lwd = 3)

# check north america buffers
plot(allvars_na[['elev']])
points(na.occs.thin[, c('long', 'lat')], col = 'red')
plot(buf[[3]], add = T, lwd = 3)

# export buffers
st_write(buf[[1]], 'data/poly/buffers/global/global_300km.shp')
st_write(buf[[2]], 'data/poly/buffers/europe/europe_300km.shp')
st_write(buf[[3]], 'data/poly/buffers/north_america/north_america_300km.shp')
