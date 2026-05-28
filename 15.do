**2015 RALS
**Matsu
**2023/09/17
**install
/*ssc install geonear*/

** settings
clear all
set more off
global RALS15="C:\Users\mm_wi\Documents\research\gender_decision\data\RALS15_Stata_Data-20231117T021549Z-001\RALS15_Stata_Data" 
global clean="C:\Users\mm_wi\Documents\research\gender_decision\data\clean"


**hhid and climate
use $RALS15/id, clear
keep cluster hh s_dd_new e_dd_new prov dist const ward region csa popwgt pstatus
egen long hhid=group(cluster hh)
destring hhid, replace
label var hhid "Household id"
rename (s_dd_new e_dd_new popwgt)(lat lon weight)
save id15.dta, replace

/*import delimited "C:\Users\user\Documents\research\obed\gender_decision\data\climate\RALS2.csv", encoding(ISO-8859-2) numericcols(4 5 6) clear 
rename (v1)(nid)
drop if hdindex==.
save climate15, replace

import delimited "C:\Users\user\Documents\research\obed\gender_decision\data\district.csv", encoding(ISO-8859-2) clear 
geonear adm2_en x y using climate15, neighbors(nid lon lat)
merge m:m nid using climate15, nogen
drop if x==.
rename adm2_en district
replace district="Chienge" if district=="Chiengi"
replace district="Kapiri-Mposhi" if district=="Kapiri Mposhi"
replace district="Milenge" if district=="Milengi"
save climate15.dta, replace*/

use id15, clear
decode dist, gen(district)
merge m:m district using climate15, nogen
drop if hhid==.
keep cluster hh prov dist const ward region csa hhid weight pstatus
save id15, replace

** FRA distance and other household indicators
use $RALS15/household, clear
rename (HH fra1)(hh FRAdis)
recode hh10a (1=1)(nonm=0), gen(pssblchng)
label var pssblchng "Possibility to change the tenure status(=1 if yes)"
recode hh54 (1=1)(nonm=0), gen(lcl)
label var lcl "Local household head (=1 if yes)"
recode hh57 (1=1 "Yes")(nonm=0 "No"), gen(mtrlnl)
label var mtrlnl "Matrilineal household (=1 if yes)"
keep cluster hh FRAdis pssblchng lcl mtrlnl
save FRAdis15, replace

** socioeconomic variables
use $RALS15/demog, clear
egen long hhid=group(cluster hh)
keep if age < 12
bysort cluster hh: egen hhsize_c =count(mem)
replace hhsize_c=0 if hhsize_c==.
duplicates drop cluster hh, force
keep cluster hh hhsize_c
save chld15, replace
*** number of adult equivalent (proxy of labor)
use $RALS15/demog, clear
egen long hhid=group(cluster hh)
keep if age>11
bysort cluster hh: egen hhsize_a=count(mem)
keep if mem==1 | mem==2
bysort cluster hh: egen rank=rank(-age)
keep if rank==1
label var hhsize_a "Adult equivalent"

label var age "Age of HH"

*** gender
recode da02 (1 .=0 "male")(2=1 "female" ), gen(female)
rename (da06)(hhschl)
*** education
replace hhschl=0 if hhschl==-9
label var hhschl "Educational level of HH (years)"
label var female "Female headed household(=1 if yes)"
label var age "Age of HH"
duplicates drop cluster hh, force
merge 1:1 cluster hh using chld15, nogen

gen hhsize=hhsize_a+hhsize_c

label var hhsize "Household size"
keep cluster hh hhid female hhschl age hhsize hhsize_a hhsize_c
destring hhid, replace
save socio15, replace

*** first born between 2011-2014
use $RALS15/demog, clear
egen long hhid=group(cluster hh)
keep if da03==3 // child
bysort cluster hh: egen hhsize_c_first=count(mem) if 4 <= age   // if they already have children before the first survey
bysort cluster hh: egen baby_1214=count(mem) if 1 < age & age < 4 //newborn between the first round (ref ag year 2010-2011 but demography in 2011-12) and the second round (ref ag year 2013-2014 but demography in 2014-15)
keep if hhsize_c_first==.
bysort cluster hh: egen older=min(da01) 
//keep if da00d==15 //newborn
keep if older==da01 //first born between the periods
bysort cluster hh: gen firstson_i=1 if da02==1
bysort cluster hh: gen firstdaughter_i=1 if da02==2
bysort cluster hh: egen firstson=max(firstson_i)
bysort cluster hh: egen firstdaughter=max(firstdaughter_i)
label var firstson "First son"
label var firstdaughter "First daughter"
duplicates drop cluster hh, force
keep cluster hh hhid firstson firstdaughter
save first15, replace

