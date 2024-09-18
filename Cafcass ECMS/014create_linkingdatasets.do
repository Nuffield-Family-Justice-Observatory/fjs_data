
**************** This file creates the relationships from using the relationship table and merges them with the main dataset *****************

*Clean relationships table
clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_PERSONRELATIONSHIPS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
sort PERSON_ID_PE
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g
destring RELATEDPERSON_ID_PE, replace
format RELATEDPERSON_ID_PE %14.0g
drop AVAIL_FROM_DT 
save "$interim\person_relationships", replace

*Relationship lookups
clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_RELATIONSHIPTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
tempfile lkp_relationshiptype
sort ID
rename ID RELATIONSHIPTYPE_ID
save "$temp\lkp_relationshiptype", replace

*Merge relationship lookups with relationship table
use "$interim\person_relationships", clear
sort RELATIONSHIPTYPE_ID
merge m:1 RELATIONSHIPTYPE_ID using "$temp/lkp_relationshiptype"
tab _merge
drop _merge SORTORDER ISLOCKED ISACTIVE INVERSEREF ISPRIMARY AVAIL_FROM_DT 

labmask RELATIONSHIPTYPE_ID, values(NAME)
label var RELATIONSHIPTYPE_ID "Relationship between related person ID and person ID (refers to related person ID)"
save "$interim\relationships_final", replace

*Merge in information on the related person characteristics e.g. age, gender, ethnicity, nationality, religion etc.
use "$path\02people_clean_final", clear
rename PERSON_ID_PE RELATEDPERSON_ID_PE
sort RELATEDPERSON_ID_PE
save "$interim\related_people", replace

use "$interim\relationships_final", clear 
sort RELATEDPERSON_ID_PE
merge m:1 RELATEDPERSON_ID_PE using "$interim/related_people"

drop if _merge==2 | _merge==1
sort PERSON_ID_PE
drop _merge ID_PE  RELATIONSHIPMALE RELATIONSHIPFEMALE

save "$interim\relationships_people", replace

*Reshape into a wide dataset and link with core dataset by person id. Then run a loop in order to identify people e.g. mother, father, siblings, grandparents, step-parents. Probably better ways of doing it but this seems like a reasonable approach given how I've structured the data. 
bysort PERSON_ID_PE: gen n=_n
rename Learning_Difficulties__e_g__Dyx Learning_Difficultiesx
rename Wheelchair_Mobility_Difficultix Wheelchair_Mobilityx
reshape wide RELATIONSHIPTYPE_ID RELATEDPERSON_ID_PE PARENTALRESPONSIBILITYTYPE_ID NAME ALF2_PE ALF_PE GENDER WEEKOFBIRTH ETHNICITYTYPE_ID source_religion ethnicity_mis source_ethnicity RELIGIONTYPE_ID religion_mis NATIONALITYTYPE_ID source_nationality nationality_mis LANGUAGETYPE_ID source_language language_mis hasdisability Autism_or_Spectrum_Disordersx Blind_Partially_Sightedx Cerebral_Palsyx Deaf_Hearing_Impairedx Downs_Syndromex Dyslexiax Facial_Disfigurementx Global_Development_Delayx Learning_Difficultiesx Learning_Disabilityx Manual_Dexterityx Mental_Health_Difficultiesx Need_Personal_Care_Supportx Otherx Progressive_Conditionsx Speech_Impairmentx Unseen_Disabilitiesx Wheelchair_Mobilityx disability_mis, i(PERSON_ID_PE) j(n)
save "$interim\relationships_people_wide", replace


use "$path\03Core_dataset_ECMS", clear
sort PERSON_ID_PE
merge m:1 PERSON_ID_PE using "$interim\Relationships_people_wide"
*So, remember I have used only children (<18s). The _m==2 large number of people should be the adults and the _m==1 are children who don't have any relationsips recorded. 
drop if _merge==2
rename _merge flag_norel 
recode flag_norel (3=0)
label var flag_norel "Flag for child not having any relationships recorded"

*Check number of mothers and fathers - should be one of each but there is approx 0.4% with more than 2 parents (leave for now)
egen num_parents=anycount(RELATIONSHIPTYPE_ID*), values (1)
label var num_parents "Number of parents recorded"
*Check number of mothers - approx 0.5% of the sample (leave for now)
generate count_mothers=0

forvalues i=1/14 {
	replace count_mothers=count_mothers+1 if RELATIONSHIPTYPE_ID`i'==1 & GENDER`i'=="Female"	
}

*Check number of fathers - approx 0.5% of the sample (leave for now)
generate count_fathers=0

forvalues i=1/14 {
	replace count_fathers=count_fathers+1 if RELATIONSHIPTYPE_ID`i'==1 & GENDER`i'=="Male"
}
label var count_fathers "Number of fathers"
label var count_mothers "Number of mothers"

*Generate new mother and father variables and run a loop for identifying mother/father and their characteristics
generate long motherid=.
generate motherdob=.
generate mother_ethnicity=.
generate mother_disabiity=.
generate mother_nationality=.
generate mother_language=.
generate mother_religion=.

generate long fatherid=.
generate fatherdob=.
generate father_ethnicity=.
generate father_disabiity=.
generate father_nationality=.
generate father_language=.
generate father_religion=.

