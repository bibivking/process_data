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

; __________________________ Preparing ____________________________

filename = "/g/data/w35/mm3972/model/cable/src/CABLE-AUX/offline/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix_6layer_uniform.nc"

f  = addfile (filename,"w")


do i = 0, 5
  f->swilt_vec(i,:,:)   = f->swilt*1.
  f->rhosoil_vec(i,:,:) = f->rhosoil*1.
  f->sand_vec(i,:,:)    = f->sand*1.
  f->clay_vec(i,:,:)    = f->clay*1.
  f->silt_vec(i,:,:)    = f->silt*1.
  f->org_vec(i,:,:)     = f->organic*1.
  f->bch_vec(i,:,:)     = f->bch*1.
  f->sucs_vec(i,:,:)    = f->sucs*1.
  f->ssat_vec(i,:,:)    = f->ssat*1.
  f->sfc_vec(i,:,:)     = f->sfc*1.
	f->css_vec(i,:,:)     = f->css*1.
  f->cnsd_vec(i,:,:)    = f->cnsd*1.
  f->hyds_vec(i,:,:)    = f->hyds*1000.
end do

end
