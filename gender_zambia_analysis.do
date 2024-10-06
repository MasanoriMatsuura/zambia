********************************************************************************************************************
**Gender, land tenure security, and household welfare: Insights from matrilineal and patrilineal society in Zambia**
********************************************************************************************************************

****************************************************************
**M Matsuura-Kannari, O Chanda, C Umetsu, W Kodama, AHMS Islam**
****************************************************************

*****************************
**Latest update: 2024/10/07**
*****************************

*****************
***data import***
*****************

use data_analysis_hh, clear

**********************************
**Table 1 descriptive statistics**
**********************************

global control "ttl FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time i.year i.prov"

reghdfe ln_ttlfrm $control, a(hhid) vce(r) 
gen use=e(sample) // cleate a cleaned sample

sum ttl_frm insec trplnt irri frtl FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time if year==2012 & use==1 & tenure_status==1
 
sum ttl_frm insec trplnt irri frtl FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time if year==2012 & use==1 & tenure_status==0 

foreach m in ttl_frm insec trplnt irri frtl FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time{
	ttest `m' if year==2012 & use==1, by(tenure_status)
}

***********
**Table 2**
***********
ttest FH  if use==1 & year==2012, by(tenure_status) // detailed summary statistics
ttest mtrlnl if use==1 & year==2012, by(FH)

***************************************************
**Table A1 Factors affecting land tenure security**
***************************************************
global control "FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time i.prov"
eststo clear
eststo: probit tenure_status $control if year==2012 & use==1, vce(r)
eststo: reg tenure_status $control if year==2012 & use==1, vce(r)
esttab using $table\frst_tnr.rtf,  b(%4.3f) se replace nogaps nodepvar starlevels(* 0.1 ** 0.05 *** 0.01) label nocons




*********************************************************************************************************************
**Table 3 and Table A2/A3, Heterogeneous association between gender and tenure on household welfare: PSM-DiD (TWFE)**
*********************************************************************************************************************

*******
**PSM**
*******

use data_analysis_hh, clear
drop if year==2012 & ttl==1
global control "FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time i.prov" //sler trplnt irri
psmatch2 tenure_status $control if year==2012, out(sle) com cal(0.005)
drop if _support==0 //remove household out of common support assumption

*******
**DiD**
*******

global control1 "FH JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time" //sler trplnt irri
global control2 "MH JH ptrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time" //sler trplnt irri

global outcome2 ln_ttlfrm insec 

global treatment1 ttl ttl_FH ttl_FH_mtr ttl_mtr FH_mtr
global treatment2 ttl ttl_MH ttl_MH_ptr ttl_ptr MH_ptr
eststo clear

***********
**Panel A**
***********
foreach out in $outcome2{
    eststo: reghdfe `out' $treatment1 ttl#FH#mtrlnl , a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_FH + ttl_FH_mtr
	lincom ttl + ttl_FH 
	lincom ttl 	
}

foreach out in $outcome2{
    eststo: reghdfe `out' $treatment1 ttl#FH#mtrlnl $control1, a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_FH + ttl_FH_mtr
	lincom ttl + ttl_FH 
	lincom ttl 	
}

esttab using $table\hetero_hh_mt.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

***********
**Panel B**
***********
eststo clear

foreach out in $outcome2{
    eststo: reghdfe `out' $treatment2 ttl#MH#ptrlnl , a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_MH + ttl_MH_ptr
	lincom ttl + ttl_MH 
	lincom ttl	
	}
	
