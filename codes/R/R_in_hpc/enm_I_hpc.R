#####  Invaded range ENM for M. religiosa (North America) == model at 5km scale == run this script on Mendel cluster
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


#####  part 1. prep data ---------------
# load environmental variables
envs <- rast(list.files(path = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/input/data/envs/north_america', pattern = '.tif$', full.names = T))
envs <- envs[[c('bio1', 'bio2', 'bio12', 'bio15', 'built', 'cropland', 'elev', 'grassland', 'human_footprint', 'shrubs', 'trees')]]

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


#####  part 2. data formatting & CV specification ---------------
### format data
bm_data <- BIOMOD_FormatingData(resp.name = 'Mantis religiosa_namerica',
                                resp.var = vect(occs, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                                expl.var = envs,
                                dir.name = '/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/namerica_5km/output',
                                PA.nb.rep = 3,
                                PA.nb.absences = nrow(occs)*10,
                                PA.strategy = 'random',
                                filter.raster = T,
                                na.rm = T)

### prep cross-validation data
cv <- bm_CrossValidation(bm.format = bm_data,
                         strategy = 'env',
                         k = 5,
                         perc = 0.7,
                         do.full.models = T)


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
                                  CV.do.full.models = T,
                                  OPT.data.type = 'binary',
                                  OPT.strategy = 'tuned',
                                  metric.eval = c('ROC','TSS','BOYCE'),
                                  var.import = 100,
                                  seed.val = 123,
                                  do.progress = T)


#####  part 3. run ensemble models ---------------
# run
mods_em <- BIOMOD_EnsembleModeling(bm.mod = mods_single_bb,
                                   models.chosen = 'all',
                                   em.by = 'all',
                                   em.algo = c('EMmean'),
                                   metric.select = c('TSS'),
                                   metric.select.thresh = c(0.8),
                                   seed.val = 123,
                                   do.progress = T)


#####  part 5. projection ---------------
### project ensemble models to the current envs
em_proj <- BIOMOD_EnsembleForecasting(bm.em = mods_em,
                                      bm.proj = NULL,
                                      proj.name = 'religiosa_namerica_5km',
                                      new.env = envs,
                                      models.chosen = 'all',
                                      metric.binary = c('TSS'),
                                      metric.filter = c('TSS'))
