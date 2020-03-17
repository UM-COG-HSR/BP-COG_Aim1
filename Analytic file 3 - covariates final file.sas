
/************************************************************************************************************
* Program: Analytic File 3 - covariates final file.SAS            											*
* Folder: S:\Intmed_Rsrch2\GenMed\Restricted\BP COG\Aim 1\Data Management\Data\Freeze2020_Master\SAS Progs  *
* Author: Nick Tilton                          																*
* Created: 03/13/20                            																*
* Summary: Creates longitudinal analysis file and wide "table 1" file										*
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
%let CohortPath = &BPCOGpath.\Original Cohort Files;

libname frz "&MasterPath";
libname mem "&MemPath";
libname fmts "&FormatPath";
libname intm "&IntrmdPath";
libname anls "&AnalysPath";
libname cog "&CogPath";
libname excl "&ExclusPath";
libname ARIC "&CohortPath.\ARIC\SAS Files";
libname CARDIA "&CohortPath.\CARDIA\SAS Files";
libname CHS "&CohortPath.\CHS\SAS Files";
libname FOS "&CohortPath.\FOS\SAS Files";
libname MESA "&CohortPath.\MESA\SAS Files";
libname NOMAS "&CohortPath.\NOMAS\SAS Files";

options fmtsearch=(fmts) nofmterr;

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

/* get latest filedate */
data _null_;
retain late_dt;
rc=filename('mydir',"&MasterPath");
did=dopen('mydir');
numopts=doptnum(did);
memcount=dnum(did);
if (memcount gt 0) then do i = 1 to memcount;
	filename=dread(did,i);
	if i=1 then late_dt=input(substr(filename,12,6),best6.);
	curr_dt=input(substr(filename,12,6),best6.);
	if curr_dt > late_dt then late_dt = curr_dt;
	fid = mopen(did, filename,'i',0,'d');
	rc=fclose(fid);
	if i=memcount then call symputx("filedate",late_dt);
end;
rc=dclose(did);
run;
%put &=filedate;



%macro get_bl_val(vn);
/* work.tcog1 is a temporary file with one observation per participant that contains the date of 1st cog assessmentw. studyname was first kept for verification purposes then discarded*/
data tcog1;
set excl.prelim4;
if cog_idx_base=0;
dvb=daysfromvisit1;
keep newid dvb studyname;
run; 

/* afib: combine incident afib and history of afib */ 
%if &vn=hxafib %then %do;
proc sort data=frz.masterlong_&filedate out=tafcmb (keep=newid daysfromvisit1 hxafib afibinc); by newid daysfromvisit1; 

data tafcmb;
set tafcmb; by newid;
retain hx;
if first.newid then hx=0;
if hxafib=1 or afibinc=1 then hx=1;
hxafib=hx;
keep newid daysfromvisit1 hxafib;
run;
%end;
/* end of afib section */

/* MI: combine incident MI and history of MI */ 
%if &vn=mi %then %do;
proc sort data=frz.masterlong_&filedate out=tmicmb (keep=newid daysfromvisit1 mi miinc); by newid daysfromvisit1; 

data tmicmb;
set tmicmb; by newid;
retain hx;
if first.newid then hx=0;
if mi=1 or miinc=1 then hx=1;
mi=hx;
keep newid daysfromvisit1 mi;
run;
%end;
/* end of MI section */


data t&vn;
%if &vn=hxafib %then %do; set tafcmb; %end;
%else %if &vn=mi %then %do; set tmicmb; %end;
%else %do; set frz.masterlong_&filedate; %end;
keep newid daysfromvisit1 &vn;
run;

data t&vn;
set t&vn;
if &vn^=.;
run;

proc sort data=t&vn; by newid; run;

proc sort data=tcog1;
by newid; run;

data t2&vn;
merge t&vn tcog1 (in=in1);
by newid;
if in1;
%if &vn=educ %then %do;
	if studyname='fos' then do; 
		if daysfromvisit1^=.; 
	end;
    else do; if daysfromvisit1^=. and daysfromvisit1<=dvb; end; 
	prior=(daysfromvisit1<=dvb);
%end;
%else %do;
	if daysfromvisit1^=. and daysfromvisit1<=dvb;
%end;
run;

proc sort data=t2&vn; 
%if &vn=occupation %then %do; by newid descending occupation; %end;
%else %if &vn=educ %then %do; by newid descending prior descending daysfromvisit1; %end;
%else %do; by newid descending daysfromvisit1; %end;
run;

