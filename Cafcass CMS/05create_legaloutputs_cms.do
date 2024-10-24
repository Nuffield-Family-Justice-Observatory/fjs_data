***** Cleaning legal outputs file ***** Note legal orders are recorded for the case (well, in public law). This is different to the ECMS where legal orders are recorded for the subject on the application. 

*Lookups
clear 
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPLEGALOUTPUTTYPE_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename LEGALOUTPUTTYPEID LEGALOUTPUTTYPEREF
sort LEGALOUTPUTTYPEREF
save "$tempcms\lkp_legaloutputtype", replace

clear
odbc load, exec ("select * from SAILCAFEREFV.CMS_TLKPLEGALOUTPUTCLASS_20191220") dsn (PR_SAIL) user ($user) password ($password)
rename LEGALOUTPUTCLASSID LEGALOUTPUTCLASSREF
sort LEGALOUTPUTCLASSREF
save "$tempcms\lkp_legaloutputclass", replace

clear
odbc load, exec ("select * from SAIL$project.CAFE_CMS_TBLLEGALOUTPUT_20191220") dsn (PR_SAIL) user ($user) password ($password)
sort LEGALOUTPUTTYPEREF
merge m:1 LEGALOUTPUTTYPEREF using "$tempcms\lkp_legaloutputtype", keepusing(LEGALOUTPUTTYPEREF LEGALOUTPUTTYPE LEGALOUTPUTCLASSREF)
labmask LEGALOUTPUTTYPEREF, values(LEGALOUTPUTTYPE)
drop if _m==2
drop _merge LEGALOUTPUTTYPE

sort LEGALOUTPUTCLASSREF
merge m:1 LEGALOUTPUTCLASSREF using "$tempcms\lkp_legaloutputclass", keepusing(LEGALOUTPUTCLASSREF LEGALOUTPUTCLASS)
labmask LEGALOUTPUTCLASSREF, values(LEGALOUTPUTCLASS)
drop if _m==2
drop _merge LEGALOUTPUTCLASS
rename CASEREF_PE CASEID_PE

*Remove duplicates
duplicates drop CASEHEARINGREF_PE LEGALOUTPUTTYPEREF FURTHERWORKTYPEREF ISCAFCASSWORK EXPIRYDATE ISFINAL CASEID_PE LEGALORDERHEARINGDATE AVAIL_FROM_DT LEGALOUTPUTCLASSREF, force

*Categorising legal orders --> have pre-categorised to remove legal outputs that are not relevant and combined some legal order categories.
merge m:1 LEGALOUTPUTTYPEREF using "S:\1661 - Understanding the family justice system\Data setup\Do files\Legal_categoriesCMS", keepusing(isalegalorder legal_order_cat Rule164 s7report miam )

replace legal_order_cat="Rule16.4" if Rule164==1
replace legal_order_cat="S.7 Report" if s7report==1
replace legal_order_cat="MIAM" if miam==1

drop Rule164 s7report miam


*This code creates a flag for legal orders/outputs on application (after categorising)
*First restrict to 30 chars to allow code to run
generate newname=substr(legal_order_cat, 1,30)
levelsof newname, local(levels)

foreach v of local levels {
	local suf=strtoname("`v'")
	generate `suf'=1 if newname=="`v'"
	bysort CASEID_PE: egen `suf'x=max(`suf')
	drop `suf'
}

*Generate the numbers of legal outputs made per case
bysort CASEID_PE: generate N1=_N
rename N1 num_legal_outputs
label var num_legal_outputs "Total number of legal outputs made (by person and application)"

drop CASEHEARINGREF_PE LEGALOUTPUTTYPEREF FURTHERWORKTYPEREF ISCAFCASSWORK EXPIRYDATE ISFINAL LEGALORDERHEARINGDATE newname _merge LEGALOUTPUTID_PE AVAIL_FROM_DT LEGALOUTPUTCLASSREF isalegalorder legal_order_cat
duplicates drop
duplicates report

sort CASEID_PE
save "$interimcms\legal_outputs_clean", replace

use "$pathcms\04Core_dataset_CMS_withrels", clear
drop _merge
rename CASEREF_PE CASEID_PE
sort CASEID_PE
merge m:1 CASEID_PE using "$interimcms\legal_outputs_clean"
drop if _m==2
drop _merge

sort CASEID_PE
save "$pathcms\05Core_dataset_CMS_withLO_rels", replace
