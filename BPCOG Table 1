/****************************************************************************************************************
* Program: BPCOG Table 1.SAS            											
* Folder: S:\Intmed_Rsrch2\GenMed\Restricted\BP COG\Aim 1\Data Management\Data\Freeze2020_Master\SAS Progs  
* Author: Nick Tilton                          																
* Created: 03/23/20                            																
* Summary: Creates table 1 for hisp vs. white and female vs male analyses										
* Revisions: 																								
*****************************************************************************************************************/

/* Please provide info about this repository */
%let repo_name = BP-COG_Aim1; /* Repository name on GitHub */
%let repo_maintainer = Nick Tilton;
%let repo_description = Create analytic file for Aim 1 and run models for all individual projects (Black vs. White, Hispanic vs. White, Male vs. Female);

%put repo_name := &repo_name;  /* Github Repository name */

/*****---- SAS Setup starts here -----*****/ 

/* Define global macro variable names */
%global 
 SAS_work_dir
 computer_name
 sas_batchmode   /* Y/N */
 sas_progname    
 sas_fullname
;

/* Store path to SAS working directory in `SAS_work_dir` macro variable */
/* Based on `https://communities.sas.com/t5/SAS-Communities-Library/Find-current-directory-path/ta-p/485785` */
/* Note the location of the file*/
filename setupc  "C:/Users/Public/SAS_work_directory.sas";
%include setupc;
%let SAS_work_dir =  %SAS_work_directory;
%put SAS_work_dir := &SAS_work_dir;   
%put sysuserid    := &sysuserid;   /* User id */

/*--- Load repository assets ----*/ 
filename fx "&SAS_work_dir/_load_repo_assets.inc";
%include fx;

%computer_name;  /* Stores computer name in `computer_name` global macro variable */
%put computer_name := &computer_name;
%our_sas_session_info;
/***** SAS Setup ends here *****/

/*****----  Our program starts here  *****/

%let BPCOGpath = S:\Intmed_Rsrch2\GenMed\Restricted\BP COG;

%let MasterPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Master Data;
%let AnalysPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Analytic File;
%let FormatPath = &BPCOGpath.\Aim 1\Data Management\Data\formats;
%let IntrmdPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Intermediate Files;
%let ExclusPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Exclusions;
%let SenstvPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Sensitivity Data;
%let CogPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Cognitive Data;
%let MemPath = &BPCOGpath.\Aim 1\Data Management\Data;
%let CohortPath = &BPCOGpath.\Original Cohort Files;

libname frz "&MasterPath";
libname mem "&MemPath";
libname fmts "&FormatPath";
libname intm "&IntrmdPath";
libname anls "&AnalysPath";
libname cog "&CogPath";
libname excl "&ExclusPath";
libname sens "&SenstvPath";
libname ARIC "&CohortPath.\ARIC\SAS Files";
libname CARDIA "&CohortPath.\CARDIA\SAS Files";
libname CHS "&CohortPath.\CHS\SAS Files";
libname FOS "&CohortPath.\FOS\SAS Files";
libname MESA "&CohortPath.\MESA\SAS Files";
libname NOMAS "&CohortPath.\NOMAS\SAS Files";

options fmtsearch=(fmts work) nofmterr;


proc format library=fmts;
value alcfmt 
0 = 'None'
1 = '>0, <=6'
2 = '>6, <=13'
3 = '>13';
value racefmt_tb
0 = 'All'
2 = 'Non-Hispanic White'
3 = 'Hispanic or Latino';
value sexfmt_tb
0 = 'All'
2 = 'Male'
3 = 'Female';
value sexfmt
0 = 'Male'
1 = 'Female';
run;

%macro today_YYMMDD();
%let z=0;
%let y2=%sysfunc(today(),year2.);
%let m2=%sysfunc(today(),month2.);
%let d2=%sysfunc(today(),day2.);
%if %eval(&m2)<=9 %then %let m2 = &z&m2;
%if %eval(&d2)<=9 %then %let d2 = &z&d2;
%let ymd = &y2&m2&d2;
&ymd;
%mend;

%let ymd = %today_YYMMDD();


%macro table1(samp);

%if &samp = hvw %then %do;
	%let OutputPath = &BPCOGpath.\Aim 1\Hispanic vs White\Post-Freeze Analysis;
	%let cmplt = cmplt3;
	%let alc =; %let afmt =;
	%let tablevar = racebpcog; %let tablefmt = racefmt_tb;
	%let cvar1 = female0; %let cfmt1 = sexfmt;
	%let studylist = 'aric','cardia','chs','fos','mesa','nomas';
	%let span = coginspanish englishprof; %let spanfmt = yna engprof;
