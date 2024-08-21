*This code saves a lot of time by automating the process by which the Cafcass data is loaded in each of the do files - it means entering usernames, passwords and locations to save only once. 
*Enter your SAIL username and password here
global user "XXX"
global password "XXXX"
*Enter the project number in SAIL
global project "1661V"
*Enter the most up-to-date Cafcass data date
global refreshdate "20240111"
*Enter the path that you want to save the final files in e.g.
global path "S:\1661 - Understanding the family justice system\Data setup\Raw files\Final files"
*Enter the location for the lookup files to be saved e.g. 
global temp "S:\1661 - Understanding the family justice system\Data setup\Raw files\Lookups"
*Enter the location for the interim files to be stored
global interim "S:\1661 - Understanding the family justice system\Data setup\Raw files\Interim files"


*Select the command directory where the do files will be saved and run from e.g. 
cd "S:\1661 - Understanding the family justice system\Data setup\Do files"

/******************************
This do file runs a cleaning of the applications file and merges to all the lookups for court references and application types.
*******************************/

do 011create_applications

/******************************
This do file runs a cleaning of the people file. It merges any characteristics held in a different table such as ethnicity or disability. 
*******************************/

do 012create_people

/******************************
This do file runs a cleaning of the persons on application file. It merges any characteristics held in a different table such as ethnicity, disability, language, religion, nationality of the person on application. 
*******************************/

do 013create_personsonapplication


/******************************
This do file attaches the relationships to the dataset and the personal characteristics of mother and father (where present). It results in a core dataset at person-application level 
*******************************/

do 014create_linkingdatasets

/******************************
This do file runs a cleaning of the legal output file and creates flags for each legal output that has happened on an application-person level. 
*******************************/

do 015create_legaloutputs

/******************************
This do file runs a cleaning of the cases file and creates summary variables which can be loaded into the main dataset if required.
*******************************/

do 016create_cases


/******************************
Erase all temporary files at end to conserve space
*******************************
local datafiles: dir  "$temp/" files "*.dta"

foreach file of local datafiles {
	
	di "`file'"
	erase "temp/`file'"
}


*/////

