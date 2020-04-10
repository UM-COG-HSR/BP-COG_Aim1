/************************************************************************************************************
* Program: Sex Differences Plot 1 - Predicted Values 200410.SAS        										
* Folder: S:\Intmed_Rsrch2\GenMed\Restricted\BP COG\Aim 1\Data Management\Data\Freeze2020_Master\SAS Progs  
* Author: Nick Tilton                          																
* Created: 04/10/20                            																
* Summary: Creates plot of predicted values for sex differences analysis (All outcomes, common y-axes)									
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

%let BPCOGpath = S:\Intmed_Rsrch2\GenMed\Restricted\BP COG;
%let AnalysPath = &BPCOGpath.\Aim 1\Data Management\Data\Freeze2020_Master\SAS Analytic File;
%let ResultPath = &BPCOGpath.\Aim 1\Sex Differences\Post-Freeze Analysis\SAS Results;
%let PlotPath = &BPCOGpath.\Aim 1\Sex Differences\Post-Freeze Analysis\Plots;
%let FormatPath = &BPCOGpath.\Aim 1\Data Management\Data\formats;

libname sr "&ResultPath";
libname anls "&AnalysPath";
libname fmts "&FormatPath";
options fmtsearch=(fmts work) nofmterr;

%macro sgplot(model,tprd); 

proc format;
value sexfmt
1 = Female
0 = Male;
run;

%do i = 1 %to 3; /*cycle through once for each of the three outcomes*/
	%if &i = 1 %then %do; %let dvar = GCP; %let tvar = cogtime_y2; %let vardesc = Global Cognition; %end;
	%else %if &i = 2 %then %do; %let dvar = EXF; %let tvar = t_&dvar; %let vardesc = Executive Function; %end;
	%else %do; %let dvar = MEM; %let tvar = t_&dvar; %let vardesc = Memory; %end;
	
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
	
	/* get outcome-specific regression results */
	data model_effects_&dvar;
	set sr.&dvar._mod&model._&filedate;
	effect=transtrn(effect,'*','x');
	keep effect estimate;

	proc transpose data=model_effects_&dvar out=model_effects2_&dvar (drop=_NAME_);
	id Effect;
	run;

	data model_effects2_&dvar;
	retain _MODEL_ _TYPE_ _DEPVAR_;
	set model_effects2_&dvar;
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
	set model_effects_&dvar end=eof;
	retain effectlist;
	length effectlist $300;
	if _N_=1 then effectlist='';
	if strip(lowcase(effect)) ^= 'intercept' then
		effectlist=catx(' ',effectlist,strip(effect));
	if eof then call symputx("effectlist",effectlist);
	run;
	%put &=effectlist;

	/*create exemplar patient parameter dataset*/
	data model_params;
	array zeros[*] &effectlist;
	do i=1 to dim(zeros);
   		zeros[i]=0;
	end;
	black=1; age0med10=(70-&agemed)/10; nomas=1; educ1=1;
	do female0=0 to 1;
		do i=0 to &tprd;
    		&tvar = i; 
    		&tvar.xblack = &tvar*black;
    		&tvar.xage0med10 = &tvar*age0med10;
    		&tvar.xfemale0 = &tvar*female0;
			%if &model ^= A %then %do;
	     		sbp120m = 3+(i/10);
    	 		&tvar.xsbp120m = &tvar*sbp120m;
				%if &model ^= C %then %do;
					htntx=0;
					&tvar.xhtntx = &tvar*htntx;
				%end;
			%end;
    		output;
  		end;
	end; 
	drop i;
	run;
	
	/* generate predicted values */
	proc score data=model_params score=model_effects2_&dvar out=model_predict_&dvar type=parms nostd predict;
	var &effectlist;
	run;

	data model_predict_&dvar;
	set model_predict_&dvar;
	label Model_&model = "&vardesc"
		female0 = 'Sex'
		&tvar = 'Time (Years)';
	format female0 sexfmt.;
	run;
%end;

/* get common y-axis values for plots */
data Model_predict_all;
set Model_predict:;
keep Model_&model;
run;

proc sql;
select min(Model_C), max(Model_C)  into :cogmin, :cogmax
from Model_predict_all;
quit;
%let cogmin = %sysfunc(floor(%sysevalf(&cogmin - 1)));
%let cogmax = %sysfunc(floor(%sysevalf(&cogmax + 2)));
%put &=cogmin &=cogmax;

/* generate a plot for each outcome */
%do i=1 %to 3;
	%if &i = 1 %then %do; %let dvar = GCP; %let tvar = cogtime_y2; %let vardesc = Global Cognition; %end;
	%else %if &i = 2 %then %do; %let dvar = EXF; %let tvar = t_&dvar; %let vardesc = Executive Function; %end;
	%else %do; %let dvar = MEM; %let tvar = t_&dvar; %let vardesc = Memory; %end;

	ods listing gpath="&PlotPath" image_dpi=300;
	ods graphics on / imagename="Plot&dvar._Mod&Model._&ymd._" width=4.5in  height=3.5in imagefmt=png;
	proc sgplot data=model_predict_&dvar;
	series x=&tvar y=Model_&model / group=female0 MARKERS LINEATTRS = (THICKNESS = 2);
	yaxis min=&cogmin max=&cogmax;
	title "Predicted &vardesc Trajectory by Sex";
	run; 
%end;

proc datasets library=work memtype=data nolist;
delete model_effects: model_params: model_predict:;
run;
quit;

%mend;

/* 
Two Parameters
	Which Model? C for sex differences project
	Length of time(y) for predicted values? Settled on 20 years during the last call
*/
%sgplot(C,20);

