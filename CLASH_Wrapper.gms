$ontext

CLASH - Climate-responsive Land Allocation model with carbon Storage and Harvests

Version date: 2023-06-16

This is a wrapper for running CLASH as a stand-alone land-use model.

$offtext

$title        CLASH Land Use Model - stand-alone version


*************************************************************************
* GAMS control options:
* Allow multiple definitions of sets and data (warning: the source is read in two runs, first all data statements, then everything else):
$ONMULTI
* Allow empty set and data declarations:
$ONEMPTY
* Zero symbol means number zero, not boolean FALSE:
$ONEPS



************************************************************
* Basic definitions for running the model as stand-alone

SETS
        time                        / 2020,2030,2040,2050,2060,2070,2080,2090,2100 /
        tfirst(time)
        tlast(time)
;

alias(time,t);

tfirst(t) = yes$(ord(t) eq 1);
tlast(t)  = yes$(ord(t) eq card(t));



************************************************************
* Load the LU module core:

* assign the directory for land-use module files:
$setglobal CLASHdir ''

* Load CLASH core:
$batinclude %CLASHdir%CLASH_Core.gms




************************************************************
* Agricultural and forestry demand (Mt DM/year):
* Source, food: FAO data for 2019 and MAgPIE SSP2 growth (see 'FAO crop production and use 2010-2019.xlsx')
*         wood:
*         animal products: (see 'Livestock_Data.xlsx')

set     commodity  /FoodCrops
                    FoodBeef
                    FoodShoat
                    FoodPork
                    FoodPoultry
                    FoodMilk
                    FoodEggs
                    WoodLogs
                    WoodPulp
                    Bioenergy
                    /;

* Agricultural and forestry demand (Mt DM/year):
table data_demand(time,commodity)
        FoodCrops    FoodBeef     FoodShoat     FoodPork     FoodPoultry    FoodMilk    FoodEggs     WoodLogs     WoodPulp     Bioenergy
2020    2991          67.900       16.000       109.800       119.500       886.900      86.700         780         390.2          855
2030    3336          78.212       18.430       126.475       137.648       1021.59      99.867         870         383.8         1010
2040    3649          86.804       20.455       140.369       152.770       1133.82      110.838        945         377.4         1145
2050    4002          93.709       22.082       151.536       164.923       1224.01      119.655       1005         379.0         1376
2060    4293          98.223       23.145       158.835       172.867       1282.97      125.419       1052         384.9         1470
2070    4526          100.90       23.777       163.170       177.584       1317.98      128.842       1090         383.4         1578
2080    4674          102.11       24.062       165.122       179.709       1333.76      130.383       1118         386.1         1678
2090    4733          101.20       23.848       163.657       178.115       1321.92      129.227       1140         389.8         1750
2100    4714          98.867       23.297       159.876       174.000       1291.38      126.241       1157         393.5         1837
;

** Agricultural and forestry demand (Mt DM/year): WITHOUT WOOD AND BIOENERGY (for validation, LPJG LUH runs have no wood harvesting)
*table data_demand(time,commodity)
*        FoodCrops    FoodBeef     FoodShoat     FoodPork     FoodPoultry    FoodMilk    FoodEggs
*2020    2991          67.900       16.000       109.800       119.500       886.900      86.700
*2030    3336          78.212       18.430       126.475       137.648       1021.59      99.867
*2040    3649          86.804       20.455       140.369       152.770       1133.82      110.838
*2050    4002          93.709       22.082       151.536       164.923       1224.01      119.655
*2060    4293          98.223       23.145       158.835       172.867       1282.97      125.419
*2070    4526          100.90       23.777       163.170       177.584       1317.98      128.842
*2080    4674          102.11       24.062       165.122       179.709       1333.76      130.383
*2090    4733          101.20       23.848       163.657       178.115       1321.92      129.227
*2100    4714          98.867       23.297       159.876       174.000       1291.38      126.241
*;
*


************************************************************
* Equations for satisfying the demand

