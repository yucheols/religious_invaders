##########  niche analyses for North Amercian (= non-native) populations
##########  combinations to test ::: East vs. Great Plains ::: East vs. West ::: Great Plains vs. West 

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set random seed for reproducibility
set.seed(100)

# load packages
library(terra)
library(sf)
library(ENMTools)
library(ntbox)
library(dplyr)
library(factoextra)


#####  part 1 ::: load occurrence data ----------
e.occs <- read.csv('data/occs/north_america/by_ecoregion/na_east.csv') %>% dplyr::select(2,3)
gp.occs <- read.csv('data/occs/north_america/by_ecoregion/na_great_plains.csv') %>% dplyr::select(2,3)
w.occs <- read.csv('data/occs/north_america/by_ecoregion/na_west.csv') %>% dplyr::select(2,3)

head(e.occs)
head(gp.occs)
head(w.occs)


#####  part 2 ::: load environmental data ----------
# load rasters
envs <- rast(list.files(path = 'data/envs/north_america/', pattern = '.tif$', full.names = T))
plot(envs[[1]])

# remove highly correlated variables
envs.df <- as.data.frame(envs) %>% na.omit()
print(envs.df)

env.cor <- cor(envs.df)
print(env.cor)

correlation_finder(cor_mat = env.cor, threshold = 0.7, verbose = T)

# retain bio1 bio2 bio8 bio12 bio15 built cropland elev grassland human_footprint shrubs trees
envs <- envs[[c('bio1', 'bio2', 'bio8', 'bio12', 'bio15', 'built', 'cropland', 'elev', 'grassland', 'human_footprint', 'shrubs', 'trees')]]
print(envs)

# conduct raster PCA
envs.pca <- raster.pca(env = envs, n = 5)
print(envs.pca)

# check eigenvalues...retain PCs with eigenvalue > 2
get_eigenvalue(envs.pca$pca.object)

# check PC loadings
envs.pca.var <- get_pca_var(envs.pca$pca.object)
envs.pca.contrib <- envs.pca.var$contrib[, c(1,2)]
colnames(envs.pca.contrib) = c('PC1', 'PC2')
print(envs.pca.contrib)

rev(sort(envs.pca.contrib[, 1]))  # PC1 == bio2 (19.9 %) & PC2 == tree cover (14.6%)
rev(sort(envs.pca.contrib[, 2]))  # PC2 == human footprint (26.9 %) & PC2 == elevation (14.6 %)


#####  part 3 ::: set up extents for analyses ----------
# load ecoregion polygons
east <- st_read('data/poly/ecoregion_sliced/eco_east.shp') %>% st_transform(crs = 4326)
gp <- st_read('data/poly/ecoregion_sliced/eco_great_plains.shp') %>% st_transform(crs = 4326)
west <- st_read('data/poly/ecoregion_sliced/eco_west.shp') %>% st_transform(crs = 4326)

# set "global" rasters == in this case this would be the entire North America
glob.envs <- envs.pca$rasters[[1:2]]
print(glob.envs)
plot(glob.envs)

# East
east.envs <- mask(glob.envs, east)
plot(east.envs)

# Great Plains
gp.envs <- mask(glob.envs, gp)
plot(gp.envs)

# West
west.envs <- mask(glob.envs, west)
plot(west.envs)


#####  part 4 ::: define data ----------

### East
# sp env
east.sp.ext <- extract(east.envs, e.occs)
east.sp <- cbind(rep('east_sp', nrow(east.sp.ext)), e.occs, east.sp.ext[, c(2,3)])

colnames(east.sp) = c('species', colnames(e.occs), colnames(east.sp.ext[, c(2,3)]))
head(east.sp)

# bg env
east.bg <- as.data.frame(east.envs, xy = T, na.rm = T)
east.bg <- cbind(rep('east_bg', nrow(east.bg)), east.bg)

colnames(east.bg) = colnames(east.sp)
head(east.bg)


### Great Plains
# sp env
gp.sp.ext <- extract(gp.envs, gp.occs)
gp.sp <- cbind(rep('gp_sp', nrow(gp.sp.ext)), gp.occs, gp.sp.ext[, c(2,3)])

colnames(gp.sp) = colnames(east.sp)
head(gp.sp)

# bg env
gp.bg <- as.data.frame(gp.envs, xy = T, na.rm = T)
gp.bg <- cbind(rep('gp_bg', nrow(gp.bg)), gp.bg)

colnames(gp.bg) = colnames(east.sp)
head(gp.bg)


### West
# sp env
west.sp.ext <- extract(west.envs, w.occs)
west.sp <- cbind(rep('west_sp', nrow(west.sp.ext)), w.occs, west.sp.ext[, c(2,3)])

colnames(west.sp) = colnames(east.sp)
head(west.sp)

# bg env
west.bg <- as.data.frame(west.envs, xy = T, na.rm = T)
west.bg <- cbind(rep('west_bg', nrow(west.bg)), west.bg)

colnames(west.bg) = colnames(east.sp)
head(west.bg)


### "global" env
total.bg.env <- as.data.frame(glob.envs, xy = T, na.rm = T)
total.bg.env <- cbind(rep('global_background', nrow(total.bg.env)), total.bg.env)

colnames(total.bg.env) = colnames(east.sp)
head(total.bg.env)


#####  part 5 ::: run ecospat test in ENMTools ----------

### sample random points for each ecoregion == dismo::randomPoints function does not accept SpatRaster class
east.rand <- dismo::randomPoints(mask = raster::raster(east.envs[[1]]), n = 10000) %>% as.data.frame()
gp.rand <- dismo::randomPoints(mask = raster::raster(gp.envs[[1]]), n = 10000) %>% as.data.frame()
w.rand <- dismo::randomPoints(mask = raster::raster(west.envs[[1]]), n = 10000) %>% as.data.frame()

colnames(east.rand) = c('long', 'lat')
colnames(gp.rand) = colnames(east.rand)
colnames(w.rand) = colnames(east.rand)

### define enmtools.species objects
# east
east.enmtools <- enmtools.species(species.name = 'religiosa_East',
                                  range = east.envs, 
                                  presence.points = vect(e.occs, geom = c('long', 'lat'), crs = 'EPSG:4326'), 
                                  background.points = vect(east.rand, geom = c('long', 'lat'), crs = 'EPSG:4326'))

# Great Plains
gp.enmtools <- enmtools.species(species.name = 'religiosa_GP',
                                range = gp.envs,
                                presence.points = vect(gp.occs, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                                background.points = vect(gp.rand, geom = c('long', 'lat'), crs = 'EPSG:4326'))

# West
w.enmtools <- enmtools.species(species.name = 'religiosa_West',
                               range = west.envs,
                               presence.points = vect(w.occs, geom = c('long', 'lat'), crs = 'EPSG:4326'),
                               background.points = vect(w.rand, geom = c('long', 'lat'), crs = 'EPSG:4326'))


### run niche ID test
# East vs. Great Plains
east_gp <- enmtools.ecospat.id(species.1 = east.enmtools, species.2 = gp.enmtools, env = glob.envs, nreps = 100, 
                               layers = names(glob.envs), R = 100, bg.source = 'points', verbose = T)

# East vs. West
east_west <- enmtools.ecospat.id(species.1 = east.enmtools, species.2 = west.enmtools, env = glob.envs, nreps = 100,
                                 layers = names(glob.envs), R = 100, bg.source = 'points', verbose = T)

# Great Plains vs. West 


### run bg test

