** Rebecca Joseph, University of Nottingham, 2023
** File: cleaning_datasets.do
** Requires: Created using Stata MP v17. Install package cleanplots.
** Desc: Creates bar charts using prepared dataset

net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
set scheme cleanplots

frames reset

*** Log
capture log close log3
log using "logfile_graphs.txt", text replace name(log3)


**************************
use "clean_ds.dta"

// age <18
count if age<18	// n=40
drop if age<18
count

**** Define postcode area for most common codes
gen city=""
replace city="Birmingham" if pcode2=="B"
replace city="Paisley" if pcode2=="PA"
replace city="Newcastle" if pcode2=="NE"
replace city="Sheffield" if pcode2=="S"
replace city="Glasgow" if pcode2=="G"
replace city="Inverness" if pcode2=="IV"
encode city, gen(city1)


*** BMI category by postcode area
replace bmicat=9 if bmicat==.
label define bmi 9 "Missing", add

forval X=1/6 {
	levelsof city if city1==`X', clean local(city)
	di "`city'"
	count if city1==`X'
	graph hbar if city1==`X', over(bmicat) allcat title("`city' (N=`r(N)')") name("b`X'", replace)
}
graph combine b1 b5 b4 b6 b2 b3, xcommon name("bmi", replace) title("BMI category by postcode area") 
graph export bmi_pcode.tif, replace width(1800)


*** Diabetes type by postcode area
tab dmtype,m
replace dmtype=9 if dmtype==.
label define type 9 "Missing", add
tab dmtype

forval X=1/6 {
	levelsof city if city1==`X', clean local(city)
	di "`city'"
	count if city1==`X'
	graph hbar if city1==`X', over(dmtype) allcat title("`city' (N=`r(N)')") name("d`X'", replace)
}

graph combine d1 d5 d4 d6 d2 d3, xcommon title("Diabetes type by postcode area") name("type",replace)
graph export dmtype_pcode.tif, replace width(1800) name(type)


*** Age group by postcode area
forval X=1/6 {
	levelsof city if city1==`X', clean local(city)
	di "`city'"
	count if city1==`X'
	graph hbar if city1==`X', over(agecat) allcat title("`city' (N=`r(N)')") name("a`X'", replace)
}

graph combine a1 a5 a4 a6 a2 a3, xcommon title("Age group by postcode area") name("type",replace)
graph export age_pcode.tif, replace width(1800) name(type)


*** Blood pressure by postcode area
label define yesno 9 "missing", add
replace highbp=9 if highbp==.
tab highbp

forval X=1/6 {
	levelsof city if city1==`X', clean local(city)
	di "`city'"
	count if city1==`X'
	graph hbar if city1==`X', over(highbp) allcat title("`city' (N=`r(N)')") name("bp`X'", replace)
}

graph combine bp1 bp5 bp4 bp6 bp2 bp3, xcommon title("Having high blood pressure, by postcode area") name("type",replace)
graph export highbp_pcode.tif, replace width(1800) name(type)


******
log close log3
frames reset
exit

