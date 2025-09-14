#!/bin/sh
#SBATCH --job-name=religiosa_glob_10km
#SBATCH --nodes=1
#SBATCH --cpus-per-task=30
#SBATCH --time=144:00:00
#SBATCH --mem=120G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=yshin@amnh.org
#SBATCH --output=/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/global_10km/output/log/religiosa_glob_10km_%j-%x.log
<<<<<<< HEAD
=======
#SBATCH --output=/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/global_10km/output/err/religiosa_glob_10km_%j-%x.err

# load conda in batch mode
source /home/yshin/mendel-nas1/miniconda3/etc/profile.d/conda.sh
>>>>>>> 645663b178dfe08d2d874ca6b277563c9ffca762

# activate conda environment that contains R and all necessary packages
conda activate nsdm_hpc
cd /home/yshin/mendel-nas1/religiosa_nsdm_HPC  # this will be the R working directory on the cluster 

# run the R script
<<<<<<< HEAD
Rscript /home/yshin/mendel-nas1/religiosa_nsdm_HPC/scripts/R/enm_G_hpc.R
=======
Rscript /home/yshin/mendel-nas1/religiosa_nsdm_HPC/scripts/R/enm_G_hpc.R
>>>>>>> 645663b178dfe08d2d874ca6b277563c9ffca762