data t2&vn;
set t2&vn; by newid;
if first.newid;
%if &vn=educ %then %do; drop daysfromvisit1 dvb studyname prior; %end;
%else %do; drop daysfromvisit1 dvb studyname; %end;
run;

%mend;

%get_bl_val(educ);
%get_bl_val(bmi);
%get_bl_val(waistcm);
%get_bl_val(cholldl); 
%get_bl_val(htntx); *baseline (time-invariant);
%get_bl_val(glucosef);
%get_bl_val(smoke);
%get_bl_val(physact);
%get_bl_val(alcperwk);
%get_bl_val(hxafib);
%get_bl_val(mi);
%get_bl_val(age);
%get_bl_val(racebpcog);

data t2age;
set t2age;
age0=age;
drop age;
run;

/* missing lab values for nomas */
proc sort data=nomas.lab out=nlab (keep=id bs lldl); by id; where visit='BL' and vdate=. and ((bs^=. and fasting=1) or (lldl^=.)); run;
data nlab;
set nlab; by id;
newid=compress(id)||"nomas";
if first.id;
drop id;
run;

proc sort data=nlab; by newid; run;

data t2gluchol;
merge t2glucosef (in=in1) t2cholldl (in=in2) nlab (in=in3);
by newid;
if in1 or in2;
if in3 then do;
	if glucosef=. then glucosef=bs;
	if cholldl=. then cholldl=lldl;
end;
drop bs lldl;
run;

proc delete data = work.t2glucosef; run;
proc delete data = work.t2cholldl; run;
proc delete data = work.t2; run;

/* time-varying htn */

proc sort data=frz.masterlong_&filedate out=thtn(keep=newid daysfromvisit1 htntx); by newid daysfromvisit1; run;

data thtn_tv;
set thtn (rename=(htntx=htntx_tv)); by newid;
retain ttx;
if first.newid then ttx=.;
if htntx_tv^=. then ttx=htntx_tv;
else htntx_tv=ttx;
drop ttx;
run;

proc sort data=excl.prelim4 out=ttv (keep=newid daysfromvisit1); by newid daysfromvisit1; run;

data thtn_tv;
merge ttv (in=in1) thtn_tv;
by newid daysfromvisit1;
if in1;
run;

data t3htn_tv;
merge thtn_tv t2htntx;
by newid;
retain ttx;
if first.newid then ttx=htntx;
if htntx_tv^=. then ttx=htntx_tv;
else htntx_tv=ttx;
drop ttx htntx;
run;


proc sort data = excl.prelim4; by newid daysfromvisit1; run;
data nummeas;
set excl.prelim4; by newid;
array narr[3] ngcp nexf nmem;
array ovs[3] gcp exf mem;
retain ngcp nexf nmem;
if first.newid then do i=1 to 3; narr[i]=0; end;
do i=1 to 3; if ovs[i]^=. then narr[i]+1; end;
if last.newid;
keep newid ngcp--nmem;
run;

data lastob;
set excl.prelim4 (rename=(cogtime_y=fuptime)); by newid;
if last.newid;
keep newid fuptime;
run;


data cv1_t;
merge t2:;
by newid;

if alcperwk=. or alcperwk<0 then alccat=.;
else if alcperwk=0 then alccat=0;
else if alcperwk<=6 then alccat=1;
else if alcperwk<=13 then alccat=2;
else alccat=3;
alc1=(alccat=1); if alccat=. then alc1=.;
alc2=(alccat=2); if alccat=. then alc2=.;
alc3=(alccat=3); if alccat=. then alc3=.;
educ1=(educ=1); if educ=. then educ1=.;
educ2=(educ=2); if educ=. then educ2=.;
educ3=(educ=3); if educ=. then educ3=.;
educ4=(educ=4); if educ=. then educ4=.;
run;

%macro getmdns();
%let vlist=bmi waistcm glucosef cholldl age0;

%do i=1 %to 5;
	%let vn = %scan(&vlist,&i);
	proc means data=cv1_t median;
	var &vn;
	ods output summary=med&i;
	run;
%end;

data allmed;
merge med:;
run;

data cv1_t;
merge cv1_t allmed;
retain v1-v5;
if _N_ = 1 then do;
	%do j=1 %to 5; 
		%let vn = %scan(&vlist,&j);
		v&j = &vn._median;
	%end;
end;
else do;
	%do j=1 %to 5; 
		%let vn = %scan(&vlist,&j);
		&vn._median = v&j; 
	%end;
