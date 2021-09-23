;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: Regrid AWAP dataset from 5km resoluation to 10km 

; Change History:

; ______________________________________________________________________________


;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; ================================== Options ===================================
year_s    = 1970
year_e    = 2019
var_names = (/"LWdown","PSurf","Qair","Rainf","Snowf","SWdown","Tair","Wind"/)

path_in   = "/g/data/w35/Shared_data/AWAP_3h_v1/"
path_out  = "/g/data/w35/mm3972/data/AWAP_3h_v1_10km/"

; _________________ set range of lat and lon ______________________
lat_s = -44.
lat_e = -10.
lon_s = 112.
lon_e = 154.

nlat   = 341
nlon   = 421
lat_out= fspan( lat_s, lat_e, nlat)
lon_out= fspan( lon_s, lon_e, nlon)


do var_nm_num = 0, dimsizes(var_names) - 1 
  do year = year_s, year_e

    var_name = var_names(var_nm_num)
  
    fname_in  = path_in  + var_name + "/AWAP."+var_name+".3hr."+year+".nc"
    fname_out = path_out + var_name + "/AWAP."+var_name+".3hr."+year+".nc"

    fin    = addfile (fname_in, "r")     ; open input file
    lat_in = fin->lat
    lon_in = fin->lon
    time   = fin->time
    ntime  = dimsizes(time)

    system("/bin/rm -f " + fname_out)    ; remove if exists
    fout   = addfile (fname_out, "c")     ; open output file

    ; ================================ Edit NetCDF =================================
    ; explicitly declare file definition mode. Improve efficiency.
    setfileoption(fout,"DefineMode",True)

    ; create global attributes of the file
    fAtt               = True            ; assign file attributes
    fAtt@title         = "AWAP met forcing across AU in 10 km res, regridded from 5 km"

    fAtt@creation_date = systemfunc ("date")
    fileattdef( fout, fAtt )            ; copy file attributes

    dimNames = (/"time",  "lat" ,  "lon" /)
    dimSizes = (/ ntime,  nlat  ,  nlon  /)
    dimUnlim = (/ False,  False ,  False /)
    filedimdef(fout,dimNames,dimSizes,dimUnlim)

    ; __________________ 1D ___________________
    filevardef( fout, "time", typeof(fin->time),getvardims(fin->time))
    filevarattdef(fout,"time",fin->time)
    fout->time  = time*1.
    delete(time)

    filevardef( fout, "lat", typeof(fin->lat),getvardims(fin->lat))
    filevarattdef(fout,"lat",fin->lat)
    fout->lat = lat_out*1.

    filevardef( fout, "lon", typeof(fin->lon),getvardims(fin->lon))
    filevarattdef(fout,"lon",fin->lon)
    fout->lon = lon_out*1.

    filevardef( fout, var_name, typeof(fin->$var_name$), getvardims(fin->$var_name$))
    filevarattdef(fout,var_name,fin->$var_name$) ; 0:land, 1:sea
    var     = area_hi2lores( lon_in, lat_in, fin->$var_name$, False, 1, lon_out, lat_out, False)
    fout->$var_name$ = var*1.

    setfileoption(fout,"DefineMode",False)
    print("Exit DefineMode")
    delete(var)
    delete(var_name)
    delete(fAtt)
    delete(dimNames)
    delete(dimSizes)
    delete(dimUnlim)
  end do
end do
end
