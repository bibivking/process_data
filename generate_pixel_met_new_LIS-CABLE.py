#!/usr/bin/env python

"""
Use LIS-CABLE half-hour met output to make met file for offline CABLE

Source: generate_CABLE_netcdf_met_imp.py

Includes:

That's all folks.
"""

__author__    = "MU Mengyuan"
__email__     = "mu.mengyuan815@gmail.com"

import os
import sys
import glob
import pandas as pd
import numpy as np
import netCDF4 as nc
import datetime
from scipy.interpolate import interp1d
from scipy.interpolate import griddata

def main(input_fname, out_fname, loc_lat, loc_lon, dels):

    print(input_fname[0])
    print(out_fname)
    DEG_2_KELVIN = 273.15
    SW_2_PAR     = 2.3
    PAR_2_SW     = 1.0 / SW_2_PAR
    HLFHR_2_SEC  = 1.0 / 1800.

    DOY   = 1
    nsoil = 6
    ndim  = 1
    nsoil = nsoil
    n_timesteps = int(DOY*(24*60*60/dels))
    print(n_timesteps)
    times = []
    secs  = dels
    for i in range(n_timesteps):
        times.append(secs)
        secs += dels

    # create file and write global attributes
    f = nc.Dataset(out_fname, 'w', format='NETCDF4')
    f.description   = 'ERAI met data, created by MU Mengyuan'
    f.source        = input_fname
    f.history       = "Created by: %s" % (os.path.basename(__file__))
    f.creation_date = "%s" % (datetime.datetime.now())

    # set dimensions
    f.createDimension('time', None)
    f.createDimension('z', ndim)
    f.createDimension('y', ndim)
    f.createDimension('x', ndim)
    f.createDimension('soil_depth', nsoil)
    f.Conventions  = "CF-1.0"

    # create variables
    time           = f.createVariable('time', 'f8', ('time',))
    time.units     = "seconds since 2006-01-01 00:00:00"
    time.long_name = "time"
    time.calendar  = "standard"

    z = f.createVariable('z', 'f8', ('z',))
    z.long_name = "z"
    z.long_name = "z dimension"

    y = f.createVariable('y', 'f8', ('y',))
    y.long_name = "y"
    y.long_name = "y dimension"

    x = f.createVariable('x', 'f8', ('x',))
    x.long_name = "x"
    x.long_name = "x dimension"

    soil_depth = f.createVariable('soil_depth', 'f4', ('soil_depth',))
    soil_depth.long_name = "soil_depth"

    latitude = f.createVariable('latitude', 'f4', ('y', 'x',))
    latitude.units = "degrees_north"
    latitude.missing_value = -9999.
    latitude.long_name = "Latitude"

    longitude = f.createVariable('longitude', 'f4', ('y', 'x',))
    longitude.units = "degrees_east"
    longitude.missing_value = -9999.
    longitude.long_name = "Longitude"

    SWdown = f.createVariable('SWdown', 'f4', ('time', 'y', 'x',))
    SWdown.units = "W/m^2"
    SWdown.missing_value = -9999.
    SWdown.long_name = "Surface incident shortwave radiation"
    SWdown.CF_name = "surface_downwelling_shortwave_flux_in_air"

    Tair = f.createVariable('Tair', 'f4', ('time', 'z', 'y', 'x',))
    Tair.units = "K"
    Tair.missing_value = -9999.
    Tair.long_name = "Near surface air temperature"
    Tair.CF_name = "surface_temperature"

    Rainf = f.createVariable('Rainf', 'f4', ('time', 'y', 'x',))
    Rainf.units = "mm/s"
    Rainf.missing_value = -9999.
    Rainf.long_name = "Rainfall rate"
    Rainf.CF_name = "precipitation_flux"

    Qair = f.createVariable('Qair', 'f4', ('time', 'z', 'y', 'x',))
    Qair.units = "kg/kg"
    Qair.missing_value = -9999.
    Qair.long_name = "Near surface specific humidity"
    Qair.CF_name = "surface_specific_humidity"

    Wind = f.createVariable('Wind', 'f4', ('time', 'z', 'y', 'x',))
    Wind.units = "m/s"
    Wind.missing_value = -9999.
    Wind.long_name = "Scalar windspeed" ;
    Wind.CF_name = "wind_speed"

    PSurf = f.createVariable('PSurf', 'f4', ('time', 'y', 'x',))
    PSurf.units = "Pa"
    PSurf.missing_value = -9999.
    PSurf.long_name = "Surface air pressure"
    PSurf.CF_name = "surface_air_pressure"

    LWdown = f.createVariable('LWdown', 'f4', ('time', 'y', 'x',))
    LWdown.units = "W/m^2"
    LWdown.missing_value = -9999.
    LWdown.long_name = "Surface incident longwave radiation"
    LWdown.CF_name = "surface_downwelling_longwave_flux_in_air"

    CO2 = f.createVariable('CO2air', 'f4', ('time', 'z', 'y', 'x',))
    CO2.units = "ppm"
    CO2.missing_value = -9999.
    CO2.long_name = ""
    CO2.CF_name = ""

    LAI = f.createVariable('LAI', 'f4', ('time', 'y', 'x'))
    LAI.setncatts({'long_name': u"Leaf Area Index",})

    elevation = f.createVariable('elevation', 'f4', ('y', 'x',))
    elevation.units = "m" 
    elevation.missing_value = -9999.
    elevation.long_name = "Site elevation above sea level" 

    iveg = f.createVariable('iveg', 'f4', ('y', 'x',))
    iveg.long_name = "vegetation type"
    iveg.units = "-"
    iveg.missing_value = -9999.0

    sand = f.createVariable('sand', 'f4', ('y', 'x',))
    sand.units = "-"
    sand.missing_value = -1.0

    clay = f.createVariable('clay', 'f4', ('y', 'x',))
    clay.units = "-"
    clay.missing_value = -1.0

    silt = f.createVariable('silt', 'f4', ('y', 'x',))
    silt.units = "-"
    silt.missing_value = -1.0

    rhosoil = f.createVariable('rhosoil', 'f4', ('y', 'x',))
    rhosoil.units = "kg m-3"
    rhosoil.long_name = "soil density"
    rhosoil.missing_value = -9999.0

    bch  = f.createVariable('bch', 'f4', ('y', 'x',))
    bch.units = "-"
    bch.long_name = "C and H B"
    bch.missing_value = -9999.0

    hyds = f.createVariable('hyds', 'f4', ('y', 'x',))
    hyds.units = "m s-1"
    hyds.long_name = "hydraulic conductivity at saturation"
    hyds.missing_value = -9999.0

    sucs = f.createVariable('sucs', 'f4', ('y', 'x',))
    sucs.units = "m"
    sucs.long_name = "matric potential at saturation"
    sucs.missing_value = -9999.0

    ssat = f.createVariable('ssat', 'f4', ('y', 'x',))
    ssat.units = "m3 m-3"
    ssat.long_name = "volumetric water content at saturation"
    ssat.missing_value = -9999.0

    swilt= f.createVariable('swilt', 'f4', ('y', 'x',))
    swilt.units = "m3 m-3"
    swilt.long_name = "wilting point"
    swilt.missing_value = -9999.0

    sfc  = f.createVariable('sfc', 'f4', ('y', 'x',))
    sfc.units = "m3 m-3"
    sfc.long_name = "field capcacity"
    sfc.missing_value = -9999.0

    css  = f.createVariable('css', 'f4', ('y', 'x',))
    css.units = "kJ kg-1 K-1"
    css.long_name = "soil specific heat capacity"
    css.missing_value = -9999.0

    cnsd = f.createVariable('cnsd', 'f4', ('y', 'x',))
    cnsd.units = "W m-1 K-1"
    cnsd.long_name = "thermal conductivity of dry soil"
    cnsd.missing_value = -9999.0

    # 3-Dimension variables
    sand_vec = f.createVariable('sand_vec', 'f4', ('soil_depth', 'y', 'x',))
    sand_vec.units = "-"
    sand_vec.missing_value = -1.0

    clay_vec = f.createVariable('clay_vec', 'f4', ('soil_depth', 'y', 'x',))
    clay_vec.units = "-"
    clay_vec.missing_value = -1.0

    silt_vec = f.createVariable('silt_vec', 'f4', ('soil_depth', 'y', 'x',))
    silt_vec.units = "-"
    silt_vec.missing_value = -1.0

    org_vec  = f.createVariable('org_vec', 'f4', ('soil_depth', 'y', 'x',))
    org_vec.units = "-"
    org_vec.missing_value = -1.0

    rhosoil_vec = f.createVariable('rhosoil_vec', 'f4', ('soil_depth', 'y', 'x',))
    rhosoil_vec.units = "kg m-3"
    rhosoil_vec.long_name = "soil density"
    rhosoil_vec.missing_value = -9999.0

    bch_vec  = f.createVariable('bch_vec', 'f4', ('soil_depth', 'y', 'x',))
    bch_vec.units = "-"
    bch_vec.long_name = "C and H B"
    bch_vec.missing_value = -9999.0

    hyds_vec = f.createVariable('hyds_vec', 'f4', ('soil_depth', 'y', 'x',))
    hyds_vec.units = "mm s-1"
    hyds_vec.long_name = "hydraulic conductivity at saturation"
    hyds_vec.missing_value = -9999.0

    sucs_vec = f.createVariable('sucs_vec', 'f4', ('soil_depth', 'y', 'x',))
    sucs_vec.units = "m"
    sucs_vec.long_name = "matric potential at saturation"
    sucs_vec.missing_value = -9999.0

    ssat_vec = f.createVariable('ssat_vec', 'f4', ('soil_depth', 'y', 'x',))
    ssat_vec.units = "m3 m-3"
    ssat_vec.long_name = "volumetric water content at saturation"
    ssat_vec.missing_value = -9999.0

    swilt_vec= f.createVariable('swilt_vec', 'f4', ('soil_depth', 'y', 'x',))
    swilt_vec.units = "m3 m-3"
    swilt_vec.long_name = "wilting point"
    swilt_vec.missing_value = -9999.0

    sfc_vec  = f.createVariable('sfc_vec', 'f4', ('soil_depth', 'y', 'x',))
    sfc_vec.units = "m3 m-3"
    sfc_vec.long_name = "field capcacity"
    sfc_vec.missing_value = -9999.0

    css_vec  = f.createVariable('css_vec', 'f4', ('soil_depth', 'y', 'x',))
    css_vec.units = "kJ kg-1 K-1"
    css_vec.long_name = "soil specific heat capacity"
    css_vec.missing_value = -9999.0

    cnsd_vec = f.createVariable('cnsd_vec', 'f4', ('soil_depth', 'y', 'x',))
    cnsd_vec.units = "W m-1 K-1"
    cnsd_vec.long_name = "thermal conductivity of dry soil"
    cnsd_vec.missing_value = -9999.0

    watr = f.createVariable('watr', 'f4', ('soil_depth', 'y', 'x',))
    watr.units = "m3 m-3"
    watr.long_name = "residual water content of the soil"
    watr.missing_value = -9999.0

    # write data to file
    x[:] = ndim
    y[:] = ndim
    z[:] = ndim

    soil_depth[:] = np.arange(0,nsoil,1)
    time[:] = times

    lat,lon,rain,tair,qair,psurf,swdown,lwdown,wind,lai = \
                                    get_met_input(input_fname,loc_lat,loc_lon,dels)

    print(lat)
    print(lon)

    latitude[0]  = lat
    longitude[0] = lon
    print(latitude[0])
    print(longitude[0])
    SWdown[:,0,0] = swdown
    LWdown[:,0,0] = lwdown
    PSurf[:,0,0]  = psurf
    Rainf[:,0,0]  = rain
    Tair[:,0,0,0] = tair
    Qair[:,0,0,0] = qair
    Wind[:,0,0,0] = wind
    CO2[:,0,0]    = 380.8 # 2006
    LAI[:,0,0]    = lai


    para_cable = nc.Dataset(input_fname[0], 'r')
    elevation[0,0] = para_cable.variables['Elevation_inst'][loc_lat,loc_lon]
    iveg[0,0] = 2 # veg type 7 in LIS is 5 in CABLE
                # para_cable.variables['Landcover_inst'][0,loc_lat,loc_lon]
    sand[0,0] = para_cable.variables['SandFrac_inst'][loc_lat,loc_lon]
    clay[0,0] = para_cable.variables['ClayFrac_inst'][loc_lat,loc_lon]
    silt[0,0] = para_cable.variables['SiltFrac_inst'][loc_lat,loc_lon]
    rhosoil[0,0] = 1417.000
    bch[0,0]  = para_cable.variables['Bch_inst'][loc_lat,loc_lon]
    hyds[0,0] = para_cable.variables['Hyds_inst'][loc_lat,loc_lon]
    sucs[0,0] = para_cable.variables['Sucs_inst'][loc_lat,loc_lon]
    ssat[0,0] = para_cable.variables['SoilSat_inst'][loc_lat,loc_lon]
    swilt[0,0]= para_cable.variables['SoilWiltPt_inst'][loc_lat,loc_lon]
    sfc[0,0]  = para_cable.variables['SoilFieldCap_inst'][loc_lat,loc_lon]
    css[0,0]  = 799.6967
    cnsd[0,0] = 0.267706423997879
    # 3-Dimension variables
    sand_vec[:,0,0]    = np.repeat(sand[0,0], 6)
    clay_vec[:,0,0]    = np.repeat(clay[0,0], 6)
    silt_vec[:,0,0]    = np.repeat(silt[0,0], 6)
    org_vec[:,0,0]     = [0,0,0,0,0,0]
    rhosoil_vec[:,0,0] = np.repeat(rhosoil[0,0], 6)
    bch_vec[:,0,0]     = np.repeat(bch[0,0], 6)
    hyds_vec[:,0,0]    = np.repeat(hyds[0,0]*1000, 6)
    sucs_vec[:,0,0]    = np.repeat(sucs[0,0], 6)
    ssat_vec[:,0,0]    = np.repeat(ssat[0,0], 6)
    swilt_vec[:,0,0]   = np.repeat(swilt[0,0], 6)
    sfc_vec[:,0,0]     = np.repeat(sfc[0,0], 6)
    css_vec[:,0,0]     = np.repeat(css[0,0], 6)
    cnsd_vec[:,0,0]    = np.repeat(cnsd[0,0], 6)
    watr[:,0,0]        = [0.05, 0.05, 0.05, 0.05, 0.05, 0.05]

    f.close()

