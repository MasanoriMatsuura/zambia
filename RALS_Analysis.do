** Land tenure, farm investment, and agricultural productivity in zambia
** Masanori Matsuura
** 2022/10/01
* install
ssc install mvprobit
ssc install ivreg2, replace
ssc install ranktest, replace
ssc install psmatch2
ssc install outreg2
ssc install coefplot, replace
*/

clear all
set more off
global figure="C:\Users\mm_wi\Documents\research\gender_decision\data\figure"
global table="C:\Users\mm_wi\Documents\research\gender_decision\data\table"
global data="C:\Users\mm_wi\Documents\research\gender_decision\data\clean"
cd "C:\Users\mm_wi\Documents\research\gender_decision\data\out"

/** import plot level datasets
use $data\RALS15_plt, clear
append using $data\RALS12_plt

recode crp (1/4 6/7 9 12/15 17 57 18 22=0 "Subsistence crop")(5 8 10/11 16 19 20 60 61 64 66 21 =1 "Cash crop"), gen(cshcrp)
label var cshcrp "Cash crop planted (=1 if yes)"

recode rntn (0 = 0 "No") (nonm = 1 "Yes"), gen(rnt)
label var rnt "Rented in (=1 if yes)"

** cleaning
label var asst "Asset index"
label var prchsd "Purchased (=1 if yes)"
label var allctd "Allocated (=1 if yes)"
label var inhrtd "Inherited (=1 if yes)"
label var wlkin "Just walk in (=1 if yes)"
replace tnr=0 if tnr==2
drop if tnr==.
gen ln_dst=log(dist_plot)
label var ln_dst "Distance from home to plot (km)(log)"
gen ln_inc=log(ttl_inc+1)
//gen ln_mz=log(maizesale+1)

gen age_sq=(age*age)/100
label var age_sq "Age aquared/100"
save data_analysis_plt, replace

**Table A1, determinants of land tenure security 
eststo clear
global control "prchsd allctd inhrtd rntn pssblchng dmfml hhschl cshcrp mtrlnl lcl age hhsize_a crdt asst tlu time" //
eststo: probit tnr $control i.year i.prov, vce(robust) 
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

eststo: reghdfe tnr $control, a(hhid year prov) vce(robust) 
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

esttab using $table\frst_plt.rtf,  b(%4.3f) se replace nogaps nodepvar starlevels(* 0.1 ** 0.05 *** 0.01) label nocons order($control) keep($control) s(hh province year N, label("Province dummy" "Year dummy" "Observations"))

**Table 4, Impact of tenure on investment by IPWRA and household FE
eststo clear

global control "dmfml prchsd allctd inhrtd rntn pssblchng cshcrp mtrlnl lcl age hhschl hhsize_a asst tlu time i.year i.prov" //hect
eststo: teffects ipwra (soilero $control) (tnr $control ,probit), atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit), atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit), atet vce(robust)

eststo: teffects ipwra (soilero $control) (tnr $control ,probit) if dmfml==1, atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit) if dmfml==1, atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit) if dmfml==1, atet vce(robust)

eststo: teffects ipwra (soilero $control) (tnr $control ,probit) if dmfml==0, atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit) if dmfml==0, atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit) if dmfml==0, atet vce(robust)

gen use=e(sample)
esttab using $table\hetero_tnr_inv.rtf, b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

eststo clear
global control "dmfml prchsd allctd inhrtd rntn pssblchng cshcrp mtrlnl lcl age hhschl hhsize_a asst tlu time" //hect
eststo: reghdfe soilero tnr $control , a(hhid year prov) vce(robust)
eststo: reghdfe trplnt tnr $control, a(hhid year prov) vce(robust)
eststo: reghdfe irri tnr $control, a(hhid year prov) vce(robust)

eststo: reghdfe soilero tnr $control if dmfml==1, a(hhid year prov) vce(robust)
eststo: reghdfe trplnt tnr $control if dmfml==1, a(hhid year prov) vce(robust)
eststo: reghdfe irri tnr $control if dmfml==1, a(hhid year prov) vce(robust)

eststo: reghdfe soilero tnr $control if dmfml==0, a(hhid year prov) vce(robust)
eststo: reghdfe trplnt tnr $control if dmfml==0, a(hhid year prov) vce(robust)
eststo: reghdfe irri tnr $control if dmfml==0, a(hhid year prov) vce(robust)

esttab using $table\hetero_tnr_inv_fe.rtf, b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

**Table 5, heterogeneous impact of tenure on investment IPWRA for decomposing matrilineal and patrilineal
eststo clear

global control "dmfml prchsd allctd inhrtd rntn pssblchng cshcrp mtrlnl lcl age hhschl hhsize_a asst tlu time i.year i.prov" //hect

eststo: teffects ipwra (soilero $control) (tnr $control ,probit) if dmfml==1 & mtrlnl==0, atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit) if dmfml==1 & mtrlnl==0, atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit) if dmfml==1 & mtrlnl==0, atet vce(robust)

eststo: teffects ipwra (soilero $control) (tnr $control ,probit) if dmfml==0 & mtrlnl==0, atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit) if dmfml==0 & mtrlnl==0, atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit) if dmfml==0 & mtrlnl==0, atet vce(robust)

esttab using $table\hetero_tnr_pat.rtf, b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons

eststo clear
eststo: teffects ipwra (soilero $control) (tnr $control ,probit) if dmfml==1 & mtrlnl==1, atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit) if dmfml==1 & mtrlnl==1, atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit) if dmfml==1 & mtrlnl==1, atet vce(robust)

eststo: teffects ipwra (soilero $control) (tnr $control ,probit) if dmfml==0 & mtrlnl==1, atet vce(robust)
eststo: teffects ipwra (trplnt $control) (tnr $control ,probit) if dmfml==0 & mtrlnl==1, atet vce(robust)
eststo: teffects ipwra (irri $control) (tnr $control ,probit) if dmfml==0 & mtrlnl==1, atet vce(robust)

esttab using $table\hetero_tnr_mat.rtf, b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons

**Table 1 and 2, descriptive statistics Titled vs non-titled in 1st Wave

sum soilero trplnt irri prchsd inhrtd allctd rntn pssblchng dmfml cshcrp if year==2012 & use==1 & tnr==1
sum soilero trplnt irri prchsd inhrtd allctd rntn pssblchng dmfml cshcrp if year==2012 & use==1 & tnr==0

foreach m in soilero trplnt irri prchsd inhrtd allctd rntn pssblchng dmfml cshcrp { 
ttest `m' if use==1 & year==2012, by(tnr)
}

** Table 2, 3, 4
ttest tnr if use==1, by(dmfml)
ttest hect if use==1, by(dmfml)

tab dmfml tnr if use==1, row chi2
ttest dmfml  if use==1, by(tnr)


** robustness checks
**Table A5, tenure and investment with dummy　outcome variable
use data_analysis_plt, clear
eststo clear
global control "prchsd allctd inhrtd rntn pssblchng dmfml hhschl cshcrp mtrlnl lcl hect age  hhsize_a asst tlu time"

psmatch2 tnr $control i.year i.prov, out(soilero) n(1) com caliper(0.05) noreplace

global control "tnr dmfml prchsd allctd inhrtd rntn pssblchng cshcrp mtrlnl lcl age hhschl hhsize_a asst tlu time i.year i.prov" //hect

eststo:  reghdfe soil tnr#dmfml $control if _support==1, vce (r) a(hhid year prov)

eststo: reghdfe trpl tnr#dmfml $control if _support==1, vce (r) a(hhid year prov)

eststo:  reghdfe irr tnr#dmfml  $control if _support==1, vce (r) a(hhid year prov)

esttab using $table\robust_tnr_inv2.rtf, b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))

**Table A6 restricted sample: sample to those households that have both titled and not titled land 
use data_analysis_plt, clear
bysort cluster hh year: egen tnr_n=sum(tnr)
drop if tnr_n==0
drop if nmfld==tnr_n

eststo clear
global control "prchsd allctd inhrtd rntn pssblchng dmfml hhschl cshcrp mtrlnl lcl  age  hhsize_a asst tlu time"
//hect
gen tnrfml=tnr*dmfml

label var tnrfml "Tenure*Female"

global control "tnr dmfml prchsd allctd inhrtd rntn pssblchng  cshcrp mtrlnl lcl age hhschl hhsize_a asst tlu time i.year i.prov" //hect

eststo:  reghdfe soilero tnr#dmfml $control , vce (r) a(hhid year prov)

eststo: reghdfe trplnt tnr#dmfml $control , vce (r) a(hhid year prov)

eststo:  reghdfe irri tnr#dmfml  $control , vce (r) a(hhid year prov)

esttab using $table\hetero_tnr_inv_robust.rtf, b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons order(tnr tnrfml prchsd allctd inhrtd rntn pssblchng hect cshcrp mtrlnl lcl age hhschl hhsize_a asst tlu time) s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))*/