**food needs
use $RALS15/foodneeds, clear
keep if foodneed==1
bysort cluster hh: egen insec=count(month)
label var insec "Months of food insecurity"
duplicates drop cluster hh, force
keep cluster hh insec
save insec15, replace

** plot level variables
use $RALS15/field, clear
merge 1:1 cluster hh field using $RALS15/trees, force nogen
/*drop if f15==23
drop if f15==24
drop if f15==25
drop if f15==26
drop if f15==27
drop if f15==28
drop if f15==50
drop if f15==51
drop if f15==52
drop if f15==53
drop if f15==54*/
*** tenure status
recode f05 (1 4 7=1 "Titled")(2 3 5 6 8 9 .=0 "Non-titled"), gen(tnr)
label var tnr "Land tenure (=1 if yes)"
gen tnrhct=hect if tnr==1
replace tnrhct=0 if tnrhct==.
label var tnrhct "Land tenure (ha)"
*** land usage
recode f01 (1=1 "Yes")(nonm=0 "No"), gen(ownc)
gen ownclt=hect if ownc==1
replace ownclt=0 if ownclt==.
label var ownclt "Own cultivated (ha)"
recode f01 (2 3=1 "Yes")(nonm=0 "No"), gen(rnt)
gen rntn=hect if rnt==1
replace rntn=0 if rntn==.
label var rntn "Rent/Borrowed in (ha)"
*** land acquisition
recode f06 (1=1)(2/5 .=0),gen(prchsd)
recode f06 (2=1)(1 3/5 .=0),gen(inhrtd)
recode f06 (3=1)(1 2 4 5 .=0),gen(allctd)
recode f06 (4=1)(1/3 5 .=0),gen(rntd)
recode f06 (5=1)(1/4 .=0),gen(wlkin)
rename f06 lndacq
*** crop type
rename f15 crp
recode crp (1=1)(nonm=0),gen(mz_plt)
label var mz_plt "Planting maize (=1 if female)"
*** decision maker(gender)
recode da02 (2=1 "Yes")(1=0 "No"), gen(dmfml)
label var dmfml "Decision maker (=1 if female)"

*** investment behavior
**** preventing soil erosion
recode f11 (0 .=0 "No")(nonm=1 "Yes"), gen(soil)
label var soil "Soil and land management (=1 if yes)"
gen soilero=hect if soil==1
replace soilero=0 if soilero==.
label var soilero "Soil and land management (ha)"
**** planting trees
recode f12 (2 .=0 "No")(1=1 "Yes"), gen(trpl)
label var trpl "Agroforestry (=1 if yes)"
gen trplnt=hect if trpl==1
replace trplnt=0 if trplnt==.
label var trplnt "Agroforestry (ha)"
**** irrigation
recode f09 (1=1 "Yes")(2 .=0 "No"), gen(irr)
label var irr "Irrigation (=1 if yes)"
gen irri=hect if irr==1
replace irri=0 if irri==.
label var irri "Irrigation (ha)"
**** fallow
recode f01 (5 = 1 "Yes")(nonm = 0 "No"), gen(fll)
label var fll "Fallow (=1 if yes)"
gen fllw=hect if fll==1
replace fllw=0 if fllw==.
label var fllw "Fallow (ha)"

keep cluster hh panwgt prchsd field mz_plt crp tnrhct ownclt rntn inhrtd allctd rntd wlkin hect dist_plot tnr dmfml soil soilero trpl trplnt irr irri fll fllw prov dist lndacq
save plt15, replace


