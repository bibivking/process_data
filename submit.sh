#!/bin/bash

#PBS -m ae
#PBS -P w35
#PBS -q normalbw
#PBS -l walltime=12:00:00
#PBS -l mem=128GB
#PBS -l ncpus=1
#PBS -j oe
#PBS -l wd
#PBS -l storage=gdata/w35

#source activate science
cd /g/data/w35/mm3972/scripts/process_data
ncl regrid_to_10km.ncl
