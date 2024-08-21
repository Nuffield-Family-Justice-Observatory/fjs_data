
***** Persons on application file cleaning and merge with cleaned people file *****

clear
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_PERSONSONAPPLICATIONS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g

*Check how many people have multiple roles on application. Technically there should not be anyone who has multiple roles on an application - they should be mutually exclusive. Having spoken to people at NFJO, practically a person should not be able to have more than one role on an application. However the data shows that a very small number have more than one role. This is likely a data entry error.
tab ISSUBJECT, gen(subject)
drop subject1
tab ISRESPONDENT , gen(respondent)
drop respondent1
tab ISAPPLICANT , gen(applicant)
drop applicant1
tab ISOTHER , gen(other)
drop other1
egen row= rowtotal(subject2 respondent2 applicant2 other2)
tab row 
browse ID_PE ISSUBJECT ISRESPONDENT ISAPPLICANT ISOTHER PERSON_ID_PE if row>1

*Check for duplicates
duplicates report
*Because there is a unique ID for every person in this table need to exclude that from duplicates check. There are some duplicates here, not entirely sure why.
duplicates report PERSON_ID_PE APPLICATION_ID_PE ISSUBJECT ISSUBJECT ISRESPONDENT ISAPPLICANT ISOTHER ISSUBJECTPARTY ISOTHERPARTY  AVAIL_FROM_DT

*Remove all full duplicates (ID not included in varlist as always different) */
duplicates drop ISSUBJECT ISSUBJECT ISRESPONDENT ISAPPLICANT ISOTHER ISSUBJECTPARTY ISOTHERPARTY PERSON_ID_PE APPLICATION_ID_PE AVAIL_FROM_DT, force 
*There are still duplicates based on person ID and application ID. The reason is due to different roles on application and a person-application having a row for each role
duplicates report PERSON_ID_PE APPLICATION_ID_PE 

*Generate a variable for the role on the application
generate role_on_application=1 if ISSUBJECT=="true"
replace role_on_application=2 if ISRESPONDENT=="true"
replace role_on_application=3 if ISAPPLICANT=="true"
replace role_on_application=4 if ISOTHER=="true"
replace role_on_application=.a if ISSUBJECT=="false" & ISRESPONDENT=="false" &ISAPPLICANT=="false" &  ISOTHER=="false"
replace role_on_application=.b if row>1

label var role_on_application "Persons role on application"
label def role_on_application 1 "Subject" 2 "Respondent" 3 "Applicant" 4 "Other" .a "Missing" .b "Unclear", modify
label values role_on_application role_on_application

browse ID_PE ISSUBJECT ISRESPONDENT ISAPPLICANT ISOTHER PERSON_ID_PE if row!=1

*This tags the duplicates (due to having a new row for more than one role on application recorded) and then replaces the role on the application as unclear. Then it removes the duplicates and keeps one which identifies unclear role on application */
duplicates tag PERSON_ID_PE APPLICATION_ID_PE, gen(Tag)
replace role_on_application=.b if Tag==1
drop Tag
duplicates drop PERSON_ID_PE APPLICATION_ID_PE, force
*Drop these and use role on application as new variables
drop ISSUBJECT ISRESPONDENT ISAPPLICANT ISOTHER subject2 respondent2 applicant2 other2 

save "$interim\persons_on_application", replace

*Merge with applications table
sort APPLICATION_ID_PE
merge m:1 APPLICATION_ID_PE using "$path\01applications_clean" /*Some observations have not merged here. This is where there is a record of an application in the applications table but not in the persons on applications table. This is a very small relative number. Have kept them but maybe stay aware that there will be some applications that do not have person data attached to it (the people data is only possible to be merged via. the persons on application table) */
*Drop persons on applications who are not linked to an application (this should be rare) *
drop if _m==1 
drop _m

*Now merge in the people characteristics
sort PERSON_ID_PE
merge m:1 PERSON_ID_PE using "$path\02people_clean_final" /* You've got a lot of people who don't merge. Where they are in the people file but not person on application file - so people who cannot be connected to their application. I think this is OK though, just remove them. A lot of the ID's suggest perhaps from the earlier CMS. The ones that don't merge who are in the Master but not using dataset are the ones who did not merge above - i.e. that have an application but no persons on application record so this is to be expected */
drop if _merge==2
drop _merge AVAIL_FROM_DT

*This is a dataset of every person involved in any type of proceedings. Here I restrict this to children. Define children as under 18 at the time of application.
generate age=age(WEEKOFBIRTH, DATEOFAPPLICATION) if WEEKOFBIRTH!=.
*Check outliers
browse ID_PE role_on_application PERSON_ID_PE APPLICATION_ID_PE WEEKOFBIRTH DATEOFAPPLICATION age if age>89 & age!=.
*looks like some of these are where there was an 8 placed instead of a 9 and some were mis-typed. This needs researchers discretion. 
generate yearofbirth=year(WEEKOFBIRTH)
generate monthofbirth=month(WEEKOFBIRTH)
generate dayofbirth=day(WEEKOFBIRTH)
generate first_two_digits_yr=floor(yearofbirth/100)
recode first_two_digits_yr (18=19) (22=20) (29=20) (79=19) /*probably needs checking based on individual circumstances*/
tostring yearofbirth, replace
generate last_two_digits_yr=substr(yearofbirth,3,2)
destring last_two_digits_yr, replace
generate yearofbirth1=(first_two_digits_yr*100)+last_two_digits_yr
drop yearofbirth first_two_digits_yr last_two_digits_yr
generate dob=dmy(dayofbirth, monthofbirth, yearofbirth1)
label var dob "Date of birth"
format dob %td

