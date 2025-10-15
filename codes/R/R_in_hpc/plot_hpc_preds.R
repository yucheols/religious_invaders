#########   plotting predictions from HPC runs
#########   naming convention ::: "enm_N" == Native-range ::: "enm_I" == Invaded-range 

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(terra)
library(tidyterra)
library(ggplot2)


#########  europe_10km

### load ensemble pred for Europe
# load raster
enm_N_europe_10km <- rast('outputs/hpc_outputs/europe_10km/output/Mantis.religiosa.europe/proj_religiosa_europe_10km/proj_religiosa_europe_10km_Mantis.religiosa.europe_ensemble.tif')
print(enm_N_europe_10km)

# the raster values range from 0-1000...divide it up by 1000 so that it scales to 0-1
enm_N_europe_10km <- enm_N_europe_10km / 1000
plot(enm_N_europe_10km)

# plot
ggplot() +
  geom_spatraster(data = enm_N_europe_10km) +
  scale_fill_grass_c(palette = 'inferno',
                     na.value = NA,
                     name = 'RS') +
  coord_sf(expand = F) +
  theme_minimal() +
  theme(panel.border = element_rect(fill = NA),
        axis.text = element_text(size = 16),
        legend.title = element_text(size = 16),
        legend.text = element_text(size = 14))


### load ensemble pred for North America (model transfer)
# load raster
enm_N_namerica_10km <- rast('outputs/hpc_outputs/europe_10km/output/Mantis.religiosa.europe/proj_religiosa_europe2na_10km/proj_religiosa_europe2na_10km_Mantis.religiosa.europe_ensemble.tif')
print(enm_N_namerica_10km)

# the raster values range from 0-1000...divide it up by 1000 so that it scales to 0-1
enm_N_namerica_10km <- enm_N_namerica_10km / 1000
plot(enm_N_namerica_10km)

# plot
ggplot() +
  geom_spatraster(data = enm_N_namerica_10km) +
  scale_fill_grass_c(palette = 'inferno',
                     na.value = NA,
                     name = 'RS') +
  coord_sf(expand = F) +
  theme_minimal() +
  theme(panel.border = element_rect(fill = NA),
        axis.text = element_text(size = 16),
        legend.title = element_text(size = 16),
        legend.text = element_text(size = 14))
