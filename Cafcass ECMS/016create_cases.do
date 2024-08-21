
*************** This file merges in the case-level information e.g. law type *********************

*Save lookups for law type, local authority and court form ID
clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_LAWTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID LAWTYPE_ID
sort LAWTYPE_ID
save "$temp\lkp_lawtype", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_LOCALAUTHORITIES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID LOCALAUTHORITY_ID
sort LOCALAUTHORITY_ID 
save "$temp\lkp_localauthority", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_COURTFORMS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID COURTFORM_ID
sort COURTFORM_ID
save "$temp\lkp_courtform", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_CASESTATUS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID CASESTATU_ID
sort CASESTATU_ID
save "$temp\lkp_casestatus", replace


clear 
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_CASES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password) 

drop AVAIL_FROM_DT 
rename ID_PE CASE_ID

*Merge all lookups 
**Merge court references
sort COURTCOURTLEVELREF_ID
merge m:1 COURTCOURTLEVELREF_ID using "$temp\lkp_courtref", keepusing(COURTCOURTLEVELREF_ID COURTFULLNAME COURT_ID COURTLEVELREF_ID)
labmask COURTCOURTLEVELREF_ID, values(COURTFULLNAME)
drop if _merge==2
drop _merge COURTFULLNAME

**Merge court ID
sort COURT_ID
merge m:1 COURT_ID using "$temp\lkp_courtid", keepusing(COURT_ID NAME DJAREAREF_ID CIRCUITREF_ID)
labmask COURT_ID, values(NAME)

drop if _merge==2
drop _merge NAME

**Merge court level reference
sort COURTLEVELREF_ID
merge m:1 COURTLEVELREF_ID using "$temp\lkp_courtlevel", keepusing(COURTLEVELREF_ID NAME)
labmask COURTLEVELREF_ID, values(NAME)

drop if _merge==2
drop _merge NAME

**Merge DFJ area ref
sort DJAREAREF_ID
merge m:1 DJAREAREF_ID using "$temp\lkp_dfjareas", keepusing(DJAREAREF_ID NAME)
labmask DJAREAREF_ID, values(NAME)

drop if _merge==2
drop _merge NAME

**Merge circuit reference
sort CIRCUITREF_ID
merge m:1 CIRCUITREF_ID using "$temp\lkp_circuitref", keepusing(CIRCUITREF_ID NAME)
labmask CIRCUITREF_ID, values(NAME)

drop if _merge==2
drop _merge NAME

**Merge law type
sort LAWTYPE_ID
merge m:1 LAWTYPE_ID using "$temp\lkp_lawtype", keepusing(LAWTYPE_ID CAPTION)
labmask LAWTYPE_ID, values(CAPTION)

drop if _merge==2
drop _merge CAPTION

**Merge local authorities
sort LOCALAUTHORITY_ID
merge m:1 LOCALAUTHORITY_ID using "$temp\lkp_localauthority", keepusing(LOCALAUTHORITY_ID NAME)
labmask LOCALAUTHORITY_ID, values(NAME)

drop if _merge==2
drop _merge NAME

**Merge court form
sort COURTFORM_ID
merge m:1 COURTFORM_ID using "$temp\lkp_courtform", keepusing(COURTFORM_ID FORMNAME)
labmask COURTFORM_ID, values(FORMNAME)

drop if _merge==2
drop _merge FORMNAME

**Merge case status
sort CASESTATU_ID
merge m:1 CASESTATU_ID using "$temp\lkp_casestatus", keepusing(CASESTATU_ID NAME)
labmask CASESTATU_ID, values(NAME)

drop if _merge==2
drop _merge NAME

rename CASE_ID CASE_ID_PE
sort CASE_ID_PE

save "$interim\cases_cleaned", replace


use "$path\05Core_dataset_ECMS_LO_rels", clear

sort CASE_ID_PE
merge m:1 CASE_ID_PE using "$interim\cases_cleaned", keepusing(CASE_ID_PE HARM DATERECEIVED CLOSUREDATE REOPENDATE COURTFORM_ID LAWTYPE_ID LOCALAUTHORITY_ID)

drop if _merge==2
drop _merge

label var CLOSUREDATE "Date case was closed"
label var REOPENDATE "Date case was re-opened"
label var COURTFORM_ID "Court form"
label var LAWTYPE_ID "Law type"
label var LOCALAUTHORITY_ID "Local authority on case"

save "$path\06Final_dataset_ECMS", replace
