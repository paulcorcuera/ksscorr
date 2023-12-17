clear*
cls 

frames reset
cd "C:\Users\steve\Desktop\vchdfe\bin"
insheet using "test.csv", clear
ren v1 workerid 
ren v2 firmid 
ren v3 year 
ren v4 log_wage 
ren v6 age 
ren v7 female 


set seed 1234
cap drop rand 
gen rand = runiform(20,55)


ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath("C:\Program Files (x86)\VarianceComponentsHDFE\vchdfe\bin")
ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath("C:\Program Files (x86)\VarianceComponentsHDFE\vchdfe\bin") v nthreads(8) partialout(female rand) getres


*qui su bii_first 
*assert inrange(r(Var),.71954288-0.000001,.71954288+0.000001)