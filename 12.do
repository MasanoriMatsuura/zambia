**2012 RALS
**Matsu
**2022/09/18
**install

** settings
clear all
set more off
global RALS12="C:\Users\mm_wi\Documents\research\gender_decision\data\RALS12_Stata_Data-20231117T021550Z-001\RALS12_Stata_Data"
global clean="C:\Users\mm_wi\Documents\research\gender_decision\data\clean"


**hhid and climate
use $RALS12/id, clear
keep cluster hh S_DD E_DD prov dist const ward region csa category weight
egen long hhid=group(cluster hh)
destring hhid, replace
label var hhid "Household id"
rename (S_DD E_DD)(lat lon)
save id12.dta, replace

/*import delimited "C:\Users\user\Documents\research\obed\gender_decision\data\climate\RALS1.csv", encoding(ISO-8859-2) numericcols(4 5 6) clear 
/*gen lat1=-(lat)
drop lat
rename (lat1 v1)(lat nid)*/
rename (v1)(nid)
drop if hdindex==.
save climate12.dta, replace

import delimited "C:\Users\user\Documents\research\obed\gender_decision\data\district.csv", encoding(ISO-8859-2) clear 
geonear adm2_en x y using climate12, neighbors(nid lon lat)
merge m:m nid using climate12, nogen
drop if x==.
rename adm2_en district
replace district="Chienge" if district=="Chiengi"
replace district="Kapiri-Mposhi" if district=="Kapiri Mposhi"
replace district="Milenge" if district=="Milengi"
save climate12.dta, replace*/

use id12, clear
decode dist, gen(district)
merge m:m district using climate12, nogen
drop if hhid==.
keep cluster hh  prov dist const ward region csa category hhid weight
save id12, replace

** FRA distance
use $RALS12/hh_part2, clear
rename (FRA1)(FRAdis)
recode HH54 (1=1)(nonm=0), gen(lcl)
label var lcl "Local household head (=1 if yes)"
recode HH57 (1=1 "Yes")(nonm=0 "No"), gen(mtrlnl)
label var mtrlnl "Matrilineal household (=1 if yes)"
save hhs.dta, replace
use $RALS12/hh_part1, clear
recode HH10A (1=1)(nonm=0), gen(pssblchng)
label var pssblchng "Possibility to change the tenure status(=1 if yes)"
merge 1:1 cluster hh using hhs, nogen
keep cluster hh FRAdis pssblchng lcl mtrlnl
save FRAdis12, replace

** socioeconomic variables
use $RALS12/demog_child, clear
bysort cluster hh: egen hhsize_c=count(mem) 
duplicates drop cluster hh, force
save chld12, replace
use $RALS12/demog_adult, clear
egen hhid = concat(cluster hh dist)
bysort cluster hh: egen hhsize_a=count(mem) 
keep if mem==1
recode DA02 (1=0 "male")(2=1 "female" ), gen(female)
rename (DA06)(hhschl)
label var hhschl "Educational level of HH (years)"
label var female "Female headed household(=1)"
destring hhid, replace
duplicates drop cluster hh, force
merge 1:1 cluster hh using chld12, nogen
replace hhsize_c=0 if hhsize_c==.
gen hhsize=hhsize_a+hhsize_c
label var hhsize_a "Adult equivalent"
label var age "Age of HH"
keep cluster  hh hhid female age hhschl hhsize hhid hhsize_a hhsize_c
save socio12, replace

