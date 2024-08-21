
***** This do file cleans the applications file by attaching the relevant lookup files and generating the number of applications in a case. *****

clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_APPLICATIONTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)

rename ID APPLICATIONTYPE1_ID /*Always rename in lookup file*/
sort APPLICATIONTYPE1_ID

save "$temp\lkp_applicationtype", replace

*Sort and save the lookup files
clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_COURTCOURTLEVELREFS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID COURTCOURTLEVELREF_ID
sort COURTCOURTLEVELREF_ID 
save "$temp\lkp_courtref", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_COURTS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID COURT_ID
sort COURT_ID
save "$temp\lkp_courtid", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_COURTLEVELREFS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID COURTLEVELREF_ID
sort COURTLEVELREF_ID
save "$temp\lkp_courtlevel", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_DJAREAREFS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID DJAREAREF_ID
sort DJAREAREF_ID
save "$temp\lkp_dfjareas", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_CIRCUITREFS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID CIRCUITREF_ID
sort CIRCUITREF_ID
save "$temp\lkp_circuitref", replace

*Merge in the lookups to application table
clear 
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_APPLICATIONS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password) 

*Merge application type lookup
sort APPLICATIONTYPE1_ID
merge m:1 APPLICATIONTYPE1_ID using "$temp\lkp_applicationtype", keepusing(APPLICATIONTYPE1_ID NAME)
labmask APPLICATIONTYPE1_ID, values(NAME)
drop if _m==2
drop _merge NAME

*Merge court name lookup
sort COURTCOURTLEVELREF_ID
merge m:1 COURTCOURTLEVELREF_ID using "$temp\lkp_courtref", keepusing(COURTCOURTLEVELREF_ID COURTFULLNAME COURT_ID COURTLEVELREF_ID)
labmask COURTCOURTLEVELREF_ID, values(COURTFULLNAME)
drop if _merge==2
drop _merge COURTFULLNAME

*Merge court ID lookup
sort COURT_ID
merge m:1 COURT_ID using "$temp\lkp_courtid", keepusing(COURT_ID NAME DJAREAREF_ID CIRCUITREF_ID)
labmask COURT_ID, values(NAME)
drop if _merge==2
drop _merge NAME

*Merge court level reference
sort COURTLEVELREF_ID
merge m:1 COURTLEVELREF_ID using "$temp\lkp_courtlevel", keepusing(COURTLEVELREF_ID NAME)
labmask COURTLEVELREF_ID, values(NAME)
drop if _merge==2
drop _merge NAME

*Merge DFJ area ref
sort DJAREAREF_ID
merge m:1 DJAREAREF_ID using "$temp\lkp_dfjareas", keepusing(DJAREAREF_ID NAME)
labmask DJAREAREF_ID, values(NAME)
drop if _merge==2
drop _merge NAME

*Merge circuit reference
sort CIRCUITREF_ID
merge m:1 CIRCUITREF_ID using "$temp\lkp_circuitref", keepusing(CIRCUITREF_ID NAME)
labmask CIRCUITREF_ID, values(NAME)
drop if _merge==2
drop _merge NAME

*Calculate the number of applications per case
bysort CASE_ID_PE: gen num_applications=_N
label var num_applications "Number of applications in case"
rename ID_PE APPLICATION_ID_PE
sort APPLICATION_ID_PE

save "$path\01applications_clean", replace
