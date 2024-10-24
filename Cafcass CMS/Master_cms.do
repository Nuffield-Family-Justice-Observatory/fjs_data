*This code saves time by automating the process by which the Cafcass data is loaded in each of the do files - it means entering usernames, passwords and locations to save only once. 

*Enter your SAIL username and password here
global user "xxxx"
global password "xxxx"
*Enter the project number in SAIL
global project "1661V"
*Enter the path that you want to save the final files in e.g.
global pathcms "S:\1661 - Understanding the family justice system\Data setup\Raw files\Final files\CMS"
*Enter the location for the lookup files to be saved e.g. 
global tempcms "S:\1661 - Understanding the family justice system\Data setup\Raw files\Lookups\CMS"
*Enter the location for the interim files to be stored
global interimcms "S:\1661 - Understanding the family justice system\Data setup\Raw files\Interim files\CMS"

*Select the command directory where the do files will be saved and run from e.g. 
cd "S:\1661 - Understanding the family justice system\Data setup\Do files\Final\CMS"

/******************************
This do file runs a cleaning of the applications file and merges to all the lookups for court references and application types.
*******************************/

do 01create_applications_cms

/******************************
This do file runs a cleaning of the people file.
*******************************/

do 02create_people_cms

/******************************
This do file runs a cleaning of the application members file.
*******************************/

do 03application_members_cms


/******************************
This do file attaches the relationships to the dataset and the personal characteristics of mother and father (where present). It results in a core dataset at person-application level 
*******************************/

do 04create_relationships_cms

/******************************
This do file runs a cleaning of the legal output file and creates flags for each legal output that has happened on an application-person level. 
*******************************/

do 05create_legaloutputs_cms

/******************************
This do file runs a cleaning of the cases file and creates summary variables which can be loaded into the main dataset if required.
*******************************/

do 06create_cases_cms


**The files you haven't used are the case participant, case hearing, case report, member resolution, experts and expert specialities.

/******************************
Erase all temporary files at end to conserve space
*******************************
local datafiles: dir  "$temp/" files "*.dta"

foreach file of local datafiles {
	
	di "`file'"
	erase "temp/`file'"
}


*/////



