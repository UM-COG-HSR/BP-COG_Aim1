/************************************************************************************************************
* Program: BPCOG Analysis 2 - Sensitivity.SAS            											
* Folder: S:\Intmed_Rsrch2\GenMed\Restricted\BP COG\Aim 1\Data Management\Data\Freeze2020_Master\SAS Progs  
* Author: Nick Tilton                          																
* Created: 03/13/20                            																
* Summary: Conducts Sensitivity analyses for Longitudinal models										
* Revisions: 																								
*************************************************************************************************************/

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

options fmtsearch=(fmts) nofmterr;

proc sort data=fos.EX1_8S_17 out=fos_hisp(rename=(ranid=id)); by id; run;
data fos_hisp; 
length newid $25;
set fos_hisp;
hisp_sens=(h700=1);
char_id = put(id,12.);
newid = compress(char_id||'fos');
if hisp_sens=1;
keep newid hisp_sens;
run;

proc sort data=cardia.form1 out=cardia_hisp (keep=ID A01RACE1); by ID; run;
data cardia_hisp;
length newid $25;
set cardia_hisp;
hisp_sens=(a01race1=3);
newid = compress(id||'cardia');
if hisp_sens=1;
keep newid hisp_sens;
run;

/*
proc sort data=chs.levine_main out=chs_hisp (keep=id hisp01); by id; run;
data chs_hisp;
length newid $25;
set chs_hisp;
hisp_sens=(hisp01=1);
char_id = put(id,15.);
newid = compress(char_id||'chs');
if hisp_sens=1;
keep newid hisp_sens;
run;
*/
data sens.hisp_excl;
set /*chs_hisp*/ fos_hisp cardia_hisp;
run;

proc sort data=sens.hisp_excl; by newid; run;
proc sort data=anls.cv3 out=cv_tmp; by newid cogtime_y2; run;
data sens.cv3;
merge cv_tmp (in=in1) sens.hisp_excl (in=in2);
by newid;
if in1;
if in1 and not in2 then hisp_sens=0;
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

/*	&sens - 
		Sensitivity #1: 2+ cog assessments
		Sensitivity #2: Remove participants with hispanic ethnicity from CARDIA, CHS, FOS
*/
	
%macro bpcog_reg_sens(dvar,model,samp,sens);
%if &dvar = GCP %then %let ty = cogtime_y2;
%else %let ty = t_&dvar;

%if &samp = hvw %then %do;
	%let racevar = hisp;
	%let OutputPath = &BPCOGpath.\Aim 1\Hispanic vs White\Post-Freeze Analysis;
	%let studylist = 'aric','cardia','chs','fos','mesa','nomas'; %let studylist2 = cardia chs fos mesa nomas;
	%let alc =;
	%let cmplt = cmplt3;
%end;
%else %do;
	%let racevar = black;
	%let OutputPath = &BPCOGpath.\Aim 1\Sex Differences\Post-Freeze Analysis;
	%let studylist = 'aric','cardia','chs','fos','nomas'; %let studylist2 = cardia chs fos nomas; 
	%let alc = alc1 alc2 alc3;
	%let cmplt = cmplt1;
%end;

%if &sens = 1 %then %do;
	%let ncog = 2;
	%let hispexcl = 0 1;
%end;
%else %do;
	%let ncog = 1;
	%let hispexcl = 0;
%end;

libname sr "&OutputPath.\SAS Results";

%let alist = &studylist2 &ty &racevar female0 age0med10 &racevar*&ty age0med10*&ty female0*&ty educ1 educ2 educ3 educ4 &alc smoke bmimed waistcmmed cholldlmed10 glucosefmed10 physact hxafib ;
%let blist = sbp120m sbp120m*&ty ;
%let clist = htntx htntx*&ty ;

ods graphics on;
ods rtf file="&OutputPath.\Output\Sensitivity\&dvar._Model&Model._Sens&sens._&ymd..rtf";
proc hpmixed data = sens.cv3 noclprint;
class newid;
%if &model = A %then %do; model &dvar = &alist / s cl; %end;
%if &model = B %then %do; model &dvar = &alist &blist / s cl; %end;
%if &model = C %then %do; model &dvar = &alist &blist &clist / s cl; %end;
random int &ty / subject=newid type=un;
where strokeinc=0 and &cmplt=1 and n&dvar >= &ncog and &samp = 1 and hisp_sens in (&hispexcl) and studyname in (&studylist);
ods output ParameterEstimates=sr.&dvar._mod&model._Sens&sens._&ymd;
run;
ods rtf close;
ods graphics off; 

%mend;

/*Hispanic vs. White: Sensitivity #1 and 2*/
%bpcog_reg_sens(GCP,A,hvw,1);
%bpcog_reg_sens(GCP,B,hvw,1);
%bpcog_reg_sens(GCP,C,hvw,1);

%bpcog_reg_sens(EXF,A,hvw,1);
%bpcog_reg_sens(EXF,B,hvw,1);
%bpcog_reg_sens(EXF,C,hvw,1);

%bpcog_reg_sens(MEM,A,hvw,1);
%bpcog_reg_sens(MEM,B,hvw,1);
%bpcog_reg_sens(MEM,C,hvw,1);

%bpcog_reg_sens(GCP,C,hvw,2);

/*Female vs. Male: Sensitivity #1 only*/
%bpcog_reg_sens(GCP,C,fvm,1);
%bpcog_reg_sens(EXF,C,fvm,1);
%bpcog_reg_sens(MEM,C,fvm,1);
