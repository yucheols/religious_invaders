##############   plot output maps

# clean the working environment
rm(list = ls(all.names = T))
gc()

# load packages
library(terra)
library(tidyterra)
library(ggplot2)
library(ggpubr)


#####  religiosa North America complete data
# North America prediction



#####  religiosa North America Ecoregion ENMs and their global projections
# load North America projection rasters
e_pred <- rast('outputs/preds/M.religiosa East_preds.tif')
gp_pred <- rast('outputs/preds/M.religiosa GP_preds.tif')
w_pred <- rast('outputs/preds/M.religiosa W_preds.tif')

eco_preds <- c(e_pred, gp_pred, w_pred)
names(eco_preds) = c('East', 'Great Plains', 'West')
print(eco_preds)

# plot
eco_preds_plot <- ggplot() +
  geom_spatraster(data = eco_preds) +
  facet_wrap(~ lyr) +
  coord_sf(expand = F) +
  scale_fill_grass_c(palette = 'inferno') +
  scale_x_continuous(breaks = seq(from = -120, to = 70, by = 15)) +
  labs(fill = 'Suitability') +
  theme_bw() +
  theme(strip.text = element_text(size = 14),
        legend.title = element_text(size = 14, face = 'bold', margin = margin(b = 15)),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 12),
        axis.text.x = element_text(angle = 25, hjust = 1))


# load global projection rasters
e_glob_pred <- rast('outputs/preds/M.religiosa East_proj2Glob.tif')
gp_glob_pred <- rast('outputs/preds/M.religiosa GP_proj2Glob.tif')
w_glob_pred <- rast('outputs/preds/M.religiosa W_proj2Glob.tif')

eco_glob_preds <- c(e_glob_pred, gp_glob_pred, w_glob_pred)
names(eco_glob_preds) = names(eco_preds)
print(eco_glob_preds)

# plot
eco_glob_preds_plot <- ggplot() +
  geom_spatraster(data = eco_glob_preds) +
  facet_wrap(~ lyr) +
  coord_sf(expand = F) +
  scale_fill_grass_c(palette = 'inferno') + 
  labs(fill = 'Suitability') +
  theme_bw() +
  theme(strip.text = element_text(size = 14),
        legend.title = element_text(size = 14, face = 'bold', margin = margin(b = 15)),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 12),
        axis.text.x = element_text(angle = 25, hjust = 1))

# combine two plots
ggarrange(eco_preds_plot, eco_glob_preds_plot, ncol = 1, nrow = 2, align = 'hv')
