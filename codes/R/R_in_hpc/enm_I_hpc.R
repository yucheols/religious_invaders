#####  Invaded range ENM for M. religiosa (North America) == model at 10km scale == run this script on Mendel cluster
#####  use only North America occurrence points (i.e. no projection from the native range models)
#####  trial run 1

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# load packages
library(terra)
library(sf)
library(SDMtune)
library(biomod2)
library(dplyr)

# record session info
sessionInfo()

# specify maxent.jar path
options(maxent.jar = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/maxent.jar')


#####  part 1. prep data ---------------
# load environmental variables
envs <- rast(list.files(path = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/envs/north_america', pattern = '.tif$', full.names = T))
envs <- envs[[c('bio1', 'bio2', 'bio12', 'bio15', 'cropland', 'elev', 'grassland', 'human_footprint', 'trees')]]

# resample to 10km resolution (fact = 2)
envs <- terra::aggregate(envs, fact = 2)
print(envs)

# load occs
occs <- read.csv('/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/occs/north_america/north_america_occs_raw.csv')
head(occs)

# occurrence thinning
occs_thin <- SDMtune::thinData(coords = occs, env = envs, x = 'long', y = 'lat', verbose = T, progress = T)
occs <- occs_thin[, c('long', 'lat')]

# load background points == note these were sampled 100x the size of occurrence points, and there were sampled on a kernel density surface 
# of European M.religiosa data points
# from this set, we will draw three different sets of background points, each set with 10x the number of occurrence points 
bg <- read.csv('/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/bg/kde_biomod2/bg_namerica.csv') %>% dplyr::select('long', 'lat')
head(bg)

# bind occs and bg == mark occs 1, mark bg as NA
occs$pa <- 1
bg$pa <- NA

colnames(occs) == colnames(bg)         # ensure same column names
pts <- rbind(occs, bg)                 # bind


#####  part 2. data formatting & parameter specification ---------------
### format data
bm_data <- BIOMOD_FormatingData(resp.name = 'Mantis religiosa_namerica',
                                resp.var = vect(pts, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                                expl.var = envs,
                                dir.name = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/namerica_5km/output',
                                PA.nb.rep = 3,
                                PA.nb.absences = nrow(occs)*10,
                                PA.strategy = 'random',
                                filter.raster = T,
                                na.rm = T)

### prep cross-validation data
#cv <- bm_CrossValidation(bm.format = bm_data,
#                         strategy = 'env',
#                         k = 5,
#                         perc = 0.7,
#                         do.full.models = T)


### tune parameters for RFd and MaxEnt
opt_tn <- bm_ModelingOptions(data.type = 'binary',
                             models = c('RFd','MAXENT'),
                             strategy = 'tuned',
                             bm.format = bm_data)


### set GAM and GBM paramters to bigboss specification
opt_bb <- bm_ModelingOptions(data.type = 'binary',
                             models = c('GAM', 'GBM'),
                             strategy = 'bigboss',
                             bm.format = bm_data)


### gather user specified paramters
opt_user <- c(opt_tn, opt_bb)


#####  part 3. run single models ---------------
### use pre-defined parameterization
mods_single_tn <- BIOMOD_Modeling(bm.format = bm_data,
                                  modeling.id = 'religiosa_na_singles_tuned',
                                  models = c('GAM', 'GBM','RFd','MAXENT'),
                                  CV.strategy = 'env',
                                  CV.perc = 0.7,
                                  CV.k = 5,
                                  CV.balance = 'presences',
                                  CV.strat = 'both',
                                  CV.do.full.models = F,
                                  OPT.data.type = 'binary',
                                  OPT.strategy = 'user.defined',
                                  OPT.user.val = opt_user,
                                  metric.eval = c('ROC','TSS','BOYCE'),
                                  var.import = 1,
                                  seed.val = 123,
                                  do.progress = T)

# check model results
print(mods_single_tn)

# get evaluation
single_mods_eval_metrics <- get_evaluations(mods_single_tn)
write.csv(single_mods_eval_metrics, '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/namerica_5km/output/single_mods_eval_metrics.csv')


#####  part 3. run ensemble models ---------------
# run
mods_em <- BIOMOD_EnsembleModeling(bm.mod = mods_single_tn,
                                   models.chosen = 'all',
                                   em.by = 'all',
                                   em.algo = c('EMmean'),
                                   metric.select = c('TSS'),
                                   metric.select.thresh = c(0.7),
                                   seed.val = 123,
                                   do.progress = T)

# check model results
print(mods_em)

# get evaluation
em_eval_metrics <- get_evaluations(mods_em)
write.csv(em_eval_metrics, '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/namerica_5km/output/em_eval_metrics.csv')


#####  part 5. projection ---------------
### project ensemble models to the current envs
em_proj <- BIOMOD_EnsembleForecasting(bm.em = mods_em,
                                      bm.proj = NULL,
                                      proj.name = 'religiosa_namerica_5km',
                                      new.env = envs,
                                      models.chosen = 'all',
                                      metric.binary = c('TSS'),
                                      metric.filter = c('TSS'))

### project to Europe
# load Europe envs layers
envs_eu <- rast(list.files(path = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/envs/europe', pattern = '.tif$', full.names = T))
envs_eu <- envs_eu[[c('bio1', 'bio2', 'bio12', 'bio15', 'cropland', 'elev', 'grassland', 'human_footprint', 'trees')]]

# project
em_proj_eu <- BIOMOD_EnsembleForecasting(bm.em = mods_em,
                                         bm.proj = NULL,
                                         proj.name = 'religiosa_namerica2eu_5km',
                                         new.env = envs_eu,
                                         models.chosen = 'all',
                                         metric.binary = c('TSS'),
                                         metric.filter = c('TSS'))

### project globally
# load global layers
envs_glob <- rast(list.files(path = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/envs/global/allvars_global_processed', pattern = '.tif$', full.names = T))
envs_glob <- envs_glob[[c('bio1', 'bio2', 'bio12', 'bio15', 'cropland', 'elev', 'grassland', 'human_footprint', 'trees')]]

# project
em_proj_glob <- BIOMOD_EnsembleForecasting(bm.em = mods_em,
                                           bm.proj = NULL,
                                           proj.name = 'religiosa_namerica2glob_5km',
                                           new.env = envs_glob,
                                           models.chosen = 'all',
                                           metric.binary = c('TSS'),
                                           metric.filter = c('TSS'))
