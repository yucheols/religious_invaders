#####  Global scale ENM for M. religiosa

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# load packages
library(terra)
library(sf)
library(ENMeval)
library(blockCV)

# session info
sessionInfo()

#####  part 1 ::: load data ----------
# thinned occurrences
glob.occs <- read.csv('data/occs/global/global_occs_thin_30km.csv')
glob.occs$X <- NULL
head(glob.occs)

# environment
glob.envs <- rast(list.files(path = 'data/envs/subset/global/', pattern = '.tif$', full.names = T))
print(glob.envs)
plot(glob.envs[[1]])

# background points
glob.bg <- read.csv('data/bg/global_20000_kd.csv') 
glob.bg$X <- NULL
head(glob.bg)

# plot points
points(glob.bg, col = 'red')
points(glob.occs[, c('long', 'lat')], col = 'green')


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


#####  part 3 ::: run models ----------
glob.mod <- ENMevaluate(taxon.name = 'Mantis religiosa_Global',
                        occs = glob.occs.narm,
                        bg = glob.bg.narm,
                        envs = glob.envs,
                        tune.args = list(fc = c('L','LQ','H','LQH','LQHP','LQHPT'),
                                         rm = seq(1,5, by = 0.5)),
                        partitions = 'checkerboard',
                        partition.settings = list(aggregation.factor = c(10,10)),
                        algorithm = 'maxent.jar',
                        doClamp = T)
