$ontext

CLASH - Climate-responsive Land Allocation model with carbon Storage and Harvests

Version date: 2024-01-22
Contributors: Tommi Ekholm, Aapo Rautiainen, Nadine Freistetter  -  Finnish Meteorological Institute

This file is the core of the CLASH model.
The file doesn't work as a stand-alone model, but needs to be integrated to an IAM.
The main file needs to provide the set time (alias t), subsets tfirst and tlast, the objective function and the model and solve statements.

If you wish to run CLASH as stand-alone model, please use the file CLASH_Wrapper.gms.

$offtext

* Path for the land-use module's files (should come from the IAM, but if running stand-alone, assume that all files are in the same folder as the main file)
$ife not set CLASHdir $setglobal CLASHdir ''
* If no parametrization was specified, use EC-Earth:
$ife not set CLASH_Param $setglobal CLASH_Param 'ECE'



*********************************************************************************************************************************
***                                             Model declarations and structure                                              ***
*********************************************************************************************************************************

SETS
        pool    Land pools                                  / Boreal, Desert, DesertCold, Semiarid, TemperateDry, TemperateHumid, TropicalDry, TropicalHumid, Tundra, Unproductive /
        use     Land uses                                   / crops, pastr, primf, primn, secdf, secdn, urban /
        cstock  Carbon stocks                               / veg, litter, soil /
        age     Forest age classes (at 10 year time step)   / age010,age020,age030,age040,age050,age060,age070,age080,age090,age100,age110,age120,age130,age140,age150/
;



*********************************************************************************************************************************
***                                                  Parameter declarations                                                   ***
*********************************************************************************************************************************

PARAMETERS
* Land area
        LU_TotalArea(pool)                      Area of each land pool (mln. km2)
        LU_InitArea(pool,use)                   Initial area by land use and land pool (million km2)
        LU_InitAges(pool,age)                   Initial areas of secondary forest age classes (million km2)
        tstep                                   Model timestep (years)                                                  /10/
* Crop yield and Pasture NPPs
        LU_Crop_Yields(t,pool)                  Crop yield by land pool (kg dry mass per m2 per year)
        LU_Crop_LossShare                       Share of crops lost and used as seeds                                   / 0.07 /
        LU_Cropping_Intensity                   Cropland used intensity (excl. fallow etc.)                             / 0.8  /
        LU_Pasture_NPP(t,pool)                  NPP in pastures (kg C per m2 per year)
* Carbon density
        LU_Cdens(t,pool,use)                    Carbon density for land other than secondary forests (kg C per m2)
        LU_Cdens_SecnFor(t,pool,age)            Carbon density of secondary forests by age-class (kg C per m2)
        LU_DistProbSecnF(t,pool)                natural disturbance probability in secondary forests
        LU_InitCdensityCropland(pool, cstock)   Initial litter and soil carbon density in croplands (kg C per m2)
        LU_InitCdensityForest(pool, cstock)     Initial litter and soil carbon density in forests (kg C per m2)
        LU_InitCdensityPasture(pool, cstock)    Initial litter and soil carbon density on pasturess (kg C per m2)
* Carbon stock dynamics' parameters
        LU_LitterHarv(pool)                     Share of vegetation C stock ending as woody litter at harvest
        LU_LitterPrimFor(t,pool)                Woody litter production from primary forest land
        LU_LitterSecdFor(t,pool,age)            Woody litter production from secondary forest land

        LU_LitterWoodToSoilC(pool)              Woody litter C flux to soil
        LU_LitterWoodDecay(t,pool)              Woody litter C decay rate
        LU_SoilCWoodDecay(t,pool)               Woody soil C decay rate

        LU_LitterCropland(t,pool)               Herbaceous litter production from cropland
        LU_LitterPasture(t,pool)                Herbaceous litter production from pastures
        LU_LitterHerbToSoilC(pool)              Herbaceous litter C flux to soil
        LU_LitterHerbDecay(t,pool)              Herbaceous litter C decay rate
        LU_SoilCHerbDecay(t,pool)               Herbaceous soil C decay rate
