/************************************************************************************************************
* Program: BPCOG Analysis 3- Appendix.SAS            											*
* Folder: S:\Intmed_Rsrch2\GenMed\Restricted\BP COG\Aim 1\Data Management\Data\Freeze2020_Master\SAS Progs  *
* Author: Nick Tilton                          																*
* Created: 03/13/20                            																*
* Summary: Conducts Longitudinal analyses										*
* Revisions: 																								*
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
%let CogPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Cognitive Data;
%let MemPath = &BPCOGpath.\Aim 1\Data Management\Data;
%let ResultPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Results;

libname frz "&MasterPath";
libname mem "&MemPath";
libname fmts "&FormatPath";
libname intm "&IntrmdPath";
libname anls "&AnalysPath";
libname cog "&CogPath";
libname excl "&ExclusPath";


options fmtsearch=(fmts) nofmterr nosymbolgen;

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

%macro bpcog_reg(dvar,model,samp);
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
	%if &model = E2 %then %do;
		%let strval = 0 1;
		%let cmplt = cmplt1;
	%end;
	%else %if &model = E3 %then %do;
		%let strval = 0;
		%let cmplt = cmplt4;
	%end;
	%else %if &model = E5 %then %do;
		%let strval = 0;
		%let cmplt = cmplt1;
		%let studylist2 =;
	%end;
%end;

libname sr "&OutputPath.\SAS Results";

%let alist = &studylist2 &ty &racevar female0 age0med10 &racevar*&ty age0med10*&ty female0*&ty educ1 educ2 educ3 educ4 &alc smoke bmimed waistcmmed cholldlmed10 glucosefmed10 physact hxafib ;
%let blist = sbp120m sbp120m*&ty ;
%let clist = htntx htntx*&ty ;
%let e3list = gfrmed10 hxmi;

%if &model = E5 %then %do; proc sort data=anls.cv3 out=cv3; by studyname newid &ty; where studyname in (&studylist); run; %end;
%else %do; proc sort data=anls.cv3 out=cv3; by newid &ty; where studyname in (&studylist); run; %end;

ods graphics on;
ods rtf file="&OutputPath.\Output\Sensitivity\&dvar._App&model._&ymd..rtf";
proc hpmixed data = cv3 noclprint;
class newid;
%if &model = E5 %then %do; by studyname; %end;

%if &model = E3 %then %do; model &dvar = &alist &blist &clist &e3list / s cl; %end;
%else %do; model &dvar = &alist &blist &clist / s cl; %end; 
random int &ty / subject=newid type=un;
where strokeinc in (&strval) and &cmplt=1 and n&dvar >= 1 and &samp = 1 and studyname in (&studylist);
ods output ParameterEstimates=sr.&dvar._App&model._&ymd;
run;
ods rtf close;
ods graphics off; 

%mend;

/*Appendix E2: observations after incident stroke - strokeinc in (0 1)*/
*%bpcog_reg(GCP,E2,fvm);
*%bpcog_reg(EXF,E2,fvm);
*%bpcog_reg(MEM,E2,fvm);

/*Appendix E3: Model includes GFR and HxMI*/
*%bpcog_reg(GCP,E3,fvm);
*%bpcog_reg(EXF,E3,fvm);
*%bpcog_reg(MEM,E3,fvm);

/*Appendix E5: Model within cohort*/
*%bpcog_reg(GCP,E5,fvm);
%bpcog_reg(EXF,E5,fvm);
%bpcog_reg(MEM,E5,fvm);

