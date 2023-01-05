** Rebecca Joseph, University of Nottingham, 2023
** File: cleaning_datasets.do
** Requires: Created using Stata MP v17. Requires Stata v16 (frames function)
** Desc: Loads and combines demographics and app data. Cleans each 
**		 of the variables. For time-varying variables, keeps the most
**		 recently recorded observation.

frames reset

*** Log
capture log close log1
log using "logfile_cleaning.txt", text replace name(log1)




**************************
**# LOAD AND PREPARE THE DEMOGRAPHICS DATASET
import delimited "Task4_ehr_demographics.csv"

*** Explore
sum id	// range 1-1000
count // n=891
duplicates report id // one record per id

*** Create age variable
count if birthyear==.	// no missing values
sum birthyear, d	// range 1921-2003 
gen age=2022-birthyear	// age in 2022
sum age,d	// range 19-101
order age, after(birthyear)

*** Convert sex to numeric
tab sex,m	// no missing values
rename sex temp
encode temp, gen(sex)	// destring
order sex, after(age)
drop temp

*** Transform height to m
count if height==.	// no missing values
replace height=round(height)
replace height=height/100	// assume cm, convert to metres
sum height,d	// range 1.38-2.07m

*** Convert dmtype to numeric
rename dmtype temp
encode temp, gen(dmtype)	// destring
drop temp
label define type 1 "type 1" 2 "type 2" 3 "pre-diabetes" 4 "other" 5 "diabetes"
recode dmtype (4=1) (5=2) (2=4) (1=5)	// assign categories to match labels
label values dmtype type
tab dmtype, m	// no missing values

label drop dmtype
label list







**# BLANK DATASET - create dataset with 1000 obs, use to link to other fields
frame create combine
frame combine {
	set obs 1000
	gen id = _n
	
	frlink 1:1 id, frame(default)
	frget *, from(default)
	drop default
}




**# APP DATA - clean and link each set of observations in turn
frame create data
frame change data
import delimited "Task4_app_data.csv"

duplicates drop // duplicates in all variables (n=86)

gen date=date(obs_date,"YMD")	// convert date to numerical var
format date %dD/N/CY
drop obs_date
order id date

count	// 34,637 observations
codebook id	// n=1000 unique ids
sum id	// id range 1-1000

list if _n<10, clean
tab question,m



** Long dataset. For each variable:
*	-> move observations to empty frame
*	-> cleaning steps, inc defining new vars if appropriate
*	-> keep most recent record if >1 record per id
*	-> link with the *combine* dataset

encode question, gen(Q)
label list
/*  
		   1 Postcode
           2 birthyear
           3 bp medications
           4 cholesterol lowering medications
           5 dbp
           6 dmtype
           7 insulin
           8 insulin pump
           9 sbp
          10 sex
          11 weight
*/


*** postcode
frame put if Q==1, into(temp)
frame change temp

duplicates report id // 1 record for all 1000 ids
rename value postcode
gen pcode2=regexs(0) if regexm(postcode,"[A-Z]+")==1 // define postcode area var
keep id postcode pcode2
compress

frame combine {
	frlink 1:1 id, frame(temp)
	frget *, from(temp)
	drop temp
}

frame change data
frame drop temp



*** birth year
frame put if Q==2, into(temp)
frame change temp

duplicates report id // noone has >1 record, everyone has a record
destring value, gen(yob)
sum yob,d // range 1921-2023
keep id yob

frame change combine 
frlink 1:1 id, frame(temp)
frget *, from(temp)
drop temp

count if birthyear!=yob // n=109, all people with missing birthyear
replace birthyear=yob if birthyear==.
drop yob

replace age=2022-birthyear	// update age variable
sum age,d	// new range -1 to 101. Deal with later.

frame change data
frame drop temp



*** dmtype
frame put if Q==6, into(temp)
frame change temp

duplicates report 
duplicates report id	// people can have >1 record
sort id date

encode value, gen(type_add)	// convert to numerical var
label define type 1 "type 1" 2 "type 2" 3 "pre-diabetes" 4 "other" 5 "diabetes"
recode type_add (3=1) (4=2) (2=3) (1=4)	// recode categories to match other ds
label values type_add type
label drop type_add

tab type_add,m

duplicates report id // people can have >1 record
duplicates report id date // noone has >1 per day

bys id (date): keep if _n==_N	// keep the most recent record
tab type_add,m

keep id type_add

frame change combine
frlink 1:1 id, frame(temp)
frget *, from(temp)
drop temp

tab dmtype type,m	// no conflicts based on most recent record
replace dmtype=type_add if dmtype==. // 11 extra values
drop type_add

frame change data
frame drop temp



*** Sex
frame put if Q==10, into(temp)
frame change temp

duplicates report id // people can have >1 record
duplicates report id date  // noone has >1 per day

sort id date
encode value, gen(sex1)	// convert to numerical
tab sex1,m
drop if sex1==3	// n==4 obs. drop if sex is "prefer not to say"
bys id (date): keep if _n==_N	// keep the most recent record

keep id sex1

frame change combine
frlink 1:1 id, frame(temp)
frget *, from(temp)
drop temp

tab sex sex1,m	// no conflicts based on most recent record
replace sex=sex1 if sex==. // 40 extra values
drop sex1

frame change data
frame drop temp



*** Weight
frame put if Q==11, into(temp)
frame change temp

duplicates report
duplicates report id	// multiple records per id
duplicates report id date	// multiple records per id and date possible

drop question Q

// data are mix of kg and stone (and pounds?). Convert to kg.
destring value, gen(weightkg) force
sum weightkg	// range 32.8-172.1
*histogram weightkg	// can't separate kg and pounds?

