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
# get relevant columns

# grab occurrence points for Europe (native) and North America (non-native) separately

# spatially thin occurrence points

# 


#####  part 4 ::: sample background points

