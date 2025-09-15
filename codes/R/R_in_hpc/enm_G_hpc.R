#####  Global scale ENM for M. religiosa == model at 10km scale == run this script on Mendel cluster
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

#####  part 1. prep data ---------------
# load environmental variables
envs <- rast(list.files(path = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/envs/global/allvars_global_processed', pattern = '.tif$', full.names = T))
envs <- envs[[c('bio1', 'bio2', 'bio12', 'bio15', 'built', 'cropland', 'elev', 'grassland', 'human_footprint', 'shrubs', 'trees')]]

# these rasters are at 5km resolution (= 0.04166667dd) == resample to 10km using "aggregate" with a factor of 2
envs <- aggregate(envs, fact = 2)

# load occs
occs <- read.csv('/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/occs/global/global_occs_raw.csv')
head(occs)

# thin occurrence points
occs_thin <- SDMtune::thinData(coords = occs, env = envs, x = 'long', y = 'lat', verbose = T, progress = T)
occs <- occs_thin[, c('long', 'lat')]


#####  part 2. data formatting & CV specification ---------------
### format data
bm_data <- BIOMOD_FormatingData(resp.name = 'Mantis religiosa',
                                resp.var = vect(occs, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                                expl.var = envs,
                                dir.name = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/global_10km/output',
                                PA.nb.rep = 5,
                                PA.nb.absences = 100000,
                                PA.strategy = 'random',
                                na.rm = T)

### prep cross-validation data
cv <- bm_CrossValidation(bm.format = bm_data,
                         strategy = 'env',
                         k = 5,
                         perc = 0.7,
                         do.full.models = T)


#####  part 3. run single models ---------------
### use pre-defined parameterization
mods_single_bb <- BIOMOD_Modeling(bm.format = bm_data,
                                  modeling.id = 'religiosa_singles_bigboss',
                                  models = c('GAM', 'GBM','RFd','MAXNET'),
                                  CV.strategy = 'env',
                                  CV.perc = 0.7,
                                  CV.k = 5,
                                  CV.balance = 'presences',
                                  CV.strat = 'both',
                                  CV.do.full.models = T,
                                  OPT.data.type = 'binary',
                                  OPT.strategy = 'bigboss',
                                  metric.eval = c('ROC','TSS','BOYCE'),
                                  var.import = 100,
                                  seed.val = 123,
                                  do.progress = T)


#####  part 3. run ensemble models ---------------
# look at eval metrics to dicede on the cutoff value
eval.metrics <- get_evaluations(mods_single_bb)[, c('metric.eval', 'validation')]
print(eval.metrics)

# TSS
eval.tss <- eval.metrics %>% filter(metric.eval == 'TSS') %>% na.omit()
mean(eval.tss$validation)

# run
mods_em <- BIOMOD_EnsembleModeling(bm.mod = mods_single_bb,
                                   models.chosen = 'all',
                                   em.by = 'all',
                                   em.algo = c('EMmean'),
                                   metric.select = c('TSS'),
                                   metric.select.thresh = c(mean(eval.tss$validation) + 0.25),
                                   seed.val = 123,
                                   do.progress = T)


#####  part 5. projection ---------------
### project ensemble models to the current envs
em_proj <- BIOMOD_EnsembleForecasting(bm.em = mods_em,
                                      bm.proj = NULL,
                                      proj.name = 'religiosa_global_10km',
                                      new.env = envs,
                                      models.chosen = 'all',
                                      metric.binary = c('TSS'),
                                      metric.filter = c('TSS'))