* Wood harvesting
        LU_StemVol_secfor(t,pool,age)           Stem volume of secondary forests by age-class (m3 per ha)
        LU_stemvol_prifor(t,pool)               Stem volume of primary forests by age-class (m3 per ha)

        LU_d_to_v_conv(pool)                    Carbon density (kg C per m2) to stem volume (m3 per ha) conversion factor
        LU_wood_Cdens(pool)                     Wood carbon density (t C per m3)
        LU_eshare_secfor(t,pool,age)            Energy wood share of stem volume in secondary forest
        LU_pshare_secfor(t,pool,age)            Pulpwood share of stem volume in secondary forest
        LU_lshare_secfor(t,pool,age)            Log share of stem volume in secondary forest
        LU_eshare_prifor(t,pool)                Energy wood share of stem volume in primary forest
        LU_pshare_prifor(t,pool)                Pulpwood share of stem volume in primary forest
        LU_lshare_prifor(t,pool)                Log share of stem volume in primary forest
        LU_rshare(pool)                         Residue share of total biomass carbon

        LU_Ccont                                Carbon content of biomass                                               /0.5/
        LU_WoodDens(pool)                       Wood density (t per m3)
* Wood volume parameters (calculated below)
        LU_v_wast(t,pool,age)                   Waste wood volume (m3 per ha)
        LU_v_pulp(t,pool,age)                   Pulp volume (m3 per ha)
        LU_v_logs(t,pool,age)                   Log volume (m3 per ha)
        LU_v_logs_pr(t,pool)                    Log volume (m3 per ha) in primary forest
        LU_v_pulp_pr(t,pool)                    Pulp volume (m3 per ha) in primary forest
        LU_v_wast_pr(t,pool)                    Waste wood volume (m3 per ha) in primary forest
* Emission factors:
        LU_EF_CropN2O(t,pool)                   N2O emission factor for croplands (t N2O per km2)
        LU_EF_CropCH4(t,pool)                   CH4 emission factor for croplands (rice) (t CH4 per km2)
;


********************************************************************
* Load data from GDX and text files
$batinclude %CLASHdir%CLASH_ReadData.gms

* Load livestock:
$batinclude %CLASHdir%CLASH_Livestock.gms




*********************************************************************************************************************************
***                                                 Parameter value assignments                                               ***
*********************************************************************************************************************************


* Set the total area of each land pool based on the initial areas.
LU_TotalArea(pool) = sum(use, LU_initarea(pool,use) );


* Cropland N2O and CH4 (rice) emissions:
* Source: https://www.nature.com/articles/nclimate1458
LU_EF_CropN2O(t,pool) = 0.53;
* Source: https://doi.org/10.1002/2016GB005381
LU_EF_CropCH4(t,pool) = 2.3;

* Livestock NPP use in pastures, based on their pasture use and the weighted average of NPP over the land pools
LVST_LivestockNPPUse(LVST_animals) = LVST_pasture_use(LVST_animals) * sum(pool, LU_Pasture_NPP('2020',pool) * LU_initarea(pool,'pastr')) / sum(pool, LU_initarea(pool,'pastr'));


********************************************************************
* Pulp, log and waste wood yields

* Total stem volume in secondary forest
LU_stemvol_secfor(t,pool,age) = LU_d_to_v_conv(pool)*LU_Cdens_SecnFor(t,pool,age)  ;

* Shares of energy wood, pulpwood, and logs of total stem volume in secondary forest (unitless values between 0 and 1 that sum to 1)
LU_eshare_secfor(t,pool,age) $ (LU_stemvol_secfor(t,pool,age) < 20) = 1;
LU_eshare_secfor(t,pool,age) $ (LU_stemvol_secfor(t,pool,age) > 20 and LU_stemvol_secfor(t,pool,age) < 120) = 1 - 0.0085*(LU_stemvol_secfor(t,pool,age)-20);
LU_eshare_secfor(t,pool,age) $ (LU_stemvol_secfor(t,pool,age) > 120)= 0.15;

