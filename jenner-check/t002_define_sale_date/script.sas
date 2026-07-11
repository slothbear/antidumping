/* jenner-check bundle: DEFINE_SALE_DATE from common-macros.sas (slothbear/antidumping)
   Source: common-macros.sas, PART 5: "SELECTIVELY ADJUST SALE DATE BASED ON
   AN EARLIER DATE VARIABLE". Reproduced verbatim; the DATA step below is a
   caller built from the real invocation used throughout the repo (see
   nme-margin-calculation.sas / me-margin-calculation.sas, where U.S. sales
   are read in with:
       %DEFINE_SALE_DATE (SALEDATE = &USSALEDATE, DATEBEFORESALE = &USDATEBEFORESALE,
                           EARLIERDATE = &USEARLIERDATE);
   applied inside the DATA step that reads COMPANY.&USDATA). */

%MACRO DEFINE_SALE_DATE (SALEDATE =, DATEBEFORESALE =, EARLIERDATE =);
    %IF &DATEBEFORESALE = YES %THEN
    %DO;
        &EARLIERDATE = FLOOR(&EARLIERDATE); /* Eliminates the time part of sale date */
                                            /* when defined as a datetime variable.  */
        IF &EARLIERDATE < &SALEDATE THEN
            &SALEDATE = &EARLIERDATE;
    %END;
%MEND DEFINE_SALE_DATE;

/* Stand-in for COMPANY.&USDATA: invoice date (SALEDATE) vs. an earlier
   contract/shipment date (SHIPDATU) -- the same shape the antidumping
   programs use to decide which date actually governs the sale. */
DATA USSALES;
    LENGTH US_IMPORTER $20;
    INFORMAT SALEDATE SHIPDATU DATE9.;
    FORMAT SALEDATE SHIPDATU DATE9.;
    INPUT US_IMPORTER $20. SALEDATE SHIPDATU;

    /* Real call convention from the repo: adjust SALEDATE to the earlier
       SHIPDATU whenever "sales before shipment" applies to this record. */
    %DEFINE_SALE_DATE (SALEDATE = SALEDATE, DATEBEFORESALE = YES, EARLIERDATE = SHIPDATU);

    DATALINES;
ACME TRADING         15MAR2024 01MAR2024
DELTA IMPORTS        22APR2024 22APR2024
GLOBAL METALS INC    05MAY2024 28APR2024
HARBOR STEEL CO      10JUN2024 15JUN2024
PACIFIC RIM TRADERS  01JUL2024 20JUN2024
;
RUN;

PROC PRINT DATA = USSALES NOOBS;
    VAR US_IMPORTER SHIPDATU SALEDATE;
    TITLE "SALE DATE AFTER SELECTIVE EARLIER-DATE ADJUSTMENT";
RUN;