** hh-level fertilizer and other investment
use $RALS15/field_cult, clear
bysort cluster hh: egen nmfld=count(field)
label var nmfld "Number of plots"
recode fl12 (0 .=0)(1 2 3=1), gen(manure)
bysort cluster hh: egen man=sum(manure)
recode man (0 .=0)(nonm=1),gen(orgmanu)
bysort cluster hh: egen orgm=sum(ha_cult) if orgmanu==1
replace orgm=0 if orgm==.
duplicates drop cluster hh, force
label var orgmanu "Organic fertilizer(=1 if yes)"
label var orgm "Organic fertilier (ha)"

bysort cluster hh:egen frtlz=sum(basalkg+topdkg)
label var frtlz "Fertilizer (kgs)"
recode frtlz (0=0 "No")(nonm=1 "Yes"), gen(frt)
label var frt "Fertilizer (=1 yes)"
keep cluster hh orgmanu orgm prov dist nmfld frt frtlz
save orgmnr15, replace


**tenure hh level
use $RALS15/field, clear
merge 1:1 cluster hh field using $RALS15/trees, force nogen
*** tenure status
recode f05 (1 4 7=1 "Titled")(2 3 5 6 8 9 .=0 "Non-titled"), gen(tnr)
label var tnr "Land tenure (=1 if yes)"
bysort cluster hh: egen tnr_s=sum(tnr) // number of tenured plot
recode tnr_s (0 .=0)(nonm=1), gen(ttl)
label var ttl "Land tenure (=1 if yes)"
bysort cluster hh: egen lndttl = sum(hect) if ttl==1
replace lndttl=0 if lndttl==.
label var lndttl "Land tenure (ha)"
bysort cluster hh: egen hct=sum(hect) if f01==1
label var hct "Total hectares of cultivated land"

*** gender of decision maker
bysort cluster hh: gen mh=1 if da02==1
bysort cluster hh: egen MH=sum(mh)
bysort cluster hh: gen FH=1 if MH==0
replace FH=0 if FH==.
bysort cluster hh: egen nump=count(f01)
bysort cluster hh: replace MH=0 if MH < nump
replace MH=1 if MH>1
bysort cluster hh: gen JH=1 if MH==0 & FH==0
replace JH=0 if JH==.
label var MH "Male decision making (=1 if yes)"
label var FH "Female decision making (=1 if yes)"
label var JH "Joint decision making (=1 if yes)"
*** land usage
recode f01 (1=1 "Yes")(nonm=0 "No"), gen(own)
bysort cluster hh: egen ownc=sum(own)
recode ownc (0 .=0)(nonm=1), gen(owncl)
bysort cluster hh: egen ownclt=sum(hect) if owncl==1
replace ownclt=0 if ownclt==.
label var ownclt "Own cultivated (ha)"
recode f01 (2 3=1 "Yes")(nonm=0 "No"), gen(rnt)
bysort cluster hh: egen rentin=sum(rnt)
recode rentin (0 .=0)(nonm=1), gen(rntin)
bysort cluster hh: egen rntn=sum(hect) if rntin==1
replace rntn=0 if rntn==.
label var rntn "Rent/Borrowed in (ha)"
*** planting maize
rename f15 crp
recode crp (1=1)(2/66 .=0),gen(mz)
bysort cluster hh: egen mz_t=sum(mz)
recode mz_t (0 .=0)(nonm=1), gen(mzp)
label var mzp "Planting maize (=1 if female)"
recode crp (1/4 6/7 9 12/15 17 57 18 22=0 "Subsistence crop")(5 8 10/11 16 19 20 60 61 64 66 21 =1 "Cash crop"), gen(cshcrpi)
bysort cluster hh: egen cshcrp_i=sum(cshcrpi)
recode cshcrp_i (0=0)(nonm=1), gen(cshcrp)
label var cshcrp "Cash crop planted (=1 if yes)"

