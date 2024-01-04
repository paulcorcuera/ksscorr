
cap program drop ksscorr
program define ksscorr 
	version 14
	syntax, FIRSTid(varname num) ///
			SECONDid(varname num) ///
			TIMEVAR(varname num) ///
			OUTCOMEid(varname num) ///
			APPPATH(str) /// PATH TO VCHDFE BIN FOLDER
		   [LEVel(str)] ///LEAVE-OUT LEVEL
		   [PARTIALout(varlist)] /// COVARIATES TO BE PARTIALLED OUT
		   [NTHREADS(int 1)] /// NUMBER OF CORES FOR JULIA MULTITHREADING 
		   [ALGOrithm(str)] /// TYPE OF ALGORITHM USED : EXACT vs JLA
		   [NOFIRST] /// DON'T COMPUTE SOME VARIANCE COMPONENTS
		   [NOCOV] /// DON'T COMPUTE SOME VARIANCE COMPONENTS
		   [NSIMulations(int 200)] /// NUMBER OF JLA SIMULATIONS (DEFAULT: 200)
		   [Verbose] /// INCREASE DEFAULT VERBOSITY LEVEL
		   [FIRSTLABel(str)] /// ATTACH LABEL TO FIRST ID
		   [SECONDLABel(str)] /// ATTACH LABEL TO SECOND ID
		   [GETRESults] /// CREATE LEAVE OUT SET INDICATOR AND ADD Pii and Bii's 
		   [LINCOM(varlist)] /// REGRESS FIRM EFFECTS AGAINST SOME COVARIATES AFTER ROUTINE
	
	*If covariates are specified attach them to a controls local
	if ("`partialout'" != "") unab controls: `partialout'
	if ("`lincom'" != "") unab lincom_controls: `lincom'
	
	*If nthreads not specified we assume its equal to 1
	loc threads = cond(`nthreads'==0,1,`nthreads')
	
	// Parse 
	loc covars = ("`partialout'" != "")
	loc getres = ("`getresults'" != "")
	loc print_level   = cond("`verbose'" == "", 1,2)
	loc algo   = cond("`algorithm'"=="", "JLA", "EXACT")
	loc simul   = cond(`nsimulations'==0, 200 , `nsimulations')
	loc labfir  = cond("`firstlabel'"=="", "Worker" , "`firstlabel'") 
	loc labsec  = cond("`secondlabel'"=="", "Firm" , "`secondlabel'")
	loc kss_level = cond("`level'"=="", "match" , "`obs'")
	loc nofirst = cond("`nofirst'"=="",1,0)
	loc nocov = cond("`nocov'"=="",1,0)
	loc zcovars = ("`lincom'" != "")

	*Check whether inshell in installed as a dependency 
	cap which inshell
	loc rc = c(rc)
	if (`rc') {
		di as error "SSC Package inshell required (to show terminal output in Stata)"
		di as smcl "{err}To install: {stata ssc install inshell}"
		error `rc'
	}

	*Get the executable path and replace all \ chars by /   (this helps some Windows users)
	*local apppath "C:\Program Files (x86)\VarianceComponentsHDFE\vchdfe\bin"
	loc apppath: subinstr loc apppath "\" "/" , all

	*Intermediate files will be stored at Stata's temp folder
	loc tempdir = c(tmpdir)
	loc tempdir: subinstr loc tempdir "\" "/" , all
		
	*Make sure we can save output from KSS
	if (`getres'==1) cap erase "`tempdir'/kss_out.csv"

	*Order data so that we can parse easily in the app (I'll circumvent this issue eventually)
	if (`covars') order `firstid' `secondid' `timevar' `outcomeid' `controls'
	if (!`covars') order `firstid' `secondid' `timevar' `outcomeid' 
	
	

	* Check whether data is sorted by first_id timevar 
	loc ok = ( strpos("`: sortedby'", "`firstid'") == 1) &  ( strpos("`: sortedby'", "`timevar'") == strlen("`firstid'")+2)

	if (`ok') {
		di as text "Data sorted by `firstid' `timevar'; running the program."	
	}
	if (!`ok') {
		di as text "Data doesn't seem to be sorted; sorting by `firstid' `timevar'."	
		sort `firstid' `timevar'
	}

	*Save intermediate file in the temp folder 
	if (`covars'==0){
		qui outsheet `firstid' `secondid' `timevar' `outcomeid' using "`tempdir'/data_for_kss.csv", comma replace 
	}
	if (`covars'==1){
		qui outsheet `firstid' `secondid' `timevar' `outcomeid' `controls' using "`tempdir'/data_for_kss.csv", comma replace 
	}


	*inshell "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" 
	if (c(os)=="Windows"){
		
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'
			
		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'			
			
		if (`getres'==0 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'

		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'

		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'			
			
		if (`getres'==0 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'

		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell set JULIA_NUM_THREADS=`threads' && "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'
			

	}
	if (c(os)!="Windows"){
		
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'
			
		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'			
			
		if (`getres'==0 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'

		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv"
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==0)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==0 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'			
			
		if (`getres'==0 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==0 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'

		if (`getres'==0 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==0 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'"  --covariates `controls' --print_level `print_level' --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==0 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --do_lincom --lincom_covariates `lincom_controls'
			
		if (`getres'==1 & `covars'==1 & `nofirst'==1 & `nocov'==1 & `zcovars'==1)   inshell export JULIA_NUM_THREADS=`threads' ; "`apppath'/vchdfe" "`tempdir'/data_for_kss.csv" --header --algorithm "`algo'" ///
			--simulations `simul' --first_id_display "`labfir'" --second_id_display "`labsec'"  ///
			--leave_out_level "`kss_level'" --print_level `print_level' --write_detailed_csv --detailed_csv_path "`tempdir'/kss_out.csv" --covariates `controls' --do_lincom --lincom_covariates `lincom_controls'
			
	}

	*Erase the created temporary file 
	cap erase "`tempdir'/data_for_kss.csv"	

	
	/* *Check if the part below is needed, i think erase should work on any OS
	if (c(os)=="Windows"){
		erase "`tempdir'/kss_temp.csv"	
	}
	if !(c(os)=="Windows"){
		rm "`tempdir'/kss_temp.csv"	
	}
	*/
	
	
	*This part of the code will merge the variables created during KSS routine to the main data
	if (`getres'==1){
			cap drop observation
			qui gen observation = _n
			
			cap frame drop kss_temp
			frame create kss_temp 
			frame change kss_temp 
			qui import delimited using "`tempdir'/kss_out.csv", delimiter(",") asdouble varn(1) clear
			qui ren *, lower //Make sure no typos from upper case
			
			*New varlist created on KSS
			unab allvars: _all
			local outlist observation first_id_old first_id second_id_old second_id y
			loc keeplist : list allvars-outlist
			
			frame change default 

			*Link frames
			cap drop leave_out_set
			qui frlink 1:1 observation, frame(kss_temp) gen(leave_out_set)
			
			
			*Get vars from kss output
			qui frget `keeplist', from(leave_out_set)
			cap drop observation 
			
			*Dummy for leave-out set
			qui recode leave_out_set (.=0) (else=1) 
			qui la var leave_out_set "Belongs to Leave-Out Connected Set"
			
			*Pii can be rounded to 1 due to computer eps, I'll fix that here
			cap format %15.0g pii
			cap replace pii=0.9999999999999 if pii>0.9999999999999 & !mi(pii)

			*We can get rid of the new frame now
			frame drop kss_temp 
	}

end 