split value, parse(",") gen(w) destring // extract stone,pounds
replace weightkg=w1*6.35029 + w2*0.453592142840941 if weightkg==.	// convert stones to kg
replace weightkg=round(weightkg,0.1)

keep id date weightkg

bys id date: gen recs=_N	// count number of records per day
bys id date: egen avgweight=mean(weightkg)	// mean weight per date
replace avgweight=round(avgweight,0.1)
gen dif=abs(avgweight-weightkg)	// difference between average and recorded weight
list if recs==3, clean // all cases have at least 2 similar so next step ok
drop if dif>=1	// drop if dif is larger than 1kg

sum avgweight,d	// range 32.8-172.1

bys id (date): keep if _n==_N	// keep most recent record
keep id weightkg

frame change combine
frlink 1:1 id, frame(temp)
frget *, from(temp)
drop temp

frame change data
frame drop temp




*** Blood pressure
frame put if (Q==5|Q==9), into(temp)
frame change temp
duplicates report
duplicates report id date question // >1 obs per date per question 

destring value, replace
drop if value<50	// cleaning: drop low values
drop if value>180	// cleaning: drop high values

bys id date question: gen i=_n
drop Q
reshape wide value, i(id date i) j(question) string	// change to wide dataset
rename valuedbp dbp
rename valuesbp sbp

// dbp should be lower than sbp. If not, assume recording error. Fix.
gen temp=dbp
gen flag=(sbp<dbp & dbp<.)
replace dbp=sbp if flag==1
replace sbp=temp if flag==1
drop temp flag

bys id date: egen dbp_avg=mean(dbp)	// avg if multiple per date... keep all
bys id date: egen sbp_avg=mean(sbp)	// avg if multiple per date... keep all

drop if dbp_avg==.| sbp_avg==.	// drop if only have one of the measurements
bys id (date): keep if _n==_N	// keep most recent record
keep id dbp_avg sbp_avg

frame change combine
frlink 1:1 id, frame(temp)
frget *, from(temp)
drop temp

frame change data
frame drop temp




*** Medicines
foreach X of numlist 3 4 7 8 {
	frame put if (Q==`X'), into(temp)
	frame change temp
	
	di `X'
	levelsof question, clean 

	duplicates report id // multiple records per id
	duplicates report id date 

	bys id date: gen count=_N
	drop if count>1	// if any date has >1 entry, drop those records
	drop if value=="dont know"	// drop if unknown (sets to missing)

	encode value, gen(med`X') // convert to numeric
	bys id (date): keep if _n==_N	// keep most recent record
	
	keep id med`X'
	
	frame change combine
	frlink 1:1 id, frame(temp)
	frget *, from(temp)
	drop temp

	frame change data
	frame drop temp
}

frame change combine
rename med3 bpmeds
rename med4 cholmeds
rename med7 insulin
rename med8 inspump





**# FINAL PREPARATION STEPS
*** Generate BMI, drop extreme values, create categorical version
gen bmi=weight/(height*height)
replace bmi=round(bmi,0.1)
order weight bmi, after(height)

sum bmi,d
*graph hbox bmi
count if bmi<15.7
count if bmi>44.7 & bmi<.
replace bmi=. if bmi<15.7 & bmi>44.7 // possible miscoding of weight

gen bmicat=.
replace bmicat=1 if bmi<18.5
replace bmicat=2 if bmi>=18.5 & bmi<25
replace bmicat=3 if bmi>=25 & bmi<30
replace bmicat=4 if bmi>=30 & bmi<.
label define bmi 1 "Underweight, <18.5" 2 "Healthy weight, 18.5-24.9" ///
	3 "Overweight, 25-29.9" 4 "Obese, 30+" 
label values bmicat bmi
order bmicat, after(bmi)

*** Generate categorical age variable
egen agecat=cut(age), at(0 18 25(10)75 105) icodes
label define age	1 "18-24" ///
					2 "25-34" ///
					3 "35-44" ///
					4 "45-54" ///
					5 "55-64" ///
					6 "65-74" ///
					7 "75+" 
label values agecat age
order agecat, after(age)

*** Define high blood pressure based on dbp and sbp
gen highbp=(dbp_avg>=90 & sbp_avg>=140)
replace highbp=. if dbp_avg==. | sbp_avg==.
order highbp, after(sbp_avg)

*** Change binary indicators with 1 2 to 0 1
recode bpmeds-inspump (1=0) (2=1)
label define yesno 0 "no" 1 "yes"
label values highbp bpmeds-inspump yesno


*** Create variables indicating missing data for each categorical var
order id postcode pcode2 birthyear age height weight bmi dbp_avg sbp_avg
foreach X of varlist sex-inspump {
	gen miss`X'=(`X'==.)
	order miss`X', after(`X')
	label values miss`X' yesno
	label variable miss`X' "Missing data for variable `X'"
	}
order miss*, last

*** Label variables
label var age "Age (years) in 2022"
label var agecat "Age group (years) in 2022"
label var sex "Sex"
label var height "Height (cm)"
label var weightkg "Weight (kg)"
label var bmi "Body mass index"
label var bmicat "Body mass index category"
label var dmtype "Diabetes type"
label var postcode "Postcode"
label var pcode2 "Postcode region"
label var dbp_avg "Diastolic blood pressure"
label var sbp_avg "Systolic blood pressure"
label var highbp "High blood pressure (>=140/90)"
label var bpmeds "Taking blood pressure medicine"
label var cholmeds "Taking cholesterol-lowering medicine"
label var insulin "Using insulin"
label var inspump "Using insulin pump"

save "clean_ds.dta", replace
export delimited using "clean_ds.csv", replace


************
log close log1
frames reset
exit

