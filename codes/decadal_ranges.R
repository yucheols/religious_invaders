#####  decadal range vis in europe and north america

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(terra)
library(sf)
library(tidyterra)
library(dplyr)
library(ggplot2)
library(ggpubr)

# get session info
sessionInfo()

#####  part 1 ::: europe range ----------
# load a europe elevation raster 
eu_base <- rast('data/envs/europe/elev.tif')
plot(eu_base)

# load raw European occurrence points with the year column
eu_occs <- read.csv('data/occs/europe/europe_occs_raw.csv')
eu_occs$X <- NULL
head(eu_occs)

# create a decade column
eu_occs_dec <- eu_occs %>% na.omit() %>% dplyr::mutate(decade = floor(year/10)*10)
head(eu_occs_dec)
unique(eu_occs_dec$decade)

# split by decadal interval
eu_dec_list <- eu_occs_dec %>%
  group_by(decade) %>%
  group_split()

# check the number of rows per decadal interval == only the last 5 intervals have a sufficient number of occurrence points
for (i in 1:length(eu_dec_list)) {
  print(nrow(eu_dec_list[[i]]))
}

# bind the last 5 intervals
eu_dec_keep <- bind_rows(eu_dec_list[16:20]) %>% as.data.frame()
head(eu_dec_keep)
tail(eu_dec_keep)

# recode the decade names for better visualization
eu_dec_keep$decade <- as.character(eu_dec_keep$decade)
eu_dec_keep$decade <- eu_dec_keep$decade %>% recode_factor('1980' = '1980s',
                                                           '1990' = '1990s',
                                                           '2000' = '2000s',
                                                           '2010' = '2010s',
                                                           '2020' = '2020s')

# convert to sf object
eu_dec_sf <- st_as_sf(eu_dec_keep, coords = c('long', 'lat'), crs = 4326)

# plot
eu_plot <- ggplot() +
  geom_spatraster(data = eu_base) +
  geom_sf(data = eu_dec_sf, shape = 21, fill = '#6495ED', stroke = 1) +
  facet_grid(~ decade) +
  scale_fill_wiki_c(na.value = NA) +
  scale_x_continuous(breaks = seq(from = -10, to = 60, by = 15)) +
  labs(title = '(A) Europe', fill = 'Elevation (m)') +
  coord_sf(expand = F) +
  theme_bw() +
  theme(plot.title = element_text(size = 18, face = 'bold'), 
        strip.text = element_text(size = 14, face = 'bold'),
        legend.title = element_text(size = 14, face = 'bold'),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 12),
        axis.text.x = element_text(angle = 25, hjust = 1))

print(eu_plot)


#####  part 2 ::: north america range ----------
# load a north america elevation raster 
na_base <- rast('data/envs/north_america/elev.tif')
plot(na_base)

# load raw North American occurrence points with the year column
na_occs <- read.csv('data/occs/north_america/north_america_occs_raw.csv')
na_occs$X <- NULL
head(na_occs)

# create a decade column
na_occs_dec <- na_occs %>% na.omit() %>% dplyr::mutate(decade = floor(year/10)*10)
head(na_occs_dec)

# split by decadal interval
na_dec_list <- na_occs_dec %>%
  group_by(decade) %>%
  group_split()

# check the number of rows per decadal interval == use the last 5 intervals
for (i in 1:length(na_dec_list)) {
  print(nrow(na_dec_list[[i]]))
}

# bind the last 5 intervals
na_dec_keep <- bind_rows(na_dec_list[8:12]) %>% as.data.frame()
head(na_dec_keep)
tail(na_dec_keep)

# recode the decade names for better visualization
na_dec_keep$decade <-as.character(na_dec_keep$decade)
na_dec_keep$decade <- na_dec_keep$decade %>% recode_factor('1980' = '1980s',
                                                           '1990' = '1990s',
                                                           '2000' = '2000s',
                                                           '2010' = '2010s',
                                                           '2020' = '2020s')

# convert to sf object
na_dec_sf <- st_as_sf(na_dec_keep, coords = c('long', 'lat'), crs = 4326)

# plot  
na_plot <- ggplot() +
  geom_spatraster(data = na_base) +
  geom_sf(data = na_dec_sf, shape = 21, fill = '#6495ED', stroke = 1) +
  facet_grid(~ decade) +
  scale_fill_wiki_c(na.value = NA) +
  scale_x_continuous(breaks = seq(from = -120, to = 70, by = 15)) +
  labs(title = '(B) North America', fill = 'Elevation (m)') +
  coord_sf(expand = F) +
  theme_bw() +
  theme(plot.title = element_text(size = 18, face = 'bold'), 
        strip.text = element_text(size = 14, face = 'bold'),
        legend.title = element_text(size = 14, face = 'bold'),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 12),
        axis.text.x = element_text(angle = 25, hjust = 1))
  
print(na_plot)


#####  part 3 ::: combine plots // 1500W X 700H ----------
ggarrange(eu_plot, na_plot, ncol = 1, nrow = 2, align = 'hv')
