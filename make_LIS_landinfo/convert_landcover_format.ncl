load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

; ================================ read data ===================================
; setfileoption("bin","ReadByteOrder","BigEndian")
; NCAR_path = "/g/data/w35/LIS/LIS_PARAMS/LIS_PARAMS/UMD/1KM/landcover_CABLE_NCAR.1gd4r"
; NCAR_LC   = fbindirread (NCAR_path, 0, (/15000,36000/), "float") ;
; print(NCAR_LC)

; ============================= testing plot ===================================
wks = gsn_open_wks("pdf","Check_LC")
gsn_define_colormap(wks,"drought_severity")

res                         = True
res@gsnDraw                 = True
res@gsnFrame                = True
res@gsnMaximize             = False
res@cnFillMode              = "RasterFill"            ; Raster Mode
res@cnFillOn                = True
res@cnLinesOn               = False
;
; plot = gsn_csm_contour(wks,NCAR_LC,res)


DLCD_in = "/g/data/w35/mm3972/data/Dynamic_land_cover_maps/Dynamic_land_cover_dataset_CABLE.nc"
DLCD    = addfile(DLCD_in,"r")
DLCD_LC = where( .not. ismissing(DLCD->iveg(::-1,:)), DLCD->iveg, 16)
DLCD_LC = where( DLCD_LC < 0, 16, DLCD_LC)
DLCD_LC_int = tointeger(DLCD_LC)
DLCD_LC_int@_FillValue = 16
printVarSummary(DLCD_LC_int)
;Defvalue = -3.4e+38
;print(any(DLCD_LC .ne. 16))
;DLCD_LC = where(DLCD_LC .eq. Defvalue, 16, DLCD_LC)

setfileoption("bin","WriteByteOrder","BigEndian")
DLCD_out = "Dynamic_land_cover_dataset_CABLE.1gd4r"
system("rm "+ DLCD_out)
fbindirwrite(DLCD_out,DLCD_LC_int)
print(max(DLCD_LC_int))
print(min(DLCD_LC_int))

; setfileoption("bin","ReadByteOrder","BigEndian")
; NCAR_path = "Dynamic_land_cover_dataset_CABLE"
; NCAR_LC   = fbindirread (NCAR_path, 0, (14902,19161/), "float") ;
; printVarSummary(NCAR_LC)
; plot      = gsn_csm_contour(wks,NCAR_LC,res)

end