foreach out in $outcome2{
    eststo: reghdfe `out' $treatment2 ttl#MH#ptrlnl $control2 , a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_MH + ttl_MH_ptr
	lincom ttl + ttl_MH 
	lincom ttl	
}


esttab using $table\hetero_hh_pt.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

********************************************************************************
**Robustness check without kinship accounting for measurement error of kinship**
********************************************************************************

*******************************************************************************************************************
**Table A4, Heterogeneous association between gender and tenure on household welfare w/o matrilineal(patrilineal)**
*******************************************************************************************************************

eststo clear
global control1 "FH JH age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time" 
global control2 "MH JH age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time" 

global outcome2 ln_ttlfrm insec 

global treatment1 ttl ttl_FH ttl_FH_mtr ttl_mtr FH_mtr
global treatment2 ttl ttl_MH ttl_MH_ptr ttl_ptr MH_ptr
eststo clear

***********
**Panel A**
***********

foreach out in $outcome2{
    eststo: reghdfe `out' $treatment1 ttl#FH , a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_FH + ttl_FH_mtr
	lincom ttl + ttl_FH 
	lincom ttl 	
}

foreach out in $outcome2{
    eststo: reghdfe `out' $treatment1 ttl#FH $control1, a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_FH + ttl_FH_mtr
	lincom ttl + ttl_FH 
	lincom ttl 	
}

esttab using $table\hetero_hh_mt1.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 


***********
**Panel B**
***********

eststo clear

foreach out in $outcome2{
    eststo: reghdfe `out' $treatment2 ttl#MH , a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_MH + ttl_MH_ptr
	lincom ttl + ttl_MH 
	lincom ttl	
	}
	
foreach out in $outcome2{
    eststo: reghdfe `out' $treatment2 ttl#MH $control2 , a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_MH + ttl_MH_ptr
	lincom ttl + ttl_MH 
	lincom ttl	
}


esttab using $table\hetero_hh_pt1.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

************************************************************************
**Mechanism: Impact of land tenure on farm investment by PSM-DiD(TWFE)**
************************************************************************

******************************************************************************************************************************************
**Table 4 and Table A5 and A6 Heterogeneous association between land tenure security and farm investment among gender of decision makers**
******************************************************************************************************************************************

global control1 "JH mtrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time " 
global control2 "JH ptrlnl age lcl land hhsize_a hhschl FRA crdt tlu asst nmfld time " 

global outcome1 trplnt irri frtl
global treatment1 ttl ttl_FH_mtr ttl_FH  ttl_mtr FH_mtr
global treatment2 ttl ttl_MH_ptr ttl_MH  ttl_ptr MH_ptr

***********
**Panel A**
***********

eststo clear

foreach out in $outcome1{
    eststo: reghdfe `out' $treatment1 ttl#FH#mtrlnl, a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_FH + ttl_FH_mtr
	lincom ttl + ttl_FH 
	lincom ttl 	
}


foreach out in $outcome1{
    eststo: reghdfe `out' $treatment1 ttl#FH#mtrlnl $control1, a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_FH + ttl_FH_mtr
	lincom ttl + ttl_FH 
	lincom ttl 	
}

esttab using $table\hetero_tnr_inv_mt.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

***********
**Panel B**
***********

eststo clear

foreach out in $outcome1{
    eststo: reghdfe `out' $treatment2 ttl#MH#ptrlnl, a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_MH + ttl_MH_ptr
	lincom ttl + ttl_MH 
	lincom ttl 	
}


foreach out in $outcome1{
    eststo: reghdfe `out' $treatment2 ttl#MH#ptrlnl $control2, a(id prov year) vce(r)
	local ttl = r(mean)
	lincom ttl + ttl_MH + ttl_MH_ptr
	lincom ttl + ttl_MH 
	lincom ttl	
}
	
esttab using $table\hetero_tnr_inv_pt.rtf,  b(%4.3f) se replace nogaps starlevels(* 0.1 ** 0.05 *** 0.01) label nocons 

************
**Footnote**
************
bysort mtrlnl: sum asst if JH==1 & _est_est1==1 & year==2012
bysort mtrlnl: sum asst if MH==1 & _est_est1==1 & year==2012
bysort mtrlnl: sum asst if FH==1 & _est_est1==1 & year==2012
                   