LU_lshare_secfor(t,pool,age) $ (LU_stemvol_secfor(t,pool,age) < 80) = 0;
LU_lshare_secfor(t,pool,age) $ (LU_stemvol_secfor(t,pool,age) > 80 and LU_stemvol_secfor(t,pool,age) < 280) = (1-LU_eshare_secfor(t,pool,age))*0.00425*LU_stemvol_secfor(t,pool,age);
LU_lshare_secfor(t,pool,age) $ (LU_stemvol_secfor(t,pool,age) > 280)= (1-LU_eshare_secfor(t,pool,age))*0.85;

LU_pshare_secfor(t,pool,age) = 1 - LU_eshare_secfor(t,pool,age) - LU_lshare_secfor(t,pool,age);

* Energy wood, pulpwood, and log volumes in secondary forest
LU_v_wast(t,pool,age)    = LU_eshare_secfor(t,pool,age) * LU_stemvol_secfor(t,pool,age);
LU_v_pulp(t,pool,age)    = LU_pshare_secfor(t,pool,age) * LU_stemvol_secfor(t,pool,age);
LU_v_logs(t,pool,age)    = LU_lshare_secfor(t,pool,age) * LU_stemvol_secfor(t,pool,age);

* Total stem volume in primary forest
LU_stemvol_prifor(t,pool) = LU_d_to_v_conv(pool) * LU_Cdens(t,pool,'primf') ;

* Shares of energy wood, pulpwood, and logs of total stem volume in primary forest (unitless values between 0 and 1 that sum to 1)
LU_eshare_prifor(t,pool) $ (LU_stemvol_prifor(t,pool) < 20) = 1;
LU_eshare_prifor(t,pool) $ (LU_stemvol_prifor(t,pool) > 20 and LU_stemvol_prifor(t,pool) < 120) = 1 - 0.0085*(LU_stemvol_prifor(t,pool)-20);
LU_eshare_prifor(t,pool) $ (LU_stemvol_prifor(t,pool) > 120)= 0.15;

LU_lshare_prifor(t,pool) $ (LU_stemvol_prifor(t,pool) < 80) = 0;
LU_lshare_prifor(t,pool) $ (LU_stemvol_prifor(t,pool) > 80 and LU_stemvol_prifor(t,pool) < 280) = (1-LU_eshare_prifor(t,pool))*0.00425*LU_stemvol_prifor(t,pool);
LU_lshare_prifor(t,pool) $ (LU_stemvol_prifor(t,pool) > 280)= (1-LU_eshare_prifor(t,pool))*0.85;

LU_pshare_prifor(t,pool) = 1 - LU_eshare_prifor(t,pool) - LU_lshare_prifor(t,pool);

* Energy wood, pulpwood, and log volumes in primary forest
LU_v_wast_pr(t,pool) = LU_eshare_prifor(t,pool) * LU_stemvol_prifor(t,pool);
LU_v_pulp_pr(t,pool) = LU_pshare_prifor(t,pool) * LU_stemvol_prifor(t,pool);
LU_v_logs_pr(t,pool) = LU_lshare_prifor(t,pool) * LU_stemvol_prifor(t,pool);

* Residue share
LU_rshare(pool)      = 1 - (LU_d_to_v_conv(pool)*LU_wood_Cdens(pool)/10);

* Wood density (t per m3)
LU_WoodDens(pool)=LU_wood_Cdens(pool)/LU_Ccont;



*********************************************************************************************************************************
***                                                  Variable  declarations                                                   ***
*********************************************************************************************************************************

POSITIVE VARIABLES
* Area:
         LU_Area(t,pool,use)            area of different land-use categories by land-pool (million km2)
         LU_Area_SecdF(t,pool,age)      area of secondary forest by age-class (million km2)
