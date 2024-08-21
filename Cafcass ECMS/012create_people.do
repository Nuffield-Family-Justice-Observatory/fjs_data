
***** This do file cleans the people file which contains characteristics of each person in the dataset. It also uses special access datasets for sensitive characteristics. These include ethnicity, disability, language, nationality and religion *****

clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_PEOPLE_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
*There are some duplicates in this table - remove
duplicates report
duplicates drop
rename ID_PE PERSON_ID_PE
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g
drop MOB_LINKAGE AVAIL_FROM_DT
sort PERSON_ID_PE
save "$interim\people_clean", replace

*Clean the lookup files for the source data
clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_SOURCES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID SOURCE_ID
save "$temp\lkp_sources", replace

*Ethnicity
**Ethnicity lookup file
clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_ETHNICITYTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID ETHNICITYTYPE_ID
sort ETHNICITYTYPE_ID
save "$temp\ethnicity_lkp", replace

**Merge ethnicity lookups with ethnicity table
clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_ETHNICITIES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
sort ETHNICITYTYPE_ID
merge m:1 ETHNICITYTYPE_ID using "$temp\ethnicity_lkp"
labmask ETHNICITYTYPE_ID, values(NAME)
drop if _m==2
drop _merge NAME AVAIL_FROM_DT SORTORDER ISLOCKED ISACTIVE ID_PE
sort PERSON_ID_PE
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g
sort SOURCE_ID
merge m:1 SOURCE_ID using "$temp\lkp_sources", keepusing(NAME SOURCE_ID)
labmask SOURCE_ID, values(NAME)
rename SOURCE_ID source_ethnicity
drop if _m==2
drop _m

**There are duplicates that need removing
duplicates drop /* Drop full duplicates */ 
duplicates report PERSON_ID_PE /* There are still some duplicates for people who have more than one recorded ethnicity (numbers are small).  */
duplicates tag PERSON_ID_PE, gen(tag)
recode ETHNICITYTYPE_ID (19=22) /* Recode Prefer not to say into Unknown */
sort PERSON_ID_PE
bysort PERSON_ID_PE (ETHNICITYTYPE_ID): gen n=_n
bysort PERSON_ID_PE (ETHNICITYTYPE_ID): gen N=_N
**Important to sort the ethnicity ID and for unknown to be coded as the highest number

drop if ETHNICITYTYPE_ID==22 & n>1 /* This removes the row where the ethnicity is unknown and prioritises the row where it isn't. But you still have duplicates remaining where two different ethnicities are recorded. */

**Possible to take a variety of approaches here. I keep one row and recode ethnicity as unclear. This will need to be checked with every data refresh
replace ETHNICITYTYPE_ID=22 if n==N & tag==1
drop tag
duplicates tag PERSON_ID_PE, gen(tag)
drop if tag==1 & n==1
drop tag n N
duplicates report PERSON_ID_PE
sort PERSON_ID_PE
save "$interim\ethnicity_clean", replace

*Religion
**Religion lookup file
clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_RELIGIONTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID RELIGIONTYPE_ID
sort RELIGIONTYPE_ID
save "$temp\lkp_religion", replace

**Merge religion lookups with religion file
clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_RELIGIONS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
sort RELIGIONTYPE_ID
merge m:1 RELIGIONTYPE_ID using "$temp\lkp_religion", keepusing(NAME RELIGIONTYPE_ID)
labmask RELIGIONTYPE_ID, values(NAME)
drop if _m==2
drop _m NAME
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g

sort SOURCE_ID
merge m:1 SOURCE_ID using "$temp\lkp_sources", keepusing(NAME SOURCE_ID)
labmask SOURCE_ID, values(NAME)
rename SOURCE_ID source_religion
drop if _m==2
drop _m NAME ID_PE AVAIL_FROM_DT
recode RELIGIONTYPE_ID (23=24)

