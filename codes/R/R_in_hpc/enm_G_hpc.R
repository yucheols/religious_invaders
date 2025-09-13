#####  Global scale ENM for M. religiosa == model at 10km scale == run this script on Mendel cluster

# clean the working environment
rm(list = ls(all.names = T))
gc()

# set seed
set.seed(1234)

# load packages
library(terra)
library(sf)
library(SDMtune)
library(ENMeval)
library(ntbox)
library(dplyr)