*** investment behavior
**** preventing soil erosion
recode f11 (0 =0 "No")(nonm=1 "Yes"), gen(soilero)
bysort cluster hh: egen sil_t=sum(soilero)
recode soilero (0 .=0)(nonm=1),gen(sle)
label var sle "Soil and land management (=1 if yes)"
bysort cluster hh: egen sler=sum(hect) if sle==1
replace sler=0 if sler==.
label var sler "Soil and land management (ha)"
**** planting trees
recode f12 (2 .=0 "No")(nonm=1 "Yes"), gen(trpl)
bysort cluster hh: egen tr_t=sum(tr)
recode tr_t (0 .=0)(nonm=1),gen(trpln)
label var trpln "Agroforestry (=1 if yes)"
bysort cluster hh: egen trplnt=sum(hect) if trpln==1
replace trplnt=0 if trplnt==.
label var trplnt "Agroforestry (ha)"
**** irrigation
recode f09 (1=1 "Yes")(2. =0 "No"), gen(i)
bysort cluster hh: egen ir=sum(i)
recode ir (0 .=0)(nonm=1), gen(irr)
label var irr "Irrigation (=1 if yes)"
bysort cluster hh: egen irri=sum(hect) if irr==1
replace irri=0 if irri==.
label var irri "Irrigation (ha)"
**** fallow
recode f01 (5=1 "Yes")(nonm =0 "No"), gen(f)
bysort cluster hh: egen fl=sum(f)
recode fl (0 =0)(nonm=1), gen(fll)
label var fll "Fallow (=1 if yes)"
bysort cluster hh: egen fllw=sum(hect) if fll==1
replace fllw=0 if fllw==.
label var fllw "Fallow (ha)"

*** distance to plots
bysort cluster hh: egen dstnc=mean(dist_plot)
label var dstnc "Average distance from house to plot (km)"

duplicates drop cluster hh, force
keep cluster hh mzp dstnc tnr tnr_s sle sler lndttl ownclt rntn trpln trplnt irr irri prov dist ttl JH MH FH hct cshcrp ir tr_t sil_t fll fllw
save hh_tnr15, replace 

/** seed cost
use $RALS15/seed, clear
bysort cluster hh: gen seedcost=*st04/st05_conv
replace seedcost=0 if seedcost==.
keep cluster hh seedcost
duplicates drop cluster hh, force
save seed15, replace*/

** total income
*** maize sale and cost
use $RALS15/maizesales, clear
recode ms05(5=1 "yes")(nonm=0 "no"), gen(FRAi)
bysort cluster hh: egen FRA=sum(FRAi)
replace FRA=1 if FRA >= 1
rename (ms06 price gvsales_maize) (fradistance maizeprice maizesale)
label var FRA "If a household sell maize to FRA(=1)"
bysort cluster hh: gen maizerev= gvsales_maize_actprice
bysort cluster hh: gen cost= trans_kg*kgsold_barter
replace maizerev=0 if maizerev==.
replace cost=0 if cost==.
bysort cluster hh: gen maize=maizerev-cost
label var maize "Total value of sold maize"
duplicates drop cluster hh, force
keep cluster hh FRA fradistance maize maizeprice maizerev
save mz15, replace

*** crop sale and cost
use $RALS15/cropsales, clear
bysort cluster hh: gen ttl_crpi=(s09a*kgsold_total)/s09b_conv //price per unit we convert unit into price per kilogram then calculate total price
replace ttl_crpi=0 if ttl_crpi==.
bysort cluster hh: gen ttl_crpt=sum(ttl_crpi)
bysort cluster hh: gen cost= kg_transpt*kgsold_total
replace cost=0 if cost==.
bysort cluster hh: gen ttl_crp=ttl_crpt-cost
duplicates drop cluster hh, force
keep cluster hh ttl_crp ttl_crpt
save crp15, replace

*** cassava
use $RALS15/cassava_sales, clear
bysort cluster hh: gen ttl_cssvi=kg_totalsold*price_kg
replace ttl_cssvi=0 if ttl_cssvi==.
bysort cluster hh: gen ttl_cssv=sum(ttl_cssvi)
duplicates drop cluster hh, force
keep cluster hh ttl_cssv
save cssv15, replace

*** livestock
use $RALS15/livestock_sales, clear
bysort cluster hh: gen ttl_lvstck=sum(price_per_animal*ls18)
duplicates drop cluster hh, force
keep cluster hh ttl_lvstck
save lvstck15, replace

*** fish
use $RALS15/fish, clear
bysort cluster hh: egen ttl_fsh= sum(fsh01 + fsh02 + fsh03 + fsh04 + fsh05 + fsh06 + fsh07 + fsh08+ fsh09 + fsh10 + fsh11 + fsh12)
duplicates drop cluster hh, force
keep cluster hh ttl_fsh
save fsh15, replace

