***** This cleans the case application member file and merges with cleaned applications and people files *****

clear 
odbc load, exec ("select * from SAIL$project.CAFE_CMS_TBLCASEAPPLICATIONMEMBER_20191220") dsn (PR_SAIL) user ($user) password ($password)

*Member type has replaced converted type variable so consolidated these two variables 
replace MEMBERTYPE=1 if CONVERTEDTYPE=="Adult Applicant" & MEMBERTYPE==16
replace MEMBERTYPE=2 if CONVERTEDTYPE=="Adult Respondent" & MEMBERTYPE==16
replace MEMBERTYPE=8 if CONVERTEDTYPE=="Adult" & MEMBERTYPE==16 
label define MEMBERTYPE 1 "Adult applicant" 2 "Adult respondent" 4 "Subject" 8 "Unknown", modify
label values MEMBERTYPE MEMBERTYPE

drop  AVAIL_FROM_DT CONVERTEDTYPE

duplicates drop CASEAPPLICATIONREF_PE MEMBERREF_PE MEMBERTYPE ISPARTY ISLAREP, force

duplicates tag CASEAPPLICATIONREF MEMBERREF, gen(Tag)
generate role_on_application=1 if MEMBERTYPE==4
replace role_on_application=2 if MEMBERTYPE==2
replace role_on_application=3 if MEMBERTYPE==1
replace role_on_application=.b if MEMBERTYPE==8
label var "Persons role on application"
label def role_on_application 1 "Subject" 2 "Respondent" 3 "Applicant" .b "Unclear", modify
label values role_on_application role_on_application

replace MEMBERTYPE.b if Tag==1
drop Tag MEMBERTYPE

save "$interimcms\case_application_member_clean", replace

rename CASEAPPLICATIONREF_PE CASEAPPLICATIONID_PE
merge m:1 CASEAPPLICATIONID_PE using "$pathcms\01applications_clean"
drop _merge

rename MEMBERREF_PE PERSONID_PE
merge m:1 PERSONID_PE using "$pathcms\02people_cleaned"
drop _merge

**Calculate ages
generate age=age(WEEKOFBIRTH, DATEOFAPPLICATION) if WEEKOFBIRTH!=.
drop AVAIL_FROM_DT

label var CASEAPPLICATIONMEMBERID_PE 
label var CASEAPPLICATIONID_PE "Application ID "
label var PERSONID_PE "Person ID"
label var MEMBERTYPE "Role on application"
label var CASEREF_PE "Case ID"
label var CASEAPPLICATIONTYPEREF "Type of application made"
label var COURTREF "Court"
label var DATEOFAPPLICATION "Date application made"
label var DATERECEIVED "Date application received"
label var DATECOMPLETED "Date application completed"
label var DATEAPPLICATIONCOMPLETED "Date application completed"
label var LAWTYPES "Law type"
label var COURTLEVELREF "Type of court"
label var CIRCUITREF "Circuit area"
label var DFJAREAREF "Designated Family Judge Area"
label var ALF2_PE "Data linkage field2"
label var ALF_PE "Data linkage field1"
label var ETHNICREF "Ethnicity"
label var RELIGIONREF "Religion"
label var FIRSTLANGUAGEREF "First language"
label var INTERPRETERREQ "Interpreter requested"
label var DISABILITYREF "Disability type"
label var GENDER "Gender"
label var WEEKOFBIRTH "Week of birth"
label var age "Age"


*Keep only children/subjects on application 
keep if MEMBERTYPE==4
drop if age>=18

save "$pathcms\03Core_dataset_CMS", replace