def get_met_input(input_fname,loc_lat,loc_lon,dels):

    """
    read met fields from LIS-CABLE output
    """

    print("carry on read_cable_var")
    rain     = []
    tair     = []
    qair     = []
    psurf    = []
    swdown   = []
    lwdown   = []
    wind     = []
    lai      = []
    for time in np.arange(0,47,1):
        print(time)
        cable = nc.Dataset(input_fname[time], 'r')

        lat      = cable.variables['lat'][loc_lat,loc_lon]
        lon      = cable.variables['lon'][loc_lat,loc_lon]
        landmask = cable.variables['Landmask_inst'][loc_lat,loc_lon]
        landcover= cable.variables['Landcover_inst'][loc_lat,loc_lon]

        tmp = cable.variables['Rainf_f_inst'][loc_lat,loc_lon].filled(-9999.)
        rain.append(tmp)
        tmp = cable.variables['Tair_f_inst'][loc_lat,loc_lon].filled(-9999.)
        tair.append(tmp)
        tmp = cable.variables['Qair_f_inst'][loc_lat,loc_lon].filled(-9999.)
        qair.append(tmp)
        tmp = cable.variables['Psurf_f_inst'][loc_lat,loc_lon].filled(-9999.)
        psurf.append(tmp)
        tmp = cable.variables['SWdown_f_inst'][loc_lat,loc_lon].filled(-9999.)
        swdown.append(tmp)
        tmp = cable.variables['LWdown_f_inst'][loc_lat,loc_lon].filled(-9999.)
        lwdown.append(tmp)
        tmp = cable.variables['Wind_f_inst'][loc_lat,loc_lon].filled(-9999.)
        wind.append(tmp)
        tmp = cable.variables['LAI_inst'][loc_lat,loc_lon].filled(-9999.)
        lai.append(tmp)
        cable.close()
    print(rain[:])

    if dels != 1800:
        tts_05hr = len(rain)
        nts      = int(dels/1800)
        tts      = int(tts_05hr/nts)
        print("tts_05hr %s" % tts_05hr)
        print("nts %s" % nts)
        print("tts %s" % tts)
        rain_tmp   = np.zeros(tts)
        tair_tmp   = np.zeros(tts)
        qair_tmp   = np.zeros(tts)
        psurf_tmp  = np.zeros(tts)
        swdown_tmp = np.zeros(tts)
        lwdown_tmp = np.zeros(tts)
        wind_tmp   = np.zeros(tts)
        lai_tmp    = np.zeros(tts)
        for j in np.arange(0,tts):
            rain_tmp[j]    = np.average(rain[j*nts:(j+1)*nts])
            tair_tmp[j]    = np.average(tair[j*nts:(j+1)*nts])
            qair_tmp[j]    = np.average(qair[j*nts:(j+1)*nts])
            psurf_tmp[j]   = np.average(psurf[j*nts:(j+1)*nts])
            swdown_tmp[j]  = np.average(swdown[j*nts:(j+1)*nts])
            lwdown_tmp[j]  = np.average(lwdown[j*nts:(j+1)*nts])
            wind_tmp[j]    = np.average(wind[j*nts:(j+1)*nts])
            lai_tmp[j]     = np.average(lai[j*nts:(j+1)*nts])

        rain   = rain_tmp
        tair   = tair_tmp
        qair   = qair_tmp
        psurf  = psurf_tmp
        swdown = swdown_tmp
        lwdown = lwdown_tmp
        wind   = wind_tmp
        lai    = lai_tmp

    print(rain[:])


    return lat,lon,rain,tair,qair,psurf,swdown,lwdown,wind,lai;