end;
drop v1-v5;
run;

data cv1_t;
set cv1_t;
%let suf1 = med;
%let suf2 = med10;
%do i=1 %to 5;
	%let vn = %scan(&vlist,&i);
	&vn&suf1 = &vn - &vn._Median;
	label &vn._Median = "Median &vn";
%end;
%do i=3 %to 5;
	%let vn = %scan(&vlist,&i);
	&vn&suf2 = &vn&suf1 /10;
%end;
drop age0;
run;
	
%mend;

%getmdns();

data cv2_t;
merge excl.prelim4 (in=in1) nummeas lastob cv1_t;
by newid;
if in1;
cardia=(studyname='cardia');
aric=(studyname='aric');
chs=(studyname='chs');
fos=(studyname='fos');
nomas=(studyname='nomas');
mesa=(studyname='mesa');
run;


proc sort data=frz.masterlong_&filedate out=span (keep=newid daysfromvisit1 coginspanish englishprof); by newid daysfromvisit1; run;

data cv1;
merge cv2_t (in=in1) span;
by newid daysfromvisit1;
if in1;
run;


data mcovs;
set cv1;
by newid;
if first.newid;
mc1=nmiss(age0,racebpcog,female0,educ,alccat,smoke,physact,
bmi,waistcm,hxafib,glucosef,cholldl,htntx,coginspanish);
mc2=nmiss(age0,racebpcog,female0,educ,alccat,smoke,physact,
bmi,waistcm,hxafib,glucosef,cholldl,htntx,englishprof);
mc3=nmiss(age0,racebpcog,female0,educ,smoke,physact, /* ~25% of MESA are missing alcohol use */
bmi,waistcm,hxafib,glucosef,cholldl,htntx,coginspanish);
cmplt1=(mc1=0);
cmplt2=(mc2=0);
cmplt3=(mc3=0);
keep newid mean_sbp_all mean_dbp_all gcp studyname age0 racebpcog female0 educ alccat smoke physact 
bmi waistcm hxafib glucosef cholldl htntx fuptime exf mem mc1 mc2 cmplt1 cmplt2 cmplt3 ngcp nexf nmem coginspanish englishprof;
run;

proc sort data=mcovs out=mc_t (keep=newid mc1 mc2 cmplt1 cmplt2); by newid; 
proc sort data=cv1; by newid cog_idx_base; run;

data cv2; 
merge cv1 mc_t;
by newid;
run;

proc sort data=cv2; by newid daysfromvisit1; run;

data anls.cv3;
set cv2;
by newid;
retain fndexf fndmem;
if first.newid then do; 
	fndexf=0;
	fndmem=0;
	prac_gcp=0; 
	if exf^=. then do; prac_exf=0; fndexf=1; end; 
	if mem^=. then do; prac_mem=0; fndmem=1; end;
end;
else do;
	prac_gcp=1;
	if fndexf then do; if exf^=. then prac_exf=1; else prac_exf=.; end;
	else do;
		if exf^=. then do; prac_exf=0; fndexf=1; end;
	end;
	if fndmem then do; if mem^=. then prac_mem=1; else prac_mem=.; end;
	else do;
		if mem^=. then do; prac_mem=0; fndmem=1; end;
	end;
end;
drop fndexf fndmem;
run;


proc sort data=anls.cv3; by newid daysfromvisit1; run;
data anls.cv3;
set anls.cv3;
by newid;
retain vcnt v2t;
if first.newid then do; vcnt=0; v2t=.; end;
vcnt=vcnt+1;
if vcnt=2 then v2t = cogtime_y2;
if vcnt=1 then cogtime_aux = 0;
else cogtime_aux = cogtime_y2 - v2t;
drop vcnt v2t;
run;

proc sort data=anls.cv3; by newid daysfromvisit1; run;
data anls.cv3;
set anls.cv3;
by newid;
retain v1exf v1mem v2exf v2mem exfcnt memcnt;

if first.newid then do;
	v1exf=.; v1mem=.; v2exf=.; v2mem=.; exfcnt=0; memcnt=0;
end;

if exf^=. then exfcnt=exfcnt+1;
if exfcnt=1 and exf^=. then do; v1exf=cogtime_y2; taux_exf=0; end;
if exfcnt=2 and exf^=. then v2exf = cogtime_y2;
if exfcnt>=2 and exf^=. then taux_exf = cogtime_y2 - v2exf; 
if exf^=. then t_exf = cogtime_y2 - v1exf;

