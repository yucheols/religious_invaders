#!/bin/sh
#SBATCH --job-name=test_mx
#SBATCH --nodes=1
#SBATCH --cpus-per-task=30
#SBATCH --time=144:00:00
#SBATCH --mem=120G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=yshin@amnh.org
#SBATCH --output=/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/small/mx_test/log/small_religiosa_na_5km_%j-%x.log
#SBATCH --error=/home/yshin/mendel-nas1/religiosa_nsdm_HPC/models_run/small/mx_test/err/small_religiosa_na_5km_%j-%x.err

# load conda in batch mode
source /home/yshin/mendel-nas1/miniconda3/etc/profile.d/conda.sh

# activate conda environment that contains R and all necessary packages
conda activate nsdm_hpc
cd /home/yshin/mendel-nas1/religiosa_nsdm_HPC  # this will be the R working directory on the cluster

# run the R script
Rscript /home/yshin/mendel-nas1/religiosa_nsdm_HPC/scripts/R/small/test_mx.R