Equations
    EQ_LUwrapper_FoodCrops(t)
    EQ_LUwrapper_FoodBeef(t)
    EQ_LUwrapper_FoodShoat(t)
    EQ_LUwrapper_FoodPork(t)
    EQ_LUwrapper_FoodPoultry(t)
    EQ_LUwrapper_FoodMilk(t)
    EQ_LUwrapper_FoodEggs(t)
    EQ_LUwrapper_WoodLogs(t)
    EQ_LUwrapper_PulpWood(t)
    EQ_LUwrapper_Bioenergy(t)
;

* Require production to meet specified demand:
EQ_LUwrapper_FoodCrops(t)..     data_demand(t,'FoodCrops')    =L= LU_harv_FoodCrops(t);
EQ_LUwrapper_FoodBeef(t)..      data_demand(t,'FoodBeef' )    =L= LVST_product_output(t, 'LVST_Beef');
EQ_LUwrapper_FoodShoat(t)..     data_demand(t,'FoodShoat')    =L= LVST_product_output(t, 'LVST_Shoat');
EQ_LUwrapper_FoodPork(t)..      data_demand(t,'FoodPork' )    =L= LVST_product_output(t, 'LVST_Pork');
EQ_LUwrapper_FoodPoultry(t)..   data_demand(t,'FoodPoultry' ) =L= LVST_product_output(t, 'LVST_Poultry');
EQ_LUwrapper_FoodMilk(t)..      data_demand(t,'FoodMilk' )    =L= LVST_product_output(t, 'LVST_Milk');
EQ_LUwrapper_FoodEggs(t)..      data_demand(t,'FoodEggs' )    =L= LVST_product_output(t, 'LVST_Eggs');
EQ_LUwrapper_WoodLogs(t)..      data_demand(t,'WoodLogs' )    =L= sum(pool, LU_WoodDens(pool)*LU_harv_logs(t,pool));
EQ_LUwrapper_PulpWood(t)..      data_demand(t,'WoodPulp' )    =L= sum(pool, LU_WoodDens(pool)*LU_harv_pulp(t,pool));
EQ_LUwrapper_Bioenergy(t)..     data_demand(t,'Bioenergy')    =L= sum(pool, LU_WoodDens(pool)*LU_harv_wast(t,pool)) + LU_harv_EnerCrops(t);



************************************************************
* Exogenous land-use constraints:

* Fix land-use to the SSP2-4.5 scenario (with some slack - otherwise this can make the model infeasible):
*LU_Area.LO(t,pool,use)$(ord(t) >= 2) = 0.995*LU_area_SSP245(t,pool,use);

* Land-use area fixing by land-use type:
* Lower bounds for 'non-productive' land-use classes from SSP2-4.5:
LU_Area.FX(t,pool,'urban')$(ord(t) >= 2) = LU_area_SSP245(t,pool,'urban');
LU_Area.LO(t,pool,'primf')$(ord(t) >= 2) = LU_area_SSP245(t,pool,'primf');
LU_Area.LO(t,pool,'primn')$(ord(t) >= 2) = LU_area_SSP245(t,pool,'primn');
* Fix secondary non-forest area to disallow rapid buildup of vegetation carbon stocks
*LU_Area.FX(t,pool,'secdn')$(ord(t) >= 2) = LU_area_SSP245(t,pool,'secdn');



************************************************************
* Problem statement for running the model as stand-alone

VARIABLES
         total_CStock2100  Total carbon stock in 2100
;

EQUATIONS
    EQ_total_CStock2100
;

EQ_total_CStock2100..
    total_CStock2100 =E= LU_CStockTotalVege('2100') + LU_CStockTotalLitt('2100') + LU_CStockTotalSoil('2100');


************************************************************
* Solve statement

model  landuse /all/;

option LP = CPLEX

solve landuse maximizing total_CStock2100 using lp;


************************************************************
* Calculate some easy-to-read aggregates from the results

parameters
            LU_AreaByPool(t,pool)
            LU_AreaByUse(t,use)
;

LU_AreaByPool(t,pool) = sum(use,    LU_Area.L(t,pool,use));
LU_AreaByUse(t,use)     = sum(pool, LU_Area.L(t,pool,use));



