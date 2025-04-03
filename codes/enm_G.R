#####  Global scale ENM for M. religiosa == model at 30km scale for faster computation

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
library(SDMtune)
library(ENMeval)
library(ntbox)
library(dplyr)

# session info
sessionInfo()

#####  part 1 ::: load data ----------

# load environmental variables == these are at 5km resolution == resample to 20km // 5*n = 20 ... agg factor of 4 
glob.envs <- rast(list.files(path = 'data/envs/subset/global/', pattern = '.tif$', full.names = T))
glob.envs <- aggregate(glob.envs, fact = 4)
print(glob.envs)
plot(glob.envs[[1]])

# load thinned occurrences and thin again
glob.occs <- read.csv('data/occs/global/global_occs_thin_30km.csv')
glob.occs <- thinData(coords = glob.occs, env = glob.envs, x = 'long', y = 'lat', verbose = T, progress = T)
glob.occs$X <- NULL
head(glob.occs)

# sample background points
#glob.kd <- biaslayer(occs_df = glob.occs, longitude = 'long', latitude = 'lat', raster_mold = raster::raster(glob.envs[[1]]))
#plot(glob.kd)

#glob.bg <- raster::xyFromCell(object = glob.kd, 
#                              sample(which(!is.na(values(subset(x = glob.envs[[1]], 1)))), 
#                                     size = 20000, prob = values(x = glob.kd)[!is.na(values(subset(x = glob.envs[[1]], 1)))])) %>% as.data.frame()

#colnames(glob.bg) = c('long', 'lat')
#write.csv(glob.bg, 'data/bg/global_20000_kd_20km.csv')

# load background data
glob.bg <- read.csv('data/bg/global_20000_kd_20km.csv')
glob.bg$X <- NULL
head(glob.bg)

# plot points
points(glob.bg, col = 'red')
points(glob.occs[, c('long', 'lat')], col = 'blue')


#####  part 2 ::: generate data partitions for model evaluation ----------
# remove NAs from occurrence dataset
glob.occs.narm <- as.data.frame(terra::extract(glob.envs, glob.occs[, c('long', 'lat')]))
glob.occs.narm <- cbind(glob.occs.narm, glob.occs[, c('long', 'lat')]) %>% na.omit() %>% dplyr::select('long', 'lat')
head(glob.occs.narm)

# remove NAs from background dataset
glob.bg.narm <- as.data.frame(terra::extract(glob.envs, glob.bg))
glob.bg.narm <- cbind(glob.bg.narm, glob.bg) %>% na.omit() %>% dplyr::select('long', 'lat')
head(glob.bg.narm)

# get checkerboard
ckb2 <- get.checkerboard(occs = glob.occs.narm, bg = glob.bg.narm, envs = glob.envs, aggregation.factor = c(10,10))
evalplot.grps(pts = glob.occs.narm, pts.grp = ckb2$occs.grp, envs = glob.envs)
evalplot.grps(pts = glob.bg.narm, pts.grp = ckb2$bg.grp, envs = glob.envs)


#####  part 3 ::: run models at 5km spatial resolution ----------
# format data for SDMtune
glob.swd <- prepareSWD(species = 'Mantis religiosa_Global', env = glob.envs, p = glob.occs.narm, a = glob.bg.narm, verbose = T)
print(glob.swd)

# train a base model
glob.mod <- SDMtune::train(method = 'Maxent', data = glob.swd, folds = ckb2, iter = 5000, progress = T)

# tune model parameters // save model = F to prevent crashing
glob.tune <- gridSearch(model = glob.mod,
                        hypers = list(reg = seq(1,5, by = 0.5),
                                      fc = c('l', 'lq', 'h', 'lqh', 'lqhp', 'lqhpt')),
                        metric = 'tss',
                        interactive = F,
                        progress = T,
                        save_models = F)

print(glob.tune@results)

# save the model test result
#saveRDS(glob.tune, 'outputs/models/global_model_test.rds')

# load saved model
glob.tune <- readRDS('outputs/models/global_model_test.rds')
print(glob.tune)
print(glob.tune@models)

# get the model with optimal parameters == lqhp 1.0 == default model
glob.opt <- glob.tune@results %>% dplyr::filter(test_TSS == max(test_TSS))
print(glob.opt)

# generate the prediction
glob.pred <- SDMtune::predict(object = glob.tune@models[[1]], data = glob.envs, type = 'cloglog', clamp = T, progress = T)
plot(glob.pred)

# export prediction raster. use GIS to fill out holes in the prediction
writeRaster(glob.pred, 'outputs/preds/global_20km.tif', overwrite = T)
