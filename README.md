# Developing a child-level family court dataset using Cafcass data
## Repository description
The aim was to create a child-level dataset of families going through the family courts (in both public and private law) using Cafcass data. This repository contains code that generates this. Note this is a work in progress so I'd be grateful if you report any issues you find. Suggestions for improvements are also welcome. The code has initially been written for the Cafcass ECMS database but will be rolled out to include Cafcass CMS and Cafacass Cymru data shortly.

In each folder a guidance document is available on how to set up your file structure and a description of what each of the do files does.

## Data sources
Cafcass (Children and Family Court Advisory Support Service) data is available through the SAIL databank. In England there are two case management systems used by Cafcass - the CMS (2007-2014) and the ECMS (2014-present). In Wales there is just one - Cafcass Cymru.

For a visual representation of how the raw data tables are structured see:

* England: https://docs.hiru.swan.ac.uk/display/SATP/CAFE+-+Cafcass+England

* Wales: https://docs.hiru.swan.ac.uk/display/SATP/CAFW+-+CAFCASS+Wales

For variable lists see:

* England: https://web.www.healthdatagateway.org/dataset/8ee61578-e298-423a-be22-cb0438023e5c

* Wales: https://web.www.healthdatagateway.org/dataset/29a714e1-5289-4362-be24-2848c954344e

## Software
The code was developed using Stata.

## Other useful references
Bedston SJ, Pearson RJ, Jay MA, Broadhurst K, Gilbert R, Wijlaars L. Data Resource: Children and Family Court Advisory and Support Service (Cafcass) public family law administrative records in England. Int J Popul Data Sci. 2020;1159. Published 2020 Mar 26. https://ijpds.org/article/view/1159

Johnson, R. D., Ford, D. V., Broadhurst, K., Cusworth, L., Jones, K. H., Akbari, A., Bedston, S., Alrouh, B., Doebler, S., Lee, A., Smart, J., Thompson, S., Trinder, L., & Griffiths, L. J. (2020). Data Resource: population level family justice administrative data with opportunities for data linkage. International Journal of Population Data Science, 1339. https://doi.org/10.23889/ijpds.v5i1.1339

Any questions/issues can be directed to me at cedney@nuffieldfoundation.org

Code cleared for publication by SAIL on the 21st August 2024.