*** vegetable
use $RALS15/veg_fruit, clear
bysort cluster hh: gen ttl_vgfrti=totvf_sold*kg_price
bysort cluster hh: gen ttl_vgfrt=sum(ttl_vgfrti)
duplicates drop cluster hh, force
keep cluster hh ttl_vgfrt
save frt15, replace

*** non-farm business
use $RALS15/business, clear
replace tot_bus=0 if tot_bus==.
bysort cluster hh: egen ttl_bz=sum(tot_bus)
duplicates drop cluster hh, force
keep cluster hh ttl_bz
save bz15, replace

*wage 
use $RALS15/salwage, clear
replace totwage=0 if totwage==.
replace inkind_wage=0 if inkind_wage==.
bysort cluster hh: egen ttl_wage=sum(totwage+inkind_wage)
duplicates drop cluster hh, force
keep cluster hh ttl_wage
save wage15, replace


** sum up all income sources
use id15, clear
merge 1:1 cluster hh using mz15, nogen force
merge 1:1 cluster hh using crp15, nogen force
merge 1:1 cluster hh using cssv15, nogen force
merge 1:1 cluster hh using lvstck15, nogen force
merge 1:1 cluster hh using fsh15, nogen force
merge 1:1 cluster hh using frt15, nogen force
merge 1:1 cluster hh using bz15, nogen force
merge 1:1 cluster hh using wage15, nogen force
*merge 1:1 cluster hh using seed15, nogen force
replace maize=0 if maize==.
replace maizerev=0 if maizerev==.
replace ttl_crp=0 if ttl_crp==.
replace ttl_crpt=0 if ttl_crpt==.
replace ttl_cssv=0 if ttl_cssv==.
replace ttl_lvstck=0 if ttl_lvstck==.
replace ttl_fsh=0 if ttl_fsh==.
replace ttl_vgfrt=0 if ttl_vgfrt==.
replace ttl_bz=0 if ttl_bz==.
replace ttl_wage=0 if ttl_wage==.
replace FRA=0 if FRA==.
*replace seedcost=0 if seedcost==.
drop if ttl_bz < 0
bysort cluster hh: gen ttl_inc=9.52*(maizerev + ttl_crpt + ttl_cssv + ttl_lvstck + ttl_fsh + ttl_vgfrt + ttl_bz + ttl_wage)/6.15
bysort cluster hh: gen ttl_frm=9.52*(ttl_crp + ttl_cssv + ttl_vgfrt + maize)/6.15 //profit
bysort cluster hh: gen frm_inc=9.52*(ttl_crpt + ttl_cssv + ttl_vgfrt+maizerev)/6.15 //income
foreach rev in maizerev ttl_crpt ttl_cssv maize ttl_vgfrt{
	gen s_`rev'=9.52*(`rev')/6.15
}
label var ttl_inc "Total household Income"
save id15, replace

** natural capital
use $RALS15/field, clear
bysort cluster hh: egen land=sum(hect)
label var land "Landholding size (ha)"
duplicates drop cluster hh, force
keep cluster hh land
save land15, replace

** soil land management
use $RALS15/soil_land_manage, clear
replace slm01=0 if slm01==2
bysort cluster hh: egen sum=sum(slm01)
recode sum (0=0 "No")(nonm=1 "Yes"), gen(slm)
label var slm "Soil and land management (=1 if yes) "
duplicates drop cluster hh, force
keep cluster cluster hh pstatus slm category
save slm15, replace

** access to credit
use $RALS15/loans_credit, clear
replace lna01=0 if lna01==2
bysort cluster hh: egen sum=sum(lna01)
recode sum (0=0 "No")(nonm=1 "Yes"), gen(crdt)
label var crdt "Obtaining credit(=1 if yes) "
duplicates drop cluster hh, force
keep cluster cluster hh crdt prov dist
save crdt15, replace

