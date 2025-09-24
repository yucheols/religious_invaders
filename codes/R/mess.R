######  Multivar Env Similarity Surface == MESS

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(ntbox)
library(terra)
library(tidyterra)
library(ggplot2)

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
ggplot() +
  geom_spatraster(data = rast(eu_na_mess)) +
  coord_sf(expand = F) +
  scale_fill_whitebox_c(palette = 'bl_yl_rd',
                        name = 'Extrapolation',
                        breaks = c(0, 60),
                        labels = c('Low', 'High'),
                        guide = guide_colorbar(title.position = 'top',
                                               title.hjust = 0.5)) +
  theme_classic() +
  theme(panel.border = element_rect(fill = NA),
        panel.grid.major = element_line(),
        axis.text = element_text(size = 13),
        legend.position = 'top',
        legend.text = element_text(size = 13),
        legend.title = element_text(size = 16, face = 'bold', margin = margin(b = 15)),
        axis.text.x = element_text(angle = 45, margin = margin(t = 15)))


# save
ggsave()
  

###  MESS between native (Europe) and global ranges of M. religiosa
# load global environment
envs_glob <- rast(list.files(path = 'data/envs/global/allvars_global_processed/', pattern = '.tif$', full.names = T))
envs_glob <- envs_glob[[names(envs_na)]]
names(envs_glob)

# run mess
eu_glob_mess <- ntb_mess(M_stack = raster::stack(envs_eu), G_stack = raster::stack(envs_glob))
plot(eu_glob_mess)

# plot
ggplot() +
  geom_spatraster(data = rast(eu_glob_mess)) +
  coord_sf(expand = F) +
  scale_fill_whitebox_c(palette = 'bl_yl_rd',
                        direction = -1,
                        name = 'MESS',
                        breaks = c(-20, 60),
                        labels = c('Dissimilar', 'Similar'),
                        guide = guide_colorbar(title.position = 'top',
                                               title.hjust = 0.5)) +
  theme_classic() +
  theme(panel.border = element_rect(fill = NA),
        panel.grid.major = element_line(),
        axis.text = element_text(size = 13),
        legend.position = 'top',
        legend.text = element_text(size = 13),
        legend.title = element_text(size = 16, face = 'bold', margin = margin(b = 15)))

