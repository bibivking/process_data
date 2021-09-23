load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________


; ================================ read Copernicus_LC ===================================
Copernicus_in     = "/g/data/w35/mm3972/data/LAI_data/monthly_climatology.nc"
Copernicus        = addfile(Copernicus_in,"r")
Copernicus_LC     = dble2flt(where( .not. ismissing(Copernicus->LAI(:,::-1,:)), Copernicus->LAI(:,::-1,:), 0.0001))
lat               = dble2flt(Copernicus->lat(::-1))
lon               = dble2flt(Copernicus->lon)

Copernicus_LC!0   = "time"
Copernicus_LC!1   = "lat"
Copernicus_LC!2   = "lon"
Copernicus_LC&time= (/1,2,3,4,5,6,7,8,9,10,11,12/)
Copernicus_LC&lat = lat
Copernicus_LC&lon = lon

printVarSummary(Copernicus_LC)


lat_s = -46.00  ; -45.9999999999714
lat_e = -7.008   ;  -7.00892857140879
lon_s = 105.00 ; 105.000000000389
lon_e = 164.992 ; 164.991071429042


; ================================ read AVHRR_LC ===================================
setfileoption("bin","ReadByteOrder","BigEndian")
mth_name = (/"jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"/)

do mth = 0,0 ;11 
  AVHRR_path   = "/g/data/w35/LIS/LIS_PARAMS/UMD/1KM/lai_AVHRR_CLIM."+mth_name(mth)+".1gd4r"
  AVHRR_LC     = fbindirread (AVHRR_path, 0, (/15000,36000/), "float")
  ; AVHRR_LC@_FillValue = 16

  AVHRR_LC!0   = "lat"
  AVHRR_LC!1   = "lon"
  AVHRR_nlat   = floattointeger((89.995+59.995)/0.01+1)
  AVHRR_nlon   = floattointeger((179.995+179.995)/0.01+1)
  LAT          = fspan(-59.995,89.995,  AVHRR_nlat)
  LAT!0        = "LAT"
  LAT&LAT      = fspan(-59.995,89.995,  AVHRR_nlat)

  LON          = fspan(-179.995,179.995,AVHRR_nlon)
  LON!0        = "LON"
  LON&LON      = fspan(-179.995,179.995,AVHRR_nlon)

  AVHRR_LC&lat = fspan(-59.995,89.995,  AVHRR_nlat)
  AVHRR_LC&lon = fspan(-179.995,179.995, AVHRR_nlon)
  printVarSummary(AVHRR_LC)

  printVarSummary(Copernicus_LC&lon)
  printVarSummary(Copernicus_LC&lat)
  printVarSummary(LON({lon_s:lon_e}))
  printVarSummary(LAT({lat_s:lat_e}))
  AVHRR_LC({lat_s:lat_e},{lon_s:lon_e}) = \
              linint2( Copernicus_LC&lon, Copernicus_LC&lat, Copernicus_LC(mth,{lat_s:lat_e},{lon_s:lon_e}),\
                       True, LON({lon_s:lon_e}), LAT({lat_s:lat_e}), 0)

  setfileoption("bin","WriteByteOrder","BigEndian")
  AVHRR_out = "./binary_file/lai_AVHRR_CLIM."+mth_name(mth)+".1gd4r"
  system("/bin/rm -f " + AVHRR_out)
  fbindirwrite(AVHRR_out, AVHRR_LC)
end do

; __________________ check output __________________
file_out_nc = "./binary_file/AVHRR_AU_Copernicus_LAI.nc"
system("/bin/rm -f " + file_out_nc)    ; remove if exists
fout  = addfile (file_out_nc, "c")     ; open output file

setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "AVHRR + Anna's Copernicus (over AU) LAI landcover map"
fAtt@source_file   = "/g/data/w35/LIS/LIS_PARAMS/UMD/1KM/lai_AVHRR_CLIM.1-12.1gd4r and /g/data/w35/mm3972/data/LAI_data/monthly_climatology.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"time","lat", "lon"/)
dimSizes = (/ 12, AVHRR_nlat,  AVHRR_nlon/)
dimUnlim = (/False, False, False/)
filedimdef( fout,dimNames,dimSizes,dimUnlim)

filevardef( fout, "time", "integer", "time")
filevardef( fout, "lat", "float", "lat")
filevardef( fout, "lon", "float", "lon")
filevardef( fout, "LAI", "float", (/ "time","lat", "lon" /))
setfileoption(fout,"DefineMode",False)

fout->time@long_name     = "time"
fout->time@standard_name = "time"
fout->time               = ispan(1,12,1)

fout->lat@long_name     = "latitude"
fout->lat@standard_name = "latitude"
fout->lat@axis          = "Y"
fout->lat@units         = "degrees_North"
fout->lat               = AVHRR_LC&lat*1.

fout->lon@long_name     = "longitude"
fout->lon@standard_name = "longitude"
fout->lon@axis          = "X"
fout->lon@units         = "degrees_East"
fout->lon               = AVHRR_LC&lon*1.

fout->LAI@long_name     = "leaf area index"
fout->LAI@units         = "-"
fout->LAI@_FillValue    = -9999.
fout->LAI               = AVHRR_LC*1.

end
