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
import netCDF4 as nc
import pandas as pd
import datetime
import matplotlib.pyplot as plt
import matplotlib.colors
from scipy.interpolate import griddata, interp2d


def main(fn, fld, level, unit, long_name, scale_opt):

    ds = gdal.Open(fn, gdal.GA_ReadOnly)
    rb = ds.GetRasterBand(1)
    var = rb.ReadAsArray()

    transf = ds.GetGeoTransform()
    print(transf)
    cols = ds.RasterXSize # 49200
    rows = ds.RasterYSize # 40800
    print(cols)
    print(rows)

    #bands = ds.RasterCount
    #bandtype = gdal.GetDataTypeName(var.DataType) #Int16
    #driver = ds.GetDriver().LongName #'GeoTIFF'
    print(transf)
    lon = np.arange(transf[0],transf[0]+cols*transf[1],transf[1])
    lat = np.arange(transf[3]+(rows-1)*transf[5],transf[3]-transf[5],-transf[5])

    print(lon)
    print(lat)
    print(len(var))
    #plot_spitial(var,lon,lat)
    convert_to_netcdf(fld, var, lat, lon, level, unit, long_name, scale_opt)

    ds = None

def convert_to_netcdf(fld, var, lat, lon, level, unit, long_name, scale_opt):

    '''
    lat and lon index over Australia
    lat is from -61.9987 to 87.37
    lon is from -180. to 179.99785907
    '''

    # create file and write global attributes
    out_fname = "./nc_file/%s_%scm_%s_OpenLandMap.nc" %(fld, level, scale_opt)
    f = nc.Dataset(out_fname, 'w', format='NETCDF4')
    
    if scale_opt == "AU":
        ### AWAP domain ###
        lat_idx_s = 8600    # No.8639.39 represents -44
        lat_idx_e = 25000   # No.24959.39 represents -10
        lon_idx_s = 140000  # No.140160 represents 112
        lon_idx_e = 161000  # No. 160320 represent 154
        nLat  = lat_idx_e - lat_idx_s 
        nLon  = lon_idx_e - lon_idx_s

    if scale_opt == "Global":
        ### Global domain ###
        lat_s = -62.995 
        lat_e = 87.375
        lon_s = -179.995  
        lon_e = 180.005         
        Lat = np.arange(lat_s,lat_e,0.01) 
        Lon = np.arange(lon_s,lon_e,0.01) 
        nLat  = len(Lat)
        nLon  = len(Lon)

    if scale_opt == "CORDEX":
        ### CORDEX domain ###
        lat_s = -54.995    
        lat_e = 15.005
        lon_s = 85.005  
        lon_e = 208.005  
        Lat = np.arange(lat_s,lat_e,0.01) 
        Lon = np.arange(lon_s,lon_e,0.01) 
        nLat  = len(Lat)
        nLon  = len(Lon)        

    print("scale_opt is %s" % scale_opt)
    print("Lat is %f" % nLat)
    print("Lon is %f" % nLon)

    ### Create nc file ###
    f.history = "Created by: %s" % (os.path.basename(__file__))
    f.creation_date = "%s" % (datetime.datetime.now())
    f.description = scale_opt+' OpenLandMap_soil Maps, created by MU Mengyuan'
    # set dimensions
    f.createDimension('lat', nLat)
    f.createDimension('lon', nLon)
    f.Conventions = "CF-1.0"

    # create variables
    latitude = f.createVariable('lat', 'f4', ('lat',))
    latitude.long_name = "latitude"

    longitude = f.createVariable('lon', 'f4', ('lon',))
    longitude.long_name = "longitude"

    Var = f.createVariable('%s' % fld, 'f4', ('lat','lon'))
    Var.units = unit
    Var.missing_value = 255.
    Var.long_name = long_name
    # Var.description = description
    var_tmp = var[::-1,:]

    if scale_opt == "AU":
        latitude[:]  = lat[lat_idx_s:lat_idx_e]
        longitude[:] = lon[lon_idx_s:lon_idx_e]
        print(latitude)
        print(longitude)
        print(var_tmp.shape)
        Var[:,:]     = var_tmp[lat_idx_s:lat_idx_e,lon_idx_s:lon_idx_e]

    if scale_opt == "Global":
        latitude[:]  = Lat
        longitude[:] = Lon
        print(latitude)
        print(longitude)
        print(var_tmp.shape)
        Var[:,:]     = interpolate_to_1km_interp2d(var_tmp, lat, lon, Lat, Lon)
        print(Var.shape)

    if scale_opt == "CORDEX":
        latitude[:]  = Lat
        longitude[:] = Lon
        mask_lat = (lat >= lat_s) & (lat < lat_e)
        mask_lon = (lon >= lon_s) & (lon < lon_e)
        value   = var_tmp[mask_lat][:,mask_lon]     
        var_max = np.max(value[value !=255])
        var_min = np.min(value[value !=255])
        Var.max_rawdata = var_max
        Var.min_rawdata = var_min
        Var_tmp = interpolate_to_1km_interp2d( value, lat[mask_lat], lon[mask_lon], Lat, Lon)
        Var[:,:]= np.where((Var_tmp <= var_max) & (Var_tmp >= var_min), Var_tmp, 255.)

    f.close()

def interpolate_to_1km_interp2d(var, lat, lon, Lat, Lon):

    # grid_x, grid_y = np.meshgrid(lon,lat)
    print('lat')
    print(lat.shape)
    print('lon')
    print(lon.shape)
    print('var')
    print(var.shape)

    f = interp2d(lon, lat, var, kind='linear',fill_value=255)
    var_out = f(Lon,Lat)
    print('var_out')
    print(var_out.shape)
    plt.imshow(var_out)

    return var_out
    

def interpolate_to_1km_griddata(var, lat, lon, Lat, Lon):

    grid_x, grid_y = np.meshgrid(lon,lat)
    x              = np.reshape(grid_x,-1)
    y              = np.reshape(grid_y,-1)
    value          = np.reshape(var,-1)
    grid_X, grid_Y = np.meshgrid(Lon,Lat)

    print('grid_x')
    print(grid_x.shape)
    print('grid_y')
    print(grid_y.shape)

    print('x')
    print(x.shape)
    print('y')
    print(y.shape)
    print('value')
    print(value.shape)
    # print('if any value != 255, %s' % (np.any(value != 255)))
    print('grid_X')
    print(grid_X.shape)
    print('grid_Y')
    print(grid_Y.shape)
    
    var_out        = griddata((x, y), value, (grid_X, grid_Y), method="linear")
    print(var_out.shape)
    return var_out

if __name__ == "__main__":

    pyth    = '/g/data/w35/mm3972/data/OpenLandMap_soil/'
    folder  = ['Soil_bulkdens','Sand','Clay','organic_C']
    levels  = ['100','200'] #['0','10','30','60','100','200']
    scale_opt = "CORDEX" #"Global" # "AU"

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
            main(fn, fld, level, unit, long_name, scale_opt)