*** first born between 2007-2010
use $RALS12/demog_adult, clear
rename DA03 dc03
append using $RALS12/demog_child
egen long hhid=group(cluster hh)
keep if dc03==3 //keep only child
bysort cluster hh: egen hhsize_c_old=count(mem) if age >= 4 //for dropping households having more than 3 years old
keep if hhsize_c_old==. //drop if the household has a child who is older than 4
bysort cluster hh: egen baby_0810=count(mem) if 0 < age & age < 4   //newborn just before the first round (ref ag year 2010-2011 but demography in 2011-12)
drop if baby_0810 == .
bysort cluster hh: egen older=min(dc01) //older year-born
keep if older==dc01 //first born three year before the first round
bysort cluster hh: gen firstson_i=1 if dc02==1
bysort cluster hh: gen firstdaughter_i=1 if dc02==2
bysort cluster hh: egen firstson=max(firstson_i)
bysort cluster hh: egen firstdaughter=max(firstdaughter_i)
label var firstson "First son"
label var firstdaughter "First daughter"
duplicates drop cluster hh firstson firstdaughter, force
keep cluster hh hhid firstson firstdaughter
save first12, replace

**food needs
use $RALS12/foodneeds, clear
keep if foodneed==1
bysort cluster hh: egen insec=count(month)
label var insec "Months of food insecurity"
duplicates drop cluster hh, force
keep cluster hh insec
save insec12, replace

** plot level variables
use $RALS12/field, clear
/*drop if F15==23
drop if F15==24
drop if F15==25
drop if F15==26
drop if F15==27
drop if F15==28
drop if F15==50
drop if F15==51
drop if F15==52
drop if F15==53
drop if F15==54*/
*** tenure status
recode F05 (1 2 =1 "Titled")( 3 4 5 7 .=0 "Non-titled"), gen(tnr)
label var tnr "Land tenure (=1 if yes)"
gen tnrhct=hect if tnr==1
replace tnrhct=0 if tnrhct==.
label var tnrhct "Land title(ha)"
*** land usage
recode F01 (1=1 "Yes")(nonm=0 "No"), gen(ownc)
gen ownclt=hect if ownc==1
replace ownclt=0 if ownclt==.
label var ownclt "Own cultivated (ha)"
recode F01 (2 3=1 "Yes")(nonm=0 "No"), gen(rnt)
gen rntn=hect if rnt==1
replace rntn=0 if rntn==.
label var rntn "Rent/Borrowed in (ha)"
*** land acquisition
recode F06 (1=1)(2/5 .=0),gen(prchsd)
recode F06 (2=1)(1 3/5 .=0),gen(inhrtd)
recode F06 (3=1)(1 2 4 5 .=0),gen(allctd)
recode F06 (4=1)(1/3 5 .=0),gen(rntd)
recode F06 (5=1)(1/4 .=0),gen(wlkin)
rename F06 lndacq
*** crop type
rename F15 crp
recode crp (1=1)(nonm=0), gen(mz_plt)
label var mz_plt "Planting maize(=1 if female)"
*** decision maker(gender)
recode F04 (2 3 5 7 9 11=1 "Yes")(1 4 6 8 10=0 "No"), gen(dmfml)
label var dmfml "Decision maker (=1 if female)"

*** investment behavior
**** preventing soil erosion
recode F11 (0 .=0 "No")(nonm=1 "Yes"), gen(soil)
label var soil "Soil and land management (=1 if yes)"
gen soilero=hect if soil==1
replace soilero=0 if soilero==.
label var soilero "Soil and land management (ha)"
**** planting trees
recode F12 (0 .=0 "No")(nonm=1 "Yes"), gen(trpl)
label var trpl "Agroforestry (=1 if yes)"
gen trplnt=hect if trpl==1
replace trplnt=0 if trplnt==.
label var trplnt "Agroforestry (ha)"
**** irrigation
recode F09 (1=1 "Yes")(2 .=0 "No"), gen(irr)
label var irr "Irrigaton(=1 if yes)"
gen irri=hect if irr==1
replace irri=0 if irri==.
label var irri "Irrigation (ha)"

**** fallow
recode F01 (5 = 1 "Yes")(nonm = 0 "No"), gen(fll)
label var fll "Fallow (=1 if yes)"
gen fllw=hect if fll==1
replace fllw=0 if fllw==.
label var fllw "Fallow (ha)"

keep cluster hh prchsd field mz_plt tnrhct crp ownclt rntn inhrtd allctd rntd wlkin hect tnr dmfml soil soilero trpl trplnt irr irri fll fllw prov dist lndacq
save plt12, replace

