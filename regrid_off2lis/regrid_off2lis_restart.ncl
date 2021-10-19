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
fname_lis_in      = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/ctl_26Sep/LIS_output/LIS_RST_CABLE_200101010000.d01.nc"
fname_lis_hist    = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/ctl_26Sep/LIS_output/LIS.CABLE.200012-200012.d01.nc"
fname_lis_out     = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/ctl_26Sep/LIS_output/LIS_RST_CABLE_200101010000_off-gw.d01.nc"
fname_off_in      = "/g/data/w35/mm3972/model/cable/runs/sanaa_run/test_fix_satfrac_10km/restarts/restart_2019.nc"

system("cp "+fname_lis_in+" "+fname_lis_out)

; LIS dimensions(sizes): ntiles(12306), dim1(6), dim2(6), dim3(3), dim4(3), dim5(2), time(1)

lis_2D_names      = (/"lat", "lon"/)

lis_1D_names      = (/"CANSTO", "RTSOIL", "SSDNN", "SNOWD","OSNOWD", "SNAGE",  \
          				    "WBTOT", "GWWB", "TSS", "GA"/)

lis_2D_lvl6_names = (/"WBICE", "TGG", "WB","GAMMZZ"/) ; "WATR","SSAT_HYS",

lis_2D_lvl3_names = (/"TGGSN","SMASS","SSDN","ALBSOILSN","ALBSOIL","CPLANT"/)

lis_2D_lvl2_names = (/"CSOIL"/)

lis_var_keep      = (/ "KTAU","PUDSTO", "PUDSMX","OTSS", "WTD","OWETFAC", "US", \
                      "RTEVAP_SAT", "RTEVAP_UNSAT", "SATFRAC","RH_SRF","ISFLAG" /)

; OFF dimensions(sizes): mland(66230), mp(66230), soil(6), snow(3), rad(3), soil_carbon_pools(2), plant_carbon_pools(3), time(1)

off_2D_names      = (/"latitude", "longitude"/)

off_1D_names      = (/ "cansto","rtsoil","ssdnn","snowd","osnowd","snage",\
                       "wbtot0", "GWwb","tss","ga" /) ; int32 "isflag", "wbtot0"???

off_2D_lvl6_names = (/ "wbice", "tgg","wb", "gammzz"/) ; "wb", "gammzz" are double format; "watr_hys","ssat_hys",

off_2D_lvl3_names = (/"tggsn","smass","ssdn","albsoilsn","albsoil","cplant"/)

off_2D_lvl2_names = (/"csoil"/)

; _________________ set range of lat and lon ______________________
flis     = addfile (fname_lis_out, "w")     ; open output file
foff     = addfile (fname_off_in, "r")     ; open output file
flis_his = addfile (fname_lis_hist, "r")     ; open output file

def_lis = -9999.
def_off = -1.e+33

off_lat    = foff->latitude
off_lon    = foff->longitude
lis_lat    = flis_his->lat
lis_lon    = flis_his->lon
lis_mask   = flis_his->Landmask_inst(0,:,:)

lis_mask_1D   = ndtooned(lis_mask)
lis_mask_keep = ind(lis_mask_1D .eq. 1.)

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

end
