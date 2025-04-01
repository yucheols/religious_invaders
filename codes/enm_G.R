#####  Global scale ENM for M. religiosa == model at 10km scale for faster computation

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

# session info
sessionInfo()

#####  part 1 ::: load data ----------
# thinned occurrences
glob.occs <- read.csv('data/occs/global/global_occs_thin_30km.csv')
glob.occs$X <- NULL
head(glob.occs)

# load environmental variables
glob.envs <- rast(list.files(path = 'data/envs/subset/global/', pattern = '.tif$', full.names = T))
print(glob.envs)
plot(glob.envs[[1]])

# load background data
glob.bg <- read.csv('data/bg/global_20000_kd.csv')
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


#####  part 3 ::: run models at 20km spatial resolution ----------
# format data for SDMtune
glob.swd <- prepareSWD(species = 'Mantis religiosa_Global', env = glob.envs, p = glob.occs.narm, a = glob.bg.narm, verbose = T)
print(glob.swd)

# train a base model
glob.mod <- SDMtune::train(method = 'Maxent', data = glob.swd, folds = ckb2, iter = 5000, progress = T)

# tune model parameters
glob.tune <- gridSearch(model = glob.mod,
                        hypers = list(reg = seq(1,5, by = 0.5),
                                      fc = c('l', 'lq', 'h', 'lqh', 'lqhp', 'lqhpt')),
                        metric = 'tss',
                        interactive = F,
                        progress = T)

# save the output model object as RDS file
saveRDS()

# select optimal model parameter combination


