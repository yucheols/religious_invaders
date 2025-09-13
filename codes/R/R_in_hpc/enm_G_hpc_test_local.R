#####  Global scale ENM for M. religiosa == model at 10km scale == run this script on Mendel cluster
#####  test locally with Europe dataset

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
# load environmental variables == the input path needs to change for the actual HPC run
envs <- rast(list.files('data/envs/europe/', pattern = '.tif$', full.names = T))
envs <- envs[[c('bio1', 'bio2', 'bio12', 'bio15', 'built', 'cropland', 'elev', 'grassland', 'human_footprint', 'shrubs', 'trees')]]
nlyr(envs)
names(envs)

# these rasters are at 5km resolution (= 0.04166667dd) == resample to 10km using "aggregate" with a factor of 2
envs <- aggregate(envs, fact = 2)
res(envs)

# load occurrence == grab 50 points for faster run == this will not be used in the actual run on the cluster
occs <- read.csv('data/occs/europe/europe_occs_thin_30km.csv')
occs <- occs[sample(nrow(occs), 50), ]
head(occs)

occs <- occs[, c('long', 'lat')]


#####  part 2. data formatting & CV specification ---------------
### format data
bm_data <- BIOMOD_FormatingData(resp.name = 'Mantis religiosa',
                                resp.var = vect(occs, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                                expl.var = envs,
                                dir.name = 'hpc_test_loc',
                                PA.nb.rep = 1,
                                PA.nb.absences = 200,
                                PA.strategy = 'random',
                                na.rm = T)

# check formatted data
summary(bm_data)
plot(bm_data)    # do not use this in the cluster!


### prep cross-validation data
cv <- bm_CrossValidation(bm.format = bm_data,
                         strategy = 'random',
                         nb.rep = 1,
                         perc = 0.7,
                         do.full.models = T)


### tune model parameters == this will take a long time (almost 6 hours on my computer)
#mod.opts <- bm_ModelingOptions(data.type = 'binary',
#                               models = c('GBM','RF','MAXENT'),
#                               strategy = 'tuned',
#                               bm.format = bm_data)

#print(mod.opts)
#class(mod.opts)

# save tuning object as RDS file for later use // because we dont want to run this again!!!!
#saveRDS(mod.opts, 'hpc_test_loc/religiosa_model_tuning_out.rds')


#####  part 3. run single models ---------------

### use pre-defined parameterization
mods_single_bb <- BIOMOD_Modeling(bm.format = bm_data,
                                  modeling.id = 'religiosa_singles_bigboss',
                                  models = c('GBM','RF','MAXENT'),
                                  CV.strategy = 'random',
                                  CV.nb.rep = 1,
                                  CV.perc = 0.7,
                                  CV.do.full.models = T,
                                  OPT.data.type = 'binary',
                                  OPT.strategy = 'bigboss',
                                  metric.eval = c('ROC','TSS','BOYCE'),
                                  seed.val = 123,
                                  do.progress = T)

# check model results
print(mods_single_bb)

# get evaluation
get_evaluations(mods_single_bb)

# look at mean response curves
bm_PlotResponseCurves(bm.out = mods_single_bb, models.chosen = 'all', fixed.var = 'mean')  # dont run this in the cluster


#####  part 4. run ensemble models ---------------
### look at eval metrics to dicede on the cutoff value
eval.metrics <- get_evaluations(mods_single_bb)[, c('metric.eval', 'validation')]
print(eval.metrics)

# TSS
eval.tss <- eval.metrics %>% filter(metric.eval == 'TSS') %>% na.omit()
mean(eval.tss$validation)

# ROC
eval.roc <- eval.metrics %>% filter(metric.eval == 'ROC') %>% na.omit()
mean(eval.roc$validation)

# BOYCE
eval.boyce <- eval.metrics %>% filter(metric.eval == 'BOYCE') %>% na.omit()
mean(eval.boyce$validation)


### run
mods_em <- BIOMOD_EnsembleModeling(bm.mod = mods_single_bb,
                                   models.chosen = 'all',
                                   em.by = 'all',
                                   em.algo = c('EMmean','EMmedian'),
                                   metric.select = c('TSS','ROC','BOYCE'),
                                   metric.select.thresh = c(mean(eval.tss$validation), mean(eval.roc$validation), mean(eval.boyce$validation)),
                                   var.import = 5,
                                   seed.val = 123,
                                   do.progress = T)


#####  part 5. projection ---------------
### project ensemble models to the current envs
em_proj_test <- BIOMOD_EnsembleForecasting(bm.em = mods_em,
                                           bm.proj = NULL,
                                           proj.name = 'religiosa_test',
                                           new.env = envs,
                                           models.chosen = 'all',
                                           metric.binary = c('TSS','ROC','BOYCE'),
                                           metric.filter = c('TSS','ROC','BOYCE'))


### see model predictions == note that the scale is (predicted habitat suitability) * 1000 == thus on the scale of 0-1000
### simply divide this raster by 1000 to make the scale 0-1
### current
pred_test <- rast('hpc_test_loc/Mantis.religiosa/proj_religiosa_test/proj_religiosa_test_Mantis.religiosa_ensemble.tif')
pred_test <- pred_test[[1]]/1000
plot(pred_test)  # dont use this in the cluster

# export ensemble raster
writeRaster(pred_test, 'hpc_test_loc/Mantis.religiosa/test_outputs/religiosa_test_ensemble.tif', overwrite = T)
