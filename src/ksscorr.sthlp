{smcl}
{viewerjumpto "Syntax" "ksscorr##syntax"}{...}
{viewerjumpto "Description" "ksscorr##description"}{...}
{viewerjumpto "Options" "ksscorr##options"}{...}
{viewerjumpto "Examples" "ksscorr##examples"}{...}
{viewerjumpto "References" "ksscorr##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:ksscorr} {hline 2}}Bias Correction of Variance Components in Two-Way FE Models based on Kline, Saggio and Soelvsten (2020){p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:ksscorr}
{cmd:,} {opth first:id(firstidvar)} {opth second:id(secondidvar)} {opt timevar(tvar)} {opth outcome:id(outid)}  {opt apppath(binpath)} [{help ksscorr##options_table:options}]{p_end}


{marker options_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main Identifiers}
{synopt: {opt first:id(firstidvar)}}variable that identifies individuals (eg:  {it:workerid}, {it:studentid}){p_end}
{synopt: {opt second:id(secondidvar)}}variable that identifies groups (eg: {it:firmid}, {it:teacherid}){p_end}
{synopt: {opt timevar(tvar)}}time variable (eg: {it:year}, {it:quarter}){p_end}
{synopt: {opt outcome:id(out)}}outcome variable (eg: {it:logwage}, {it:studentgrades}){p_end}

{syntab:Path to Executable}
{synopt: {opth apppath(str)}}the path to the bin folder of the Julia executable. You must download mannually from this {browse "https://github.com/HighDimensionalEconLab/VarianceComponentsHDFE.jl/releases/tag/v0.2.1.8":link} {p_end}

{syntab:VCHDFE Executable Options (see {browse "https://highdimensionaleconlab.github.io/VarianceComponentsHDFE.jl/dev/Executable/":here})}

{synopt : {opth lev:el(str)}}leave-out level; options are observation ({opt obs}) and match ({opt match}). Default is {opt match} {p_end}
{synopt : {opt partial:out(covars)}}covariates to be partialled-out before performing two-way FE correction{p_end}

{synopt : {opt nthreads(#)}}number of cores to be used in the Julia routine. Default is 1 (no multithreading used) {p_end}
{synopt : {opth algo:ritm(str)}}algorithm to be used for bias correction; options are Exact ({opt exact}) and Johnson–Lindenstrauss ({opt JLA}). Default is {opt JLA} {p_end}
{synopt : {opt nsim:ulations(#)}}number of simulations used in the JLA algorithm. Default is 200 {p_end}

{synopt : {opt nofirst}}this option excludes computation of the corrected variance of the fist fixed effect {p_end}
{synopt : {opt nocov}}this option excludes computation of the corrected covariance of the fixed effects {p_end}
{synopt : {opt verbose}}increases the verbosity level of the Julia subroutine {p_end}
{synopt : {opth firstlab:el(str)}}attach a variable label to the first identifier for the Julia subroutine {p_end}
{synopt : {opth secondlab:el(str)}}attach a variable label to the second identifier for the Julia subroutine  {p_end}

{synopt : {opt getres:ults}}add the output from the KSS routine to the dataset (Pii, Bii, and indicator of the leave-out connected set). For more details please refer to the paper {p_end}

{synopt : {opt lincom(zcovars)}}regress firm effects against a set of covariates; correct inference requires KSS bias correction.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ksscorr} is a Stata wrapper of the Julia executable that performs bias correction of variance components in two-way fixed effects models (see {browse "https://github.com/HighDimensionalEconLab/VarianceComponentsHDFE.jl/tree/main":here}).
In particular, suppose you are running a high dimensional linear model {hilite: y = X b + e }, where {hi: b} contains fixed effects in two large dimensions (e.g. worker and firms). Any quadratic form of {hi:b} is biased (see {browse "https://en.wikipedia.org/wiki/Quadratic_form_(statistics)":here}). 
In a setting with heteroskedastic errors we cannot construct a consistent estimator of the variance of errors to perform bias correction; instead, we can use a leave-out variance estimator to perform this correction. This is what the routine will perform.

{marker examples}{...}
{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. use employeremployeedata, clear}{p_end}

{pstd}Simple case - no optional arguments{p_end}
{phang2}{cmd:. ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath("some_path/vchdfe/bin")}{p_end}
{hline}

{pstd}As above, but also partial-out some covariates{p_end}
{phang2}{cmd:. ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath("some_path/vchdfe/bin") partialout(female age)}{p_end}
{hline}

{pstd}Get results from the Julia routine into the Stata dataset{p_end}
{phang2}{cmd:. ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath("some_path/vchdfe/bin") getres }{p_end}
{hline}

{pstd}Simple case and regress estimated firm effects against female dummy{p_end}
{phang2}{cmd:. ksscorr , firstid(workerid) secondid(firmid) timevar(year) outcomeid(log_wage) apppath("some_path/vchdfe/bin") lincom(female) }{p_end}
{hline}

{marker support}{...}
{title:Support and updates}

{pstd}{cmd:ksscorr} requires the {cmd:inshell} package.{p_end}
{phang2}{cmd:. ssc install inshell }{p_end}


{marker references}{...}
{title:References}

{phang}
Kline, Saggio and Soelvsten. "Leave-out Estimation of Variance Components".
{it:Econometrica, 88(5), 1859–1898, 2020.}
{browse "https://eml.berkeley.edu/~pkline/papers/KSS2020.pdf":[link]}
{p_end}