%end;
%else %do;
	%let OutputPath = &BPCOGpath.\Aim 1\Sex Differences\Post-Freeze Analysis;
	%let cmplt = cmplt1;
	%let alc = alccat; %let afmt = alcfmt;
	%let tablevar = sex; %let tablefmt = sexfmt_tb;
	%let cvar1 = racebpcog; %let cfmt1 = racefmt_hvw;
	%let studylist = 'aric','cardia','chs','fos','nomas';
	%let span =;  %let spanfmt =; 
%end;

libname sr "&OutputPath.\SAS Results";

%let catlist = &cvar1 educ &alc smoke physact hxafib htntx &span;
%let fmtlist = &cfmt1 educ &afmt yna yna yna yna &spanfmt;
%let conlist = age0 age0coh bmi waistcm glucosef cholldl mean_sbp_all sbpbpcog0 mean_dbp_all dbpbpcog0 bpprior bppriortime bptotal fuptime gcp ngcp;
%let clist2 = exf nexf;
%let clist3 = mem nmem;
%let conlist2 = &conlist &clist2 &clist3;
%let ncat = %sysfunc(countw(&catlist));
%let ncon = %sysfunc(countw(&conlist2));

data mcovs2;
set anls.mcovs2;
sex=female0+2;
if &samp=1 and studyname in (&studylist) and &cmplt=1;
run;

	/* categorical vars */
%do mi = 1 %to %eval(&ncat);
	%let cov = %scan(&catlist,&mi);
	proc freq data=mcovs2;
	tables &cov * &tablevar / chisq;
	ods output crosstabfreqs=tcat&mi chisq=tcat&mi._c;
	run;

	data tcat&mi;
	set tcat&mi;
	if not missing(&cov);
	drop _TYPE_ _TABLE_ percent rowpercent missing;
	run;

	data tcat&mi._c;
	set tcat&mi._c;
	if Statistic = 'Chi-Square';
	keep Table Prob;
	run;

	data tcat&mi;
	set tcat&mi tcat&mi._c;
	sord = &mi;
	run;

	proc delete data=tcat&mi._c; run;
%end;

data ttcat_all;
retain table cov_level;
format &tablevar &tablefmt..;
set tcat:;
length cov_level $ 30;
if &tablevar=. and not missing(cov_level) then &tablevar=0;
table = tranwrd(tranwrd(table,"Table ","")," * &tablevar","");
run;

%do mi = 1 %to %eval(&ncat);
	%let tfmt = %scan(&fmtlist,&mi).;
	data ttcat_all;
	set ttcat_all; 
	if not missing(%scan(&catlist,&mi)) then do;
		cov_level=put(%scan(&catlist,&mi),&tfmt);
		cov_num=%scan(&catlist,&mi);
	end; 
	drop %scan(&catlist,&mi);
	run; 
%end;

proc sort data=ttcat_all; by sord prob descending cov_num descending &tablevar;

data sr.Table1_continuous_&samp._&ymd;
retain table &tablevar._t1;
length &tablevar._t1 $20;
set t1mcall;
if varname = 'age0' then do;
	Median=floor(Median); Q1=floor(Q1); Q3=floor(Q3);
end;
&tablevar._t1 = put(&tablevar,&tablefmt..);
drop sord varname &tablevar;
run;

	/* continuous vars */
data sord;
length varname $15;
do i=1 to &ncon;
	varname=scan("&conlist2",i);
	sord=i;
	output;
end;
drop i;
run;
	
proc means data=mcovs2;
var &conlist;
class &tablevar;
output out=t1mc(drop=_type_ _freq_) median= q1= q3= / autoname;
run;

proc means data=mcovs2;
var &clist2;
class &tablevar;
where nexf>=1;
output out=t1mc_a(drop=_type_ _freq_) median= q1= q3= / autoname;
run;

proc means data=mcovs2;
var &clist3;
class &tablevar;
where nmem>=1;
output out=t1mc_b(drop=_type_ _freq_) median= q1= q3= / autoname;
run;

data t1mc;
merge t1mc t1mc_a t1mc_b;
run; 

proc transpose data=t1mc out=t1mc2; run;

data t1mc3;
set t1mc2;
varname=trim(tranwrd(_name_,'_'||scan(_name_,countw(_name_,'_'),'_'),""));
stat=scan(_name_,countw(_name_,'_'),'_');
if missing(_LABEL_) then _LABEL_ = varname;
drop _name_;
run;

proc sort data=t1mc3; by varname _LABEL_; run;

proc transpose data=t1mc3 out=t1mc4;
by varname _LABEL_;
id stat;
var col:;
run;

