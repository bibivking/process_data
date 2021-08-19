load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________


; ================================ read NCAR_LC ===================================
setfileoption("bin","ReadByteOrder","BigEndian")
NCAR_path   = "/g/data/w35/LIS/LIS_PARAMS/LIS_PARAMS/UMD/1KM/landcover_CABLE_NCAR.1gd4r"
NCAR_LC     = fbindirread (NCAR_path, 0, (/15000,36000/), "float")
NCAR_LC_int = tointeger(NCAR_LC)
NCAR_LC_int@_FillValue = 16

NCAR_LC_int!0   = "lat"
NCAR_LC_int!1   = "lon"
NCAR_nlat       = floattointeger((89.995+59.995)/0.01+1)
NCAR_nlon       = floattointeger((179.995+179.995)/0.01+1)
NCAR_LC_int&lat = fspan(-59.995,89.995,  NCAR_nlat)
NCAR_LC_int&lon = fspan(-179.995,179.995, NCAR_nlon)
printVarSummary(NCAR_LC_int)

do i = -44,-10
  ; ================================ read DLCD_LC ===================================
  LAT   = i-0.5

  ; lat-lon
  lat_s       = LAT-0.495 ; -45.003623
  lat_e       = LAT+0.495 ; -10.001174
  lon_s       = 110.005 ; 110.001175
  lon_e       = 155.005 ; 155.008015
  nlat        = 100
  nlon        = floattointeger((lon_e-lon_s)/0.01+1)
  lat         = fspan(lat_s,lat_e,nlat)
  lon         = fspan(lon_s,lon_e,nlon)

  setfileoption("bin","ReadByteOrder","BigEndian")
  DLCD_lat_in = "./regrid_DLCD_run/binary_file/NCAR_AU_Dynamic_land_cover_dataset_lat"+i+".5.1gd4r"
  DLCD_lat    = fbindirread (DLCD_lat_in, 0, (/nlat,nlon/), "integer") ;

  ; ================================ insert DLCD_LC ===================================
  printVarSummary(NCAR_LC_int)
  NCAR_LC_int({lat_s-0.005:lat_e+0.005},{lon_s-0.005:lon_e+0.005}) = DLCD_lat*1
end do

NCAR_LC_int@_FillValue = 16

setfileoption("bin","WriteByteOrder","BigEndian")
file_out = "./binary_file/NCAR_AU_Dynamic_land_cover_dataset.1gd4r"
system("/bin/rm -f " + file_out)
fbindirwrite(file_out,NCAR_LC_int)
print(max(NCAR_LC_int))
print(min(NCAR_LC_int))

; __________________ check output __________________
file_out_nc = "./binary_file/NCAR_AU_Dynamic_land_cover_dataset.nc"
system("/bin/rm -f " + file_out_nc)    ; remove if exists
fout  = addfile (file_out_nc, "c")     ; open output file

setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "NCAR + Dynamic land cover dataset (over AU) landcover map"
fAtt@source_file   = "/g/data/w35/LIS/LIS_PARAMS/LIS_PARAMS/UMD/1KM/landcover_CABLE_NCAR.1gd4r and /g/data/w35/mm3972/data/Dynamic_land_cover_maps/Dynamic_land_cover_dataset_CABLE.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"lat", "lon"/)
dimSizes = (/ NCAR_nlat,  NCAR_nlon/)
dimUnlim = (/False, False/)
filedimdef( fout,dimNames,dimSizes,dimUnlim)

filevardef( fout, "lat", "float", "lat")
filevardef( fout, "lon", "float", "lon")
filevardef( fout, "Landcover", "integer", (/ "lat", "lon" /))
setfileoption(fout,"DefineMode",False)

fout->lat@long_name     = "latitude"
fout->lat@standard_name = "latitude"
fout->lat@axis          = "Y"
fout->lat@units         = "degrees_North"
fout->lat               = NCAR_LC_int&lat*1.

fout->lon@long_name     = "longitude"
fout->lon@standard_name = "longitude"
fout->lon@axis          = "X"
fout->lon@units         = "degrees_East"
fout->lon               = NCAR_LC_int&lon

fout->Landcover@long_name     = "land cover type"
fout->Landcover@units         = "-"
fout->Landcover@_FillValue    = 16
fout->Landcover               = NCAR_LC_int*1

; ============================== Check output file ===============================

; setfileoption("bin","ReadByteOrder","BigEndian")
; NCAR_path = "Dynamic_land_cover_dataset_CABLE"
; NCAR_LC   = fbindirread (NCAR_path, 0, (14902,19161/), "float") ;
; printVarSummary(NCAR_LC)
; plot      = gsn_csm_contour(wks,NCAR_LC,res)

end
