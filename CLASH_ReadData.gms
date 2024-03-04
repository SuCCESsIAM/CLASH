$ontext

This file reads input data for CLASH core from GDX files, which produced by the ecological module, and from separate input text files

$offtext

* OBTAIN EXOGENOUS PARAMETER VALUES FOR CALCULATIONS:
* - primary forest carbon density
* - secondary forest carbon density
* - forest disturbance probability
* - initial area by land pool and land use
* - initial area of secondary forest by age classes and land pool


*Load the parametrization from the ecological module
$gdxin %CLASHdir%CLASH_Parametrization_%CLASH_Param%.gdx
$load  LU_Cdens, LU_Cdens_SecnFor, LU_DistProbSecnF
$load  LU_Crop_Yields, LU_Pasture_NPP
$load  LU_LitterHarv, LU_LitterPrimFor, LU_LitterSecdFor, LU_LitterWoodToSoilC, LU_LitterWoodDecay, LU_SoilCWoodDecay        
$load  LU_LitterCropland, LU_LitterPasture, LU_LitterHerbToSoilC, LU_LitterHerbDecay, LU_SoilCHerbDecay
$load  LU_InitCdensityCropland, LU_InitCdensityForest, LU_InitCdensityPasture
$gdxin


*Load initial areas by land use and land pool
Table LU_initarea(pool,use)
$include %CLASHdir%CLASHinput_LUH2_LUAreaByBiome.txt
;

*Load initial areas by land use and land pool
Table LU_area_SSP245(t,pool,use)
$include %CLASHdir%CLASHinput_LUH2_LUAreaSSP245.txt
;

*Load initial areas of secondary forest age classes by land pool
Table LU_initages(pool,age)
$include %CLASHdir%CLASHinput_LUH2_ForestAgeClassArea.txt
;

* Carbon density to wood volume conversion factors and wood carbon densities
$include %CLASHdir%CLASHinput_WoodProperties.txt