* Carbon stocks:
         LU_CStockVege(t,pool,use)      Carbon stock of vegetation by land-pool (GtC)
         LU_CStockLittWoody(t,pool)     Carbon stock of litter by land-pool (GtC)
         LU_CStockSoilWoody(t,pool)     Carbon stock of soil by land-pool (GtC)
         LU_CStockLittHerb(t,pool)      Carbon stock of litter by land-pool (GtC)
         LU_CStockSoilHerb(t,pool)      Carbon stock of soil by land-pool (GtC)
         LU_CStockTotalVege(t)          Total carbon stock of vegetation (GtC)
         LU_CStockTotalLitt(t)          Total carbon stock of litter (GtC)
         LU_CStockTotalSoil(t)          Total carbon stock of soil (GtC)
* Forest clearing and regeneration:
         LU_clear_sec(t,pool,age)       Cleared secondary forest (million km2)
         LU_clear_pri(t,pool)           Cleared primary forest (million km2)
         LU_regen_area(t)               Regenerated area (million km2)
* Harvesting:
         LU_harv_crops(t,pool)             Harvested crops (Mt DM per year)
         LU_harv_FoodCrops(t)              Crops used as human food (Mt DM per year)
         LU_harv_EnerCrops(t)              Crops used for energy (Mt DM per year)
         LU_harv_logs(t,pool)              Harvested logwood (mln. m3 per year)
         LU_harv_pulp(t,pool)              Harvested pulpwood (mln. m3 per year)
         LU_harv_wast(t,pool)              Harvested waste wood (mln. m3 per year)
         LU_harv_CropResid(t,pool)         Harvested crop residues (Mt DM per year)
         LU_harv_WoodResid(t,pool)         Harvested wood residues (Mt DM per year)
* Emissions:
         LU_emis_CropN2O(t,pool)        N2O emissions from croplands (Mt N2O per year)
         LU_emis_CropCH4(t,pool)        CH4 emissions from croplands (rice) (Mt N2O per year)
;


VARIABLES
         LU_CO2NetEmission(t) Net CO2 emission from land use (Mt CO2 per year)
;


EQUATIONS
* Area:
        EQ_LU_Area(t,pool)              constrain the sum of all land-use area to the area of the land pool
        EQ_LU_Area_SecF(t,pool)         total area of secondary forests
        EQ_LU_Area_PrimF(t,pool)        primary forests' area cannot be increased
        EQ_LU_Area_PrimN(t,pool)        primary non-forests' area cannot be increased
        EQ_LU_Area_SecdN(t,pool)        secondary non-forests' area cannot be increased
* Carbon stocks:
        EQ_LU_CStockVege(t,pool,use)    carbon stock of vegetation by land-pool
        EQ_LU_CStockLittWoody(t,pool)   carbon stock of woody litter by land-pool
        EQ_LU_CStockSoilWoody(t,pool)   carbon stock of woody soil by land-pool
        EQ_LU_CStockLittHerb(t,pool)    carbon stock of herb litter by land-pool
        EQ_LU_CStockSoilHerb(t,pool)    carbon stock of herb soil by land-pool
        EQ_LU_CStockTotalVege(t)        Total carbon stock of vegetation
        EQ_LU_CStockTotalLitt(t)        Total carbon stock of litter
        EQ_LU_CStockTotalSoil(t)        Total carbon stock of soil
        EQ_LU_CO2NetEmission(t)         Net CO2 emission from land use
* Forest growth, clearing and regeneration:
        EQ_LU_SecForAging(t,pool,age)
        EQ_LU_SecForLast(t,pool,age)
        EQ_LU_PriForClearing(t,pool)
        EQ_LU_MaxSecForClearing(t,pool,age)
        EQ_LU_MaxPriForClearing(t,pool)
        EQ_LU_SecForRegenArea(t)
