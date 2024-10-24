
***** This do file cleans the people file which contain characteristics of each person in the dataset *****

*Lookups from characteristics
clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPDISABILITY_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename DISABILITYID DISABILITYREF
sort DISABILITYREF
save "$tempcms\lkp_disability", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPETHNICORIGIN_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID ETHNICREF
sort ETHNICREF
save "$tempcms\lkp_ethnicity", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPLANGUAGE_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID FIRSTLANGUAGEREF
sort FIRSTLANGUAGEREF
save "$tempcms\lkp_language", replace

clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPRELIGION_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID RELIGIONREF
sort RELIGIONREF
save "$tempcms\lkp_religion", replace

*Merge lookups
clear 
odbc load, exec ("select * from SAIL$project.CAFE_CMS_TBLPERSON_20191220") dsn (PR_SAIL) user ($user) password ($password)

duplicates drop 
drop AVAIL_FROM_DT

sort DISABILITYREF
merge m:1 DISABILITYREF using "$tempcms\lkp_disability", keepusing(DISABILITYREF DISABILITY)
labmask DISABILITYREF, values(DISABILITY)
drop if _m==2
drop _merge DISABILITY

sort ETHNICREF
merge m:1 ETHNICREF using "$tempcms\lkp_ethnicity", keepusing(ETHNICREF CAPTION)
labmask ETHNICREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

sort FIRSTLANGUAGEREF
merge m:1 FIRSTLANGUAGEREF using "$tempcms\lkp_language", keepusing(FIRSTLANGUAGEREF CAPTION)
labmask FIRSTLANGUAGEREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

sort RELIGIONREF
merge m:1 RELIGIONREF using "$tempcms\lkp_religion", keepusing(RELIGIONREF CAPTION)
labmask RELIGIONREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

drop MOB_LINKAGE

save "$pathcms\02people_cleaned", replace