if __name__ == "__main__":

    path = "/scratch/w35/mm3972/model/NUWRF/test_25km_print_para/LIS_offline/OUTPUT/SURFACEMODEL/"
    input_fname = [path+"LIS_HIST_200606010030.d01.nc",path+"LIS_HIST_200606010100.d01.nc",
                   path+"LIS_HIST_200606010130.d01.nc",path+"LIS_HIST_200606010200.d01.nc",
                   path+"LIS_HIST_200606010230.d01.nc",path+"LIS_HIST_200606010300.d01.nc",
                   path+"LIS_HIST_200606010330.d01.nc",path+"LIS_HIST_200606010400.d01.nc",
                   path+"LIS_HIST_200606010430.d01.nc",path+"LIS_HIST_200606010500.d01.nc",
                   path+"LIS_HIST_200606010530.d01.nc",path+"LIS_HIST_200606010600.d01.nc",
                   path+"LIS_HIST_200606010630.d01.nc",path+"LIS_HIST_200606010700.d01.nc",
                   path+"LIS_HIST_200606010730.d01.nc",path+"LIS_HIST_200606010800.d01.nc",
                   path+"LIS_HIST_200606010830.d01.nc",path+"LIS_HIST_200606010900.d01.nc",
                   path+"LIS_HIST_200606010930.d01.nc",path+"LIS_HIST_200606011000.d01.nc",
                   path+"LIS_HIST_200606011030.d01.nc",path+"LIS_HIST_200606011100.d01.nc",
                   path+"LIS_HIST_200606011130.d01.nc",path+"LIS_HIST_200606011200.d01.nc",
                   path+"LIS_HIST_200606011230.d01.nc",path+"LIS_HIST_200606011300.d01.nc",
                   path+"LIS_HIST_200606011330.d01.nc",path+"LIS_HIST_200606011400.d01.nc",
                   path+"LIS_HIST_200606011430.d01.nc",path+"LIS_HIST_200606011500.d01.nc",
                   path+"LIS_HIST_200606011530.d01.nc",path+"LIS_HIST_200606011600.d01.nc",
                   path+"LIS_HIST_200606011630.d01.nc",path+"LIS_HIST_200606011700.d01.nc",
                   path+"LIS_HIST_200606011730.d01.nc",path+"LIS_HIST_200606011800.d01.nc",
                   path+"LIS_HIST_200606011830.d01.nc",path+"LIS_HIST_200606011900.d01.nc",
                   path+"LIS_HIST_200606011930.d01.nc",path+"LIS_HIST_200606012000.d01.nc",
                   path+"LIS_HIST_200606012030.d01.nc",path+"LIS_HIST_200606012100.d01.nc",
                   path+"LIS_HIST_200606012130.d01.nc",path+"LIS_HIST_200606012200.d01.nc",
                   path+"LIS_HIST_200606012230.d01.nc",path+"LIS_HIST_200606012300.d01.nc",
                   path+"LIS_HIST_200606012330.d01.nc",path+"LIS_HIST_200606020000.d01.nc"]
    out_fname = "./nc_files/ERAI_05hr_pixel_met_new_LIS-CABLE.nc"

    # lat -24.255707 lon 135.95001
    loc_lat = 0 # 6
    loc_lon = 0 # 20

    dels = 3600*0.5
    main(input_fname, out_fname, loc_lat, loc_lon, dels)