* Harvesting:
        EQ_LU_harv_Crops(t,pool)        Harvested crops (Mt DM per year)
        EQ_LU_harv_wast(t,pool)         Harvested waste wood (mln. m3 per year)
        EQ_LU_harv_pulp(t,pool)         Harvested pulpwood (mln. m3 per year)
        EQ_LU_harv_logs(t,pool)         Harvested logwood (mln. m3 per year)
        EQ_LU_CropUse(t)                "Distribution of crops for food, feed and energy use"
        EQ_LU_MaxWoodResidHarv(t,pool)  Maximum residue harvesting
        EQ_LU_MaxCropResidHarv(t,pool)  Maximum residue harvesting
* Emissions:
        EQ_LU_emis_CropN2O(t,pool)       N2O emissions from croplands
        EQ_LU_emis_CropCH4(t,pool)       CH4 emissions from croplands (rice)
* Livestock pasture use:
        EQ_LU_LivestockPastureUse(t)    Livestock pasture use
;



*********************************************************************************************************************************
***                                                      Model equations                                                      ***
*********************************************************************************************************************************


********************************************************************
* Land area and allocation

* Land allocation is bounded by the area of the land-pool in question
EQ_LU_Area(t,pool)..                                                       sum(use, LU_Area(t,pool,use)) =E= LU_TotalArea(pool) ;
* Total secondary forest area is the sum over different age classes
EQ_LU_Area_SecF(t,pool)..                                                         LU_Area(t,pool,'secdf') =E= sum(age, LU_Area_SecdF(t,pool,age) )  ;

* Primary ecosystems' area cannot be increased:
EQ_LU_Area_PrimF(t,pool)..      LU_Area(t+1,pool,'primf') =L= LU_Area(t,pool,'primf');
EQ_LU_Area_PrimN(t,pool)..      LU_Area(t+1,pool,'primn') =L= LU_Area(t,pool,'primn');
* Assume the same for secondary non-forests (modelled the same as primary ecosystems, and can have thus high amount of vegetation)
EQ_LU_Area_SecdN(t,pool)..      LU_Area(t+1,pool,'secdn') =L= LU_Area(t,pool,'secdn');



********************************************************************
* Forest aging, clearing and regeneration

* Secondary forest aging
EQ_LU_SecForAging(t,pool,age)$(ord(age) LT (card(age)-1) and ord(t) LT card(t))..       LU_Area_SecdF(t+1,pool,age+1)   =E= (LU_Area_SecdF(t,pool,age) - LU_clear_sec(t,pool,age)*tstep) * (1-LU_DistProbSecnF(t,pool));
* Area of secondary forests' last age-class
EQ_LU_SecForLast(t,pool,age)$(ord(age) EQ (card(age)-1) and ord(t) LT card(t))..        LU_Area_SecdF(t+1,pool,age+1)   =E= (LU_Area_SecdF(t,pool,age) + LU_Area_SecdF(t,pool,age+1) - LU_clear_sec(t,pool,age)*tstep - LU_clear_sec(t,pool,age+1)*tstep) * (1-LU_DistProbSecnF(t,pool));
* Primary forest area changes by forest clearing
EQ_LU_PriForClearing(t,pool)$(ord(t) LT card(t))..                                          LU_Area(t+1,pool,'primf')   =E=  LU_Area(t,pool,'primf') - LU_clear_pri(t,pool)*tstep;

* Regenerated secondary forest area (planting)
EQ_LU_SecForRegenArea(t)..                                                                           LU_regen_area(t)   =E= sum((pool,age)$(ord(age) eq 1), LU_Area_SecdF(t+1,pool,age));

* Maximum primary and secondary forest clearing (needed only for the last period)
EQ_LU_MaxSecForClearing(t,pool,age)$tlast(t)..                                                 LU_clear_sec(t,pool,age)  =L=  LU_Area_SecdF(t,pool,age)/tstep;
EQ_LU_MaxPriForClearing(t,pool)$tlast(t)..                                                         LU_clear_pri(t,pool)  =L=  LU_Area(t,pool,'primf')/tstep;

