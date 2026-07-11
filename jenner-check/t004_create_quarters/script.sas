/* jenner-check bundle: CREATE_QUARTERS from me-macros.sas (slothbear/antidumping)
   Source: me-macros.sas, macro CREATE_QUARTERS -- assigns each U.S. sale to
   a period-of-review quarter (QTR) relative to &BEGINPERIOD, which is how
   the antidumping margin-calculation programs group sales for time-based
   comparisons (see me-margin-calculation.sas / me-comparison-market.sas,
   "Part 6: Create Concordance of Price-To-Price Matching Instructions").
   Reproduced verbatim; only the call site and its mock USSALES dataset
   are new. */

%MACRO CREATE_QUARTERS(SLDT, PROGRAM);
    %GLOBAL HM_TIME_PERIOD US_TIME_PERIOD;

    %LET HM_TIME_PERIOD = ;
    %LET US_TIME_PERIOD = ;

    %IF %UPCASE(&COMPARE_BY_TIME) EQ YES %THEN
    %DO;
        %LET US_TIME_PERIOD = QTR;

        %IF &SALESDB = HMSALES %THEN
        %DO;
            %LET HM_TIME_PERIOD = QTR;
        %END;
        %ELSE
        %IF &SALESDB = USSALES %THEN
        %DO;
            %LET HM_TIME_PERIOD = HM_TIME_PERIOD;
       %END;

        FIRSTMONTH =(MONTH("&BEGINPERIOD"D));
        MTH = (MONTH(&SLDT) + (YEAR(&SLDT) - YEAR("&BEGINPERIOD"D)) * 12);
        NQTR = (1 + (FLOOR((MTH - FIRSTMONTH) / 3))) ;
        QTR = STRIP(PUT(NQTR, 2.));
        DROP FIRSTMONTH MTH NQTR;
    %END;
%MEND CREATE_QUARTERS;

/* Repo's real call-site setup (see me-margin-calculation.sas, Part 1-D
   "PERIOD OF INVESTIGATION/REVIEW INFORMATION" and Part 6): COMPARE_BY_TIME
   turns on time-based comparisons, BEGINPERIOD anchors quarter 1, SALESDB
   names which sales dataset is currently being processed. */
%LET COMPARE_BY_TIME = YES;
%LET BEGINPERIOD = 01JAN2024;
%LET SALESDB = USSALES;

/* Stand-in for COMPANY.&USDATA: five U.S. sales spread across a
   twelve-month period of review, the shape the antidumping programs
   quarter-bucket for time-based comparisons. */
DATA USSALES;
    LENGTH US_IMPORTER $20;
    INFORMAT SALEDATE DATE9.;
    FORMAT SALEDATE DATE9.;
    INPUT US_IMPORTER $20. SALEDATE;

    /* Real call convention from the repo (see me-margin-calculation.sas,
       Part 6): %CREATE_QUARTERS (SLDT = &USSALEDATE, PROGRAM = MEMARG); */
    %CREATE_QUARTERS (SLDT = SALEDATE, PROGRAM = MEMARG);

    DATALINES;
ACME TRADING         15JAN2024
DELTA IMPORTS        20APR2024
GLOBAL METALS INC    03JUL2024
HARBOR STEEL CO      28SEP2024
PACIFIC RIM TRADERS  19DEC2024
;
RUN;

PROC PRINT DATA = USSALES NOOBS;
    VAR US_IMPORTER SALEDATE QTR;
    TITLE "U.S. SALES ASSIGNED TO PERIOD-OF-REVIEW QUARTERS";
RUN;
