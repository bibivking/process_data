;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

; ================================= Start ======================================
begin

year_s    = 2000
year_e    = 2019
year_sum  = year_e - year_s + 1

path      = "/g/data/w35/mm3972/data/CERES/"
filename  = path+"CERES_EBAF-Surface_Ed2.8_Subset_200003-201502.nc"
fin       = addfile (filename,"r")

system("rm -rf "+path+"CERES_EBAF-Surface_Ed4.1_Subset_200003-201911.nc")
filename1 = path+"CERES_EBAF-Surface_Ed4.1_Subset_200003-201911.nc"
fout      = addfile (filename1,"c")

; ================================ Edit NetCDF =================================
; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt             = True            ; assign file attributes
fAtt@title       = "CERES EBAF Surface Fluxes. Monthly Averages and 20-year Climatology." ;
fAtt@institution = "NASA Langley Research Center" ;
fAtt@Conventions = "CF-1.4" ;
fAtt@comment     = "Climatology from 03/2000 to 11/2019" ;
fAtt@version     = "Edition 4.1; Release Date May 28, 2019" ;
fAtt@DOI         = "10.5067/TERRA-AQUA/CERES/EBAF_L3B004.1"

dimNames = (/"time", "lat", "lon"  /)
dimSizes = (/   237,   180,  360   /)
dimUnlim = (/ False, False,  False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; __________________ 1D ___________________
filevardef( fout, "time", "integer", "time")
fout->time@units         = "days since 2000-03-01 00:00:00"
fout->time@long_name     = "time"
fout->time@delta_t       = "0000-00-01 00:00:00"

filevardef( fout, "lat", "float", "lat")
fout->lat@long_name     = "latitude" ;
fout->lat@standard_name = "latitude" ;
fout->lat@units         = "degrees_north" ;
fout->lat@valid_range   = "-90., 90." ;
fout->lat               = fspan(-89.5, 89.5, 180)

filevardef( fout, "lon", "float", "lon")
fout->lon@long_name     = "longitude" ;
fout->lon@standard_name = "longitude" ;
fout->lon@units         = "degrees_east" ;
fout->lon@valid_range   = "-180., 360." ;
fout->lon               = fspan(0.5, 359.5, 360)

; __________________ 2D ___________________
filevardef( fout, "sfc_net_tot_all_mon", "float", (/ "time", "lat", "lon" /))
fout->sfc_net_tot_all_mon@long_name     = "Surface Net Total Flux, All-Sky conditions, Monthly Means" ;
fout->sfc_net_tot_all_mon@standard_name = "Surface Net Total Flux - All-Sky" ;
fout->sfc_net_tot_all_mon@CF_name       = "surface_net_downward_radiative_flux" ;
fout->sfc_net_tot_all_mon@comment       = "none" ;
fout->sfc_net_tot_all_mon@units         = "W m-2" ;
fout->sfc_net_tot_all_mon@valid_min     = " -300.000" ;
fout->sfc_net_tot_all_mon@valid_max     = "  500.000" ;
fout->sfc_net_tot_all_mon@_FillValue    = -999.

time                 = new(237,integer)
sfc_net_tot_all_mon  = new((/237,180,360/),float)
time                 = 0
sfc_net_tot_all_mon  = 0.

counter              = 0

do year = year_s,year_e
   do month = 1, 12
     if month .lt. 10 then
        filename2        = path+"CERES_EBAF_Ed4.1_Subset_"+year+"0"+month+"-"+year+"0"+month+".nc"
     else
        filename2        = path+"CERES_EBAF_Ed4.1_Subset_"+year+month+"-"+year+month+".nc"
     end if

     if (year .ne. year_s .or. month .gt. 2) .and. (year .ne. year_e .or. month .lt. 12) then
         finput              = addfile(filename2,"r")
         time(counter)       = finput->time(0)
         sfc_net_tot_all_mon(counter,:,:) = finput->sfc_net_tot_all_mon(0,:,:)
         counter             = counter + 1
         delete(finput)
     end if
     delete(filename2)
   end do
end do

fout->time                = time*1
fout->sfc_net_tot_all_mon = sfc_net_tot_all_mon*1

wks = gsn_open_wks("pdf","./plots/Check_CERES")
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res                    = True
res@cnFillMode         = "RasterFill"            ; Raster Mode
res@cnFillOn           = True                            ;��ɫ
res@tmBorderThicknessF = 3.0

; x              = ispan(1,time_tot,1)
plot = gsn_csm_contour(wks,dim_avg_n_Wrap(fout->sfc_net_tot_all_mon(:180,:,:),0),res)
plot = gsn_csm_contour(wks,lonFlip(dim_avg_n_Wrap(fin->sfc_net_tot_all_mon(:,:,:),0)),res)

plot = gsn_csm_contour(wks,lonFlip(dim_avg_n_Wrap(fin->sfc_net_tot_all_mon(:,:,:),0))-dim_avg_n_Wrap(fout->sfc_net_tot_all_mon(:180,:,:),0),res)
setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")

end