**Mothers
local varbase = "1 2 3 4 5 6 7 8 9 10 11 12 13 14"
foreach v of local varbase  {
	
	replace motherid=RELATEDPERSON_ID_PE`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & motherid==.
	replace motherdob=WEEKOFBIRTH`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & motherdob==.
	replace mother_ethnicity=ETHNICITYTYPE_ID`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & mother_ethnicity==.
	replace mother_disability=hasdisability`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & mother_disability==.
	replace mother_nationality=NATIONALITYTYPE_ID`v'  if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & mother_nationality==.
	replace mother_language=LANGUAGETYPE_ID`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & mother_language==.
	replace mother_religion=RELIGIONTYPE_ID`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Female") & mother_religion==.

}
format motherdob %td
label values mother_ethnicity ETHNICITYTYPE_ID
label var mother_ethnicity "Mother ethnicity"
label values mother_nationality NATIONALITYTYPE_ID
label var mother_nationality "Mother nationality"
label values mother_language LANGUAGETYPE_ID
label var mother_language "Mother language"
label values mother_religion RELIGIONTYPE_ID
label var mother_religion "Mother religion"
label var mother_disability "Mother disability"
label var motherid "Unique mother ID"
label var motherdob "DOB mother"

**Fathers
local varbase = "1 2 3 4 5 6 7 8 9 10 11 12 13 14"
foreach v of local varbase  {
	
	replace fatherid=RELATEDPERSON_ID_PE`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & fatherid==.
	replace fatherdob=WEEKOFBIRTH`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & fatherdob==.
	replace father_ethnicity=ETHNICITYTYPE_ID`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & father_ethnicity==.
	replace father_disability=hasdisability`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & father_disability==.
	replace father_nationality=NATIONALITYTYPE_ID`v'  if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & father_nationality==.
	replace father_language=LANGUAGETYPE_ID`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & father_language==.
	replace father_religion=RELIGIONTYPE_ID`v' if (RELATIONSHIPTYPE_ID`v'==1 & GENDER`v'=="Male") & father_religion==.


}
format fatherdob %td
label values father_ethnicity ETHNICITYTYPE_ID
label var father_ethnicity "Father ethnicity"
label values father_nationality NATIONALITYTYPE_ID
label var father_nationality "Father nationality"
label values father_language LANGUAGETYPE_ID
label var father_language "Father language"
label values father_religion RELIGIONTYPE_ID
label var father_religion "Father religion"
label var father_disability "Father disability"
label var fatherid "Unique father ID"
label var fatherdob "DOB father"

*Generate flag for other extended family members
generate count_extendedfamily=0

forvalues i=1/14 {
	replace count_extendedfamily=count_extendedfamily+1 if (RELATIONSHIPTYPE_ID`i'!=1 & RELATIONSHIPTYPE_ID`i'!=14 & RELATIONSHIPTYPE_ID`i'!=. & RELATIONSHIPTYPE_ID`i'!=34 & RELATIONSHIPTYPE_ID`i'!=35 & RELATIONSHIPTYPE_ID`i'!=40 & RELATIONSHIPTYPE_ID`i'!=41 & RELATIONSHIPTYPE_ID`i'!=51 & RELATIONSHIPTYPE_ID`i'!=52 & RELATIONSHIPTYPE_ID`i'!=9 & RELATIONSHIPTYPE_ID`i'!=24)
	
}

replace count_extendedfamily=1 if count_extendedfamily>0
rename count_extendedfamily extendedfamily 
label var extendedfamily "Flag for whether there are recorded extended family members"

*Generate variables for number of siblings
egen num_nat_sib=anycount(RELATIONSHIPTYPE_ID*), values (34 35)
egen num_half_sib=anycount(RELATIONSHIPTYPE_ID*), values (40 41)
egen num_step_sib=anycount(RELATIONSHIPTYPE_ID*), values (51 52)
egen total_sib=rowtotal(num_nat_sib num_half_sib num_step_sib)

label var num_nat_sib "Number of recorded natural siblings"
label var num_half_sib "Number of recorded half siblings"
label var num_step_sib "Number of recorded step siblings"
label var total_sib "Total number of recorded siblings (natural, step and half)"

*Drop wide relationship data
forvalues i=1/14 {
	
	drop GENDER`i' ALF_PE`i' ALF2_PE`i' WEEKOFBIRTH`i' ETHNICITYTYPE_ID`i' RELIGIONTYPE_ID`i' NATIONALITYTYPE_ID`i' LANGUAGETYPE_ID`i' hasdisability`i' Autism_or_Spectrum_Disordersx`i' Blind_Partially_Sightedx`i' Cerebral_Palsyx`i' Deaf_Hearing_Impairedx`i' Downs_Syndromex`i' Dyslexiax`i' Facial_Disfigurementx`i' Global_Development_Delayx`i' Learning_Difficultiesx`i' Learning_Disabilityx`i' Manual_Dexterityx`i' Mental_Health_Difficultiesx`i' Need_Personal_Care_Supportx`i' Otherx`i' Progressive_Conditionsx`i' Speech_Impairmentx`i' Unseen_Disabilitiesx`i' Wheelchair_Mobilityx`i'
}

drop RELATIONSHIPTYPE_ID* RELATEDPERSON_ID_PE* PARENTALRESPONSIBILITYTYPE_ID* NAME* ethnicity_mis* religion_mis* nationality_mis* language_mis* disability_mis*  source_language* source_religion* source_nationality* source_ethnicity*

save "$path\04Coredataset_wrels", replace