**import household level data
use $data\RALS15_hh, clear
append using $data\RALS12_hh

** household id
sort cluster hh
egen id=group(cluster hh)
label var id "Household ID"

** cleaning
label var asst "Asset index"
gen ln_dst=log(dstnc+0.01)
label var ln_dst "Average distance from home to plot (km)(log)"
foreach m in nmfld hct orgmanu orgm mzp crdt hhschl rntn female hhsize_a irri trplnt sler irr trpln sle {
	replace `m'=0 if `m'==.
} 

drop if tnr==.

recode category (1 2=1 "0 to 4.00 ha")(3=0 "5 to 19.99ha"), gen(small)
label var small "Smallholder"

gen age_sq=(age*age)/100
label var age_sq "Age aquared/100"

recode mtrlnl (1=0)(0=1), gen(ptrlnl)
label var ptrlnl "Patrilineal household"

** treatment variables
sort id year
bysort id: gen diff_ttl1 = ttl[_n] - ttl[_n-1] //1であれば0->1を示す 
drop if diff_ttl1==-1
replace diff_ttl1=0 if diff_ttl1==.
bysort id: egen tenure_status=sum(diff_ttl1)
label var tenure_status "Treatment household"
drop if tenure_status==0 & ttl==1

** income
gen ln_ttlfrm=log(ttl_frm+1)
label var ln_ttlfrm "Farm income (log)"
label var ttl_frm "Farm income"
save data_analysis_hh, replace

