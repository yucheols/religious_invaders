######  process occurrence and environmental input data for niche modeling

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(geodata)
library(ClimDatDownloadR)
library(terra)

#####  part 1 ::: acquire spatial data ----------
# obtain occurrence data from GBIF == total of 89,769 occurrence points acquired
occs <- geodata::sp_occurrence(genus = 'Mantis', species = 'religiosa', geo = T, removeZeros = T, download = T, path = 'data/occs')
write.csv(occs, 'data/occs/occs_GBIF_raw_20250328.csv')

nrow(occs)
head(occs)

# acquire CHELSA global climate data == downloaded at 1km resolution
ClimDatDownloadR::Chelsa.Clim.download(save.location = 'data/envs/global/', parameter = 'bio', bio.var = c(1:19), version.var = '2.1', clipping = F, 
                                       clip.extent = c(-180, 180, -90, 90), buffer = 0, convert.files.to.asc = F, stacking.data = F, combine.raw.zip = F,
                                       delete.raw.data = F, save.bib.file = T, save.download.table = T)

# acquire global elevation data

# acquire global land cover data


# acquire global human population data, considering M.religiosa have been moved around the world due to human activities  


#####  part 2 ::: process acquired data ----------
# grab occurrence points for Europe (native) and North America (non-native) separately

# spatially thin occurrence points

#