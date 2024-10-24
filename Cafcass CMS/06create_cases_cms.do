*************** This file merges in the case-level information e.g. law type *********************

*Lookups
clear
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPCASESTATUS_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID CASESTATUSREF
sort CASESTATUSREF
save "$tempcms\lkp_casestatus", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPLOCALAUTHORITY_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename LOCALAUTHORITYID LOCALAUTHORITYREF
sort LOCALAUTHORITYREF
save "$tempcms\lkp_localauthority", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPREGION_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename REGIONID REGIONREF
sort REGIONREF
save "$tempcms\lkp_region", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPLAWTYPE_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename ITEMID LAWTYPEREF
sort LAWTYPEREF
save "$tempcms\lkp_lawtype", replace

*Merge lookups
clear 
odbc load, exec ("select * from SAIL$project.CAFE_CMS_TBLCASE_20191220") dsn (PR_SAIL) user ($user) password ($password)
sort CASESTATUSREF
merge m:1 CASESTATUSREF using "$tempcms\lkp_casestatus", keepusing(CASESTATUSREF CAPTION)
drop if _m==2
labmask CASESTATUSREF, values(CAPTION)
drop _merge CAPTION

sort LOCALAUTHORITYREF
merge m:1 LOCALAUTHORITYREF using "$tempcms\lkp_localauthority", keepusing(LOCALAUTHORITYREF AUTHORITY)
labmask LOCALAUTHORITYREF, values(AUTHORITY)
drop if _m==2
drop _merge AUTHORITY

sort REGIONREF
merge m:1 REGIONREF using "$tempcms\lkp_region", keepusing(REGIONREF REGION)
labmask REGIONREF, values(REGION)
drop if _m==2
drop _merge REGION

sort LAWTYPEREF
merge m:1 LAWTYPEREF using "$tempcms\lkp_lawtype", keepusing(LAWTYPEREF CAPTION)
labmask LAWTYPEREF, values(CAPTION)
drop if _m==2
drop _merge CAPTION

sort CASEID_PE
save "$interimcms\cases_clean", replace

use "$pathcms\05Core_dataset_CMS_withLO_rels", clear
sort CASEID_PE
merge m:1 CASEID_PE using "$interimcms\cases_clean"
drop if _m==2
drop _merge

save "$pathcms\06Final_dataset", replace
