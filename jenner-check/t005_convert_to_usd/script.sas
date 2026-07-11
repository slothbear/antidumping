/* jenner-check bundle: CONVERT_TO_USD from nme-margin-calculation.sas
   (slothbear/antidumping)
   Source: nme-margin-calculation.sas, macro CONVERT_TO_USD -- converts
   sale adjustments reported in a foreign currency (freight, brokerage,
   etc.) into U.S. dollars using each sale's own daily exchange rate, then
   drops the original foreign-currency columns. The macro builds its
   "_USD" variable list dynamically with %SCAN/%DO %UNTIL over whatever
   variable list is passed in -- reproduced verbatim below; only the call
   site and its mock USSALES dataset are new. */

%MACRO CONVERT_TO_USD (USE_EXRATES = , EXDATA = , VARS_TO_USD =);
    %IF %UPCASE(&USE_EXRATES) = YES %THEN
    %DO;
        DATA USSALES;
            SET USSALES;
            /*---------------------------------------------*/
            /* THE FOLLOWING ARRAY USES THE MACRO VARIABLE */
            /* VAR_TO_USD TO CONVERT ADJUSTMENTS EXPRESSED */
            /* IN FOREIGN CURRENCY TO U.S. DOLLARS.        */
            /*---------------------------------------------*/

            ARRAY CONVERT (*) &VARS_TO_USD;

            %LET I = 1;

            /*------------------------------------------------*/
            /* CREATE A LIST OF REVISED VARIABLES NAMES WITH  */
            /* THE SUFFIX _USD. LOOP THROUGH THE VARIABLES IN */
            /* THE ORIGINAL LIST AND ADD THE REVISED VARIABLE */
            /* NAMES TO THE MACRO VARIABLE VARS_IN_USD.       */
            /*------------------------------------------------*/

            %LET VARS_IN_USD = ;
            %DO %UNTIL (%SCAN(&VARS_TO_USD, &I, %STR( )) = %STR());
                %LET VARS_IN_USD = &VARS_IN_USD
                     %SYSFUNC(COMPRESS(%SCAN(&VARS_TO_USD, &I, %STR( )) _USD));
                %LET I = %EVAL(&I + 1);
            %END;
            %LET VARS_IN_USD = %CMPRES(&VARS_IN_USD);

            ARRAY CONVERTED (*) &VARS_IN_USD;

            /*-----------------------------------------------------*/
            /* CONVERT THE ORIGINAL VARIABLES IN THE ARRAY CONVERT */
            /* TO U.S DOLLARS USING THE DAILY EXCHANGE RATE AND    */
            /* ASSIGN THE NEW VALUES TO NEW VARIABLES WITH THE     */
            /* ORIGINAL NAME AND THE SUFFIX _USD THAT ARE IN THE   */
            /* ARRAY CONVERTED.                                    */
            /*                                                     */
            /* FOR EXAMPLE, IF THE VARIABLE COAL_SV IS DENOMINATED */
            /* IN A FOREIGN CURRENCY, THE VARIABLE COAL_SV_USD IS  */
            /* CREATED AND DENOMINATED IN U.S. DOLLARS.            */
            /*-----------------------------------------------------*/

            DO I = 1 TO DIM(CONVERT);
                CONVERTED(I) = CONVERT(I) * EXRATE_&EXDATA;
            END;
        RUN;

        PROC PRINT DATA = USSALES (OBS = &PRINTOBS);
            VAR EXRATE_&EXDATA &VARS_TO_USD &VARS_IN_USD;
            TITLE3 "VARIABLES CONVERTED TO U.S. DOLLARS";
        RUN;

        /*--------------------------------------------*/
        /* DROP THE ORIGINAL NON-CONVERTED VARIABLES. */
        /*--------------------------------------------*/

        DATA USSALES;
            SET USSALES (DROP = &VARS_TO_USD);
        RUN;
    %END;
%MEND CONVERT_TO_USD;

/* Repo's real call-site setup (see nme-margin-calculation.sas, Part 6):
   USE_EXRATES1 turns the conversion on, EXDATA1 names the exchange-rate
   source (its column becomes EXRATE_<EXDATA1>), VARS_TO_USD1 lists the
   foreign-currency adjustment columns to convert. PRINTOBS caps how many
   rows the PROC PRINT preview shows, same as elsewhere in the repo. */
%LET USE_EXRATES1 = YES;
%LET EXDATA1 = DAILY;
%LET VARS_TO_USD1 = FREIGHT BROKERAGE;
%LET PRINTOBS = 20;

/* Stand-in for USSALES after PART 2/PART 6 of the real program: each row
   already carries its own daily exchange rate (EXRATE_DAILY) merged in
   from the exchange-rate dataset, plus freight and brokerage reported by
   the foreign respondent in local currency. */
DATA USSALES;
    LENGTH US_IMPORTER $20;
    INPUT US_IMPORTER $20. EXRATE_DAILY FREIGHT BROKERAGE;
    DATALINES;
ACME TRADING         0.1350 850.00 120.00
DELTA IMPORTS        0.1362 620.00  95.50
GLOBAL METALS INC    0.1341 990.00 140.25
HARBOR STEEL CO      0.1358 410.00  60.00
PACIFIC RIM TRADERS  0.1347 705.00 110.75
;
RUN;

%CONVERT_TO_USD (USE_EXRATES = &USE_EXRATES1, EXDATA = &EXDATA1, VARS_TO_USD = &VARS_TO_USD1)

PROC PRINT DATA = USSALES NOOBS;
    VAR US_IMPORTER EXRATE_DAILY FREIGHT_USD BROKERAGE_USD;
    TITLE "FREIGHT AND BROKERAGE CONVERTED TO U.S. DOLLARS";
RUN;