* Maximum residue harvesting (note: harvesting is in Mt, C stokcs in Gt)
EQ_LU_MaxWoodResidHarv(t,pool)..                                                               LU_harv_WoodResid(t,pool) =L=  1000 * ( LU_Cdens(t,pool,'primf')*LU_clear_pri(t,pool) + sum(age, LU_Cdens_SecnFor(t,pool,age) * LU_clear_sec(t,pool,age)) ) * LU_rshare(pool);
EQ_LU_MaxCropResidHarv(t,pool)..                                                    LU_Ccont * LU_harv_CropResid(t,pool) =L=  1000 * LU_Area(t,pool,'crops') * (LU_LitterCropland(t,pool) - LU_Ccont * LU_Crop_Yields(t,pool) );



********************************************************************
* Carbon stocks - vegetation, soil and litter

* Vegetation carbon stocks (secondary forests calculated by age-class)
EQ_LU_CStockVege(t,pool,use)..
    LU_CStockVege(t,pool,use) =E= (LU_Cdens(t,pool,use) * LU_Area(t,pool,use))$LU_Cdens(t,pool,use) + sum(age, LU_Cdens_SecnFor(t,pool,age) * LU_Area_SecdF(t,pool,age) )$(sameAs(use,'secdf'))
;


* Woody litter (forest-based) carbon stock dynamics
EQ_LU_CStockLittWoody(t,pool)$(ord(t) LT card(t))..
    LU_CStockLittWoody(t+1,pool) =E= LU_CStockLittWoody(t,pool) * (1 - LU_LitterWoodDecay(t,pool) - LU_LitterWoodToSoilC(pool))**tstep
* This takes into account the decay of the litter input from years 0..(tstep-1) as (1/r * (1 - (1-r)^tstep)):
                                + (1 / (LU_LitterWoodDecay(t,pool) + LU_LitterWoodToSoilC(pool)) * (1 - (1 - LU_LitterWoodDecay(t,pool) - LU_LitterWoodToSoilC(pool))**tstep) ) * (
* assume non-forests to produce woody litter:
                                 + LU_LitterPrimFor(t,pool) * (LU_Area(t,pool,'primf') + LU_Area(t,pool,'primn') + LU_Area(t,pool,'secdn'))
                                 + sum(age, LU_LitterSecdFor(t,pool,age) * LU_Area_SecdF(t,pool,age))
* Litter from harvests: total C stock of the cleared areas, minus harvested wood C stock, minus harvested residue C stock:
                                 + ( LU_Cdens(t,pool,'primf')*LU_clear_pri(t,pool) + sum(age, LU_Cdens_SecnFor(t,pool,age) * LU_clear_sec(t,pool,age)) ) * LU_rshare(pool) - LU_Ccont * LU_harv_WoodResid(t,pool)/1000
                                )
;

* Woody soil carbon stock dynamics:
EQ_LU_CStockSoilWoody(t,pool)$(ord(t) LT card(t))..
    LU_CStockSoilWoody(t+1,pool) =E= LU_CStockSoilWoody(t,pool) * (1 - LU_SoilCWoodDecay(t,pool))**tstep
                                     + (1/LU_SoilCWoodDecay(t,pool) * (1 - (1-LU_SoilCWoodDecay(t,pool))**tstep))
                                        * LU_LitterWoodToSoilC(pool) * LU_CStockLittWoody(t,pool)
;

* Herbaceous litter (non-forest-based) carbon stock dynamics
EQ_LU_CStockLittHerb(t,pool)$(ord(t) LT card(t))..
    LU_CStockLittHerb(t+1,pool) =E= LU_CStockLittHerb(t,pool) * (1 - LU_LitterHerbDecay(t,pool) - LU_LitterHerbToSoilC(pool))**tstep
                                + (1/(LU_LitterHerbDecay(t,pool) + LU_LitterHerbToSoilC(pool)) * (1 - (1 - LU_LitterHerbDecay(t,pool) - LU_LitterHerbToSoilC(pool))**tstep)) * (
                                 + LU_Area(t,pool,'crops') * (LU_LitterCropland(t,pool) - LU_Ccont * LU_Crop_Yields(t,pool) ) - LU_Ccont * LU_harv_CropResid(t,pool) /1000
                                 + LU_Area(t,pool,'pastr') *  LU_LitterPasture(t,pool)
                                )
