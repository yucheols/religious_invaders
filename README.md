# Ensemble ecological niche modeling of the European mantis (*Mantis religiosa*)

## Overall workflow
<img width="1416" height="581" alt="workflow" src="https://github.com/user-attachments/assets/49a2bcac-e98f-499a-bd3c-f7b1eaf1de06" />

## Computing resources
Mendel HPC at AMNH

## Software and package dependencies (local runs)
- R (v 4.4.2)
- biomod2
- ClimDatDownloadR
- dplyr
- ENMTools
- ENMwrap
- factoextra
- geodata
- ggplot2
- ntbox
- rnaturalearth
- SDMtune
- sf
- terra
- tidyterra

## Software and package dependencies (HPC runs)
- R (v 4.3.3)
- biomod2
- dplyr
- future
- sf
- SDMtune
- terra

## Study background


## Ecological niche models (ENMs)
- Script "enm_G": Global-scale ENM using all available occurrence points
- Script "enm_N_alldata": The "native range" ENMs fitted with all available native range occurrence points and spatial extents.
- Script "enm_N_constrained": The "native range" ENMs fitted with a subset of the native range occurrence points and environmental data, informed by genetic data.
- Script "enm_I_alldata": The "invaded range" ENMs fitted with all available invaded range occurrence points and spatial extents.
- Script "enm_I_constrained": Two "invaded range" ENMs, one fitted on the "East" data and another fitted on the "West" data.

## Niche overlap/divergence/shift analysis
