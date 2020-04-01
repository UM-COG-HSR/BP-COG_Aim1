/************************************************************************************************************
* Program: Sex Differences Plot 1 - Predicted Values.SAS            										*
* Folder: S:\Intmed_Rsrch2\GenMed\Restricted\BP COG\Aim 1\Data Management\Data\Freeze2020_Master\SAS Progs  *
* Author: Nick Tilton                          																*
* Created: 03/30/20                            																*
* Summary: Creates plot of predicted values for sex differences analysis									*
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

%let ResultPath = &BPCOGpath.\Aim 1\Sex Differences\Post-Freeze Analysis\SAS Results;
%let PlotPath = &BPCOGpath.\Aim 1\Sex Differences\Post-Freeze Analysis\Plots;

libname sr "&ResultPath";

%macro sgplot(dvar,model); 

proc format;
value sexfmt
1 = Female
0 = Male;
run;

/* get latest filedate */
data _null_;
retain late_dt;
rc=filename('mydir',"&ResultPath");
did=dopen('mydir');
numopts=doptnum(did);
memcount=dnum(did);
if (memcount gt 0) then do i = 1 to memcount;
	filename=transtrn(dread(did,i),'.sas7bdat','');
	if lowcase(substr(filename,1,8)) = lowcase("&dvar._mod&model") then do;
		if i=1 then late_dt=input(substr(filename,length(filename)-5,6),best6.);
		curr_dt=input(substr(filename,length(filename)-5,6),best6.);
		if curr_dt > late_dt then late_dt = curr_dt;
	end;
	fid = mopen(did, filename,'i',0,'d');
	rc=fclose(fid);
	if i=memcount then call symputx("filedate",late_dt);
end;
rc=dclose(did);
run;
%put &=filedate;

data model_effects;
set sr.&dvar._mod&model._&filedate;
effect=transtrn(effect,'*','x');
keep effect estimate;

proc transpose data=model_effects out=model_effects2 (drop=_NAME_);
id Effect;
run;

data model_effects2;
retain _MODEL_ _TYPE_ _DEPVAR_;
set model_effects2;
_MODEL_="Model_&Model"; _TYPE_="PARMS"; _DEPVAR_="&dvar";
run;

data _null_;
set anls.cv3;
if not missing(age0_median) then do;
	call symputx("agemed",age0_median);
	stop;
end;
run;

data _null_;
set model_effects end=eof;
retain effectlist;
length effectlist $300;
if _N_=1 then effectlist='';
if strip(lowcase(effect)) ^= 'intercept' then
	effectlist=catx(' ',effectlist,strip(effect));
if eof then call symputx("effectlist",effectlist);
run;
%put &=effectlist;
%if &dvar = GCP %then %do; %let tvar = cogtime_y2; %let vardesc = Global Cognition; %end;
%else %do; %let tvar = t_&dvar;
	%if &dvar = EXF %then %let vardesc = Executive Function; %else %let vardesc = Memory;
%end;

data model_params;
array zeros[*] &effectlist;
do i=1 to dim(zeros);
   zeros[i]=0;
end;
black=1; age0med10=(70-&agemed)/10; nomas=1; educ1=1;
do female0=0 to 1;
	do i=0 to 25;
    	&tvar = i; 
    	&tvar.xblack = &tvar*black;
    	&tvar.xage0med10 = &tvar*age0med10;
    	&tvar.xfemale0 = &tvar*female0;
		%if &model ^= A %then %do;
	     	sbp120m = 3+(i/10);
    	 	&tvar.xsbp120m = &tvar*sbp120m;
		%end;
    	output;
  	end;
end; 
drop i;
run;

proc score data=model_params score=model_effects2 out=model_predict type=parms nostd predict;
var &effectlist;
run;

data model_predict;
set model_predict;
label Model_&model = "&vardesc (Model &Model)"
	female0 = 'Sex'
	&tvar = 'Time (Years)';
format female0 sexfmt.;
run;

ods listing gpath="&PlotPath" image_dpi=300;
ods graphics on / imagename="Plot&dvar._Mod&Model._&ymd" width=4.5in  height=3.5in imagefmt=png;
proc sgplot data=model_predict;
series x=&tvar y=Model_&model / group=female0 MARKERS LINEATTRS = (THICKNESS = 2);
yaxis min=27 max=53;
title "Predicted &vardesc Trajectory by Sex";
run; 

%mend;

%sgplot(GCP,B);


