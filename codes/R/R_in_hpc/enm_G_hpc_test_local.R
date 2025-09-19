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
envs <- envs[[c('bio1', 'bio2', 'bio12', 'bio15', 'cropland', 'elev', 'grassland', 'human_footprint', 'trees')]]
nlyr(envs)
names(envs)

# these rasters are at 5km resolution (= 0.04166667dd) == resample to 10km using "aggregate" with a factor of 2
envs <- aggregate(envs, fact = 2)
res(envs)

# load occurrence == grab 50 points for faster run == this will not be used in the actual run on the cluster
occs <- read.csv('data/occs/europe/europe_occs_thin_30km.csv')
head(occs)

# test thinning
occs_thin <- SDMtune::thinData(coords = occs, env = envs, x = 'long', y = 'lat', verbose = T, progress = T)
head(occs_thin)

# randomly grab 50 points
occs <- occs_thin[sample(nrow(occs_thin), 50), ]
head(occs)

occs <- occs[, c('long', 'lat')]

# load pre-sampled background points and randomly grab 200
bg <- read.csv('data/bg/kde_biomod2/bg_europe.csv') %>% dplyr::select('long', 'lat')
bg <- bg[sample(nrow(bg), 400), ]

# bind occs and bg == mark occs 1, mark bg as NA
occs$pa <- 1
bg$pa <- NA

colnames(occs) == colnames(bg)         # ensure same column names
pts <- rbind(occs, bg)                 # bind


#####  part 2. data formatting & CV specification ---------------
### format data
bm_data <- BIOMOD_FormatingData(resp.name = 'Mantis religiosa',
                                resp.var = vect(pts, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                                expl.var = envs,
                                dir.name = 'hpc_test_loc',
                                PA.nb.rep = 2,
                                PA.nb.absences = 200,
                                PA.strategy = 'random',
                                filter.raster = T,
                                na.rm = T)

# check formatted data
summary(bm_data)
plot(bm_data)    # do not use this in the cluster!


### prep cross-validation data
#cv <- bm_CrossValidation(bm.format = bm_data,
#                         strategy = 'env',
#                         k = 5,
#                         balance = 'presences',
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
                                  modeling.id = 'religiosa_singles_bigboss',
                                  models = c('GAM', 'GBM','RFd','MAXENT'),
                                  CV.strategy = 'random',
                                  CV.nb.rep = 1,
                                  CV.perc = 0.7,
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
get_evaluations(mods_single_tn)

# look at mean response curves
bm_PlotResponseCurves(bm.out = mods_single_bb, models.chosen = 'all', fixed.var = 'mean')  # dont run this in the cluster


#####  part 4. run ensemble models ---------------
### run
mods_em <- BIOMOD_EnsembleModeling(bm.mod = mods_single_tn,
                                   models.chosen = 'all',
                                   em.by = 'all',
                                   em.algo = c('EMmean','EMmedian'),
                                   metric.select = c('TSS'),
                                   metric.select.thresh = c(0.2),
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
                                           metric.binary = c('TSS'),
                                           metric.filter = c('TSS'))


### see model predictions == note that the scale is (predicted habitat suitability) * 1000 == thus on the scale of 0-1000
### simply divide this raster by 1000 to make the scale 0-1
### current
pred_test <- rast('hpc_test_loc/Mantis.religiosa/proj_religiosa_test/proj_religiosa_test_Mantis.religiosa_ensemble.tif')
pred_test <- pred_test[[1]]/1000
plot(pred_test)  # dont use this in the cluster

# export ensemble raster
writeRaster(pred_test, 'hpc_test_loc/Mantis.religiosa/religiosa_test_ensemble.tif', overwrite = T)
