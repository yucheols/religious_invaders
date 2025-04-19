#####  ENM for M. religiosa calibrated on North America East, Central, and West == model at 5km scale 

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# increase java heap space
options(java.parameters = "-Xmx32G")

# load packages
library(terra)
library(sf)
library(ENMwrap)
library(blockCV)
library(ntbox)
library(dplyr)

# session info
sessionInfo()


################   USE ENMwrap TO MAKE MODELS PER ECOREGION

#####  part 1 ::: load data ----------
# load environmental variables == these are at 5km resolution
i.envs <- rast(list.files(path = 'data/envs/subset/north_america/', pattern = '.tif$', full.names = T))
print(i.envs)
plot(i.envs[[1]])

# load occurrences
e.occs <- read.csv('data/occs/north_america/by_ecoregion/na_east.csv') %>% dplyr::select('long', 'lat')
gp.occs <- read.csv('data/occs/north_america/by_ecoregion/na_great_plains.csv') %>% dplyr::select('long', 'lat')
w.occs <- read.csv('data/occs/north_america/by_ecoregion/na_west.csv') %>% dplyr::select('long', 'lat')

head(e.occs)
head(gp.occs)
head(w.occs)

points(e.occs, col = 'pink', pch = 21)
points(gp.occs, col = 'yellow', pch = 23)
points(w.occs, col = 'green', pch = 25)


#####  part 2 ::: sample background points ----------
# first make buffers
buff <- buff_maker(occs_list = list(e.occs, gp.occs, w.occs), envs = raster::stack(i.envs), buff_dist = 300000)
glimpse(buff)

plot(buff[[1]], border = 'pink', lwd = 3, add = T)
plot(buff[[2]], border = 'yellow', lwd = 3, add = T)
plot(buff[[3]], border = 'green', lwd = 3, add = T)

# sample 10000 bg each
bg <- bg_sampler(envs = raster::raster(i.envs[[1]]), n = 10000, occs_list = list(e.occs, gp.occs, w.occs), buffer_list = buff, excludep = T, method = 'buffer')

plot(i.envs[['elev']])
points(bg[[1]], col = 'pink')
points(bg[[2]], col = 'yellow')
points(bg[[3]], col = 'green')


# export sample bg
labs <- c('east', 'great_plains', 'west')

for (i in 1:length(bg)) {
  write.csv(bg[[i]], paste0('data/bg/north_america_', labs[[i]], '.csv'))
}


#####  part 3 ::: clean NAs from point data ----------
occs.narm <- na_cleaner(pts = list(e.occs, gp.occs, w.occs), envs = i.envs, x = 'long', y = 'lat')
bg.narm <- na_cleaner(pts = bg, envs = i.envs, x = 'long', y = 'lat')

class(occs.narm)
class(bg.narm)

#####  part 4 ::: partition the data ----------
# find the block size to use
get_block_size <- block_size(points = occs.narm, raster = raster::stack(i.envs), num_sample = 10000, crs = 4326)
glimpse(get_block_size)

# get partitions
e_blocks <- fold_maker(occs = occs.narm[[1]], bg.list = list(bg.narm[[1]]), envs = raster::stack(i.envs), k = 5, block.size = get_block_size[[1]])
gp_blocks <- fold_maker(occs = occs.narm[[2]], bg.list = list(bg.narm[[2]]), envs = raster::stack(i.envs), k = 5, block.size = get_block_size[[2]])
w_blocks <- fold_maker(occs = occs.narm[[3]], bg.list = list(bg.narm[[3]]), envs = raster::stack(i.envs), k = 5, block.size = get_block_size[[3]])

# patition occs & bg partitions by ecoregion
e.occs.folds <- e_blocks[[1]][[1]]
e.bg.folds <- e_blocks[[2]][[1]]

gp.occs.folds <- gp_blocks[[1]][[1]]
gp.bg.folds <- gp_blocks[[2]][[1]]

w.occs.folds <- w_blocks[[1]][[1]]
w.bg.folds <- w_blocks[[2]][[1]]

# make named list
e.user.grps <- list(occs.grp = as.vector(e.occs.folds)$fold_id,
                    bg.grp = as.vector(e.bg.folds)$fold_id)

gp.user.grp <- list(occs.grp = as.vector(gp.occs.folds)$fold_id,
                    bg.grp = as.vector(gp.bg.folds)$fold_id)

w.user.grp <- list(occs.grp = as.vector(w.occs.folds)$fold_id,
                   bg.grp = as.vector(w.bg.folds)$fold_id)

# combine all
user.grp <- list(e.user.grps, gp.user.grp, w.user.grp)

# export folds
saveRDS(user.grp, 'outputs/folds/north_america_ecoregion_folds.rds')


#####  part 5 ::: run models ----------
# define taxon list
taxon.list <- list('M.religiosa East', 'M.religiosa GP', 'M.religiosa W')

# run models
na_mods <- test_multisp(taxon.list = taxon.list,
                        occs.list = occs.narm,
                        envs = i.envs,
                        bg = bg.narm,
                        tune.args = list(rm = seq(0.5, 5, by = 0.5),
                                         fc = c('L', 'LQ', 'H', 'LQH', 'LQHP', 'LQHPT')),
                        partitions = 'user',
                        user.grp = user.grp,
                        type = 'type1')

# look at the selected optimal models
print(na_mods$metrics)

# look at variable contributions
print(na_mods$contrib[[1]])  # east
print(na_mods$contrib[[2]])  # great plains
print(na_mods$contrib[[3]])  # west

# look at predictions
plot(na_mods$preds[[1]])  # east
plot(na_mods$preds[[2]])  # great plains
plot(na_mods$preds[[3]])  # west

# export tuning object
saveRDS(na_mods, 'outputs/models/north_america_ecoreion_tuning.rds')

# export metrics
write.csv(na_mods$metrics, 'outputs/metrics/ecoregion_models_metrics.csv')

# export contribution
for (i in 1:length(na_mods$contrib)) {
  write.csv(na_mods$contrib[[i]], paste0('outputs/contrib/', taxon.list[[i]], '_contrib.csv'))
}

# export prediction
for (i in 1:nlayers(na_mods$preds)) {
  raster::writeRaster(na_mods$preds[[i]], paste0('outputs/preds/', taxon.list[[i]], '_preds.tif'), overwrite = T)
}


#####  part 6 ::: plot response curves ----------
# pull response curve data
resp_data <- list()

for (i in 1:length(taxon.list)) {
  pull_data <- resp_data_pull(sp.name = taxon.list[[i]], model = na_mods$models[[i]], names.var = names(i.envs))
  resp_data[[i]] <- pull_data
}

# export response data
for (i in 1:length(resp_data)) {
  write.csv(resp_data[[i]], paste0('outputs/resp_data/', taxon.list[[i]], '_resp_data.csv'))
}

# plot curves



#####  part 7 ::: global prediction ----------
# global data
glob.envs <- raster::stack(list.files(path = 'data/envs/subset/global/', pattern = '.tif$', full.names = T))
names(glob.envs) != names(i.envs)

# make predictions
glob.pred <- model_predictr(model = na_mods$models, preds.list = glob.envs, pred.names = c('East', 'Great Plains', 'West'), method = 'multi2single')
print(glob.pred)

plot(glob.pred[[1]])
plot(glob.pred[[2]])
plot(glob.pred[[3]])

# export predictions
for (i in 1:nlayers(glob.pred)) {
  raster::writeRaster(glob.pred[[i]], paste0('outputs/preds/', taxon.list[[i]], '_proj2Glob.tif'), overwrite = T)
}
