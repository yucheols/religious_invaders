#######  create (global - N America) and (global - [N America + Africa]) occurrence points sets

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# load packages
library(terra)
library(sf)
library(dplyr)

####  load global occurrence & 
glob_occs <- read.csv('data/occs/global/global_occs_thin_30km.csv') %>% dplyr::select('long', 'lat', 'continent')
head(glob_occs)

####  map out 
map <- rast('data/envs/global/elev/elevation/wc2.1_2.5m/wc2.1_2.5m_elev.tif')
plot(map)

points(glob_occs[, c('long', 'lat')], col = 'red')

####  (global - N America)
glob_occs_filt <- glob_occs %>% dplyr::filter(continent != 'NORTH_AMERICA')
unique(glob_occs_filt$continent)

####  (global - [N America + Africa])
glob_occs_filt2 <- glob_occs_filt %>% dplyr::filter(continent != 'AFRICA')
unique(glob_occs_filt2$continent)

####  export
write.csv(glob_occs_filt, 'data/occs/global/global_minus_namerica.csv')
write.csv(glob_occs_filt2, 'data/occs/global/global_minus_namerica_africa.csv')
