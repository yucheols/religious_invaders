#####  ENM for M. religiosa calibrated on North America using all available data == model at 5km scale 

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
library(ENMeval)
library(blockCV)
library(ntbox)
library(dplyr)

# session info
sessionInfo()


#####  part 1 ::: load data ----------

# load environmental variables == these are at 5km resolution
i.envs <- rast(list.files(path = 'data/envs/subset/north_america/', pattern = '.tif$', full.names = T))
print(i.envs)
plot(i.envs[[1]])

# load thinned occurrences
i.occs <- read.csv('data/occs/north_america/north_america_occs_thin_30km.csv')
i.occs$X <- NULL
head(i.occs)

# load background data
i.bg <- read.csv('data/bg/north_america_20000.csv')
i.bg$X <- NULL
head(i.bg)


#####  part 2 ::: generate data partitions for model evaluation ----------
# remove NAs from occurrence dataset
i.occs.narm <- as.data.frame(terra::extract(i.envs, i.occs[, c('long', 'lat')]))
i.occs.narm <- cbind(i.occs.narm, i.occs[, c('long', 'lat')]) %>% na.omit() %>% dplyr::select('long', 'lat')
head(i.occs.narm)

# remove NAs from background dataset
i.bg.narm <- as.data.frame(terra::extract(i.envs, i.bg))
i.bg.narm <- cbind(i.bg.narm, i.bg) %>% na.omit() %>% dplyr::select('long', 'lat')
head(i.bg.narm)

# prep data for custom block sampling
pts <- rbind(i.occs.narm, i.bg.narm)
pts$occ <- c(rep(1, nrow(i.occs.narm)), rep(0, nrow(i.bg.narm)))

# investigate spatial autocorrelation in the landscape to choose a suitable size for spatial blocks
folds.cor <- cv_spatial_autocor(r = i.envs, x = st_as_sf(pts, coords = c('long', 'lat'), crs = 4326), column = 'occ', num_sample = 10000, plot = T, progress = T)

# generate folds
scv <- cv_spatial(x = st_as_sf(pts, coords = c('long', 'lat'), crs = 4326), column = 'occ', r = i.envs, k = 5, hexagon = T, flat_top = F, size = folds.cor$range, 
                  selection = 'random', iteration = 50, progress = T, report = T, plot = T, raster_colors = terrain.colors(10, rev = T)) 

# plot folds
cv_plot(cv = scv, x = st_as_sf(pts, coords = c('long', 'lat'), crs = 4326))

# separate occs and bg folds
fold_ids <- data.frame(fold_ids = scv$folds_ids)
folds <-  cbind(pts, fold_ids)
head(folds)

occs.folds <- folds %>% dplyr::filter(occ == 1) %>% dplyr::select('fold_ids')
bg.folds <- folds %>% dplyr::filter(occ == 0) %>% dplyr::select('fold_ids')

# export folds
saveRDS(as.vector(occs.folds)$fold_ids, 'outputs/folds/occs_fold.rds')
saveRDS(as.vector(bg.folds)$fold_ids, 'outputs/folds/bg_fold.rds')


#####  part 3 ::: run models at 5km spatial resolution ----------
# run the model
i.mods <- ENMevaluate(taxon.name = 'Mantis religiosa',
                      occs = i.occs.narm, 
                      envs = i.envs,
                      bg = i.bg.narm,
                      tune.args = list(rm = seq(0.5, 5, by = 0.5),
                                       fc = c('L', 'LQ', 'H', 'LQH', 'LQHP', 'LQHPT')),
                      partitions = 'user',
                      user.grp = list(occs.grp = as.vector(occs.folds)$fold_ids,
                                      bg.grp = as.vector(bg.folds)$fold_ids),
                      algorithm = 'maxent.jar',
                      doClamp = T)

# save model object
#saveRDS(i.mods, 'outputs/models/north_america_model_alldata.rds')

# find optimal model based on the lowest 10% omission rate, highest CBI, and highest test AUC
i.tune.res <- eval.results(i.mods)
i.find.opt <- i.tune.res %>% 
  dplyr::filter(or.10p.avg == min(or.10p.avg)) %>%
  dplyr::filter(cbi.val.avg == max(cbi.val.avg)) %>%
  dplyr::filter(auc.val.avg == max(auc.val.avg)) %>%
  print()

# the optimal model based on the above criteria is LQ 3...lets look at the prediction map
# fit the optimal model again because re-loading R makes the tuning run object to corrupt :(
i.opt.mod <- ENMevaluate(taxon.name = 'Mantis religiosa', occs = i.occs.narm, envs = i.envs, bg = i.bg.narm, tune.args = list(rm = 3, fc = 'LQ'), partitions = 'user',
                         user.grp = list(occs.grp = as.vector(occs.folds)$fold_ids, bg.grp = as.vector(bg.folds)$fold_ids), algorithm = 'maxent.jar', doClamp = T)

# now look at the actual prediction
i.opt.pred <- eval.predictions(i.opt.mod)
plot(i.opt.pred)

# export prediction
writeRaster(i.opt.pred, 'outputs/preds/north_america_alldata.tif', overwrite = T)


#####  part 4 ::: model evaluation against null models ---------- 
i.nulls <- ENMnulls(e = i.opt.mod, mod.settings = list(fc = 'LQ', rm = 3), no.iter = 2, user.eval.type = 'kspatial')

#####  part 5 ::: make a global prediction ---------- 
# load global data
glob.envs <- rast(list.files(path = 'data/envs/subset/global/', pattern = '.tif$', full.names = T))
plot(glob.envs[[1]])

# prediction
glob.pred <- predicts::predict(object = i.opt.mod@models$rm.3_fc.LQ, x = glob.envs)
plot(glob.pred)

# export prediction
writeRaster(glob.pred, 'outputs/preds/north_america_alldata_to_global.tif')
