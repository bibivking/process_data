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
level_class  = (/"0","10","30","60","100","200"/)
path_in      = "/g/data/w35/mm3972/data/OpenLandMap_soil"

lat_s = -44.
lat_e = -10.
lon_s = 112.
lon_e = 154.

nlat  = 3401
nlon  = 4201

lat          = fspan(lat_s,lat_e,nlat)
lon          = fspan(lon_s,lon_e,nlon)

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
    frho  = addfile(path_in+"/Soil_bulkdens_"+level_class(level)+"cm_OpenLandMap.nc", "r")
    fsand = addfile(path_in+"/Sand_"+level_class(level)+"cm_OpenLandMap.nc", "r")
    fclay = addfile(path_in+"/Clay_"+level_class(level)+"cm_OpenLandMap.nc", "r")
    forg  = addfile(path_in+"/organic_C_"+level_class(level)+"cm_OpenLandMap.nc", "r")

    LAT = frho->lat
    LON = frho->lon

    rhosoil_temp(level,:,:) = area_hi2lores_Wrap( LON, LAT, frho->Soil_bulkdens,\
                                  False, 1, lon, lat, False)
    sand_temp(level,:,:)    = area_hi2lores_Wrap( LON, LAT, fsand->Sand,\
                                  False, 1, lon, lat, False)
    clay_temp(level,:,:)    = area_hi2lores_Wrap( LON, LAT, fclay->Clay,\
                                  False, 1, lon, lat, False)
    organic_temp(level,:,:) = area_hi2lores_Wrap( LON, LAT, forg->organic_C,\
                                  False, 1, lon, lat, False)

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
rhosoil_temp = where( ismissing(rhosoil_temp) .or. ismissing(mask_temp), -9999., rhosoil_temp)

sand_temp    = where( ismissing(sand_temp) .or. ismissing(mask_temp), -9999., sand_temp)
sand_temp    = where( .not. ismissing(sand_temp) .and. sand_temp .lt. 0. , 0., sand_temp)
sand_temp    = where( sand_temp .gt. 1. , 1., sand_temp)

clay_temp    = where( ismissing(clay_temp) .or. ismissing(mask_temp), -9999., clay_temp)
clay_temp    = where( .not. ismissing(clay_temp) .and. clay_temp .lt. 0. , 0., clay_temp)
clay_temp    = where( clay_temp .gt. 1. , 1., clay_temp)

silt_temp    = where( ismissing(sand_temp) .or. ismissing(clay_temp) .or. ismissing(mask_temp),\
               -9999., 1. - sand_temp - clay_temp)

organic_temp = where( ismissing(organic_temp) .or. ismissing(mask_temp), -9999., organic_temp)
organic_temp = where( .not. ismissing(organic_temp) .and. organic_temp .lt. 0. , 0., organic_temp)
organic_temp = where( organic_temp .gt. 1. , 1., organic_temp)

rhosoil_temp = where( (sand_temp + clay_temp) .gt. 1., -9999., rhosoil_temp)
sand_temp    = where( (sand_temp + clay_temp) .gt. 1., -9999., sand_temp)
clay_temp    = where( (sand_temp + clay_temp) .gt. 1., -9999., clay_temp)
silt_temp    = where( (sand_temp + clay_temp) .gt. 1., -9999., silt_temp)
organic_temp = where( (sand_temp + clay_temp) .gt. 1., -9999., organic_temp)

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
file_out = "Openlandmap_soilcomposition_AU.nc"
system("/bin/rm -f " + file_out)    ; remove if exists
fout  = addfile (file_out, "c")     ; open output file

setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "Global OpenLandMap Soil texture"
fAtt@source_file   = "Soil_bulkdens/organic_C/Sand/Clay_0/10/30/60/100/200cm_OpenLandMap.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

print("point 5")

dimNames = (/"lat", "lon"/)
dimSizes = (/ nlat,  nlon/)
dimUnlim = (/False, False/)
filedimdef( fout,dimNames,dimSizes,dimUnlim)

filevardef( fout, "lat", "double", "lat")
filevardef( fout, "lon", "double", "lon")
filevardef( fout, "SAND", "double", (/ "lat", "lon" /))
filevardef( fout, "CLAY", "double", (/ "lat", "lon" /))
filevardef( fout, "SILT", "double", (/ "lat", "lon" /))
filevardef( fout, "OC", "double", (/ "lat", "lon" /))
filevardef( fout, "BULK_DEN", "double", (/ "lat", "lon" /))

setfileoption(fout,"DefineMode",False)

printVarSummary(fout->lat)
printVarSummary(lat)

fout->lat@long_name     = "latitude"
fout->lat@standard_name = "latitude"
fout->lat@axis          = "Y"
fout->lat@units         = "degrees_North"
fout->lat@_FillValue    = flt2dble(-9999.)
fout->lat               = flt2dble(lat)

printVarSummary(fout->lon)
printVarSummary(lon)
fout->lon@long_name     = "longitude"
fout->lon@standard_name = "longitude"
fout->lon@axis          = "X"
fout->lon@units         = "degrees_East"
fout->lon@_FillValue    = flt2dble(-9999.)
fout->lon               = flt2dble(lon)


printVarSummary(sand)
printVarSummary(fout->SAND)
fout->SAND@long_name     = "soil sand fraction"
fout->SAND@units         = "-"
fout->SAND@comment       = "Column of soil between 0 and 460 cm." ;
fout->SAND@_FillValue    = flt2dble(-9999.)
fout->SAND               = flt2dble(sand)


fout->CLAY@long_name     = "soil clay fraction"
fout->CLAY@units         = "-"
fout->CLAY@comment       = "Column of soil between 0 and 460 cm." ;
fout->CLAY@_FillValue    = flt2dble(-9999.)
fout->CLAY               = flt2dble(clay)

fout->SILT@long_name     = "soil silt fraction"
fout->SILT@units         = "-"
fout->SILT@comment       = "Column of soil between 0 and 460 cm." ;
fout->SILT@_FillValue    = flt2dble(-9999.)
fout->SILT               = flt2dble(silt)

fout->OC@long_name       = "soil organic carbon"
fout->OC@units           = "kg/kg"
fout->OC@comment         = "Column of soil between 0 and 460 cm." ;
fout->OC@_FillValue      = flt2dble(-9999.)
fout->OC                 = flt2dble(organic)

fout->BULK_DEN@long_name   = "soil bulk density"
fout->BULK_DEN@units       = "kg m-3"
fout->BULK_DEN@comment     = "Column of soil between 0 and 460 cm." ;
fout->BULK_DEN@_FillValue  = flt2dble(-9999.)
fout->BULK_DEN             = flt2dble(rhosoil)

print("Exit DefineMode")
end
