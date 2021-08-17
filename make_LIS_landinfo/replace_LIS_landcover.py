#!/usr/bin/env python

"""
Reproject and resample geodata
"""

__author__    = "MU Mengyuan"

import os
import sys
import glob
import pandas as pd
import numpy as np
import netCDF4 as nc
import datetime
import matplotlib.pyplot as plt
from pyresample.kd_tree import resample_nearest
from pyresample.geometry import AreaDefinition,SwathDefinition

def reprojection_nearest(var,lats,lons):

    '''
    Larmbert conformal projection
    see more information in https://proj.org/operations/projections/lcc.html?highlight=lambert%20conformal
    '''

    width  = 179
    height = 199

    area_id     = 'Lambert_conformal'
    description = 'Lambert_conformal over Australia'

    # make the projection
    proj_dict   = {'proj': 'lcc', 'lat_0': -26., 'lon_0': 135., 'lat_1' = -0.6, 'lat_2'= -38.0, 'a': 6371228.0, 'units': 'm'}
 
    # create WRF domain 
    area_def    = create_area_def(area_id, proj_dict, center=(0,0) ,shape= (width, height), resolution=25000.0 units="m", description=description)

    # create gridinfo domain
    swath_def   = SwathDefinition(lons=lons, lats=lats)
    result   = resample_nearest(swath_def, var, area_def, radius_of_influence=20000, fill_value=None)

    return result, area_def


def reprojection_bucket(var,lats,lons):

    '''
    Larmbert conformal projection
    bucket method
    see more information in https://pyresample.readthedocs.io/en/latest/api/pyresample.bucket.html?highlight=bucket
    '''

    width  = 179
    height = 199

    area_id     = 'Lambert_conformal'
    description = 'Lambert_conformal over Australia'

    # make the projection
    proj_dict   = {'proj': 'lcc', 'lat_0': -26., 'lon_0': 135., 'lat_1' = -0.6, 'lat_2'= -38.0, 'a': 6371228.0, 'units': 'm'}
 
    # create WRF domain 
    area_def    = create_area_def(area_id, proj_dict, center=(0,0) ,shape= (width, height), resolution=25000.0 units="m", description=description)

    # create gridinfo domain
    swath_def   = SwathDefinition(lons=lons, lats=lats)
    result   = resample_nearest(swath_def, var, area_def, radius_of_influence=20000, fill_value=None)

    return result, area_def    



def reprojection_bilinear(var,lats,lons):
    '''
    https://pyresample.readthedocs.io/en/latest/swath.html?highlight=resample_nearest
    '''
    from pyresample.bilinear import XArrayBilinearResampler

    target_def = geometry.AreaDefinition('areaD',
                                        'Europe (3km, HRV, VTC)',
                                        'areaD',
                                        {'a': '6378144.0', 'b': '6356759.0',
                                        'lat_0': '50.00', 'lat_ts': '50.00',
                                        'lon_0': '8.00', 'proj': 'stere'},
                                        800, 800,
                                        [-1370912.72, -909968.64,
                                        1029087.28, 1490031.36])
    data = DataArray(da.from_array(np.fromfunction(lambda y, x: y*x, (500, 100))), dims=('y', 'x'))
    lons = da.from_array(np.fromfunction(lambda y, x: 3 + x * 0.1, (500, 100)))
    lats = da.from_array(np.fromfunction(lambda y, x: 75 - y * 0.1, (500, 100)))
    source_def = geometry.SwathDefinition(lons=lons, lats=lats)
    resampler = XArrayBilinearResampler(source_def, target_def, 30e3)
    result = resampler.resample(data)
    return result, area_def    

def update_parameters(finput, foutput, varname_in, varname_out):

    # create file and write global attributes
    input     = nc.Dataset(finput, "r", format="NETCDF4")
    output    = nc.Dataset(foutput, "r+", format="NETCDF4")

    var_in    = input.variables[varname_in]
    lats      = input.variables['latitude']
    lons      = input.variables['longitude']    

    if pre_type == :
       var_out, area_def = reprojection_nearest(var,lats,lons)

       reprojection_nearest(var,lats,lons)

    output.variables[varname_out] = var_out

    # plotting for tests
    crs = area_def.to_cartopy_crs()

    fig, ax = plt.subplots(subplot_kw=dict(projection=crs))
    coastlines = ax.coastlines()  
    ax.set_global()
    img = plt.imshow(output.variables[varname_out], transform=crs, extent=crs.bounds, origin='upper')
    cbar = plt.colorbar()
    fig.savefig('check_reprojection.png')

    input.close()    
    output.close()

if __name__ == "__main__":

    input_varnames  = ['sand','silt','clay']
    output_varnames = ['SAND','SILT','CLAY']

    for i in np.arange(len(input_varnames)):

        finput     = "/g/data/w35/mm3972/model/cable/src/CABLE-AUX/offline/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix.nc"
        foutput    = "/g/data/w35/mm3972/scripts/process_data/replace_LIS_landcover/lis_input.d01.nc"

        update_parameters(finput, foutput, input_varnames[i], output_varnames[i])