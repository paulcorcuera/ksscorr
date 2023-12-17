clear*
cls 

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


ksscorr , first_id(workerid) second_id(firmid) timevar(year) outcome_id(log_wage) apppath("C:\Program Files (x86)\VarianceComponentsHDFE\vchdfe\bin")
ksscorr , first_id(workerid) second_id(firmid) timevar(year) outcome_id(log_wage) apppath("C:\Program Files (x86)\VarianceComponentsHDFE\vchdfe\bin") v nthreads(8)