**Table 1 descriptive statistics
global control "ttl FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time i.year i.prov"

reghdfe ln_ttlfrm $control, a(hhid) vce(r) 
gen use=e(sample)

sum ttl_frm insec sle trpln irr orgmanu frt fll FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time if year==2012 & use==1 & tenure_status==1
 
sum ttl_frm insec sle trpln irr orgmanu frt fll FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time if year==2012 & use==1 & tenure_status==0 

foreach m in ttl_frm insec sle trpln irr orgmanu frt fll FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time {
	ttest `m' if year==2012 & use==1, by(tenure_status)
}


** Table 2
ttest FH  if use==1 & year==2012, by(tenure_status)
ttest mtrlnl if use==1 & year==2012, by(FH)

** Table A1 Factors affecting land tenure security
global control "FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time i.year i.prov" //sler trplnt irri
eststo clear
eststo: probit ttl $control, vce(r)
eststo: reghdfe ttl $control, a(id year) vce(r)
esttab using $table\frst_plt.rtf,  b(%4.3f) se replace nogaps nodepvar starlevels(* 0.1 ** 0.05 *** 0.01) label nocons

** Impact of land tenure on farm investment by PSM-DiD(TWFE)
** PSM
drop if year==2012 & ttl==1
global control "FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time i.year" //sler trplnt irri
psmatch2 tenure_status $control if year==2012, out(sle) com cal(0.005)
drop if _support==0 //remove household out of common support assumption

** Table 4 Heterogeneous association between land tenure security and farm investment among gender of decision makers: PSM-DiD estimates
global control "FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time" //sler trplnt irri
eststo clear
global outcome1 sle trpln irr  //sle trpln irr orgmanu frt fll sler trplnt irri orgm frtlz fllw
foreach out in $outcome1{
    eststo: reghdfe `out' ttl#FH $control, a(id prov year) vce(r)
}

