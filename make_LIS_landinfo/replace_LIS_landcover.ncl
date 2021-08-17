;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

begin

filename  = "lis_input.d01.nc"
fin       = addfile(filename,"w")

SURFACETYPE1 = fin->SURFACETYPE(1,:,:)
SURFACETYPE5 = fin->SURFACETYPE(5,:,:)
LANDCOVER1   = fin->LANDCOVER(1,:,:)
LANDCOVER5   = fin->LANDCOVER(5,:,:)

printVarSummary(SURFACETYPE1)
printVarSummary(LANDCOVER5)

; 1: BEF, 5:C3 grassland
SURFACETYPE1 = where(SURFACETYPE5 .eq. 1., 1., SURFACETYPE1)
printVarSummary(SURFACETYPE1)
LANDCOVER1   = where(SURFACETYPE5 .eq. 1., LANDCOVER1 + LANDCOVER5, LANDCOVER1)
printVarSummary(LANDCOVER1)

fin->SURFACETYPE(1,:,:) = SURFACETYPE1*1.
fin->LANDCOVER(1,:,:)   = LANDCOVER1*1.
fin->SURFACETYPE(5,:,:) = 0.
fin->LANDCOVER(5,:,:)   = 0.


end