** hh-level fertilizer and other investment
use $RALS12/field_cult, clear
bysort cluster hh: egen nmfld=count(field)
label var nmfld "Number of plots"
recode FL12 (2 .=0)(1=1), gen(manure)
bysort cluster hh: egen man=sum(manure)
recode man (0 .=0)(nonm=1),gen(orgmanu)
label var orgmanu "Organic fertilizer(=1 if yes)"

bysort cluster hh:egen frtlz=sum(FL14+FL16)
label var frtlz "Fertilizer (kgs)"
recode frtlz (0=0 "No")(nonm=1 "Yes"), gen(frt)
label var frt "Fertilizer (=1 yes)"
duplicates drop cluster hh, force

keep cluster hh orgmanu frtlz frt prov dist nmfld
save orgmnr12, replace

**tenure hh level
use $RALS12/field, clear
*** tenure status
recode F05 (1 2 =1 "Titled")(3 4 5 7 .=0 "Non-titled"), gen(tnr)
label var tnr "Land tenure (=1 if yes)"
bysort cluster hh: egen tnr_s=sum(tnr) // number of tenured plot
recode tnr_s (0 =0)(nonm=1), gen(ttl)
label var ttl "Land tenure (=1 if yes)"
bysort cluster hh: egen lndttl = sum(hect) if ttl==1
replace lndttl=0 if lndttl==.
label var lndttl "Land tenure (ha)"
bysort cluster hh: egen hct=sum(hect) if F01==1
label var hct "Total hectares of cultivated land"

*** gender of decision maker
bysort cluster hh: gen mh=1 if F04==1 | F04== 4| F04== 6| F04== 8| F04== 10 //2 3 5 7 9 11
bysort cluster hh: egen MH=sum(mh)
bysort cluster hh: gen FH=1 if MH==0
replace FH=0 if FH==.
bysort cluster hh: egen nump=count(F01)
bysort cluster hh: replace MH=0 if MH < nump
replace MH=1 if MH>1
bysort cluster hh: gen JH=1 if MH==0 & FH==0
replace JH=0 if JH==.
label var MH "Male decision making (=1 if yes)"
label var FH "Female decision making (=1 if yes)"
label var JH "Joint decision making (=1 if yes)"

*** land usage
recode F01 (1=1 "Yes")(nonm=0 "No"), gen(own)
bysort cluster hh: egen ownc=sum(own)
recode ownc (0 .=0)(nonm=1), gen(owncl)
bysort cluster hh: egen ownclt=sum(hect) if owncl==1
replace ownclt=0 if ownclt==.
label var ownclt "Own cultivated (ha)"

recode F01 (2 3=1 "Yes")(nonm=0 "No"), gen(rnt)
bysort cluster hh: egen rentin=sum(rnt)
recode rentin (0 .=0)(nonm=1), gen(rntin)
bysort cluster hh: egen rntn=sum(hect) if rntin==1
replace rntn=0 if rntn==.
label var rntn "Rent/Borrowed in (ha)"
*** planting maize
rename F15 crp
recode crp (1=1)(2/66 .=0),gen(mz)
bysort cluster hh: egen mz_t=sum(mz)
recode mz_t (0 =0)(nonm=1), gen(mzp)
label var mzp "Planting maize (=1 if female)"
recode crp (1/4 6/7 9 12/15 17 57 18 22=0 "Subsistence crop")(5 8 10/11 16 19 20 60 61 64 66 21 =1 "Cash crop"), gen(cshcrpi)
bysort cluster hh: gen cshcrp_i=sum(cshcrpi)
recode cshcrp_i (0=0)(nonm=1), gen(cshcrp)
label var cshcrp "Cash crop planted (=1 if yes)"

