;****************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; # make landsea file for GSWP3 over Australia, out of Australia = 1 (sea)

; author  = MU Mengyuan
; email   = mu.mengyuan815@gmail.com
; version = 2020.7.13


;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin
; __________________________ PLOT SETTING ____________________________
pic = "check_landmask"
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"rainbow");"WhiteBlueGreenYellowRed")

res                    = True
res@cnFillMode         = "RasterFill"            ; Raster Mode
res@cnFillOn           = True
res@tmBorderThicknessF = 3.0

res@gsnDraw            = True  ; Don't draw plots
res@gsnFrame           = True
res@lbLabelBarOn       = True

; __________________________ Preparing ____________________________

filename = "land_MSWEP.nc/srv/ccrc/data25/z5218916/script/reproduce_gridfile/gridinfo_mmy_MD_elev_orig_std_avg-sand_AU_landmask.nc"
filename1 = "/srv/ccrc/data25/z5218916/script/reproduce_gridfile/gridinfo_mmy_MD_elev_orig_std_avg-sand_landmask.nc"

print("openfile")
; read the GSWP3 landsea data
f1 = addfile (filename1,"r")
landsea = f1->landsea
delete(f1)
printVarSummary(landsea)

; make the GSWP3 landsea over Australia
f  = addfile (filename,"w")

printVarSummary(f->landsea)
print("plotting")

; Australia border
lat_n = -10
lat_s = -44
lon_w = 112
lon_e = 154

f->landsea = 1       ; sea
f->landsea({lat_s:lat_n},{lon_w:lon_e}) = landsea({lat_s:lat_n},{lon_w:lon_e})

print("start to plot")

plot = gsn_csm_contour(wks,f->landsea,res)
plot = gsn_csm_contour(wks,landsea,res)

end
