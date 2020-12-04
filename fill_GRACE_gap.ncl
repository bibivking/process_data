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

year_s    = 2002
year_e    = 2020
year_sum  = year_e - year_s + 1
time_tot  = year_sum * 12

filename  = "/g/data/w35/Shared_data/Observations/GRACE/GRACE_JPLRL06M_MASCON/GRCTellus.JPL.200204_202004.GLO.RL06M.MSCNv02CRI.nc"
fin       = addfile (filename,"r")
grace_tot = dimsizes(fin->time)

system("rm -rf GRCTellus.JPL.2002_2020_gap-fill.nc") ;-- delete file

filename1 = "GRCTellus.JPL.2002_2020_gap-fill.nc" ; /g/data/w35/mm3972/data/GRACE/GRACE_JPL_RL06/
fout      = addfile (filename1,"c")

; ================================ Edit NetCDF =================================

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "CABLE surface forcing data over Australia"

; copy all global attributes from input file
global_attnames = getvaratts(fin)

do i = 0,dimsizes(global_attnames)-1
   print(fin@$global_attnames(i)$) ;-- print global attribute contents
   fout@$global_attnames(i)$ = fin@$global_attnames(i)$ ;-- write global attributes to new file
end do

dimNames = (/"time", "lat", "lon"  /)
dimSizes = (/ time_tot,  360,   720   /)
dimUnlim = (/ False, False,  False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; __________________ 1D ___________________
filevardef( fout, "time", "integer", "time")
fout->time@units         = "months since Jan 2002" ;
fout->time@long_name     = "time"
fout->time@standard_name = "time" ;
fout->time@axis          = "T" ;
fout->time@calendar      = "gregorian" ;
fout->time               = ispan(0,time_tot-1,1)

filevardef( fout, "lat", "float", "lat")
fout->lat@long_name     = "latitude"
fout->lat@standard_name = "latitude" ;
fout->lat@units         = "degrees_north" ;
fout->lat@axis          = "Y" ;
fout->lat@valid_min     = -89.75 ;
fout->lat@valid_max     = 89.75 ;
fout->lat               = fspan( -89.75, 89.75, 360)

filevardef( fout, "lon", "float", "lon")
fout->lon@long_name     = "longitude"
fout->lon@standard_name = "longitude"
fout->lon@units         = "degrees_east"
fout->lon@axis          = "X" ;
fout->lon@valid_min     = 0.25 ;
fout->lon@valid_max     = 359.75 ;
fout->lon               = fspan( 0.25, 359.75, 720)

; __________________ 2D ___________________
filevardef( fout, "lwe_thickness", "float", (/ "time", "lat", "lon" /))
fout->lwe_thickness@units         = "cm" ;
fout->lwe_thickness@long_name     = "Liquid_Water_Equivalent_Thickness" ;
fout->lwe_thickness@standard_name = "Liquid_Water_Equivalent_Thickness" ;
fout->lwe_thickness@coordinates   = "time lat lon" ;
fout->lwe_thickness@_FillValue    = -99999. ;
fout->lwe_thickness@grid_mapping  = "WGS84" ;
fout->lwe_thickness@valid_min     = -1634.03549712907 ;
fout->lwe_thickness@valid_max     = 802.820740928253 ;
fout->lwe_thickness@comment       = "Coastline Resolution Improvement (CRI) filter is applied" ;

filevardef( fout, "uncertainty", "float", (/ "time", "lat", "lon" /))
fout->uncertainty@units          = "cm" ;
fout->uncertainty@long_name      = "uncertainty" ;
fout->uncertainty@standard_name  = "uncertainty" ;
fout->uncertainty@coordinates    = "time lat lon" ;
fout->uncertainty@grid_mapping   = "WGS84" ;
fout->uncertainty@_FillValue     = -99999. ;
fout->uncertainty@valid_min      = 0.175191867765331 ;
fout->uncertainty@valid_max      = 53.3446959856009 ;
fout->uncertainty@comment        = "1-sigma uncertainty: not for each 0.5 degree grid cell, but for each 3-degree mascon estimate" ;

i         = 0
j         = 0
day_start = 0
day_end   = 0
time      = doubletofloat(fin->time)
lwe_thickness = doubletofloat(fin->lwe_thickness)
uncertainty   = doubletofloat(fin->uncertainty)
missing_value = fout->lwe_thickness@_FillValue

lwe_thickness_out = new((/time_tot,360,720/),float)
uncertainty_out   = new((/time_tot,360,720/),float)

do year = year_s, year_e
  print("year is "+year)
  if ( mod(year,4) .eq. 0) then
     dom = (/31,29,31,30,31,30,31,31,30,31,30,31/)
  else
     dom = (/31,28,31,30,31,30,31,31,30,31,30,31/)
  end if

  do month = 0, 11
    print("month is "+ month)
    day_end = day_start + dom(month) -1
    print(day_start+"-"+day_end)

    if year .eq. 2011 .and. month .eq. 11 then
      ; 2012 Jan has two observation, one is 1st Jan the other is 16th Jan, so give
      ; 1st Jan to Dec 2011
      print("i is "+i+"; time is "+time(i)+"; day_start is "+ day_start+ "; day_end is "+ day_end)
      lwe_thickness_out(j,:,:) = lwe_thickness(i,:,:)
      uncertainty_out(j,:,:)   = uncertainty(i,:,:)
      i = i + 1
      j = j + 1
    else if year .eq. 2015 .and. month .eq. 3 then
      ; 2015 April has two observation, thus use their average
      print("i is "+i+"; time is "+time(i)+"; day_start is "+ day_start+ "; day_end is "+ day_end)
      lwe_thickness_out(j,:,:) = (lwe_thickness(i,:,:) + lwe_thickness(i+1,:,:))/2.
      uncertainty_out(j,:,:)   = (uncertainty(i,:,:) + uncertainty(i+1,:,:))/2.
      i = i + 2
      j = j + 1
    else if (i .lt. grace_tot) .and. ( time(i) .gt. day_start-0.5 ) .and. ( time(i) .le. day_end+0.5 ) then
      print("i is "+i+"; time is "+time(i)+"; day_start is "+ day_start+ "; day_end is "+ day_end)
      lwe_thickness_out(j,:,:) = lwe_thickness(i,:,:)
      uncertainty_out(j,:,:)   = uncertainty(i,:,:)
      i = i + 1
      j = j + 1
    else
      if (i .lt. grace_tot) then
         print("i is "+i+"; time is "+time(i)+"; day_start is "+ day_start+ "; day_end is "+ day_end)
      end if
      lwe_thickness_out(j,:,:) = missing_value
      uncertainty_out(j,:,:)   = missing_value
      j = j + 1
    end if
    end if
    end if
    day_start = day_end + 1
  end do
end do
fout->lwe_thickness = lwe_thickness_out*1.
fout->uncertainty   = uncertainty_out*1.

wks = gsn_open_wks("pdf","./plots/Check")
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
x              = ispan(1,time_tot,1)
plot = gsn_csm_xy(wks,x,dim_avg_n_Wrap(fout->lwe_thickness(:,{-44:-28},{140:154}),(/1,2/)),res)

setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")

end
