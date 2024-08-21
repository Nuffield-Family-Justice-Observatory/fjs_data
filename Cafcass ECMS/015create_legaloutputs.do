
***** Cleaning legal outputs file ***** Note legal orders are recorded for the child (well, in public law)
clear
odbc load, exec ("select * from SAILCAFEREFV.ECMS_LEGALOUTPUTTYPES_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)

*Replace names in legal outputs which include a unicode character in lookup file - this may not be necessary and list may change so be very careful using this code.
sort NAME
replace NAME = "DR at FHDRA full agreement final order" in 45
replace NAME = "DR at FHDRA no agreement Cafcass further work" in 46
replace NAME = "DR at FHDRA partial agreement signpost to SPIP" in 47
replace NAME = "Referred to LA - SPH" in 113
replace NAME = "Referred to PSU - SPH" in 115
rename ID LEGALOUTPUTTYPE_ID
sort LEGALOUTPUTTYPE_ID
save "$temp\lkp_legaloutputtype", replace

clear 
odbc load, exec ("select * from SAIL$project.CAFE_ECMS_LEGALOUTPUTS_$refreshdate") dsn (PR_SAIL) user ($user) password ($password)
sort LEGALOUTPUTTYPE_ID
merge m:1 LEGALOUTPUTTYPE_ID using "$temp\lkp_legaloutputtype"
drop if _merge==2
labmask LEGALOUTPUTTYPE_ID, values(NAME)
drop AVAIL_FROM_DT _merge

destring PERSON_ID_PE, replace
format PERSON_ID_PE %14.0g

*Remove duplicates (leave out the ID as this is unique)
duplicates drop PERSON_ID_PE CASE_ID_PE ISFPR164 DATEORDERED APPLICATION_ID_PE LEGALOUTPUTTYPE_ID NAME SORTORDER ISACTIVE ISLOCKED PUBLICSORTORDER PRIVATESORTORDER APPLIESTOSUBJECT ALLAPPLICATIONTYPES, force

*Generate the numbers of legal outputs made per person and application
bysort APPLICATION_ID_PE PERSON_ID_PE(DATEORDERED): generate n1=_n
bysort APPLICATION_ID_PE PERSON_ID_PE (DATEORDERED): generate N1=_N
rename N1 num_legal_outputs
label var num_legal_outputs "Total number of legal outputs made (by person and application)"

*Drop unnecessary variables
drop SORTORDER ISACTIVE ISLOCKED PUBLICSORTORDER PRIVATESORTORDER ALLAPPLICATIONTYPES

*Created a file with our categories for legal orders/outputs which can then be merged into the main dataset. This was to simplify which is not technically necessary
merge m:1 LEGALOUTPUTTYPE_ID using Legal_categories, keepusing(isalegalorder legal_order_cat Rule164 s7report miam )
drop _merge
replace legal_order_cat="Rule16.4" if Rule164==1
replace legal_order_cat="S.7 Report" if s7report==1
replace legal_order_cat="MIAM" if miam==1

drop Rule164 s7report miam

*Create a flag for each legal order/outputs on application (after categorising)
**Restrict to 30 chars to allow code to run
generate newname=substr(legal_order_cat, 1,30)
levelsof newname, local(levels)

foreach v of local levels {
	local suf=strtoname("`v'")
	generate `suf'=1 if newname=="`v'"
	bysort PERSON_ID_PE APPLICATION_ID_PE: egen `suf'x=max(`suf')
	drop `suf'
}


drop NAME newname APPLIESTOSUBJECT n1 recent_legal_order ISFPR164 ID_PE DATEORDERED num_legal_outputs LEGALOUTPUTTYPE_ID isalegalorder legal_order_cat
duplicates drop
duplicates report

/*Previous research has identified the "highest legal order" from the flags by using a pre-defined hierarchy in public law see NFJO published research for more information. But in this code we only identify the flags. A hierarchy can be added here if needed. 
*/

save "$interim\legaloutputs", replace

*Merge legal outputs into the core dataset file. About 8% of people and applications who don't merge on the person and application ids. Have looked into who doesn't merge and it's mainly people who are not the subject on the application and/or are older, and haven't yet had a completed case! Matching rate after accounting for these two things (subject and completed case gives 99.65% match rate.)
use "$path\04Coredataset_wrels", clear
merge 1:m PERSON_ID_PE APPLICATION_ID_PE using "$interim\legaloutputs"
drop if _merge==2
drop _merge
save "$path\05Core_dataset_ECMS_LO_rels", replace

