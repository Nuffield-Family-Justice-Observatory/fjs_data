**************** This file creates the relationships from using the relationship table and merges them with the main dataset *****************

*Lookups
clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPCRSRELATIONSHIP_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename CRSRELATIONSHIPID RELATIONSHIPREF
sort RELATIONSHIPREF
save "$tempcms\lkp_relationships", replace

*Merge lookups
clear 
odbc load, exec ("select * from SAIL$project.CAFE_CMS_TBLCRSPERSONRELATIONSHIP_20191220") dsn (PR_SAIL) user ($user) password ($password)
merge m:1 RELATIONSHIPREF using "$tempcms\lkp_relationships", keepusing(RELATIONSHIPREF CRSRELATIONSHIP)
drop if _m==2
drop _merge

drop AVAIL_FROM_DT

rename CHILDREF_PE PERSONID_PE
sort PERSONID_PE

duplicates drop PARENTREF_PE PERSONID_PE CRSRELATIONSHIP, force

labmask RELATIONSHIPREF, values(CRSRELATIONSHIP)
drop CRSRELATIONSHIP
duplicates tag PARENTREF_PE PERSONID_PE, gen(tag)
replace RELATIONSHIPREF=.a if tag>0

drop PERSONRELATIONSHIPID_PE tag
duplicates drop

bysort PERSONID_PE: gen n=_n

save "$interimcms\relationships_final", replace

use "$pathcms\02people_cleaned", clear
rename PERSONID_PE PARENTREF_PE
sort PARENTREF_PE
save "$interimcms\person_parent_cleaned", replace

use "$interimcms\relationships_final", clear
merge m:1 PARENTREF_PE using "$interimcms\person_parent_cleaned"

drop if _m==2
drop _merge
reshape wide PARENTREF_PE RELATIONSHIPREF ALF2_PE ALF_PE ETHNICREF RELIGIONREF FIRSTLANGUAGEREF INTERPRETERREQ DISABILITYREF GENDER WEEKOFBIRTH, i(PERSONID_PE) j(n)


*Check number of mothers and fathers for each child - should be one of each but there are not, need to make decision here which to take. This code takes first instance.
egen num_parents=anycount(RELATIONSHIPREF*), values (1)
*Check number of mothers
generate count_mothers=0

forvalues i=1/7 {
	replace count_mothers=count_mothers+1 if RELATIONSHIPREF`i'==1 & GENDER`i'=="Female"
}

*Check number of fathers
generate count_fathers=0

forvalues i=1/7 {
	replace count_fathers=count_fathers+1 if RELATIONSHIPREF`i'==1 & GENDER`i'=="Male"
}

**Now you need to run a loop for identifying mother/father and their characteristics
generate long motherid=.
generate motherdob=.
generate mother_ethnicity=.
generate mother_disability=.
generate mother_language=.
generate mother_religion=.

generate long fatherid=.
generate fatherdob=.
generate father_ethnicity=.
generate father_disability=.
generate father_language=.
generate father_religion=.

destring PARENTREF_PE*, replace

*Mothers
local varbase = "1 2 3 4 5 6 7"
foreach v of local varbase  {
	
	replace motherid=PARENTREF_PE`v' if (RELATIONSHIPREF`v'==1	& GENDER`v'=="Female") & motherid==.
	replace motherdob=WEEKOFBIRTH`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Female") & motherdob==.
	replace mother_ethnicity=ETHNICREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Female") & mother_ethnicity==.
	replace mother_disability=DISABILITYREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Female") & mother_disability==.
	replace mother_language=FIRSTLANGUAGEREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Female") & mother_language==.
	replace mother_religion=RELIGIONREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Female") & mother_religion==.
}
format motherdob %td
label values mother_ethnicity ETHNICREF
label values mother_language FIRSTLANGUAGEREF
label values mother_religion RELIGIONREF
label values mother_disability DISABILITYREF


*Fathers
local varbase = "1 2 3 4 5 6 7"
foreach v of local varbase  {
	
	replace fatherid=PARENTREF_PE`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Male") & fatherid==.
	replace fatherdob=WEEKOFBIRTH`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Male") & fatherdob==.
	replace father_ethnicity=ETHNICREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Male") & father_ethnicity==.
	replace father_disability=DISABILITYREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Male") & father_disability==.
	replace father_language=FIRSTLANGUAGEREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Male") & father_language==.
	replace father_religion=RELIGIONREF`v' if (RELATIONSHIPREF`v'==1 & GENDER`v'=="Male") & father_religion==. 


}
format fatherdob %td
label values father_ethnicity ETHNICREF
label values father_language FIRSTLANGUAGEREF
label values father_religion RELIGIONREF
label values father_disability DISABILITYREF

*Drop wide relationship data when finished with summary variables but rename ones you want to keep first.
forvalues i=1/7 {
	
	drop GENDER`i' ALF_PE`i' ALF2_PE`i' WEEKOFBIRTH`i' ETHNICREF`i' RELIGIONREF`i' FIRSTLANGUAGEREF`i' DISABILITYREF`i' 
}

drop INTERPRETERREQ* PARENTREF_PE* RELATIONSHIPREF* 
sort PERSONID_PE
save "$interimcms\relationships_people", replace


use "$pathcms\03Core_dataset_CMS", clear
sort PERSONID_PE
merge m:1 PERSONID_PE using "$interimcms\relationships_people"
drop if _m==2
drop _merge
save "$pathcms\04Core_dataset_CMS_withrels", replace