;

* Herbaceous soil carbon stock dynamics:
EQ_LU_CStockSoilHerb(t,pool)$(ord(t) LT card(t))..
    LU_CStockSoilHerb(t+1,pool) =E= LU_CStockSoilHerb(t,pool) * (1 - LU_SoilCHerbDecay(t,pool))**tstep
                                    + (1/LU_SoilCHerbDecay(t,pool) * (1 - (1-LU_SoilCHerbDecay(t,pool))**tstep))
                                      * LU_LitterHerbToSoilC(pool) * LU_CStockLittHerb(t,pool)
;


********************************************************************
* Carbon stock totals

* Total vegetation, litter and soil carbon stock
EQ_LU_CStockTotalVege(t)..   LU_CStockTotalVege(t) =E= sum((pool,use), LU_CStockVege(t,pool,use) );
EQ_LU_CStockTotalLitt(t)..   LU_CStockTotalLitt(t) =E= sum(pool, LU_CStockLittWoody(t,pool) + LU_CStockLittHerb(t,pool) );
EQ_LU_CStockTotalSoil(t)..   LU_CStockTotalSoil(t) =E= sum(pool, LU_CStockSoilWoody(t,pool) + LU_CStockSoilHerb(t,pool) );


* Net land-use CO2 emissions per year (note conversion: GtC -> Mt CO2)
EQ_LU_CO2NetEmission(t)$(ord(t) LT card(t))..
    LU_CO2NetEmission(t+1) =E= -1 * 44/12 * 1000 * (
                                   (LU_CStockTotalVege(t+1) - LU_CStockTotalVege(t)) +
                                   (LU_CStockTotalLitt(t+1) - LU_CStockTotalLitt(t)) +
                                   (LU_CStockTotalSoil(t+1) - LU_CStockTotalSoil(t))
                                   )/tstep;


********************************************************************
* Production

* Cropland harvests in Mt DM/year (note: yield (dry mass) is in kg/m2 = 1000 t/km2; area is in mln. km2)
EQ_LU_harv_crops(t,pool)..                                           LU_harv_crops(t,pool) =E= 1000*LU_Cropping_Intensity*LU_Crop_Yields(t,pool) * LU_Area(t,pool,'crops');
* Total harvest (minus losses) distributed to different uses (food, feed, energy)
EQ_LU_CropUse(t)..                (1-LU_Crop_LossShare) * sum(pool, LU_harv_crops(t,pool)) =E=  LU_harv_FoodCrops(t) + LVST_total_feed_intake(t) + LU_harv_EnerCrops(t);

* Harvests of different wood fractions (note: LU_stemvol_secfor is in m3/ha; LU_clear_sec in mln. km2)
EQ_LU_harv_wast(t,pool)..                                             LU_harv_wast(t,pool) =E= sum(age, LU_v_wast(t,pool,age) * 100*LU_clear_sec(t,pool,age)) + LU_v_wast_pr(t,pool) * 100*LU_clear_pri(t,pool);
EQ_LU_harv_pulp(t,pool)..                                             LU_harv_pulp(t,pool) =E= sum(age, LU_v_pulp(t,pool,age) * 100*LU_clear_sec(t,pool,age)) + LU_v_pulp_pr(t,pool) * 100*LU_clear_pri(t,pool);
EQ_LU_harv_logs(t,pool)..                                             LU_harv_logs(t,pool) =E= sum(age, LU_v_logs(t,pool,age) * 100*LU_clear_sec(t,pool,age)) + LU_v_logs_pr(t,pool) * 100*LU_clear_pri(t,pool);


********************************************************************
* Emissions

