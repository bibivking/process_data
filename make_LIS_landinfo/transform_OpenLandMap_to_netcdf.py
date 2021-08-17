#!/usr/bin/env python

"""
Raw soil data is from the Soil and Landscape Grid of Australia

http://www.clw.csiro.au/aclep/soilandlandscapegrid/GetData-DAP.html

We are using the Soil and Landscape Grid Australia-Wide 3D Soil Property Maps
(3" resolution) - Release 1

We are degrading the 90m to 5km and moving it onto the matching AWAP grid using
a nearest neighbour interpolation.

After we are done I'm removing the raw (5 gig file to save space). Either
re-download it or look on your black backup drive "raw_AUS_Soils"

By the way to just degrade the data gdalwarp -tr 0.05 -0.05 would do it.
"""

import os
import sys
import glob
import gdal
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors
import netCDF4 as nc
import datetime
import pandas as pd

def main( fn , fld , level , unit , long_name , description):

    ds = gdal.Open(fn, gdal.GA_ReadOnly)
    rb = ds.GetRasterBand(1)
    var = rb.ReadAsArray()

    transf = ds.GetGeoTransform()
    cols = ds.RasterXSize # 49200
    rows = ds.RasterYSize # 40800

    #bands = ds.RasterCount
    #bandtype = gdal.GetDataTypeName(var.DataType) #Int16
    #driver = ds.GetDriver().LongName #'GeoTIFF'
    print(transf)
    lon = np.arange(transf[0],transf[0]+cols*transf[1],transf[1])
    lat = np.arange(transf[3]+(rows-1)*transf[5],transf[3]-transf[5],-transf[5])

    print(lon)
    print(lat)
    #plot_spitial(var,lon,lat)
    convert_to_netcdf(fld , var , lat, lon , level , unit , long_name , description)

    ds = None


def interpolate_to_1km(fld , var , lat, lon , level , unit , long_name , description):

    return 

def convert_to_netcdf(fld , var , lat, lon , level , unit , long_name , description):

    '''
    lat and lon index over Australia
    lat is from -61.9987 to 87.37
    lon is from -180. to 179.99785907
    '''
    
    '''
    AWAP domain
    lat_s = 8600    # No.8639.39 represents -44
    lat_e = 25000   # No.24959.39 represents -10
    lon_s = 140000  # No.140160 represents 112
    lon_e = 161000  # No. 160320 represent 154
    '''

    # create file and write global attributes
    out_fname = "%s_%scm_OpenLandMap.nc" %(fld, level)
    f = nc.Dataset(out_fname, 'w', format='NETCDF4')
    f.description = 'OpenLandMap_soil Maps over Australia, created by MU Mengyuan'
    f.history = "Created by: %s" % (os.path.basename(__file__))
    f.creation_date = "%s" % (datetime.datetime.now())

    # set dimensions
    f.createDimension('lat', (lat_e-lat_s))
    f.createDimension('lon', (lon_e-lon_s))
    f.Conventions = "CF-1.0"

    # create variables
    latitude = f.createVariable('lat', 'f4', ('lat',))
    latitude.long_name = "latitude"

    longitude = f.createVariable('lon', 'f4', ('lon',))
    longitude.long_name = "longitude"

    latitude[:] = lat[lat_s:lat_e]
    longitude[:] = lon[lon_s:lon_e]

    Var = f.createVariable('%s' % fld, 'f4', ('lat','lon'))
    Var.units = unit
    Var.missing_value = 255.
    Var.long_name = long_name
    Var.description = description
    var_tmp = var[::-1,:]
    Var[:,:] = var_tmp[lat_s:lat_e,lon_s:lon_e]
    f.close()


if __name__ == "__main__":

    pyth    = '/g/data/w35/mm3972/data/OpenLandMap_soil/'
    folder  = ['Soil_bulkdens','Sand','Clay','organic_C']
    levels  = ['0','10','30','60','100','200']

    for level in levels:
        print(level)
        for fld in folder:
            if fld == 'Soil_bulkdens':
                unit = "10 kg / m3"
                long_name = "Bulk Density"
                file_name = "%s/sol_bulkdens.fineearth_usda.4a1h_m_250m_b%s..%scm_1950..2017_v0.2.tif" %(fld, level, level)
            elif fld == 'Sand':
                unit = "%"
                long_name = "sand"
                file_name = "%s/sol_sand.wfraction_usda.3a1a1a_m_250m_b%s..%scm_1950..2017_v0.2.tif" %(fld, level, level)
            elif fld == 'Clay':
                unit = "%"
                long_name = "clay"
                file_name = "%s/sol_clay.wfraction_usda.3a1a1a_m_250m_b%s..%scm_1950..2017_v0.2.tif" %(fld, level, level)
            elif fld == 'organic_C':
                unit = "5 g / kg"
                long_name = "Organic Carbon"
                file_name = "%s/sol_organic.carbon_usda.6a1c_m_250m_b%s..%scm_1950..2017_v0.2.tif" %(fld, level, level)

            fn = os.path.join(pyth, "%s" % (file_name))
            main(fn,fld,level,unit,long_name,description)
