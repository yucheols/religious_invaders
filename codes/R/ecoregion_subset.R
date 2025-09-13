#####  subset ecoregions needed to subset North American occurrence

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(sf)
library(dplyr)
library(terra)
library(tidyterra)
library(ggplot2)
library(ggnewscale)


#####  load ecoregion polygon
eco <- st_read('data/poly/na_cec_eco_l1/NA_CEC_Eco_Level1.shp')

# slice out ecoregion 6, 7, 10, 11, 12, 13, 14 == the "West"
eco_west <- eco %>% filter(NA_L1CODE %in% c(6,7,10,11,12,13,14))
#plot(eco_west)

# slice out ecoregion 9 == great plains
eco_gp <- eco %>% filter(NA_L1CODE == 9)
#plot(eco_gp)

# slice out ecoregion 5, 8 == the "East"
eco_east <- eco %>% filter(NA_L1CODE %in% c(5,8))
#plot(eco_east)


#####  export sliced ecoregions
st_write(eco_west, 'data/poly/ecoregion_sliced/eco_west.shp', append = F)
st_write(eco_gp, 'data/poly/ecoregion_sliced/eco_great_plains.shp', append = F)
st_write(eco_east, 'data/poly/ecoregion_sliced/eco_east.shp', append = F)


#####  slice occurrences based on ecoregion
# load occurrences
occs <- read.csv('data/occs/north_america/north_america_occs_thin_30km.csv')
occs$X <- NULL
head(occs)

# transform to sf 
occs_sf <- st_as_sf(occs, coords = c('long', 'lat'), crs = 4326)
occs_sf <- st_transform(occs_sf, st_crs(eco))

# perform spatial join to select points within polygons // then transform it back WGS 84
occs_west <- st_filter(occs_sf, eco_west, join = st_within) %>% st_transform(crs = 4326)
occs_gp <- st_filter(occs_sf, eco_gp, join = st_within) %>% st_transform(crs = 4326)
occs_east <- st_filter(occs_sf, eco_east, join = st_within) %>% st_transform(crs = 4326)

# return to df 
# west
occs_west_df <- occs_west %>%
  st_coordinates() %>%
  as.data.frame() %>%
  bind_cols(st_drop_geometry(occs_west)) %>%
  select(1:5)

colnames(occs_west_df) = c('long', 'lat', 'species', 'continent', 'year')
head(occs_west_df)
nrow(occs_west_df)

# Great Plains
occs_gp_df <- occs_gp %>%
  st_coordinates() %>%
  as.data.frame() %>%
  bind_cols(st_drop_geometry(occs_gp)) %>%
  select(1:5)

colnames(occs_gp_df) = colnames(occs_west_df)
head(occs_gp_df)
nrow(occs_gp_df)

# East
occs_east_df <- occs_east %>%
  st_coordinates() %>%
  as.data.frame() %>%
  bind_cols(st_drop_geometry(occs_east)) %>%
  select(1:5)

colnames(occs_east_df) = colnames(occs_west_df)
head(occs_east_df)
nrow(occs_east_df)

# export occurrences sliced by ecoregion
write.csv(occs_west_df, 'data/occs/north_america/by_ecoregion/na_west.csv')
write.csv(occs_gp_df, 'data/occs/north_america/by_ecoregion/na_great_plains.csv')
write.csv(occs_east_df, 'data/occs/north_america/by_ecoregion/na_east.csv')


#####  verify 
# elevation as basemap
elev <- rast('data/envs/north_america/elev.tif')
plot(elev)

# plot points
points(occs_west_df[, c(1,2)], col = 'pink', pch = 21)
points(occs_gp_df[, c(1,2)], col = 'yellow', pch = 23)
points(occs_east_df[, c(1,2)], col = 'green', pch = 25)


#####  make a good-looking map....becasue why not?????
# bind points
occs_west_df$Region = 'West'
occs_gp_df$Region = 'Great Plains'
occs_east_df$Region = 'East'

occs_bind <- rbind(occs_west_df[, c('long', 'lat', 'Region')], occs_gp_df[, c('long', 'lat', 'Region')], occs_east_df[, c('long', 'lat', 'Region')])
head(occs_bind)
tail(occs_bind)

# convert points to sf
occs_bind_sf <- st_as_sf(occs_bind, coords = c('long', 'lat'), crs = 4326)

# plot
ggplot() +
  geom_spatraster(data = elev) +
  scale_fill_wiki_c() +
  labs(fill = 'Elevation (m)') +
  new_scale_fill() +
  geom_sf(data = occs_bind_sf, shape = 21, aes(fill = Region), color = 'black', stroke = 1.1, size = 3) +
  coord_sf(expand = F) +
  theme(axis.title = element_blank(),
        legend.title = element_text(size = 16, face = 'bold'),
        legend.text = element_text(size = 14),
        axis.text = element_text(size = 14),
        axis.text.x = element_text(angle = 25, hjust = 1))