*Re-calculate ages. There are still some outliers but a small number - leave in.
drop age
generate age=age(dob, DATEOFAPPLICATION) if dob!=.
label var age "Age at application date"

*Now do age restriction to under 18
keep if age<18
tab role_on_application /* A number of children are not subjects. */
tab age role_on_application /* Low numbers which jump up as the chilren get older. This implies that may not actually be in proceedings as the subject. */


drop ID_PE  monthofbirth dayofbirth yearofbirth WEEKOFBIRTH row NAME

*Label all the variables
label var CASE_ID_PE "Case ID"
label var PERSON_ID_PE "Person ID"
label var APPLICATION_ID_PE "Application ID"
label var APPLICATIONTYPE1_ID "Type of application made"
label var ISSUBJECTPARTY "Flag whether subject is party to proceedings"
label var ISOTHERPARTY "Flag for whether other is party to proceedings"
label var DATEOFAPPLICATION "Date application is made"
label var DATERECEIVED "Date application received by Cafcass"
label var DATECOMPLETED "Date completed?" /* Not clear whether this is completed by cafcass or completed by the court? */
label var DATEAPPLICATIONCOMPLETED "Date application completed?" /* As above unclear */
label var APPLICATIONREASON_ID "Reason for application" /*This only has X responses therefore I think you can remove from var list */
label var GENDER "Gender"
label var dob "Date of birth"
label var ALF2_PE "Linkage ID to Family Court"
label var ALF_PE "Linkage ID"
label var COURTCOURTLEVELREF_ID "Court reference number"
label var DATENOTIFIED "Date Cafcass notified of this application"
label var ETHNICITYTYPE_ID "Ethnicity"
label var CIRCUITREF_ID "Circuit level"
label var DJAREAREF_ID "District Judge Area level"
label var COURTLEVELREF_ID "Type of court (level)"
label var COURT_ID "Court"
label var source_ethnicity "Source of ethnicity info"
label var source_religion "Source of religion info"
label var source_language "Source of language info"
label var source_nationality "Source of nationality info"
label var RELIGIONTYPE_ID "Religion"
label var NATIONALITYTYPE_ID "Nationality"
label var LANGUAGETYPE_ID "Main language spoken"
label var nationality_mis "Nationality data missing (didn't merge from Nationality file)"
label var religion_mis "Religion data missing (didn't merge from Nationality file)"

foreach x of varlist Autism_or_Spectrum_Disordersx Blind_Partially_Sightedx Cerebral_Palsyx Deaf_Hearing_Impairedx Downs_Syndromex Dyslexiax Facial_Disfigurementx Global_Development_Delayx Learning_Difficulties__e_g__Dyx Learning_Disabilityx Manual_Dexterityx Mental_Health_Difficultiesx Need_Personal_Care_Supportx Otherx Progressive_Conditionsx Speech_Impairmentx Unseen_Disabilitiesx Wheelchair_Mobility_Difficultix {
	
	label var `x' "Flag `x'"

}

order CASE_ID_PE PERSON_ID_PE APPLICATION_ID_PE num_applications APPLICATIONTYPE1_ID role_on_application ISSUBJECTPARTY ISOTHERPARTY DATEOFAPPLICATION DATERECEIVED DATENOTIFIED DATECOMPLETED DATEAPPLICATIONCOMPLETED NEWAPPLICATIONDATE REVOCATIONAPPLICANTTYPEID APPLICATIONREASON_ID GENDER dob age ETHNICITYTYPE_ID ethnicity_mis source_ethnicity RELIGIONTYPE_ID religion_mis source_religion NATIONALITYTYPE_ID nationality_mis source_nationality LANGUAGETYPE_ID language_mis source_language hasdisability Autism_or_Spectrum_Disordersx Blind_Partially_Sightedx Cerebral_Palsyx Deaf_Hearing_Impairedx Downs_Syndromex Dyslexiax Facial_Disfigurementx Global_Development_Delayx Learning_Difficulties__e_g__Dyx Learning_Disabilityx Manual_Dexterityx Mental_Health_Difficultiesx Need_Personal_Care_Supportx Otherx Progressive_Conditionsx Speech_Impairmentx Unseen_Disabilitiesx Wheelchair_Mobility_Difficultix disability_mis ALF_PE ALF2_PE CIRCUITREF_ID DJAREAREF_ID COURTLEVELREF_ID COURT_ID COURTCOURTLEVELREF_ID


save "$path\03Core_dataset_ECMS", replace

