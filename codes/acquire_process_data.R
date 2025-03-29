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

#####  part 1 ::: acquire spatial data ----------
# obtain occurrence data from GBIF == total of 89,769 occurrence points acquired
occs <- geodata::sp_occurrence(genus = 'Mantis', species = 'religiosa', geo = T, removeZeros = T, download = T, path = 'data/occs')
write.csv(occs, 'data/occs/occs_GBIF_raw_20250328.csv')

nrow(occs)
head(occs)

# acquire CHELSA global climate data == downloaded at 1km resolution
# download data
ClimDatDownloadR::Chelsa.Clim.download(save.location = 'data/envs/global/', parameter = 'bio', bio.var = c(1:19), version.var = '2.1', clipping = F, 
                                       clip.extent = c(-180, 180, -90, 90), buffer = 0, convert.files.to.asc = F, stacking.data = F, combine.raw.zip = F,
                                       delete.raw.data = F, save.bib.file = T, save.download.table = T)

# acquire global elevation data == SRTM // from WordClim 2.1
geodata::elevation_global(lon = c(-180, 180), lat = c(-90, 90), path = 'data/envs/global/elev/', res = 2.5)

# acquire global land cover data
varnames <- c('trees', 'grassland', 'shrubs', 'cropland', 'built')

for (i in 1:length(varnames)) {
  geodata::landcover(var = varnames[[i]], path = 'data/envs/global/land/')
}

# acquire global human footprint data, considering M.religiosa have been moved around the world due to human activities  
# original data == https://sedac.ciesin.columbia.edu/data/collection/wildareas-v3
geodata::footprint(year = 2009, path = 'data/envs/global/human_footprint/')


#####  part 2 ::: process environmental data ----------
# get global shapefile
world <- ne_countries(scale = 10, returnclass = 'sf')
plot(world)

# load bioclimatic variables
bio <- rast(list.files('data/envs/global/bio/ChelsaV2.1Climatologies/', pattern = '.tif$', full.names = T))
names(bio) = gsub('CHELSA_bio_0*([0-9]+)_.*', 'bio\\1', names(bio))

bio <- mask(bio, world)
plot(bio[[1]])


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
plot(foot)


#####  part 3 ::: process occurrence data ----------
# grab occurrence points for Europe (native) and North America (non-native) separately

# spatially thin occurrence points

# 