*** investment behavior
**** preventing soil erosion
recode F11 (0 .=0 "No")(nonm=1 "Yes"), gen(soilero)
bysort cluster hh: egen sil_t=sum(soilero)
recode soilero (0 =0)(nonm=1),gen(sle)
label var sle "Soil and land management (=1 if yes)"
bysort cluster hh: egen sler=sum(hect) if sle==1
replace sler=0 if sler==.
label var sler "Soil and land management (ha)"
**** planting trees
recode F12 (0 .=0 "No")(nonm=1 "Yes"), gen(tr)
bysort cluster hh: egen tr_t=sum(tr)
recode tr_t (0 =0)(nonm=1),gen(trpln)
label var trpln "Agroforestry (=1 if yes)"
bysort cluster hh: egen trplnt=sum(hect) if trpln==1
replace trplnt=0 if trplnt==.
label var trplnt "Agroforestry (ha)"
**** irrigation
recode F09 (1=1 "Yes")(2 .=0 "No"), gen(i)
bysort cluster hh: egen ir=sum(i)
recode ir (0 =0)(nonm=1), gen(irr)
label var irr "Irrigation (=1 if yes)"
bysort cluster hh: egen irri=sum(hect) if irr==1
replace irri=0 if irri==.
label var irri "Irrigation (ha)"

**** fallow
recode F01 (5=1 "Yes")(nonm =0 "No"), gen(f)
bysort cluster hh: egen fl=sum(f)
recode fl (0 =0)(nonm=1), gen(fll)
label var fll "Fallow (=1 if yes)"
bysort cluster hh: egen fllw=sum(hect) if fll==1
replace fllw=0 if fllw==.
label var fllw "Fallow (ha)"

duplicates drop cluster hh, force
keep cluster hh mzp tnr tnr_s sle sler lndttl ownclt rntn trpln trplnt irr irri prov ttl JH MH FH hct cshcrp ir tr_t sil_t fllw fll
save hh_tnr12, replace 

** seed cost
/*use $RALS12/seed, clear
bysort cluster hh: gen seedcost=st05_conv*ST04+ST06*st07_conv
keep cluster hh seedcost
replace seedcost=0 if seedcost==.
duplicates drop cluster hh, force
save seed12, replace*/

** total income
**maize sale and cost
use $RALS12/maizesales, clear
recode MS05(5=1 "yes")(nonm=0 "no"), gen(FRAi)
bysort cluster hh: egen FRA=sum(FRAi)
replace FRA=1 if FRA >= 1
rename (MS06 price gvsales_maize) (fradistance maizeprice maizesale)
label var FRA "If a household sell maize to FRA(=1)"
bysort cluster hh: gen maizerev= gvsales_maize_actprice
replace maizerev=0 if maizerev==.
bysort cluster hh: gen cost= (MS07*kgsold_barter)/ms08_conv
replace cost=0 if cost==.
bysort cluster hh: gen maize=maizerev-cost
label var maize "Maize profit"
duplicates drop cluster hh, force
keep cluster hh FRA fradistance maize maizeprice maizerev
save mz12, replace

*crop sale and cost
use $RALS12/cropsales, clear 
bysort cluster hh: gen ttl_crpi=(S09A*kgsold_total)/s09b_conv //price per unit we convert unit into price per kilogram then calculate total price
replace ttl_crpi=0 if ttl_crpi==.
bysort cluster hh: gen ttl_crpt=sum(ttl_crpi)
bysort cluster hh: gen cost= (S08A*kgsold_total)/s08b_conv
replace cost=0 if cost==.
bysort cluster hh: gen ttl_crp=ttl_crpt-cost
duplicates drop cluster hh, force
keep cluster hh ttl_crp ttl_crpt
save crp12, replace

*cassava sale
use $RALS12/cassava_sales, clear
bysort cluster hh: gen ttl_cssvi=kgsold_total*price_kg
replace ttl_cssvi=0 if ttl_cssvi==.
bysort cluster hh: gen ttl_cssv=sum(ttl_cssvi)
duplicates drop cluster hh, force
keep cluster hh ttl_cssv
save cssv12, replace

*livestock sale and cost
use $RALS12/livestock_sales, clear
bysort cluster hh: gen ttl_lvstck=sum(totlv_inc)
duplicates drop cluster hh, force
keep cluster hh ttl_lvstck
save lvstck12, replace