**Again there are duplicates that need removing
duplicates drop
**Check this has got rid of all duplicates. If not, code below should solve. If so #winning.
duplicates report PERSON_ID_PE
**This tags the duplicates, drops the row in which religion is unknown, and then recode remaining into religion unknown - should be small numbers
duplicates tag PERSON_ID_PE, gen(tag)
drop if RELIGIONTYPE_ID==24 & tag>0
drop tag
duplicates tag PERSON_ID_PE, gen(tag)
bysort PERSON_ID_PE (RELIGIONTYPE_ID): gen n=_n
bysort PERSON_ID_PE (RELIGIONTYPE_ID): gen N=_N
replace RELIGIONTYPE_ID=24 if (n==N & tag==1)
drop if tag==1 & n==1 & n!=N
drop tag n N
**Check that this has worked and there are no duplicates
duplicates report PERSON_ID_PE

save "$interim\religion_clean", replace

*Nationality
**Nationality lookup file
clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_NATIONALITYTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID NATIONALITYTYPE_ID
sort NATIONALITYTYPE_ID
save "$temp\lkp_nationality", replace

**Merge nationality lookups with nationality table
clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_NATIONALITIES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
sort NATIONALITYTYPE_ID
merge m:1 NATIONALITYTYPE_ID using "$temp\lkp_nationality", keepusing(NAME NATIONALITYTYPE_ID)
labmask NATIONALITYTYPE_ID, values(NAME)
drop if _m==2
drop _m NAME
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g

sort SOURCE_ID
merge m:1 SOURCE_ID using "$temp\lkp_sources", keepusing(NAME SOURCE_ID)
labmask SOURCE_ID, values(NAME)
rename SOURCE_ID source_nationality
drop if _m==2
drop _m NAME ID_PE AVAIL_FROM_DT
recode NATIONALITYTYPE_ID (229=230)

**Drop duplicates 
duplicates drop
*Check this has got rid of all duplicates. If not, need to write more code as above for ethnicity and religion. If so #winning. In this instance there are none.
duplicates report PERSON_ID_PE

save "$interim\nationality_clean", replace

*Languages
**Language lookup file
clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_LANGUAGETYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID LANGUAGETYPE_ID
sort LANGUAGETYPE_ID
save "$temp\lkp_languages", replace

**Merge language lookups with language table
clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_LANGUAGES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
sort LANGUAGETYPE_ID
merge m:1 LANGUAGETYPE_ID using "$temp\lkp_languages", keepusing(NAME LANGUAGETYPE_ID)
labmask LANGUAGETYPE_ID, values(NAME)
drop if _m==2
drop _m NAME
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g

sort SOURCE_ID
merge m:1 SOURCE_ID using "$temp\lkp_sources", keepusing(NAME SOURCE_ID)
labmask SOURCE_ID, values(NAME)
rename SOURCE_ID source_language
drop if _m==2
drop _m NAME ID_PE AVAIL_FROM_DT

**Drop duplicates
duplicates drop
duplicates report PERSON_ID_PE
**If there are still remaining duplicates this code tags the duplicates, drops the row in which language is unknown, and then recode remaining into language unknown - should be small numbers
duplicates tag PERSON_ID_PE, gen(tag)
*Recode refused into unknown
recode LANGUAGETYPE_ID (814=815)
bysort PERSON_ID_PE (LANGUAGETYPE_ID): gen n=_n
bysort PERSON_ID_PE (LANGUAGETYPE_ID): gen N=_N

*Drop those where language is unknown over those where it is recorded as something for cases where there are duplicates
drop if LANGUAGETYPE_ID==815 & tag>0
drop n N tag
*Check this has got rid of all duplicates. If not need to write more code along the lines of the ethnicity section. If so #winning. This seems to not have any more duplicates
duplicates report PERSON_ID_PE

save "$interim\language_clean", replace

