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

year_s    = 1970
year_e    = 2019

day_sum = 0
do year = year_s,year_e
  if ( mod(year,4) .eq. 0) then
     day_sum = day_sum + 366
  else
     day_sum = day_sum + 365
  end if
end do

filename  = "/g/data/w35/mm3972/scripts/ehfheatwaves/EHF_heatwaves_daily.nc"
fin       = addfile (filename,"r")

system("rm -rf /g/data/w35/mm3972/scripts/ehfheatwaves/HW_Event_Indicator_"+year_s+"-"+year_e+".nc") ;-- delete file

filename1 = "/g/data/w35/mm3972/scripts/ehfheatwaves/HW_Event_Indicator_"+year_s+"-"+year_e+".nc"
fout      = addfile (filename1,"c")

; ================================ Edit NetCDF =================================
; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "Heatwave Event Indicator (only summer heatwaves)"

; copy all global attributes from input file
global_attnames = getvaratts(fin)

do i = 0,dimsizes(global_attnames)-1
   print(fin@$global_attnames(i)$) ;-- print global attribute contents
   fout@$global_attnames(i)$ = fin@$global_attnames(i)$ ;-- write global attributes to new file
end do

dimNames = (/"time" , "lat", "lon"  /)
dimSizes = (/day_sum,   241,  281   /)
dimUnlim = (/ False,  False,  False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; __________________ define var ___________________
filevardef( fout, "time", "integer", "time")
fout->time@units         = "days since 1970-01-01" ;
fout->time@standard_name = "time"
fout->time               = ispan(0,day_sum-1,1)

filevardef( fout, "lat", "float", "lat")
fout->lat@standard_name = "latitude" ;
fout->lat@long_name     = "Latitude" ;
fout->lat@units         = "degrees_north" ;
fout->lat               = doubletofloat(fin->lat(::-1))

filevardef( fout, "lon", "float", "lon")
fout->lon@standard_name = "longitude" ;
fout->lon@long_name     = "Longitude" ;
fout->lon@units         = "degrees_east" ;
fout->lon               = doubletofloat(fin->lon)

filevardef( fout, "event", "float", (/ "time", "lat", "lon" /))
fout->event@_FillValue    = -888.88 ;
fout->event@long_name     = "Event indicator" ;
fout->event@description   = "Indicates whether a summer heatwave is happening on that day" ;
fout->event@missing_value = -999.99 ;

event       = new((/day_sum,241,281/), float)
event_input = doubletofloat(fin->event)*1.
delete(fin)

day_s = 0
day_s2= 0
do year = year_s,year_e
  print("year = "+ year)
  if ( mod(year,4) .eq. 0) then
     yr_tot_day = 366
  else
     yr_tot_day = 365
  end if
  event(day_s:day_s+58,: , :)                            = event_input(day_s2:day_s2+58,:,:)*1.
  event(day_s+59:day_s+yr_tot_day-1-31,: , :)            = 0.
  event(day_s+yr_tot_day-1-30:day_s+yr_tot_day-1,: , :)  = event_input(day_s2+364-30:day_s2+364,:,:)*1.

  day_s = day_s + yr_tot_day
  day_s2= day_s2 + 365
end do
fout->event = event
delete(event)

wks = gsn_open_wks("pdf","Check")
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
; x              = ispan(1,192,1)
plot           = gsn_csm_contour(wks,fout->event(day_sum-1,:,:),res)

setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")

end