data t1mc4;
set t1mc4;
format &tablevar &tablefmt..;
table=_LABEL_;
if median=. then delete;
median=round(median,0.1);
q1=round(q1,0.1);
q3=round(q3,0.1);
if _NAME_ = 'COL1' then &tablevar=0;
else if _NAME_ = 'COL2' then &tablevar=2;
else if _NAME_ = 'COL3' then &tablevar=3;
drop _LABEL_ _NAME_;
run;

proc sort data=t1mc4; by varname &tablevar; run;

%do mi = 1 %to &ncon;
	%let convar = %scan(&conlist2,&mi);
	proc npar1way data=mcovs2 wilcoxon;
	class &tablevar;
	var &convar;
	ods output WilcoxonTest = t1mcp_&mi;
	run;

	data t1mcp_&mi;
	length dependent varname $ 15;
	format nValue1 PVALUE6.4;
	set t1mcp_&mi;
	if _N_ = 10; 
	varname = variable; 
	keep nValue1 varname;
	run;
%end;

data t1mcp;
length varname $ 15;
set t1mcp_:;
format Prob PVALUE6.4;
Prob = nValue1;
if varname = 'age0' then sord=0;
else sord = %eval(&ncat + 1);
keep varname Prob sord;
run;

data t1mcall;
set t1mc4 t1mcp;
drop sord;
run;

proc sort data=sord; by varname; run;
proc sort data=t1mcall; by varname descending &tablevar; run;
data t1mcall;
merge t1mcall sord; by varname;
run;

data t1mcall;
set t1mcall;
if _N_>1 then tb1=lag(table);
if missing(table) then table=tb1;
drop tb1;
run;
proc sort data=t1mcall; by sord descending &tablevar; run;

data sr.Table1_categorical_&samp._&ymd;
retain table cov_level &tablevar._t1;;
length &tablevar._t1 $20;
set ttcat_all;
if missing (&tablevar) and not missing (cov_level) then &tablevar=0;
&tablevar._t1 = put(&tablevar,&tablefmt..);
drop sord &tablevar cov_num;
run;

	/* Cognitive Means */
proc datasets lib=work memtype=data nolist;
   modify mcovs2;
     attrib _all_ label=' ';
     attrib _all_ format=;
run;
quit;

proc means data=mcovs2 mean std;
var gcp exf mem;
class &tablevar;
output out=cogmean(drop=_type_ _freq_) mean= std= / autoname;
run;  

proc ttest data=mcovs2;
var gcp exf mem;
class &tablevar;
ods output ttests=cogtt;
run;

data _null_;
set cogtt;
if variable='gcp' and variances="Unequal" then call symputx("gcp_pval",put(probt,pvalue6.4));
if variable='exf' and variances="Unequal" then call symputx("exf_pval",put(probt,pvalue6.4));
if variable='mem' and variances="Unequal" then call symputx("mem_pval",put(probt,pvalue6.4));
run;

data cogmean;
retain &tablevar gcp_mean gcp_stddev gcp_pval exf_mean exf_stddev exf_pval mem_mean mem_stddev exf_pval;
length gcp_pval exf_pval mem_pval $6;
set cogmean;
if missing(&tablevar) then do;
	&tablevar=0;
	gcp_pval="&gcp_pval"; exf_pval="&exf_pval"; mem_pval="&mem_pval";
end;
else do; gcp_pval=" "; exf_pval=" "; mem_pval=" "; end;
run;

proc freq data=mcovs2;
tables &tablevar;
ods output onewayfreqs=owf (drop=table F_&tablevar);
run;

data owf;
retain &tablevar._t1;
length &tablevar._t1 $20;
set owf end=eof;
&tablevar._t1 = put(&tablevar,&tablefmt..);
output;
if eof then do;
	&tablevar=0;
	&tablevar._t1 = put(&tablevar,&tablefmt..);
	percent=cumpercent;
	frequency=cumfrequency;
	output;
end;
drop cumfrequency cumpercent;
run;

proc sort data=cogmean; by &tablevar; run;
proc sort data=owf; by &tablevar; run;

data t1mean;
merge owf cogmean;
by &tablevar;
array numarr[*] gcp_mean gcp_stddev exf_mean exf_stddev mem_mean mem_stddev;
do i=1 to dim(numarr);
	numarr[i]=round(numarr[i],0.01);
end;
drop i;
run;

proc sort data=t1mean out=sr.table1_means_&samp._&ymd (drop=&tablevar); by descending &tablevar; run;

proc datasets library=work memtype=data nolist;
delete mcovs2 ttcat_: t1mc: tcat: sord tt owf t1mean cogtt cogmean;
run; quit;

%mend tab1e1;

%table1(hvw);
%table1(fvm);
