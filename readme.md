> This repository contains data files from the Department of Commerce
> You can find the source data at http://enforcement.trade.gov/sas/programs/amcp.html
> The readme below is a copy of the text at that site.

## Antidumping Margin Calculation Programs

On this page you will find the generic antidumping (AD) margin calculation
programs. These programs are the starting point of our AD calculations. For a
particular company in a proceeding, a case analyst will fill in the company’s
case-specific information in the required sections and make any changes to the
boilerplate code required for the situation.  

There are two types of AD calculations: 1) market-economy (ME); and 2)
nonmarket-economy (NME). The AD programs required for each are found below. In
both types, we compare prices in the United States to some minimum standard
called, Normal Value (NV).  

### Market-Economy Programs

In ME calculations, we base NV on the company’s actual costs and prices in the
comparison market. The comparison market can be either the home country of the
respondent or some other suitable 3rd country. If no suitable comparison
market is found, we base NV on Constructed Value (CV) which is a cost-based
build up of a surrogate price.  

Here are the three programs used in ME calculations:  

1. Comparison Market (CM) Program `me_comparison.sas`
2. Margin Program `me_margin.sas`
3. Macros Program `me_macros.sas`

When a comparison market is the basis of NV, the first program used is the CM
Program. The CM Program is where the case analyst enters information about the
company’s costs and sales in the comparison market. The Macros Program is
where the bulk of the code is stored. When the CM Program is executed, it
calls up the relevant portions of code from the Macros Program to process the
CM sales and saves the results for use in the Margin Program. After the CM
Program is run, the Margin Program is completed by the analyst. When executed,
the Margin program calls in relevant portions of the Macros Program to process
U.S. sales and then compare them to CM sales or CV to calculate the AD duty
rate. When there is no comparison market, only the Margin Program and Macros
Program are required for comparisons of U.S. prices straight to CV.  

### Nonmarket-Economy Programs

In nonmarket-economy AD calculations, NV is comprised of the company’s factors
of production (i.e., recipe for manufacturing the goods in question) valued in
some appropriate surrogate country.  

Here is the NME program:  

1. NME Margin Program `nme_margin.sas`

In all NME calculations, the Margin Program is required. In the Margin
Program, the analyst fills in the required case-specific information.
