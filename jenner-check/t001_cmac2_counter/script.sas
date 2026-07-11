/* jenner-check bundle: CMAC2_COUNTER from common-macros.sas (slothbear/antidumping)
   Source: common-macros.sas, PART 2: "MACRO TO GET COUNTS OF THE DATASETS
   THAT NEED BE TO REVIEWED". Reproduced verbatim; only the call site and the
   input dataset below are new, standing in for the COMPANY.&USDATA sales
   extract the antidumping programs count at each pipeline stage. */

%MACRO CMAC2_COUNTER (DATASET =, MVAR =);
    %GLOBAL COUNT_&MVAR.;
    PROC SQL NOPRINT;
          SELECT COUNT(*)
           INTO :COUNT_&MVAR.
           FROM &DATASET.;
       QUIT;
%MEND CMAC2_COUNTER ;

/* Stand-in for COMPANY.&USDATA: a small U.S. sales extract with the shape
   the antidumping margin-calculation programs expect (importer, quantity,
   gross unit price). */
DATA USSALES;
    LENGTH US_IMPORTER $20;
    INPUT US_IMPORTER $20. SALEQTY GROSSPRICE;
    DATALINES;
ACME TRADING         1200 45.50
ACME TRADING          800 46.10
DELTA IMPORTS         450 52.75
DELTA IMPORTS         600 51.90
DELTA IMPORTS         300 53.20
GLOBAL METALS INC    2200 38.40
GLOBAL METALS INC    1750 39.00
HARBOR STEEL CO       900 41.15
HARBOR STEEL CO      1100 40.85
PACIFIC RIM TRADERS   500 49.60
;
RUN;

/* Real call convention from the repo (see nme-margin-calculation.sas,
   "GET USSALES COUNT FOR LOG REPORTING PURPOSES"):
       %CMAC2_COUNTER (DATASET = COMPANY.&USDATA, MVAR = ORIG_USSALES); */
%CMAC2_COUNTER (DATASET = USSALES, MVAR = ORIG_USSALES);

%PUT NOTE: COUNT_ORIG_USSALES = &COUNT_ORIG_USSALES;

DATA _NULL_;
    PUT "US sales observation count: &COUNT_ORIG_USSALES";
RUN;