*fish sale and cost
use $RALS12/fish, clear
bysort cluster hh: egen ttl_fsh= sum(FISH01 + FISH02 + FISH03 + FISH04 + FISH05 + FISH06 + FISH07 + FISH08+ FISH09 + FISH10 + FISH11 + FISH12)
egen long hhid=group(cluster hh)
duplicates drop hhid, force
keep cluster hh ttl_fsh
save fsh12, replace

*vegetable and fruit sale and cost
use $RALS12/veg_fruit, clear
bysort cluster hh: gen ttl_vgfrti=totvf_sold*kg_price
bysort cluster hh: gen ttl_vgfrt=sum(ttl_vgfrti)
egen long hhid=group(cluster hh)
duplicates drop hhid, force
keep cluster hh ttl_vgfrt
save frt12, replace

*non-farm business
use $RALS12/business, clear
egen long hhid=group(cluster hh)
replace Tot_bus=0 if Tot_bus==.
bysort cluster hh: egen ttl_bz=sum(Tot_bus)
duplicates drop hhid, force
keep cluster hh ttl_bz
save bz12, replace

*wage 
use $RALS12/salwage, clear
replace totwage=0 if totwage==.
replace inkind_wage=0 if inkind_wage==.
bysort cluster hh: egen ttl_wage=sum(totwage+inkind_wage)
duplicates drop cluster hh, force
keep cluster hh ttl_wage
save wage12, replace

*sum up all income sources
use id12, clear
merge 1:1 cluster hh using mz12, nogen force
merge 1:1 cluster hh using crp12, nogen force
merge 1:1 cluster hh using cssv12, nogen force
merge 1:1 cluster hh using lvstck12, nogen force
merge 1:1 cluster hh using fsh12, nogen force
merge 1:1 cluster hh using frt12, nogen force
merge 1:1 cluster hh using bz12, nogen force
merge 1:1 cluster hh using wage12, nogen force
*merge 1:1 cluster hh using seed12, nogen force

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
bysort cluster hh: gen ttl_inc=9.52*(maizerev + ttl_crpt + ttl_cssv + ttl_lvstck + ttl_fsh + ttl_vgfrt + ttl_bz + ttl_wage)/(1000*4.86)
bysort cluster hh: gen ttl_frm=9.52*(ttl_crp + ttl_cssv + ttl_vgfrt + maize)/(1000*4.86) //profit
bysort cluster hh: gen frm_inc=9.52*(ttl_crpt + ttl_cssv + ttl_vgfrt+maizerev)/(1000*4.86) //gross
foreach rev in maizerev ttl_crpt ttl_cssv maize ttl_vgfrt{
	gen s_`rev'=9.52*(`rev')/(1000*4.86)
}
label var ttl_inc "Total household Income"
save id12, replace

** natural capital
use $RALS12/field, clear
egen hhid = concat(cluster hh dist)
bysort hhid: egen land=sum(hect)
label var land "Landholding size (ha)"
duplicates drop hhid, force
keep cluster hh hhid land
destring hhid, replace
save land12, replace

** access to credit
use $RALS12/loans_credit, clear
replace LNA01=0 if LNA01==2
bysort cluster hh: egen sum=sum(LNA01)
recode sum (0=0 "No")(nonm=1 "Yes"), gen(crdt)
label var crdt "Obtaining credit(=1 if yes) "
duplicates drop cluster hh, force
keep cluster cluster hh crdt prov dist
save crdt12, replace

