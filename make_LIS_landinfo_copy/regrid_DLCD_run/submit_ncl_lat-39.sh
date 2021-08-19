#!/bin/bash

#PBS -m ae
#PBS -P w35
#PBS -q normalbw
#PBS -l walltime=3:00:00
#PBS -l mem=128GB
#PBS -l ncpus=1
#PBS -j oe
#PBS -l wd
#PBS -l storage=gdata/w35

cd /g/data/w35/mm3972/scripts/process_data/make_LIS_landinfo/regrid_DLCD_run
ncl regrid_DLCD_landcover_lat-39.ncl >regrid_DLCD_landcover_lat-39.out
