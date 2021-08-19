;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: form Openlandmap soil texture file for Australia
; ______________________________________________________________________________

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; __________________ Read Openlandmap soil texture __________________
nsdepth      = 6
scale_opt    = "CORDEX" ;"Global" ; "AU"
level_class  = (/"0","10","30","60","100","200"/)
path_in      = "/g/data/w35/mm3972/scripts/process_data/make_LIS_landinfo/nc_file"

if scale_opt .eq. "AU" then
  lat_s = -44.
  lat_e = -10.
  lon_s = 112.
  lon_e = 154.
  nlat  = 3401
  nlon  = 4201
  lat   = fspan(lat_s,lat_e,nlat)
  lon   = fspan(lon_s,lon_e,nlon)
else if scale_opt .eq. "Global" then
  lat_s = -62.
  lat_e = 87.4
  lon_s = -180.
  lon_e = 180
  nlat  = tointeger((lat_e-lat_s)/0.01+1)
  nlon  = tointeger((lon_e-lon_s)/0.01+1)
  lat   = fspan(lat_s,lat_e,nlat)
  lon   = fspan(lon_s,lon_e,nlon)
else if scale_opt .eq. "CORDEX" then
  lat_s = -54.995    
  lat_e = 14.995 ; the last value in python isn't included
  lon_s = 85.005  
  lon_e = 179.995 ;207.995 ; the last value in python isn't included   
  nlat  = tointeger((lat_e-lat_s)/0.01+1)
  nlon  = tointeger((lon_e-lon_s)/0.01+1)
  lat   = fspan(lat_s,lat_e,nlat) 
  lon   = fspan(lon_s,lon_e,nlon) 
end if
end if 
end if

rhosoil_temp = new((/nsdepth, nlat, nlon/), float)
sand_temp    = new((/nsdepth, nlat, nlon/), float)
clay_temp    = new((/nsdepth, nlat, nlon/), float)
silt_temp    = new((/nsdepth, nlat, nlon/), float)
organic_temp = new((/nsdepth, nlat, nlon/), float)
mask_temp    = new((/nsdepth, nlat, nlon/), float)

rhosoil_temp@_FillValue = 255.
sand_temp@_FillValue    = 255.
clay_temp@_FillValue    = 255.
silt_temp@_FillValue    = 255.
organic_temp@_FillValue = 255.

print("point 1")

do level = 0,5
    print(level_class(level))
    frho  = addfile(path_in+"/Soil_bulkdens_"+level_class(level)+"cm_"+scale_opt+"_OpenLandMap.nc", "r")
    fsand = addfile(path_in+"/Sand_"+level_class(level)+"cm_"+scale_opt+"_OpenLandMap.nc", "r")
    fclay = addfile(path_in+"/Clay_"+level_class(level)+"cm_"+scale_opt+"_OpenLandMap.nc", "r")
    forg  = addfile(path_in+"/organic_C_"+level_class(level)+"cm_"+scale_opt+"_OpenLandMap.nc", "r")

    rhosoil_temp(level,:,:) = frho->Soil_bulkdens({lat_s-0.005:lat_e+0.005},{lon_s-0.005:lon_e+0.005})*1.
    sand_temp(level,:,:)    = fsand->Sand({lat_s-0.005:lat_e+0.005},{lon_s-0.005:lon_e+0.005})*1.
    clay_temp(level,:,:)    = fclay->Clay({lat_s-0.005:lat_e+0.005},{lon_s-0.005:lon_e+0.005})*1.
    organic_temp(level,:,:) = forg->organic_C({lat_s-0.005:lat_e+0.005},{lon_s-0.005:lon_e+0.005})*1.

    ; make mask
    maskout = rhosoil_temp(level,:,:)
    print("check default value")
    printVarSummary(maskout)
    mask_temp(level,:,:)    = where(ismissing(maskout), -9999. , 1.)
    mask_temp(level,:,:)    = where(mask_temp(level,:,:) .ne. 1., -9999., 1. )
    mask_temp@_FillValue    = -9999.
    delete(frho)
    delete(fsand)
    delete(fclay)
    delete(forg)
end do