foreach out in $outcome1{
    eststo: reghdfe `out' ttl#FH#mtrlnl $control, a(id prov year) vce(r)
	}
	
esttab using $table\hetero_tnr_inv_kin.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 


** Table 6 and Table A4, Determinants of household welfare PSM-DiD
use data_analysis_hh, clear

global control "ttl FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time i.year i.prov" //sler trplnt irri

eststo clear
eststo: reg ln_ttlfrm ttl , vce(r) //sler trplnt irri
eststo: reg insec ttl, vce(r) // sler trplnt irri

eststo: reg ln_ttlfrm $control, a(hhid) vce(r) 
eststo: reg insec $control, a(hhid) vce(r) 

drop if year==2012 & ttl==1
global control "FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time i.year i.prov" //sler trplnt irri
psmatch2 ttl $control if year==2015, out(sle) com cal(0.01)
drop if _support==0

global control "FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time" //sler trplnt irri
eststo clear
global outcome2 ttl_frm insec 
foreach out in $outcome2{
    eststo: reghdfe `out' ttl $control, a(id prov year) vce(r)
}

eststo: reghdfe insec ln_ttlfrm ttl $control, a(id) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

esttab using $table\prdctvty_hh_full.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))

**Heterogeneous analysis
**Table 7 and Table A4, interactoin between gender and tenure/investment on household welfare
global control "FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time" 
eststo clear
foreach out in $outcome2{
    eststo: reghdfe `out' ttl#FH#mtrlnl $control, a(id prov year) vce(r)
}

esttab using $table\hetero_hh.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons order(ttl sler trplnt irri  FH JH ttlfml ttljh slrfml slrjh trpfml trpjh irrifml irrijh ) keep(ttl sler trplnt irri  FH JH ttlfml ttljh slrfml slrjh trpfml trpjh irrifml irrijh ) s(hh province control N, label("Household FE" "Province dummy" "Year dummy" "Control variables" "Observations"))
esttab using $table\hetero_hh_full.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons order(ttl sler trplnt irri  FH JH ttlfml ttljh slrfml slrjh trpfml trpjh irrifml irrijh )  s(hh province control N, label("Household FE" "Province dummy" "Year dummy" "Control variables" "Observations"))


** Robustness checks
** household welfare
use data_analysis_hh, clear


*** tenure, investment, and welfare
*robustness
**Table A 2 Determinants of household welfare without farm investment
eststo clear
global control "ttl FH JH mtrlnl age lcl land hhsize_a FRA cshcrp hhschl crdt tlu asst time i.year i.prov"

eststo: reg ln_ttlfrm ttl , vce(r) 

eststo: reg insec ttl , vce(r) 
eststo: reg ln_ttlfrm $control, vce(r) 
eststo: reg insec $control, vce(r) 

eststo: reghdfe ln_ttlfrm $control, a(id) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

eststo: reghdfe insec $control, a(id) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

global control "ttl FH JH mtrlnl age lcl nmfld hhsize_a cshcrp small hhschl crdt tlu asst time i.year i.prov"

eststo: reghdfe insec ln_ttlfrm $control, a(hhid) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace


esttab using $table\prdctvty_hh_app.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons keep(lndttl FH JH ln_ttlfrm) s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))

esttab using $table\prdctvty_hh_app_full.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))

**Table A7 Determinants of household welfare (HH-level, area weighterd land tenure)
eststo clear
global control "lndttl sler trplnt irri FH JH mtrlnl age lcl nmfld hhsize_a cshcrp hhschl crdt tlu asst time i.year i.prov"

eststo: reg ln_ttlfrm lndttl , vce(r) 

eststo: reg insec lndttl , vce(r) 
eststo: reg ln_ttlfrm $control, vce(r) 
eststo: reg insec $control, vce(r) 

eststo: reghdfe ln_ttlfrm $control, a(id) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

eststo: reghdfe insec $control, a(id) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace

global control "lndttl sler trplnt irri FH JH mtrlnl age lcl nmfld hhsize_a cshcrp hhschl crdt tlu asst time i.year i.prov"

eststo: reghdfe insec ln_ttlfrm $control, a(hhid) vce(r) 
quietly estadd local hh Yes, replace
quietly estadd local province Yes, replace
quietly estadd local year Yes, replace


esttab using $table\robust_area.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons keep(lndttl lndttl sler trplnt irri FH JH ln_ttlfrm) s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))

esttab using $table\robust_area_full.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons s(hh province year N, label("Household FE" "Province dummy" "Year dummy" "Observations"))