EQ_LU_emis_CropN2O(t,pool)..            LU_emis_CropN2O(t,pool) =E= LU_EF_CropN2O(t,pool) * LU_Area(t,pool,'crops');
EQ_LU_emis_CropCH4(t,pool)..            LU_emis_CropCH4(t,pool) =E= LU_EF_CropCH4(t,pool) * LU_Area(t,pool,'crops');


********************************************************************
* Livestock pasture use:

EQ_LU_LivestockPastureUse(t)..   sum(LVST_animals, LVST_headcount(t,LVST_animals) * LVST_LivestockNPPUse(LVST_animals)) / 10**6 =L= sum(pool, LU_Pasture_NPP(t,pool) * LU_Area(t,pool,'pastr'));




*********************************************************************************************************************************
***                                                   Initial conditions                                                      ***
*********************************************************************************************************************************

* Fix the areas for the first model period:
* (Note: the sec.forest area and areas need to be consistent, otherwise the model is infeasible.)
LU_Area.FX(tfirst(t),pool,use) = LU_initarea(pool,use);
LU_Area_SecdF.FX(tfirst(t),pool,age) = LU_initages(pool,age);


* Assign initial states for the litter and soil carbon stocks (assume non-forests as producing woody litter):
LU_CStockLittWoody.Fx(tfirst,pool) = LU_InitCdensityForest(pool,'litter') * ( LU_initarea(pool,'secdf') + LU_initarea(pool,'primf') + LU_initarea(pool,'primn') + LU_initarea(pool,'secdn') );
LU_CStockSoilWoody.Fx(tfirst,pool) =  LU_InitCdensityForest(pool,'soil')  * ( LU_initarea(pool,'secdf') + LU_initarea(pool,'primf') + LU_initarea(pool,'primn') + LU_initarea(pool,'secdn') );

LU_CStockLittHerb.Fx(tfirst,pool)  = LU_InitCdensityCropland(pool,'litter') * LU_initarea(pool,'crops')
                                    + LU_InitCdensityPasture(pool,'litter') * LU_initarea(pool,'pastr');
LU_CStockSoilHerb.Fx(tfirst,pool)  = LU_InitCdensityCropland(pool,'soil')   * LU_initarea(pool,'crops')
                                    + LU_InitCdensityPasture(pool,'soil')   * LU_initarea(pool,'pastr');

* The first peridod's land-use CO2 net emission cannot be calculated, so fix the variable to the estimate from Global Carbon Budget 2021 (Friedlingstein et al., 2022)
LU_CO2NetEmission.FX(tfirst(t)) = (1.1-3.1) * 44/12 * 1000;




*********************************************************************************************************************************
***                                                  Additional constraints                                                   ***
*********************************************************************************************************************************

* Constrain maximum desert cropland area (yield has been modeled based on map points with actual agricultural production):
LU_Area.UP(t,'Desert','crops')$(ord(t) >= 2) = LU_area_SSP245(t,'Desert','crops');


* To avoid end-of-horizon effects with land-use, limit the amount of clearing and production to increase max 5% in the last time periods
Equation
    EQ_LU_SecdFHarvest_EoH_Fix1(pool,age)
    EQ_LU_SecdFHarvest_EoH_Fix2(pool,age)
    EQ_LU_PrimFHarvest_EoH_Fix(pool)
    EQ_LVST_Output_EoH_Fix(lvst_products)
;

EQ_LU_SecdFHarvest_EoH_Fix1(pool,age)..             LU_clear_sec('2090',pool,age) =L= 1.05 * LU_clear_sec('2080',pool,age);
EQ_LU_SecdFHarvest_EoH_Fix2(pool,age)..             LU_clear_sec('2100',pool,age) =L= 1.05 * LU_clear_sec('2090',pool,age);
EQ_LU_PrimFHarvest_EoH_Fix(pool)..                      LU_clear_pri('2100',pool) =L= 1.05 * LU_clear_pri('2090',pool);
EQ_LVST_Output_EoH_Fix(lvst_products).. LVST_product_output('2100',LVST_products) =L= 1.05 * LVST_product_output('2090',LVST_products);

