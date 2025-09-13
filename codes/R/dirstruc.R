#####  create directory structure for various files

# clean the working environment
rm(list = ls(all.names = T))
gc()

# directory for codes
if(!dir.exists('codes')){
  dir.create('codes')
}

# directory for data
if(!dir.exists('data')){
  dir.create('data')
}

# sub-directories for data
if(!dir.exists('data/bg')){
  dir.create('data/bg')
}

if(!dir.exists('data/occs')){
  dir.create('data/occs')
}

if(!dir.exists('data/poly')){
  dir.create('data/poly')
}

if(!dir.exists('data/envs')){
  dir.create('data/envs')
}

if(!dir.exists('data/envs/global')){
  dir.create('data/envs/global')
}

# directory for model outputs
if(!dir.exists('outputs')){
  dir.create('outputs')
}

if(!dir.exists('outputs/models')){
  dir.create('outputs/models')
}

if(!dir.exists('outputs/preds')){
  dir.create('outputs/preds')
}

if(!dir.exists('outputs/other')){
  dir.create('outputs/other')
}

# directory for plots
if(!dir.exists('plots')){
  dir.create('plots')
}
