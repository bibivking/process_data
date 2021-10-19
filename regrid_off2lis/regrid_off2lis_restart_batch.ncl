;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: Regrid Offline CABLE restart file to LIS-CABLE resolution
; ______________________________________________________________________________


;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; ================================== Options ===================================
; LIS dimensions(sizes): ntiles(12306), dim1(6), dim2(6), dim3(3), dim4(3), dim5(2), time(1)
lis_2D_names      = (/"lat", "lon"/)

lis_1D_names      = (/"CANSTO", "RTSOIL", "SSDNN", "SNOWD","OSNOWD", "SNAGE",  \
          				    "WBTOT", "GWWB", "TSS", "GA"/)

lis_2D_lvl6_names = (/"WBICE", "TGG", "WB","GAMMZZ"/) ; "WATR","SSAT_HYS",

lis_2D_lvl3_names = (/"TGGSN","SMASS","SSDN","ALBSOILSN","ALBSOIL","CPLANT"/)

lis_2D_lvl2_names = (/"CSOIL"/)

lis_var_keep      = (/ "KTAU","PUDSTO", "PUDSMX","OTSS", "WTD","OWETFAC", "US", \
                       "RTEVAP_SAT", "RTEVAP_UNSAT", "SATFRAC","RH_SRF", "ISFLAG" /)

; OFF dimensions(sizes): mland(66230), mp(66230), soil(6), snow(3), rad(3), soil_carbon_pools(2), plant_carbon_pools(3), time(1)
off_2D_names      = (/"latitude", "longitude"/)

off_1D_names      = (/ "cansto","rtsoil","ssdnn","snowd","osnowd","snage",\
                       "wbtot0", "GWwb","tss","ga" /) ; int32 "isflag", "wbtot0"???

off_2D_lvl6_names = (/ "wbice", "tgg","wb", "gammzz"/) ; "wb", "gammzz" are double format; "watr_hys","ssat_hys",

off_2D_lvl3_names = (/"tggsn","smass","ssdn","albsoilsn","albsoil","cplant"/)

off_2D_lvl2_names = (/"csoil"/)


; =================================== Dates selection ==================================

; ; =========== 28th Jan 2009 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2009","2009","2009","2009","2009" /)
; slct_mon_off      = (/  "01",  "01",  "01",  "01",  "01" /)
; slct_day_off      = (/  "13",  "15",  "17",  "19",  "21" /)
; slct_doy          = (/    14,    16,    18,    20,   22  /)
; ; Here, slct_doy should always be 1 day later than slct_day
; ; Here, "2009-01-13" means the simulation at 2009-01-13 21:00:00 AEST

; ; LIS-CABLE, UTC
; slct_year         = (/"2009","2009","2009","2009","2009"/)
; slct_mon          = (/  "01",  "01",  "01", "01",  "01" /)
; slct_day          = (/  "13",  "15",  "17", "19",  "21" /)
; ; Here, "2009-01-13" means the simulation at 2009-01-13 11:00:00 UTC


