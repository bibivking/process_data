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
lis_3D_names = (/\
				"Swnet_tavg","Lwnet_tavg","Qle_tavg","Qh_tavg","Qg_tavg","Snowf_tavg",     \
				"Rainf_tavg","Evap_tavg","Qs_tavg","Qsb_tavg","VegT_tavg",                 \
				"Albedo_inst","SWE_inst","SnowDepth_inst","LAI_inst",                      \
				"ECanop_tavg","TVeg_tavg","FWsoil_tavg","ESoil_tavg",                      \
				"CanopInt_inst","WaterTableD_tavg","Wind_f_inst",                          \
				"Rainf_f_inst","Tair_f_inst","Qair_f_inst",                                \
				"SWdown_f_inst","LWdown_f_inst","GWwb_tavg","AvgSurfT_tavg"                \
				/) ; ,"Psurf_f_inst", MMY: LIS doesn't need air pressure from AWAP since it is constant, (also units are different)

off_3D_names     = (/ \
					"SWnet","LWnet","Qle","Qh","Qg","Snowf",     \
					"Rainf","Evap","Qs","Qsb","VegT",            \
					"Albedo","SWE","SnowDepth","LAI",            \
					"ECanop","TVeg","Fwsoil","ESoil",            \
					"CanopInt","WatTable","Wind",                \
					"Rainf","Tair","Qair",                       \
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


; ================================== Path & Filename ===================================

; +++++++++++++++++++++++++++++++++ Note +++++++++++++++++++++++++++++++++
; 1. Time zone difference between WRF-CABLE & AWAP
;    WRF-CABLE uses UTC time, but AWAP uses local time (AEST).
;    The UTC time is 10 hours later than the AEST (Australian
;    Eastern Standard Time). However, AEST doesn't equate to
;    Australian Eastern Daylight Time (AEDT) in summers. AEDT
;    is 1 hour earlier than AEST.
;
; 2. Time step and local time in offline CABLE:
;    model time step : 0, 1, 2, 3 , 4 , 5,  6,  7
;    real world time : 0, 3, 6, 9, 12, 15, 18, 21
;
; 2. Name the lis_hist output file by the start day of the coupled simulation
;
; 3. the same as restart file. Here, use the simulation of UTC 11am of day x
; as the simulation of UTC 12pm of day x (middle night after the day).
; Thus, there are 13 hours without simulating.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ; =========== 28th Jan 2009 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2009","2009","2009","2009","2009" /)
; slct_mon_off      = (/  "01",  "01",  "01",  "01",  "01" /)
; slct_day_off      = (/  "13",  "15",  "17",  "19",  "21" /)
; slct_doy          = (/    13,    15,    17,    19,   21  /)
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
; slct_doy          = (/    15,    17,    19,    21,   23  /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2011","2011","2011","2011","2011"/)
; slct_mon          = (/  "01",  "01",  "01", "01",  "01" /)
; slct_day          = (/  "15",  "17",  "19",  "21",  "23"/)

; =========== 1th Jan 2013 ===========
; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; Offline CABLE: one day before the targeted restart date
slct_year_off     = (/"2012","2012","2012","2012","2012" /)
slct_mon_off      = (/  "12",  "12",  "12",  "12",  "12" /)
slct_day_off      = (/  "17",  "19",  "21",  "23",  "25" /)
slct_doy          = (/  4735,  4737,  4739,  4741,  4743 /)

; LIS-CABLE, UTC
slct_year         = (/"2012","2012","2012","2012","2012"/)
slct_mon          = (/  "12",  "12",  "12", "12",  "12" /)
slct_day          = (/  "17",  "19",  "21",  "23",  "25"/)


; ; =========== 13th Jan 2014 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2013","2013","2014","2014","2014" /)
; slct_mon_off      = (/  "12",  "12",  "01",  "01",  "01" /)
; slct_day_off      = (/  "29",  "31",  "02",  "04",  "06" /)
; slct_doy          = (/   363,   365,     2,    4,    6  /)

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
; slct_doy          = (/  6226,  6228,  6230,  6232,  6234 /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2017","2017","2017","2017","2017"/)
; slct_mon          = (/  "01",  "01",  "01", "01",  "01" /)
; slct_day          = (/  "16",  "18",  "20",  "22",  "24"/)


; ; =========== 12th Jan 2019 ===========
; ; Emsemble: 14, 12, 10, 8, 6 days before heatwaves

; ; Offline CABLE: one day before the targeted restart date
; slct_year_off     = (/"2018","2018","2019","2019","2019" /)
; slct_mon_off      = (/  "12",  "12",  "01",  "01",  "01" /)
; slct_day_off      = (/  "28",  "30",  "01",  "03",  "05" /)
; slct_doy          = (/  6937,  6939,  6941,  6943,  6945 /)

; ; LIS-CABLE, UTC
; slct_year         = (/"2018","2018","2019","2019","2019"/)
; slct_mon          = (/  "12",  "12",  "01", "01",  "01" /)
; slct_day          = (/  "28",  "30",  "01", "03",  "05" /)


slct_event_sum    = dimsizes(slct_year)

; ================================== Path & Filename ===================================
case_name         = "fd" ;"gw" ; "fd"

lis_path_in       = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/offline_rst_output/prototype/"
lis_path_out      = "/g/data/w35/mm3972/model/wrf/NUWRF/LISWRF_configs/offline_rst_output/"+case_name+"/"
off_path_in       = "/g/data/w35/mm3972/model/cable/runs/runs_4_coupled/"+case_name+"_after_sp30yrx3/outputs/"

lis_file_hist_in  = lis_path_in + "LIS.CABLE.200812-200812.d01.nc"


off_file_output_in= off_path_in  + "cable_out_2000-2019.nc"
print("off_file_output_in is "+off_file_output_in)

do slct_event_num = 0, slct_event_sum - 1

	lis_file_hist_out = lis_path_out + "LIS.CABLE."+slct_year(slct_event_num)+slct_mon(slct_event_num)+slct_day(slct_event_num)+"110000.d01.nc"
	print("lis_file_hist_out is "+lis_file_hist_out)

	system("cp "+lis_file_hist_in+" "+lis_file_hist_out)

	; _________________ set range of lat and lon ______________________

	flis   = addfile (lis_file_hist_out, "w")     ; open output file
	foff   = addfile (off_file_output_in, "r")     ; open output file

	def_lis = -9999.
	def_off = -1.e+33

	ntime_lis  = dimsizes(flis->time)
	ntime_off  = slct_doy(slct_event_num) - 1
	lis_lat    = flis->lat
	lis_lon    = flis->lon
	off_lat    = foff->latitude
	off_lon    = foff->longitude
	off_lat_1D = ndtooned(off_lat)
	off_lon_1D = ndtooned(off_lon)

	flis->time@units = "days since "+slct_year_off(slct_event_num)+"-"+slct_mon_off(slct_event_num)+"-"+slct_day_off(slct_event_num)+" 11:00:00"
	flis->time = 0

	do var_num = 0, dimsizes(lis_3D_names) - 1
		print(off_3D_names(var_num))
		if off_3D_names(var_num) .eq. "WatTable" then
			tmp     = ndtooned(foff->$off_3D_names(var_num)$(ntime_off,:,:))*1000.
		else
			tmp     = ndtooned(foff->$off_3D_names(var_num)$(ntime_off,:,:))
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
		tmp         = ndtooned(foff->$off_4D_names(var_num)$(ntime_off,soil_num,:,:))
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
end do ; slct_event_num

end
