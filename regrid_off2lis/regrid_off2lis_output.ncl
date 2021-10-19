;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: Regrid Offline CABLE output to LIS-CABLE resolution
; ______________________________________________________________________________


;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; ================================== Options ===================================

fname_lis_in      = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/ctl_26Sep/LIS_output/LIS.CABLE.200012-200012.d01.nc"
; fname_lis_out     = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/ctl_26Sep/LIS_output/LIS.CABLE.200012-200012_off-GW.d01.nc"
fname_lis_out     = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/ctl_26Sep/LIS_output/LIS.CABLE.200012-200012_off-fd.d01.nc"
fname_off_in      = "/g/data/w35/mm3972/model/cable/runs/sanaa_run/test_fix_satfrac_10km_fd/outputs/cable_out_2000.nc"

system("cp "+fname_lis_in+" "+fname_lis_out)

lis_3D_names = (/\
				"Swnet_tavg","Lwnet_tavg","Qle_tavg","Qh_tavg","Qg_tavg","Snowf_tavg",     \
				"Rainf_tavg","Evap_tavg","Qs_tavg","Qsb_tavg","VegT_tavg",                 \
				"Albedo_inst","SWE_inst","SnowDepth_inst","LAI_inst",                      \
				"ECanop_tavg","TVeg_tavg","FWsoil_tavg","ESoil_tavg",                      \
				"CanopInt_inst","WaterTableD_tavg","Wind_f_inst",                          \
				"Rainf_f_inst","Tair_f_inst","Qair_f_inst",                 \
				"SWdown_f_inst","LWdown_f_inst","GWwb_tavg","AvgSurfT_tavg"                \
				/) ; ,"Psurf_f_inst", MMY: LIS doesn't need air pressure from AWAP since it is constant, (also units are different)

off_3D_names     = (/ \
					"SWnet","LWnet","Qle","Qh","Qg","Snowf",     \
					"Rainf","Evap","Qs","Qsb","VegT",            \
					"Albedo","SWE","SnowDepth","LAI",            \
					"ECanop","TVeg","Fwsoil","ESoil",            \
					"CanopInt","WatTable","Wind",                \
					"Rainf","Tair","Qair",               \
					"SWdown","LWdown","GWMoist","RadT"           \
			  	  /) ; "PSurf",

lis_4D_names = (/"SoilMoist_inst", "SoilTemp_inst"/)

off_4D_names = (/"SoilMoist",  "SoilTemp"/)

lis_keep_names   = (/"Landmask_inst","SoilColor_inst","Elevation_inst","SnowCover_inst","SmFrozFrac_inst"/)

lis_3D_para_names = (/\
				"Soiltype_inst","Landcover_inst","SandFrac_inst","ClayFrac_inst","SiltFrac_inst",           \
				"SoilFieldCap_inst","SoilSat_inst","SoilWiltPt_inst","Hyds_inst","Bch_inst","Sucs_inst"/)

off_3D_para_names = (/ \
					"isoil","iveg","sand","clay","silt",      \
					"sfc","ssat","swilt","hyds", "bch","sucs" \
					/)



; _________________ set range of lat and lon ______________________

flis   = addfile (fname_lis_out, "w")     ; open output file
foff   = addfile (fname_off_in, "r")     ; open output file

def_lis = -9999.
def_off = -1.e+33

ntime_lis  = dimsizes(flis->time)
ntime_off  = dimsizes(foff->time)
lis_lat    = flis->lat
lis_lon    = flis->lon
off_lat    = foff->latitude
off_lon    = foff->longitude
off_lat_1D = ndtooned(off_lat)
off_lon_1D = ndtooned(off_lon)

do var_num = 0, dimsizes(lis_3D_names) - 1
    print(off_3D_names(var_num))
	if off_3D_names(var_num) .eq. "WatTable" then
    	tmp         = ndtooned(foff->$off_3D_names(var_num)$(ntime_off-1,:,:))*1000.
	else
		tmp         = ndtooned(foff->$off_3D_names(var_num)$(ntime_off-1,:,:))
	end if
    tmp_var     = triple2grid2d(off_lon_1D,off_lat_1D,tmp, lis_lon,lis_lat, False)
	flis->$lis_3D_names(var_num)$(ntime_lis-1,:,:) \
	            = where( tmp_var .eq. def_off, def_lis, tmp_var )
end do
delete(tmp)
delete(tmp_var)

do var_num = 0, dimsizes(lis_4D_names) - 1
    print(off_4D_names(var_num))
    do soil_num = 0,5
      tmp         = ndtooned(foff->$off_4D_names(var_num)$(ntime_off-1,soil_num,:,:))
	  tmp_var     = triple2grid2d(off_lon_1D,off_lat_1D,tmp, lis_lon, lis_lat, False)
      flis->$lis_4D_names(var_num)$(ntime_lis-1,soil_num,:,:) \
	              = where( tmp_var .eq. def_off, def_lis, tmp_var )
    end do
end do
delete(tmp)
delete(tmp_var)

; calculate RelSMC_inst
SM_lis = flis->SoilMoist_inst(ntime_lis-1,:,:,:)
ssat   = flis->SoilSat_inst(0:5,:,:)
swilt  = flis->SoilWiltPt_inst(0:5,:,:)

SM_lis@_FillValue = def_lis
ssat@_FillValue   = def_lis
swilt@_FillValue  = def_lis

printVarSummary(SM_lis)
printVarSummary(ssat)
printVarSummary(swilt)

relsmc = (SM_lis - swilt) / (ssat - swilt)
printVarSummary(relsmc)
relsmc = where( relsmc .gt. 1.0,   1.0, relsmc)
printVarSummary(relsmc)
relsmc = where( relsmc .lt. 0.01, 0.01, relsmc)
printVarSummary(relsmc)

flis->RelSMC_inst(ntime_lis-1,:,:,:) = relsmc*1.

; calculate SoilWet_inst

zse = (/0.022, 0.058, 0.154, 0.409, 1.085, 2.872/)
SMice_lis = SM_lis
printVarSummary(SMice_lis)
SMice_lis = SMice_lis * 0.
printVarSummary(SMice_lis)
avail_sm_mm = SMice_lis(0,:,:)
printVarSummary(SMice_lis)

do l=0,5
    avail_smoist = where( (SM_lis(l,:,:) -SMice_lis(l,:,:) - swilt(l,:,:)) .gt. 0.0, SM_lis(l,:,:) -SMice_lis(l,:,:) - swilt(l,:,:), 0.0)
    avail_sm_mm  = avail_sm_mm + avail_smoist*1000.0*zse(l)
end do
soilwet = avail_sm_mm/((ssat(0,:,:)-swilt(0,:,:))*sum(zse))
printVarSummary(soilwet)
flis->SoilWet_inst(ntime_lis-1,:,:) = soilwet*1.

; calculate SmLiqFrac_inst
wblf   = (SM_lis-SMice_lis)/ssat
printVarSummary(soilwet)
flis->SmLiqFrac_inst(ntime_lis-1,:,:,:)  = where(wblf .lt. 0.01, 0.01, wblf)

end
