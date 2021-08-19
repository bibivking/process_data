#!/bin/bash

#PBS -m ae
#PBS -P w35
#PBS -q express
#PBS -l walltime=2:00:00
#PBS -l mem=128GB
#PBS -l ncpus=1
#PBS -j oe
#PBS -l wd
#PBS -l storage=gdata/w35

cd /g/data/w35/mm3972/scripts/process_data/make_LIS_landinfo
ncl regrid_DLCD_landcover.ncl >regrid_DLCD_landcover.out
#ncl convert_landcover_format.ncl >convert_landcover_format.out
