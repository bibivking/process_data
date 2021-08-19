load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________


; ================================= Notes =====================================
; This script isn't practical since it will take more than 200 h to finish.
; Thus, I regrid DLCD separately for every latitude. See regrid_DLCD_landcover_lat-XX.ncl
; in /g/data/w35/mm3972/scripts/process_data/make_LIS_landinfo/regrid_DLCD_run

; ============================= testing plot ===================================
wks = gsn_open_wks("pdf","Check_LC")
gsn_define_colormap(wks,"drought_severity")

res                         = True
res@gsnDraw                 = True
res@gsnFrame                = True
res@gsnMaximize             = False
res@cnFillMode              = "RasterFill"            ; Raster Mode
res@cnFillOn                = True
res@cnLinesOn               = False

; ================================ read NCAR_LC ===================================
setfileoption("bin","ReadByteOrder","BigEndian")
NCAR_path = "/g/data/w35/LIS/LIS_PARAMS/LIS_PARAMS/UMD/1KM/landcover_CABLE_NCAR.1gd4r"
NCAR_LC   = fbindirread (NCAR_path, 0, (/15000,36000/), "float") ;
NCAR_LC!0 = "lat"
NCAR_LC!1 = "lon"
NCAR_nlat = floattointeger((89.995+59.995)/0.01+1)
NCAR_nlon = floattointeger((179.995+179.995)/0.01+1)
; print("NCAR_nlat =" + NCAR_nlat)
; print("NCAR_nlon =" + NCAR_nlon)
NCAR_LC&lat = fspan(-59.995,89.995,  NCAR_nlat)
NCAR_LC&lon = fspan(-179.995,179.995, NCAR_nlon)
printVarSummary(NCAR_LC)

; ================================ read DLCD_LC ===================================
DLCD_in = "/g/data/w35/mm3972/data/Dynamic_land_cover_maps/Dynamic_land_cover_dataset_CABLE.nc"
DLCD    = addfile(DLCD_in,"r")
DLCD_LC = where( .not. ismissing(DLCD->iveg(::-1,:)), DLCD->iveg(::-1,:), 16)
DLCD_LC = where( DLCD_LC < 0, 16, DLCD_LC)
DLCD_LC!0 = "lat"
DLCD_LC!1 = "lon"
lat       = dble2flt(DLCD->latitude(::-1))
lon       = dble2flt(DLCD->longitude)
DLCD_LC&lat = lat
DLCD_LC&lon = lon


lat_s = -44.995 ; -45.003623
lat_e = -9.995 ; -10.001174
lon_s = 110.005 ; 110.001175
lon_e = 155.005 ; 155.008015

nlat  = floattointeger((lat_e-lat_s)/0.01+1)
nlon  = floattointeger((lon_e-lon_s)/0.01+1)
Lat   = fspan(lat_s,lat_e,nlat)
Lon   = fspan(lon_s,lon_e,nlon)

; =============================== interpolation ==================================
DLCD_LC_regrid = new((/nlat,nlon/),float)
DLCD_LC_regrid = -1.

do lat_idx = 0, nlat-1  

  print("lat_idx = " + lat_idx)

  do lon_idx = 0, nlon-1
    ; print("lat_idx = "+lat_idx)
    ; print("lon_idx = "+lon_idx)
    tmp_block = DLCD_LC({Lat(lat_idx)-0.005:Lat(lat_idx)+0.005},{Lon(lon_idx)-0.005:Lon(lon_idx)+0.005})    
    uniq_pfts = get_unique_values(tmp_block)
    nuniq     = dimsizes(uniq_pfts)
    if nuniq .eq. 1 then
      DLCD_LC_regrid(lat_idx,lon_idx) = uniq_pfts(0)
    else 
      pft_type      = uniq_pfts(0)
      pixel_max     = num(tmp_block .eq. uniq_pfts(0)) 
      do i=1,nuniq-1
        pixel_num = num(tmp_block .eq. uniq_pfts(i)) 
        if pixel_max .lt. pixel_num then
          pixel_max = pixel_num
          pft_type  = uniq_pfts(i)
        end if
      end do ; i
      DLCD_LC_regrid(lat_idx,lon_idx) = pft_type
    end if
    delete(tmp_block)
    delete(uniq_pfts)
  end do ; lon_idx
end do ; lat_idx

; DLCD_LC_regrid     = linint2(DLCD_LC&lon, DLCD_LC&lat, DLCD_LC, False, Lon, Lat, 0)
; DLCD_LC_regrid!0   = "lat" 
; DLCD_LC_regrid!1   = "lon"
; DLCD_LC_regrid&lat = Lat
; DLCD_LC_regrid&lon = Lon

print("NCAR_LC({lat_s:lat_e},{lon_s,lon_e})")
tt = NCAR_LC({lat_s:lat_e},{lon_s:lon_e})
printVarSummary(tt)
print("DLCD_LC_regrid")
printVarSummary(DLCD_LC_regrid)

NCAR_LC({lat_s-0.005:lat_e+0.005},{lon_s-0.005:lon_e+0.005}) = DLCD_LC_regrid
NCAR_LC_int = tointeger(NCAR_LC)
NCAR_LC_int@_FillValue = 16
; print(NCAR_LC_int)

setfileoption("bin","WriteByteOrder","BigEndian")
file_out = "./binary_file/NCAR_AU_Dynamic_land_cover_dataset.1gd4r"
system("rm "+ file_out)
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
fout->lat               = NCAR_LC&lat

fout->lon@long_name     = "longitude"
fout->lon@standard_name = "longitude"
fout->lon@axis          = "X"
fout->lon@units         = "degrees_East"
fout->lon               = NCAR_LC&lon

fout->Landcover@long_name     = "land cover type"
fout->Landcover@units         = "-"
fout->Landcover@_FillValue    = 16
fout->Landcover               = NCAR_LC_int

; plot = gsn_csm_contour(wks,NCAR_LC_int,res)

; ============================== Check output file ===============================

; setfileoption("bin","ReadByteOrder","BigEndian")
; NCAR_path = "Dynamic_land_cover_dataset_CABLE"
; NCAR_LC   = fbindirread (NCAR_path, 0, (14902,19161/), "float") ;
; printVarSummary(NCAR_LC)
; plot      = gsn_csm_contour(wks,NCAR_LC,res)

end
