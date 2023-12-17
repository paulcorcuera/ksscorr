clear*
cls

*Check whether inshell in installed as a dependency 
which inshell
loc rc = c(rc)
if (`rc') {
	di as error "SSC Package inshell required (to show terminal output in Stata)"
	di as smcl "{err}To install: {stata ssc install inshell}"
	error `rc'
}

insheet using "C:\Users\steve\Desktop\vchdfe\bin\test.csv", clear
ren v1 workerid 
ren v2 firmid 
ren v3 year 
ren v4 log_wage 
ren v6 age 
ren v7 female 


set seed 1234
cap drop rand 
gen rand = runiform(20,55)

*Get the executable path and replace all \ chars by / 
local apppath "C:\Program Files (x86)\VarianceComponentsHDFE\vchdfe\bin"
loc apppath: subinstr loc apppath "\" "/" , all

*di "`apppath'"

*The file will be stored at the bin path temporarily
loc tempdir = c(tmpdir)
loc tempdir: subinstr loc tempdir "\" "/" , all
*di "`tempdir'"


*Locals that store the different vars 
loc timevar year
loc first_id workerid
loc second_id firmid
loc outcome_id log_wage
loc controls female rand

order `first_id' `second_id' `timevar' `outcome_id' `controls'


* Check whether data is sorted by firstid year 
loc ok = ( strpos("`: sortedby'", "`first_id'") == 1) &  ( strpos("`: sortedby'", "`timevar'") == strlen("`first_id'")+2)

if (`ok') {
	di as text "Data already sorted; running the program."	
}
if (!`ok') {
	di as text "Data doesn't seem to be sorted; sorting by `firstid' `timevar'."	
	sort `first_id' `timevar'
}


outsheet `first_id' `second_id' `timevar' `outcome_id' `controls' using "`tempdir'/data_for_kss.csv", comma replace 


*inshell "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" 
if (c(os)=="Windows"){
	inshell set JULIA_NUM_THREADS=8 && vchdfe "`tempdir'/data_for_kss.csv" --header --covariates `controls'
}
if !(c(os)=="Windows"){
	inshell export JULIA_NUM_THREADS=8 ; vchdfe "`tempdir'/data_for_kss.csv" --header
}

* Erase the created tempfile
cap erase "`tempdir'/data_for_kss.csv"	

*Check if the part below is needed, i think erase should work on any OS
/*
if (c(os)=="Windows"){
	erase "`tempdir'/kss_temp.csv"	
}
if !(c(os)=="Windows"){
	rm "`tempdir'/kss_temp.csv"	
}
*/

frame create kss_temp 
frame change kss_temp 
insheet using .... 

frame change default 
frlink 1:1 obs_id, frame(kss_temp)


frame drop kss_temp 