** Land tenure, farm investment, and agricultural productivity in zambia
** Masanori Matsuura
** 2025/9/14
/* install
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
foreach m in nmfld hct orgmanu orgm mzp crdt hhschl rntn female hhsize_a irri trplnt sler irr trpln sle fll fllw {
	replace `m'=0 if `m'==.
} 

drop if tnr==.

recode category (1 2=1 "0 to 4.00 ha")(3=0 "5 to 19.99ha"), gen(small)
label var small "Smallholder"

gen age_sq=(age*age)/100
label var age_sq "Age aquared/100"

recode mtrlnl (1=0)(0=1), gen(ptrlnl)
label var ptrlnl "Patrilineal household"

replace firstson=0 if firstson==.

** income
gen ln_ttlfrm=log(ttl_frm+1) 
label var ln_ttlfrm "Farm profit (log)"
label var ttl_frm "Farm profit"

gen ln_ttlinc=log(ttl_inc+1)
label var ln_ttlinc "Household income (log)"
label var ttl_inc "Household income"

gen ln_frminc=log(frm_inc+1)
label var ln_frminc "Farm income (log)"

gen crp_inc = s_ttl_crpt+s_ttl_cssv+s_maizerev
label var crp_inc "Crop income"

gen ln_crp=log(s_ttl_crpt+s_ttl_cssv+s_maizerev+1)
label var ln_crp "Crop income (log)"

gen yield=frm_inc/land
gen ln_yld=log(yield+1)
label var ln_yld "Yield (log)"

gen ln_vg = log(s_ttl_vgfrt+1)
label var ln_vg "Cash crop income (log)"

** Creating interactions
gen ttl_FH=lndttl*FH
gen ttl_FH_mtr=lndttl*FH*mtrlnl
gen ttl_mtr=lndttl*mtrlnl
gen FH_mtr=FH*mtrlnl

label var ttl_FH_mtr "Land tenure × Female × Matrilineality"
label var ttl_FH "Land tenure × Female"
label var ttl_mtr "Land tenure × Matrilineality"
label var FH_mtr "Female × Matrilineality"

save data_analysis_hh, replace

**Table 1 descriptive statistics
use data_analysis_hh, clear

eststo pre: estpost sum ttl frm_inc yield crp_inc s_ttl_vgfrt sle trpln irr mtrlnl FH age age_sq hhsize hhschl crdt FRA tlu asst time if year == 2012
 
eststo post: estpost sum ttl frm_inc yield crp_inc s_ttl_vgfrt sle trpln irr mtrlnl FH age age_sq hhsize hhschl crdt FRA tlu asst time if year == 2015

eststo Diff: qui estpost ttest ttl frm_inc yield crp_inc s_ttl_vgfrt sle trpln irr mtrlnl FH age age_sq hhsize hhschl crdt FRA tlu asst time, by(ttl)

esttab pre post using $table\table1_a.csv, ///
	label nogap nonotes nomtitle nonumber b(%4.3f) ///
	cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3)) se(pattern(0 0 1) fmt(3)) ") ///
	mgroups("Difference", pattern(1 1 0)) replace
	
** Table 2
eststo treatment1: estpost sum ttl if FH==1 
eststo control1: estpost sum ttl if FH==0 
eststo Diff1: estpost ttest ttl, by(FH)
eststo treatment2: estpost sum mtrlnl if FH==1 
eststo control2: estpost sum mtrlnl if FH==0
eststo Diff2: estpost ttest mtrlnl , by(FH)

esttab treatment1 control1 Diff1 treatment2 control2 Diff2 using $table\table2.csv, ///
	label nogap nonotes nomtitle nonumber b(%4.3f) ///
	cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3)) se(pattern(0 0 1) fmt(3)) ") ///
	mgroups("Land tenure" "Kinship" , pattern(1 1 0)) replace

**Heterogeneous analysis FE
**Table 3 and Table A4, Heterogeneous association between gender and tenure on household welfare
global control1 "age hhsize_a hhschl crdt FRA tlu asst time i.prov#i.year" //sler trplnt irri
eststo clear

eststo model1: reghdfe ln_frminc ttl#mtrlnl $control1  [pw = weight] if FH==1, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr 

eststo model2: reghdfe ln_yld ttl#mtrlnl $control1  [pw = weight] if FH==1, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model3: reghdfe ln_crp ttl#mtrlnl $control1  [pw = weight] if FH==1, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model4: reghdfe ln_vg ttl#mtrlnl $control1 [pw = weight] if FH==1, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model5: reghdfe ln_frminc ttl#mtrlnl $control1  [pw = weight] if FH==0, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model6: reghdfe ln_yld ttl#mtrlnl $control1 [pw = weight] if FH==0, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model7: reghdfe ln_crp ttl#mtrlnl $control1   [pw = weight] if FH==0, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model8: reghdfe ln_vg ttl#mtrlnl $control1 [pw = weight] if FH==0, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model9: reghdfe ln_frminc ttl#mtrlnl $control1  [pw = weight], a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr 

eststo model10: reghdfe ln_yld ttl#mtrlnl $control1  [pw = weight], a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model11: reghdfe ln_crp ttl#mtrlnl $control1  [pw = weight], a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model12: reghdfe ln_vg ttl#mtrlnl $control1 [pw = weight], a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"
* table
esttab model1 model2 model3 model4 model5 model6 model7 model8 using $table\table3.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) replace keep(1.ttl#1.mtrlnl 0.ttl#1.mtrlnl 1.ttl#0.mtrlnl)
esttab model1 model2 model3 model4 model5 model6 model7 model8 using $table\tableA1.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) replace 
esttab model9 model10 model11 model12 using $table\table3_rev.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) replace keep(1.ttl#1.mtrlnl 0.ttl#1.mtrlnl 1.ttl#0.mtrlnl)

estimates drop model1 model2 model3 model4 model5 model6 model7 model8 model9 model10 model11 model12

** Mediation analysis: household level 
eststo model1: reghdfe ln_vg sle trpln irr ttl#mtrlnl $control1  [pw = weight], a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model2: reghdfe ln_vg sle trpln irr ttl#mtrlnl $control1  [pw = weight] if FH==1, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model3: reghdfe ln_vg sle trpln irr ttl#mtrlnl $control1 [pw = weight] if FH==0, a(cluster year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

esttab model1 model2 model3 using $table\table4.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) keep(sle trpln irr 1.ttl#1.mtrlnl 0.ttl#1.mtrlnl 1.ttl#0.mtrlnl) replace
esttab model1 model2 using $table\tableA2.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) replace

estimates drop model1 model2

** Mechanism: land tenure and investment
eststo model1: reghdfe sle ttl#mtrlnl  $control1  [pw = weight] if FH==1, a(cluster year) vce(r)

eststo model2: reghdfe trpln ttl#mtrlnl $control1 [pw = weight] if FH==1, a(cluster year) vce(r)

eststo model3: reghdfe irr ttl#mtrlnl $control1  [pw = weight] if FH==1, a(cluster year) vce(r)

eststo model4: reghdfe sle ttl#mtrlnl $control1 [pw = weight] if FH==0, a(cluster year) vce(r)

eststo model5: reghdfe trpln ttl#mtrlnl $control1  [pw = weight] if FH==0, a(cluster year) vce(r)

eststo model6: reghdfe irr ttl#mtrlnl $control1 [pw = weight] if FH==0, a(cluster year) vce(r)

esttab model1 model2 model3 model4 model5 model6 using $table\table5.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) keep( 1.ttl#1.mtrlnl 0.ttl#1.mtrlnl 1.ttl#0.mtrlnl) replace
esttab model1 model2 model3 model4 model5 model6 using $table\tableA3.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) replace

estimates drop model1 model2 model3 model4 model5 model6

**Robustness check:
reg ln_vg ttl#mtrlnl $control1 i.cluster i.prov#i.year [pw = weight] if FH==1, vce(r)
eststo model1: psacalc delta 1.ttl#1.mtrlnl

**TableA5
eststo model1: reghdfe ln_vg ttl#mtrlnl i.prov#i.year [pw = weight] if FH==1, a(cluster year) vce(r)
eststo model2: reghdfe ln_vg sle trpln irr ttl#mtrlnl i.prov#i.year [pw = weight] if FH==1, a(cluster year) vce(r)

eststo model3: reg ln_vg ttl#mtrlnl age hhsize_a hhschl crdt FRA tlu asst time  [pw = weight] if FH==1, vce(r)
eststo model4: reg ln_vg sle trpln irr ttl#mtrlnl age hhsize_a hhschl crdt FRA tlu asst time [pw = weight] if FH==1, vce(r)

eststo model5: reghdfe ln_vg ttl#mtrlnl [pw = weight] if FH==1,  vce(r)
eststo model6: reghdfe ln_vg sle trpln irr ttl#mtrlnl [pw = weight] if FH==1, vce(r)

esttab model1 model2 model3 model4 model5 model6 using $table\tableA5.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) keep( 1.ttl#1.mtrlnl 0.ttl#1.mtrlnl 1.ttl#0.mtrlnl sle trpln irr) replace

estimates drop model1 model2 model3 model4 model5 model6

**Table A6 HH FE
eststo model1: reghdfe ln_vg ttl#mtrlnl $control1 [pw = weight] if FH==1, a(id year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

eststo model2: reghdfe ln_vg ttl#mtrlnl $control1 [pw = weight] if FH==0, a(id year) vce(r)
qui estadd local control "Yes"
qui estadd local clyr "Yes"

esttab model1 model2 using $table\tableA6.csv, se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) replace
estimates drop model1


** Mechanism: Impact of land tenure on farm investment (DR estimator, plot-level)
**import plot-level data
use $data\RALS15_plt, clear
append using $data\RALS12_plt

label var tnr "Land tenure"
** household id
sort cluster hh
egen id=group(cluster hh)
label var id "Household ID"

/*oreach outcome in soil soilero trpl trplnt irr irri{
	teffects ipwra (`outcome' time age tlu mz_plt i.cluster i.year) ///
	(tnr time age tlu mz_plt i.cluster i.year) if mtrlnl==1 & dmfml == 1  ,osample(over2)
}
foreach outcome in soil soilero trpl trplnt irr irri{
	teffects ipwra (`outcome' time age tlu mz_plt i.cluster i.year) ///
	(tnr time age tlu mz_plt i.cluster i.year) if mtrlnl==0 & dmfml == 1, osample(over1)
}*/
save data_analysis_plt, replace

