# religious_invaders

## Overall workflow

## Computing resources
Mendel HPC at AMNH
<img width="1416" height="581" alt="workflow" src="https://github.com/user-attachments/assets/49a2bcac-e98f-499a-bd3c-f7b1eaf1de06" />

## Software and package dependencies for local runs
- R (v 4.4.2) for local runs
- blockCV
- ClimDatDownloadR
- dismo
- dplyr
- ENMTools
- ENMwrap
- factoextra
- foster
- geodata
- ggplot2
- ggpubr
- ntbox
- rnaturalearth
- SDMtune
- sf
- terra
- tidyterra

## Software and package dependencies for HPC runs
R (v 4.3.3)

## Study background


## Ecological niche models (ENMs)
- Script "enm_G": Global-scale ENM using all available occurrence points
- Script "enm_N_alldata": The "native range" ENMs fitted with all available native range occurrence points and spatial extents.
- Script "enm_N_constrained": The "native range" ENMs fitted with a subset of the native range occurrence points and environmental data, informed by genetic data.
- Script "enm_I_alldata": The "invaded range" ENMs fitted with all available invaded range occurrence points and spatial extents.
- Script "enm_I_constrained": Two "invaded range" ENMs, one fitted on the "East" data and another fitted on the "West" data.

## Niche overlap/divergence analysis
