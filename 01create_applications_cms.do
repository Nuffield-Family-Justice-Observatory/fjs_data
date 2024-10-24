***** This do file cleans the applications file by attaching the relevant lookup files *****

*Lookups 
clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPCASEAPPLICATIONTYPE") dsn (PR_SAIL) user ($user) password ($password)
rename CASEAPPLICATIONTYPEID CASEAPPLICATIONTYPEREF
sort CASEAPPLICATIONTYPEREF
save "$tempcms\lkp_applicationtype", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPCOURT_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename COURTID COURTREF 
sort COURTREF
save "$tempcms\lkp_court", replace


clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPCOURTLEVEL_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID COURTLEVELREF
sort COURTLEVELREF
save "$tempcms\lkp_courtlevel", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPCIRCUIT_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID CIRCUITREF
sort CIRCUITREF
save "$tempcms\lkp_circuit", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPDFJAREA_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID DFJAREAREF
sort DFJAREAREF
save "$tempcms\lkp_dfjarea", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPLAWTYPE_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID LAWTYPES
sort LAWTYPES
save "$tempcms\lkp_lawtype", replace


**Merge in lookups
clear 
odbc load, exec ("select * from SAIL$project.CAFE_CMS_TBLCASEAPPLICATION_20191220") dsn (PR_SAIL) user ($user) password ($password)
sort CASEAPPLICATIONTYPEREF
merge m:1 CASEAPPLICATIONTYPEREF using "$tempcms\lkp_applicationtype", keepusing(CASEAPPLICATIONTYPEREF CASEAPPLICATIONTYPE LAWTYPES)
labmask CASEAPPLICATIONTYPEREF, values(CASEAPPLICATIONTYPE)
drop if _m==2
drop _merge CASEAPPLICATIONTYPE

sort LAWTYPES
merge m:1 LAWTYPES using "$tempcms\lkp_lawtype", keepusing(LAWTYPES CAPTION)
labmask LAWTYPES, values(CAPTION)
drop if _m==2 
drop _merge CAPTION

sort COURTREF
merge m:1 COURTREF using "$tempcms\lkp_court", keepusing(COURTREF COURT COURTLEVELREF CIRCUITREF DFJAREAREF)
labmask COURTREF, values(COURT)
drop if _m==2
drop _merge COURT

sort COURTLEVELREF
merge m:1 COURTLEVELREF using "$tempcms\lkp_courtlevel", keepusing(COURTLEVELREF CAPTION)
labmask COURTLEVELREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

sort CIRCUITREF
merge m:1 CIRCUITREF using "$tempcms\lkp_circuit", keepusing(CIRCUITREF CAPTION)
labmask CIRCUITREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

sort DFJAREAREF
merge m:1 DFJAREAREF using "$tempcms\lkp_dfjarea", keepusing(DFJAREAREF CAPTION)
labmask DFJAREAREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

save "$pathcms\01applications_clean", replace 
