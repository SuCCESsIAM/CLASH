$ontext

This file describes livestock rearing and the production of animal products in CLASH

$offtext


* Livestock considered: beef and dairy cattle, pigs, chicken, sheep & goat (=shoat)
set LVST_ANIMALS /
LVST_cattle_beef
LVST_cattle_dairy
LVST_shoat
LVST_pigs
LVST_chicken_broiler
LVST_chicken_egglaying
/;

set LVST_PRODUCTS /
LVST_beef
LVST_shoat
LVST_pork
LVST_poultry
LVST_milk
LVST_eggs
/;



*********************************************************************************************************************************
***                                                           Parameters                                                      ***
*********************************************************************************************************************************

* Herd size 2020 (+1% on top to ensure feasability) (million animals)		
parameter LVST_initial_headcount(LVST_animals) /		
LVST_cattle_beef              962.5
LVST_cattle_dairy             578.6
LVST_shoat                   2415.1
LVST_pigs                     962.1
LVST_chicken_broiler        33428.03
LVST_chicken_egglaying       7978.3
/;		


* Feed use (kg/head/year)               
parameter LVST_feed_use(LVST_animals) Livestock feed use (kg per head per year)/             
LVST_cattle_beef                    124.2       
LVST_cattle_dairy                   137.3       
LVST_shoat                          1.3     
LVST_pigs                           309.7       
LVST_chicken_broiler                14.6        
LVST_chicken_egglaying              13.9        
/;              
                
* Pasture use (m2/head)             
parameter LVST_pasture_use(LVST_animals) Livestock pasture use (m2 per head) /              
LVST_cattle_beef                    15981.8      
LVST_cattle_dairy                   11466.5      
LVST_shoat                          3832.7       
LVST_pigs                           10.6         
LVST_chicken_broiler                0.6      
LVST_chicken_egglaying              2.8    
/;

             
* Product yield (t/head/yr, for meat: edible weight/boneless meat)             
parameter LVST_product_yield(LVST_ANIMALS, LVST_PRODUCTS) Livestock product yield (t per head per yr) /				
LVST_cattle_beef         .   LVST_beef          				0.05645
LVST_cattle_dairy        .   LVST_beef          				0.02637
LVST_shoat               .   LVST_shoat         				0.01090
LVST_pigs                .   LVST_pork          				0.14004
LVST_chicken_broiler     .   LVST_poultry       				0.00372
LVST_cattle_dairy        .   LVST_milk          				1.54803
LVST_chicken_egglaying   .   LVST_eggs          				0.01122
/;				


* CH4 emissions from enteric fermantation + manure management (t CH4/head/yr)               
parameter LVST_emissionfactor_CH4(LVST_animals) Livestock CH4 emissions (enteric fermantation + manure mgmt)(t CH4 per head per yr) /               
LVST_cattle_beef                            0.058864
LVST_cattle_dairy                           0.096216
LVST_shoat                                  0.007122
LVST_pigs                                   0.002856
LVST_chicken_broiler                        0.000009
LVST_chicken_egglaying                      0.000135
/;              
                
                
* N2O emissions from manure management (t N2O/head/yr)              
parameter LVST_emissionfactor_N2O(LVST_animals) Livestock N2O emissions (manure mgmt)(t N2O per head per yr) /               
LVST_cattle_beef                            0.000943
LVST_cattle_dairy                           0.001100
LVST_shoat                                  0.000251
LVST_pigs                                   0.000283
LVST_chicken_broiler                        0.000009
LVST_chicken_egglaying                      0.000009
/;              


* Livestock NPP use in pastures, based on their pasture use and the weighted average of NPP over the land pools
* Note: this is calculated in the core module
parameter LVST_LivestockNPPUse(LVST_animals) Livestock NPP use (kg C per head per year) ;




*********************************************************************************************************************************
***                                                  Variables and equations                                                  ***
*********************************************************************************************************************************


POSITIVE VARIABLES
    LVST_headcount(t,LVST_animals)                     "Number of livestock globally"
    LVST_emissions_CH4(t)                              "CH4 emissions caused by livestock (enteric fermentation + manure management)  (Mt/year)"
    LVST_emissions_N2O(t)                              "N2O emissions caused by livestock (enteric fermentation + manure management)  (Mt/year)"

    LVST_total_pasture_use(t)                          "Total pasture required for grazing livestock globally (million km2)"                          
    LVST_total_feed_intake(t)                          "Total human-produced feed required for livestock (Mt/year)"
    LVST_product_output(t,LVST_products)               "Food production per animal species (Mt/year)"
;


EQUATIONS
    EQ_LVST_product_output(t,LVST_products)                      "Food production per animal species (Mt)"
    EQ_LVST_total_feed_intake(t)                                 "Total human-produced feed required for livestock (Mt/year)"
    EQ_LVST_emissions_CH4(t)                                     "Total emissions of methane through enteric fermentation and manure management (Mt/year)"
    EQ_LVST_emissions_N2O(t)                                     "Total emissions of nitrous oxide through enteric fermentation and manure management (Mt/year)"
;


* EQUATIONS
    EQ_LVST_product_output(t,LVST_products)..     LVST_product_output(t,LVST_products)  =E=  sum(LVST_animals, LVST_headcount(t,LVST_animals) * LVST_product_yield(LVST_ANIMALS, LVST_PRODUCTS) ) ;
    
    EQ_LVST_total_feed_intake(t) ..     LVST_total_feed_intake(t)    =E=  sum(LVST_animals, LVST_headcount(t,LVST_animals)  *  LVST_feed_use(LVST_animals)) / 10**3 ;
                                                             
    EQ_LVST_emissions_CH4(t)..     LVST_emissions_CH4(t)  =E=  sum(LVST_animals, LVST_headcount(t,LVST_animals)  *  LVST_emissionfactor_CH4(LVST_animals)) ;
    EQ_LVST_emissions_N2O(t)..     LVST_emissions_N2O(t)  =E=  sum(LVST_animals, LVST_headcount(t,LVST_animals)  *  LVST_emissionfactor_N2O(LVST_animals)) ;



* INITIAL CONDITONS
LVST_headcount.FX(tfirst,LVST_animals)  =   LVST_initial_headcount(LVST_animals);