; rhosoil 10 kg/m3 -> kg/m3
rhosoil_temp = rhosoil_temp*10.
; sand, clay % -> m3/m3
sand_temp    = sand_temp/100.
clay_temp    = clay_temp/100.
; organic 5g / kg"
organic_temp = organic_temp*0.005

print("point 2")

; __________________ quality control __________________
rhosoil_temp = where( ismissing(rhosoil_temp) .or. ismissing(mask_temp), -9999., rhosoil_temp) ;

sand_temp    = where( ismissing(sand_temp) .or. ismissing(mask_temp), -9999., sand_temp)
sand_temp    = where( (.not. ismissing(sand_temp)) .and. (.not. ismissing(mask_temp)) .and. (sand_temp .lt. 0.),\
                      0., sand_temp)
sand_temp    = where( sand_temp .gt. 1. , 1., sand_temp)

clay_temp    = where( ismissing(clay_temp) .or. ismissing(mask_temp), -9999., clay_temp)
clay_temp    = where( (.not. ismissing(clay_temp)) .and. (.not. ismissing(mask_temp)) .and. (clay_temp .lt. 0.), \
                      0., clay_temp)
clay_temp    = where( clay_temp .gt. 1. , 1., clay_temp)

sand_temp    = where( (sand_temp + clay_temp) .gt. 1., -9999., sand_temp)
clay_temp    = where( (sand_temp + clay_temp) .gt. 1., -9999., clay_temp)

organic_temp = where( ismissing(organic_temp) .or. ismissing(mask_temp), -9999., organic_temp)
organic_temp = where( (.not. ismissing(organic_temp)) .and. (.not. ismissing(organic_temp)) .and. (organic_temp .lt. 0.),\
                      0., organic_temp)
organic_temp = where( organic_temp .gt. 1. , 1., organic_temp)

rhosoil_temp@_FillValue = -9999.
sand_temp@_FillValue    = -9999.
clay_temp@_FillValue    = -9999.
organic_temp@_FillValue = -9999.

do lvl = 0,5
  print("lvl = "+lvl)
  print(avg(rhosoil_temp(lvl,:,:)))
  print(avg(sand_temp(lvl,:,:)))
  print(avg(clay_temp(lvl,:,:)))
  print(avg(organic_temp(lvl,:,:)))
  rhosoil_temp(lvl,:,:) = where(ismissing(rhosoil_temp(lvl,:,:)), avg(rhosoil_temp(lvl,:,:)) , rhosoil_temp(lvl,:,:))
  sand_temp(lvl,:,:)    = where(ismissing(sand_temp(lvl,:,:)), avg(sand_temp(lvl,:,:)) , sand_temp(lvl,:,:))
  clay_temp(lvl,:,:)    = where(ismissing(clay_temp(lvl,:,:)), avg(clay_temp(lvl,:,:)) , clay_temp(lvl,:,:))
  organic_temp(lvl,:,:) = where(ismissing(organic_temp(lvl,:,:)), avg(organic_temp(lvl,:,:)) , organic_temp(lvl,:,:))
end do
print(any(ismissing(rhosoil_temp)))
print(any(ismissing(sand_temp)))
print(any(ismissing(clay_temp)))
print(any(ismissing(organic_temp)))

silt_temp    = 1. - sand_temp - clay_temp

print("point 3")

; __________________ 6->1 __________________
rhosoil = (rhosoil_temp(0,:,:)*0.05 + rhosoil_temp(1,:,:)*0.15 \
                  + rhosoil_temp(2,:,:)*0.25 + rhosoil_temp(3,:,:)*0.35 \
                  + rhosoil_temp(4,:,:)*0.7 + rhosoil_temp(5,:,:)*3.1)/4.6
sand    = (sand_temp(0,:,:)*0.05 + sand_temp(1,:,:)*0.15 \
                  + sand_temp(2,:,:)*0.25 + sand_temp(3,:,:)*0.35 \
                  + sand_temp(4,:,:)*0.7 + sand_temp(5,:,:)*3.1)/4.6
clay    = (clay_temp(0,:,:)*0.05 + clay_temp(1,:,:)*0.15 \
                  + clay_temp(2,:,:)*0.25 + clay_temp(3,:,:)*0.35 \
                  + clay_temp(4,:,:)*0.7 + clay_temp(5,:,:)*3.1)/4.6
