clear*
cls 

*Open test dataset and name some vars (just for testing)
insheet using "test.csv", clear
ren v1 workerid 
ren v2 firmid 
ren v3 year 
ren v4 log_wage 
ren v7 female 


/* TESTING BELOW */

global path_to_bin ""  //Fill this with your current local folder!


ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath(${path_to_bin}) nthreads(8) getres
qui su dalpha
assert inrange(r(Var), 0.10353934003413184-0.00001 ,  0.10353934003413184+0.00001)

*To do: add more tests here :) 