** asset
use $RALS12/asset, clear  
egen hhid = concat(cluster hh dist)
keep cluster hh hhid asset AST01
reshape wide AST01,i(cluster hh) j(asset)
local varlist "AST011 AST012 AST013 AST014 AST015 AST016 AST017 AST018 AST019 AST0110 AST0111 AST0112 AST0113 AST0114 AST0115 AST0116 AST0117 AST0118 AST0119 AST0120 AST0121 AST0122 AST0123 AST0124 AST0125 AST0126 AST0127 AST0128 AST0129 AST0130 AST0131 AST0132 AST0133 AST0134 AST0135 AST0136 AST0137 AST0138 AST0139 AST0140 AST0140 AST0141 AST0142"
foreach x in `varlist'{
	replace `x'=0 if `x'==2
	replace `x'=0 if `x'==.
}
pca `varlist'
predict asst
keep cluster hh hhid asst
destring hhid, replace
save asset12, replace

** livestock
use $RALS12/livestock, clear
egen hhid = concat(cluster hh dist)

bysort cluster hh: gen cttl=1 if lstock==1
bysort cluster hh: gen cattle=cttl*LS02
replace cattle=0 if cattle==.

bysort cluster hh: gen shp=1 if lstock==4
bysort cluster hh: gen sheep=shp*LS02
replace sheep=0 if sheep==.

bysort cluster hh: gen gts=1 if lstock==2
bysort cluster hh: gen goats=gts*LS02
replace goats=0 if goats==.

bysort cluster hh: gen pgs=1 if lstock==3
bysort cluster hh: gen pigs=pgs*LS02
replace pigs=0 if pigs==.

bysort cluster hh: gen chckn=1 if lstock==6
bysort cluster hh: gen chicken=chckn*LS02
replace chicken=0 if chicken==.

bysort cluster hh: egen ct=sum(cattle)
bysort cluster hh: egen sh=sum(sheep)
bysort cluster hh: egen gt=sum(goats)
bysort cluster hh: egen pg=sum(pigs)
bysort cluster hh: egen ch=sum(chicken)
bysort cluster hh: gen tlu=0.7*ct +0.1*sh +0.1*gt +0.2*pg +0.01*ch 
duplicates drop cluster hh, force
keep cluster hh hhid tlu
//Conversion factors are: cattle = 0.7, sheep = 0.1, goats = 0.1, pigs = 0.2, chicken = 0.01
destring hhid, replace
label var tlu "Tropical Livestock Unit"
save tlu12, replace
 
** distance to road
use $RALS12/distance_agserv, clear
keep if keyserv==2
rename KS01 km_trmc
label var km_trmc "Distance to the nearest tarmac(mainroad)(km)"
gen time=KS03*60 if KS04==2
replace time=KS03 if KS04==1
label var time "Time to the nearest paved road (min)"
keep cluster hh km_trmc prov dist time
save rd12, replace

** merge
**plot-level
use plt12, clear
merge m:1 cluster hh using id12, nogen force
merge m:1 cluster hh using FRAdis12, nogen force
merge m:1 cluster hh using socio12, nogen force
merge m:1 cluster hh using land12, nogen force
merge m:1 cluster hh using asset12, nogen force
merge m:1 cluster hh using tlu12, nogen force
merge m:1 cluster hh using crdt12, nogen force
merge m:1 cluster hh using orgmnr12, nogen 
merge m:1 cluster hh using rd12, nogen
merge m:1 cluster hh using insec12, nogen
merge m:1 cluster hh using first12, nogen

foreach m in land tlu insec {
	replace `m'=0 if `m'==.
}
gen year=2012
save RALS12_plt, replace

**HH-level
use id12, clear
merge 1:1 cluster hh using FRAdis12, nogen force
merge 1:1 cluster hh using socio12, nogen force
merge 1:1 cluster hh using land12, nogen force
merge 1:1 cluster hh using asset12, nogen force
merge 1:1 cluster hh using tlu12, nogen force
merge 1:1 cluster hh using crdt12, nogen force
merge 1:1 cluster hh using orgmnr12, nogen
merge 1:1 cluster hh using hh_tnr12, nogen
merge 1:1 cluster hh using rd12, nogen
merge m:1 cluster hh using insec12, nogen
merge m:1 cluster hh using first12, nogen

foreach m in land tlu insec {
	replace `m'=0 if `m'==.
}
gen year=2012
save RALS12_hh, replace