silt    = (silt_temp(0,:,:)*0.05 + silt_temp(1,:,:)*0.15 \
                  + silt_temp(2,:,:)*0.25 + silt_temp(3,:,:)*0.35 \
                  + silt_temp(4,:,:)*0.7 + silt_temp(5,:,:)*3.1)/4.6
organic = (organic_temp(0,:,:)*0.05 + organic_temp(1,:,:)*0.15 \
                  + organic_temp(2,:,:)*0.25 + organic_temp(3,:,:)*0.35 \
                  + organic_temp(4,:,:)*0.7 + organic_temp(5,:,:)*3.1)/4.6

; print(rhosoil(8000,:))
printVarSummary(sand)
printVarSummary(clay)
printVarSummary(silt)
printVarSummary(organic)

delete(rhosoil_temp)
delete(sand_temp)
delete(clay_temp)
delete(silt_temp)
delete(organic_temp)
delete(mask_temp)

print("point 4")

; __________________ create netcdf file __________________
file_out = "Openlandmap_soilcomposition_"+scale_opt+"_180E.nc"
system("/bin/rm -f " + file_out)    ; remove if exists
fout  = addfile (file_out, "c")     ; open output file

setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = scale_opt+" OpenLandMap Soil texture"
fAtt@source_file   = "Soil_bulkdens/organic_C/Sand/Clay_0/10/30/60/100/200cm_OpenLandMap.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

print("point 5")

dimNames = (/"lat", "lon"/)
dimSizes = (/ nlat,  nlon/)
dimUnlim = (/False, False/)
filedimdef( fout,dimNames,dimSizes,dimUnlim)

filevardef( fout, "lat", "float", "lat")
filevardef( fout, "lon", "float", "lon")
filevardef( fout, "SAND", "float", (/ "lat", "lon" /))
filevardef( fout, "CLAY", "float", (/ "lat", "lon" /))
filevardef( fout, "SILT", "float", (/ "lat", "lon" /))
filevardef( fout, "OC", "float", (/ "lat", "lon" /))
filevardef( fout, "BULK_DEN", "float", (/ "lat", "lon" /))

setfileoption(fout,"DefineMode",False)

printVarSummary(fout->lat)
printVarSummary(lat)

fout->lat@long_name     = "latitude"
fout->lat@standard_name = "latitude"
fout->lat@axis          = "Y"
fout->lat@units         = "degrees_North"
fout->lat@_FillValue    = -9999.;flt2dble()
fout->lat               = lat*1.

printVarSummary(fout->lon)
printVarSummary(lon)
fout->lon@long_name     = "longitude"
fout->lon@standard_name = "longitude"
fout->lon@axis          = "X"
fout->lon@units         = "degrees_East"
fout->lon@_FillValue    = -9999.
fout->lon               = lon*1.


printVarSummary(sand)
printVarSummary(fout->SAND)
fout->SAND@long_name     = "soil sand fraction"
fout->SAND@units         = "-"
fout->SAND@comment       = "Column of soil between 0 and 460 cm." ;
fout->SAND@_FillValue    = -9999.
fout->SAND               = sand*1.


fout->CLAY@long_name     = "soil clay fraction"
fout->CLAY@units         = "-"
fout->CLAY@comment       = "Column of soil between 0 and 460 cm." ;
fout->CLAY@_FillValue    = -9999.
fout->CLAY               = clay*1.

fout->SILT@long_name     = "soil silt fraction"
fout->SILT@units         = "-"
fout->SILT@comment       = "Column of soil between 0 and 460 cm." ;
fout->SILT@_FillValue    = -9999.
fout->SILT               = silt*1.

fout->OC@long_name       = "soil organic carbon"
fout->OC@units           = "kg/kg"
fout->OC@comment         = "Column of soil between 0 and 460 cm." ;
fout->OC@_FillValue      = -9999.
fout->OC                 = organic*1.

fout->BULK_DEN@long_name   = "soil bulk density"
fout->BULK_DEN@units       = "kg m-3"
fout->BULK_DEN@comment     = "Column of soil between 0 and 460 cm." ;
fout->BULK_DEN@_FillValue  = -9999.
fout->BULK_DEN             = rhosoil*1.

print("Exit DefineMode")
end