** asset
use $RALS15/assets,clear  
keep cluster hh asset ast01
reshape wide ast01,i(cluster hh) j(asset)
local varlist "ast011 ast012 ast013 ast014 ast015 ast016 ast017 ast018 ast019 ast0110 ast0111 ast0112 ast0113 ast0114 ast0115 ast0116 ast0117 ast0118 ast0119 ast0120 ast0121 ast0122 ast0123 ast0124 ast0125 ast0126 ast0127 ast0128 ast0129 ast0130 ast0131 ast0132 ast0133 ast0134 ast0135 ast0136 ast0137 ast0138 ast0139 ast0140 ast0140 ast0141 ast0142 ast0143"
foreach x in `varlist'{
	replace `x'=0 if `x'==2
	replace `x'=0 if `x'==.
}
pca `varlist'
predict asst
keep cluster hh asst
duplicates drop cluster hh, force
save asset15, replace

*** livestock
use $RALS15/livestock, clear
bysort cluster hh: gen cttl=1 if lstock==1
bysort cluster hh: gen cattle=cttl*ls02
replace cattle=0 if cattle==.

bysort cluster hh: gen shp=1 if lstock==4
bysort cluster hh: gen sheep=shp*ls02
replace sheep=0 if sheep==.

bysort cluster hh: gen gts=1 if lstock==2
bysort cluster hh: gen goats=gts*ls02
replace goats=0 if goats==.

bysort cluster hh: gen pgs=1 if lstock==3
bysort cluster hh: gen pigs=pgs*ls02
replace pigs=0 if pigs==.

bysort cluster hh: gen chckn=1 if lstock==6
bysort cluster hh: gen chicken=chckn*ls02
replace chicken=0 if chicken==.

bysort cluster hh: egen ct=sum(cattle)
bysort cluster hh: egen sh=sum(sheep)
bysort cluster hh: egen gt=sum(goats)
bysort cluster hh: egen pg=sum(pigs)
bysort cluster hh: egen ch=sum(chicken)
bysort cluster hh: gen tlu=0.7*ct +0.1*sh +0.1*gt +0.2*pg +0.01*ch 
duplicates drop cluster hh, force
keep cluster hh tlu
//Conversion factors are: cattle = 0.7, sheep = 0.1, goats = 0.1, pigs = 0.2, chicken = 0.01
label var tlu "Tropical Livestock Unit"
save tlu15, replace

** distance to road
use $RALS15/distance_agser, clear
keep if keyserv==2
rename ks01 km_trmc
label var km_trmc "Distance to the nearest tarmac(mainroad)(km)"
gen time=ks03*60 if ks04==2
replace time=ks03 if ks04==1
label var time "Time to the nearest paved road (min)"
keep cluster hh km_trmc prov dist time
save rd15, replace
** merge
use plt15, clear
merge m:1 cluster hh using id15, nogen force
merge m:1 cluster hh using FRAdis15, nogen force
merge m:1 cluster hh using socio15, nogen force
merge m:1 cluster hh using land15, nogen force
merge m:1 cluster hh using asset15, nogen force
merge m:1 cluster hh using tlu15, nogen force
merge m:1 cluster hh using slm15, nogen force
merge m:1 cluster hh using crdt15, nogen force
merge m:1 cluster hh using orgmnr15, nogen force
merge m:1 cluster hh using rd15, nogen
merge m:1 cluster hh using insec15, nogen
merge m:1 cluster hh using first15, nogen

foreach m in land tlu insec {
	replace `m'=0 if `m'==.
}
gen year=2015
save $clean/RALS15_plt, replace

use id15, clear
merge 1:1 cluster hh using FRAdis15, nogen force
merge 1:1 cluster hh using socio15, nogen force
merge 1:1 cluster hh using land15, nogen force
merge 1:1 cluster hh using asset15, nogen force
merge 1:1 cluster hh using tlu15, nogen force
merge 1:1 cluster hh using slm15, nogen force
merge 1:1 cluster hh using crdt15, nogen force
merge 1:1 cluster hh using orgmnr15, nogen
merge 1:1 cluster hh using hh_tnr15, nogen
merge 1:1 cluster hh using rd15, nogen
merge m:1 cluster hh using insec15, nogen
merge m:1 cluster hh using first15, nogen

foreach m in land tlu insec{
	replace `m'=0 if `m'==.
}

gen year=2015
save $clean/RALS15_hh, replace