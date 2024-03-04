$ontext

Ecological module of CLASH

Authors: Tommi Ekholm, Aapo Rautiainen, 22.6.2023

$offtext
$offlisting
$title        Ecological module for CLASH



*********************************************************************************************************************************
***                                                 Set and parameter definitions                                             ***
*********************************************************************************************************************************

SETS
           ea               ecological module age classes (1-year resolution)           / age001*age150 /
           et               ecological module years                                     / 1850*2200 /
           t(et)            IAM timeperiods (10 years each)                             / 2020,2030,2040,2050,2060,2070,2080,2090,2100,2110,
                                                                                          2120,2130,2140,2150,2160,2170,2180,2190,2200 /
           age(ea)          IAM age classes (at 10-year timestep)                       / age010,age020,age030,age040,age050,age060,age070,age080,age090,age100,age110,age120,age130,age140,age150 /
           pool             land pools                                                  / Boreal, Desert, DesertCold, Semiarid, TemperateDry, TemperateHumid, TropicalDry,TropicalHumid, Tundra, Unproductive /
           use              land uses                                                   / crops, pastr, primf, primn, secdf, secdn, urban /
           cstock           carbon stocks                                               / veg, litter, soil /
           climvar          climate variables                                           / co2ppm,DeltaT /
           fgpar            forest growth parameters                                    / d,dd,const,temp,co2ppm,temp2,co2temp2,error /
           vcpar            vegetation carbon stock parameters                          / const, tmp, ppm, tmp_ppm /
           scpar            soil carbon dynamics parameters                             / const,temp,ppm,cveg,harv,litt_atm,litt_tmp,litt_soil,soil_atm,soil_tmp,error /
;

PARAMETERS
           dt                           IAM timestep                                                    / 10 /
           pigavt                       preindustrial global average temperature (degrees C)            / 9.4 /
           climate(et,climvar)          climate data (historical and scenario)
           dfirst(pool)                 forest initial carbon density
;



*********************************************************************************************************************************
***                                         Read historical and future climate scenario                                       ***
*********************************************************************************************************************************

*Load historical climate data (CO2 concentration and global temperature anomaly)
Table climate_hist(et,climvar)   historical climate data
$include EMinput_climdata_hist.txt
;

*Load scenario climate data (CO2 concentration and global temperature anomaly)
Table climate_scen(t,climvar)   scenario climate data
*$include EMinput_climdata_scen_RCP26.txt
$include EMinput_climdata_scen_RCP45.txt
;

* Assign historical values to the climate data
climate(et,climvar) = climate_hist(et,climvar);

* Assign scenario values to the climate data (interpolate between IAM model periods)
loop(t,
    climate(et,climvar)$(et.val ge t.val and et.val le (t.val+dt)) = (dt-(et.val-t.val))/dt * climate_scen(t,climvar) + (et.val-t.val)/dt * climate_scen(t+1,climvar);
);
* use the 2100 values beyond that year
climate(et,climvar)$(et.val > 2100) = climate('2100',climvar);


*********************************************************************************************************************************
***                                    Read the parametrization from a specified climate model                                ***
*********************************************************************************************************************************


* If no parametrization was specified, use EC-Earth:
$ifE not set Parametrization $setglobal Parametrization 'ECE'
$setGlobal ParamDir 'Parametrization_%Parametrization%\'

*Load forest growth parameters for land pools
table forestpar(pool,fgpar)   forest growth parameters by land pools
$include %ParamDir%EMinput_ForestGrowthFitCoefs_%Parametrization%.txt
;

*Load secondary forest initial (=first age class) carbon density for land pools
Parameter dfirst(pool)   forest carbon density at age 1 by land pool /
$include %ParamDir%EMinput_StandInitialCarbonDensity_%Parametrization%.txt
/;

*Load natural disturbance risk parameters for land pools
Table FireProbCoefs(pool,vcpar)   natural disturbance probability per year
$include %ParamDir%EMinput_FireProbCoefs_%Parametrization%.txt
;

*Load natural disturbance risk parameters for land pools
Table CropYieldCoefs(pool,vcpar)   crop yield parameters by land pools
$include %ParamDir%EMinput_CropYieldFitCoefs_%Parametrization%.txt
;