** Table 1
use data_analysis_plt, clear

eststo pre: qui estpost sum tnr soil trpl irr dmfml mz_plt if year == 2012 
 
eststo post: qui estpost sum tnr soil trpl irr dmfml mz_plt if year == 2015

eststo Diff: qui estpost ttest tnr soil trpl irr dmfml mz_plt, by(year)

esttab pre post Diff using $table\table1_b.csv, ///
	label nogap nonotes nomtitle nonumber b(%4.3f) ///
	cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3)) se(pattern(0 0 1) fmt(3)) ") ///
	mgroups("Difference", pattern(1 1 0)) replace

** Table 6: FE
foreach outcome in soil trpl irr {
	eststo model1_`outcome': reghdfe `outcome' tnr#mtrlnl age hhsize_a hhschl crdt FRA tlu asst time mz_plt i.prov#i.year [pw = weight] if dmfml==1, a(cluster year) vce(cluster id) 
	qui estadd local control "Yes"
	qui estadd local hh "Yes"
	qui estadd local year "Yes"
} 

foreach outcome in soil trpl irr {
	eststo model2_`outcome': reghdfe `outcome' tnr#mtrlnl age hhsize_a hhschl crdt FRA tlu asst time mz_plt i.prov#i.year [pw = weight] if dmfml==0, a(cluster year) vce(cluster id) 
	qui estadd local control "Yes"
	qui estadd local hh "Yes"
	qui estadd local year "Yes"
} 

esttab model1_soil model1_trpl model1_irr model2_soil model2_trpl model2_irr ///
	using $table\table6.csv, ///
	se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) ///
	replace
	
esttab model1_soil model1_trpl model1_irr model2_soil model2_trpl model2_irr ///
	using $table\tableA4.csv, ///
	se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) ///
	replace
estimates drop  model1_soil model1_trpl model1_irr model2_soil model2_trpl model2_irr
