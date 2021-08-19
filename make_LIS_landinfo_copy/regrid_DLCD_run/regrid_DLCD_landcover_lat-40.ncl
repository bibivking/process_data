load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

; ================================ read DLCD_LC ===================================
DLCD_in     = "/g/data/w35/mm3972/data/Dynamic_land_cover_maps/Dynamic_land_cover_dataset_CABLE.nc"
DLCD        = addfile(DLCD_in,"r")
DLCD_LC     = where( .not. ismissing(DLCD->iveg(::-1,:)), DLCD->iveg(::-1,:), 16)
DLCD_LC!0   = "lat"
DLCD_LC!1   = "lon"
lat         = dble2flt(DLCD->latitude(::-1))
lon         = dble2flt(DLCD->longitude)
DLCD_LC&lat = lat
DLCD_LC&lon = lon
printVarSummary(lat)

LAT   = -40.500

; Source lat-lon
DLCD_LC_lat     = tointeger(DLCD_LC({LAT-0.5:LAT+0.5},:))
DLCD_LC_lat!0   = "lat"
DLCD_LC_lat!1   = "lon"
DLCD_LC_lat&lat = lat({LAT-0.5:LAT+0.5})
DLCD_LC_lat&lon = lon

; Aim lat-lon
Lat_s       = LAT-0.495 ; -45.003623
Lat_e       = LAT+0.495 ; -10.001174
Lon_s       = 110.005 ; 110.001175
Lon_e       = 155.005 ; 155.008015
nLat        = 100 ;floattointeger((Lat_e-Lat_s)/0.01+1)
nLon        = floattointeger((Lon_e-Lon_s)/0.01+1)
Lat         = fspan(Lat_s,Lat_e,nLat)
Lon         = fspan(Lon_s,Lon_e,nLon)

print("nLat = "+nLat+" nLon = "+nLon)
print("Lat")
print(Lat)

; =============================== interpolation ==================================
DLCD_LC_regrid = new((/nLat,nLon/),integer)
DLCD_LC_regrid = -1

do lat_idx = 0, nLat-1  
  print("lat_idx = " + lat_idx)
  do lon_idx = 0, nLon-1
    ; print("lat_idx = "+lat_idx)
    ; print("lon_idx = "+lon_idx)
    lat_tmp   = Lat(lat_idx)
    lon_tmp   = Lon(lon_idx)
    tmp_block = DLCD_LC_lat({lat_tmp-0.005:lat_tmp+0.005},{lon_tmp-0.005:lon_tmp+0.005})    
    uniq_pfts = get_unique_values(tmp_block)
    nuniq     = dimsizes(uniq_pfts)
    if nuniq .eq. 1 then
      DLCD_LC_regrid(lat_idx,lon_idx) = uniq_pfts(0)
    else 
      pft_type      = uniq_pfts(0)
      pixel_max     = num(tmp_block .eq. uniq_pfts(0)) 
      do i=1,nuniq-1
        pixel_num   = num(tmp_block .eq. uniq_pfts(i)) 
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


setfileoption("bin","WriteByteOrder","BigEndian")
file_out = "./binary_file/NCAR_AU_Dynamic_land_cover_dataset_lat"+LAT+".1gd4r"
system("rm "+ file_out)
fbindirwrite(file_out,DLCD_LC_regrid)
print(max(DLCD_LC_regrid))
print(min(DLCD_LC_regrid))

end