if mem^=. then memcnt=memcnt+1;
if memcnt=1 and mem^=. then do; v1mem=cogtime_y2; taux_mem=0; end;
if memcnt=2 and mem^=. then v2mem = cogtime_y2;
if memcnt>=2 and mem^=. then taux_mem = cogtime_y2 - v2mem; 
if mem^=. then t_mem = cogtime_y2 - v1mem;

bvw = (racebpcog in (1 2)); /*black vs. white study population */
fvm = (racebpcog in (1 2)); /*female vs. male study population (race=black/white) */
hvw = (racebpcog in (2 3)); /*hispanic vs. white study population */
run;



/*  # of BP measurements */

proc sort data=frz.masterlong_&filedate out=tbpn (keep=newid daysfromvisit1 sbpbpcog dbpbpcog age0); by newid daysfromvisit1; run;
proc sort data=anls.cv3 out=ta1a (keep=newid daysfromvisit1 studyname racebpcog cmplt1); by newid daysfromvisit1; where cog_idx_base=0; run;

data ta1a;
set ta1a;
by newid;
if first.newid;
rename daysfromvisit1=dv1cog;
run;

data ta1a;
merge ta1a (in=in1) tbpn;
by newid;
if in1;
run;

data ta1a;
set ta1a (rename=(age0=age0coh)); by newid;
retain bpprior;
if first.newid then bpprior=0; 
if sbpbpcog^=. and daysfromvisit1<dv1cog then bpprior+1;
if last.newid;
keep newid studyname racebpcog age0coh bpprior cmplt1;
run;

proc sort data=frz.masterlong_&filedate out=tbpn2 (keep=newid daysfromvisit1 sbpbpcog dbpbpcog); by newid daysfromvisit1; where sbpbpcog^=.; run;
proc sort data=cv2 out=ta1b (keep=newid daysfromvisit1 studyname racebpcog); by newid daysfromvisit1; run;

data ta1c;
set ta1b; by newid;
rename daysfromvisit1=dv1cog;
if first.newid;
run;

data ta1c;
merge ta1c (in=in1) tbpn2;
by newid;
if in1;
run;

data ta1c;
set ta1c (rename=(sbpbpcog=sbpbpcog0 dbpbpcog=dbpbpcog0)); by newid;
if first.newid then do; bppriortime=(dv1cog-daysfromvisit1)/365.25; end;
else delete;
keep newid sbpbpcog0 dbpbpcog0 bppriortime;
run;

data ta1d;
set ta1b; by newid;
rename daysfromvisit1=lastday;
if last.newid;
run;

data ta1d;
merge ta1d (in=in1)  tbpn2;
by newid;
if in1;
run;

data ta1d;
set ta1d; by newid;
retain bptotal;
if first.newid then bptotal=0; 
if daysfromvisit1<lastday then bptotal+1;
if last.newid;
keep newid bptotal;
run;

data anls.bpcohorts;
merge ta1a ta1c ta1d;
by newid;
bvw = (racebpcog in (1 2)); /*black vs. white study population */
fvm = (racebpcog in (1 2)); /*female vs. male study population (race=black/white) */
hvw = (racebpcog in (2 3)); /*hispanic vs. white study population */
run;

proc sort data=mcovs; by newid;
proc sort data=anls.bpcohorts out=bpc (keep=newid age0coh--bptotal); by newid; run;

data anls.mcovs2;
merge mcovs anls.bpcohorts;
by newid;
run;


proc sort data=anls.cv3 out=cvexf (keep=newid exf); by newid daysfromvisit1; where exf^=.; run;
data cvexf;
set cvexf; by newid;
if first.newid;
exf2=exf;
drop exf;
run;

proc sort data=anls.cv3 out=cvmem (keep=newid mem); by newid daysfromvisit1; where mem^=.; run;
data cvmem;
set cvmem; by newid;
if first.newid;
mem2=mem;
drop mem;
run;

proc sort data=anls.mcovs2; by newid; run;

data anls.mcovs2;
merge anls.mcovs2 (in=in1) cvexf cvmem;
by newid;
if in1;
exf=exf2;
mem=mem2;
bvw = (racebpcog in (1 2)); /*black vs. white study population */
fvm = (racebpcog in (1 2)); /*female vs. male study population (race=black/white) */
hvw = (racebpcog in (2 3)); /*hispanic vs. white study population */
drop exf2 mem2;
run;

proc datasets library=work memtype=data nolist kill;
run;
quit;