*Load cropland vegetation carbon density
Table CropVegCarbonFitCoefs(pool,vcpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_CropVegCarbonFitCoefs_%Parametrization%.txt
;

*Load pasture vegetation carbon density
Table PastureVegCarbonFitCoefs(pool,vcpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_PastureVegCarbonFitCoefs_%Parametrization%.txt
;

*Load natural vegetation carbon density
Table NaturalVegCarbonFitCoefs(pool,vcpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_NaturalVegCarbonFitCoefs_%Parametrization%.txt
;

*Load woody litter and soil carbon dynamics parameters
Table ForestSoilCarbonFitCoefs(pool,scpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_ForestSoilCarbonFitCoefs_%Parametrization%.txt
;

*Load herbaceous litter and soil carbon dynamics parameters
Table AgriSoilCarbonFitCoefs(pool,scpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_AgriSoilCarbonFitCoefs_%Parametrization%.txt
;

*Load cropland NPP parameters
Table CropNPPFitCoefs(pool,vcpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_CropNPPFitCoefs_%Parametrization%.txt
;

*Load pasture NPP parameters
Table PastureNPPCoefs(pool,vcpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_PastureNPPFitCoefs_%Parametrization%.txt
;

* Forest litter production parameters
Table ForestLitterprodFit(pool,scpar)   Soil C dynamics parameters
$include %ParamDir%EMinput_ForestLitterProdFitCoefs_%Parametrization%.txt
;

*Load initial litter and soil carbon stocks for croplands, forest and pastures by land pool
Table LU_InitCdensityCropland(pool, cstock)
$include %ParamDir%LUinput_InitCdensityCropland_%Parametrization%.txt
;

Table LU_InitCdensityForest(pool, cstock)
$include %ParamDir%LUinput_InitCdensityForest_%Parametrization%.txt
;

Table LU_InitCdensityPasture(pool, cstock)
$include %ParamDir%LUinput_InitCdensityPasture_%Parametrization%.txt
;




*********************************************************************************************************************************
***                                                Do some preparatory calculations                                           ***
*********************************************************************************************************************************

parameter dens(et,pool,ea)     Forests carbon density;
parameter grow(pool,ea)        Forests' relative annual growth of carbon density;

* Assign the initial carbon density for the first age-class for all biomes
dens(et,pool,ea)$(ord(ea)= 1) = dfirst(pool);

* Loop all timesteps, calculate C density for those age-classes that exist in that timestep
loop(et$(ord(et) lt card(et)),
* relative growth according to the fitted model
    grow(pool,ea)$(ord(ea) le ord(et))
                    = (dens(et,pool,ea)**forestpar(pool,'d'))
                       * (dens(et,pool,ea)**( dens(et,pool,ea)*forestpar(pool,'dd')) )
                       * ( forestpar(pool,'const')
                           + forestpar(pool,'temp') * (climate(et,'DeltaT')+pigavt)
                           + forestpar(pool,'co2ppm') * climate(et,'co2ppm')
                           + ( forestpar(pool,'temp2') + forestpar(pool,'co2temp2')*climate(et,'co2ppm') ) * (climate(et,'DeltaT')+pigavt)**2
                          )
                        ;

* increase in carbon density to the next year and age-class
    dens(et+1,pool,ea+1)$(ord(ea) le ord(et)) =  dens(et,pool,ea) * (1 + grow(pool,ea));
);



*********************************************************************************************************************************
***                                                  Prepare data for CLASH                                                   ***
*********************************************************************************************************************************

PARAMETERS
    LU_Crop_Yields(t,pool)                  Crop yield by land pool (kg DM per m2 per year)
    LU_Pasture_NPP(t,pool)                  NPP in pastures (kg C per m2 per year)
;

LU_Crop_Yields(t,pool) = CropYieldCoefs(pool, 'const') + CropYieldCoefs(pool, 'tmp')*(climate(t,'DeltaT')+pigavt) + CropYieldCoefs(pool, 'ppm')*climate(t,'co2ppm');
LU_Pasture_NPP(t,pool) = PastureNPPCoefs(pool,'const') + PastureNPPCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt) + PastureNPPCoefs(pool,'ppm')*climate(t,'co2ppm');

* Vegetation carbon densities and forest disturbances:
PARAMETERS
    LU_Cdens(t,pool,use)                    carbon density for land other than secondary forests (kg C per m2)
    LU_Cdens_SecnFor(t,pool,age)            carbon density in secondary forests by IAM age class (kg C per m2)
    LU_Cdens_Natural(t,pool)                carbon density in primary ecosystems (kg C per m2)  (temporary parameter)
    LU_Cdens_Crops(t,pool)                  carbon density in croplands (kg C per m2) (temporary parameter)
    LU_Cdens_Pasture(t,pool)                carbon density on pastures (kg C per m2) (temporary parameter)
    LU_DistProbSecnF(t,pool)                probability of natural disturbance in secondary forest
;

LU_Cdens_SecnFor(t,pool,age) = dens(t,pool,age);

LU_DistProbSecnF(t,pool) = FireProbCoefs(pool,'const')
                         + FireProbCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt)
                         + FireProbCoefs(pool,'ppm') * climate(t,'co2ppm');

LU_Cdens_Crops(t,pool)   = CropVegCarbonFitCoefs(pool,'const')
                         + CropVegCarbonFitCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt)
                         + CropVegCarbonFitCoefs(pool,'ppm') * climate(t,'co2ppm');

LU_Cdens_Pasture(t,pool) = PastureVegCarbonFitCoefs(pool,'const')
                         + PastureVegCarbonFitCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt)
                         + PastureVegCarbonFitCoefs(pool,'ppm') * climate(t,'co2ppm');

LU_Cdens_Natural(t,pool) = NaturalVegCarbonFitCoefs(pool,'const')
                         + NaturalVegCarbonFitCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt)
                         + NaturalVegCarbonFitCoefs(pool,'ppm') * climate(t,'co2ppm');

* Store the non-secondary-forest carbon densities in the same parameter:
LU_Cdens(t,pool,'primf') = LU_Cdens_Natural(t,pool);
LU_Cdens(t,pool,'primn') = LU_Cdens_Natural(t,pool);
LU_Cdens(t,pool,'secdn') = LU_Cdens_Natural(t,pool);
LU_Cdens(t,pool,'crops') = LU_Cdens_Crops(t,pool);
LU_Cdens(t,pool,'pastr') = LU_Cdens_Pasture(t,pool);

* Litter and soil carbon dynamics (woody/herbaceous):
parameters
        LU_LitterHarv(pool)                 Woody litter production from wood harvest
        LU_LitterPrimFor(t,pool)            Woody litter production from primary forest land
        LU_LitterSecdFor(t,pool,age)        Woody litter production from secondary forest land

        LU_LitterWoodToSoilC(pool)          Woody litter C flux to soil
        LU_LitterWoodDecay(t,pool)          Woody litter C decay rate
        LU_SoilCWoodDecay(t,pool)           Woody soil C decay rate

        LU_LitterCropland(t,pool)           Herbaceous litter production from cropland
        LU_LitterPasture(t,pool)            Herbaceous litter production from pastures
        LU_LitterHerbToSoilC(pool)          Herbaceous litter C flux to soil
        LU_LitterHerbDecay(t,pool)          Herbaceous litter C decay rate
        LU_SoilCHerbDecay(t,pool)           Herbaceous soil C decay rate
;

* Woody litter and soil C generation and dynamics:
LU_LitterHarv(pool)    = ForestSoilCarbonFitCoefs(pool,'harv');

LU_LitterPrimFor(t,pool)    = ForestLitterprodFit(pool,'const') + ForestLitterprodFit(pool,'cveg')*LU_Cdens(t,pool,'primf');
LU_LitterSecdFor(t,pool,age)= ForestLitterprodFit(pool,'const') + ForestLitterprodFit(pool,'cveg')*LU_Cdens_SecnFor(t,pool,age);

LU_LitterWoodToSoilC(pool)  = ForestSoilCarbonFitCoefs(pool,'litt_soil');
LU_LitterWoodDecay(t,pool)  = ForestSoilCarbonFitCoefs(pool,'litt_atm') + ForestSoilCarbonFitCoefs(pool,'litt_tmp')*(climate(t,'DeltaT')+pigavt);
LU_SoilCWoodDecay(t,pool)   = ForestSoilCarbonFitCoefs(pool,'soil_atm') + ForestSoilCarbonFitCoefs(pool,'soil_tmp')*(climate(t,'DeltaT')+pigavt);

* Herbaceous litter and soil C generation and dynamics:
LU_LitterCropland(t,pool)   = CropNPPFitCoefs(pool,'const') + CropNPPFitCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt) + CropNPPFitCoefs(pool,'ppm')*climate(t,'co2ppm');
LU_LitterPasture(t,pool)    = PastureNPPCoefs(pool,'const') + PastureNPPCoefs(pool,'tmp')*(climate(t,'DeltaT')+pigavt) + PastureNPPCoefs(pool,'ppm')*climate(t,'co2ppm');
LU_LitterHerbToSoilC(pool)  = AgriSoilCarbonFitCoefs(pool,'litt_soil');
LU_LitterHerbDecay(t,pool)  = AgriSoilCarbonFitCoefs(pool,'litt_atm') + AgriSoilCarbonFitCoefs(pool,'litt_tmp')*(climate(t,'DeltaT')+pigavt);
LU_SoilCHerbDecay(t,pool)   = AgriSoilCarbonFitCoefs(pool,'soil_atm') + AgriSoilCarbonFitCoefs(pool,'soil_tmp')*(climate(t,'DeltaT')+pigavt);




*********************************************************************************************************************************
***                                             Write data into GDX files for CLASH                                           ***
*********************************************************************************************************************************

execute_unload "CLASH_Parametrization_%Parametrization%.gdx" LU_Cdens, LU_Cdens_SecnFor, LU_DistProbSecnF,
                                           LU_Crop_Yields, LU_Pasture_NPP,
                                           LU_LitterHarv, LU_LitterPrimFor, LU_LitterSecdFor, LU_LitterWoodToSoilC, LU_LitterWoodDecay, LU_SoilCWoodDecay,
                                           LU_LitterCropland, LU_LitterPasture, LU_LitterHerbToSoilC, LU_LitterHerbDecay, LU_SoilCHerbDecay,
                                           LU_InitCdensityCropland, LU_InitCdensityForest, LU_InitCdensityPasture ;

