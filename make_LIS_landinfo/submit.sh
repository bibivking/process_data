#!/bin/bash

#PBS -m ae
#PBS -P w35
#PBS -q normalbw
#PBS -l walltime=2:00:00
#PBS -l mem=256GB
#PBS -l ncpus=1
#PBS -j oe
#PBS -l wd
#PBS -l storage=gdata/w35

#source activate science
cd /g/data/w35/mm3972/scripts/process_data/make_LIS_landinfo
ncl add_Copernicus_lai.ncl