*Disability
**Disability lookup file
clear 
odbc load, exec ("select * from SAILCAFEREFV.ECMS_DISABILITYTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
rename ID DISABILITYTYPE_ID
sort DISABILITYTYPE_ID
replace NAME = "Downs Syndrome" in 20
save "$temp\lkp_disability", replace

**Merge in disability lookups with disability table
clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_DISABILITIES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
merge m:1 DISABILITYTYPE_ID using "$temp\lkp_disability", keepusing(DISABILITYTYPE_ID NAME)
drop if _merge==2
labmask DISABILITYTYPE_ID, values(NAME)
drop _merge
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g
rename NAME disability_name

merge m:1 SOURCE_ID using "$temp\lkp_sources", keepusing(SOURCE_ID NAME)
drop if _merge==2
labmask SOURCE_ID, values(NAME)
drop _merge NAME ID_PE AVAIL_FROM_DT
drop disability_name

*Remove full duplicates
duplicates drop
*However, some people have multiple disabilities so I have created flags for each disability they have and also a flag for whether they have any disability at all. B
sort PERSON_ID_PE
duplicates tag PERSON_ID_PE, gen(tag)

*Create flag for if they have disability and extend this for all instances of the same person. But, there are people who have none recorded as a disability and another disability.This code means that any mention of a disability overrides the recording of none or unknown.
generate hasdisability=1 if (DISABILITYTYPE_ID!=19 & DISABILITYTYPE_ID!=12 & DISABILITYTYPE_ID!=23 & DISABILITYTYPE_ID!=20 &  DISABILITYTYPE_ID!=12)
bysort PERSON_ID_PE: egen max_hasdisability=max(hasdisability)
replace max_hasdisability=0 if DISABILITYTYPE_ID==19 & max_hasdisability==.

generate unknowndis=1 if (DISABILITYTYPE_ID==23 | DISABILITYTYPE_ID==20 | DISABILITYTYPE_ID==12)
bysort PERSON_ID_PE: egen max_unknowndis=max(unknowndis)

replace max_hasdisability=.a if max_unknowndis==1 & max_hasdisability!=1
drop max_unknowndis unknowndis hasdisability tag
rename max_hasdisability hasdisability
label define hasdisability 0 "No disability" 1 "Disability" .a "Unknown"
label values hasdisability hasdisability
label var hasdisability "Disability status"

bysort PERSON_ID_PE: gen n=_n

*Create the type of disability flags which are then labelled with the value labels
decode DISABILITYTYPE_ID, gen(strDISABILITYTYPE_ID)
generate newname=substr(strDISABILITYTYPE_ID, 1,30)
levelsof newname, local(levels)

foreach v of local levels {
	local suf=strtoname("`v'")
	generate `suf'=1 if newname=="`v'"
	bysort PERSON_ID_PE: egen `suf'x=max(`suf')
	drop `suf'
}

drop Declined_to_specifyx Nonex Prefer_Not_to_Sayx Unknownx
*Drop duplicates - as you have multiple instances of the same person with all the flags. 
drop DISABILITYTYPE_ID SOURCE_ID n strDISABILITYTYPE_ID newname
duplicates drop
save "$interim\disability_clean", replace


*Merge all these characteristics into the people file
use "$interim\people_clean", clear
sort PERSON_ID_PE
merge 1:1 PERSON_ID_PE using "$interim\ethnicity_clean"
drop if _m==2
rename _merge ethnicity_mis
label var ethnicity_mis "Ethnicity data missing (didn't merge from ethnicity file)"

merge 1:1 PERSON_ID_PE using "$interim\religion_clean"
drop if _m==2
rename _merge religion_mis
label var religion_mis "Religion data missing (didn't merge from religion file)"

merge 1:1 PERSON_ID_PE using "$interim\nationality_clean"
drop if _m==2
rename _merge nationality_mis
label var religion_mis "Nationality data missing (didn't merge from nationality file)"


merge 1:1 PERSON_ID_PE using "$interim\language_clean"
drop if _m==2
rename _merge language_mis
label var language_mis "Language data missing (didn't merge from Language file)"

merge 1:1 PERSON_ID_PE using "$interim\disability_clean"
drop if _m==2
rename _merge disability_mis
label var disability_mis "Disability data missing (didn't merge from disability file)"

*Recode the missing variables 
recode ethnicity_mis (3=0) (1=1)
recode religion_mis (3=0) (1=1)
recode nationality_mis (3=0) (1=1)
recode language_mis (3=0) (1=1)
recode disability_mis (3=0) (1=1)

label define ethnicity_mis 0 "Not missing" 1 "Missing"
label values ethnicity_mis ethnicity_mis

label define religion_mis 0 "Not missing" 1 "Missing"
label values religion_mis religion_mis

label define nationality_mis 0 "Not missing" 1 "Missing"
label values nationality_mis nationality_mis

label define language_mis 0 "Not missing" 1 "Missing"
label values language_mis language_mis

label define disability_mis 0 "Not missing" 1 "Missing"
label values disability_mis disability_mis


save "$path\02people_clean_final", replace
