** Rebecca Joseph, University of Nottingham, 2023
** File: cleaning_datasets.do
** Requires: Created using Stata MP v17. Install package cleanplots.
** Desc: Uses prepared dataset & performs summary statistics

net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
set scheme cleanplots

frames reset

*** Log
capture log close log2
log using "logfile_summarytables.txt", text replace name(log2)



**************************
use "clean_ds.dta"

capture putdocx clear
putdocx begin	// add tables to word doc

**# Summary of dataset (DROP IF AGE<18)
// age <18
count if age<18	// n=40
drop if age<18


*** continuous vars
// missing data
count if age==.
count if height==.
count if weight==.
count if bmi==.
count if dbp_avg==.
count if sbp_avg==.

// distributions
graph hbox age, name(age, replace)
graph hbox height, name(height, replace)
graph hbox weight, name(weight, replace)
graph hbox bmi, name(bmi, replace)
graph hbox dbp_avg, name(dbp_avg, replace)
graph hbox sbp_avg, name(sbp_avg, replace)

graph combine age height weight bmi dbp_avg sbp_avg


// median and IQR
local vars age height weightkg bmi dbp_avg sbp_avg
qui table (var) (), stat(median `vars') stat(q1 `vars') stat(q3 `vars')	 
collect composite define IQR = q1 q3, delimiter(", ") 	// make result showing "q1, q2"
collect style cell var[age dbp_avg sbp_avg]#result[IQR], nformat(%2.0f) sformat("(%s)")	// format as "(q1, q2)"
collect style cell var[height]#result[IQR], nformat(%4.2f) sformat("(%s)")	// format as "(q1, q2)"
collect style cell var[weightkg bmi]#result[IQR], nformat(%4.1f) sformat("(%s)")	// format as "(q1, q2)"

collect layout (var) (result[median IQR])
putdocx collect
putdocx paragraph


*** categorical vars
// missing data
tabstat miss*, col(stats)	// results are proportion with missing data

// table, counts and percentages
local vars agecat-inspump
qui table (var) (), stat(fvfreq `vars') stat(fvpercent `vars')	 
collect style cell result[fvpercent], nformat(%4.1fc) sformat("%s%%")
collect style row stack, nobinder spacer
collect preview
putdocx collect

// insulin users
tab inspump insulin,m // confirms all insulin pump users are insulin users

tab inspump if insulin==1
tab inspump if insulin==1, m

putdocx save "Summary tables", replace


****** 
log close log2
frames reset
exit