; ; =========== 30th Jan 2011 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2011","2011","2011","2011","2011" /)
; slct_mon_off      = (/  "01",  "01",  "01",  "01",  "01" /)
; slct_day_off      = (/  "15",  "17",  "19",  "21",  "23" /)
; slct_doy          = (/    16,    18,    20,    22,   24  /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2011","2011","2011","2011","2011"/)
; slct_mon          = (/  "01",  "01",  "01", "01",  "01" /)
; slct_day          = (/  "15",  "17",  "19",  "21",  "23"/)

; ; =========== 1th Jan 2013 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2012","2012","2012","2012","2012" /)
; slct_mon_off      = (/  "12",  "12",  "12",  "12",  "12" /)
; slct_day_off      = (/  "17",  "19",  "21",  "23",  "25" /)
; slct_doy          = (/   352,   354,   356,   358,  360  /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2012","2012","2012","2012","2012"/)
; slct_mon          = (/  "12",  "12",  "12", "12",  "12" /)
; slct_day          = (/  "17",  "19",  "21",  "23",  "25"/)


; ; =========== 13th Jan 2014 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2013","2013","2014","2014","2014" /)
; slct_mon_off      = (/  "12",  "12",  "01",  "01",  "01" /)
; slct_day_off      = (/  "29",  "31",  "02",  "04",  "06" /)
; slct_doy          = (/   364,   366,     3,    5,    7  /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2013","2013","2014","2014","2014"/)
; slct_mon          = (/  "12",  "12",  "01",  "01",  "01"/)
; slct_day          = (/  "29",  "31",  "02",  "04",  "06"/)


; ; =========== 31st Jan 2017 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2017","2017","2017","2017","2017" /)
; slct_mon_off      = (/  "01",  "01",  "01",  "01",  "01" /)
; slct_day_off      = (/  "16",  "18",  "20",  "22",  "24" /)
; slct_doy          = (/    17,    19,    21,    23,   25  /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2017","2017","2017","2017","2017"/)
; slct_mon          = (/  "01",  "01",  "01", "01",  "01" /)
; slct_day          = (/  "16",  "18",  "20",  "22",  "24"/)


; =========== 12th Jan 2019 ===========
; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; Offline CABLE: one day before the targeted restart date
slct_year_off     = (/"2018","2018","2019","2019","2019" /)
slct_mon_off      = (/  "12",  "12",  "01",  "01",  "01" /)
slct_day_off      = (/  "28",  "30",  "01",  "03",  "05" /)
slct_doy          = (/   363,   365,     2,     4,   6   /)

; LIS-CABLE, UTC
slct_year         = (/"2018","2018","2019","2019","2019"/)
slct_mon          = (/  "12",  "12",  "01", "01",  "01" /)
slct_day          = (/  "28",  "30",  "01", "03",  "05" /)


slct_event_sum    = dimsizes(slct_year)

; ================================== Path & Filename ===================================
case_name         = "fd" ;"gw";"fd"

lis_path_in       = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/offline_rst_output/prototype/"
lis_path_out      = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/offline_rst_output/"+case_name+"/"
off_path_in       = "/g/data/w35/mm3972/model/cable/runs/runs_4_coupled/"+case_name+"_after_sp30yrx3/restarts/"


lis_file_rst_in   = lis_path_in + "LIS_RST_CABLE_200812210000.d01.nc"

; Read lat, lon, mask from LIS_HIST file
lis_file_hist_in  = lis_path_in + "LIS.CABLE.200812-200812.d01.nc"
flis_his = addfile (lis_file_hist_in, "r")     ; open output file

lis_lat    = flis_his->lat
lis_lon    = flis_his->lon
lis_mask   = flis_his->Landmask_inst(0,:,:)

do slct_event_num = 0, slct_event_sum - 1

  ; the time of the daily restart file is 9pm in AEST and 11am in UTC
  ; however, since wrf cannot start from the time except the start of a day,
  ; we here need to use the offline restart at UTC 11am of day x 
  ; to initilize UTC 12am of day x+1 (middle night before morning).
  ; Thus, there are 13 hours without simulating

  lis_file_rst_out  = lis_path_out + "LIS_RST_CABLE_"+slct_year(slct_event_num)+slct_mon(slct_event_num)+slct_day(slct_event_num)+"1100.d01.nc"
  print("lis_file_rst_out is "+lis_file_rst_out)
  off_file_rst_in   = off_path_in  + "restart_"+slct_year_off(slct_event_num)+".nc_Day"+slct_doy(slct_event_num)
  print("off_file_rst_in is "+off_file_rst_in)
  system("cp "+lis_file_rst_in+" "+lis_file_rst_out)

  ; _________________ set range of lat and lon ______________________
  flis     = addfile (lis_file_rst_out, "w")     ; open output file
  foff     = addfile (off_file_rst_in, "r")     ; open output file

  def_lis  = -9999.
  def_off  = -1.e+33

  off_lat  = foff->latitude
  off_lon  = foff->longitude

  lis_mask_1D   = ndtooned(lis_mask)
  lis_mask_keep = ind(lis_mask_1D .eq. 1.)

	flis->time@units = "minutes since "+slct_year(slct_event_num)+"-"+slct_mon(slct_event_num)+"-"+slct_day(slct_event_num)+" 11:00:00"
	flis->time@time_increment = "3600"
  flis->time@begin_date = slct_year(slct_event_num)+slct_mon(slct_event_num)+slct_day(slct_event_num)
	flis->time@begin_time = "110000" 

  do var_num = 0, dimsizes(lis_1D_names) - 1
    print(off_1D_names(var_num))
    tmp           = foff->$off_1D_names(var_num)$
    var_tmp       = triple2grid2d(off_lon, off_lat, tmp, lis_lon,lis_lat, False)
    var_tmp_1D    = ndtooned(var_tmp)
    flis->$lis_1D_names(var_num)$ = var_tmp_1D(lis_mask_keep)
  end do
  delete(tmp)
  delete(var_tmp)
  delete(var_tmp_1D)

  do var_num = 0, dimsizes(lis_2D_lvl6_names) - 1
    print(off_2D_lvl6_names(var_num))
    lis_tmp = flis->$lis_2D_lvl6_names(var_num)$ * 1.
    do soil_num = 0,5
      tmp = tofloat(foff->$off_2D_lvl6_names(var_num)$(soil_num,:))
      var_tmp      = triple2grid2d(off_lon, off_lat, tmp, lis_lon,lis_lat, False)
      var_tmp_1D   = ndtooned(var_tmp)
      lis_tmp(soil_num,:) = var_tmp_1D(lis_mask_keep)
    end do
    flis->$lis_2D_lvl6_names(var_num)$ = lis_tmp
  end do
  delete(tmp)
  delete(var_tmp)
  delete(var_tmp_1D)
  delete(lis_tmp)

  do var_num = 0, dimsizes(lis_2D_lvl3_names) - 1
    print(off_2D_lvl3_names(var_num))
    lis_tmp = flis->$lis_2D_lvl3_names(var_num)$ * 1.
    do soil_num = 0,2
      tmp          = foff->$off_2D_lvl3_names(var_num)$(soil_num,:)
      var_tmp      = triple2grid2d(off_lon, off_lat, tmp, lis_lon,lis_lat, False)
      var_tmp_1D   = ndtooned(var_tmp)
      lis_tmp(soil_num,:) = var_tmp_1D(lis_mask_keep)
    end do
    flis->$lis_2D_lvl3_names(var_num)$ = lis_tmp
  end do
  delete(tmp)
  delete(var_tmp)
  delete(var_tmp_1D)
  delete(lis_tmp)

  do var_num = 0, dimsizes(lis_2D_lvl2_names) - 1
    print(off_2D_lvl3_names(var_num))
    lis_tmp = flis->$lis_2D_lvl2_names(var_num)$ * 1.
    do soil_num = 0,1
      tmp          = foff->$off_2D_lvl2_names(var_num)$(soil_num,:)
      var_tmp      = triple2grid2d(off_lon, off_lat, tmp, lis_lon,lis_lat, False)
      var_tmp_1D   = ndtooned(var_tmp)
      lis_tmp(soil_num,:) = var_tmp_1D(lis_mask_keep)
    end do
    flis->$lis_2D_lvl2_names(var_num)$ = lis_tmp
  end do
  delete(tmp)
  delete(var_tmp)
  delete(var_tmp_1D)
  delete(lis_tmp)

end do ; slct_case_num

end
