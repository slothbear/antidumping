/********************************************************************/
/*                    ANTIDUMPING MARKET ECONOMY                    */
/*                          MACROS PROGRAM                          */
/*                                                                  */
/*           GENERIC VERSION LAST UPDATED MARCH 21, 2022            */
/*                                                                  */
/********************************************************************/
/*                          GENERAL MACROS                          */
/*------------------------------------------------------------------*/
/*     G1_RUNTIME_SETUP                                             */
/*     G2_TITLE_SETUP                                               */
/*     G3_COST_TIME_MVARS                                           */
/*     G4_LOT                                                       */
/*     G5_DATE_CONVERT                                              */
/*     G6_CHECK_SALES                                               */
/*     G7_EXRATES                                                   */
/*     G8_FIND_NOPRODUCTION                                         */
/*     G9_COST_PRODCHARS                                            */
/*     G10_TIME_PROD_LIST IN QUARTERLY COST SITUATIONS              */
/*     G11_CREATE_TIME_COST_DB IN QUARTERLY COST SITUATIONS         */
/*     G12_ZERO_PROD_IN_PERIODS IN QUARTERLY COST SITUATIONS        */
/*     G13_CREATE_COST_PROD_TIMES IN QUARTERLY COST SITUATIONS      */
/*     G14_HIGH_INFLATION                                           */
/*     G15_CHOOSE_COSTS                                             */
/*     G16_MATCH_NOPRODUCTION IN NON-HIGH INFLATION SITUATIONS OR   */
/*         NON-QUARTERLY COST SITUATIONS                            */
/*     G17_FINALIZE_COSTDATA                                        */
/*     G18_DEL_ALL_WORK_FILES                                       */
/*     G19_PROGRAM_RUNTIME                                          */
/*------------------------------------------------------------------*/
/*                     COMPARISON MARKET MACROS                     */
/*------------------------------------------------------------------*/
/*     HM1_PRIME_MANUF_MACROS                                       */
/*     HM2_MIXEDCURR                                                */
/*     HM3_ARMSLENGTH                                               */
/*     HM4_CEPTOT                                                   */
/*     HM5_COSTTEST                                                 */
/*     HM6_DATA_4_WTAVG                                             */
/*     HM7_WTAVG_DATA                                               */
/*     HM8_CVSELL                                                   */
/*     HM9_LOTADJ                                                   */
/*------------------------------------------------------------------*/
/*                      MARGIN PROGRAM MACROS                       */
/*------------------------------------------------------------------*/
/*     US1_MACROS                                                   */
/*     US2_SALETYPE                                                 */
/*     US3_USD_CONVERSION                                           */
/*     US4_INDCOMM                                                  */
/*     US5_CEPRATE                                                  */
/*     US6_ENTVALUE                                                 */
/*     US7_CONCORDANCE                                              */
/*     US8_LOTADJ                                                   */
/*     US9_OFFSETS                                                  */
/*     US10_LOT_ADJUST_OFFSETS                                      */
/*     US11_CVSELL_OFFSETS                                          */
/*     US12_COMBINE_P2P_CV                                          */
/*     US13_COHENS_D_TEST                                           */
/*     US14_WT_AVG_DATA                                             */
/*     US15_RESULTS                                                 */
/*     US16_CALC_CASH_DEPOSIT                                       */
/*     US17_MEANINGFUL_DIFF_TEST                                    */
/*     US18_ASSESSMENT                                              */
/*     US19_FINAL_CASH_DEPOSIT                                      */
/********************************************************************/

/********************************************************/
/* G-1: SET UP MACRO VARIABLES FOR RUN TIME CALCULATION */
/********************************************************/

%MACRO G1_RUNTIME_SETUP;

DATA _NULL_;
    CALL SYMPUT ('BTIME',PUT(TIME(),TIME5.));
    CALL SYMPUT ('BDATE',PUT(DATE(),DATE.));
    CALL SYMPUT ('BWDATE',TRIM(LEFT(PUT(DATE(),WORDDATE18.))));
    CALL SYMPUT ('BDAY',TRIM(LEFT(PUT(DATE(),DOWNAME.))));
RUN;

%PUT NOTE: This program started running on &BDAY, &BWDATE - &BTIME;

%MEND G1_RUNTIME_SETUP;

%GLOBAL INDEX_SOURCE TIME_OUTSIDE_POR TIME_ANNUALIZED;
%LET INDEX_SOURCE = NA;
%LET TIME_OUTSIDE_POR = NA;
%LET TIME_ANNUALIZED = NA;

/***********************************************************/
/* G-2: CREATE FIXED TITLES AND FOOTNOTES ON LINES 1 AND 2 */
/* FOR EACH PRINT AND PROGRAM-SPECIFIC MACROS FOR TITLES 3 */
/* AND HIGHER                                              */
/***********************************************************/

%MACRO G2_TITLE_SETUP;
    %GLOBAL PROGRAM SALES_DB CALC_TYPE;

    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %LET PROGRAM = HOME MARKET;
        %LET SALES_DB = HOME MARKET;
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = USSALES %THEN   
    %DO;
        %LET PROGRAM = U.S. SALES MARGIN;
        %LET SALES_DB = U.S.;
    %END;

    %IF %UPCASE(&CASE_TYPE) = AR %THEN 
    %DO;
        %LET CALC_TYPE = RESULTS;
    %END;
    %ELSE
    %IF %UPCASE(&CASE_TYPE) = INV %THEN 
    %DO;
        %LET CALC_TYPE = DETERMINATION;
    %END;
    %ELSE 
    %DO;
        %LET CALC_TYPE = ;
    %END;

    TITLE1 "&PROGRAM PROGRAM - &PRODUCT FROM &COUNTRY (&BEGINPERIOD - &ENDPERIOD)";
    TITLE2 "&SEGMENT &STAGE FOR RESPONDENT &RESPONDENT (&CASE_NUMBER)";

    FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
    FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";
%MEND G2_TITLE_SETUP;

/*****************************************/
/* G3: CREATE MACROS FOR QUARTERLY COSTS */
/*****************************************/

%MACRO G3_COST_TIME_MVARS;
    %GLOBAL HM_TIME_PERIOD NAF_TIME_PERIOD COST_TIME_PERIOD US_TIME_PERIOD
            US_TIME AND_TIME EQUAL_TIME OR_TIME FIRST_TIME COP_TIME_OUT
            COST_PERIODS TIME_ANNUAL ANNUAL_COST COST_DUTY_DRAWBACK_VARIABLE;

    /*--------------------------------------------*/
    /* Define format for different kinds of Cost. */
    /*--------------------------------------------*/

    PROC FORMAT;
        VALUE $TIMETYPE
            'AN' = 'Reported Annualized'
            'SG' = 'Surrogate Annualized'

            'TS' = 'Reported Quarterly'
            'BL' = 'Blended Surrogate Quarterly'
            'GF' = 'Gap Fill Surrogate Quarterly'

            'H1' = 'Reported High Inflation'
            'H2' = 'Annualized High Inflation'
            'H3' = 'Surrogate High Inflation'

            'CA' = 'Calculated'
            'NA' = 'N/A';
    RUN;

    /*--------------------------------------------------------*/
    /* Define macro variable used to keep Cost duty drawback. */
    /*--------------------------------------------------------*/

    %LET COST_DUTY_DRAWBACK_VARIABLE = ;    /* Cost duty drawback variable */
    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %IF &USE_COST_DUTY_DRAWBACK = YES %THEN
        %DO;
            %LET COST_DUTY_DRAWBACK_VARIABLE = &COST_DUTY_DRAWBACK;
        %END;
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = USSALES AND %UPCASE(&COST_TYPE) = CV %THEN   
    %DO;
        %IF &USE_COST_DUTY_DRAWBACK = YES %THEN
        %DO;
            %LET COST_DUTY_DRAWBACK_VARIABLE = &COST_DUTY_DRAWBACK;
        %END;
    %END;

    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %LET AND_TIME = AND;
        %LET EQUAL_TIME = =;
        %LET OR_TIME = OR;
        %LET FIRST_TIME = FIRST.&US_TIME_PERIOD;
        %LET US_TIME = US_TIME_PERIOD;   /* For Level of Trade calculation */
                                         /* in CM program. */

        %LET COST_PERIODS = COST PERIODS;
        %LET HM_TIME_PERIOD = HM_TIME_PERIOD;

        %IF %UPCASE(&TIME_ANNUALIZED) = NA %THEN
        %DO;
            %LET TIME_ANNUAL = ;
            %LET ANNUAL_COST = ;
        %END;

        %IF %UPCASE(&TIME_ANNUALIZED) NE NA %THEN
        %DO;
            %LET TIME_ANNUAL = ,&TIME_ANNUALIZED;
            %LET ANNUAL_COST = ANNUALCOST;
        %END;

        %IF %UPCASE(&SALESDB) = HMSALES %THEN
        %DO;
            %LET NAF_TIME_PERIOD = NAF_TIME_PERIOD;
            %LET COP_TIME_OUT = COST_TIME_PERIOD;
        %END;

        %IF %UPCASE(&SALESDB) = USSALES %THEN
        %DO;
             %LET HM_TIME_PERIOD = HM_TIME_PERIOD;
        %END;
    %END;

    %IF %UPCASE(&COMPARE_BY_TIME) = NO %THEN
    %DO; 
        %LET HM_TIME_PERIOD = ;
        %LET COST_TIME_PERIOD = ;
        %LET NAF_TIME_PERIOD = ;
        %LET US_TIME_PERIOD = ;
        %LET US_TIME = ;
        %LET AND_TIME = ;   
        %LET EQUAL_TIME = ;
        %LET COP_TIME_OUT = ;
        %LET COST_PERIODS = ;
        %LET TIME_ANNUAL = ;
        %LET ANNUAL_COST = ;
    %END;
%MEND G3_COST_TIME_MVARS;

/*******************************************************************/
/* G4: CREATE LEVEL OF TRADE VARIABLE FOR PROGRAMMING USE BASED ON */
/*     INFORMATION IN MACRO VARIABLE 'LET HMLOT = <???>'           */
/*******************************************************************/

%MACRO G4_LOT(LOT_REP, LOT_PROG);
    %IF %UPCASE(&LOT_REP) NE NA %THEN 
    %DO;
        &LOT_PROG = &LOT_REP;
    %END;
    %ELSE
    %IF %UPCASE(&LOT_REP) EQ NA %THEN 
    %DO;
        &LOT_PROG = 0;
    %END;
%MEND G4_LOT;

/*******************************************************************/
/* G-5: TEST SALE DATE VARIABLE FORMAT                             */
/*                                                                 */
/* If your date variable is not in SAS date format, the language   */
/* below will attempt to convert it.  If the conversion is not     */
/* successful, please contact a SAS support person for assistance. */
/*******************************************************************/

%MACRO DATE_CONVERT(DATE, TYPE);
    %GLOBAL SALEDATE_FORMAT DATE_FORMAT&TYPE;
    DATA _NULL_;
        SET &SALESDB;
        IF _N_=1 THEN 
        DO;
            LENGTH SALEDATEFORM $4;            
            SALEDATEFORM = VFORMATN(&DATE);
            IF SUBSTR(SALEDATEFORM,1,1) = '$' THEN 
                SALEDATE_FORMAT_TYPE = 'CHARACTER';
            ELSE
            IF SALEDATEFORM IN( 'DATE','WEEK','YYMM', 'MMDD','WORD') THEN
                SALEDATE_FORMAT_TYPE = 'DATE';
            ELSE
                SALEDATE_FORMAT_TYPE = 'NUMERIC';

            CALL SYMPUT ('SALEDATE_FORMAT',SALEDATE_FORMAT_TYPE);
        END;
    RUN;
    
    %IF &SALEDATE_FORMAT = DATE %THEN
    %DO;
        %LET DATE_FORMAT&TYPE = YES;
    %END;

    /*********************************************/
    /* Attempt to convert the sale date variable */
    /* to date format, when necessary.           */
    /*********************************************/

    %IF &SALEDATE_FORMAT NE DATE %THEN
    %DO;
        DATA &SALESDB;
            SET &SALESDB (RENAME = (&DATE = DATE_TEMP));
            FORMAT &DATE DATE9.;
            &DATE = INPUT(DATE_TEMP, ANYDTDTE21.);
        RUN;

        /************************************************/
        /* Retest the format of converted date variable */
        /* to see if conversion was successful.         */
        /************************************************/
    
        DATA _NULL_;
            LENGTH CONVERTDATEFORM $4;            
            SET &SALESDB;
            IF _N_ = 1;
            CONVERTDATEFORM = VFORMATN(&DATE);
            IF CONVERTDATEFORM IN('DATE','WEEK','YYMM', 'MMDD','WORD') THEN
                CONVERTDATE = 'YES';
            ELSE
                CONVERTDATE = 'NO';
            CALL SYMPUT('CONVERT_SUCCESS', CONVERTDATE);
         RUN;

         %IF &CONVERT_SUCCESS = YES %THEN
         %DO;
             %LET DATE_FORMAT&TYPE = YES;

             PROC PRINT DATA = &SALESDB (OBS = &PRINTOBS) SPLIT="*";
                 VAR DATE_TEMP &DATE;
                 LABEL DATE_TEMP = "ORIGINAL*DATE*VARIABLE*==========="
                       &DATE = "CONVERTED*DATE*VARIABLE*===========";
                 TITLE3 "CHECK OF SALE DATE VARIABLE CONVERSION, FIRST &PRINTOBS OBSERVATIONS";
                 TITLE5 "If converted data is missing or not correct, further action will be required.";
                 TITLE6 "If original data is missing and the converted date is 01JAN1960, then variable &date is uninitialized.";
             RUN;
         %END;
         %ELSE
         %IF &CONVERT_SUCCESS = NO %THEN
         %DO;
             %LET DATE_FORMAT&TYPE = NO;

             PROC PRINT DATA = &SALEDB (OBS = &PRINTOBS) SPLIT="*";
                 VAR DATE_TEMP &DATE;
                 LABEL DATE_TEMP = "ORIGINAL*DATE*VARIABLE*==========="
                       &DATE = "CONVERTED*DATE*VARIABLE*===========";
                 TITLE3 "THE AUTOMATIC ATTEMPT TO CONVERT &DATE, A &SALEDATE_FORMAT VARIABLE, WAS NOT SUCCESSFUL.";
                 TITLE5 "Note:  Before exchange rates can be merged or month designations assigned in administrative,";
                 TITLE6 "reviews, the variable will have to be converted to SAS date format by an alternative method.";
             RUN;
        %END;    
    %END;
%MEND DATE_CONVERT;

%MACRO G5_DATE_CONVERT;
    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %DATE_CONVERT(&HMSALEDATE, )
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN
    %DO;
        %DATE_CONVERT(&HMSALEDATE, )
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = USSALES %THEN
    %DO;
        %DATE_CONVERT(&USSALEDATE, )
        %IF %UPCASE(&FILTER_EP) = YES %THEN
        %DO;
            %DATE_CONVERT(&EP_DATE_VAR,_EP)
        %END;
        %IF %UPCASE(&FILTER_CEP) = YES %THEN
        %DO;
            %DATE_CONVERT(&CEP_DATE_VAR,_CEP)
        %END;
    %END;
%MEND G5_DATE_CONVERT;

/*****************************************************************************/
/* G-6: CHECK SALES FOR NEGATIVE PRICES AND QUANTITIES, DATES OUTSIDE PERIOD */
/*****************************************************************************/

%MACRO G6_CHECK_SALES;
    %GLOBAL MONTH;
    %LET MONTH = ;    /* Null value for macro variables &HMMONTH or &USMONTH for investigations. */

    %MACRO CHECK_SALES(SALES_MONTH, QTY,GUP, DATE, SALES, DBTYPE, DB, BEGINDAY, ENDDAY);
        DATA &SALES NEGDATA_&DB OUTDATES_&DB;
            SET &SALES;

            IF &QTY LE 0 OR &GUP LE 0 THEN
                OUTPUT NEGDATA_&DB;
            ELSE
            IF "&BEGINDAY."D GT &DATE OR &DATE GT "&ENDDAY."D THEN
                OUTPUT OUTDATES_&DB;
            %MARGIN_FILTER
            ELSE
            DO;
                /*--------------------------------------------------------------------*/
                /* In administrative reviews, define HMMONTH and USMONTH variables so */
                /* that each month has a unique value.                                */
                /*--------------------------------------------------------------------*/

                %IF %UPCASE(&CASE_TYPE) = AR %THEN
                %DO;
                    %IF &DBTYPE = US %THEN
                    %DO;
                        %LET BEGIN = &HMBEGINWINDOW;
                    %END;
                    %ELSE
                    %DO;
                        %LET BEGIN = &HMBEGINDAY;
                    %END;
                    MON = MONTH(&DATE);
                    YRDIFF = YEAR(&DATE) - YEAR("&BEGIN."D);
                    &SALES_MONTH = MON + YRDIFF * 12;
                    DROP MON YRDIFF;
                    %LET MONTH = &SALES_MONTH;
                %END;

                OUTPUT &SALES;
            END;
        RUN;

        PROC PRINT DATA = NEGDATA_&DB (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF &DBTYPE SALES WITH GROSS PRICE (&GUP) OR QUANTITY (&QTY) LESS THAN OR EQUAL TO ZERO";
            TITLE5 "NOTE:  Default programming removes these sales from the calculations.";
            TITLE6 "Should this not be appropriate, adjust accordingly.";
        RUN;

        PROC PRINT DATA = OUTDATES_&DB (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF &DBTYPE SALES OUTSIDE THE PERIOD OF ANALYSIS";
            TITLE4 "BASED ON THE VALUE OF &DATE BEING OUTSIDE THE DATE RANGE &BEGINDAY AND &ENDDAY";
            TITLE6 "NOTE:  Default programming removes these sales from the calculations.";
            TITLE7 "Should this not be appropriate, adjust accordingly.";
        RUN;
    %MEND CHECK_SALES;

    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %MACRO MARGIN_FILTER;
        %MEND MARGIN_FILTER;

        %CHECK_SALES(HMMONTH, &HMQTY, &HMGUP, &HMSALEDATE, HMSALES, HOME MARKET, HM, &HMBEGINDAY, &HMENDDAY);
    %END;    
    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN
    %DO;
        %MACRO MARGIN_FILTER;
        %MEND MARGIN_FILTER;

        %CHECK_SALES(HMMONTH, &HMQTY, &HMGUP, &HMSALEDATE, DOWNSTREAM, DOWNSTREAM, DS, &HMBEGINDAY, &HMENDDAY);
    %END;
    %IF %UPCASE(&SALESDB) = USSALES %THEN
    %DO;
        %MACRO MARGIN_FILTER;
            %IF %UPCASE(&FILTER_CEP) = YES %THEN
            %DO;
                %IF &DATE_FORMAT_CEP = YES %THEN
                %DO;
                    ELSE IF SALE_TYPE = "CEP" 
                    AND ("&BEGINDAY_CEP."D GT &CEP_DATE_VAR OR &CEP_DATE_VAR GT "&ENDDAY_CEP."D) 
                    THEN OUTPUT OUTDATES_&DB;
                %END;
            %END; 
            %IF %UPCASE(&FILTER_EP) = YES %THEN
            %DO; 
                %IF &DATE_FORMAT_EP = YES %THEN
                %DO;
                    ELSE IF SALE_TYPE = "EP" 
                    AND ("&BEGINDAY_EP."D GT &EP_DATE_VAR OR &EP_DATE_VAR GT "&ENDDAY_EP."D) 
                    THEN OUTPUT OUTDATES_&DB;
                %END; 
            %END;
        %MEND MARGIN_FILTER;

        %CHECK_SALES(USMONTH, &USQTY, &USGUP, &USSALEDATE, USSALES, US, US, &USBEGINDAY, &USENDDAY);
    %END;
%MEND G6_CHECK_SALES;

/*************************************************/
/* G-7: MERGE EXCHANGE RATES INTO SALES DATABASE */
/*************************************************/

%MACRO G7_EXRATES;
    %GLOBAL EXRATE1 XRATE1 EXRATE2 XRATE2;

    %MACRO MERGE_RATES(USE_EXRATES, EXDATA, EXRATE, XRATE,DATE); 
        /*----------------------------------------------*/
        /* Set values for exchange rate macro variables */
        /* when exchange rate is not required.          */
        /*----------------------------------------------*/

        %IF %UPCASE(&USE_EXRATES) = NO %THEN
        %DO;
            %LET &EXRATE = ; 
            %LET &XRATE = 1; 
        %END;

        /*--------------------------------------*/
        /* Merge Exchange Rates, when required. */
        /*--------------------------------------*/

        %IF %UPCASE(&USE_EXRATES) = YES %THEN
        %DO;
            %LET &EXRATE = EXRATE_&EXDATA;
            %LET &XRATE = EXRATE_&EXDATA;

            /*----------------------------------------------------*/
            /* First establish whether date variable is in proper */
            /* format before attempting to merge exchange rates.  */
            /*----------------------------------------------------*/
    
            %IF &DATE_FORMAT = YES %THEN
            %DO;
                /*---------------------------------------------------*/
                /* If date variable is in proper format, merge in    */
                /* format before attempting to merge exchange rates. */
                /*---------------------------------------------------*/

                PROC SORT DATA = COMPANY.&EXDATA (RENAME = (DATE = &DATE
                                %IF %UPCASE(&CASE_TYPE) = INV %THEN
                                %DO;
                                     &EXDATA.I = EXRATE_&EXDATA)
                                    DROP = &EXDATA.R)
                                %END;     
                                %ELSE
                                %IF %UPCASE(&CASE_TYPE) = AR %THEN
                                %DO;
                                    &EXDATA.R = EXRATE_&EXDATA)
                                    DROP = &EXDATA.I)
                                %END;
                          OUT = EXRATES;
                    BY &DATE;
                RUN;

                PROC SORT DATA = &SALESDB OUT = &SALESDB;
                    BY &DATE;
                RUN;

                DATA &SALESDB NORATES;
                    MERGE &SALESDB (IN = A) EXRATES (IN = B);
                    BY &DATE;
                    IF A & B THEN
                        OUTPUT &SALESDB;
                    ELSE IF A & NOT B THEN
                        OUTPUT NORATES;
                RUN;

                PROC PRINT DATA = NORATES;
                    VAR &DATE;
                    TITLE3 "&SALESDB WITH NO EXCHANGE RATES FOR &EXDATA";
                RUN;
            %END;
        %END;
    %MEND MERGE_RATES;

    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %MERGE_RATES(&USE_EXRATES1, &EXDATA1, EXRATE1, XRATE1, &HMSALEDATE);
        %MERGE_RATES(&USE_EXRATES2, &EXDATA2, EXRATE2, XRATE2, &HMSALEDATE);
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = USSALES %THEN
    %DO;
        %MERGE_RATES(&USE_EXRATES1, &EXDATA1, EXRATE1, XRATE1, &USSALEDATE);
        %MERGE_RATES(&USE_EXRATES2, &EXDATA2, EXRATE2, XRATE2, &USSALEDATE);
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN
    %DO;
        %MERGE_RATES(&USE_EXRATES1, &EXDATA1, EXRATE1, XRATE1, &HMSALEDATE);
        %MERGE_RATES(&USE_EXRATES2, &EXDATA2, EXRATE2, XRATE2, &HMSALEDATE);
    %END;
%MEND G7_EXRATES;

/**********************************************************/
/* G-8 IDENTIFY PRODUCTS REQUIRING SURROGATE COSTS        */
/*                                                        */
/* CONNUMUs in the CM and U.S. datasets that have sales   */
/* but no production in the POI/POR must be in the COP    */
/* dataset with a production quantity of 0 (zero). If     */
/* respondent does not report these CONNUMs in the cost   */
/* dataset, the analyst must add these CONNUMs to the COP */
/* dataset with a production quantity of 0 (zero).        */
/**********************************************************/

%MACRO G8_FIND_NOPRODUCTION;
    /********************************************************************************/
    /* G-8-A: Annualized Cost, High Inflation, OR Quarterly Cost without production */
    /********************************************************************************/

    %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ NO %THEN
    %DO;
        /*************************************************************************/
        /* G-8-A-i: Define macro variables and macros used in finding annualized */
        /*          Cost or quarterly Cost without production.                   */
        /*************************************************************************/

        %GLOBAL EQUAL_COST_PRIME NO_PROD_COST_PRIME TIME_ANNUALIZED;

        %LET TIME_ANNUALIZED = NA;

        /*-----------------------------------------------------------------------------------*/
        /* Create null values for macro variables when Cost prime/non-prime is not relevant. */
        /*-----------------------------------------------------------------------------------*/

        %IF %UPCASE(&COST_PRIME) EQ NA %THEN
        %DO;
            %LET EQUAL_COST_PRIME = ;   /* EQUAL operator for cost prime purposes */
            %LET NO_PROD_COST_PRIME = ; /* no production cost prime               */
        %END;
        %ELSE

        /*---------------------------------------------------------------*/
        /* Create macro variables when Cost prime/non-prime is relevant. */
        /*---------------------------------------------------------------*/

        %IF %UPCASE(&COST_PRIME) NE NA %THEN
        %DO;
            %LET EQUAL_COST_PRIME = =;
            %LET NO_PROD_COST_PRIME = NO_PROD_&COST_PRIM;
        %END;

        PROC SORT DATA = COST OUT = COST;
            BY &COST_MANF &COST_PRIM &COST_MATCH &COST_TIME_PERIOD;
        RUN;

        %IF %UPCASE(&COST_PROD_CHARS) = YES %THEN 
        %DO;
            %LET PROD_CHARS = &COST_CHAR;
        %END;
        %ELSE
        %IF %UPCASE(&COST_PROD_CHARS) = NO %THEN
        %DO;
            %LET PROD_CHARS = ;
        %END;

        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            %MACRO WHERE_STMT;
            %MEND WHERE_STMT;

            %IF %UPCASE(&TIME_ANNUALIZED) EQ NA %THEN
            %DO;
                %MACRO NOPROD_TIME_TYPE;
                    NOPROD_TIME_TYPE = "TS";
                %MEND NOPROD_TIME_TYPE;
            %END;
            %ELSE 
            %IF %UPCASE(&TIME_ANNUALIZED) NE NA %THEN
            %DO;
                %MACRO NOPROD_TIME_TYPE;
                    NOPROD_TIME_TYPE = "TS";
                    IF &COST_TIME_PERIOD IN(&TIME_ANNUALIZED) THEN
                        NOPROD_TIME_TYPE = "AN";
                %MEND NOPROD_TIME_TYPE;
            %END;

            %MACRO RENAME_TIME_TYPE;
                &COST_TIME_PERIOD = NO_PRODUCTION_QUARTER
            %MEND RENAME_TIME_TYPE;
        %END;
        %ELSE
        %IF %UPCASE(&COMPARE_BY_TIME) = NO %THEN
        %DO;
            %MACRO WHERE_STMT;
            %MEND WHERE_STMT; 

            %MACRO NOPROD_TIME_TYPE;
                NOPROD_TIME_TYPE = "NA";
            %MEND NOPROD_TIME_TYPE;

            %MACRO RENAME_TIME_TYPE;
            %MEND RENAME_TIME_TYPE;
        %END;

        /************************************************************/
        /* G-8-A-ii: Find total production quantity for each model. */
        /************************************************************/

        PROC MEANS NWAY DATA = COST NOPRINT;
            CLASS &COST_MANF &COST_PRIM &COST_MATCH &COST_TIME_PERIOD;     
            %WHERE_STMT 
            VAR &COST_QTY;
            OUTPUT OUT = TOTPRODQTY (DROP = _:) 
                   SUM = TOT_CONNUM_PROD_QTY;
        RUN;

        /****************************************************/
        /* G-8-A-iii: Separate out Cost without production. */
        /****************************************************/

        DATA COST (DROP = TOT_CONNUM_PROD_QTY 
                   RENAME = (NOPROD_TIME_TYPE = COST_TIME_TYPE)) 
             NOPRODUCTION (KEEP = &COST_MANF &COST_PRIM &COST_MATCH
                                  &PROD_CHARS NOPROD_TIME_TYPE &COST_TIME_PERIOD
                           RENAME = (&COST_MANF &EQUAL_COST_MANF &NO_PROD_COST_MANF
                                     &COST_PRIM &EQUAL_COST_PRIME &NO_PROD_COST_PRIME
                                     &COST_MATCH = NO_PRODUCTION_CONNUM
                                     %RENAME_TIME_TYPE));                 
             MERGE COST (IN = A) TOTPRODQTY (IN = B);
             BY &COST_MANF &COST_PRIM &COST_MATCH &COST_TIME_PERIOD;
             IF A;

             %NOPROD_TIME_TYPE
             IF TOT_CONNUM_PROD_QTY LE 0 THEN
                 OUTPUT NOPRODUCTION;
             ELSE
                 OUTPUT COST;
        RUN;

        PROC CONTENTS DATA = NOPRODUCTION 
                      OUT = NOPROD (KEEP = NOBS) NOPRINT;
        RUN;

        DATA _NULL_;
            SET NOPROD;
            IF _N_ = 1;
            IF NOBS GT 0 THEN
                MATCH_NOPRODS = "YES";
            ELSE
            IF NOBS = 0 THEN
                MATCH_NOPRODS = "NO";
    
            CALL SYMPUT('FIND_SURROGATES', MATCH_NOPRODS);
        RUN;
    %END;
    %ELSE

    /*************************************************/
    /* G-8-B: High inflation Cost Without Production */
    /*************************************************/

    %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
    %DO;
        /****************************************************/
        /* G-8-B-i: Define macro variables used in finding  */
        /*          high inflation Cost without production. */
        /****************************************************/

        %GLOBAL COST_MFR_HP COST_MFR_HP_RENAME /* 8 macro variables */
                COST_MFR_HP_RENAME_BACK COST_MFR_HP_SAME COST_PRIME_HP   
                COST_PRIME_HP_RENAME COST_PRIME_HP_RENAME_BACK COST_PRIME_HP_SAME;

        /*------------------------------------------------------------*/
        /* Create null macro variable values when CM sales            */
        /* manufacturer or Cost manufacturer is not relevant.         */
        /*------------------------------------------------------------*/

        %LET COST_MFR_HP = ;             /* Cost manufacturer variable                            */
        %LET COST_MFR_HP_RENAME = ;      /* Rename cost mfr variable to no-prod cost mfr variable */
        %LET COST_MFR_HP_RENAME_BACK = ; /* Rename no-prod cost mfr variable to cost mfr variable */
        %LET COST_MFR_HP_SAME = ;        /* If no-prod cost mfr variable equal cost mfr variable  */

        /*---------------------------------------------------------*/
        /* Assign macro variable values when CM sales manufacturer */
        /* and Cost manufacturer are relevant.                     */
        /*---------------------------------------------------------*/

        %IF %UPCASE(&HMMANUF) NE NA AND %UPCASE(&COST_MANUF) NE NA %THEN /* When there is reported CM and Cost mfr */
        %DO; 
            %LET COST_MFR_HP = &COST_MANUF;
            %LET COST_MFR_HP_RENAME = &COST_MANUF = NO_PROD_MFR;
            %LET COST_MFR_HP_RENAME_BACK = NO_PROD_MFR = &COST_MANUF;
            %LET COST_MFR_HP_SAME = &COST_MANUF = NO_PROD_MFR;
        %END;

        /*-----------------------------------------------------------------*/
        /* Assign null macro variable values when CM sales Prime/Non-prime */
        /* or Cost Prime/Non-prime are not relevant.                       */
        /*-----------------------------------------------------------------*/
 
        %LET COST_PRIME_HP = ;             /* Cost prime variable                                       */
        %LET COST_PRIME_HP_RENAME = ;      /* Rename Cost prime variable to no-prod cost prime variable */
        %LET COST_PRIME_HP_RENAME_BACK = ; /* Rename no-prod prime mfr variable to cost prime variable  */
        %LET COST_PRIME_HP_SAME = ;        /* If no-prod prime variable to cost prime variable          */

        /*-------------------------------------------------------*/
        /* Assign macro variables values when CM Prime/Non-prime */
        /* and Cost Prime/Non-prime are relevant.                */
        /*-------------------------------------------------------*/

        %IF %UPCASE(&HMPRIME) NE NA AND %UPCASE(&COST_PRIME) NE NA %THEN /* When there is reported CM and Cost prime */
        %DO;                                
            %LET COST_PRIME_HP = &COST_PRIME;
            %LET COST_PRIME_HP_RENAME = &COST_PRIME = NO_PROD_PRIME;
            %LET COST_PRIME_HP_RENAME_BACK = NO_PROD_PRIME = &COST_PRIME_HP;
            %LET COST_PRIME_HP_SAME = &COST_PRIME = NO_PROD_PRIME;
        %END;

        /************************************************************/
        /* G-8-B-ii: Find total production quantity for each model. */
        /************************************************************/

        PROC MEANS NWAY DATA = COST NOPRINT;
            CLASS &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH;   
            VAR &COST_QTY;
            OUTPUT OUT = TOTPRODQTY (DROP = _:) SUM = TOT_CONNUM_PROD_QTY;
        RUN;

        /****************************************************/
        /* G-8-B-iii: Separate out Cost without production. */
        /****************************************************/

        PROC SORT DATA = COST OUT = COST;
            BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH;
        RUN;

        DATA COST (DROP = TOT_CONNUM_PROD_QTY) 
             NOPRODUCTION (KEEP = &COST_MFR_HP &COST_PRIME_HP &COST_MATCH
                                  &COST_YEAR_MONTH &COST_CHAR  
                           RENAME = (&COST_MFR_HP_RENAME &COST_PRIME_HP_RENAME 
                                     &COST_MATCH = NO_PROD_CONNUM
                                     &COST_YEAR_MONTH = NO_PROD_YEAR_MONTH));                 
            MERGE COST TOTPRODQTY;
            BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH;

            IF TOT_CONNUM_PROD_QTY LE 0 THEN
                OUTPUT NOPRODUCTION;
            ELSE
                OUTPUT COST;
        RUN;

        PROC CONTENTS DATA = NOPRODUCTION 
                      OUT = NOPROD (KEEP = NOBS) NOPRINT;
        RUN;

        DATA _NULL_;
            SET NOPROD;
            IF _N_ = 1;
            IF NOBS GT 0 THEN
                MATCH_NOPRODS = "YES";
            ELSE
            IF NOBS = 0 THEN
                MATCH_NOPRODS = "NO";
    
            CALL SYMPUT('FIND_SURROGATES', MATCH_NOPRODS);
        RUN;
    %END;
%MEND G8_FIND_NOPRODUCTION;

/*****************************************************************/
/* G-9 ATTACH PRODUCT CHARACTERISTIC TO COST DATA, WHEN REQUIRED */
/*****************************************************************/

%MACRO G9_COST_PRODCHARS;
    %GLOBAL PROD_MATCH;

    %LET PROD_MATCH = ;

    %IF %UPCASE(&FIND_SURROGATES) = YES AND %UPCASE(&COST_PROD_CHARS) = NO %THEN 
    %DO;
        %MACRO GETCHARS;
            %IF %UPCASE(&SALESDB) = HMSALES %THEN
            %DO;
                %LET PROD_MATCH = &HMCPPROD;

                PROC SORT DATA = USSALES NODUPKEY OUT = USCONNUMLIST (KEEP = &USCVPROD &USCHAR);
                    BY &USCVPROD; 
                RUN;

                DATA USCONNUMLIST;
                    SET USCONNUMLIST;
                    RENAME &USCVPROD = &HMCPPROD;
                    %MACRO RENAMECHARS;
                        %LET I = 1;
                        %LET RENAMECALC = ;
                        %DO %UNTIL (%SCAN(&USCHAR, &I, %STR( )) = %STR());
                            %LET RENAMECALC = &RENAMECALC
                            RENAME %SYSFUNC(COMPRESS(%SCAN(&USCHAR,&I, %STR( )))) 
                                 = %SYSFUNC(COMPRESS(%SCAN(&HMCHAR,&I, %STR( )))) %NRSTR(;); 
                            &RENAMECALC
                            %LET I = %EVAL(&I + 1);
                        %END;
                    %MEND RENAMECHARS;

                    %RENAMECHARS;
                RUN;
    
                PROC SORT DATA = HMSALES NODUPKEY OUT = HMCONNUMLIST (KEEP = &HMCPPROD &HMCHAR); 
                    BY &HMCPPROD; 
                RUN;
    
                DATA CONNUMLIST;
                    SET HMCONNUMLIST USCONNUMLIST;
                RUN;
    
                PROC SORT DATA = CONNUMLIST OUT = CONNUMLIST NODUPKEY;  
                    BY &HMCPPROD; 
                RUN; 
            %END;
    
            %IF %UPCASE(&SALESDB) = USSALES %THEN
            %DO;
                %LET PROD_MATCH = &USCVPROD;
    
                PROC SORT DATA = USSALES NODUPKEY OUT = CONNUMLIST (KEEP = &USCVPROD &USCHAR); 
                    BY &USCVPROD; 
                RUN;
            %END;
        %MEND GETCHARS;

        %GETCHARS;

        %MACRO ATTACH_CHARS(SALES_MATCH);
            PROC SORT DATA = COST OUT = COST;
                BY &COST_MATCH &COST_TIME_PERIOD;
            RUN;
    
            DATA COST COST_NOT_SALES;
                MERGE COST (IN=A ) CONNUMLIST (IN=B RENAME=(&SALES_MATCH = &COST_MATCH));
                BY &COST_MATCH;
                IF A & B THEN OUTPUT COST;
                IF A & NOT B THEN OUTPUT COST_NOT_SALES; 
            RUN;

            DATA NOPRODUCTION;
                MERGE NOPRODUCTION (IN = A )
                      CONNUMLIST (IN = B
                                  RENAME = (&SALES_MATCH = NO_PRODUCTION_CONNUM));
                BY NO_PRODUCTION_CONNUM;
                IF A & B;
            RUN; 
        %MEND ATTACH_CHARS;

        %IF %UPCASE(&SALESDB) = HMSALES %THEN 
        %DO;
            %ATTACH_CHARS(&HMCPPROD);
        %END;
        %IF %UPCASE(&SALESDB) = USSALES %THEN 
        %DO;
            %ATTACH_CHARS(&USCVPROD);
        %END;
    %END;
%MEND G9_COST_PRODCHARS;

/****************************************************************************/
/* G-10. FILL IN MISSING LINES IN  TIME SPECIFIC COST DATA, WHEN REQUIRED  */
/****************************************************************************/

/**********************************************************************************************/
/* For cases where there are time–specific costs, i.e. quarterly cost, the program assigns    */
/* quarters to the CM and U.S. sales observations. The quarters are based off of the reported */
/* sale date, and first day of the POR/POI. The quarters are character, length 2, with the    */
/* values '-2', '-1', '0', '1', '2', etc. This will only run if there is quarterly cost.      */
/**********************************************************************************************/

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

/**********************************************************************************************************************/
/*                                                                                                                    */
/* For cases where there are time – specific costs, i.e. quarterly cost, the program takes the following steps:       */
/* 1. In section G-10;                                                                                                */
/*     a. Makes a list of CONNUMS and time periods with reported sales                                                */
/*     b. Makes a list of time periods with reported costs.                                                           */
/*     c. Checks to see if there are periods with sales that have no reported costs.                                  */
/*     d. Makes a POR weight average of the cost database by CONNUM.                                                  */
/* 2. In Section G-11, if there are periods that have sales that do not have any reported costs:                      */
/*     a. On a CONNUM specific basis, pull the closest period of production into the period that needs production.    */
/*        Keep the direct materials costs, and index them to adjust those costs according to the period.              */
/*     b. Apply the POR/I weight average ‘conversion costs’ i.e. the non-direct materials costs, to each CONNUM.      */
/* 3. In Section G-12; if there CONNUMS with no production in a specific period, but production in other period(s):   */
/*     a. Find the most similar CONNUM with production in the period and assign its direct materials costs as         */
/*        surrogate to the CONNUM(s) with no production.                                                              */
/*     b. Assign the POR/I weight average conversion costs to those CONNUMS with no production in the period.         */
/* 4. In Section G-13; if there are CONNUMS with sales in the POR/I and no production anywhere in the POR/I:          */
/*     a. Assign the most similar CONNUM’s cost from within the period as the surrogate for the CONNUM with no costs. */
/*                                                                                                                    */
/**********************************************************************************************************************/

%MACRO G10_TIME_PROD_LIST;
    OPTIONS MPRINT SYMBOLGEN;
    %IF %UPCASE(&COMPARE_BY_TIME) EQ YES %THEN
    %DO;

    %GLOBAL NOPROD_CHAR DIF_CHAR RENAME_NOPROD RENAME_DIF RENAME_HMCHAR RENAME_USCHAR ALLCOSTVARS NOPROD_TO_CHAR
            MFRZ LIST_TIMES ZERO_PROD_TIME NEEDTIMELST NV_TYPE SUM_DIRMAT_VARS REPLACE_INDEXED_DIRMATS NOPRDDMT
            CLSTPRDDMT PCTCHADMT RDMT HM_TIMES COSTPROD;

    %MACRO SCENERIO_MCRS;
        %LET RENAME_USCHAR =  ;

        /* Scenario 1: CM, COP DB has COST_CHARS */

        %MACRO HM_COP_HAS_CHARS;  
            DATA CHAR_CHANGE (DROP = I);
                DO I = 1 TO COUNTW("&COST_CHAR");
                    NOPROD_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "_NOPROD"));
                    DIF_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "_DIF"));
                    RENAME_NOPROD = STRIP(CATS(SCAN("&COST_CHAR", I), "=", NOPROD_CHAR));
                    RENAME_DIF = STRIP(CATS(SCAN("&COST_CHAR", I), "=", DIF_CHAR));
                    RENAMEMATCHUS= STRIP(CATS(SCAN("&USCHAR", I), "=", SCAN("&COST_CHAR", I)));
                    NOPROD_TO_CHAR= STRIP(CATS(NOPROD_CHAR, "=", SCAN("&COST_CHAR", I)));
                    RENAMEMATCHHM = STRIP(CATS(SCAN("&HMCHAR", I), "=", SCAN("&COST_CHAR", I)));
                    OUTPUT;
                END;
            RUN; 
    
            PROC SQL NOPRINT;
                SELECT NOPROD_CHAR, DIF_CHAR, RENAME_NOPROD, RENAME_DIF, RENAMEMATCHHM, RENAMEMATCHUS, NOPROD_TO_CHAR
                INTO :NOPROD_CHAR SEPARATED BY " ", 
                     :DIF_CHAR SEPARATED BY " ", 
                     :RENAME_NOPROD SEPARATED BY " ", 
                     :RENAME_DIF SEPARATED BY " ",
                     :RENAME_HMCHAR SEPARATED BY " ",
                     :RENAME_USCHAR SEPARATED BY " ",
                     :NOPROD_TO_CHAR SEPARATED BY " "
                FROM CHAR_CHANGE;
            QUIT;
        %MEND HM_COP_HAS_CHARS;
            
        /* Scenario 2: CM, COP DB does not have COST_CHARS */

        %MACRO HM_COP_NOTHAVE_CHARS;  
            DATA CHAR_CHANGE (DROP = I);
                DO I = 1 TO COUNTW("&HMCHAR");
                    NOPROD_CHAR = STRIP(CATS(SCAN("&HMCHAR", I), "_NOPROD"));
                    DIF_CHAR = STRIP(CATS(SCAN("&HMCHAR", I), "_DIF"));
                    RENAME_NOPROD = STRIP(CATS(SCAN("&HMCHAR", I), "=", NOPROD_CHAR));
                    RENAME_DIF = STRIP(CATS(SCAN("&HMCHAR", I), "=", DIF_CHAR));
                    RENAMEMATCHUS= STRIP(CATS(SCAN("&USCHAR", I), "=", SCAN("&HMCHAR", I)));
                    NOPROD_TO_CHAR= STRIP(CATS(NOPROD_CHAR, "=", SCAN("&HMCHAR", I)));
                    OUTPUT;
                END; 
            RUN;

            PROC SQL NOPRINT;
                SELECT NOPROD_CHAR, DIF_CHAR, RENAME_NOPROD, RENAME_DIF, RENAMEMATCHUS, NOPROD_TO_CHAR
                INTO :NOPROD_CHAR SEPARATED BY " ", 
                     :DIF_CHAR SEPARATED BY " ", 
                     :RENAME_NOPROD SEPARATED BY " ", 
                     :RENAME_DIF SEPARATED BY " ",
                     :RENAME_USCHAR SEPARATED BY " ",
                     :NOPROD_TO_CHAR SEPARATED BY " "
                FROM CHAR_CHANGE;
            QUIT;

            %LET RENAME_HMCHAR = ;
        %MEND HM_COP_NOTHAVE_CHARS;

        /* Scenario 3: US (CV), COP has COST_CHARS */

        %MACRO US_COP_HAS_CHARS;
            DATA CHAR_CHANGE (DROP = I);
                DO I = 1 TO COUNTW("&COST_CHAR");
                    NOPROD_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "_NOPROD"));
                    DIF_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "_DIF"));
                    RENAME_NOPROD = STRIP(CATS(SCAN("&COST_CHAR", I), "=", NOPROD_CHAR));
                    RENAME_DIF = STRIP(CATS(SCAN("&COST_CHAR", I), "=", DIF_CHAR));
                    RENAMEMATCHUS= STRIP(CATS(SCAN("&USCHAR", I), "=", SCAN("&COST_CHAR", I)));
                    NOPROD_TO_CHAR= STRIP(CATS(NOPROD_CHAR, "=", SCAN("&COST_CHAR", I)));
                    OUTPUT;
                END;
            RUN; 

            PROC SQL NOPRINT;
                SELECT NOPROD_CHAR, DIF_CHAR, RENAME_NOPROD, RENAME_DIF, RENAMEMATCHUS, NOPROD_TO_CHAR
                INTO :NOPROD_CHAR SEPARATED BY " ", 
                     :DIF_CHAR SEPARATED BY " ", 
                     :RENAME_NOPROD SEPARATED BY " ", 
                     :RENAME_DIF SEPARATED BY " ",
                     :RENAME_USCHAR SEPARATED BY " ",
                     :NOPROD_TO_CHAR SEPARATED BY " "
                FROM CHAR_CHANGE;
            QUIT;
        %MEND US_COP_HAS_CHARS;

        /* Scenario 4: US (CV), COP DB does not have COST_CHARS */

        %MACRO US_COP_NOTHAVE_CHARS;
            %LET COST_CHAR = ;

            DATA CHAR_CHANGE (DROP = I);
                DO I = 1 TO COUNTW("&USCHAR");
                    NOPROD_CHAR = STRIP(CATS(SCAN("&USCHAR", I), "_NOPROD"));
                    DIF_CHAR = STRIP(CATS(SCAN("&USCHAR", I), "_DIF"));
                    RENAME_NOPROD = STRIP(CATS(SCAN("&USCHAR", I), "=", NOPROD_CHAR));
                    RENAME_DIF = STRIP(CATS(SCAN("&USCHAR", I), "=", DIF_CHAR));
                    NOPROD_TO_CHAR= STRIP(CATS(NOPROD_CHAR, "=", SCAN("&USCHAR", I)));
                    OUTPUT;
                END; 
            RUN;

            PROC SQL NOPRINT;
                SELECT NOPROD_CHAR, DIF_CHAR, RENAME_NOPROD, RENAME_DIF, NOPROD_TO_CHAR
                INTO :NOPROD_CHAR SEPARATED BY " ", 
                     :DIF_CHAR SEPARATED BY " ", 
                     :RENAME_NOPROD SEPARATED BY " ", 
                     :RENAME_DIF SEPARATED BY " ",
                     :NOPROD_TO_CHAR SEPARATED BY " "
                FROM CHAR_CHANGE;
            QUIT;
        %MEND US_COP_NOTHAVE_CHARS;

        %MACRO MAKE_HMLIST;
            PROC SORT DATA = HMSALES (KEEP = &HM_TIME_PERIOD &SALES_COST_MANF &HMCONNUM &HMCHAR)
                      OUT = HM_TIMES (RENAME = (&HM_TIME_PERIOD = &COST_TIME_PERIOD &HMCONNUM = &COST_MATCH
                            &SALES_COST_MANF &EQUAL_COST_MANF &COST_MANF &RENAME_HMCHAR )) NODUPKEY;
                BY &SALES_COST_MANF &HM_TIME_PERIOD &HMCONNUM;
            RUN;
        %MEND;

        %IF &SALESDB = HMSALES %THEN
        %DO;
            %IF &COST_PROD_CHARS NE NO %THEN
            %DO;
                %HM_COP_HAS_CHARS
                %LET COSTPROD = &COST_CHAR;
            %END;
            %ELSE
            %DO;
                %HM_COP_NOTHAVE_CHARS
                %LET COSTPROD = &HMCHAR;
            %END;

            %MAKE_HMLIST
            %READ_US

            %LET HM_TIMES = HM_TIMES;  /* To include CM sales in the times list */
        %END;
        %ELSE
        %IF &SALESDB = USSALES %THEN
        %DO;
            %GLOBAL COST_MANF COST_PRIM COP_MANF_OUT EQUAL_COST_MANF US_SALES_COST_MANF;

            /*-----------------------------------------------------------------*/
            /* Define macro variables and set their default values to nothing. */
            /*-----------------------------------------------------------------*/

            %LET COST_MANF = ;
            %LET COP_MANF_OUT = ;
            %LET EQUAL_COST_MANF = ;
            %LET US_SALES_COST_MANF = ;

            %IF %UPCASE(&COST_MANUF) NE NA %THEN
            %DO;
                %LET COST_MANF = &COST_MANUF;
                %LET COP_MANF_OUT = COST_MANUF; 
                %LET EQUAL_COST_MANF = = ;
                %LET FIRST_COST_MANF = FIRST.&&COST_MANF OR;
                %LET US_SALES_COST_MANF = &USMANF;
            %END;

            %IF %UPCASE(&COST_PRIME) = NA %THEN
            %DO;
                %LET COST_PRIM = ;
            %END;
            %IF %UPCASE(&COST_PRIME) NE NA %THEN
            %DO;
                %LET COST_PRIM = &COST_PRIME;
            %END;

            %IF &COST_PROD_CHARS NE NO %THEN
            %DO;
                %US_COP_HAS_CHARS
                %LET COSTPROD = &COST_CHAR;
            %END;
            %ELSE
            %DO;
                %US_COP_NOTHAVE_CHARS
                %LET COSTPROD = &USCHAR;
            %END;

            %LET HM_TIMES = ;  /* No CM sales for the times list */
        %END;
    %MEND SCENERIO_MCRS;

    %SCENERIO_MCRS

    PROC SORT DATA = USSALES (KEEP = &US_TIME_PERIOD &US_SALES_COST_MANF &USCVPROD &USCHAR)
              OUT = US_TIMES (RENAME = (&US_TIME_PERIOD = &COST_TIME_PERIOD &USCVPROD = &COST_MATCH
                                        &US_SALES_COST_MANF &EQUAL_COST_MANF &COST_MANF &RENAME_USCHAR)) NODUPKEY;
        BY &US_SALES_COST_MANF &US_TIME_PERIOD &USCVPROD;
    RUN;

    DATA ALL_SALES_TIME_PERIODS;
        SET &HM_TIMES US_TIMES;
        SALESTIME = &COST_TIME_PERIOD;
    RUN;

    /* Creates a list of quarters with sales */

    PROC SORT DATA = ALL_SALES_TIME_PERIODS (DROP = &COST_CHAR)
              OUT = SALES_TIME_PERIODS NODUPKEY;  
        BY &COST_MANF &COST_TIME_PERIOD;
    RUN;

    PROC SQL NOPRINT ;
        SELECT DISTINCT(&COST_TIME_PERIOD)
            INTO :LIST_TIMES SEPARATED BY " " 
            FROM SALES_TIME_PERIODS;
    QUIT; 

    /* Creates a list of manufacturers, quarters, and CONNUMS */

    PROC SORT DATA = ALL_SALES_TIME_PERIODS
              OUT = MFR_TIME_CONN_LIST (DROP = SALESTIME) NODUPKEY;  
        BY &COST_MANF &COST_TIME_PERIOD &COST_MATCH;
    RUN;

    /*-------------------------------------------------------------------*/
    /* Make a list of all time periods with production in the cost data. */
    /*-------------------------------------------------------------------*/

    PROC MEANS NWAY DATA = COST NOPRINT;
        WHERE &COST_QTY GT 0;
        CLASS &COST_MANF &COST_TIME_PERIOD;
        VAR &COST_QTY;
        OUTPUT OUT = COST_TIMES (DROP = _:) SUM = ;
    RUN;

    DATA COST_TIMES;
       SET COST_TIMES;
       COST_TIME = &COST_TIME_PERIOD;
    RUN;

        DATA NEED_COST_TIMES NEED_COST_TIMES_LIST (KEEP = NEED_TIME &COST_MANF);
            MERGE SALES_TIME_PERIODS(IN = A) COST_TIMES (IN = B);
            FORMAT NEED_TIME $9.;
            BY &COST_MANF &COST_TIME_PERIOD;
            IF COST_TIME = "" THEN
               NEED_TIME = &COST_TIME_PERIOD;
            OUTPUT NEED_COST_TIMES;
            IF COST_TIME = "" THEN
            DO;
                OUTPUT NEED_COST_TIMES_LIST;
                CALL SYMPUTX("ZERO_PROD_TIME", 'YES');
            END;
        RUN;

        %LET NEEDTIMELST = ;

        PROC SQL NOPRINT;
            SELECT DISTINCT(QUOTE(NEED_TIME)) 
                INTO :NEEDTIMELST SEPARATED BY ","
                FROM NEED_COST_TIMES_LIST;
        QUIT;

        PROC PRINT DATA = NEED_COST_TIMES LABEL;
            VAR &COST_MANF SALESTIME COST_TIME NEED_TIME;
            LABEL SALESTIME = "PERIODS WITH REPORTED SALES"
                  COST_TIME = "PERIODS WITH REPORTED PRODUCTION"
                  NEED_TIME = "PERIODS WITH SALES WITHOUT REPORTED PRODUCTION";
            TITLE3 "TIME PERIODS WITH SALES BUT NO REPORTED PRODUCTION";
        RUN;

        /* Create POR weight averaged cost dataset */

        PROC MEANS NWAY DATA = COST NOPRINT;
            WHERE &COST_TIME_PERIOD IN (&TIME_INSIDE_POR);
            ID &COST_CHAR;
            CLASS &COST_MANF &COST_MATCH;
            VAR _NUMERIC_;
            WEIGHT &COST_QTY;
            OUTPUT OUT = POR_COST (DROP = _:) MEAN =;
        RUN;

        PROC MEANS NWAY DATA = COST NOPRINT;
            WHERE &COST_TIME_PERIOD IN (&TIME_INSIDE_POR);
            CLASS &COST_MANF &COST_MATCH;
            VAR &COST_QTY;
            OUTPUT OUT = POR_COST_QTYS (DROP = _:) SUM =;
        RUN;

        DATA POR_COST TEST;
            MERGE POR_COST (IN = A) POR_COST_QTYS (IN = B);
            BY &COST_MANF &COST_MATCH;
            IF A AND B THEN
                OUTPUT POR_COST;
            ELSE
                OUTPUT TEST;
        RUN;

        PROC CONTENTS DATA = COST NOPRINT OUT = ALLCOSTVARS (KEEP = NAME VARNUM);
        RUN;

        PROC SORT DATA = ALLCOSTVARS OUT = ALLCOSTVARS;
            BY VARNUM;
        RUN;

        PROC SQL NOPRINT;
        SELECT NAME
            INTO :ALLCOSTVARS SEPARATED BY " "
            FROM ALLCOSTVARS;
        QUIT;
    %END;
%MEND G10_TIME_PROD_LIST;

/***************************************************************/
/* G-11 CREATE COST DATABASE FOR PERIODS WITH ZERO PRODUCTION, */
/*      BUT SALES IN QUARTERLY COST SITUATIONS                 */
/***************************************************************/

%MACRO G11_CREATE_TIME_COST_DB;
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %IF &COST_MANUF NE NA %THEN
        %DO;
            %MACRO NTC_MFR;
                (RENAME = &COST_MANF = NTC_&COST_MANF)
            %MEND;

            %MACRO WHERENTCMFR;    
                WHERE &COST_MANF = NTC_&COST_MANF;
            %MEND;
        %END;
        %ELSE
        %DO;
            %MACRO NTC_MFR;
            %MEND;

            %MACRO WHERENTCMFR;    
            %MEND;
        %END;

/*****************************************************************************/
/* Pull closest quarter into need quarter for the direct material variables. */
/*****************************************************************************/

         /*********************************************************************************************/
         /* CREATE THE INDEXING CALCULATIONS                                                          */
         /*     NO_PROD_DIRMAT = INPUT(PUT(NEED_TIME, $DIRMAT_INPUT.), 8.);                           */
         /*     CLOSEST_PROD_DIRMAT= INPUT(PUT(&COST_TIME_PERIOD, $DIRMAT_INPUT.), 8.);               */
         /*     PERCENT_CHANGE_DIRMAT = (NO_PROD_DIRMAT - CLOSEST_PROD_DIRMAT) / CLOSEST_PROD_DIRMAT; */
         /*     RDIRMAT = DIRMAT * (1 + PERCENT_CHANGE_DIRMAT);                                       */
         /*********************************************************************************************/

        DATA DIRMAT_VARS_CHANGE (DROP = I);
            DO I = 1 TO COUNTW("&DIRMAT_VARS");
                DMT_VRS = STRIP(SCAN("&DIRMAT_VARS", I));
                R_DRMT_VRS = STRIP(CATS("R",SCAN("&DIRMAT_VARS", I))); 
                RNMAME_RDRIMATS = STRIP(CATS(SCAN("&DIRMAT_VARS", I), "=", R_DRMT_VRS,";")); 
                NOPRDDMT = CATS("NO_PROD_",DMT_VRS, " = INPUT(PUT(NEED_TIME, $", DMT_VRS, "_INPUT.), 8.)");    
                CLSTPRDDMT = CATS("CLOSEST_PROD_",DMT_VRS," = INPUT(PUT(&COST_TIME_PERIOD, $",DMT_VRS, "_INPUT.), 8.)");
                PCTCHADMT = CATS("PERCENT_CHANGE_",DMT_VRS, " = (NO_PROD_", DMT_VRS, " - CLOSEST_PROD_", DMT_VRS, ") / CLOSEST_PROD_", DMT_VRS);
                RDMT = CATS("R", DMT_VRS, " = ", DMT_VRS," * (1 + PERCENT_CHANGE_", DMT_VRS, ")");
                OUTPUT;
            END; 
        RUN;

        PROC SQL NOPRINT;
            SELECT DMT_VRS, RNMAME_RDRIMATS, NOPRDDMT, CLSTPRDDMT, PCTCHADMT, RDMT
                INTO :SUM_DIRMAT_VARS SEPARATED BY ",", 
                     :REPLACE_INDEXED_DIRMATS SEPARATED BY " ",
                     :NOPRDDMT SEPARATED BY "; ",
                     :CLSTPRDDMT SEPARATED BY "; ",
                     :PCTCHADMT SEPARATED BY "; ",
                     :RDMT SEPARATED BY "; "
                FROM DIRMAT_VARS_CHANGE ;
        QUIT;

        /* Pull closest quarter into needed quarter for DIRMAT variables */

        %IF &NEEDTIMELST NE ( ) %THEN
        %DO;
            DATA NEED_TIMES_COST;
                SET COST;
                DO J = 1 TO LAST;
                    SET NEED_COST_TIMES_LIST %NTC_MFR  POINT = J NOBS = LAST;
                    TIME_DIF=  ABS(NEED_TIME - &COST_TIME_PERIOD);
                    OUTPUT;              
                END;
            RUN;

            PROC SORT DATA = NEED_TIMES_COST OUT = NEED_TIMES_COST;
                BY NEED_TIME &COST_MANF &COST_MATCH TIME_DIF;
            RUN;

            DATA NO_PROD_TIMES_COST;
                SET NEED_TIMES_COST;
                %WHERENTCMFR;
                BY NEED_TIME &COST_MANF &COST_MATCH TIME_DIF;
                IF FIRST.&COST_MATCH THEN
                    OUTPUT NO_PROD_TIMES_COST;
            RUN;

/*******************************************************************************************/
/* Use the indexing calculations from Section G10. For each indexed cost variable,         */
/* the calculations should be:                                                             */
/*                                                                                         */
/*   NO_PROD_DIRMAT = INPUT(PUT(NEED_TIME, $DIRMAT_INPUT.), 8.);                           */
/*   CLOSEST_PROD_DIRMAT = INPUT(PUT(&COST_TIME_PERIOD, $DIRMAT_INPUT.), 8.);              */
/*   PERCENT_CHANGE_DIRMAT = (NO_PROD_DIRMAT - CLOSEST_PROD_DIRMAT) / CLOSEST_PROD_DIRMAT; */
/*   RDIRMAT = DIRMAT * (1 + PERCENT_CHANGE_DIRMAT);                                       */
/*******************************************************************************************/

            DATA NO_PROD_TIMES_COST;
                SET NO_PROD_TIMES_COST;
                &NOPRDDMT;
                &CLSTPRDDMT; 
                &PCTCHADMT; 
                &RDMT; 
                %LET REVISED_DIRMAT_VARS = R%SYSFUNC(TRANWRD(%QUOTE(&SUM_DIRMAT_VARS), %STR(,), %STR(, R)));
            RUN;

            PROC PRINT DATA = NO_PROD_TIMES_COST (OBS = &PRINTOBS);
                VAR &ALLCOSTVARS NEED_TIME TIME_DIF NO_PROD: CLOSEST_PROD: PERCENT_CHANGE: R:;
                TITLE3 "DIRECT MATERIALS ADJUSTMENT CALCULATIONS (&REVISED_DIRMAT_VARS)";
                TITLE4 "FOR COSTS IN PERIODS WITHOUT PRODUCTION";
            RUN;

            DATA NO_PROD_TIMES_COST (KEEP = &ALLCOSTVARS);
                SET NO_PROD_TIMES_COST;
                &REPLACE_INDEXED_DIRMATS;
                &COST_TIME_PERIOD = NEED_TIME;
            RUN;

/***************************************************************************************/
/* Replace time period specific conversion costs with period average conversion costs. */
/***************************************************************************************/

            PROC SORT DATA= NO_PROD_TIMES_COST (KEEP = &DIRMAT_VARS &COST_MATCH &COST_MANF &COST_TIME_PERIOD);
                BY &COST_MANF &COST_MATCH;
            RUN;

            DATA POR_COST_2;
                SET POR_COST;
                SUMDURMATS = SUM(&SUM_DIRMAT_VARS);
                REDUCED_&TOTCOM = &TOTCOM - SUMDURMATS;
                %LET DIRMAT_VARS_WITHOUT_COMMAS = %SYSFUNC(TRANWRD(%QUOTE(&SUM_DIRMAT_VARS), %STR(,), %STR(  )));
            RUN;

            PROC PRINT DATA = POR_COST_2 (OBS = &PRINTOBS);
                VAR &COST_MANF &COST_MATCH &TOTCOM &DIRMAT_VARS_WITHOUT_COMMAS REDUCED_&TOTCOM;
                TITLE3 "REDUCED TOTAL COST OF MANUFACTURING (REDUCED_&TOTCOM)";
                TITLE4 "WITH DIRECT MATERIAL VARIABLES NEEDING AVERAGE PURCHASE COSTS (&SUM_DIRMAT_VARS)";
                TITLE5 "BACKED OUT OF THE ORIGINAL TOTAL COST OF MANUFACTURING (&TOTCOM)";
            RUN;

            PROC SORT DATA = POR_COST_2 (DROP = &DIRMAT_VARS SUMDURMATS) OUT = POR_COST_2;
                BY &COST_MANF &COST_MATCH;
            RUN;

            DATA NO_PROD_TIMES_COST TEST;
                MERGE NO_PROD_TIMES_COST (IN = A) POR_COST_2(IN = B);
                BY &COST_MANF &COST_MATCH;

                IF A AND NOT B
                    THEN OUTPUT TEST;
                ELSE IF A THEN
                    OUTPUT NO_PROD_TIMES_COST;
            RUN;

            DATA NO_PROD_TIMES_COST(DROP = SUM_INDEXED_DIRMATS);
                SET NO_PROD_TIMES_COST;
                SUM_INDEXED_DIRMATS = SUM(&SUM_DIRMAT_VARS);
                REVISED_&TOTCOM = REDUCED_&TOTCOM + SUM_INDEXED_DIRMATS;
            RUN;

            PROC PRINT DATA = NO_PROD_TIMES_COST (OBS = &PRINTOBS);
                TITLE3 "SELECTION OF COSTS IN PERIODS WITHOUT PRODUCTION";
                TITLE4 "WITH REVISED DIRECT MATERIAL VARIABLES WITH AVERAGE PURCHASE COSTS (&SUM_DIRMAT_VARS)";
                TITLE5 "ADDED TO REDUCED TOTAL COST OF MANUFACTURING (REDUCED_&TOTCOM)";
            RUN;

            DATA COST;
                SET COST NO_PROD_TIMES_COST (DROP = &TOTCOM REDUCED_&TOTCOM
                                             RENAME = REVISED_&TOTCOM = &TOTCOM);
            RUN;
        %END;
    %END;
%MEND G11_CREATE_TIME_COST_DB;

/**************************************************************/
/* G-12 CREATE COST FOR CONNUMS WITH NO PRODUCTION IN PERIODS */
/*      WITH PRODUCTION IN QUARTERLY COST SITUATIONS          */
/**************************************************************/

%MACRO G12_ZERO_PROD_IN_PERIODS;
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %IF &COST_MANUF NE NA %THEN
        %DO;
            %MACRO MFREQUAL;
                AND &COST_MANF = NTC_&COST_MANF
            %MEND MFREQUAL;

            %MACRO RENAMEMFR;
                &COST_MANF = NTC_&COST_MANF
            %MEND RENAMEMFR;

            %MACRO NTC_MANF;
                NTC_&COST_MANF
            %MEND NTC_MANF;
        %END;
        %ELSE
        %DO;
            %MACRO MFREQUAL;
            %MEND MFREQUAL;

            %MACRO RENAMEMFR;    
            %MEND RENAMEMFR;

            %MACRO NTC_MANF;
            %MEND NTC_MANF;
        %END;

        PROC SORT DATA = NEED_COST_TIMES (DROP = &COST_MATCH NEED_TIME
                                          RENAME = (%RENAMEMFR COST_TIME = NO_PRODUCTION_QUARTER))
                  OUT = NEED_COST_TIMES;
            BY %NTC_MANF NO_PRODUCTION_QUARTER;
            WHERE NO_PRODUCTION_QUARTER NE " ";
        RUN;

        PROC SORT DATA = NOPRODUCTION %NTC_MFR OUT = NOPRODUCTION;
            BY %NTC_MANF NO_PRODUCTION_QUARTER NO_PRODUCTION_CONNUM;
        RUN;

        DATA ZERO_PROD TEST;
            MERGE  NOPRODUCTION (IN = A DROP = NOPROD_TIME_TYPE) NEED_COST_TIMES (IN = B);
            BY %NTC_MANF NO_PRODUCTION_QUARTER;
            IF A AND B THEN
                OUTPUT ZERO_PROD;
            ELSE
                OUTPUT TEST;
        RUN;

        DATA ZERO_PROD_SIMCOST (DROP = I);
            SET ZERO_PROD (RENAME = (&RENAME_NOPROD));

            DO J = 1 TO LAST;
                SET COST (KEEP = &COST_MATCH &COSTPROD &COST_TIME_PERIOD &COST_MANF &DIRMAT_VARS)
                          POINT = J NOBS = LAST;

                IF &COST_TIME_PERIOD = NO_PRODUCTION_QUARTER %MFREQUAL THEN
                DO;
                    ARRAY NOPROD(*) &NOPROD_CHAR;
                    ARRAY COSTPROD (*) &COSTPROD;
                    ARRAY DIFCHR (*) &DIF_CHAR;

                    DO I = 1 TO DIM(DIFCHR);
                        DIFCHR(I) = ABS(INPUT(NOPROD(I), 8.) - INPUT(COSTPROD(I), 8.));
                    END;

                    OUTPUT ZERO_PROD_SIMCOST;
                END;
            END;
        RUN;

        PROC SORT DATA = ZERO_PROD_SIMCOST OUT = ZERO_PROD_SIMCOST;
            BY &COST_MANF &COST_TIME_PERIOD NO_PRODUCTION_CONNUM &DIF_CHAR;
        RUN;

        DATA ZERO_PROD_SIMCOST_TOP5
             ZERO_PROD_SIMCOST_TOP1 (DROP = &DIF_CHAR &NOPROD_CHAR CHOICE NO_PRODUCTION_QUARTER
                                            &COST_MATCH %NTC_MANF
                                     RENAME = (NO_PRODUCTION_CONNUM = &COST_MATCH));

            SET ZERO_PROD_SIMCOST;
            BY &COST_MANF &COST_TIME_PERIOD NO_PRODUCTION_CONNUM &DIF_CHAR;

            IF FIRST.NO_PRODUCTION_CONNUM THEN
                CHOICE = 0;

            CHOICE + 1;

            IF CHOICE = 1 THEN 
            DO;
                OUTPUT ZERO_PROD_SIMCOST_TOP1;
            END; 

            IF CHOICE LE 5 THEN
                OUTPUT ZERO_PROD_SIMCOST_TOP5; 
        RUN;

        PROC SORT DATA = ZERO_PROD_SIMCOST_TOP5 OUT = ZERO_PROD_SIMCOST_TOP5;
            BY NO_PRODUCTION_CONNUM;
        RUN;

        PROC PRINT DATA = ZERO_PROD_SIMCOST_TOP5 (OBS = &PRINTOBS);
            BY NO_PRODUCTION_CONNUM;
            PAGEBY NO_PRODUCTION_CONNUM;
            VAR &COST_TIME_PERIOD NO_PRODUCTION_CONNUM %NTC_MANF &COST_MATCH
                &COST_MANF &DIF_CHAR CHOICE &DIRMAT_VARS;
            TITLE3 "CHECK TO 5 SIMILIAR MATCHES FOR ASSIGNING DIRECT MATERIALS TO CONNUMS WITHOUT PRODUCTION IN PERIODS WITH PRODUCTION";
        RUN;

        /* Add por weight averaged conversion costs to similar list */ 

        DATA POR_COST_3;
            SET POR_COST;
            SUMDURMATS = SUM(&SUM_DIRMAT_VARS);
            R&TOTCOM = &TOTCOM - SUMDURMATS;
        RUN;

        PROC SORT DATA = ZERO_PROD_SIMCOST_TOP1 (KEEP = &COST_TIME_PERIOD &COST_MANF &COST_MATCH &DIRMAT_VARS)
                  OUT = ZERO_PROD_SIMCOST_TOP1;
            BY &COST_MANF &COST_MATCH;
        RUN;

        PROC SORT DATA = POR_COST_3 
                  OUT = POR_CONV_COST (DROP = &DIRMAT_VARS SUMDURMATS &TOTCOM);
            BY &COST_MANF &COST_MATCH;
        RUN;

        DATA ZERO_PROD_ALLCOST;
            MERGE ZERO_PROD_SIMCOST_TOP1 (IN = A) POR_CONV_COST (IN = B);
            BY &COST_MANF &COST_MATCH;
            IF A AND B THEN
                OUTPUT ZERO_PROD_ALLCOST;
        RUN;

        DATA ZERO_PROD_ALLCOST (DROP = R&TOTCOM SUMDURMATS);
            SET ZERO_PROD_ALLCOST;
            SUMDURMATS = SUM(&SUM_DIRMAT_VARS);
            &TOTCOM = R&TOTCOM + SUMDURMATS;
        RUN;

        PROC PRINT DATA = ZERO_PROD_ALLCOST (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF COSTS FOR CONNUMS WITH ZERO PRODUCTION WITHIN PERIODS WITH PRODUCTION";
        RUN;

        /* Append to the total cost dataset */

        DATA COST;
            SET COST ZERO_PROD_ALLCOST;
        RUN;
    %END;
%MEND G12_ZERO_PROD_IN_PERIODS;

/*************************************************************/
/* G-13 CREATE COST FOR SALES WITHOUT PRODUCTION IN REPORTED */
/*      TIME PERIOD(S) IN QUARTERLY COST SITUATIONS          */
/*************************************************************/

%MACRO G13_CREATE_COST_PROD_TIMES;
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %IF &COST_MANUF NE NA %THEN
        %DO;
            %MACRO MFREQUAL;
                AND &COST_MANF = ISNC_&COST_MANF
            %MEND MFREQUAL;

            %MACRO RENAMEMFR;
                &COST_MANF = ISNC_&COST_MANF
            %MEND RENAMEMFR;

            %MACRO ISNC_MANF;
                ISNC_&COST_MANF
            %MEND ISNC_MANF;
        %END;
        %ELSE
        %DO;
            %MACRO MFREQUAL;
            %MEND MFREQUAL;

            %MACRO RENAMEMFR;
            %MEND RENAMEMFR;

            %MACRO ISNC_MANF;
            %MEND ISNC_MANF;
        %END;

        PROC SORT DATA = COST;
            BY &COST_TIME_PERIOD &COST_MANF &COST_MATCH;
        RUN;

        PROC SORT DATA = ALL_SALES_TIME_PERIODS (KEEP = &COST_MANF &COST_TIME_PERIOD &COST_MATCH &COSTPROD)
                  OUT = ALL_SALES_TIME_PERIODS;
            BY &COST_TIME_PERIOD &COST_MANF &COST_MATCH;
        RUN;

        DATA IN_SALES_NOT_COST (KEEP = &COST_MANF &COST_TIME_PERIOD &COST_MATCH &COSTPROD);
            MERGE ALL_SALES_TIME_PERIODS (IN = A) COST (IN = B);
            BY &COST_TIME_PERIOD &COST_MANF &COST_MATCH;
            IF A AND NOT B THEN
                OUTPUT IN_SALES_NOT_COST;
        RUN;

        DATA ISNC_SIMCOST (DROP = I);
            SET IN_SALES_NOT_COST (RENAME = (&RENAME_NOPROD &COST_TIME_PERIOD = ISNC_&COST_TIME_PERIOD
                                             &COST_MATCH = ISNC_&COST_MATCH %RENAMEMFR));
            DO J = 1 TO LAST;
                SET COST POINT = J NOBS = LAST;

                IF &COST_TIME_PERIOD = ISNC_&COST_TIME_PERIOD %MFREQUAL THEN
                DO;
                    ARRAY NOPROD(*) &NOPROD_CHAR;
                    ARRAY COSTPROD (*) &COSTPROD;
                    ARRAY DIFCHR (*) &DIF_CHAR;

                    DO I = 1 TO DIM(DIFCHR);
                        DIFCHR(I) = ABS(INPUT(NOPROD(I), 8.) - INPUT(COSTPROD(I), 8.));
                    END;

                    OUTPUT ISNC_SIMCOST;
                END;
            END;
        RUN;

        PROC SORT DATA = ISNC_SIMCOST;
           BY &COST_MANF &COST_TIME_PERIOD ISNC_&COST_MATCH &DIF_CHAR;
           RUN;

        DATA ISNC_SIMCOST_TOP5
            ISNC_SIMCOST_TOP1 (DROP = &DIF_CHAR &NOPROD_CHAR CHOICE &COST_MATCH %ISNC_MANF ISNC_&COST_TIME_PERIOD
                               RENAME = (ISNC_&COST_MATCH = &COST_MATCH));
            SET ISNC_SIMCOST;
            BY &COST_MANF &COST_TIME_PERIOD ISNC_&COST_MATCH &DIF_CHAR;

            IF FIRST.ISNC_&COST_MATCH THEN
            CHOICE = 0;

            CHOICE + 1;

            IF CHOICE = 1 THEN 
            DO;
                OUTPUT ISNC_SIMCOST_TOP1;
            END;
 
            IF CHOICE LE 5 THEN
                OUTPUT ISNC_SIMCOST_TOP5; 
        RUN;

        PROC SORT DATA = ISNC_SIMCOST_TOP5 OUT = ISNC_SIMCOST_TOP5;
            BY ISNC_&COST_MATCH;
        RUN;

        PROC PRINT DATA = ISNC_SIMCOST_TOP5 (OBS = &PRINTOBS);
            BY ISNC_&COST_MATCH;
            PAGEBY ISNC_&COST_MATCH;
            VAR &COST_TIME_PERIOD ISNC_&COST_MATCH %ISNC_MANF &COST_MATCH &COST_MANF &DIF_CHAR CHOICE &DIRMAT_VARS;
            TITLE3 "CHECK OF 5 SIMILIAR MATCHES FOR SALES WITHOUT PRODUCTION IN PERIODS WITH PRODUCTION";
        RUN;

        /* Append to the total cost dataset */

        DATA COST;
            SET COST ISNC_SIMCOST_TOP1;
            COST_TIME_TYPE = "TS";
            FORMAT COST_TIME_TYPE $TIMETYPE.;
        RUN;

        PROC SORT DATA = COST NODUPKEY OUT = CTEST DUPOUT = CDUPS;
            BY &COST_MANF &COST_TIME_PERIOD &COST_MATCH;
        RUN;
    %END;
%MEND G13_CREATE_COST_PROD_TIMES;

/************************/
/* G-14: HIGH INFLATION */
/************************/

/*************************************************************/
/* Create the variable YEARMONTHH or YEARMONTHU representing */
/* the year and month of the sales based on the sale date.   */
/*************************************************************/

%MACRO CREATE_YEAR_MONTH(SALEDATE, PROGRAM);
    %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
    %DO;
        %IF %UPCASE(&SALESDB = HMSALES) %THEN
        %DO;
            LENGTH YEARMONTHH $6.;
            YEARMONTHH = CATS(PUT(YEAR(&SALEDATE), 4.), PUT(MONTH(&SALEDATE), Z2.));
        %END;
        %ELSE
        %IF %UPCASE(&SALESDB = DOWNSTREAM) %THEN
        %DO;
            LENGTH YEARMONTHH $6.;
            YEARMONTHH = CATS(PUT(YEAR(&SALEDATE), 4.), PUT(MONTH(&SALEDATE), Z2.));
        %END;
        %ELSE
        %IF %UPCASE(&SALESDB) = USSALES %THEN
        %DO;
            LENGTH YEARMONTHU $6.;
            YEARMONTHU = CATS(PUT(YEAR(&SALEDATE), 4.), PUT(MONTH(&SALEDATE), Z2.));
       %END;
    %END;
%MEND CREATE_YEAR_MONTH;

%MACRO G14_HIGH_INFLATION;
%IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
%DO;
    /**********************************************************************************/
    /* G-14-A: Macro variable setup. There are 31 macro variables used by this macro. */
    /*         The following macro variable is defined in the ME Home Market Program: */
    /*             * COST_PRIME                                                       */
    /*         The following 9 macro variables are defined in the ME Home Market      */
    /*         Program and ME Margin Calculation Program:                             */
    /*             * COMPARE_BY_HIGH_INFLATION                                        */
    /*             * COST_CHAR                                                        */
    /*             * COST_MANUF                                                       */
    /*             * COST_MATCH                                                       */
    /*             * COST_QTY                                                         */
    /*             * COST_TIME_PERIOD                                                 */
    /*             * COST_YEAR_MONTH                                                  */
    /*             * LAST_YEAR_MONTH                                                  */
    /*             * PRINTOBS                                                         */
    /*         The following macro variables is defined in the G10_TIME_PROD_LIST,    */
    /*         HM1_PRIME_MANUF_MACROS, and US1_MACROS macros:                         */
    /*             * COST_PRIM                                                        */
    /*             * COST_MANF                                                        */
    /*         The following 2 macro variables are defined in the                     */
    /*         HM1_PRIME_MANUF_MACROS and US1_MACROS macros:                          */
    /*             * NO_PROD_COST_MANF                                                */
    /*             * NO_PROD_COST_PRIME                                               */
    /*         The following 8 macro variables are defined in the                     */
    /*         G8_FIND_NOPRODUCTION macro and also the G14_HIGH_INFLATION macro:      */
    /*             * COST_MFR_HP                                                      */
    /*             * COST_MFR_HP_RENAME                                               */
    /*             * COST_MFR_HP_RENAME_BACK                                          */
    /*             * COST_MFR_HP_SAME                                                 */
    /*             * COST_PRIME_HP                                                    */
    /*             * COST_PRIME_HP_RENAME                                             */
    /*             * COST_PRIME_HP_RENAME_BACK                                        */
    /*             * COST_PRIME_HP_SAME                                               */
    /*         The following 2 macro variables are defined in the                     */
    /*         G10_TIME_PROD_LIST and G14_HIGH_INFLATION:                             */
    /*             * DIF_CHAR (Defined using PROC SQL)                                */
    /*             * NOPROD_CHAR (Defined using PROC SQL)                             */
    /*         The following 7 macro variables are defined within and exclusively     */
    /*         used by the G14_HIGH_INFLATION macro:                                  */
    /*             * AND_COST_MANF                                                    */
    /*             * SURROGATE_COST_MFR_LABEL                                         */
    /*             * SURROGATE_COST_PRIME_LABEL                                       */
    /*             * NO_PROD_COST_MANF_LABEL                                          */
    /*             * NO_PROD_COST_PRIME_LABEL                                         */
    /*             * RENAME_NOPROD_CHAR (Defined using PROC SQL)                      */
    /*             * RENAME_NOPROD_CHAR_BACK (Defined using PROC SQL)                 */
    /**********************************************************************************/

   /*-----------------------------------------------------------------------*/
   /* G-14: Define macro variables and set their default values to nothing. */
   /*-----------------------------------------------------------------------*/

    /* 15 macro variables */

    %GLOBAL AND_COST_MANF COST_MFR_HP COST_MFR_HP_RENAME COST_MFR_HP_RENAME_BACK COST_MFR_HP_SAME 
            COST_PRIME_HP COST_PRIME_HP_RENAME COST_PRIME_HP_RENAME_BACK COST_PRIME_HP_SAME
            NO_PROD_COST_MANF_LABEL NO_PROD_COST_PRIME_LABEL RENAME_NOPROD_CHAR RENAME_NOPROD_CHAR_BACK
            SURROGATE_COST_MFR_LABEL SURROGATE_COST_PRIME_LABEL;   

    /*---------------------------------------------------------------------------*/
    /* Assign null macro variable values when Cost manufacturer is not relevant. */
    /*---------------------------------------------------------------------------*/

    %LET AND_COST_MANF = ;              /* AND operator for Cost manufacturer purposes         */
    %LET SURROGATE_COST_MFR_LABEL = ;   /* Surrogate Cost manufacturer variable label          */
    %LET SURROGATE_COST_PRIME_LABEL = ; /* Surrogate Cost prime variable label                 */
    %LET NO_PROD_COST_MANF_LABEL = ;    /* No production Cost manufacturer variable label      */
    %LET NO_PROD_COST_PRIME_LABEL = ;   /* No production Cost manufacturer variable label      */

    /*------------------------------------------------------------*/
    /* Assign null macro variable values when HM sales            */
    /* manufacturer or Cost manufacturer is not relevant.         */
    /*------------------------------------------------------------*/

    %LET COST_MFR_HP = ;             /* Cost manufacturer variable                            */
    %LET COST_MFR_HP_RENAME = ;      /* Rename cost mfr variable to no-prod cost mfr variable */
    %LET COST_MFR_HP_RENAME_BACK = ; /* Rename no-prod cost mfr variable to cost mfr variable */
    %LET COST_MFR_HP_SAME = ;        /* If no-prod cost mfr variable equal cost mfr variable  */

    /*-----------------------------------------------------------------*/
    /* Assign null macro variable values when HM sales Prime/Non-prime */
    /* or Cost Prime/Non-prime are not relevant.                       */
    /*-----------------------------------------------------------------*/
 
    %LET COST_PRIME_HP = ;             /* Cost prime variable                                       */
    %LET COST_PRIME_HP_RENAME = ;      /* Rename Cost prime variable to no-prod cost prime variable */
    %LET COST_PRIME_HP_RENAME_BACK = ; /* Rename no-prod prime mfr variable to cost prime variable  */
    %LET COST_PRIME_HP_SAME = ;        /* If no-prod prime variable to cost prime variable          */

    /*---------------------------------------------------------*/
    /* Assign macro variable values when HM sales manufacturer */
    /* and Cost manufacturer are relevant.                     */
    /*---------------------------------------------------------*/

    %IF %UPCASE(&HMMANUF) NE NA AND %UPCASE(&COST_MANUF) NE NA %THEN /* When there is reported HM and Cost mfr */
    %DO; 
        %LET COST_MFR_HP = &COST_MANUF;
        %LET COST_MFR_HP_RENAME = &COST_MANUF = NO_PROD_MFR;
        %LET COST_MFR_HP_RENAME_BACK = NO_PROD_MFR = &COST_MANUF;
        %LET COST_MFR_HP_SAME = &COST_MANUF = NO_PROD_MFR;
    %END;

    /*-------------------------------------------------------*/
    /* Assign macro variables values when HM Prime/Non-prime */
    /* and Cost Prime/Non-prime are relevant.                */
    /*-------------------------------------------------------*/

    %IF %UPCASE(&HMPRIME) NE NA AND %UPCASE(&COST_PRIME) NE NA %THEN /* When there is reported HM and Cost prime */
    %DO;                                
        %LET COST_PRIME_HP = &COST_PRIME;
        %LET COST_PRIME_HP_RENAME = &COST_PRIME = NO_PROD_PRIME;
        %LET COST_PRIME_HP_RENAME_BACK = NO_PROD_PRIME = &COST_PRIME_HP;
        %LET COST_PRIME_HP_SAME = &COST_PRIME = NO_PROD_PRIME;
    %END;

    /*-------------------------------------------------------*/
    /* Assign macro variables values when Cost manufacturer  */
    /* is relevant.                                          */
    /*-------------------------------------------------------*/

    %IF %UPCASE(&COST_MANUF) NE NA %THEN           /* When there is reported Cost manufacturer */
    %DO;
        %LET AND_COST_MANF = AND ;
        %LET NO_PROD_COST_MANF_LABEL = &NO_PROD_COST_MANF = 'NO PROCUCTION*MANUFACTURER';

        %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
        %DO;
            %LET SURROGATE_COST_MFR_LABEL = &COST_MFR_HP = 'SURROGATE*MANUFACTURER';
        %END;
    %END;

    /*---------------------------------------------------------*/
    /* Assign macro variables values when Cost Prime/Non-prime */
    /* is relevant.                                            */
    /*---------------------------------------------------------*/

    %IF %UPCASE(&COST_PRIME) NE NA %THEN           /* When there is reported Cost prime */
    %DO; 
        %LET NO_PROD_COST_PRIME_LABEL = &NO_PROD_COST_PRIME = 'NO PROCUCTION*PRIME';

        %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
        %DO;
           %LET SURROGATE_COST_PRIME_LABEL = &COST_PRIME = "SURROGATE*PRIME";
        %END;
    %END;

    /*-----------------------------------------------------------------------*/
    /* Print a sample of Cost calculations before high inflation adjustmets. */
    /*-----------------------------------------------------------------------*/

    PROC PRINT DATA = COST (OBS = &PRINTOBS);
        TITLE3 "SAMPLE OF COST CALCULATIONS BEFORE HIGH INFLATION ADJUSTMENTS";
    RUN;

    /***************************************************************************************/
    /* G-14-A: Find costs for CONNUMs/Months sold and produced in the same CONNUMs/Months. */
    /***************************************************************************************/

    /********************************************************/
    /* G-14-A-i: Find extended costs using monthly indexes. */
    /********************************************************/

    DATA REPORTED_EXTENDED_COST (DROP = I);
        SET COST;  

        ENDINDEX = INPUT(PUT("&LAST_YEAR_MONTH", $PRICE_INDEX.), 8.);
        INDEX = INPUT(PUT(&COST_YEAR_MONTH, $PRICE_INDEX.), 8.);
        INFLATOR = ENDINDEX / INDEX;

        ARRAY EXTEND (*) TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP;
        ARRAY EXTENDED (*) TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;

        DO I = 1 TO DIM(EXTEND);
            EXTENDED(I) = EXTEND(I) * INFLATOR;
        END;
    RUN;

    PROC PRINT DATA = REPORTED_EXTENDED_COST (OBS = &PRINTOBS) SPLIT = '<';
        VAR &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH &COST_DUTY_DRAWBACK_VARIABLE TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP 
            INDEX ENDINDEX INFLATOR TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;
        LABEL &COST_YEAR_MONTH = 'YEAR AND<MONTH'
              ENDINDEX = 'END OF PERIOD<MONTHLY INFLATION<INDEX'
              INDEX = 'MONTHLY INFLATION<INDEX'
              INFLATOR = 'INFLATOR =<ENDINDEX / INDEX'
              TCOMCOP_EXT = 'EXTENDED<TCOMCOP'
              VCOMCOP_EXT = 'EXTENDED<VCOMCOP'
              GNACOP_EXT = 'EXTENDED<GNACOP'
              INTEXCOP_EXT = 'EXTENDED<INTEXCOP'
              TOTALCOP_EXT = 'EXTENDED<TOTALCOP';
        TITLE3 "REPORTED COSTS RESTATED (I.E., INFLATED) IN A CONSTANT CURRENCY BASIS (END OF PERIOD) USING MONTHLY INFLATION INDICES";
        TITLE4 "EXTENDED COST VARIABLE = COST VARIABLE * INFLATOR";
    RUN;

    /*************************************************************/
    /* G-14-A-ii: Find weight averaged extended costs by CONNUM. */
    /*************************************************************/

    PROC MEANS DATA = REPORTED_EXTENDED_COST NWAY NOPRINT;
        CLASS &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;
        ID &COST_CHAR;
        VAR &COST_DUTY_DRAWBACK_VARIABLE TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;
        WEIGHT &COST_QTY;
        OUTPUT OUT = WEIGHT_AVERAGED_COST (DROP = _:) MEAN = SUMWGT = TOTAL_PROD_QUANTITY;
    RUN;

    PROC PRINT DATA = WEIGHT_AVERAGED_COST (OBS = &PRINTOBS) SPLIT = "<";
        VAR &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_DUTY_DRAWBACK_VARIABLE TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;
        LABEL TCOMCOP_EXT = "WA EXTENDED<TCOMCOP"
              VCOMCOP_EXT = "WA EXTENDED<VCOMCOP"
              GNACOP_EXT = "WA EXTENDED<GNACOP"
              INTEXCOP_EXT = "WA EXTENDED<INTEXCOP"
              TOTALCOP_EXT = "WA EXTENDED<TOTALCOP";
        TITLE3 "PERIOD-WIDE WEIGHT AVERAGED COSTS";
    RUN;

    /***********************************************************************************/
    /* G-14-A-iii: Combine monthly cost with weight averaged extended costs by CONNUM. */
    /***********************************************************************************/

    PROC SORT DATA = REPORTED_EXTENDED_COST
              OUT = MONTHLY_CONNUM_LIST (KEEP = &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH &COST_QTY) NODUPKEY;
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH;
    RUN;

    DATA REPORTED_COST (DROP = I);
        MERGE WEIGHT_AVERAGED_COST (IN = A) MONTHLY_CONNUM_LIST (IN = B);
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;

        IF B;

        /*********************************************************/
        /* G-14-A-iv: Find deflated costs using monthly indexes. */
        /*********************************************************/

        INDEX = INPUT(PUT(&COST_YEAR_MONTH, $PRICE_INDEX.), 8.);
        ENDINDEX = INPUT(PUT("&LAST_YEAR_MONTH", $PRICE_INDEX.), 8.);
        DEFLATOR = INDEX / ENDINDEX;

        ARRAY EXTEND (*) TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP;
        ARRAY EXTENDED (*) TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;

        DO I = 1 TO DIM(EXTENDED);
            EXTEND(I) = EXTENDED(I) * DEFLATOR;
        END;

        COST_TYPE = 'H1';
        FORMAT COST_TYPE $TIMETYPE.;
    RUN;

    PROC PRINT DATA = REPORTED_COST (OBS = &PRINTOBS) SPLIT = '<';
        VAR &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH &COST_DUTY_DRAWBACK_VARIABLE TCOMCOP_EXT 
            VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT INDEX ENDINDEX DEFLATOR TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP COST_TYPE;
        LABEL &COST_YEAR_MONTH = 'YEAR AND<MONTH'
              TCOMCOP_EXT = 'WA EXTENDED<TCOMCOP'
              VCOMCOP_EXT = 'WA EXTENDED<VCOMCOP'
              GNACOP_EXT = 'WA EXTENDED<GNACOP'
              INTEXCOP_EXT = 'WA EXTENDED<INTEXCOP'
              TOTALCOP_EXT = 'WA EXTENDED<TOTALCOP'
              INDEX = 'MONTHLY INFLATION<INDEX'
              ENDINDEX = 'END OF PERIOD<MONTHLY INFLATION<INDEX'
              DEFLATOR = 'DEFLATOR =<INDEX / ENDINDEX'
              TCOMCOP = 'DEFLATED<TCOMCOP'
              VCOMCOP = 'DEFLATED<VCOMCOP'
              GNACOP = 'DEFLATED<GNACOP'
              INTEXCOP = 'DEFLATED<INTEXCOP'
              TOTALCOP = 'EXTENDED<TOTALCOP'
              COST_TYPE = 'COST<TYPE';
        TITLE3 "COSTS FOR CONNUMS/MONTHS SOLD AND PRODUCED IN THE SAME CONNUMS/MONTHS";
        TITLE4 "PERIOD-WIDE WEIGHT AVERAGED COSTS (I.E. EXTENDED) RESTATED (I.E. DEFLATED) IN MONTH CURRENCY VALUES";
        TITLE5 "COST VARIABLE = EXTENDED COST VARIABLE * DEFLATOR";
    RUN;

    /*******************************************************************************************/
    /* G-14-B: Find costs for CONNUMs/Months sold but not produced in the same CONNUMs/Months. */
    /*******************************************************************************************/

    PROC SORT DATA = NOPRODUCTION OUT = NOPRODUCTION;   
        BY NO_PROD_CONNUM;
    RUN;

    PROC SORT DATA = REPORTED_COST (KEEP = &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_QTY &COST_DUTY_DRAWBACK_VARIABLE
                                           TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT)
              OUT =  END_OF_PERIOD_COST NODUPKEY;   
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;
    RUN;

    /***************************************************************************************/
    /* G-14-B-i: Combine no-production cost with weight averaged extended costs by CONNUM. */
    /***************************************************************************************/

    DATA COST_FROM_DIFFERENT_MONTH (DROP = I)
        NOPRODUCTION_COST (DROP = I RENAME = (&COST_MFR_HP_RENAME &COST_PRIME_HP_RENAME
                                              &COST_MATCH = NO_PROD_CONNUM
                                              &COST_YEAR_MONTH = NO_PROD_YEAR_MONTH));
        MERGE NOPRODUCTION (IN = A RENAME = (&COST_MFR_HP_RENAME_BACK &COST_PRIME_HP_RENAME_BACK
                                             NO_PROD_CONNUM = &COST_MATCH
                                             NO_PROD_YEAR_MONTH = &COST_YEAR_MONTH))
                           END_OF_PERIOD_COST (IN = B); 
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;
        IF A AND B THEN
        DO;
            /*********************************************************/
            /* G-14-B-ii: Find deflated costs using monthly indexes. */
            /*********************************************************/

            INDEX = INPUT(PUT(&COST_YEAR_MONTH, $PRICE_INDEX.), 8.);
            ENDINDEX = INPUT(PUT("&LAST_YEAR_MONTH", $PRICE_INDEX.), 8.);
            DEFLATOR = INDEX / ENDINDEX;

            ARRAY EXTENDED (*) TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;
            ARRAY ANNUALIZED (*) TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP;

            DO I = 1 TO DIM(EXTENDED);
                ANNUALIZED(I) = EXTENDED(I) * DEFLATOR;
            END;

            COST_TYPE = 'H2';
            FORMAT COST_TYPE $TIMETYPE.;
            OUTPUT COST_FROM_DIFFERENT_MONTH;
        END;
        ELSE
        IF A AND NOT B THEN
            OUTPUT NOPRODUCTION_COST;
    RUN;

    PROC PRINT DATA = COST_FROM_DIFFERENT_MONTH (OBS = &PRINTOBS);
        VAR &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH &COST_DUTY_DRAWBACK_VARIABLE TCOMCOP_EXT VCOMCOP_EXT 
            GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT INDEX ENDINDEX DEFLATOR TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP;
        LABEL &COST_YEAR_MONTH = 'YEAR AND<MONTH'
              TCOMCOP_EXT = 'WA EXTENDED<TCOMCOP'
              VCOMCOP_EXT = 'WA EXTENDED<VCOMCOP'
              GNACOP_EXT = 'WA EXTENDED<GNACOP'
              INTEXCOP_EXT = 'WA EXTENDED<INTEXCOP'
              TOTALCOP_EXT = 'WA EXTENDED<TOTALCOP'
              INDEX = 'MONTHLY INFLATION<INDEX'
              ENDINDEX = 'END OF PERIOD<MONTHLY INFLATION<INDEX'
              DEFLATOR = 'DEFLATOR =<INDEX / ENDINDEX'
              TCOMCOP = 'DEFLATED<TCOMCOP'
              VCOMCOP = 'DEFLATED<VCOMCOP'
              GNACOP= 'DEFLATED<GNACOP'
              INTEXCOP = 'DEFLATED<INTEXCOP'
              TOTALCOP = 'DEFLATED<TOTALCOP';
        TITLE3 "COSTS FOR PRODUCED CONNUMS/MONTHS SOLD BUT NOT PRODUCED IN THE SAME CONNUMS/MONTHS";
        TITLE4 "WITH PERIOD-WIDE WEIGHT AVERAGED COSTS (I.E. EXTENDED) RESTATED (I.E. DEFLATED) IN MONTH CURRENCY VALUES";
        TITLE5 "COST VARIABLE = EXTENDED COST VARIABLE * DEFLATOR";
    RUN;

    /**************************************************************************************/
    /* G-14-C: Weight-average costs sold and produced in the same CONNUMs/Months with     */
    /*         costs for CONNUMs/Months sold but not produced in the same CONNUMs/Months. */
    /**************************************************************************************/

    DATA IDENTICAL_CONNUM_COST;
        SET REPORTED_COST COST_FROM_DIFFERENT_MONTH;
    RUN;

    PROC MEANS NWAY DATA = IDENTICAL_CONNUM_COST NOPRINT;
        CLASS &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH;
        ID &COST_CHAR COST_TYPE;
        VAR &COST_DUTY_DRAWBACK_VARIABLE VCOMCOP TCOMCOP GNACOP INTEXCOP TOTALCOP;
        WEIGHT &COST_QTY;
        OUTPUT OUT = IDENTICAL_CONNUM_COST (DROP = _:) SUMWGT = &COST_QTY
               MEAN = &COST_DUTY_DRAWBACK_VARIABLE AVGVCOM AVGTCOM AVGGNA AVGINT AVGCOST;
    RUN;

    PROC SORT DATA = IDENTICAL_CONNUM_COST OUT = IDENTICAL_CONNUM_COST;
        BY COST_TYPE &COST_MATCH;
    RUN;

    DATA COSTCHECK (DROP = COUNT);
        SET IDENTICAL_CONNUM_COST;
        BY COST_TYPE &COST_MATCH;

        IF FIRST.COST_TYPE THEN
            COUNT = 0;

        COUNT + 1;

        IF COUNT LE 5;
    RUN;

    PROC PRINT DATA = COSTCHECK (OBS = &PRINTOBS);
        BY COST_TYPE;
        ID COST_TYPE;
        TITLE3 "SAMPLE OF WEIGHT-AVERAGED COST DATA FOR CONNUMS WITH PRODUCTION IN THE PERIOD";
    RUN;

    /*********************************************************************/
    /* G-14-D: Find costs for CONNUMs/Months not produced in the period. */
    /*********************************************************************/

    /******************************************************************************************/
    /* G-14-D-i: Create the macro variables DIF_CHAR and NOPROD_CHAR                          */
    /*           that contain lists of Cost physical characteristics with the added suffixes  */
    /*           _DIF and _NOPROD respectively. Create the macro variable RENAME_NOPROD_CHAR  */
    /*           that contains a list of Cost physical characteristics equal to the same      */
    /*           physical characteristics with suffix _NOPROD. RENAME_NOPROD_CHAR_BACK        */
    /*           contains a list of Cost physical characteristics with suffix _NOPROD equal   */
    /*           to the same physical characteristics.                                        */
    /******************************************************************************************/

    DATA CHAR_COMPARE (DROP = I);
        DO I = 1 TO COUNTW("&COST_CHAR");
            DIF_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "_DIF"));
            NOPROD_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "_NOPROD"));
            RENAME_NOPROD_CHAR = STRIP(CATS(SCAN("&COST_CHAR", I), "=", NOPROD_CHAR));
            RENAME_NOPROD_CHAR_BACK = STRIP(CATS(NOPROD_CHAR, "=", SCAN("&COST_CHAR", I)));
            OUTPUT;
        END;
    RUN; 

    PROC SQL NOPRINT;
        SELECT DIF_CHAR, NOPROD_CHAR, RENAME_NOPROD_CHAR, RENAME_NOPROD_CHAR_BACK
            INTO :DIF_CHAR SEPARATED BY " ", 
                 :NOPROD_CHAR SEPARATED BY " ",
                 :RENAME_NOPROD_CHAR SEPARATED BY " ",
                 :RENAME_NOPROD_CHAR_BACK SEPARATED BY " " 
            FROM CHAR_COMPARE;
    QUIT;

    /*****************************************************************************/
    /* G-14-D-ii: Find similar models sold with the constraint that manufacturer */
    /*            and no-production manufacturer are the same (if relevant) and  */
    /*            prime and no-production prime are the same (if relevant).      */
    /*****************************************************************************/

    PROC SORT DATA = NOPRODUCTION_COST (RENAME = (&RENAME_NOPROD_CHAR))
              OUT = NOPRODCONNUMS (KEEP = &NO_PROD_COST_MANF &NO_PROD_COST_PRIME
                                          NO_PROD_CONNUM NO_PROD_YEAR_MONTH &NOPROD_CHAR) NODUPKEY;
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH;
    RUN;

    PROC SORT DATA = IDENTICAL_CONNUM_COST 
              OUT = COSTPRODUCTS (KEEP = &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH
                                         &COST_TIME_PERIOD &COST_CHAR) NODUPKEY;
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH;
    RUN;

    DATA SIMCOST (DROP = I);
        SET NOPRODCONNUMS;

        DO J = 1 TO LAST;
            SET COSTPRODUCTS POINT = J NOBS = LAST;

        %IF &COST_MANUF NE NA OR &COST_PRIME NE NA %THEN    /* Cost Manufacturer and/or Cost Prime reported */
        %DO;
            IF &COST_MFR_HP_SAME &AND_COST_MANF &COST_PRIME_HP_SAME THEN
            DO;
        %END;
                ARRAY DIF_CHAR (*) &DIF_CHAR;
                ARRAY NOPROD_CHAR (*) &NOPROD_CHAR;
                ARRAY PROD_CHAR (*) &COST_CHAR;

                DO I = 1 TO DIM(DIF_CHAR);
                    DIF_CHAR(I) = ABS(INPUT(NOPROD_CHAR(I), 8.) - INPUT(PROD_CHAR(I), 8.));
                END;

                OUTPUT SIMCOST;

        %IF &COST_MANUF NE NA OR &COST_PRIME NE NA %THEN    /* Cost Manufacturer and/or Cost Prime reported */
        %DO;
           END;
        %END;

        END;
    RUN;

    PROC SORT DATA = SIMCOST OUT = SIMCOST;
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH &DIF_CHAR;
    RUN;

    DATA TOP1SIMCOST TOP5SIMCOST;
        SET SIMCOST;
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH &DIF_CHAR;

        IF FIRST.NO_PROD_YEAR_MONTH THEN
            CHOICE = 0;

        CHOICE + 1;

        IF CHOICE = 1 THEN
            OUTPUT TOP1SIMCOST;

        IF CHOICE LE 5 THEN
            OUTPUT TOP5SIMCOST;
    RUN;

    PROC PRINT DATA = TOP5SIMCOST (OBS = &PRINTOBS) NOOBS  SPLIT = '<';
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH;
        PAGEBY NO_PROD_YEAR_MONTH;
        VAR CHOICE &COST_MFR_HP &COST_PRIME_HP &COST_MATCH &COST_YEAR_MONTH
            &NOPROD_CHAR &COST_CHAR &DIF_CHAR;
        LABEL NO_PROD_CONNUM = 'NO PROCUCTION CONNUM'
              NO_PROD_YEAR_MONTH = 'NO PROCUCTION YEAR AND MONTH'
              &COST_MATCH = 'SURROGATE<CONNUM'
              &COST_YEAR_MONTH = 'SURROGATE<YEAR AND<MONTH';
        TITLE3 "TOP FIVE SIMILAR SURROGATE COST MATCHES FOR CONNUMS NOT PRODUCED DURING THE COST ACCOUNTING PERIOD";
    RUN;

    /************************************************************************/
    /* G-14-D-iii: Sort most similar surrogate matches by surrogate CONNUM. */
    /************************************************************************/

    PROC SORT DATA = TOP1SIMCOST (KEEP = &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH
                                         &NOPROD_CHAR &COST_MFR_HP &COST_PRIME_HP &COST_MATCH COST_TYPE)
              OUT = SIMILARCOST;
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;
    RUN;

    /**********************************************/
    /* G-14-D-iv: Sort annualized cost by CONNUM. */
    /**********************************************/

    PROC SORT DATA = WEIGHT_AVERAGED_COST (KEEP = &COST_MFR_HP &COST_PRIME_HP &COST_MATCH
                                                  TOTAL_PROD_QUANTITY &COST_DUTY_DRAWBACK_VARIABLE
                                                  TCOMCOP_EXT VCOMCOP_EXT
                                                  GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT)
        OUT = WA_COST_FOR_SURROGATE;
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;
    RUN;

    /************************************************************************/
    /* G-14-D-v: Append no-production CONNUMs to annualized cost by CONNUM. */
    /************************************************************************/

    DATA MOST_SIMILAR_ANNUALIZED_COST;
        MERGE SIMILARCOST (IN = A) WA_COST_FOR_SURROGATE (IN = B);
        BY &COST_MFR_HP &COST_PRIME_HP &COST_MATCH;
        IF A AND B THEN
        DO;
            COST_TYPE = 'H3';
            FORMAT COST_TYPE $TIMETYPE.;

            INDEX = INPUT(PUT(NO_PROD_YEAR_MONTH, $PRICE_INDEX.), 8.);
            ENDINDEX = INPUT(PUT("&LAST_YEAR_MONTH", $PRICE_INDEX.), 8.);
            DEFLATOR = INDEX / ENDINDEX;

            ARRAY EXTEND (*) TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP;
            ARRAY EXTENDED (*) TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT;

            DO I = 1 TO DIM(EXTENDED);
                EXTEND(I) = EXTENDED(I) * DEFLATOR;
            END;

            OUTPUT MOST_SIMILAR_ANNUALIZED_COST;
        END;
    RUN;

    PROC PRINT DATA = MOST_SIMILAR_ANNUALIZED_COST (OBS = &PRINTOBS) SPLIT = '*';
        VAR &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH
            &COST_MFR_HP &COST_PRIME_HP &COST_MATCH TOTAL_PROD_QUANTITY  
            &COST_DUTY_DRAWBACK_VARIABLE TCOMCOP_EXT VCOMCOP_EXT GNACOP_EXT INTEXCOP_EXT TOTALCOP_EXT
            INDEX ENDINDEX DEFLATOR TCOMCOP VCOMCOP GNACOP INTEXCOP TOTALCOP;
        LABEL &NO_PROD_COST_MANF_LABEL
              &NO_PROD_COST_PRIME_LABEL
              NO_PROD_CONNUM = 'NO PROCUCTION*CONNUM'
              NO_PROD_YEAR_MONTH = 'NO PROCUCTION*YEAR AND MONTH'
              &SURROGATE_COST_MFR_LABEL
              &SURROGATE_COST_PRIME_LABEL
              &COST_MATCH = 'SURROGATE*CONNUM'
              VCOMCOP_EXT = 'WA EXTENDED*VCOMCOP'
              GNACOP_EXT = 'WA EXTENDED*GNACOP'
              INTEXCOP_EXT = 'WA EXTENDED*INTEXCOP'
              TOTALCOP_EXT = 'WA EXTENDED*TOTALCOP'
              INDEX = 'MONTHLY INFLATION*INDEX'
              ENDINDEX = 'END OF PERIOD*MONTHLY INFLATION*INDEX'
              DEFLATOR = 'DEFLATOR =*INDEX / ENDINDEX'
              TCOMCOP = 'DEFLATED*TCOMCOP'
              VCOMCOP = 'DEFLATED*VCOMCOP'
              GNACOP = 'DEFLATED*GNACOP'
              INTEXCOP = 'DEFLATED*INTEXCOP'
              TOTALCOP = 'DEFLATED<TOTALCOP';
        TITLE3 "SURROGATE COST MATCHES FOR CONNUMS NOT PRODUCED DURING THE COST ACCOUNTING PERIOD";
        TITLE4 "PERIOD-WIDE WEIGHT AVERAGED COSTS (I.E. EXTENDED) RESTATED (I.E. DEFLATED) IN MONTH CURRENCY VALUES";
        TITLE5 "COST VARIABLE = EXTENDED COST VARIABLE * DEFLATOR";
    RUN;

    /********************************************************************************************/
    /* G-14-D-vi: Weight-average surrogate costs for CONNUMs/Months not produced in the period. */
    /********************************************************************************************/

    PROC MEANS NWAY DATA = MOST_SIMILAR_ANNUALIZED_COST NOPRINT;
        CLASS &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PROD_CONNUM NO_PROD_YEAR_MONTH;
        ID &NOPROD_CHAR COST_TYPE;
        VAR &COST_DUTY_DRAWBACK_VARIABLE VCOMCOP TCOMCOP GNACOP INTEXCOP TOTALCOP;
        WEIGHT TOTAL_PROD_QUANTITY;
        OUTPUT OUT = SIMILAR_CONNUM_COST (DROP = _:) SUMWGT = &COST_QTY
               MEAN = &COST_DUTY_DRAWBACK_VARIABLE AVGVCOM AVGTCOM AVGGNA AVGINT AVGCOST;
    RUN;

    /*********************************************************************************************************/
    /* G-14-E: Combine weight averaged costs for CONNUMs/Months sold and produced in the same CONNUMs/Months */
    /*         and produced costs for CONNUMs/Months sold but not produced in the same CONNUMs/Months        */
    /*         with surrogate costs for CONNUMs/Months not produced in the period.                           */
    /*********************************************************************************************************/

    DATA AVGCOST;
        SET IDENTICAL_CONNUM_COST
            SIMILAR_CONNUM_COST (RENAME = (&COST_MFR_HP_RENAME_BACK &COST_PRIME_HP_RENAME_BACK
                                           NO_PROD_CONNUM = &COST_MATCH
                                           NO_PROD_YEAR_MONTH = &COST_YEAR_MONTH
                                           &RENAME_NOPROD_CHAR_BACK));
    RUN;

    PROC SORT DATA = AVGCOST OUT = AVGCOST;
        BY COST_TYPE &COST_MATCH;
    RUN;

    DATA COSTCHECK (DROP = COUNT);
        SET AVGCOST;
        BY COST_TYPE &COST_MATCH;

        IF FIRST.COST_TYPE THEN
            COUNT = 0;

        COUNT + 1;

        IF COUNT LE 5;
    RUN;

    PROC PRINT DATA = COSTCHECK (OBS = &PRINTOBS);
        BY COST_TYPE;
        ID COST_TYPE;
        TITLE3 "SAMPLE OF WEIGHT-AVERAGED COST DATA BY COST TYPE";
    RUN;

     PROC SORT DATA = AVGCOST (KEEP = &COST_MANF &COST_PRIM &COST_MATCH &COST_YEAR_MONTH &COST_QTY &COST_CHAR
                                      &COST_DUTY_DRAWBACK_VARIABLE AVGVCOM AVGTCOM AVGGNA AVGINT AVGCOST COST_TYPE)
              OUT = AVGCOST;
        BY &COST_MANF &COST_PRIM &COST_MATCH &COST_YEAR_MONTH;
    RUN;
%END;
%MEND G14_HIGH_INFLATION;

/**************************************/
/* G-15: WEIGHT AVERAGE COST DATABASE */
/**************************************/

%MACRO G15_CHOOSE_COSTS;
%IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ NO %THEN 
%DO;
    %MACRO COSTDATA(PRODCHARS);
        /*------------------------------------------*/
        /* G-15-A: When costs are being calculated. */
        /*------------------------------------------*/

        %GLOBAL PRODCHAR COST_TIME_TYPE IDCHARS;

        %IF %UPCASE(&CALC_COST) = YES %THEN
        %DO;
            %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
            %DO; 
                %IF %UPCASE(&INDEX_SOURCE) NE RESP %THEN
                %DO;
                    %MACRO TIME_TYPE_FORMAT;
                        FORMAT COST_TIME_TYPE $TIMETYPE.;
                    %MEND TIME_TYPE_FORMAT;
                %END;
            %END;
            %ELSE
            %IF %UPCASE(&COMPARE_BY_TIME) = NO %THEN
            %DO;
                %MACRO TIME_TYPE_FORMAT;
                %MEND TIME_TYPE_FORMAT;
            %END;
            %ELSE
            %IF %UPCASE(&COMPARE_BY_TIME) = NO %THEN
            %DO;
                %MACRO TIME_TYPE_FORMAT;
                %MEND TIME_TYPE_FORMAT;
            %END;

            %IF %UPCASE(&FIND_SURROGATES) = NO %THEN 
            %DO;
                %MACRO IDCHARS;
                %MEND IDCHARS;
                %LET PRODCHAR = ;
                %LET COST_TIME_TYPE = ;
            %END;
            %ELSE
            %IF %UPCASE(&FIND_SURROGATES) = YES %THEN 
            %DO;
                %LET COST_TIME_TYPE = COST_TIME_TYPE;
                %IF %UPCASE(&COST_PROD_CHARS = YES) %THEN
                %DO;
                    %LET PRODCHAR = &COST_CHAR; 
                    %MACRO IDCHARS;
                        ID &COST_CHAR COST_TIME_TYPE;
                    %MEND IDCHARS;
                %END;
                %ELSE
                %IF %UPCASE(&COST_PROD_CHARS = NO) %THEN
                %DO;
                    %LET PRODCHAR = &PRODCHARS; 
                     %MACRO IDCHARS;
                         ID &COST_CHAR COST_TIME_TYPE;
                     %MEND IDCHARS;
                %END;
            %END;

            /*----------------------------------------------------*/
            /* G-15-A-i: Print a sample of the cost calculations. */
            /*----------------------------------------------------*/

            PROC PRINT DATA = COST (OBS = &PRINTOBS);
                %TIME_TYPE_FORMAT
                TITLE3 "SAMPLE OF COST CALCULATIONS BEFORE WEIGHT AVERAGING";
            RUN;

            /*--------------------------------------*/
            /* G-15-A-ii: Weight-average cost data. */
            /*--------------------------------------*/
            
            PROC MEANS NWAY DATA = COST NOPRINT;
                CLASS &COST_MANF &COST_PRIM &COST_MATCH
                      %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) = YES  %THEN
                      %DO;
                          &COST_YEAR_MONTH
                      %END; 
                      &COST_TIME_PERIOD;
                %IDCHARS
                VAR &COST_DUTY_DRAWBACK_VARIABLE VCOMCOP TCOMCOP GNACOP INTEXCOP TOTALCOP;
                WEIGHT &COST_QTY;
                OUTPUT OUT = AVGCOST (DROP = _:) SUMWGT = &COST_QTY
                       MEAN = &COST_DUTY_DRAWBACK_VARIABLE AVGVCOM AVGTCOM AVGGNA AVGINT AVGCOST;
            RUN;

            PROC PRINT DATA = AVGCOST (OBS = &PRINTOBS);
                %TIME_TYPE_FORMAT
                TITLE3 "SAMPLE OF WEIGHT-AVERAGED COST DATA";
            RUN;
        %END;
    %MEND COSTDATA;

    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %LET CALC_COST = YES;
        %COSTDATA(&HMCHAR);
    %END;
    %IF %UPCASE(&SALESDB) = USSALES %THEN
    %DO;
        %IF %UPCASE(&COST_TYPE) = HM %THEN
        %DO;
            %LET CALC_COST = NO;
            %COSTDATA(&USCHAR);
        %END;
        %IF %UPCASE(&COST_TYPE) = CV %THEN
        %DO;
            %LET CALC_COST = YES;
            %COSTDATA(&USCHAR);
        %END;
    %END;
%END;
%MEND G15_CHOOSE_COSTS;

/********************************************************/
/* G-16: FIND SURROGATE COSTS FOR PRODUCTS NOT PRODUCED */
/*       DURING PERIOD IN NON-QUARTERLY SITUATIONS      */
/********************************************************/

%MACRO G16_MATCH_NOPRODUCTION;
%IF %UPCASE(&COMPARE_BY_TIME) EQ NO AND
    %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ NO AND
    %UPCASE(&FIND_SURROGATES) = YES %THEN
%DO;
    %GLOBAL CHARNAMES_NOPROD CHARNAMES_DIF;
    %LET CHARNAMES = ;
    %LET DIFNAMES = ;

    /*-----------------------------------------------------------------------------------*/
    /* Create null values for macro variables when Cost Prime/Non-prime is not relevant. */
    /*-----------------------------------------------------------------------------------*/

    %IF %UPCASE(&COST_PRIME) EQ NA %THEN
    %DO;
        %LET AND_PRIME = ;          /* AND operator for cost prime purposes   */
        %LET EQUAL_COST_PRIME = ;   /* EQUAL operator for cost prime purposes */
        %LET LABEL_COST_PRIME = ;   /* label for cost prime                   */
        %LET NO_PROD_COST_PRIME = ; /* no production cost prime               */
    %END;
    %ELSE

    /*---------------------------------------------------------------*/
    /* Create macro variables when Cost Prime/Non-prime is relevant. */
    /*---------------------------------------------------------------*/

    %IF %UPCASE(&COST_PRIME) NE NA %THEN
    %DO;
        %IF %UPCASE(&COST_MANUF) NE NA %THEN /* When there is reported Cost Manufacturer */
        %DO;
            %LET AND_PRIME = AND;
        %END;
        %ELSE
        %IF %UPCASE(&COST_MANUF) EQ NA %THEN   /* When Cost Manufacturer is not reported */
        %DO;
            %LET AND_PRIME = ;
        %END;

        %LET EQUAL_COST_PRIME = =;
        %LET LABEL_COST_PRIME = &COST_PRIM = "SURROGATE*PRIME";
        %LET NO_PROD_COST_PRIME = NO_PROD_&COST_PRIM;
    %END;

    %LET I = 1;
    %LET CHARNAMES_NOPROD = ;
    %LET CHARNAMES_DIF = ;
    %DO %UNTIL (%SCAN(&PRODCHAR, &I, %STR( )) = %STR());
        %LET CHARNAMES_NOPROD = &CHARNAMES_NOPROD
             %SYSFUNC(COMPRESS(%SCAN(&PRODCHAR,&I,%STR( ))))_NOPROD;
        %LET CHARNAMES_DIF = &CHARNAMES_DIF
             %SYSFUNC(COMPRESS(%SCAN(&PRODCHAR,&I,%STR( ))))_DIF;
        %LET I = %EVAL(&I + 1);
    %END;

    DATA NOPRODUCTION;
        SET NOPRODUCTION;
        %LET I = 1;
        %LET RENAMECALC = ;
        %DO %UNTIL (%SCAN(&PRODCHAR, &I, %STR( )) = %STR());
            %LET RENAMECALC = &RENAMECALC
                 RENAME %SYSFUNC(COMPRESS(%SCAN(&PRODCHAR,&I,%STR( )))) 
                 = %SYSFUNC(COMPRESS(%SCAN(&CHARNAMES_NOPROD,&I,%STR( ))))%NRSTR(;); 
            %LET I = %EVAL(&I + 1);
        %END;
        &RENAMECALC
    RUN;

    PROC SORT DATA = NOPRODUCTION
              OUT = NOPRODCONNUMS NODUPKEY;
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PRODUCTION_CONNUM NOPROD_TIME_TYPE;
    RUN;

    PROC SORT DATA = COST
              OUT = COSTPRODUCTS (KEEP = &COST_MANF &COST_PRIM &COST_MATCH 
                    &PRODCHAR COST_TIME_TYPE) NODUPKEY;
         BY &COST_MANF &COST_PRIM &COST_MATCH COST_TIME_TYPE;
    RUN;

    DATA SIMCOST;
        SET NOPRODCONNUMS;
            DO J = 1 TO LAST;
                SET COSTPRODUCTS POINT = J NOBS = LAST;

                /*-----------------------------------------------------------*/
                /* Impose constraints on possible similar matches. Only find */
                /* surrogate costs when the reported and surrogate cost      */
                /* comparisons have the same manufacturers (if relevant)     */
                /* and the same prime/non-prime indicator (if relevant).     */
                /*-----------------------------------------------------------*/

    %IF &COST_MANUF NE NA OR &COST_PRIME NE NA %THEN    /* Cost Manufacturer and/or Cost Prime reported */
    %DO;
            IF &COST_MANF &EQUAL_COST_MANF &NO_PROD_COST_MANF
               &AND_PRIME &COST_PRIM &EQUAL_COST_PRIME &NO_PROD_COST_PRIME THEN
            DO;
    %END;
                    ARRAY NOPROD (*) &CHARNAMES_NOPROD;
                    ARRAY COSTPROD (*) &PRODCHAR;
                    ARRAY DIFCHR (*) &CHARNAMES_DIF;

                    DO I = 1 TO DIM(DIFCHR);
                        DIFCHR(I) = ABS(NOPROD(I) - COSTPROD(I));
                    END;
                    DROP I;
                    COST_TYPE = 'SG';
                    FORMAT COST_TYPE $TIMETYPE.;

                    OUTPUT SIMCOST;

    %IF &COST_MANUF NE NA OR &COST_PRIME NE NA %THEN    /* Cost Manufacturer and/or Cost Prime reported */
    %DO;
            END;
    %END;

        END;
    RUN;

    PROC SORT DATA = SIMCOST OUT = SIMCOST;
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PRODUCTION_CONNUM &CHARNAMES_DIF;
    RUN;

    DATA SIMCOST SIMCOST_TS (DROP = &CHARNAMES_DIF NOPROD_TIME_TYPE COST_TIME_TYPE) 
         SIMCOST_AN (DROP = &CHARNAMES_DIF NOPROD_TIME_TYPE COST_TIME_TYPE)
         TOP5SIMCOST;
         SET SIMCOST;
         BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PRODUCTION_CONNUM &CHARNAMES_DIF;
         IF FIRST.NO_PRODUCTION_CONNUM THEN
                CHOICE = 0;
            CHOICE + 1;
            IF CHOICE = 1 THEN 
            DO;
                OUTPUT SIMCOST;
                IF NOPROD_TIME_TYPE IN("AN", "NA") THEN
                    OUTPUT SIMCOST_AN;
                ELSE OUTPUT SIMCOST_TS;
            END; 
            IF CHOICE LE 5 THEN
                OUTPUT TOP5SIMCOST; 
    RUN;

    PROC PRINT DATA = TOP5SIMCOST (OBS = &PRINTOBS) NOOBS;
        BY &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PRODUCTION_CONNUM;
        FORMAT NOPROD_TIME_TYPE COST_TIME_TYPE $TIMETYPE.;
        VAR CHOICE &COST_MANF &COST_PRIM &COST_MATCH NOPROD_TIME_TYPE 
            COST_TIME_TYPE &CHARNAMES_NOPROD &PRODCHAR &CHARNAMES_DIF;
        TITLE3 "TOP FIVE SIMILAR MATCHES FOR SURROGATE COSTS";
    RUN;

    PROC PRINT DATA = SIMCOST (OBS = &PRINTOBS) SPLIT = '*';
        VAR &NO_PROD_COST_MANF &NO_PROD_COST_PRIME NO_PRODUCTION_CONNUM
            &COST_MANF &COST_PRIM &COST_MATCH NOPROD_TIME_TYPE 
            COST_TIME_TYPE &CHARNAMES_NOPROD &PRODCHAR &CHARNAMES_DIF;
        LABEL &LABEL_COST_MANF
              &LABEL_COST_PRIME
              &COST_MATCH = "SURROGATE*CONNUM";
        FORMAT NOPROD_TIME_TYPE COST_TIME_TYPE $TIMETYPE.;
        TITLE3 "SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING THE COST ACCOUNTING PERIOD";
    RUN;

    %LET SIMCOSTTIME = ;

    DATA SIMCOSTALLTIME;
        SET &SIMCOSTTIME SIMCOST_AN;
    RUN;

    DATA AVGCOST;
        SET AVGCOST;
        COST_TYPE = 'CA';
        FORMAT COST_TYPE $TIMETYPE.;
    RUN;

    PROC SORT DATA = AVGCOST OUT = AVGCOST;
        BY COST_TYPE &COST_MANF &COST_PRIM &COST_MATCH;
    RUN;

    PROC SORT DATA = SIMCOSTALLTIME (KEEP = &NO_PROD_COST_MANF &NO_PROD_COST_PRIME 
                                            NO_PRODUCTION_CONNUM &COST_MANF &COST_PRIM 
                                            &COST_MATCH COST_TYPE &COST_TIME_PERIOD)
              OUT = SIMCOSTALLTIME;
        BY &COST_MANF &COST_PRIM &COST_MATCH &COST_TIME_PERIOD;
    RUN;

    DATA NOPRODUCTION (DROP = &COST_MANF &COST_PRIM &COST_MATCH);
        MERGE SIMCOSTALLTIME (IN = A) AVGCOST (IN = B DROP = COST_TYPE);
        BY &COST_MANF &COST_PRIM &COST_MATCH &COST_TIME_PERIOD;
        IF A & B;
    RUN;

    %IF %UPCASE(&COST_PROD_CHARS) = YES %THEN
    %DO;
        DATA AVGCOST (DROP = &PRODCHAR);
    %END;
    %ELSE
    %IF %UPCASE(&COST_PROD_CHARS) = NO %THEN
    %DO;
        DATA AVGCOST;
    %END;
               
        SET AVGCOST NOPRODUCTION
                   (RENAME = (&NO_PROD_COST_MANF &EQUAL_COST_MANF &COST_MANF
                              &NO_PROD_COST_PRIME &EQUAL_COST_PRIME &COST_PRIM
                              NO_PRODUCTION_CONNUM = &COST_MATCH));
    RUN;

    /* End of section finding similar costs for products with no production during the period. */

    PROC SORT DATA = AVGCOST OUT = AVGCOST;
        BY COST_TYPE &COST_MANF &COST_PRIM &COST_MATCH;
    RUN;

    DATA COSTCHECK (DROP = COUNT);
        SET AVGCOST;
        BY COST_TYPE &COST_MANF &COST_PRIM &COST_MATCH;
        IF FIRST.COST_TYPE THEN
            COUNT = 0;
        COUNT + 1;
        IF COUNT LE 10;
    RUN;

    PROC PRINT DATA = COSTCHECK (OBS = &PRINTOBS);
        BY COST_TYPE;
        ID COST_TYPE;
        TITLE3 "SAMPLE OF COST COMPONENT CALCULATIONS FOR CALCULATED AND SURROGATE COSTS";
    RUN;
%END; 
%MEND G16_MATCH_NOPRODUCTION;

/************************************************************/
/* G-17: MERGE COST DATA WITH SALES DATA. SAVE DATA FROM    */
/*       CM PROGRAM FOR USE WITH U.S. SALES, WHEN REQUIRED. */
/************************************************************/
  
%MACRO G17_FINALIZE_COSTDATA;
    %MACRO MERGE_COST(SALES, SALES_MATCH, SALES_TIME, COSTDB);
        %GLOBAL COST_YEAR_MONTH RENAME_YEAR_MONTH SALES_YEAR_MONTH;        /* 3 macro variables */
        %LET RENAME_YEAR_MONTH = ; /* rename Cost year/month code for merging with CM year/cost */
        %LET SALES_YEAR_MONTH = ;  /* CM sales year/month for merging with Cost                 */

        %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) NE YES %THEN
        %DO;
            %LET COST_YEAR_MONTH = ;   /* Cost year/month for merging with Cost                 */
        %END;
        %ELSE
        %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
        %DO;
            %IF %UPCASE(&SALESDB) = HMSALES OR %UPCASE(&SALESDB) = DOWNSTREAM %THEN
            %DO;
                  %LET RENAME_YEAR_MONTH = &COST_YEAR_MONTH = YEARMONTHH;
                  %LET SALES_YEAR_MONTH = YEARMONTHH;
            %END;
            %ELSE
            %IF %UPCASE(&SALESDB) = USSALES OR %UPCASE(&SALESDB) = CV %THEN
            %DO;
                  %LET RENAME_YEAR_MONTH = &COST_YEAR_MONTH = YEARMONTHU;
                  %LET SALES_YEAR_MONTH = YEARMONTHU;
            %END;
        %END;

        %IF %UPCASE(&SALESDB) = USSALES %THEN 
        %DO;
            %IF %UPCASE(&COST_TYPE) = CM %THEN
            %DO;                                   /* Define Cost CONNUM in Cost data */
                %LET COST_MATCH = COST_MATCH;      /* set created by the CM program.  */ 
            %END;
        %END;

        PROC SORT DATA = &SALES OUT = &SALES;    
            BY &SALES_COST_MANF &SALES_COST_PRIME &SALES_MATCH &SALES_YEAR_MONTH &SALES_TIME;
        RUN;

        PROC SORT DATA = &COSTDB OUT = AVGCOST;
            BY &COST_MANF &COST_PRIM &COST_MATCH
               &COST_YEAR_MONTH &COST_TIME_PERIOD;
        RUN;

        DATA &SALES NOCOST_&SALES;
        MERGE &SALES (IN = A)
              AVGCOST (IN = B RENAME = (&COST_MANF &EQUAL_COST_MANF &SALES_COST_MANF 
                                        &COST_PRIM &EQUAL_COST_PRIME &SALES_COST_PRIME
                                        &COST_MATCH = &SALES_MATCH
                                        &RENAME_YEAR_MONTH
                                        &COST_TIME_PERIOD &EQUAL_TIME &SALES_TIME));
            BY &SALES_COST_MANF &SALES_COST_PRIME &SALES_MATCH &SALES_YEAR_MONTH &SALES_TIME;
            IF A AND B THEN
                OUTPUT &SALES;
            ELSE
            IF A & NOT B THEN
                OUTPUT NOCOST_&SALES;
        RUN;

        PROC PRINT DATA = NOCOST_&SALES (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF &SALES SALES WITH NO COSTS";
        RUN;
    %MEND MERGE_COST;
    
    %IF %UPCASE(&SALESDB) = HMSALES %THEN 
    %DO;
        %MERGE_COST(HMSALES, &HMCPPROD, &HM_TIME_PERIOD, AVGCOST);

        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST 
             (RENAME = (&COST_MANF &EQUAL_COST_MANF &COP_MANF_OUT
                        &COST_PRIM &EQUAL_COST_PRIME &COP_PRIME_OUT
                        &COST_MATCH = COST_MATCH
                        &COST_TIME_PERIOD &EQUAL_TIME &COP_TIME_OUT
                        &COST_QTY = COST_QTY));
            SET AVGCOST;
        RUN;
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN 
    %DO;
        %MERGE_COST(DOWNSTREAM, &HMCPPROD, &HM_TIME_PERIOD, AVGCOST);
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = USSALES %THEN 
    %DO;
        %IF %UPCASE(&COST_TYPE) = CM %THEN
        %DO;
            %MERGE_COST(USSALES, &USCVPROD, &US_TIME_PERIOD, 
                        COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST);
        %END;
        %ELSE
        %IF %UPCASE(&COST_TYPE) = CV %THEN
        %DO;
            %MERGE_COST(USSALES, &USCVPROD, &US_TIME_PERIOD, AVGCOST);
        %END;
    %END;
%MEND G17_FINALIZE_COSTDATA;

/********************************************/
/* G18: DELETE ALL WORK FILES IN SAS BUFFER */
/********************************************/

%MACRO G18_DEL_ALL_WORK_FILES;
    %IF &DEL_WORKFILES = YES %THEN
    %DO;
        PROC DATASETS LIBRARY = WORK NOLIST KILL;
        QUIT;
    %END;
%MEND G18_DEL_ALL_WORK_FILES;

/***********************************/
/* G19: CALCULATE PROGRAM RUN TIME */
/***********************************/

%MACRO G19_PROGRAM_RUNTIME;
    %IF &CALC_RUNTIME = YES %THEN
    %DO;
        DATA _NULL_;
            CALL SYMPUT('ETIME', PUT(TIME(), TIME5.));
            CALL SYMPUT('EDATE', PUT(DATE(), DATE.));
            CALL SYMPUT('EWDATE', TRIM(LEFT(PUT(DATE(), WORDDATE18.))));
            CALL SYMPUT('EDAY', TRIM(LEFT(PUT(DATE(), DOWNAME.))));
        RUN;

        DATA _NULL_;
            B_DATE = INPUT("&BDATE", DATE.);
            B_TIME = INPUT("&BTIME", TIME5.);
            E_DATE = INPUT("&EDATE", DATE.);
            E_TIME = INPUT("&ETIME", TIME5.);

            IF B_DATE = E_DATE THEN
                TOT_TIME = E_TIME - B_TIME;
            ELSE
            TOT_TIME = (86400 - B_TIME) + E_TIME;
             CALL SYMPUT('TTIME', PUT(TOT_TIME, TIME5.));
        RUN;

        %PUT NOTE: This program finished running on &EDAY, &EWDATE - &ETIME.;
        %PUT NOTE: This program took &TTIME (hours:minutes) to run.;
    %END;
%MEND G19_PROGRAM_RUNTIME;

/**********************************************************************/
/* HM-1:  CREATE MACROS AND MACRO VARIABLES REGARDING PRIME/NON-PRIME */
/*        MERCHANDISE AND MANUFACTURER DESIGNATION                    */
/**********************************************************************/

%MACRO HM1_PRIME_MANUF_MACROS;
    %GLOBAL AND_COST_BOTH AND_COST_PRIME AND_PRIME AND_SALES_MANF                  /* 30 macro variables */
            AND_SALES_PRIME COP_MANF_OUT COP_PRIME_OUT COST_MANF 
            COST_PRIM EITHER_COST_BOTH EQUAL_COST_MANF
            EQUAL_COST_PRIME EQUAL_PRIME EQUAL_SALES_MANF FIRST_COST_MANF 
            FIRST_NOPROD_MFR HMMANF HMPRIM LABEL_COST_MANF MANF_LABEL
            NO_PROD_COST_MANF NO_PROD_COST_PRIME NV_TYPE PRIME_LABEL 
            PRIME_TITLE SALES_COST_MANF SALES_COST_PRIME US_SALES_COST_MANF;

    /*-----------------------------------------------------------------*/
    /* Define macro variables and set their default values to nothing. */
    /*-----------------------------------------------------------------*/

    %LET AND_COST_BOTH = ;       /* AND operator when there is reported Cost manufacturer and Cost prime */
    %LET AND_COST_PRIME = ;      /* AND operator for cost prime purposes                                 */
    %LET AND_PRIME = ;           /* AND operator for prime purposes                                      */
    %LET AND_SALES_MANF = ;      /* AND operator for CM sales manufacturer purposes                      */
    %LET AND_SALES_PRIME = ;     /* AND operator for CM sales prime purposes                             */
    %LET COP_MANF_OUT = ;        /* Cost manufacturer variable for output cost dataset                   */
    %LET COP_PRIME_OUT = ;       /* Cost prime variable for output cost dataset                          */
    %LET COST_MANF = ;           /* Cost manufacturer for merging with CM sales                          */
    %LET COST_PRIM = ;           /* Cost prime variable                                                  */
    %LET EITHER_COST_BOTH = ;    /* And operator when there is reported Cost manufacturer or Cost prime  */
    %LET EQUAL_COST_MANF = ;     /* EQUAL operator for Cost manufacturer purposes                        */
    %LET EQUAL_COST_PRIME = ;    /* EQUAL operator for Cost prime purposes                               */
    %LET EQUAL_PRIME = ;         /* EQUAL operator for prime purposes                                    */
    %LET EQUAL_SALES_MANF = ;    /* EQUAL operator for CM sales manufacturer purposes                    */
    %LET FIRST_COST_MANF = ;     /* FIRST. language for Cost manufacturer                                */
    %LET FIRST_NOPROD_MFR = ;    /* FIRST. language no production manufacturer variable                  */
    %LET HMMANF = ;              /* Manufacturer for CM sales data                                       */
    %LET HMPRIM = ;              /* prime code for sales data                                            */
    %LET LABEL_COST_MANF = ;     /* label for Cost manufacturer variable                                 */
    %LET MANF_LABEL = ;          /* label for CM sales manufacturer                                      */
    %LET NO_PROD_COST_MANF = ;   /* No production Cost manufacturer variable                             */
    %LET NO_PROD_COST_PRIME = ;  /* No production Cost prime variable                                    */
    %LET PRIME_LABEL = ;         /* printing label for prime code                                        */
    %LET PRIME_TITLE = ;         /* prime v nonprime text for titles                                     */
    %LET SALES_COST_MANF = ;     /* CM sales manufacturer for merging with Cost                          */
    %LET SALES_COST_PRIME = ;    /* CM sales prime for merging with Cost                                 */
    %LET US_SALES_COST_MANF = ;  /* U.S. sales Cost manufacturer for merging with Cost manufacturer      */

    /* The macro variable NV_TYPE is defined in the Margin Program. NV_TYPE is set to blank here so that */
    /* in quarterly cost cases if the CM and Margin programs are run more than one time, the &NV_TYPE    */
    /* will not affect the CM program.                                                                   */

    %LET NV_TYPE = ; 

    /*------------------------------------------------------------------------------------*/
    /* Create null values for macro variables when CM sales manufacturer is not relevant. */
    /*------------------------------------------------------------------------------------*/

    %IF %UPCASE(&HMMANUF) NE NA %THEN            /* When there is reported CM manufacturer */
    %DO; 
        %LET AND_SALES_MANF = AND ;
        %LET EQUAL_SALES_MANF = = ;
        %LET HMMANF = &HMMANUF;
        %LET MANF_LABEL = &HMMANF = "MANUFACTURER*CODE*============" ;

        %IF %UPCASE(&COST_MANUF) NE NA %THEN   /* When there is reported Cost manufacturer */
        %DO; 
            %LET COP_MANF_OUT = COST_MANUF; 
            %LET COST_MANF = &COST_MANUF;
            %LET EQUAL_COST_MANF = = ;
            %LET FIRST_COST_MANF = FIRST.&&COST_MANF;
            %LET FIRST_NOPROD_MFR = FIRST.&&NO_PROD_COST_MANF;
            %LET LABEL_COST_MANF = &COST_MANUF = "SURROGATE*MANUFACTURER";
            %LET NO_PROD_COST_MANF = NOPROD_&COST_MANF;
            %LET SALES_COST_MANF = &HMMANUF;
            %LET US_SALES_COST_MANF = &USMANF;
        %END;
    %END;

    /*--------------------------------------------------------------------------------*/
    /* Create null macro variables and macro when CM Prime/Non-prime is not relevant. */
    /*--------------------------------------------------------------------------------*/

    %IF %UPCASE(&HMPRIME) EQ NA %THEN   /* When there is no reported CM prime */
    %DO;
        %MACRO PRIME_PRINT;       /* printing instructions for prime          */ 
        %MEND PRIME_PRINT;
    %END;

    /*------------------------------------------------------------------------*/
    /*  Create macro variables and macro when CM Prime/Non-prime is relevant. */
    /*------------------------------------------------------------------------*/

    %ELSE
    %IF %UPCASE(&HMPRIME) NE NA %THEN      /* When there is reported CM prime */
    %DO;                                
        %LET AND_PRIME = AND;
        %LET AND_SALES_PRIME = AND;
        %LET EQUAL_PRIME = = ;
        %LET HMPRIM = &HMPRIME;
        %LET PRIME_LABEL = &HMPRIM = "PRIME/NON-PRIME*QUALITY MERCHANDISE*============";
        %LET PRIME_TITLE = PRIME/NON-PRIME;
        %MACRO PRIME_PRINT;
            BY &HMPRIM;
            ID &HMPRIM;
            SUMBY &HMPRIM;
            PAGEBY &HMPRIM;
        %MEND PRIME_PRINT;

        /*---------------------------------------------------------------*/
        /* Create macro variables when Cost Prime/Non-prime is relevant. */
        /*---------------------------------------------------------------*/

        %IF %UPCASE(&COST_PRIME) NE NA %THEN     /* When there is reported Cost prime */
        %DO;
            %LET AND_COST_PRIME = AND;
            %LET COP_PRIME_OUT = COST_PRIME; 
            %LET COST_PRIM = &COST_PRIME;
            %LET EQUAL_COST_PRIME = = ;
            %LET SALES_COST_PRIME = &HMPRIME;
            %LET NO_PROD_COST_PRIME = NOPROD_&COST_PRIM;
        %END;
    %END;

    /*-----------------------------------------------------------------------*/
    /* Assign macro variables value for condtional contraint surrogate cost  */
    /* matching language when Cost manufacturer and Cost prime are relavent. */
    /*-----------------------------------------------------------------------*/

    %IF %UPCASE(&COST_MANUF) NE NA AND %UPCASE(&COST_PRIME) NE NA %THEN /* When there is reported Cost mfr and Cost prime */
    %DO;                                
        %LET AND_COST_BOTH = AND;
    %END;

    /*----------------------------------------------------------------------*/
    /* Assign macro variables value for condtional contraint surrogate cost */
    /* matching language when Cost manufacturer or Cost prime are relavent. */
    /*----------------------------------------------------------------------*/

    %IF %UPCASE(&COST_MANUF) NE NA OR %UPCASE(&COST_PRIME) NE NA %THEN /* When there is reported Cost mfr and/or Cost prime */
    %DO;                                
        %LET AND_COST_BOTH = AND;
    %END;
%MEND HM1_PRIME_MANUF_MACROS;

/**********************************************************************/
/* HM2: SPLIT MIXED-CURRENCY VARIABLES INTO SINGLE-CURRENCY VARIABLES */
/**********************************************************************/

%MACRO HM2_MIXEDCURR(SALES);
    %IF %UPCASE(&MIXEDCURR) = YES %THEN
    %DO;
        %GLOBAL SPLITNAME_&CUR1 SPLITNAME_&CUR2 SPLITNAME_&CUR3 ;
        %LET SPLITNAME_&CUR1 = ;
        %LET SPLITNAME_&CUR2 = ;
        %LET SPLITNAME_&CUR3 = ;

        DATA &SALES;
            SET &SALES;

            %MACRO SPLIT_CURR(CUR);
                %IF %UPCASE(&CUR) NE NA %THEN
                %DO;
                    %LET I = 1;
                    %LET SPLITCALC = ;
                    %LET SPLITNAME = ;
                        %DO %UNTIL (%SCAN(&MIXEDVARS, &I, %STR( )) = %STR());
                            %LET SPLITCALC = &SPLITCALC
                            %SYSFUNC(COMPRESS(%SCAN(&MIXEDVARS,&I,%STR( ))))_&CUR = 0%NRSTR(;) 
                            IF &CURRTYPE = "&CUR." THEN %SYSFUNC(COMPRESS(%SCAN(&MIXEDVARS,&I,%STR( ))))_&CUR 
                                = %SYSFUNC(COMPRESS(%SCAN(&MIXEDVARS,&I,%STR( )))) %NRSTR(;);
                            &SPLITCALC
                            %LET SPLITNAME = &SPLITNAME
                            %SYSFUNC(COMPRESS(%SCAN(&MIXEDVARS,&I,%STR( ))))_&CUR;
                            %LET I = %EVAL(&I + 1);
                        %END;
                    %LET SPLITNAME_&CUR = &SPLITNAME;
                %END;
            %MEND SPLIT_CURR;

            %SPLIT_CURR(&CUR1);
            %SPLIT_CURR(&CUR2);
            %SPLIT_CURR(&CUR3);
        RUN;

        PROC SORT DATA = &SALES OUT = CURRALL;
            BY &CURRTYPE;
        RUN;

        DATA CURRALL;
            SET CURRALL;
            BY &CURRTYPE;
            IF FIRST.&CURRTYPE THEN
                COUNT = 0;
            COUNT + 1;
            IF COUNT LE 10 THEN
                OUTPUT CURRALL;
        RUN;

        PROC PRINT DATA = CURRALL;
            BY &CURRTYPE;
            ID &CURRTYPE;
            VAR &MIXEDVARS &CURRTYPE &&SPLITNAME_&CUR1 &&SPLITNAME_&CUR2 &&SPLITNAME_&CUR3;
            TITLE3 "SPLITTING OF MIXED-CURRENCY VARIABLES INTO SINGLE-CURRENCY VARIABLES IN &SALES";
        RUN;
    %END;
%MEND HM2_MIXEDCURR;

/****************************************************/
/* HM-3: ARMS-LENGTH TEST OF AFFILIATED PARTY SALES */
/****************************************************/

%MACRO HM3_ARMSLENGTH;
    %IF %UPCASE(&RUN_ARMSLENGTH) = YES %THEN
    %DO;
        /*--------------------------------------------*/
        /* Create the macro variables, as needed, for */
        /* non-affiliated, manufacturer, and prime.   */
        /*--------------------------------------------*/
    
        %GLOBAL NAFMANF NAFMANF_DEF NAFPRIME NAFPRIME_DEF
                CHK4SIM NAFVCOM_DEF MAKE_NAFCHARS NAFCHAR DIFCHAR;

        %IF %UPCASE(&HMMANUF) = NA %THEN    /* Create null values when manufacturer is not relevant. */
        %DO;
            %LET NAFMANF = ;
            %MACRO NAFMANF_DEF;
            %MEND NAFMANF_DEF;
        %END;
        %ELSE
        %IF %UPCASE(&HMMANUF) NE NA %THEN   /* Create values when manufacturer is relevant. */
        %DO;
            %LET NAFMANF = NAFMANF;
            %MACRO NAFMANF_DEF;
                NAFMANF = &HMMANF;
            %MEND NAFMANF_DEF;
        %END;

        %IF %UPCASE(&HMPRIME) = NA %THEN    /* Create null values when prime/non-prime is not relevant. */
        %DO;
            %LET NAFPRIME = ;
                %MACRO NAFPRIME_DEF;
                %MEND NAFPRIME_DEF;
        %END;
        %ELSE
        %IF %UPCASE(&HMPRIME) NE NA %THEN   /* Create null values when prime/non-prime is relevant. */ 
        %DO;                 
            %LET NAFPRIME = NAFPRIME;
            %MACRO NAFPRIME_DEF;
                NAFPRIME = &HMPRIM; 
            %MEND NAFPRIME_DEF;
        %END;

        /*-----------------------------------------------------------------*/
        /* Create the macro variables for cost items for similar matching. */
        /*-----------------------------------------------------------------*/

        %LET CHK4SIM = YES;
        %MACRO NAFVCOM_DEF;
            RENAME AVGVCOM = NAFVCOM;
        %MEND NAFVCOM_DEF;
        %MACRO MAKE_NAFCHARS;
            %LET I = 1;
            %LET RENAMENAF = ;
            %LET NAFCHAR = ;
            %LET DIFCHAR = ;
            %DO %UNTIL (%SCAN(&HMCHAR, &I, %STR( )) = %STR());
                %LET RENAMENAF = &RENAMENAF RENAME
                     %SYSFUNC(COMPRESS(%SCAN(&HMCHAR,&I,%STR( )))) 
                     = %SYSFUNC(COMPRESS(%SCAN(&HMCHAR,&I,%STR( ))))_NAF %NRSTR(;); 
                &RENAMENAF
                %LET NAFCHAR = &NAFCHAR
                %SYSFUNC(COMPRESS(%SCAN(&HMCHAR,&I,%STR( ))))_NAF;
                %LET DIFCHAR = &DIFCHAR
                    %SYSFUNC(COMPRESS(%SCAN(&HMCHAR,&I,%STR( ))))_DIF;
                %LET I = %EVAL(&I + 1);
            %END;
        %MEND MAKE_NAFCHARS;
    
        DATA HMAFF (KEEP = &HMCUST &HMCONNUM &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD
                           &HMQTY HMNETPRI AVGVCOM AVGTCOM &HMCHAR)
             HMNAF (KEEP = &HMCONNUM HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMQTY
                           HMNETPRI &NAF_TIME_PERIOD NAFCONN NAFLOT
                           AVGVCOM &NAFMANF &NAFPRIME &HMCHAR);
            SET HMSALES;
            IF &HMAFFL = &NAFVALUE THEN
            DO;
                NAFCONN = &HMCONNUM;
                NAFLOT = HMLOT;
                %NAFMANF_DEF 
                %NAFPRIME_DEF  
                &NAF_TIME_PERIOD &EQUAL_TIME &HM_TIME_PERIOD;
                OUTPUT HMNAF;
            END;
            ELSE
                 OUTPUT HMAFF;
        RUN;

        DATA HMNAF;
            SET HMNAF;
            %NAFVCOM_DEF;
            %MAKE_NAFCHARS;
        RUN;

        /*-------------------------------------------*/
        /* HM3-A: Check Customer Affiliation and LOT */
        /*-------------------------------------------*/

        PROC MEANS NWAY DATA = HMSALES NOPRINT;
            CLASS &HMAFFL HMLOT &HMMANF &HMPRIM ;
            VAR &HMQTY;
            OUTPUT OUT = TOTS (DROP = _:)
                   N = SALES SUM = TOTQTY;
        RUN;

        PROC SORT DATA = HMSALES OUT = NUMCUST NODUPKEY;
            BY &HMAFFL HMLOT &HMMANF &HMPRIM &HMCUST;
        RUN;
 
        PROC SUMMARY DATA = NUMCUST NOPRINT;
            BY &HMAFFL HMLOT &HMMANF &HMPRIM;
            OUTPUT OUT = NUMCUST (DROP = _TYPE_);
        RUN;

        DATA TOTCUST;
            MERGE TOTS NUMCUST (RENAME = (_FREQ_ = NCUST));
            BY &HMAFFL HMLOT &HMMANF &HMPRIM;
        RUN;

        PROC PRINT DATA = TOTCUST SPLIT = '*';
            VAR &HMAFFL HMLOT &HMMANF &HMPRIM NCUST SALES TOTQTY;
            SUM NCUST SALES TOTQTY;
            FORMAT SALES COMMA7. TOTQTY COMMA12.;
            LABEL &HMAFFL  = "CUSTOMER *AFFILIATION*==========="
                  HMLOT    = "LEVEL(S)*OF TRADE*========"
                  &MANF_LABEL
                  &PRIME_LABEL 
                  NCUST    = "NUMBER OF*CUSTOMERS*========="
                  SALES    = "TOTAL*SALES*======="
                  TOTQTY   = "TOTAL *QUANTITY*=========="; 
            TITLE3 "SUMMARY OF CUSTOMER AFFILIATION & LOT";
        RUN;

        /*------------------------------------------------------------*/
        /* HM3-B: Weighted-average net prices of affiliated customers */
        /*------------------------------------------------------------*/

        PROC MEANS NWAY DATA = HMAFF NOPRINT;
            CLASS &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            ID AVGVCOM AVGTCOM &HMCHAR;
            VAR HMNETPRI;
            WEIGHT &HMQTY;
            OUTPUT OUT = TOTAFF (DROP = _:)
                   N = AFFOBS SUMWGT = AFFQTY MEAN = AFFNETPR;
        RUN;

        PROC PRINT DATA = TOTAFF (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF AFFILIATED WEIGHTED-AVERAGE NET PRICES";
        RUN;

        PROC SORT DATA = TOTAFF OUT = TOTAFF;
            BY HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM &HMCUST;
        RUN;

        /*--------------------------------------------------------------*/
        /* HM3-C: Weight-average net prices of non-affiliated customers */
        /*--------------------------------------------------------------*/
   
        PROC MEANS NWAY DATA = HMNAF NOPRINT;
            CLASS HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            ID NAFLOT &NAFMANF &NAFPRIME &NAF_TIME_PERIOD NAFCONN NAFVCOM &NAFCHAR;
            VAR HMNETPRI;
            WEIGHT &HMQTY;
            OUTPUT OUT = TOTNAF (DROP = _:)
                   N = NAFOBS SUMWGT = NAFQTY MEAN = NAFNETPR;
        RUN;

        PROC PRINT DATA = TOTNAF (OBS = &PRINTOBS);
            VAR NAFLOT &NAFMANF &NAFPRIME &NAF_TIME_PERIOD NAFCONN &NAFCHAR NAFNETPR NAFQTY NAFVCOM;
            TITLE3 "SAMPLE OF UNAFFILIATED WEIGHTED-AVERAGE NET PRICES";
        RUN;

        /*-----------------------------------------------------------*/
        /* HM3-D: Identify identical product matches at the same LOT */
        /*-----------------------------------------------------------*/

        DATA ALLCOMP NOCOMP;
            MERGE TOTAFF (IN = A) TOTNAF (IN = B);
            BY HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            IF A AND B THEN
            DO;
                NAFADJPR = NAFNETPR;
                MATCH    = 'IDENTICAL';
                DIFMER   = 0;
                COSTDIFF = 0;
                OUTPUT ALLCOMP;
            END;
            ELSE
            IF A & NOT B THEN
                OUTPUT NOCOMP;
        RUN;

        /*------------------------------------------------*/
        /* HM3-E: Identify similar product matches at the */
        /* same LOT only if cost data are available.      */
        /*------------------------------------------------*/

        %MACRO HM3_SIM;
            %IF &CHK4SIM = YES %THEN
            %DO;
                DATA SIMMATCH;
                    SET NOCOMP;

                    DO J = 1 TO LAST;
                        SET TOTNAF (DROP = HMLOT &HMMANF &HMPRIM
                                           &HM_TIME_PERIOD &HMCONNUM)  
                        POINT = J NOBS = LAST;
                        LOTDIFF = ABS(NAFLOT - HMLOT);
                        IF AVGVCOM GT .  AND NAFVCOM GT . THEN
                            DIFMER = NAFVCOM - AVGVCOM;
                        ELSE
                            DIFMER = .;

                        IF DIFMER GT . THEN
                            COSTDIFF = ABS(DIFMER / AVGTCOM);
                        ELSE
                            COSTDIFF = .;

                        /*--------------------------------------------------*/
                        /* HM3-F Examine all product matches within the 20% */
                        /*       DIFMER test and at the same LOT.           */ 
                        /*--------------------------------------------------*/ 

                        IF 0.20 GE COSTDIFF GT . & LOTDIFF  = 0 
                           &AND_SALES_MANF &NAFMANF &EQUAL_SALES_MANF &HMMANF 
                           &AND_SALES_PRIME &NAFPRIME &EQUAL_PRIME &HMPRIM 
                           &AND_TIME &HM_TIME_PERIOD &EQUAL_TIME &NAF_TIME_PERIOD THEN
                        DO;
                            /*-----------------------------------------*/
                            /* HM3-G: Select similar products based on */
                            /*        product characteristics.         */
                            /*-----------------------------------------*/

                            ARRAY AFFCHR (*) &HMCHAR;
                            ARRAY NAFCHR (*) &NAFCHAR;
                            ARRAY DIFCHR (*) &DIFCHAR;
                            DO I = 1 TO DIM(DIFCHR);
                                DIFCHR(I) = ABS(AFFCHR(I) - NAFCHR(I));
                            END;
                            DROP I;
                            MATCH = 'SIMILAR';
                            NAFADJPR = NAFNETPR - DIFMER;
                            OUTPUT SIMMATCH;
                        END;
                    END;
                RUN;

                PROC SORT DATA = SIMMATCH OUT = SIMMATCH;
                    BY HMLOT &HMMANF &HMPRIM &HMCUST &HM_TIME_PERIOD &HMCONNUM
                        MATCH &DIFCHAR LOTDIFF COSTDIFF;
                RUN;

                DATA SIMCOMP (DROP = &DIFCHAR) TOP5SIM;
                    SET SIMMATCH;
                    BY HMLOT &HMMANF &HMPRIM &HMCUST &HM_TIME_PERIOD &HMCONNUM
                       MATCH &DIFCHAR LOTDIFF COSTDIFF;

                    DIFCODE = CATX("-", OF &DIFCHAR);         
                    IF FIRST.&HMCONNUM THEN
                        CHOICE = 0;

                    CHOICE + 1;

                    IF CHOICE = 1 THEN
                        OUTPUT SIMCOMP;
                    IF CHOICE LE 5 THEN
                        OUTPUT TOP5SIM;
                    RUN;

                PROC DATASETS LIBRARY = WORK NOLIST;
                    DELETE SIMMATCH;
                QUIT;

                PROC PRINT DATA = TOP5SIM (OBS = 15);
                    BY HMLOT &HMMANF &HMPRIM &HMCUST &HM_TIME_PERIOD &HMCONNUM;
                    PAGEBY &HMCONNUM;
                    VAR &HMCHAR NAFLOT &NAF_TIME_PERIOD NAFCONN &NAFCHAR  
                        AVGVCOM AVGTCOM NAFVCOM DIFMER
                        MATCH DIFCODE LOTDIFF COSTDIFF CHOICE;
                    TITLE3 "CHECK TOP 5 SIMILAR MATCHES (NAFADJPR INCLUDES DIFMER)";
                RUN;

                /*-----------------------------------------------*/
                /* HM3-H: Combine identical and similar matches. */
                /*-----------------------------------------------*/
    
                DATA ALLCOMP;
                    SET ALLCOMP SIMCOMP;
                    DROP LOTDIFF DIFCODE CHOICE;
                RUN;
            %END;
        %MEND HM3_SIM;

        %HM3_SIM;

        /*-------------------------------------------------------------------*/
        /* HM3-I: For each product sold to an affiliate with an identical or */
        /* similar match, calculate the percent ratio (PCTRATIO) of          */
        /* the weighted-average affiliated price to the weighted-average     */
        /* non-affiliated price.                                             */
        /*-------------------------------------------------------------------*/

        PROC SORT DATA = TOTAFF OUT = TOTAFF; 
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
        RUN;

        PROC SORT DATA = ALLCOMP OUT = ALLCOMP;
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
        RUN;
 
        DATA ALLCOMP;
            MERGE TOTAFF (IN = A) ALLCOMP;
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            IF A;

            IF MATCH = '' THEN
                MATCH = 'NONE';

            IF NAFADJPR = . THEN
                PCTRATIO = .;
            ELSE
                PCTRATIO = (AFFNETPR / NAFADJPR) * 100;
            RUN;

        PROC SORT DATA = ALLCOMP OUT = ALLCOMP;
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
        RUN;

        PROC PRINT DATA = ALLCOMP (OBS = &PRINTOBS); 
            BY &HMCUST;
            ID &HMCUST;
            VAR HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM 
                AFFOBS AFFQTY AFFNETPR AVGVCOM AVGTCOM 
                NAFLOT &NAF_TIME_PERIOD NAFCONN NAFOBS NAFQTY NAFNETPR NAFVCOM 
                MATCH DIFMER COSTDIFF NAFADJPR PCTRATIO; 
            TITLE3 "SAMPLE RATIOS OF AFFILIATED TO UNAFFILIATED PRICES";
        RUN;

        /*-------------------------------------------------------------------------*/
        /* HM3-J: Calculate the overall CUSRATIO for each affiliated customer, and */
        /* keep affiliated customers with CUSRATIOs at or between 98-102 pct       */
        /*-------------------------------------------------------------------------*/

        PROC MEANS DATA = ALLCOMP NOPRINT;
            BY &HMCUST; 
            VAR PCTRATIO;
            WEIGHT AFFQTY;
            OUTPUT OUT = AFFCUST (DROP = _:) N = NUMCOMP MEAN = CUSRATIO;
        RUN;

        PROC MEANS NWAY DATA = HMAFF NOPRINT;
            CLASS &HMCUST;
            OUTPUT OUT = AFFOBS (DROP = _:) N = AFFOBS;
        RUN;

        DATA AFFCUST;
            MERGE AFFCUST (IN = A) AFFOBS (IN = B);
            BY &HMCUST;
            IF A & B;

            IF 98 LE CUSRATIO LE 102 THEN
            DO;
               RESULTS = 'PASS';
               PASSOBS = AFFOBS;
            END;
            ELSE
            DO;  
               RESULTS = 'FAIL';
               FAILOBS = AFFOBS;
            END;
        RUN;

        PROC SORT DATA = AFFCUST OUT = ALLCOMP;
            BY &HMCUST;
        RUN;
 
        PROC PRINT DATA = AFFCUST (OBS = 45) SPLIT = '*';
            VAR &HMCUST AFFOBS NUMCOMP CUSRATIO RESULTS;  
            SUM NUMCOMP AFFOBS PASSOBS FAILOBS;
            LABEL &HMCUST  = 'AFFILIATED*CUSTOMER(S)*==========='
                  AFFOBS   = 'CUSTOMER *SALES*============'
                  NUMCOMP  = 'CUSTOMER *WT-AVG PRICES*COMPARED*============='
                  CUSRATIO = 'CUSTOMER *WT-AVG PRICE*RATIO*============'
                  RESULTS  = 'CUSTOMER*TEST *RESULTS*========'
                  PASSOBS  = 'TOTAL SALES *PASSING TEST*============'
                  FAILOBS  = 'TOTAL SALES *FAILING TEST*============';
            FORMAT AFFOBS NUMCOMP PASSOBS FAILOBS COMMA12.;
            TITLE3 "TEST RESULTS FOR AFFILIATED CUSTOMER(S)";
        RUN;

        /*------------------------------------------------------*/
        /* HM3-K: Discard CM sales that fail the CUSRATIO test. */
        /*------------------------------------------------------*/

        PROC SORT DATA = AFFCUST OUT = FAIL (KEEP = &HMCUST CUSRATIO);
            WHERE RESULTS = 'FAIL';
            BY &HMCUST;
        RUN;

        PROC SORT DATA = HMSALES OUT = HMSALES;
            BY &HMCUST;
        RUN;

        DATA HMSALES HMAFFOUT;
            MERGE HMSALES (IN = INA) FAIL (IN = INB);
            BY &HMCUST;
            IF INA AND INB THEN
                OUTPUT HMAFFOUT;
            ELSE
            IF INA AND NOT INB THEN
                OUTPUT HMSALES;
        RUN;
    %END;
%MEND HM3_ARMSLENGTH;

/***********************************************/
/* HM-4: CM VALUES FOR CEP PROFIT CALCULATIONS */
/***********************************************/

%MACRO HM4_CEPTOT_PART_ONE;
    /* Calculate the CM values of CEP profit. */

    %IF %UPCASE(&RUN_HMCEPTOT) = YES %THEN
    %DO;
        REVENUH  = (HMGUP + HMGUPADJ - HMDISREB) * &HMQTY;
        COGSH    = (AVGCOST + HMPACK) * &HMQTY;
        SELLEXPH = (HMDSELL + HMISELL + HMCOMM) * &HMQTY;
        MOVEEXPH = HMMOVE * &HMQTY;
    %END;
%MEND HM4_CEPTOT_PART_ONE;

%MACRO HM4_CEPTOT_PART_TWO;
    /* Sum up and save the CM values of CEP profit. */

    %IF %UPCASE(&RUN_HMCEPTOT) = YES %THEN
    %DO;
        PROC MEANS NOPRINT DATA = HMSALES;
            VAR REVENUH COGSH SELLEXPH MOVEEXPH;
            OUTPUT OUT = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMCEP (DROP = _:)
                   SUM = TOTREVH TOTCOGSH TOTSELLH TOTMOVEH;
        RUN;

        PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMCEP;
            TITLE3 "CM VALUES FOR CEP PROFIT CALCULATIONS";
        RUN;
    %END;
%MEND HM4_CEPTOT_PART_TWO;

/*******************/
/* HM-5: COST TEST */
/*******************/

%MACRO HM5_COSTTEST;
    DATA HMSALES;
        SET HMSALES;
        IF HMNPRICOP GE AVGCOST THEN
        DO;
            QABOVE  = &HMQTY;
            QBELOW  = 0;
            OABOVE  = 1;
            OBELOW  = 0;
            COPTEST = 'ABOVE';
        END;
        ELSE
        DO;
            QABOVE  = 0;
            QBELOW  = &HMQTY;
            OABOVE  = 0;
            OBELOW  = 1;
            COPTEST = 'BELOW';
        END;
        OUTPUT HMSALES;
    RUN;

    /*-------------------------------------------*/
    /* HM5-A: Cost test results for each product */
    /*-------------------------------------------*/

    PROC SORT DATA = HMSALES OUT = HMSALES;
        BY &HMMANF &HMPRIM &HMCONNUM;
    RUN;

    DATA HMCOP (KEEP = &HMMANF &HMPRIM &HMCONNUM OBSABOVE OBSBELOW
                       QTYABOVE QTYBELOW PCTQABOV);
        SET HMSALES;
        BY &HMMANF &HMPRIM &HMCONNUM;

        IF FIRST.&HMCONNUM THEN
        DO;
            QTYABOVE = 0;
            OBSABOVE = 0;
            QTYBELOW = 0;
            OBSBELOW = 0;
        END;

        QTYABOVE + QABOVE;
        OBSABOVE + OABOVE;
        QTYBELOW + QBELOW;
        OBSBELOW + OBELOW;

        IF LAST.&HMCONNUM THEN
        DO;
            IF QTYABOVE = 0 THEN
                PCTQABOV = 0;
            ELSE
                PCTQABOV = (QTYABOVE / (QTYABOVE + QTYBELOW)) * 100;
            OUTPUT HMCOP; 
        END;
    RUN;

    PROC SORT DATA = HMCOP OUT = SUMMCTEST;
        BY &HMPRIM &HMCONNUM;
    RUN;

    %MACRO PRIME_SUMMARY;
        %IF %UPCASE(&HMPRIME) NE NA %THEN
        %DO;
            DATA SUMMCTEST;
                SET SUMMCTEST;
                BY &HMPRIM;
                IF FIRST.&HMPRIM THEN
                    COUNT = 0;

                COUNT + 1;

                IF COUNT LE 20 THEN
                    OUTPUT SUMMCTEST;
            RUN;
        %END;
    %MEND PRIME_SUMMARY;

    %PRIME_SUMMARY;
    
    PROC PRINT DATA = SUMMCTEST (OBS = &PRINTOBS);
        %PRIME_PRINT
        VAR &HMCONNUM QTYABOVE OBSABOVE QTYBELOW OBSBELOW PCTQABOV;
        TITLE3 "SAMPLE RESULTS OF COST TEST BY &HMCONNUM";
    RUN;

    /*----------------------------------------------*/
    /* HM5-A-2: Cost test results for time periods. */
    /*----------------------------------------------*/

    %MACRO TIME_COST_STATS;
        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            PROC SORT DATA = HMSALES OUT = HMSALES;
                BY &HMMANF &HMPRIM &HM_TIME_PERIOD;
            RUN;

            DATA HMCOP_TIME (KEEP = &HMMANF &HMPRIM &HM_TIME_PERIOD OBSABOVE 
                             OBSBELOW QTYABOVE QTYBELOW PCTQABOV);             
                SET HMSALES;
                BY &HMMANF &HMPRIM &HM_TIME_PERIOD;

                IF FIRST.&HM_TIME_PERIOD THEN
                DO;
                    QTYABOVE = 0;
                    OBSABOVE = 0;
                    QTYBELOW = 0;
                    OBSBELOW = 0;
                END;

                QTYABOVE + QABOVE;
                OBSABOVE + OABOVE;
                QTYBELOW + QBELOW;
                OBSBELOW + OBELOW;

                IF LAST.&HM_TIME_PERIOD THEN
                DO;
                    IF QTYABOVE = 0 THEN
                        PCTQABOV = 0;
                    ELSE
                        PCTQABOV = (QTYABOVE / (QTYABOVE + QTYBELOW)) * 100;
                    OUTPUT HMCOP_TIME; 
                END;
            RUN;

            PROC SORT DATA = HMCOP_TIME OUT = SUMMCTEST_TIME;
                BY &HMPRIM &HM_TIME_PERIOD;
            RUN;

            %IF %UPCASE(&HMPRIME) NE NA %THEN
            %DO;
                DATA SUMMCTEST_TIME;
                    SET SUMMCTEST_TIME;
                    BY &HMPRIM;
                    IF FIRST.&HMPRIM THEN
                        COUNT = 0;

                    COUNT + 1;

                    IF COUNT LE 20 THEN OUTPUT
                        SUMMCTEST_TIME;
                RUN;
    
                %MACRO BYLINE;
                    BY &HMMANF &HMPRIM;
                %MEND BYLINE;

                %MACRO IDLINE;
                    ID &HMMANF &HMPRIM;
                %MEND IDLINE;

                PROC SORT DATA = SUMMCTEST_TIME OUT = SUMMCTEST_TIME;
                    %BYLINE
                RUN;
            %END;    
            %IF %UPCASE(&HMPRIME) = NA %THEN
            %DO;
                %MACRO BYLINE;
                %MEND BYLINE;

                %MACRO IDLINE;
                %MEND IDLINE;
            %END;
    
            PROC PRINT DATA = SUMMCTEST_TIME (OBS = &PRINTOBS);
                %BYLINE
                %IDLINE
                VAR &HM_TIME_PERIOD QTYABOVE OBSABOVE QTYBELOW OBSBELOW PCTQABOV;
                SUM QTYABOVE OBSABOVE QTYBELOW OBSBELOW;
                TITLE3 "SAMPLE RESULTS OF COST TEST BY &HM_TIME_PERIOD";
            RUN;

            PROC SORT DATA = HMSALES OUT = HMSALES;
                BY &HMMANF &HMPRIM &HMCONNUM;
            RUN;
        %END;
    %MEND TIME_COST_STATS;

    %TIME_COST_STATS;

    /*---------------------------------------------------------------------------*/
    /* HM5-B: Apply cost test results to create above- and below-cost databases. */
    /*---------------------------------------------------------------------------*/

    DATA HMABOVE HMBELOW
        HMSALES (KEEP = &HMMANF &HMCONNUM &HMPRIM COSTTYPE
                         &HMQTY HMNETPRI HMNPRICOP AVGCOST);
        MERGE HMSALES (IN = INA) HMCOP;
        BY &HMMANF &HMPRIM &HMCONNUM;
        IF INA;

        LENGTH COSTTYPE $15.;

        IF PCTQABOV LE 80 AND COPTEST='BELOW' THEN
        DO;
            COSTTYPE = 'BELOW COST SALE';
            OUTPUT HMBELOW;
        END;
        ELSE
        DO;
            COSTTYPE = 'ABOVE COST SALE';
            OUTPUT HMABOVE;
        END;
        OUTPUT HMSALES;
    RUN;

    PROC MEANS NWAY DATA = HMSALES NOPRINT;
        CLASS &HMMANF &HMPRIM COSTTYPE;
        VAR HMNETPRI;
        WEIGHT &HMQTY;
        OUTPUT OUT = COSTSUMM (DROP = _:)
               N = SALES SUMWGT = TOTQTY SUM = TOTVALUE;
        RUN;

    PROC PRINT DATA = COSTSUMM;
        SUM SALES TOTQTY TOTVALUE;
        FORMAT TOTQTY COMMA16.4 TOTVALUE COMMA21.4;
        TITLE3 "SUMMARY OF COST TEST";
    RUN;

    PROC PRINT DATA = HMBELOW (OBS = &PRINTOBS);
        VAR &HMCONNUM &HMMANF &HMPRIM &HM_TIME_PERIOD
            HMNPRICOP AVGCOST COPTEST PCTQABOV COSTTYPE;
        TITLE3 "SAMPLE OF BELOW COST CM SALES";
    RUN;

    PROC PRINT DATA = HMABOVE (OBS = &PRINTOBS);
        VAR &HMCONNUM &HMMANF &HMPRIM &HM_TIME_PERIOD
            HMNPRICOP AVGCOST COPTEST PCTQABOV COSTTYPE;
        TITLE3 "SAMPLE OF ABOVE COST CM SALES";
    RUN;

    %GLOBAL RUN_RECOVERY;

    PROC SQL NOPRINT;
        SELECT COUNT(*)
        INTO :BELOW_FOUND
        FROM HMBELOW;
    QUIT;

    %MACRO BELOW_RESULT; 
        %IF &BELOW_FOUND NE 0 %THEN
        %DO;
            %LET RUN_RECOVERY = YES;
        %END;
    %MEND BELOW_RESULT;

    %BELOW_RESULT

    /*-----------------------------------------------------------*/
    /* HM5-C: Cost Recovery Test for Quarterly Cost              */
    /*                                                           */
    /*    For below-cost sales, compare the CONNUM average price */
    /*    across all time periods to the CONNUM average cost     */
    /*    across all time periods. If the average price exceeds  */
    /*    the average cost, then below-cost sales of that CONNUM */
    /*    will be reclassified as above cost.                    */
    /*-----------------------------------------------------------*/

    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %IF &RUN_RECOVERY = YES %THEN
        %DO;
            PROC MEANS NWAY DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST NOPRINT;
                CLASS &COP_MANF_OUT COST_MATCH;
                VAR AVGCOST;
                WEIGHT COST_QTY;
               OUTPUT OUT = CONNUMCOST (DROP = _:) MEAN = CONNUM_COST;
            RUN;

            PROC SORT DATA = HMBELOW OUT = HMBELOW;
                BY &SALES_COST_MANF &HMPRIM &HMCONNUM;
            RUN;

            PROC MEANS NWAY DATA = HMBELOW NOPRINT;
                WHERE "&BEGINPERIOD"D <= &HMSALEDATE <= "&ENDPERIOD"D;
                CLASS &SALES_COST_MANF &HMPRIM &HMCONNUM;
                VAR HMNPRICOP;
                WEIGHT &HMQTY;
                OUTPUT OUT = CONNUMPRICE (DROP = _:)
                       MEAN = CONNUM_PRICE;
            RUN;

            DATA HMBELOW4TEST;
                MERGE HMBELOW (IN = A) CONNUMPRICE (IN = B); 
                BY &SALES_COST_MANF &HMPRIM &HMCONNUM;
                IF A & B;
            RUN;

            PROC SORT DATA = HMBELOW4TEST OUT = HMBELOW4TEST;
                BY &SALES_COST_MANF &HMCPPROD;
            RUN;

            DATA HMBELOW4TEST RECOVERED;
                MERGE HMBELOW4TEST (IN = A) 
                      CONNUMCOST (IN = B 
                          RENAME = (&COP_MANF_OUT &EQUAL_COST_MANF 
                                    &SALES_COST_MANF
                                    COST_MATCH = &HMCPPROD));
                BY &SALES_COST_MANF &HMCPPROD;
                IF A & B;
                FORMAT RECOVERED $3.;
                RECOVERED = 'NO'; /* Default value */
                IF CONNUM_PRICE GE CONNUM_COST THEN    
                DO;
                    COSTTYPE = 'ABOVE COST SALES';
                    RECOVERED = 'YES';
                    OUTPUT RECOVERED;
                END;
                OUTPUT HMBELOW4TEST;
            RUN;

            PROC SORT DATA = HMBELOW4TEST OUT = HMBELOW4TEST;
                BY RECOVERED &HMMANF &HMPRIM &HMCONNUM &HM_TIME_PERIOD;
            RUN;

            DATA RECOVERTYPE;
                 SET HMBELOW4TEST;
                 BY RECOVERED &HMMANF &HMPRIM &HMCONNUM &HM_TIME_PERIOD;
                 IF FIRST.RECOVERED THEN
                     COUNT = 0;

                 COUNT + 1;

                 IF COUNT LE 20 THEN
                     OUTPUT RECOVERTYPE;
            RUN;

            PROC SORT DATA = RECOVERTYPE OUT = RECOVERTYPE;
                BY &HMMANF &HMPRIM &HMCONNUM;
            RUN;

            PROC PRINT DATA = RECOVERTYPE SPLIT = "*";
                BY &HMMANF &HMPRIM &HMCONNUM;
                ID  &HMMANF &HMPRIM &HMCONNUM;
                VAR &HM_TIME_PERIOD HMNPRICOP AVGCOST CONNUM_PRICE CONNUM_COST RECOVERED COSTTYPE;
                LABEL RECOVERED  = "WAS SALE*RECOVERED?"
                      &HMCONNUM = "CONTROL*NUMBER"
                      &HM_TIME_PERIOD = "TIME*PERIOD"
                      HMNPRICOP = "TRANSACTION*PRICE" 
                      AVGCOST = "QUARTERLY*COST"
                      CONNUM_PRICE = "CONTROL NUMBER*AVERAGE PRICE" 
                      CONNUM_COST = "AVERAGE COST*ALL PERIODS" 
                      COSTTYPE = "CLASSIFICATION*AFTER TEST";
                 TITLE3 "SAMPLE OF RESULTS OF COST-RECOVERY TEST PERFORMED ON";
                 TITLE4 "SALES PREVIOUSLY FOUND TO BE BELOW THE QUARTERLY COST";
             RUN;

             DATA HMABOVE;
                 SET HMABOVE RECOVERED (DROP = RECOVERED CONNUM_PRICE CONNUM_COST);
             RUN;
        %END;
    %END;
%MEND HM5_COSTTEST;

/*********************************************/
/* HM-6: SELECT CM DATA FOR WEIGHT AVERAGING */
/*                                           */
/*  Use above-cost CM sales.                 */
/*********************************************/

%MACRO HM6_DATA_4_WTAVG;
    PROC SORT DATA = HMABOVE OUT = HM;
        BY &HMMANF &HMPRIM HMLOT &MONTH &HMCONNUM &HM_TIME_PERIOD;
    RUN;
%MEND HM6_DATA_4_WTAVG;

/***************************************************************/
/* HM-7: WEIGHT AVERAGE HM DATA                                */
/*                                                             */
/* Rename control number, VCOM, manufacturer, prime/non-prime, */
/* where applicable, using standardized names.                 */
/***************************************************************/
         
%MACRO HM7_WTAVG_DATA;
    %GLOBAL MANUF_RENAME PRIME_RENAME TIME_PER_RENAME TIME_PERIOD_RENAME HM_HIGH_INFLATION_VAR HIGH_INFLATION_RENAME;

    %IF %UPCASE(&HMMANUF) NE NA %THEN 
    %DO;
        %MACRO MANUF_RENAME;
            RENAME &HMMANF = HMMANF;
        %MEND MANUF_RENAME;
    %END;
    %ELSE
    %IF %UPCASE(&HMMANUF) EQ NA %THEN 
    %DO;
        %MACRO MANUF_RENAME;
        %MEND MANUF_RENAME;
    %END;

    %IF %UPCASE(&HMPRIME) EQ NA %THEN 
    %DO;
        %MACRO PRIME_RENAME;
        %MEND PRIME_RENAME;
    %END;
    %ELSE
    %IF %UPCASE(&HMPRIME) NE NA %THEN
    %DO;
        %MACRO PRIME_RENAME;
            RENAME &HMPRIM = HMPRIME;
        %MEND PRIME_RENAME;
    %END;

    %IF %UPCASE(&COMPARE_BY_TIME) EQ NO %THEN 
    %DO;
        %LET TIME_PER_RENAME = ;
        %MACRO TIME_PERIOD_RENAME;
        %MEND TIME_PERIOD_RENAME;
    %END;
    %ELSE
    %IF %UPCASE(&COMPARE_BY_TIME) EQ YES %THEN
    %DO;
        %LET TIME_PER_RENAME = &HM_TIME_PERIOD = HM_TIME_PERIOD;
        %MACRO TIME_PERIOD_RENAME;
            RENAME &HM_TIME_PERIOD = HM_TIME_PERIOD;
        %MEND TIME_PERIOD_RENAME;
    %END;

    %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ NO %THEN 
    %DO;
        %LET HM_HIGH_INFLATION_VAR = ;
        %LET HIGH_INFLATION_RENAME = ;
        %MACRO HIGH_INFLATION_RENAME;
        %MEND HIGH_INFLATION_RENAME;
    %END;
    %ELSE
    %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
    %DO;
        %LET HM_HIGH_INFLATION_VAR = YEARMONTHH;
        %LET HIGH_INFLATION_RENAME = &HM_TIME_PERIOD = HM_TIME_PERIOD;
        %MACRO HIGH_INFLATION_RENAME;
            RENAME YEARMONTHH = HMYEARMONTH;
        %MEND HIGH_INFLATION_RENAME;
    %END;

     PROC MEANS NWAY DATA = HM NOPRINT;
        CLASS &HMMANF &HMPRIM HMLOT &MONTH &HMCONNUM &HM_TIME_PERIOD &HM_HIGH_INFLATION_VAR; 
        ID &HMCHAR AVGVCOM;
        VAR &WGTAVGVARS;
        WEIGHT &HMQTY;
        OUTPUT OUT = HMAVG (DROP = _:) MEAN = &WGTAVGVARS; 
    RUN;

    DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMWTAV;
        SET HMAVG;
        RENAME &HMCONNUM = HMCONNUM AVGVCOM = HMVCOM;
        %MANUF_RENAME
        %PRIME_RENAME 
        %TIME_PERIOD_RENAME
        %HIGH_INFLATION_RENAME
    RUN;

    PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMWTAV (OBS = &PRINTOBS);
        TITLE3 "SAMPLE OF WEIGHT-AVERAGED HM VALUES FOR PRICE-TO-PRICE COMPARISON WITH U.S. SALES";
    RUN;
%MEND HM7_WTAVG_DATA;

/************************************************************************/
/* HM-8: CALCULATE SELLING EXPENSE AND PROFIT RATIOS FOR CV COMPARISONS */
/************************************************************************/

%MACRO HM8_CVSELL;
    PROC MEANS NWAY DATA = HM NOPRINT;
        CLASS HMLOT;
        VAR HMDSELL HMISELL HMCOMM HMCRED HMICC
            HMINDCOM HMNPRICOP CVCREDPR AVGCOST;
        WEIGHT &HMQTY;
        OUTPUT OUT = CVSELLOT (DROP = _:)
               SUM = DSELCV ISELCV COMMCV CREDCV INVCV 
                     ICOMCV HMTOTVAL HMTOTCVP HMTOTCOP;
    RUN;

    DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CVSELL (KEEP = HMLOT PRATECV 
                                                               DSELCVR ISELCVR COMMCVR
                                                               CREDCVR INVCVR ICOMCVR);
        SET CVSELLOT;

        DSELCVR = DSELCV / HMTOTCOP;
        ISELCVR = ISELCV / HMTOTCOP;
        ICOMCVR = ICOMCV / HMTOTCOP;
        COMMCVR = COMMCV / HMTOTCOP;
        CREDCVR = CREDCV / HMTOTCVP;
        INVCVR  = INVCV / HMTOTCOP; 

        PRATECV = (HMTOTVAL - HMTOTCOP) / HMTOTCOP;
        IF PRATECV LT 0 THEN
            PRATECV = 0;
    RUN;

    PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CVSELL (OBS = &PRINTOBS);
        TITLE3 "COMPARISON MARKET SELLING EXPENSE RATIOS AND PROFIT RATES FOR CV";
    RUN;
%MEND HM8_CVSELL;

/*********************************************/
/* HM-9: CALCULATE LEVEL OF TRADE ADJUSTMENT */
/*********************************************/

%MACRO HM9_LOTADJ;
    %IF %UPCASE(&RUN_HMLOTADJ) = YES %THEN
    %DO;
        PROC MEANS NWAY DATA = HM (RENAME = &HMCONNUM = HMCONNUM) NOPRINT;
            CLASS HMLOT HMCONNUM &HM_TIME_PERIOD;
            VAR HMNETPRI;
            WEIGHT &HMQTY;
            OUTPUT OUT = LOT1 (DROP = _:) MEAN = HMPRICE SUMWGT = HMQTY;
        RUN;

        DATA LOT2;
            SET LOT1;
            RENAME HMLOT = USLOT HMCONNUM = USCONNUM &HM_TIME_PERIOD &EQUAL_TIME &US_TIME 
                   HMPRICE = USPRICE HMQTY = USQTY;
        RUN;

        DATA DIFF (KEEP = HMLOT HMCONNUM USCONNUM USLOT &HM_TIME_PERIOD &US_TIME
                          GNUM GQTY LNUM LQTY ENUM EQTY DIFF QTY);
            SET LOT2;

            DO J = 1 TO LAST;
                SET LOT1 POINT = J NOBS = LAST;

            IF USCONNUM = HMCONNUM &AND_TIME &HM_TIME_PERIOD &EQUAL_TIME &US_TIME THEN
                DO;
                    DIFF  = (USPRICE - HMPRICE) / HMPRICE;
                    QTY   = USQTY + HMQTY;
                    GNUM  = 0;
                    GQTY  = 0;
                    LNUM  = 0;
                    LQTY  = 0;
                    ENUM  = 0;
                    EQTY  = 0;

                    IF USPRICE GT HMPRICE THEN
                    DO;
                        GNUM = 1;
                        GQTY = USQTY + HMQTY;
                    END;
                    ELSE
                    IF USPRICE LT HMPRICE THEN 
                    DO;
                        LNUM = 1;
                        LQTY = USQTY + HMQTY;
                    END;
                    ELSE
                    DO;
                        ENUM = 1;
                        EQTY = USQTY + HMQTY;
                    END;
                    OUTPUT DIFF;
                END; 
            END;
        RUN;

        PROC MEANS NWAY DATA = DIFF NOPRINT;
            CLASS USLOT HMLOT;
            VAR GNUM GQTY LNUM LQTY ENUM EQTY;
            OUTPUT OUT = RESULTS (DROP = _:)
                   SUM = GTNUM GTQTY LTNUM LTQTY EQNUM EQQTY;
        RUN;

        PROC MEANS NWAY DATA = DIFF NOPRINT;
            CLASS USLOT HMLOT;
            VAR DIFF;
            WEIGHT QTY;
            OUTPUT OUT = RESULTS2 (DROP = _:) MEAN = LOTADJ;
        RUN;

        DATA RESULTS;
            MERGE RESULTS RESULTS2;
            BY USLOT HMLOT;

            NUM = GTNUM + LTNUM + EQNUM;
            QTY = GTQTY + LTQTY + EQQTY;

            GTNPCT = GTNUM * 100 / NUM;
            GTQPCT = GTQTY * 100 / QTY;
            LTNPCT = LTNUM * 100 / NUM;
            LTQPCT = LTQTY * 100 / QTY;
            EQNPCT = EQNUM * 100 / NUM;
            EQQPCT = EQQTY * 100 / QTY;
        RUN;

        PROC PRINT DATA = RESULTS NOOBS SPLIT = '*';
            FORMAT GTNPCT LTNPCT EQNPCT GTQPCT LTQPCT EQQPCT 6.2
                   LOTADJ 6.4;
            LABEL USLOT = 'WHEN THIS*U.S. LOT IS*COMPARED TO'
                  HMLOT = 'THIS CM LOT'
                  GTNPCT = 'MODELS*ABOVE'
                  GTQPCT = 'QUANTITY*ABOVE'
                  LTNPCT = 'MODELS*BELOW'
                  LTQPCT = 'QUANTITY*BELOW'
                  EQNPCT = 'MODELS*EQUAL'
                  EQQPCT = 'QUANTITY*EQUAL'
                  LOTADJ = 'LOT ADJUSMENT*FACTOR*(LOTADJ)';
        VAR USLOT HMLOT LOTADJ GTNPCT EQNPCT LTNPCT GTQPCT EQQPCT LTQPCT;
            TITLE3 "COMPARISON OF U.S. LOT TO CM LOT (ALL FIGURES GIVEN IN PERCENTAGES OF TOTAL)";
        RUN;

        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._LOTADJ (KEEP = USLOT HMLOT LOTADJ);
            SET RESULTS;
        RUN;
    %END;
%MEND HM9_LOTADJ;

/*********************************************************************/
/* US-1: CREATE MACROS AND MACRO VARIABLES REGARDING PRIME/NON-PRIME */
/*       MERCHANDISE, MANUFACTURER DESIGNATION, COST AND MONTHS      */
/*********************************************************************/

%MACRO US1_MACROS;
    %GLOBAL AND_COST_PRIME AND_P2P_MANF AND_PRIME COST_MANF    /* 25 macro variables */
            COST_PRIM COST_TIME_PERIOD DE_MINIMIS EQUAL_COST_MANF 
            EQUAL_COST_PRIME EQUAL_P2P_MANF EQUAL_PRIME HMMANF HMMON 
            HMPRIM LABEL_COST_MANF MANF_LABEL NO_PROD_COST_MANF    
            NO_PROD_COST_PRIME PRIME_LABEL PRIME_TITLE SALES_COST_MANF
            SALES_COST_PRIME USMANF USMON USPRIM;

    /*--------------------------------------------------------------------*/
    /* 1-A DEFINE MACRO VARIABLES AND SET THEIR DEFALUT VALUES TO NOTHING */
    /*--------------------------------------------------------------------*/

    %LET AND_COST_PRIME = ;     /* AND operator for prime/non-prime purposes         */
    %LET AND_P2P_MANF = ;       /* AND operator for sales manufacturer purposes      */
    %LET AND_PRIME = ;          /* AND operator for prime/non-prime purposes         */
    %LET COST_MANF = ;          /* cost manufacturer for merging with sales          */
    %LET COST_PRIM = ;          /* cost prime for merging with U.S. sales            */
    %LET COST_TIME_PERIOD = ;   /* Cost time period for quarterly costs              */
    %LET EQUAL_COST_MANF = ;    /* EQUAL operator for manufacturer re: costs         */
    %LET EQUAL_COST_PRIME = ;   /* EQUAL operator for cost prime purposes            */
    %LET EQUAL_P2P_MANF = ;     /* EQUAL operator for sales manufacturer purposes    */
    %LET EQUAL_PRIME = ;        /* EQUAL operator for prime/non-prime purposes       */
    %LET HMMANF = ;             /* CM sales manufacturer for merging with U.S. sales */
    %LET HMPRIM = ;             /* prime code for CM sales data                      */
    %LET LABEL_COST_MANF = ;    /* label for Cost manufacturer variable              */
    %LET MANF_LABEL = ;         /* label for sales manufacturer                      */
    %LET NO_PROD_COST_MANF = ;  /* No production Cost manufacturer variable          */
    %LET NO_PROD_COST_PRIME = ; /* No production Cost manufacturer variable          */
    %LET PRIME_LABEL = ;        /* printing label for prime code                     */
    %LET PRIME_TITLE = ;        /* prime v nonprime text for titles                  */
    %LET SALES_COST_MANF = ;    /* U.S. sales manufacturer for merging with costs    */
    %LET SALES_COST_PRIME = ;   /* U.S. sales prime for merging with Cost            */
    %LET USMANF = ;             /* U.S. sales manufacturer for merging with CM sales */
    %LET USPRIM = ;             /* prime code for U.S. sales data                    */
            
    /*------------------------------------------------------------------------------*/
    /*  1-B DEFINE INVESTIGATION OR ADMINISTRATIVE REVIEWS SPECIFIC MACRO VARIABLES */
    /*------------------------------------------------------------------------------*/

    %IF %UPCASE(&CASE_TYPE) EQ INV %THEN  /* de minimis is 2 and month is not relevant */
    %DO;
        %LET DE_MINIMIS = 2;
        %LET HMMON = ; 
        %LET USMON = ;
    %END;
    %ELSE
    %IF %UPCASE(&CASE_TYPE) EQ AR %THEN  /* de minimis is 0.5 and month is relevant */
    %DO;
        %LET DE_MINIMIS = .5;
        %LET USMON = USMONTH;
        %LET HMMON = HMMONTH;
    %END;

    /*------------------------------------------------------------------------*/
    /*  1-C DEFINE MACRO VARIABLES WHEN CM AND U.S. MANUFACTERER ARE REPORTED */
    /*------------------------------------------------------------------------*/

    %IF &NV_TYPE = CV %THEN  /* Set CM manufacturer and prime macro variables to NO */
    %DO;
        %LET COST_MANUF = NA;
        %LET HMMANUF = NO;
        %LET HMPRIME = NO;
    %END;

    %IF %UPCASE(&USMANUF) NE NA AND %UPCASE(&HMMANUF EQ YES) %THEN
    %DO;
        %LET AND_P2P_MANF = AND ;    
        %LET EQUAL_P2P_MANF = = ;
        %LET HMMANF = HMMANF;
        %LET MANF_LABEL = MANUFACTURER;
        %LET USMANF = &USMANUF;
    %END;    

    /*----------------------------------------------------------*/
    /* 1-D CREATE MACROS FOR WHEN COST MANUFACTURER IS REPORTED */
    /*----------------------------------------------------------*/

    %IF %UPCASE(&COP_MANUF) EQ YES AND    /* Create values when Cost is calculated in the CM Program.     */
        %UPCASE(&COST_MANUF) NE NA %THEN  /* Create values when Cost is calculated in the Margin Program. */
    %DO;
        %LET COST_MANF = &COST_MANUF;
        %LET EQUAL_COST_MANF = = ;
        %LET LABEL_COST_MANF = &COST_MANUF = "SURROGATE*MANUFACTURER";
        %LET NO_PROD_COST_MANF = NO_PRODUCTION_&COST_MANUF;
        %LET SALES_COST_MANF = &USMANUF;
    %END;

    /*-----------------------------------------------------------------*/
    /*  1-E DEFINE MACRO VARIABLES WHEN CM AND U.S. PRIME ARE REPORTED */
    /*-----------------------------------------------------------------*/

    %IF %UPCASE(&HMPRIME) = YES %THEN  /* Create values when CM prime is relevant. */
    %DO;
        %LET AND_PRIME = AND;
        %LET COST_PRIM = COST_PRIME; 
        %LET EQUAL_COST_PRIME = = ;  
        %LET EQUAL_PRIME = = ;
        %LET HMPRIM = HMPRIME;
        %LET PRIME_LABEL = &USPRIM = "PRIME/SECOND*QUALITY MDSE*============";
        %LET PRIME_TITLE = PRIME/NONPRIME;
        %LET SALES_COST_PRIME = &USPRIME;
        %LET USPRIM = &USPRIME;
    %END;

    /*-----------------------------------------------*/
    /* 1-F CREATE MACROS WHEN COST PRIME IS REPORTED */
    /*-----------------------------------------------*/

    %IF &SALESDB = HMSALES %THEN                 /* When running the Comparison Market Program. */
    %DO;
        %IF %UPCASE(&COST_PRIME) NE NA %THEN /* Create values when Cost prime is relevant. */
        %DO;
            %LET AND_COST_PRIME = AND;
            %LET COST_PRIM = COST_PRIME;
            %LET EQUAL_COST_PRIME = = ;
            %LET NO_PROD_COST_PRIME = NO_PRODUCTION_&COST_PRIME;
            %LET SALES_COST_PRIME = &USPRIME;
        %END;
    %END;
    %ELSE
    %IF &SALESDB = USSALES %THEN                      /* When running the Margin Program. */
    %DO;
        %IF %UPCASE(&COP_PRIME) EQ YES %THEN  /* Create values when Cost prime is relevant. */
        %DO;
            %LET AND_COST_PRIME = AND;
            %LET COST_PRIM = COST_PRIME;
            %LET EQUAL_COST_PRIME = = ;
            %LET NO_PROD_COST_PRIME = NO_PRODUCTION_&COST_PRIME;
            %LET SALES_COST_PRIME = &USPRIME;
        %END;
    %END;

    /*--------------------------------------------------------------------------------*/
    /*  1-G CREATE PRIME MACROS WHEN THERE ARE DIRECT COMPARISONS OF U.S. SALES TO CV */
    /*--------------------------------------------------------------------------------*/

    %IF &SALESDB = USSALES %THEN                                                      /* When running the Margin Program. */
    %DO;
        %IF %UPCASE(&COST_TYPE) EQ CV AND %UPCASE(&COST_PRIME) NE NA %THEN  /* Create values when Cost prime is relevant. */
        %DO;
            %LET AND_COST_PRIME = AND;
            %LET COST_PRIM = &COST_PRIME;
            %LET EQUAL_COST_PRIME = = ;
            %LET SALES_COST_PRIME = &USPRIME;
        %END;
    %END;

    /*----------------------------------------------------------------------------*/
    /*  1-H CREATE QUARTERLY COST MACROS WHEN COST DATA COMES FROM THE CM PROGRAM */
    /*----------------------------------------------------------------------------*/

    %IF %UPCASE(&COST_TYPE) EQ CM %THEN  /* Create values when Cost is calculated in the Comparison Market Program. */
    %DO;
        %LET COST_MATCH = COST_MATCH;    /* Variable linking costs to sales. */

        %IF %UPCASE(&COMPARE_BY_TIME) EQ YES %THEN  /* Create values when quarterly costs are relevant. */
        %DO;
             %LET COST_TIME_PERIOD = COST_TIME_PERIOD; 
        %END;
    %END;
%MEND US1_MACROS;

/****************************************************************/
/* US-2: CREATE VARIABLE CALLED, SALE_TYPE, INDICATING EP v CEP */
/****************************************************************/

%MACRO US2_SALETYPE;
    FORMAT SALE_TYPE $3.;
    %GLOBAL CEP_PRESENT;

    %IF %UPCASE(&SALETYPE) = CEP %THEN
    %DO;
        SALE_TYPE = 'CEP';
        %LET CEP_PRESENT = YES;
    %END;
    %ELSE %IF %UPCASE(&SALETYPE) = EP %THEN
    %DO;
        SALE_TYPE = 'EP';
        %LET CEP_PRESENT = NO;
        %GLOBAL CEPROFIT;
        %LET CEPROFIT = NA;
    %END;
    %ELSE 
    %DO;
        SALE_TYPE = LEFT(COMPRESS(&SALETYPE));
        CEP_FIND = INDEX((UPCASE(SALE_TYPE)), "CEP");
        RUN;

        PROC MEANS DATA = USSALES NOPRINT;
            VAR CEP_FIND;
            OUTPUT OUT = CEPFIND (DROP = _:) MAX = CEPFIND;
        RUN;

        DATA _NULL_;
            SET CEPFIND;
            IF CEPFIND GT 0 THEN CEP_PRESENT = "YES";
            ELSE CEP_PRESENT = "NO";
            CALL SYMPUT("CEP_PRESENT", CEP_PRESENT);
        RUN;

        DATA USSALES;
           SET USSALES;
    %END;
%MEND US2_SALETYPE; 

/********************************************************************/
/* US-3: CONVERT NON-U.S. DOLLAR VARIABLES INTO U.S. DOLLAR AMOUNTS */
/********************************************************************/

%MACRO US3_USD_CONVERSION;

/* New - Replace the above macro with this Macro. This uses Array and doesn't loop thru. Cleaner log, reduces confusion */
/* New - DROP THE ORIGINAL NON-CONVERTED VARIABLES */

%MACRO CONVERT_TO_USD (USE_EXRATES = , EXDATA = , VARS_TO_USD =);
    %IF %UPCASE(&USE_EXRATES) = YES AND %UPCASE(&VARS_TO_USD) ^= NA %THEN
    %DO;
        DATA USSALES;
            SET USSALES;

            /***********************************************/
            /* THE FOLLOWING ARRAY USES THE MACRO VARIABLE */
            /* VAR_TO_USD TO CONVERT ADJUSTMENTS EXPRESSED */
            /* IN FOREIGN CURRENCY TO U.S. DOLLARS.        */
            /***********************************************/

            ARRAY CONVERT (*) &VARS_TO_USD;

            %LET I = 1;

            /**************************************************/
            /* CREATE A LIST OF REVISED VARIABLES NAMES WITH  */
            /* THE SUFFIX _USD. LOOP THROUGH THE VARIABLES IN */
            /* THE ORIGINAL LIST AND ADD THE REVISED VARIABLE */
            /* NAMES TO THE MACRO VARIABLE VARS_IN_USD.       */
            /**************************************************/

            %LET VARS_IN_USD = ;
            %DO %UNTIL (%SCAN(&VARS_TO_USD, &I, %STR( )) = %STR());
                %LET VARS_IN_USD = &VARS_IN_USD
                %SYSFUNC(COMPRESS(%SCAN(&VARS_TO_USD, &I, %STR( )) _USD));
                %LET I = %EVAL(&I + 1);
            %END;
            %LET VARS_IN_USD = %CMPRES(&VARS_IN_USD);

            ARRAY CONVERTED (*) &VARS_IN_USD;

            /*******************************************************/
            /* CONVERT THE ORIGINAL VARIABLES IN THE ARRAY CONVERT */
            /* TO U.S DOLLARS USING THE DAILY EXCHANGE RATE AND    */
            /* ASSIGN THE NEW VALUES TO NEW VARIABLES WITH THE     */
            /* ORIGINAL NAME AND THE SUFFIX _USD THAT ARE IN THE   */
            /* ARRAY CONVERTED.                                    */
            /*                                                     */
            /* FOR EXAMPLE, IF THE VARIABLE COAL_SV IS DENOMINATED */
            /* IN A FOREIGN CURRENCY, THE VARIABLE COAL_SV_USD IS  */
            /* CREATED AND DENOMINATED IN U.S. DOLLARS.            */
            /*******************************************************/

            DO I = 1 TO DIM(CONVERT);
                CONVERTED(I) = CONVERT(I) * EXRATE_&EXDATA;
            END;
        RUN;

        PROC PRINT DATA = USSALES (OBS=&PRINTOBS);
            VAR &USSALEDATE EXRATE_&EXDATA &VARS_TO_USD &VARS_IN_USD;
            TITLE3 "SAMPLE OF FOREIGN CURRENCY VARIABLES CONVERTED INTO U.S. DOLLARS USING EXRATE_&EXDATA";
        RUN;

        /**********************************************/
        /* DROP THE ORIGINAL NON-CONVERTED VARIABLES. */
        /**********************************************/

        DATA USSALES;
            SET USSALES (DROP = &VARS_TO_USD);
        RUN;
    %END;
%MEND CONVERT_TO_USD;   

OPTIONS NOSYMBOLGEN;
%CONVERT_TO_USD (USE_EXRATES = &USE_EXRATES1, EXDATA = &EXDATA1, VARS_TO_USD = &EX1_VARS);
%CONVERT_TO_USD (USE_EXRATES = &USE_EXRATES2, EXDATA = &EXDATA2, VARS_TO_USD = &EX2_VARS);
OPTIONS SYMBOLGEN;
    
%MEND US3_USD_CONVERSION;

/******************************************/
/* US-4: COMMISSION OFFSETS ON U.S. SALES */
/******************************************/

%MACRO US4_INDCOMM;

    USINDCOMM = 0;                    /* Set default value of zero for when USCOMM is greater than zero.  */                    
    IF USCOMM = 0 THEN
        USINDCOMM = USICC + USISELL;  /* Value when USCOMM equal zero.  */

%MEND US4_INDCOMM;

/******************************/
/* US-5: CALCULATE CEP PROFIT */
/******************************/

%MACRO US5_CEPRATE;

    DATA USSALES;
        SET USSALES;        

            IF UPCASE(SALE_TYPE) = 'EP' THEN
            DO;

                CEPICC    = 0;        
                CEPISELL  = 0;        /* Do not edit. Default value for EP sales. */
                CEPOTHER = 0;        /* Do not edit. Default value for EP sales. */

            END;

            %IF %UPCASE(&CEP_PRESENT) = YES %THEN
            %DO;
                %IF %UPCASE(&CEPROFIT) = INPUT %THEN
                %DO;
                    CEPRATIO = &CEPRATE;
                %END;
            %END;
    RUN;

    %IF %UPCASE(&CEP_PRESENT) = YES %THEN
    %DO;
        %IF %UPCASE(&CEPROFIT) = CALC %THEN
        %DO;
            DATA USCEP;
                SET USSALES;

                /*------------------------------------------------------*/ 
                /* 5-A: Convert COGSU, REVENU, SELLEXPU, and MOVEU into */
                /* CM currency. Do not include any imputed expenses.    */ 
                /*------------------------------------------------------*/ 

                REVENU   = ((USGUP + USGUPADJ - USDISREB) / &XRATE1) * &USQTY;
                COGSU    = (AVGCOST+ ((USPACK + CEPOTHER) / &XRATE1)) * &USQTY;
                SELLEXPU = ((USDIRSELL + USCOMM + USISELL + 
                             CEPISELL) / &XRATE1) * &USQTY;
                MOVEXPU  = ((USDOMMOVE + USINTLMOVE) / &XRATE1) * &USQTY;
            RUN;

            PROC MEANS DATA = USCEP NOPRINT;
                VAR REVENU COGSU SELLEXPU MOVEXPU;
                OUTPUT OUT = USCEPTOT (DROP = _:)
                       SUM = TOTREVU TOTCOGSU TOTSELLU TOTMOVEU;
            RUN;
            
            DATA CEPTOT;
                SET USCEPTOT;
                IF _N_=1 THEN SET COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMCEP;

                TOTREV  = TOTREVH  + TOTREVU;
                TOTCOGS = TOTCOGSH + TOTCOGSU;
                TOTSELL = TOTSELLH + TOTSELLU;
                TOTMOVE = TOTMOVEH + TOTMOVEU;
                TOTEXP = TOTCOGS  + TOTSELL + TOTMOVE;
                TOTPROFT = TOTREV - TOTEXP;

                IF TOTPROFT LT 0 
                THEN CEPRATIO = 0;
                ELSE CEPRATIO = TOTPROFT / TOTEXP;
            RUN;

            PROC PRINT DATA=CEPTOT;
                TITLE3 "CEP PROFIT CALCULATIONS";
            RUN;

            /*-------------------------------------------------*/
            /* 5-B: Bring the CEP profit ratio into U.S. sales */
            /*-------------------------------------------------*/

            DATA USSALES;
                SET USSALES;
                IF _N_ = 1 THEN
                    SET CEPTOT (KEEP = CEPRATIO);
            RUN;
        %END;
    %END;
%MEND US5_CEPRATE;

/***************************************/
/* US-6: CBP entered value by importer */
/***************************************/

%MACRO US6_ENTVALUE;
    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;        
        DATA USSALES;
            SET USSALES;
            LENGTH SOURCEDATA $10. ENTERED_VALUE 8. US_IMPORTER $30.;

            %IF %UPCASE(&IMPORTER) EQ NA %THEN
            %DO;
                US_IMPORTER = &DP_PURCHASER;
            %END;
            %ELSE
            %DO;
                IF UPCASE(&IMPORTER) IN ('NA' 'UNK' 'UNKNOWN') THEN
                    US_IMPORTER = &DP_PURCHASER;
                ELSE
                    US_IMPORTER = &IMPORTER;
            %END;

            %IF %UPCASE(&ENTERVAL) EQ NA %THEN
            %DO;
                ENTERED_VALUE = .;  
            %END;
            %ELSE
            %IF %UPCASE(&ENTERVAL) NE NA %THEN
            %DO;
                ENTERED_VALUE = &ENTERVAL;
            %END;

            IF ENTERED_VALUE GT 0 THEN SOURCEDATA = 'REPORTED';
            ELSE 
            DO;
                SOURCEDATA = 'COMPUTED'; /* ENTERED_VALUE is computed by formula */ 
                IF SALE_TYPE = 'EP'
                THEN ENTERED_VALUE = USGUP + USGUPADJ - USDISREB - USINTLMOVE;
                ELSE ENTERED_VALUE = USGUP + USGUPADJ - USDISREB - USINTLMOVE -
                                      CEPISELL - CEPOTHER - CEPROFIT;
            END;
            OUTPUT USSALES;
        RUN;

        PROC MEANS NWAY DATA = USSALES NOPRINT;
            CLASS US_IMPORTER SALE_TYPE SOURCEDATA;
            VAR ENTERED_VALUE;
            WEIGHT &USQTY;
            OUTPUT OUT = IMPDATA (DROP = _:)
                         N = SALES SUMWGT = TOTQTY SUM = TOTEVALU;
        RUN;

        DATA SOURCECHK (KEEP = US_IMPORTER SOURCEU);
            SET IMPDATA;
            RETAIN SOURCEU;
            BY US_IMPORTER;
    
            IF FIRST.US_IMPORTER
            THEN SOURCEU = SOURCEDATA;
    
            IF SOURCEU NE SOURCEDATA
            THEN SOURCEU = 'MIXED';

            IF LAST.US_IMPORTER
            THEN OUTPUT SOURCECHK;
        RUN;

        PROC SORT DATA = SOURCECHK OUT = SOURCECHK;
            BY US_IMPORTER;
        RUN;

        DATA IMPDATA;
            MERGE IMPDATA (IN=A) SOURCECHK (IN=B);
            BY US_IMPORTER;
            IF A & B
            THEN OUTPUT IMPDATA;
        RUN;

        PROC PRINT DATA = IMPDATA (OBS = &PRINTOBS) SPLIT='*';
            BY US_IMPORTER;
            ID US_IMPORTER;
            SUMBY US_IMPORTER;
            SUM SALES TOTQTY TOTEVALU;
            VAR SALE_TYPE SOURCEDATA SOURCEU SALES TOTQTY TOTEVALU;
            FORMAT SALES COMMA10. TOTQTY TOTEVALU COMMA16.2;
            LABEL    US_IMPORTER   = 'U.S. IMPORTER(S)*================'
                    SALE_TYPE  = 'TYPE OF *U.S. SALES*=========='
                    SOURCEDATA = 'ORIGINAL *SOURCE DATA*==========='
                    SOURCEU    = 'CUSTOMS VALUE*SOURCE DATA*============='
                    SALES      = 'U.S. SALES*=========='
                    TOTQTY     = 'U.S. QUANTITY*============='
                    TOTEVALU   = 'CUSTOMS ENTERED VALUE*=====================';
            TITLE3 "SOURCE OF CUSTOMS ENTERED VALUE DATA, BY IMPORTER";
        RUN; 

        PROC SORT DATA = USSALES OUT = USSALES;
            BY US_IMPORTER;
        RUN;

        DATA USSALES;
            MERGE USSALES (IN=A) SOURCECHK (IN=B);
            BY US_IMPORTER;
            IF A & B
            THEN OUTPUT USSALES;
        RUN;

    %END;
%MEND US6_ENTVALUE;

/*********************************************/
/* US-7: FIND BEST HM MATCHES FOR U.S. SALES */
/*********************************************/

%MACRO US7_CONCORDANCE;
    PROC FORMAT;
        VALUE NVFMT
            1 = 'IDENTICAL'
            2 = 'SIMILAR'
            3 = 'CONST VALUE'
            4 = 'FACTS AVAIL';
    RUN;

    %GLOBAL CALC_P2P CALC_CV NVMATCH YEARMONTHH YEARMONTHU;

    %IF %UPCASE(&NV_TYPE) = CV %THEN
    %DO;
        %LET CALC_P2P = NO;
        %LET CALC_CV = YES;
        %MACRO NVMATCH;
            NVMATCH = 3;
        %MEND NVMATCH;
    %END;
    %ELSE
    %IF %UPCASE(&NV_TYPE) = P2P %THEN
    %DO;
        %MACRO NVMATCH;
        %MEND NVMATCH;

        /*--------------------------------------------------------*/
        /* 7-A: CREATE LISTS OF HM AND U.S. PRODUCTS FOR MATCHING */
        /*--------------------------------------------------------*/

        %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN
        %DO;
            %LET YEARMONTHH = HMYEARMONTH;
            %LET YEARMONTHU = YEARMONTHU;
        %END;

        DATA HMSALES;
            SET COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMWTAV;
        RUN;

        PROC SORT DATA = HMSALES OUT = HMMODELS;
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON HMCONNUM;
        RUN;
               

        PROC PRINT DATA = HMMODELS (OBS = &PRINTOBS);
            VAR &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON HMCONNUM &HMCHAR HMVCOM;
            TITLE3 "SAMPLE OF HOME MARKET PRODUCTS FOR CONCORDANCE";
        RUN;

        PROC SORT DATA = USSALES OUT = USMODELS (KEEP = &USMANF &USPRIM USLOT &US_TIME_PERIOD  
                                                        &YEARMONTHU &USMON &USCONNUM &USCHAR 
                                                        AVGVCOM AVGTCOM AVGCOST) NODUPKEY;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM;
        RUN;

        PROC PRINT DATA = USMODELS (OBS = &PRINTOBS);
            VAR &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM &USCHAR AVGVCOM AVGTCOM;
            TITLE3 "SAMPLE OF U.S. PRODUCTS FOR CONCORDANCE";
        RUN;

        /*--------------------------------------------------------------------*/
        /* 7-B: MACRO FOR WINDOW PERIOD PREFERENCES IN ADMINISTRATIVE REVIEWS */
        /*--------------------------------------------------------------------*/

        %MACRO CONTEMP; 
            %IF %UPCASE(&CASE_TYPE) = AR %THEN
            %DO;  
                TIMEDEV = &USMON - &HMMON;
                SELECT (TIMEDEV);
                    WHEN  (0) WNDORDER = 1;
                    WHEN  (1) WNDORDER = 2;
                    WHEN  (2) WNDORDER = 3;
                    WHEN  (3) WNDORDER = 4;
                    WHEN (-1) WNDORDER = 5;
                    WHEN (-2) WNDORDER = 6;
                    OTHERWISE WNDORDER = 7;
                END;
            %END;
        %MEND CONTEMP;

        /*------------------------------------------------*/
        /* 7-C: FIND IDENTICAL MATCHES WITHIN CONSTRAINTS */
        /*------------------------------------------------*/

        DATA IDMODELS;
            SET USMODELS;
            DO J = 1 TO LAST;
                SET HMMODELS POINT = J NOBS = LAST;

                IF &USCONNUM = HMCONNUM THEN    /* Limits matches to identical */
                DO;
                    NVMATCH = 3;    /* Default value, equivalent to CV if no identical or similar match found */
                    LOTDIFF = ABS(USLOT - HMLOT);
                    DIFMER = 0;
                    COSTDIFF = 0;
                    WNDORDER = 0;   /* Default window order preference for investigations */
                    %CONTEMP        /* Execute macro defining window order preferences in admin. reviews */

                    /*-----------------------------------------*/
                    /* US7-C-i: IMPOSE CONSTRAINTS ON POSSIBLE */
                    /*          IDENTICAL MATCHES              */
                    /*-----------------------------------------*/

                    IF WNDORDER LE 6                                            /* sales are contemporaneous             */
                       &AND_P2P_MANF &USMANF &EQUAL_P2P_MANF &HMMANF            /* same manufacturer                     */
                       &AND_PRIME &USPRIM &EQUAL_PRIME &HMPRIM                  /* same prime/non-prime indicator        */ 
                       &AND_TIME &US_TIME_PERIOD &EQUAL_TIME &HM_TIME_PERIOD    /* same quarterly cost time periods      */

                       %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN     /* same high inflation cost time periods */
                       %DO;
                           AND &YEARMONTHH = YEARMONTHU
                       %END;
                    THEN 
                    DO;
                        NVMATCH = 1;
                        OUTPUT IDMODELS;
                    END;
                END;
            END;
        RUN;    

        /*---------------------------------------------------------------*/
        /* 7-D: DETERMINE WHETHER SIMILAR MATCHING NEEDS TO BE ATTEMPTED */
        /*---------------------------------------------------------------*/

        DATA OTHERMODELS;
            MERGE USMODELS (IN = A) IDMODELS (IN = B);
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM;
            IF A AND NOT B;
        RUN;

        PROC CONTENTS NOPRINT DATA = OTHERMODELS  OUT = OTHERMATCH (KEEP = NOBS);
        RUN;

        DATA _NULL_;
            SET OTHERMATCH;
            IF _N_ = 1;
            IF NOBS GT 0 THEN
                FIND_SIMS = "YES";
            ELSE
            IF NOBS = 0 THEN
                FIND_SIMS = "NO";
            CALL SYMPUT('FIND_SIMILARS', FIND_SIMS);
        RUN;

        /*---------------------------------------------------------------*/
        /* 7-E: FIND MOST SIMILAR MATCH WITHIN CONSTRAINTS               */
        /*                                                               */
        /*  Information on VCOM and TCOM for U.S. sales, and VCOM for HM */
        /*  sales must be available in order to calculate DIFMERs.       */
        /*---------------------------------------------------------------*/
    
        %GLOBAL SIMMODELS;  
        %LET SIMMODELS = ; /* Default blank value for name of dataset containing similar matches. */

        %IF &FIND_SIMILARS = NO %THEN
        %DO;
            %GLOBAL DIFCHAR;
            %LET DIFCHAR = ;
        %END;
        %ELSE
        %IF &FIND_SIMILARS = YES %THEN
        %DO;
            %LET SIMMODELS = SIMMODELS;  /* Reset of macro variable name for similar dataset. */

            /*-----------------------------------------------------------*/
            /* 7-E-i: CREATING VARIABLE NAMES FOR DIFFERENCES IN         */
            /*          PRODUCT CHARACTERISTICS                          */
            /*                                                           */
            /*    The names for the new variables will be comprised of   */
            /*    the names of the U.S. product characteristic variables */
            /*    with the suffix "_DIF" added.  For example, the U.S.   */
            /*    product characteristic variable, GRADEU, would lead to */
            /*    the creation of the variable GRADEU_DIF which would    */
            /*    hold the difference in values between GRADEU and the   */
            /*    HM GRADE variable.                                     */
            /*-----------------------------------------------------------*/

            %MACRO MAKE_DIFCHARS;
                %GLOBAL DIFCHAR;
                %LET I = 1;
                %LET DIFCHAR = ;
                %DO %UNTIL (%SCAN(&USCHAR, &I, %STR( )) = %STR());
                    %LET DIFCHAR = &DIFCHAR
                    %SYSFUNC(COMPRESS(%SCAN(&USCHAR, &I,%STR( ))))_DIF;
                    %LET I = %EVAL(&I + 1);
                %END;
            %MEND MAKE_DIFCHARS;
            %MAKE_DIFCHARS;

            /*---------------------------------------*/
            /* 7-E-ii: FIND POSSIBLE SIMILAR MATCHES */
            /*---------------------------------------*/

            DATA SIMMODELS;
                SET OTHERMODELS;
              
                DO J = 1 TO LAST;
                SET HMMODELS POINT = J NOBS = LAST;
                    NVMATCH = 3; /* Default value, equivalent to CV if no identical or similar match found */
                    LOTDIFF = ABS(USLOT - HMLOT);

                    IF HMVCOM GT .  AND AVGVCOM GT . THEN
                        DIFMER = HMVCOM - AVGVCOM;
                    ELSE
                        DIFMER = .;

                    IF DIFMER GT . THEN
                        COSTDIFF = ABS(DIFMER / AVGTCOM);  /* difmer ratio */
                    ELSE
                        COSTDIFF = .;
             
                    WNDORDER = 0;  /* Default window order preference for investigations */
                    %CONTEMP       /* Execute macro defining window order preferences in admin. reviews */

                    /*----------------------------------------------------------*/
                    /* 7-E-ii-a: IMPOSE CONSTRAINTS ON POSSIBLE PRODUCT MATCHES */
                    /*----------------------------------------------------------*/

                    IF 0.20 GE COSTDIFF GT .                                   /* DIFMER less than 20 percent           */
                       AND WNDORDER LE 6                                       /* sales are contemporaneous             */
                       &AND_P2P_MANF &USMANF &EQUAL_P2P_MANF &HMMANF           /* same manufacturer                     */
                       &AND_PRIME &USPRIM &EQUAL_PRIME &HMPRIM                 /* same prime/non-prime indicator        */ 
                       &AND_TIME &US_TIME_PERIOD &EQUAL_TIME &HM_TIME_PERIOD   /* same cost-related time periods        */

                       %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) EQ YES %THEN    /* same high inflation cost time periods */
                       %DO;
                           AND &YEARMONTHH = YEARMONTHU
                       %END;
                    THEN 
                    DO;
                        ARRAY USCHR (*) &USCHAR;
                        ARRAY HMCHR (*) &HMCHAR;
                        ARRAY DIFCHR (*) &DIFCHAR;

                        /*------------------------------------------------------------------*/
                        /* 7-E-ii-b: CALCULATE DIFFERENCES IN PRODUCT CHARACTERISTIC VALUES */
                        /*------------------------------------------------------------------*/

                        DO I = 1 TO DIM(DIFCHR);
                            DIFCHR(I) = ABS(USCHR(I)- HMCHR(I));
                        END;
                        DROP I;
                        NVMATCH = 2;
                        OUTPUT SIMMODELS;
                    END;
                END;
            RUN;
        %END;

        /*-----------------------------------------------------------------*/
        /* 7-E-iii: IDENTIFY THE BEST PRICE-TO-PIRCE MATCHES               */
        /*                                                                 */
        /* Sort the choices in order of preference, choose the best match, */
        /* where CHOICE = 1.                                               */
        /*-----------------------------------------------------------------*/

        DATA P2PMODELS;
            SET IDMODELS &SIMMODELS;
        RUN;

        PROC SORT DATA = P2PMODELS OUT = P2PMODELS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON 
               &USCONNUM NVMATCH &DIFCHAR LOTDIFF WNDORDER COSTDIFF;
        RUN;

        DATA P2PMODS P2PTOP5;
            SET P2PMODELS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM 
               NVMATCH &DIFCHAR LOTDIFF WNDORDER COSTDIFF;

            IF FIRST.&USCONNUM THEN
               CHOICE = 0;

            CHOICE + 1;

            IF CHOICE = 1 THEN
                 OUTPUT P2PMODS;
            IF CHOICE LE 5 THEN
                 OUTPUT P2PTOP5;
        RUN;

        PROC DATASETS LIBRARY=WORK NOLIST;
            DELETE P2PMODELS;
        QUIT;

        PROC PRINT DATA = P2PTOP5 (OBS = &PRINTOBS);
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM;
            PAGEBY &USCONNUM;
            FORMAT NVMATCH NVFMT.;
            VAR &USCHAR &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON   
                HMCONNUM &HMCHAR AVGVCOM AVGTCOM HMVCOM DIFMER &DIFCHAR
                NVMATCH LOTDIFF WNDORDER COSTDIFF CHOICE;
            TITLE3 "CONCORDANCE CHECK - TOP 5 POSSIBLE MATCHES FOR SAMPLE U.S. MODELS";
        RUN;

        PROC SORT DATA = HMMODELS OUT = HMMODELS;
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON HMCONNUM;
        RUN;

        PROC SORT DATA = P2PMODS OUT = P2PMODS;
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON HMCONNUM;
        RUN;

        DATA P2PMODS;
            MERGE P2PMODS (IN = A) HMMODELS (IN = B);
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON HMCONNUM;
            IF A & B THEN OUTPUT P2PMODS;
        RUN;

        PROC SORT DATA = USMODELS OUT = USMODELS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM;
        RUN;

        PROC SORT DATA = P2PMODS OUT = P2PMODS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHH &USMON &USCONNUM;
        RUN;

        /*----------------------------------------------------------*/
        /* 7-E-iv: Merge identical and similar matches into         */
        /*         USMODELS (all U.S. products).  If a U.S. product */
        /*         has no P2P match, it will be matched to CV.      */
        /*----------------------------------------------------------*/
             
        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD 
             ISMODELS (DROP = AVGCOST CHOICE)
             CVMODELS (KEEP = &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM
                              NVMATCH AVGCOST);
            MERGE USMODELS (IN = A) P2PMODS (IN = B);
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM;

            IF NVMATCH = . THEN
                NVMATCH = 3;

            IF A THEN
                OUTPUT COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD;
            IF A & B THEN
                OUTPUT ISMODELS;
            IF A & NOT B THEN
                OUTPUT CVMODELS;
        RUN;

        PROC CONTENTS NOPRINT DATA = ISMODELS  
            OUT = MATCH (KEEP = NOBS);
        RUN;

        DATA _NULL_;
            SET MATCH;
            IF _N_ = 1;
            IF NOBS GT 0 THEN
                MATCH = "YES";
            ELSE
            IF NOBS = 0 THEN
                MATCH = "NO";
            CALL SYMPUT('CALC_P2P', MATCH);
        RUN;

        PROC CONTENTS NOPRINT DATA = CVMODELS  
            OUT = CV (KEEP = NOBS);
        RUN;

        DATA _NULL_;
            SET CV;
            IF _N_ = 1;
            IF NOBS GT 0 THEN
                CVCALC = "YES";
            ELSE IF NOBS = 0 THEN
                CVCALC = "NO";
            CALL SYMPUT('CALC_CV', CVCALC);
        RUN;

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD
                  OUT = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD;
            BY &USMANF &USPRIM USLOT &USCONNUM &US_TIME_PERIOD &YEARMONTHU &USMON;
        RUN;

        PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD (OBS = &PRINTOBS);
            FORMAT NVMATCH NVFMT.;
            VAR &USMANF &USPRIM USLOT &US_TIME_PERIOD &YEARMONTHU &USMON &USCONNUM &USCHAR
                &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &YEARMONTHH &HMMON HMCONNUM &HMCHAR 
                AVGVCOM AVGTCOM HMVCOM DIFMER &DIFCHAR 
                NVMATCH LOTDIFF WNDORDER COSTDIFF;
            TITLE3 "FULL CONCORDANCE - THE BEST MODEL MATCH SELECTIONS";
        RUN;
    %END;
%MEND US7_CONCORDANCE;

/**************************************************/
/* US-8: Merge CM LOT adjustments into U.S. sales */
/**************************************************/

%MACRO US8_LOTADJ;
    %IF %UPCASE(&LOT_ADJUST) = HM %THEN
    %DO;
        PROC SORT DATA = ISMODELS OUT = ISMODELS; 
            BY USLOT HMLOT;
        RUN;

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._LOTADJ
                  OUT = HMLOTDATA (KEEP = USLOT HMLOT LOTADJ);
        BY USLOT HMLOT;
        RUN;

        PROC PRINT DATA = HMLOTDATA;
            TITLE3 "CM LOT ADJUSTMENT FACTOR";
        RUN;

        DATA ISMODELS;
            MERGE ISMODELS (IN=A) HMLOTDATA (IN=B);
            BY USLOT HMLOT;
            IF A;
            LENGTH LOTHDATA $3.;
            IF A & B 
            THEN LOTHDATA = 'YES';
            ELSE
            IF A & NOT B THEN
            DO;
                LOTHDATA = 'NO';
                LOTADJ  = 0;
            END;
        RUN;
    %END;
    %ELSE
    %IF %UPCASE(&LOT_ADJUST) = NO %THEN
    %DO;
        DATA ISMODELS; 
            SET ISMODELS;
            LENGTH LOTHDATA $3.;
            LOTHDATA = 'NO';  /* LOT data is not available */
            LOTADJ = 0;
        RUN;
    %END;
%MEND US8_LOTADJ;

/*****************************************************************/
/* US-9: CALCULATE COMMISSION AND CEP OFFSETS, NV AND COMPARISON */
/*       RESULTS                                                 */
/*                                                               */
/* Calculate commission offsets, and then use any remaining CM   */
/* indirects (RINDSELLH) to compute the CEP offset.              */
/*****************************************************************/

%MACRO US9_OFFSETS;
        /* Commissions are greater in the CM than in the U.S. market. */

        IF COMMDOL GT USCOMM THEN
        DO;
            COMOFFSET = -1 * MIN(USINDCOMM, (COMMDOL - USCOMM));
            RINDSELLH = INDDOL;
        END;

        /* Commissions are greater in the U.S. market than in the CM. */

        ELSE
        IF USCOMM GT COMMDOL THEN
        DO;
            COMOFFSET = MIN(ICOMMDOL, (USCOMM - COMMDOL));
            RINDSELLH = INDDOL - COMOFFSET;
        END;

        /* Commissions are equal in both markets */

        ELSE
        DO;                    
            COMOFFSET = 0; 
            RINDSELLH = INDDOL;
        END;

        /* CEP Offset */

        IF USECEPOFST = 'YES' THEN
            CEPOFFSET = MIN((CEPICC + CEPISELL), RINDSELLH);
        ELSE
            CEPOFFSET = 0;
%MEND US9_OFFSETS;

/***************************************************************/
/** US-10: PRICE-2-PRICE TRANSACTION-SPECIFIC LOT ADJUSTMENTS, */
/**        COMMISSION, AND CEP OFFSETS                         */
/***************************************************************/

%MACRO US10_LOT_ADJUST_OFFSETS;
    %IF &CALC_P2P = YES %THEN
    %DO;
        PROC SORT DATA = ISMODELS (DROP = &USCHAR &HMCHAR &DIFCHAR) OUT = ISMODELS;
            BY &USMANF &USPRIM USLOT &USCONNUM &US_TIME_PERIOD &YEARMONTHU &USMON;
        RUN;

        PROC SORT DATA = USSALES OUT = USSALES;
            BY &USMANF &USPRIM USLOT &USCONNUM &US_TIME_PERIOD &YEARMONTHU &USMON;
        RUN;

        %MACRO P2P_ADJUSTMT_CEP;
            %IF &CEP_PRESENT = YES %THEN
            %DO;
                %IF %UPCASE(&ALLOW_CEP_OFFSET) = YES %THEN
                %DO;
                    IF SALE_TYPE = 'CEP' THEN USECEPOFST = 'YES';
                %END;
            %END;
        %MEND P2P_ADJUSTMT_CEP;

        DATA NVIDSIM;
            A = 0;  /* Reset the IN = flags to false force all ISMODELS variables to */
            B = 0;  /*     be reread every time the merge statement is executed      */
            MERGE USSALES (IN = A) ISMODELS (IN = B);
            BY &USMANF &USPRIM USLOT &USCONNUM &US_TIME_PERIOD &YEARMONTHU &USMON;
            IF A & B THEN
            DO;
                LENGTH USECEPOFST $3.;                /* CEP offset indicator     */
                USECEPOFST = 'NO';
                %MULTIPLE_CURR;                       /* Convert HM values in non-HM currency */
                LOTADJMT   = 0;                       /*     into HM currency, if necessary   */
                %P2P_ADJUSTMT_CEP;
                %P2P_ADJUSTMT_LOTADJ;
                INDDOL = (HMICC + HMISELL) * &XRATE1; /* HM total indirects       */
                COMMDOL = HMCOMM * &XRATE1;           /* HM commissions           */
                ICOMMDOL = HMINDCOM * &XRATE1;        /* HM surrogate commission  */
                %US9_OFFSETS                          /* Calculate offsets        */
                FARATE   = 0;                         /* P2P facts available rate */
                OUTPUT NVIDSIM;
            END;
        RUN;

        PROC PRINT DATA = NVIDSIM (OBS = &PRINTOBS);
            TITLE3 "CALCULATION OF COMMISSION OFFSETS FOR PRICE-TO-PRICE COMPARISONS";
        RUN;

    %END;
%MEND US10_LOT_ADJUST_OFFSETS;

/***********************************************************************/
/* US-11: SELLING EXPENSES,PROFIT AND OFFSETS FOR CONSTRUCTED VALUE    */
/***********************************************************************/

%MACRO US11_CVSELL_OFFSETS; 
    %IF %UPCASE(&CVSELL_TYPE) = CM %THEN
    %DO;

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CVSELL (RENAME = (HMLOT = USLOT))
                  OUT = CMCVSELL;
            BY USLOT;
        RUN;

        PROC PRINT DATA = CMCVSELL;
            TITLE3 "COMPARISON MARKET SELLING EXPENSE AND PROFIT RATIOS FOR CV";
        RUN;

        PROC SORT DATA = CVMODELS OUT = CVMODELS;
            BY USLOT;
        RUN;

        DATA CVMODS NOCVSELL;
            MERGE CVMODELS (IN=A) CMCVSELL (IN=B);
            BY USLOT;
            LENGTH CVSELLPR $3.;

             IF A & NOT B THEN
            DO;
                DSELCV = 0;
                ISELCV = 0;
                COMMCV = 0;
                ICOMMCV = 0;
                INVCARCV = 0;
                CVSELLPR = 'NO';
                OUTPUT NOCVSELL;
            END;
            ELSE
            IF A & B THEN OUTPUT CVMODS;
        RUN;

        PROC PRINT DATA = NOCVSELL;
            TITLE3 "U.S. MODELS WITH NO CV SELLING EXPENSES OR PROFIT";
        RUN;

        PROC SORT DATA = CVMODS OUT = CVMODS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
        RUN;

        PROC SORT DATA = USSALES OUT = USSALES;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
        RUN;

        DATA NVCV;
            MERGE USSALES (IN=A) CVMODS (IN=B);
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
            IF A & B;
        RUN;

    %END;

    %MACRO CV_ADJUSTMT_CEP;
    %MEND CV_ADJUSTMT_CEP;

    %IF &CEP_PRESENT = YES %THEN
    %DO;
        %IF %UPCASE(&ALLOW_CEP_OFFSET) = YES %THEN
        %DO;
            %MACRO CV_ADJUSTMT_CEP;
                IF SALE_TYPE = 'CEP' THEN USECEPOFST = 'YES';
            %MEND CV_ADJUSTMT_CEP;
        %END;
    %END;

    DATA NVCV;
        SET NVCV;

            CVSELLPR = 'YES';
            DSELCV   = DSELCVR * AVGCOST;  /* CM direct selling, excluding CREDCV */
            ISELCV   = ISELCVR * AVGCOST;  /* CM indirect selling, excluding INVCARCV */
            COMMCV   = COMMCVR * AVGCOST;  /* CM commissions */
            ICOMMCV  = ICOMCVR * AVGCOST;  /* CM surrogate commission */
            INVCARCV = INVCVR  * AVGCOST;  /* CM inventory carrying exp */
            CVPROFIT = PRATECV * AVGCOST;  /* Amount of CV profit, in CM currency */

            LENGTH USECEPOFST $3.;  /* CEP offset indicater */
            USECEPOFST = 'NO';
            LOTDIFF    = 0;
            LOTADJMT   = 0;
            %CV_ADJUSTMT_CEP    /* Reset CEP offset indicator when allowing a CEP offset */

            TOTCV    = AVGCOST + DSELCV + ISELCV + COMMCV + CVPROFIT;
            CREDCV   = CREDCVR * TOTCV;
        
            INDDOL   = (ISELCV + INVCARCV)* &XRATE1; /* CV total indirects for offsets */
            COMMDOL  = COMMCV  * &XRATE1;            /* CV commissions  for offsets */
            ICOMMDOL = ICOMMCV * &XRATE1;            /* CV surrogate commission for offsets */
            %US9_OFFSETS;
            FARATE   = 0;  /* CV facts available rate */
    RUN;

    PROC PRINT DATA = NVCV (OBS = &PRINTOBS);
        TITLE3 "CALCULATION OF CONSTRUCTED VALUE AND COMMISSION OFFSETS FOR CV COMPARISONS";
    RUN;

%MEND US11_CVSELL_OFFSETS;

/**************************************************************************/
/* US-12: COMBINE SALES WITH P2P COMPARISONS WITH THOSE COMPARED TO CV    */
/*                                                                        */
/*    In addition to the variables that are required for both P2P and     */
/*    CV comparisons from this point forward, there are some required for */
/*    just P2P and others for just CV.  Below, the macro variables        */
/*    P2P_VARS and CV_VARS  are created which contain lists of such extra */
/*    variables required for each type of comparison. When, for example   */
/*    there are P2P comparisons, P2P_VARS will be set to: HMNETPRI DIFMER */
/*    LOTDIFF LOTADJMT, allowing these variables to be carried forward    */
/*    for later use.  However, when there is no P2P comparison, P2P_VARS  */
/*    will be set to a blank value so that the calculations will not call */
/*    for these non-existent variables.                                   */
/**************************************************************************/

%MACRO US12_COMBINE_P2P_CV; 

    %GLOBAL P2P_VARS CV_VARS ;

    %IF &CALC_P2P = YES AND &CALC_CV = YES %THEN
    %DO;

        DATA  USSALES; 
            SET NVIDSIM NVCV (DROP = DSELCVR ISELCVR COMMCVR ICOMCVR INVCVR CREDCVR AVGCOST);
        RUN;

        %LET P2P_VARS = HMNETPRI DIFMER LOTDIFF LOTADJMT;                           /* P2P vars required */
        %LET CV_VARS = DSELCV ISELCV COMMCV ICOMMCV INVCARCV CREDCV CVPROFIT TOTCV; /* CV vars to keep   */

    %END;
    %ELSE
    %IF &CALC_P2P = YES AND &CALC_CV = NO %THEN
    %DO;
        DATA USSALES;
            SET NVIDSIM;
        RUN;

        %LET P2P_VARS =  HMNETPRI DIFMER LOTDIFF LOTADJMT;
        %LET CV_VARS = ;

    %END;
    %ELSE
    %IF &CALC_P2P = NO AND &CALC_CV = YES %THEN
    %DO;
        DATA USSALES;
            SET NVCV (DROP=DSELCVR ISELCVR COMMCVR ICOMCVR INVCVR CREDCVR AVGCOST);
        RUN;

        %LET P2P_VARS =  ;
        %LET CV_VARS = DSELCV ISELCV COMMCV ICOMMCV INVCARCV CREDCV CVPROFIT TOTCV; 
    %END;
%MEND US12_COMBINE_P2P_CV;

/*****************************/
/* US-13:  COHENS-D ANALYSIS */
/*****************************/
 
%MACRO US13_COHENS_D_TEST;
    TITLE3 "THE COHENS-D TEST";

    /**************************************************/
    /* US-13-A. Create macros needed re: manufacturer */
    /* and prime for price comparisons.               */
    /**************************************************/

    %IF %UPCASE(&NV_TYPE) = CV %THEN
    %DO;
        %LET HMMANUF = NO;
        %LET HMPRIME = NO;
    %END;

    /***********************************************************************/
    /* Set up null testing code when there is no CM and U.S. manufacturer. */
    /***********************************************************************/

    %IF %UPCASE(&USMANUF) EQ NA OR %UPCASE(&HMMANUF)= NO %THEN
    %DO;
        %MACRO DPMANF_RENAME;
        %MEND DPMANF_RENAME;
        %MACRO DPMANF_CONDITION;
        %MEND DPMANF_CONDITION;
        %MACRO DPMANF_SELECT_BASE;
        %MEND DPMANF_SELECT_BASE;
        %MACRO DPMANF_SELECT_TEST;
        %MEND DPMANF_SELECT_TEST;
        %MACRO DPMANF_WHERE;
        %MEND DPMANF_WHERE;
    %END;

    /***************************************************************/
    /* Set up testing code when there is CM and U.S. manufacturer. */
    /***************************************************************/

    %ELSE
    %IF %UPCASE(&USMANUF) NE NA AND %UPCASE(&HMMANUF) EQ YES %THEN
    %DO;
        %MACRO DPMANF_RENAME;
            &USMANF = BASE_&USMANF 
        %MEND DPMANF_RENAME;
        %MACRO DPMANF_CONDITION;
            &USMANF  = BASE_&USMANF AND 
        %MEND DPMANF_CONDITION;
        %MACRO DPMANF_SELECT_BASE;
            BP.BASE_&USMANF,
        %MEND DPMANF_SELECT_BASE;
        %MACRO DPMANF_SELECT_TEST;
             DP.&USMANF,
        %MEND DPMANF_SELECT_TEST;
        %MACRO DPMANF_WHERE;
            BP.BASE_&USMANF EQ DP.&USMANF AND
        %MEND DPMANF_WHERE;
    %END;

    /****************************************************************/
    /* Set up null testing code when there is no CM and U.S. prime. */
    /****************************************************************/

    %IF %UPCASE(&USPRIME) EQ NA OR %UPCASE(&HMPRIME) = NO %THEN
    %DO;
        %MACRO DPPRIME_RENAME;
        %MEND DPPRIME_RENAME;
        %MACRO DPPRIME_CONDITION;
        %MEND DPPRIME_CONDITION;
        %MACRO DPPRIME_SELECT_BASE;
        %MEND DPPRIME_SELECT_BASE;
        %MACRO DPPRIME_SELECT_TEST;
        %MEND DPPRIME_SELECT_TEST;
        %MACRO DPPRIME_WHERE;
        %MEND DPPRIME_WHERE;
    %END;

    /********************************************************/
    /* Set up testing code when there is CM and U.S. prime. */
    /********************************************************/

    %ELSE
    %IF %UPCASE(&USPRIME) NE NA AND %UPCASE(&HMPRIME) = YES %THEN
    %DO;
        %MACRO DPPRIME_RENAME;
            &USPRIM = BASE_&USPRIM
        %MEND DPPRIME_RENAME;
        %MACRO DPPRIME_CONDITION;
            &USPRIM  = BASE_&USPRIM AND
        %MEND DPPRIME_CONDITION;
        %MACRO DPPRIME_SELECT_BASE;
            BP.BASE_&USPRIM,
        %MEND DPPRIME_SELECT_BASE;
        %MACRO DPPRIME_SELECT_TEST;
            DP.&USPRIM,
        %MEND DPPRIME_SELECT_TEST;
        %MACRO DPPRIME_WHERE;
            BP.BASE_&USPRIM EQ DP.&USPRIM AND
        %MEND DPPRIME_WHERE;
    %END;

    /**********************************************/
    /* Set up null code when basis is not REGION. */
    /**********************************************/

    %IF %UPCASE(&DP_REGION_DATA) = REGION %THEN
    %DO;
        %MACRO DPREGION_PRINT_LABEL ;
        %MEND DPREGION_PRINT_LABEL;
    %END;

    /**************************************/
    /* Set up code when basis not REGION. */
    /**************************************/

    %ELSE 
    %DO;
        %MACRO DPREGION_PRINT_LABEL;
            &DP_REGION = "SOURCE FOR*DP REGION*(&DP_REGION)"
        %MEND DPREGION_PRINT_LABEL;
    %END;

    /************************************/
    /* Set up code when basis not TIME. */
    /************************************/

    %IF %UPCASE(&DP_TIME_CALC) = YES %THEN
    %DO;
        %MACRO DPPERIOD_PRINT_LABEL;
            &USSALEDATE = "U.S. DATE*OF SALE*(&USSALEDATE)"
        %MEND DPPERIOD_PRINT_LABEL;
    %END;  

    /********************************************/
    /* Set up null code when basis is not TIME. */
    /********************************************/
 
    %IF %UPCASE(&DP_TIME_CALC) = NO %THEN
    %DO;
        %MACRO DPPERIOD_PRINT_LABEL;
        %MEND DPPERIOD_PRINT_LABEL;
    %END;        

    /*****************************************************************/
    /*  US-13-B Calculate net price for Cohens-d Analysis and set up */
    /*            regions, purchasers and time periods.              */
    /*****************************************************************/

    DATA DPSALES;
        SET USSALES;

            DP_COUNT = _N_;

            DP_NETPRI = USGUP + USGUPADJ - USDISREB - USDOMMOVE - 
                        USINTLMOVE - USCREDIT - USDIRSELL - USCOMM -  
                        CEPICC - CEPISELL - CEPOTHER - CEPROFIT;

            /*********************************************************/
            /*    US-13-B-i Establish the region, time and purchaser */
            /*    variables for the analysis when there are existing */
            /*    variables in the data for the same.  If the time   */
            /*    variable for the analysis is being calculated by   */
            /*    using the quarter default, do that here.           */
            /*********************************************************/

            DP_PURCHASER = &DP_PURCHASER;

            %IF %UPCASE(&DP_REGION_DATA) EQ REGION %THEN
            %DO;
                DP_REGION = &DP_REGION;
                %LET REGION_PRINT_VARS = DP_REGION;
            %END;
            %GLOBAL DP_PERIOD;
            %IF %UPCASE(&DP_TIME_CALC) = NO %THEN
            %DO;
                DP_PERIOD = &DP_TIME;
                %LET DP_PERIOD = &DP_TIME;
                %LET PERIOD_PRINT_VARS = DP_PERIOD;
            %END;    
            %ELSE %IF %UPCASE(&DP_TIME_CALC) = YES %THEN
            %DO;
                FIRSTMONTH =MONTH("&BEGINPERIOD"D);
                DPMONTH=MONTH(&USSALEDATE)+(YEAR(&USSALEDATE)-YEAR("&BEGINPERIOD"D))*12;
                DP_PERIOD="QTR"||PUT(INT(1+(DPMONTH-FIRSTMONTH)/3),Z2.);
                DROP FIRSTMONTH DPMONTH;
                %LET DP_PERIOD = &USSALEDATE;
                %LET PERIOD_PRINT_VARS = &DP_PERIOD DP_PERIOD;
            %END;

    RUN;

        /*********************************************************************/
        /*    US13-B-ii Attach region designations using state/zip codes,    */ 
        /*    when required.                                                 */
        /*********************************************************************/

        %IF %UPCASE(&DP_REGION_DATA) NE REGION %THEN
        %DO;

            PROC FORMAT;
                VALUE $REGION
                    "PR", "VI"          = "TERRITORY"

                    "CT", "ME", "MA",
                    "NH", "RI", "VT",
                    "NJ", "NY", "PA"    = "NORTHEAST"

                    "IN", "IL", "MI",
                    "OH", "WI", "IA",
                    "KS", "MN", "MO",
                    "NE", "ND", "SD"    = "MIDWEST"

                    "AL", "AR", "DC",
                    "DE", "FL", "GA",
                    "KY", "LA", "MD",
                    "MS", "NC", "TN",
                    "OK", "SC", "TX",
                    "VA", "WV"            = "SOUTH"

                    "AK", "AZ", "CA",
                    "CO", "HI", "ID", 
                    "MT", "NM", "NV",
                    "OR", "UT", "WY",
                    "WA"                  = "WEST";
            RUN;

            %LET REGION_PRINT_VARS = &DP_REGION DP_REGION;

            DATA DPSALES;
                SET DPSALES;

                %IF %UPCASE(&DP_REGION_DATA) = ZIP %THEN
                %DO;
                    LENGTH VALID_ZIP $3.;
                    ZIPVAR_TYPE = VTYPE(&DP_REGION);
                    IF ZIPVAR_TYPE = "C" THEN
                    DO;
                        IF FINDC(&DP_REGION,"-1234567890 ", "K") GT 0 THEN VALID_ZIP = "NO";
                        ELSE VALID_ZIP = "YES";
                    END;
                    ELSE 
                    DO;
                        IF 500 LT &DP_REGION LT 100000 THEN VALID_ZIP = "YES";
                        ELSE VALID_ZIP = "NO";
                    END;
                    
                    IF VALID_ZIP = "YES" THEN STATE = ZIPSTATE(&DP_REGION);
                    ELSE STATE = "";
                    %LET STATE = STATE;
                    DROP ZIPVAR_TYPE VALID_ZIP;
                %END;

                %IF %UPCASE(&DP_REGION_DATA) = STATE %THEN
                %DO;
                    %LET STATE = UPCASE(&DP_REGION);
                %END;

                LENGTH DP_REGION $9;
                DP_REGION = PUT(&STATE, REGION.);
            RUN;

        %END;

        DATA DPSALES USSALES (DROP = DP_NETPRI DP_PURCHASER DP_REGION DP_PERIOD);
            SET DPSALES;
        RUN;

        PROC PRINT DATA = DPSALES (OBS = &PRINTOBS) SPLIT = "*";
            VAR &USMANF &USPRIM USLOT &USCONNUM USGUP USGUPADJ USDISREB USDOMMOVE
                USINTLMOVE USCREDIT USDIRSELL  
                USCOMM USICC USISELL CEPICC CEPISELL CEPOTHER CEPROFIT DP_NETPRI 
                DP_PURCHASER &PERIOD_PRINT_VARS &REGION_PRINT_VARS;
                LABEL DP_NETPRI = "NET PRICE*FOR COHENS-D*ANALYSIS"
                      %DPPERIOD_PRINT_LABEL
                      DP_PERIOD = "TIME PERIOD*FOR COHENS-D*ANALYSIS"
                      %DPREGION_PRINT_LABEL
                      DP_REGION = "REGION FOR*COHENS-D*ANALYSIS"
                      DP_PURCHASER = "PURCHASER*FOR COHENS-D*ANALYSIS*(&DP_PURCHASER)";
            TITLE4 "NET PRICE CALCULATIONS AND PURCHASER/TIME/REGION ASSIGNMENTS FOR COHENS-D";
        RUN;

    /***************************************************************/
    /* US-13-C. Calculate Information Using Comparable Merchandise */
    /*          Criteria for Cohens-D.                             */
    /***************************************************************/

    PROC MEANS NWAY DATA = DPSALES VARDEF = WEIGHT NOPRINT;
        CLASS &USMANF &USPRIM USLOT &USCONNUM;
        VAR DP_NETPRI;
        WEIGHT &USQTY;
        OUTPUT OUT = DPCONNUM (DROP = _:)
               N = TOTAL_CONNUM_OBS
               SUMWGT = TOTAL_CONNUM_QTY
               SUM = TOTAL_CONNUM_VALUE
               MEAN = AVG_CONNUM_PRICE
               MIN = MIN_CONNUM_PRICE
               MAX = MAX_CONNUM_PRICE
               STD = STD_CONNUM_PRICE;
    RUN;

    PROC PRINT DATA = DPCONNUM (OBS = &PRINTOBS) SPLIT = "*";
        LABEL &USCONNUM = "CONTROL NUMBER"
              TOTAL_CONNUM_OBS = "NUMBER*  OF  *OBSERVATIONS" 
              TOTAL_CONNUM_QTY = "  TOTAL *QUANTITY"
              TOTAL_CONNUM_VALUE = " TOTAL *VALUE "
              AVG_CONNUM_PRICE = "AVERAGE*PRICE "
              MIN_CONNUM_PRICE = "LOWEST*PRICE "
              MAX_CONNUM_PRICE = "HIGHEST*PRICE "
              STD_CONNUM_PRICE = "STANDARD*DEVIATION*IN PRICE";
        BY &USMANF &USPRIM USLOT;
        ID &USMANF &USPRIM USLOT;
        SUM TOTAL_CONNUM_QTY TOTAL_CONNUM_VALUE;
        TITLE4 "OVERALL STATISTICS FOR EACH CONTROL NUMBER (ALL SALES--NO SEPARATION OF TEST AND BASE GROUP VALUES)";
    RUN;

    /************************************************************************/
    /* US-13-D. STAGE 1: Test Control Numbers by Region, Time and Purchaser */
    /************************************************************************/

        %MACRO COHENS_D(DP_GROUP,TITLE4);

            /*************************************************************/
            /* US-13-D-ii-a. Put sales to be tested for each round in    */
            /*   DPSALES_TEST. (All sales will remain in DPSALES.) Sales */
            /*   missing group information will not be tested, but will  */
            /*   be kept in the pool for purposes of calculating base    */
            /*   group statistics.                                       */
            /*************************************************************/

            %LET DSID = %SYSFUNC(OPEN(DPSALES));
            %LET VARNUM = %SYSFUNC(VARNUM(&DSID, &DP_GROUP));
            %LET VARTYPE = %SYSFUNC(VARTYPE(&DSID, &VARNUM));
            %LET RC = %SYSFUNC(CLOSE(&DSID));

            DATA DPSALES_TEST NO_&DP_GROUP._TEST;
                SET DPSALES;
                    %IF &VARTYPE = C %THEN
                    %DO;
                        IF &DP_GROUP = "" THEN
                    %END;
                    %ELSE
                    %IF &VARTYPE = N %THEN
                    %DO;
                        IF &DP_GROUP = . THEN
                    %END;
                    OUTPUT NO_&DP_GROUP._TEST;
                    ELSE OUTPUT DPSALES_TEST;
            RUN;
                        
            PROC PRINT DATA = NO_&DP_GROUP._TEST (OBS = &PRINTOBS);
                TITLE4 "SAMPLE OF SALES FOR WHICH THERE IS NO DESIGNATION FOR &DP_GROUP, SAMPLE OF &PRINTOBS" ;
            RUN;

            /***************************************************/
            /* US-13-D-ii-b. Calculate test group information. */
            /***************************************************/

            TITLE4 "&TITLE4";

            PROC MEANS NWAY DATA = DPSALES_TEST VARDEF = WEIGHT NOPRINT;
                CLASS &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
                VAR DP_NETPRI;
                WEIGHT &USQTY;
                OUTPUT OUT = &DP_GROUP (DROP = _:)
                       N = TEST_&DP_GROUP._OBS
                       SUMWGT = TEST_&DP_GROUP._QTY
                       SUM = TEST_&DP_GROUP._VALUE
                       MEAN = TEST_AVG_&DP_GROUP._PRICE
                       STD = TEST_&DP_GROUP._STD;
            RUN;

            PROC PRINT DATA = &DP_GROUP (OBS = &PRINTOBS) SPLIT = "*";
                BY &USMANF &USPRIM USLOT &USCONNUM;
                ID &USMANF &USPRIM USLOT &USCONNUM;
                LABEL     &USCONNUM = "CONTROL NUMBER"
                        &DP_GROUP = "TEST*GROUP*(&DP_GROUP.)"
                        TEST_&DP_GROUP._OBS = "TRANSACTIONS*  IN  *TEST GROUP"
                        TEST_&DP_GROUP._QTY = "TOTAL QTY*  OF  *TEST GROUP"
                        TEST_&DP_GROUP._VALUE = "TOTAL VALUE*  OF  *TEST GROUP" 
                        TEST_AVG_&DP_GROUP._PRICE = "WT AVG PRICE*  OF  *TEST GROUP"
                        TEST_&DP_GROUP._STD = "STANDARD*DEVIATION*TEST GROUP*PRICE";
                TITLE5 "CALCULATION OF TEST GROUP STATISTICS BY &DP_GROUP";
            RUN;

            /*****************************************************************/
            /*  US-13-D-ii-c. Attach overall control number information to   */
            /*    each test group. Then separate base v. test group          */
            /*    information re: value, quantity, observations, etc.  For   */
            /*    example, if there are three purchasers (A,B and C), when   */
            /*    purchaser A is in the test group, purchasers B and C will  */
            /*    be the base/comparison group.                              */
            /*                                                               */
            /*    If there is no base group for a control number because all */
            /*    sales are to one purchaser, for example, (as evidenced by  */
            /*    zero obs/quantity) then no Cohens-d coefficient will be    */
            /*    calculated.                                                */
            /*****************************************************************/

            DATA DPGROUP NO_BASE_GROUP;  
                MERGE &DP_GROUP (IN=A) DPCONNUM (IN=B);
                BY &USMANF &USPRIM USLOT &USCONNUM;
                IF A & B;
                    BASE_&DP_GROUP._OBS   = TOTAL_CONNUM_OBS   - TEST_&DP_GROUP._OBS;
                    BASE_&DP_GROUP._QTY   = TOTAL_CONNUM_QTY   - TEST_&DP_GROUP._QTY;
                    BASE_&DP_GROUP._VALUE = TOTAL_CONNUM_VALUE - TEST_&DP_GROUP._VALUE;
                    IF BASE_&DP_GROUP._QTY EQ 0 OR BASE_&DP_GROUP._OBS EQ 0 THEN OUTPUT NO_BASE_GROUP;
                    ELSE DO;
                        BASE_AVG_&DP_GROUP._PRICE = BASE_&DP_GROUP._VALUE / BASE_&DP_GROUP._QTY;
                        &DP_GROUP._QTY_RATIO = BASE_&DP_GROUP._QTY / TOTAL_CONNUM_QTY;
                        OUTPUT DPGROUP;
                    END;
            RUN;

            PROC PRINT DATA = DPGROUP (OBS=&PRINTOBS) SPLIT="*";
                BY &USMANF &USPRIM USLOT &USCONNUM;
                ID &USMANF &USPRIM USLOT &USCONNUM;
                VAR &DP_GROUP TOTAL_CONNUM_OBS TEST_&DP_GROUP._OBS BASE_&DP_GROUP._OBS
                    TOTAL_CONNUM_QTY TEST_&DP_GROUP._QTY BASE_&DP_GROUP._QTY
                    TOTAL_CONNUM_VALUE  TEST_&DP_GROUP._VALUE BASE_&DP_GROUP._VALUE
                    &DP_GROUP._QTY_RATIO BASE_AVG_&DP_GROUP._PRICE ;
                FORMAT TOTAL_CONNUM_QTY TEST_&DP_GROUP._QTY BASE_&DP_GROUP._QTY
                    TOTAL_CONNUM_VALUE TEST_&DP_GROUP._VALUE BASE_&DP_GROUP._VALUE &COMMA_FORMAT.;
                LABEL &USCONNUM="CONTROL NUMBER"
                    &DP_GROUP="TEST*GROUP*(&DP_GROUP.)"
                    TOTAL_CONNUM_OBS=" TOTAL *CONTROL NUMBER*TRANSACTIONS* ( A ) "
                    TEST_&DP_GROUP._OBS="TRANSACTIONS*  IN  *TEST GROUP* ( B ) "
                    BASE_&DP_GROUP._OBS="TRANSACTIONS*  IN  *BASE GROUP*(C = A-B)"
                    TOTAL_CONNUM_QTY=" TOTAL QUANTITY*  OF  *CONTROL NUMBER* ( D ) " 
                    TEST_&DP_GROUP._QTY="TEST GROUP*QUANTITY* ( E ) "
                    BASE_&DP_GROUP._QTY="BASE GROUP*QUANTITY*(F = D-E)"
                    TOTAL_CONNUM_VALUE=" TOTAL VALUE *  OF  *CONTROL NUMBER*  ( G ) "
                    TEST_&DP_GROUP._VALUE="TEST GROUP* VALUE  * ( H )  "
                    BASE_&DP_GROUP._VALUE="BASE GROUP* VALUE  * (I = G-H)"
                    &DP_GROUP._QTY_RATIO="QUANTITY* RATIO *(J = F/D)"
                    BASE_AVG_&DP_GROUP._PRICE="WT AVG PRICE*  OF  *BASE GROUP*(K = I/F)" ;
                    TITLE5 "CALCULATION OF BASE GROUP STATISTICS BY &DP_GROUP";
            RUN;

            /******************************************************************/
            /* US-13-D-ii-d. Attach sales of base group control numbers to    */
            /*   group-level information calculated above.  In the example of */
            /*   three purchasers (A,B&C), when the DP_GROUP = A above, all   */
            /*   sales to purchasers B&C will be joined. (See the condition   */
            /*   DP_GROUP NE BASE_GROUP in the BASECALC dataset below.)       */
            /******************************************************************/

            DATA BASE_PRICES;
                SET DPSALES (KEEP = &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP DP_NETPRI &USQTY);
                RENAME %DPMANF_RENAME
                       %DPPRIME_RENAME
                       USLOT = BASE_LOT
                       &USCONNUM = BASE_CONNUM
                       &DP_GROUP = BASE_GROUP;
            RUN;

            PROC SORT DATA = DPGROUP (KEEP = &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP
                                             TEST_&DP_GROUP._OBS TEST_AVG_&DP_GROUP._PRICE
                                             TEST_&DP_GROUP._STD BASE_&DP_GROUP._OBS
                                             BASE_AVG_&DP_GROUP._PRICE &DP_GROUP._QTY_RATIO)
                      OUT = DPGROUP_VAR_SUBSET;
                BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
            RUN;

            PROC SQL NOPRINT;
                CREATE TABLE BASECALC AS
                SELECT %DPMANF_SELECT_BASE
                       %DPPRIME_SELECT_BASE
                       BP.BASE_LOT,
                       BP.BASE_CONNUM, BP.BASE_GROUP, BP.&USQTY, BP.DP_NETPRI,
                       %DPMANF_SELECT_TEST
                       %DPPRIME_SELECT_TEST
                       DP.USLOT,
                       DP.&USCONNUM, DP.&DP_GROUP, DP.BASE_&DP_GROUP._OBS,
                       DP.TEST_&DP_GROUP._OBS, DP.&DP_GROUP._QTY_RATIO 
                 FROM BASE_PRICES AS BP, DPGROUP_VAR_SUBSET AS DP
                 WHERE %DPMANF_WHERE
                       %DPPRIME_WHERE
                       BP.BASE_LOT EQ DP.USLOT AND
                       BP.BASE_CONNUM EQ DP.&USCONNUM AND
                       BP.BASE_GROUP NE DP.&DP_GROUP AND
                       DP.BASE_&DP_GROUP._OBS GE 2 AND
                       DP.TEST_&DP_GROUP._OBS GE 2 AND
                       DP.&DP_GROUP._QTY_RATIO GE 0.05;
            QUIT;

            /**************************************************************/
            /* US-13-D-ii-e. Calculate the base group standard deviation. */
            /**************************************************************/

            PROC MEANS NWAY DATA = BASECALC VARDEF = WEIGHT NOPRINT;
                CLASS &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
                WEIGHT &USQTY;
                VAR DP_NETPRI;
                OUTPUT OUT = BASESTD (DROP = _:) STD = BASE_STD;
            RUN;

            PROC PRINT DATA = BASESTD (OBS = &PRINTOBS) SPLIT="*";
                BY &USMANF &USPRIM USLOT &USCONNUM;
                ID &USMANF &USPRIM USLOT &USCONNUM;
                VAR &DP_GROUP BASE_STD;
                LABEL &USCONNUM = "CONTROL NUMBER"
                      &DP_GROUP = "TEST GROUP*(&DP_GROUP.)"
                      BASE_STD = "STANDARD DEVIATION*IN PRICE*OF BASE GROUP";
                TITLE5 "CALCULATION OF BASE GROUP STANDARD DEVIATIONS BY &DP_GROUP";
            RUN; 

            DATA &DP_GROUP._RESULTS;
                MERGE DPGROUP (IN = A) BASESTD (IN = B);
                BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
                IF A & B;

                LENGTH &DP_GROUP._RESULT $7;
                &DP_GROUP._RESULT = "No Pass";

                IF BASE_&DP_GROUP._OBS GE 1 THEN 
                DO;
                    IF TEST_&DP_GROUP._STD NE . AND BASE_STD  NE . THEN 
                    DO;
                        STD_POOLED = SQRT((BASE_STD**2 + TEST_&DP_GROUP._STD**2)/2);
                        IF     BASE_&DP_GROUP._OBS GE 2 AND
                            TEST_&DP_GROUP._OBS GE 2 AND 
                            &DP_GROUP._QTY_RATIO GE 0.05 THEN
                        DO;
                            IF STD_POOLED NE 0 THEN 
                            DO;
                                COHEN_D=(BASE_AVG_&DP_GROUP._PRICE - TEST_AVG_&DP_GROUP._PRICE)/STD_POOLED;
                                IF ABS(COHEN_D) GE 0.8 THEN &DP_GROUP._RESULT = "Pass";
                            END;
                            ELSE
                            IF FUZZ(BASE_AVG_&DP_GROUP._PRICE - TEST_AVG_&DP_GROUP._PRICE) ^= 0 THEN
                                &DP_GROUP._RESULT = "Pass";
                        END;
                    END;
                END;
            RUN;

            PROC SORT DATA = &DP_GROUP._RESULTS OUT = &DP_GROUP._RESULTS;
                BY &DP_GROUP &USMANF &USPRIM USLOT &USCONNUM;
            RUN;

            PROC PRINT DATA=&DP_GROUP._RESULTS (OBS=&PRINTOBS) SPLIT="*";
                BY &DP_GROUP &USMANF &USPRIM USLOT ;
                ID &DP_GROUP &USMANF &USPRIM USLOT;
                VAR &USCONNUM TEST_&DP_GROUP._OBS 
                    TEST_AVG_&DP_GROUP._PRICE TEST_&DP_GROUP._STD
                    BASE_&DP_GROUP._OBS BASE_AVG_&DP_GROUP._PRICE BASE_STD 
                    &DP_GROUP._QTY_RATIO STD_POOLED COHEN_D &DP_GROUP._RESULT;
                FORMAT     BASE_AVG_&DP_GROUP._PRICE &COMMA_FORMAT. &DP_GROUP._QTY_RATIO &PERCENT_FORMAT.;
                LABEL     &USCONNUM="CONTROL NUMBER"
                        &DP_GROUP="TEST GROUP*(&DP_GROUP.)"
                        TEST_&DP_GROUP._OBS="TRANSACTIONS*  IN  *TEST GROUP" 
                        TEST_AVG_&DP_GROUP._PRICE="WTD AVG*TEST GROUP*PRICE* ( A ) "
                        TEST_&DP_GROUP._STD="STANDARD DEVIATION*TEST GROUP PRICE* ( C )"
                        BASE_&DP_GROUP._OBS="TRANSACTIONS*  IN  *BASE GROUP" 
                        BASE_AVG_&DP_GROUP._PRICE="WTD AVG *BASE GROUP*PRICE  * ( B )  "
                        BASE_STD="STANDARD DEVIATION*BASE GROUP PRICE* ( D )  " 
                        &DP_GROUP._QTY_RATIO="PERCENT QTY* OF *BASE GROUP"
                        STD_POOLED="POOLED*STANDARD DEVIATION*E =SQ ROOT OF*((CxC + DxD)/2)" 
                        COHEN_D="COHEN'S d*COEFFICIENT*(F = (A-B)/E)"
                        &DP_GROUP._RESULT="RESULT OF*TEST BY*&DP_GROUP";
                TITLE5 "COHEN'S-d CALCULATIONS BY &DP_GROUP FOR COMPARABLE MERCHANDISE";
                TITLE6 "To pass: A) |COHEN'S-d| > 0.8, B) Test & Base obs >= 2, C) Base qty >= 5%";
            RUN;

            /****************************************************************/
            /*  US-13-D-ii-f. Merge results into U.S. sales data. Sales are */
            /*    flagged as either passing or not passing.                 */
            /****************************************************************/

            PROC SORT DATA = DPSALES OUT = DPSALES;
                BY &DP_GROUP &USMANF &USPRIM USLOT &USCONNUM;
            RUN;

            DATA DPSALES DPSALES_PASS_&DP_GROUP;
                MERGE DPSALES (IN=A) &DP_GROUP._RESULTS (IN=B KEEP=&DP_GROUP &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP._RESULT);
                BY &DP_GROUP &USMANF &USPRIM USLOT &USCONNUM;
                IF A AND B THEN
                DO;
                    OUTPUT DPSALES;
                    IF &DP_GROUP._RESULT = "Pass" THEN OUTPUT DPSALES_PASS_&DP_GROUP;
                END;
                IF A AND NOT B THEN 
                DO;
                    &DP_GROUP._RESULT = "No Pass";
                    OUTPUT DPSALES;
                END;            
            RUN;

        %MEND COHENS_D;
 
    /********************************************************************************/
    /* US-13-D-iii. Execute Stage 1: Cohens-d Test for region, time, then purchaser */
    /********************************************************************************/

    %COHENS_D(DP_REGION,FIRST PASS: ANALYSIS BY REGION)
    %COHENS_D(DP_PERIOD,SECOND PASS: ANALYSIS BY TIME PERIOD)
    %COHENS_D(DP_PURCHASER,THIRD AND FINAL PASS: ANALYSIS BY PURCHASER)

    /*************************************************************************/
    /* US-13-E. Stage 2: Calculate Ratios of Sales Passing the Cohens-d Test */
    /*************************************************************************/

        /**********************************************************************/
        /* US-13-E-i. Sales that pass any of the three rounds of the Cohens-d */
        /*   analysis pass the test as a whole.                               */
        /**********************************************************************/

        DATA DPSALES DPPASS (KEEP=DP_COUNT COHENS_D_PASS);
            SET DPSALES;
            FORMAT COHENS_D_PASS $3.;
            COHENS_D_PASS = "No";
            IF    DP_PURCHASER_RESULT  = "Pass" OR   
                DP_REGION_RESULT = "Pass" OR
                DP_PERIOD_RESULT = "Pass" 
            THEN COHENS_D_PASS = "Yes";
        RUN;

        PROC SORT DATA = DPSALES OUT = DPSALES;
            BY &USMANF &USPRIM USLOT &USCONNUM DP_PERIOD DP_REGION DP_PURCHASER;
        RUN;

        DATA DPSALES_PRINT;
            SET DPSALES;
            BY &USMANF &USPRIM USLOT &USCONNUM DP_PERIOD DP_REGION DP_PURCHASER;
            IF FIRST.&USCONNUM OR FIRST.DP_PERIOD OR FIRST.DP_REGION OR FIRST.DP_PURCHASER   
            THEN OUTPUT DPSALES_PRINT;
        RUN;

        PROC SORT DATA = DPSALES_PRINT OUT  = DPSALES_PRINT;
            BY COHENS_D_PASS &USMANF &USPRIM USLOT &USCONNUM;
        RUN;

        DATA DPSALES_PRINT (DROP=COUNT);
            SET DPSALES_PRINT;
            BY COHENS_D_PASS &USMANF &USPRIM USLOT &USCONNUM;
            IF FIRST.COHENS_D_PASS THEN COUNT = 1;
            COUNT + 1;
            IF COUNT LE &PRINTOBS THEN OUTPUT;
        RUN;

        PROC PRINT DATA = DPSALES_PRINT;
            ID COHENS_D_PASS;
            BY COHENS_D_PASS;
            VAR &USMANF &USPRIM USLOT &USCONNUM 
                DP_PERIOD DP_REGION DP_PURCHASER DP_PERIOD_RESULT 
                DP_REGION_RESULT DP_PURCHASER_RESULT;
            TITLE4 "SAMPLE OF &PRINTOBS FOR EACH TYPE OF RESULT FROM THE COHEN'S-D ANALYSIS FOR";
            TITLE5 "UNIQUE COMBINATIONS OF REGION, PURCHASER AND TIME PERIOD FOR EACH CONTROL NUMBER";
        RUN;

        /******************************************************************************/
        /* US-13-E-iii. Calculate the percentage of sales that pass the Cohens-d Test */
        /******************************************************************************/

        PROC MEANS DATA = DPSALES NOPRINT;
            VAR DP_NETPRI;
            WEIGHT &USQTY;
            OUTPUT OUT = OVERALL (DROP = _:) SUM = TOTAL_VALUE;
        RUN;

        PROC MEANS DATA = DPSALES NOPRINT;
          WHERE COHENS_D_PASS = "Yes";
          VAR DP_NETPRI;
          WEIGHT &USQTY;
          OUTPUT OUT = PASS (DROP = _:) SUM = PASS_VALUE;
        RUN;

        DATA OVERALL_DPRESULTS;
            MERGE OVERALL (IN = A) PASS (IN = B);
            IF NOT B THEN
                PASS_VALUE = 0;
            PERCENT_VALUE_PASSING = PASS_VALUE / TOTAL_VALUE;
            %GLOBAL PERCENT_VALUE_PASSING;        
            CALL SYMPUT("PERCENT_VALUE_PASSING", PUT(PERCENT_VALUE_PASSING, &PERCENT_FORMAT.));
            LENGTH CALC_METHOD $11.;
            IF PERCENT_VALUE_PASSING = 0 THEN
                CALC_METHOD = 'STANDARD';
            ELSE
            DO;
                IF PERCENT_VALUE_PASSING EQ 1 THEN
                    CALC_METHOD = 'ALTERNATIVE';
                ELSE
                    CALC_METHOD = 'MIXED';
            END;
            %GLOBAL CALC_METHOD;
            CALL SYMPUT("CALC_METHOD", CALC_METHOD);
        RUN;

        PROC PRINT DATA = OVERALL_DPRESULTS SPLIT = "*" NOOBS;
            VAR PASS_VALUE TOTAL_VALUE PERCENT_VALUE_PASSING;
            FORMAT PASS_VALUE TOTAL_VALUE &COMMA_FORMAT.
                PERCENT_VALUE_PASSING &PERCENT_FORMAT.;
            LABEL PASS_VALUE = "VALUE OF*PASSING SALES*=============" 
                  TOTAL_VALUE = "VALUE OF*ALL SALES*=========" 
                  PERCENT_VALUE_PASSING = "PERCENT OF*SALES PASSING*BY VALUE*=============";
            TITLE4 "OVERALL RESULTS";
            TITLE10 "CASE ANALYST:  Please notify management of results re: the selection of correct method to be used.";
            FOOTNOTE1 "If some sales pass the Cohens-d Test and others do not pass, then three methods will be calculated:";
            FOOTNOTE2 "1) the Standard Method (applied to all sales), 2) the A-to-T Alternative Method (applied to all sales)";
            FOOTNOTE3 "3) and the Mixed Alternative Method which will be a combination of the A-to-A (with offsets)";
            FOOTNOTE4 "applied to sales that did not pass, and A-to-T (without offsets) applied to sales that did pass.";
            FOOTNOTE6 "If either no sale or all sales pass the Cohens-d Test, then the Mixed Alternative Method will yield the same";
            FOOTNOTE7 "results as the Standard Method or the A-to-T Alternative Method, respectively, and will not be calculated.";
            FOOTNOTE9 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
            FOOTNOTE10 "&BDAY, &BWDATE - &BTIME";
        RUN;

    FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
    FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";

    %GLOBAL ABOVE_DEMINIMIS_STND ABOVE_DEMINIMIS_ALT ABOVE_DEMINIMIS_MIXED CASH_DEPOSIT_DONE;
    %LET ABOVE_DEMINIMIS_STND = NO;/* Default value. Do not edit. */
    %LET ABOVE_DEMINIMIS_ALT = NO; /* Default value. Do not edit. */
    %LET ABOVE_DEMINIMIS_MIXED = NO;/* Default value. Do not edit. */
    %LET CASH_DEPOSIT_DONE = NO;  /* Default value.  Do not edit. */

%MEND US13_COHENS_D_TEST;

/********************************************************************/
/* US-14: WEIGHT AVERAGING OF U.S. SALES DATA                       */
/********************************************************************/

%MACRO US14_WT_AVG_DATA;
    /*------------------------------------------------------------*/
    /* 14-A Create macro variables to keep required variables and */
    /* determine the weight averaging pools for U.S. sales.       */
    /*                                                            */
    /* The macro variables AR_VARS and AR_BY_VARS will contain    */
    /* lists of additional variables needed for weight-averaging  */
    /* and assessment purposes in administrative reviews.         */
    /*                                                            */
    /* For administrative reviews, the weight-averaging pools     */
    /* will also be defined by month for cash deposit do          */
    /* calculations. To this, the macro variable AR_BY_VARS will  */
    /* be used in the BY statements that will either be set to a  */
    /* blank value for investigations or the US month variable in */
    /* administrative reviews.                                    */
    /*                                                            */
    /* When the Cohens-d Test determines that the Mixed           */
    /* Alternative Method is to be used, then the DP_COUNT and    */
    /* COHENS_D_PASS macro variables will be to the variables by  */
    /* the same names in order to keep track of which             */
    /* observations passed Cohens-d and which did not. Otherwise, */
    /* the DP_COUNT and COHENS_D_PASS macro variables will be set */
    /* to null values. In addition, the MIXED_BY_VAR macro        */
    /* variable will be set to COHENS_D_PASS in order to allow    */
    /* the weight-averaging to be constricted to within just      */
    /* sales passing the Cohens-d test.                           */
    /*                                                            */
    /* When an assessment calculation is warranted, the section   */
    /* will be re-executed on an importer-specific basis. This    */
    /* is done by adding the US_IMPORTER variables to the BY      */
    /* statements.                                                */
    /*------------------------------------------------------------*/

    %GLOBAL AR_VARS AR_BY_VARS TITLE4_WTAVG TITLE4_MCALC
            DP_COUNT COHENS_D_PASS ;

    %IF %UPCASE(&CASE_TYPE) = INV %THEN
    %DO;
        %LET AR_VARS = ; 
        %LET AR_BY_VARS = ;

        /* For weight averaging */

        %LET TITLE4_WTAVG = CONTROL NUMBER AVERAGING CALCULATIONS FOR CASH DEPOSIT PURPOSES;

        /* For results calculations */

        %LET TITLE4_MCALC = CALCULATIONS FOR CASH DEPOSIT PURPOSES;
    %END;

    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;
        %LET AR_VARS = US_IMPORTER SOURCEU ENTERED_VALUE;
        %IF &CASH_DEPOSIT_DONE = NO %THEN
        %DO;
            %LET AR_BY_VARS = &USMON;
            %LET TITLE4_WTAVG = CONTROL NUMBER AVERAGING CALCULATIONS FOR CASH DEPOSIT PURPOSES; 
            %LET TITLE4_MCALC = CALCULATIONS FOR CASH DEPOSIT PURPOSES; 
        %END;
        %ELSE %IF &CASH_DEPOSIT_DONE = YES %THEN
        %DO;
            %LET AR_BY_VARS = &USMON US_IMPORTER;
            %LET TITLE4_WTAVG = IMPORTER-SPECIFIC AVERAGING CALCULATIONS FOR ASSESSMENT PURPOSES;
            %LET TITLE4_MCALC = IMPORTER-SPECIFIC CALCULATIONS FOR ASSESSMENT PURPOSES;
        %END;
    %END;

    %IF &CALC_METHOD NE STANDARD %THEN
    %DO;
        %LET DP_COUNT = DP_COUNT;
        %LET COHENS_D_PASS = COHENS_D_PASS;

            PROC SORT DATA = USSALES OUT = USSALES;
                BY DP_COUNT;
            RUN;

            PROC SORT DATA = DPPASS OUT = DPPASS;
                BY DP_COUNT;
            RUN;

            DATA USSALES;
                MERGE USSALES (IN=A) DPPASS (IN=B);
                BY DP_COUNT;
                IF A & B;
            RUN;
    %END;
    %ELSE
    %DO;
        %LET DP_COUNT = ;
        %LET COHENS_D_PASS = ;
    %END;

    /*---------------------------------------------------------/
    /* 14-B Keep variables required for rest of calculations. */
    /*--------------------------------------------------------*/

    PROC SORT DATA = USSALES (KEEP = &USMANF &USPRIM USLOT &USMON  
                     &US_TIME_PERIOD SALE_TYPE &USCONNUM &USCHAR
                     NVMATCH &USQTY &EXRATE1 &EXRATE2 USNETPRI USCOMM
                     USCREDIT USDIRSELL USPACK USECEPOFST CEPOFFSET
                     COMOFFSET INDDOL COMMDOL ICOMMDOL &P2P_VARS 
                     &CV_VARS &AR_VARS &DP_COUNT &COHENS_D_PASS)
              OUT = USNETPR;
        BY &USMANF &USPRIM USLOT SALE_TYPE &USCONNUM &US_TIME_PERIOD 
           &AR_BY_VARS &COHENS_D_PASS;
    RUN;

    /*----------------------------------------------------------*/
    /* 14-C Weight-average U.S. prices and adjustments. The     */
    /* averaged variables for the Standard Method with have     */
    /* "_MEAN" added to the end of their original names as a    */
    /* suffix.                                                  */
    /*                                                          */
    /* When the Mixed Alternative Method is employed, an extra  */
    /* weight-averaging will be done that additionally includes */
    /* the COHENS_D_PASS variable in the BY statement. This     */
    /* will allow sales not passing the Cohens-D Test to be     */
    /* eight-averaged separately from those that did pass.      */
    /* Weight-averaged amounts will have "_MIXED" added to the  */
    /* end of their original names.                             */
    /*----------------------------------------------------------*/

    %MACRO WEIGHT_AVERAGE(NAMES, DP_BYVAR);
        PROC MEANS DATA = USNETPR NOPRINT;
            BY &USMANF &USPRIM USLOT SALE_TYPE &USCONNUM
               &US_TIME_PERIOD &AR_BY_VARS &DP_BYVAR;
            VAR USNETPRI USPACK USCOMM USCREDIT USDIRSELL
                CEPOFFSET COMOFFSET;
            WEIGHT &USQTY;
            OUTPUT OUT = USAVG (DROP = _:) MEAN = &NAMES;
        RUN;

        DATA USNETPR;
            MERGE USNETPR USAVG;
            BY &USMANF &USPRIM USLOT SALE_TYPE &USCONNUM
               &US_TIME_PERIOD &AR_BY_VARS &DP_BYVAR;
        RUN;
    %MEND WEIGHT_AVERAGE;

    %LET TITLE5 =;
    %LET TITLE6 =;

    /*-----------------------------------------------------------*/
    /* 14-c-i Execute WEIGHT_AVERAGE macro for Cash Deposit Rate */
    /*-----------------------------------------------------------*/

    %LET TITLE5 = "AVERAGED VARIABLES ENDING IN '_MEAN' TO BE USED WITH THE STANDARD METHOD";
    %LET TITLE6 =;

    %IF &CASH_DEPOSIT_DONE = NO  %THEN
    %DO;
        %WEIGHT_AVERAGE(/AUTONAME, )

        %IF &CALC_METHOD = MIXED %THEN
        %DO;
            %LET TITLE6 = "THOSE ENDING IN '_MIXED' WITH SALES NOT PASSING COHENS'D WITH THE MIXED ALTERNATIVE METHOD.";
            %WEIGHT_AVERAGE(USNETPRI_MIXED USPACK_MIXED USCOMM_MIXED
                            USCREDIT_MIXED USDIRSELL_MIXED
                            CEPOFFSET_MIXED COMOFFSET_MIXED,
                            COHENS_D_PASS)
        %END;
    %END;

    /*------------------------------------------------------*/
    /*  14-c-ii Execute WEIGHT_AVERAGE macro for Assessment */
    /*------------------------------------------------------*/

    %IF &CASH_DEPOSIT_DONE = YES  %THEN
    %DO;
        /*----------------------------------------------------------*/
        /* 14-c-ii-A Weight-average variables for assessments       */
        /*           using the Standard Method only if the Standard-*/
        /*           Method Cash Deposit rate is above de minimis.  */
        /*----------------------------------------------------------*/

        %IF &ABOVE_DEMINIMIS_STND = YES %THEN
        %DO;
            %LET TITLE6 = "THOSE ENDING IN '_MEAN' WITH SALES NOT PASSING COHENS'D WITH THE STANDARD METHOD.";
            %WEIGHT_AVERAGE(/AUTONAME, )
        %END;

        /*----------------------------------------------------------*/
        /* 14-c-ii-B Weight-average variables for assessments using */
        /*           the Mixed Alternative Method, if required.     */
        /*----------------------------------------------------------*/

        %IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
        %DO;
            %LET TITLE6 = "THOSE ENDING IN '_MIXED' WITH SALES NOT PASSING COHENS'D WITH THE MIXED ALTERNATIVE METHOD.";
            %WEIGHT_AVERAGE(USNETPRI_MIXED USPACK_MIXED USCOMM_MIXED
                            USCREDIT_MIXED USDIRSELL_MIXED
                            CEPOFFSET_MIXED COMOFFSET_MIXED,
                            COHENS_D_PASS)
        %END;

        /*-------------------------------------------------------*/
        /*  14-c-ii-C Weight-average variables for assessments   */
        /*            using the Alternative Method, if required. */
        /*-------------------------------------------------------*/
    
        %IF &ABOVE_DEMINIMIS_ALT = YES %THEN
        %DO;
            %LET TITLE6 = "";
        %END;
    %END;
%MEND US14_WT_AVG_DATA;

/**************************************************************************/
/* US-15: FUPDOL, NORMAL VALUE AND COMPARISON RESULTS                     */
/*                                                                        */
/*   For variables with the macro variable SUFFIX added to their names,   */
/*   weight-averaged values will be used when SUFFIX = _MEAN or _MIXED,   */
/*   but single-transaction values will be used when the suffix is a      */
/*   blank space. For example, USNETPRI will be used in calculating the   */
/*   Alternative Method, USNETPRI_MEAN for the Standard Method            */
/*   and USNETPRI_MIXED with the sales not passing Cohens-D for the       */
/*   Mixed Alternative Method.                                            */
/*                                                                        */
/*   For purposes of calculating the initial cash deposit rate, the       */
/*   IMPORTER macro variable will be set to a blank space and not enter   */ 
/*   into the calculations.  When an assessment calculation is warranted, */
/*   the section will be re-executed on an importer-specific basis by     */
/*   setting the IMPORTER macro variable to US_IMPORTER.                  */
/**************************************************************************/

%MACRO US15_RESULTS; 
    %MACRO CALC_RESULTS(METHOD,CALC_TYPE,IMPORTER,OUTDATA,SUFFIX);

    /*--------------------------------------------------------------*/
    /* 15-A. Set up macros for this section.                        */
    /*--------------------------------------------------------------*/

        %IF &METHOD=STANDARD %THEN
        %DO;
            %LET AVG_TITLE = AVERAGE-TO-AVERAGE;
            %LET OFFSET_TITLE = BEFORE OFFSETTING (SHOULD IT BE REQUIRED);
            %MACRO TOTDUMP_LABEL;
                 TOTDUMPING = 'TOTAL AMOUNT*OF DUMPING *(D=B+C IF >0)*=============';
            %MEND TOTDUMP_LABEL;

            %IF &CALC_TYPE = STANDARD %THEN
            %DO;
                %LET TITLE5 = "STANDARD METHOD APPLIED TO ALL SALES USING VALUES ENDING WITH SUFFIX '_MEAN'";
                %MACRO IF_COHEN;
                %MEND IF_COHEN;
            %END;
            %IF &CALC_TYPE = MIXED %THEN
            %DO;
                %LET TITLE5 = "MIXED ALTERNATIVE METHOD PART 1: A-to-A APPLIED TO SALES NOT PASSING COHENS-D USING VALUES ENDING WITH SUFFIX '_MIXED'";
                %MACRO IF_COHEN;
                    IF COHENS_D_PASS = "No";
                %MEND IF_COHEN;
            %END;
        %END;

        %IF &METHOD=ALTERNATIVE    %THEN
        %DO;
            %LET AVG_TITLE = AVERAGE-TO-TRANSACTION;
            %LET OFFSET_TITLE = ;
            %MACRO TOTDUMP_LABEL;
                 TOTDUMPING = 'TOTAL AMOUNT*OF DUMPING *( D=B )*=============';
            %MEND TOTDUMP_LABEL;
            %IF &CALC_TYPE = ALTERNATIVE %THEN
            %DO;
                %LET TITLE5 = "ALTERNATIVE METHOD APPLIED TO ALL U.S. SALES";
                %MACRO IF_COHEN;
                %MEND IF_COHEN;
            %END;
            %IF &CALC_TYPE = MIXED %THEN
            %DO;
                %LET TITLE5 = "MIXED ALTERNATIVE METHOD PART 2: A-to-T APPLIED TO SALES PASSING COHENS-D TEST";
                %MACRO IF_COHEN;
                        IF COHENS_D_PASS = "Yes";
                %MEND IF_COHEN;
            %END;
        %END;

    /*--------------------------------------------------------------*/
    /* 15-B. Calculate Results                                      */
    /*--------------------------------------------------------------*/

        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA NONVMARG_&OUTDATA; 
            SET USNETPR;
                %IF_COHEN
                %MACRO FUPDOL;
                    %IF &CALC_P2P = YES %THEN
                    %DO;
                        %IF &CALC_CV = YES %THEN
                        %DO;
                            IF NVMATCH = 3 THEN
                                %FUPDOL_CV
                            ELSE
                                %FUPDOL_P2P
                        %END;
                        %IF &CALC_CV = NO %THEN
                        %DO;
                            %FUPDOL_P2P
                        %END;
                    %END;
                    %ELSE %IF &CALC_P2P = NO %THEN
                    %DO;
                        %IF &CALC_CV = YES %THEN
                        %DO;
                            %FUPDOL_CV
                        %END;
                    %END;
                %MEND FUPDOL;
                %FUPDOL
                IF SALE_TYPE = 'EP' THEN
                     NV = FUPDOL - COMOFFSET&SUFFIX + USCOMM&SUFFIX + USDIRSELL&SUFFIX + USCREDIT&SUFFIX;
                ELSE
                     NV = FUPDOL - COMOFFSET&SUFFIX + USCOMM&SUFFIX + USDIRSELL&SUFFIX - CEPOFFSET&SUFFIX;

                UMARGIN = NV - USNETPRI&SUFFIX;
                EMARGIN = UMARGIN * &USQTY;
                USVALUE = USNETPRI&SUFFIX * &USQTY;
                PCTMARG = UMARGIN / USNETPRI&SUFFIX * 100;

                IF UMARGIN = . OR NV = . OR USNETPRI&SUFFIX = . THEN
                     OUTPUT NONVMARG_&OUTDATA; 
                ELSE
                     OUTPUT COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA;
        RUN;
 
        PROC PRINT DATA = NONVMARG_&OUTDATA (OBS=&PRINTOBS);
            TITLE3 "SAMPLE OF U.S. SALES TRANSACTIONS WITH MISSING COMPARISON RESULTS";
            TITLE4 "&TITLE4_MCALC";
            TITLE5 &TITLE5;
        RUN;

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA
                  OUT = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA;
            BY DESCENDING PCTMARG;
        RUN;

        PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA (OBS = &PRINTOBS) SPLIT = "*";
            TITLE3 "SAMPLE OF &AVG_TITLE COMPARISON RESULT CALCULATIONS &OFFSET_TITLE";
            LABEL UMARGIN = "PER-UNIT*COMPARISON*RESULTS*(UMARGIN)"
                  EMARGIN = "TRANSACTION*COMPARISON*RESULTS*(EMARGIN)"
                  PCTMARG = "COMPARISON*RESULT AS*PCT OF VALUE*(PCTMARG)";
            TITLE4 "&TITLE4_MCALC (SORTED BY DESCENDING PCTMARG)";
            TITLE5 &TITLE5;
        RUN;

    /*------------------------------------------------------------*/
    /* 15-C. Keep variables needed for remaining calculations and */
    /*    put them in the database SUMMARG_<OUTDATA>.    The      */
    /*    SUMMARG_<OUTDATA> dataset does not contain any          */
    /*    offsetting information.    <OUTDATA> will be as follows */
    /*                                                            */
    /*    AVGMARG:  Cash Deposit, Standard Method                 */
    /*    AVGMIXED: Cash Deposit, sales not passing Cohens-d for  */
    /*              Mixed Alternative Method                      */
    /*    TRNMIXED: Cash Deposit, sales passing Cohens-d for      */    
    /*              Mixed Alternative Method                      */
    /*    TRANMARG: Cash Deposit, A-to-T Alternative Method       */
    /*                                                            */
    /*    IMPSTND:  Assessment, Standard Method                   */
    /*    IMPCSTN:  Assessment, sales not passing Cohens-d for    */
    /*              Mixed Alternative Method                      */    
    /*    IMPCTRN:  Assessment, sales passing Cohens-d for Mixed  */    
    /*              Alternative Method                            */
    /*    IMPTRAN:  Assessment, A-to-T Alternative Method         */
    /*------------------------------------------------------------*/

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA 
                  OUT = SUMMARG_&OUTDATA (KEEP = &IMPORTER &USQTY USNETPRI&SUFFIX
                        USVALUE PCTMARG EMARGIN UMARGIN &USMANF SALE_TYPE NVMATCH 
                        USECEPOFST CEPOFFSET COMOFFSET &AR_VARS &COHENS_D_PASS);
            BY &IMPORTER SALE_TYPE NVMATCH DESCENDING PCTMARG;
        RUN;

    %MEND CALC_RESULTS;

    /*----------------------------------------------------------*/
    /* 15-D. Execute the CALC_RESULTS macro for the appropriate */
    /*   scenario(s).                                           */
    /*----------------------------------------------------------*/

        /*---------------------------------------------------------------*/
        /* 15-D-i. Cash deposit calculations.                            */
        /*                                                               */
        /*   In all cases, the CALC_RESULTS macro will be executed using */
        /*   the Standard Method and the A-to-T Alternative              */
        /*   Method for the Cash Deposit Rate.  If there is a            */
        /*   mixture of sales pass and not passing Cohens-D, then the    */
        /*   CALC_RESULTS macro will be executed a third time using the  */
        /*   Mixed Alternative Method.                                   */ 
        /*                                                               */
        /*   The ABOVE_DEMINIMIS_STND, ABOVE_DEMINIMIS_MIXED and         */
        /*   ABOVE_DEMINIMIS_ALT macro variables were set to "NO" by     */
        /*   default above in US13.  They remains "NO" through the       */
        /*   calculation of the Cash Deposit rate(s). If a particular    */
        /*   Cash Deposit rate is above de minimis, its attendant macro  */
        /*   variable gets changed to "YES" to allow for its assessment  */
        /*   calculation in reviews in Sect 15-E-ii below.               */
        /*                                                               */
        /*   If the Mixed Alternative Method is not being                */
        /*   calculated because all sales either did or did not pass the */
        /*   Cohens-D Test, then ABOVE_DEMINIMIS_MIXED is set to "NA"    */
        /*---------------------------------------------------------------*/

        %IF &CASH_DEPOSIT_DONE = NO %THEN
        %DO;
            %LET ASSESS_TITLE = ;
            %CALC_RESULTS(STANDARD,STANDARD, ,AVGMARG,_MEAN)
            %CALC_RESULTS(ALTERNATIVE,ALTERNATIVE, ,TRANMARG, )
            %IF &CALC_METHOD = MIXED %THEN
            %DO;
                %CALC_RESULTS(STANDARD,MIXED, ,AVGMIXED,_MIXED)
                %CALC_RESULTS(ALTERNATIVE,MIXED, ,TRNMIXED, )
            %END;
        %END;

        /*---------------------------------------------------------*/
        /* 15-D-ii. Assessment Calculations (Reviews Only).        */
        /*                                                         */
        /*   For each Method for which its Cash Deposit rate is    */
        /*   above de minimis, calculate information for importer- */
        /*   specific assessment rates.                            */
        /*---------------------------------------------------------*/

        %IF %UPCASE(&CASE_TYPE)= AR %THEN
        %DO;

            %IF &CASH_DEPOSIT_DONE = YES %THEN
            %DO;
                %LET ASSESS_TITLE = "IMPORTER-SPECIFIC CALCULATIONS FOR ASSESSMENT PURPOSES";
                %IF &ABOVE_DEMINIMIS_STND = YES %THEN
                %DO;
                    %CALC_RESULTS(STANDARD,STANDARD,US_IMPORTER,IMPSTND,_MEAN)
                %END;
                %IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
                %DO;
                    %CALC_RESULTS(STANDARD,MIXED,US_IMPORTER,IMPCSTN,_MIXED)
                    %CALC_RESULTS(ALTERNATIVE,MIXED,US_IMPORTER,IMPCTRN, )
                %END;
                %IF &ABOVE_DEMINIMIS_ALT = YES %THEN
                %DO;
                    %CALC_RESULTS(ALTERNATIVE,ALTERNATIVE,US_IMPORTER,IMPTRAN, )
                %END;
            %END;

        %END;
%MEND US15_RESULTS; 

/***************************************************************************/
/* US-16: CALCULATE CASH DEPOSIT RATE                                      */
/***************************************************************************/

%MACRO US16_CALC_CASH_DEPOSIT;
    /*-----------------------------------------------------------------*/
    /* 16-A. The Standard Method will employed on all U.S. sales       */
    /* regardless of the results of the Cohens-D Test.  Also, the      */
    /* A-to-T Alternative Method will also be used on all sales to     */
    /* calculate a second Cash Deposit rate.                           */
    /*                                                                 */
    /* When there are both sales that pass and do not pass Cohens-D, a */
    /* Mixed Alternative Cash Deposit rate (in addition to the rates   */
    /* based on the Standard and A-to-T Alternative Methods) will be   */
    /* calculated using a mixture of A-to-A (with offsets) and A-to-T  */
    /* (without offsets). To calculate the Mixed rate, the A-to-A      */
    /* Method will be employed on sales not passing the Cohens-d       */
    /* Test, the A-to-T Method on the rest and then then two results   */
    /* will be aggregated.                                             */
    /*-----------------------------------------------------------------*/

    %MACRO CALC_CASH_DEPOSIT(TEMPDATA, SUFFIX, METHOD);
        PROC MEANS DATA = SUMMARG_&TEMPDATA NOPRINT;
            VAR USNETPRI&SUFFIX;
            WEIGHT &USQTY;
            OUTPUT OUT = ALLVAL_&TEMPDATA (DROP = _:)
                   N = TOTSALES SUM = TOTVAL SUMWGT = TOTQTY;
        RUN;

        /*------------------------------------------------------------*/
        /* 16-B. CALCULATE THE MINIMUM AND MAXIMUM COMPARISON RESULTS */
        /*------------------------------------------------------------*/

        PROC MEANS DATA = SUMMARG_&TEMPDATA NOPRINT;
            VAR PCTMARG;
            OUTPUT OUT = MINMAX_&TEMPDATA (DROP = _:)
                   MIN = MINMARG MAX = MAXMARG;
        RUN;

        /*-------------------------------------------------------*/
        /* 16-C. CALCULATE THE TOTAL QUANTITY AND VALUE OF SALES */
        /*    WITH POSITIVE COMPARISON RESULTS AND AMOUNT OF     */
        /*    POSITIVE DUMPING                                   */
        /*-------------------------------------------------------*/

        PROC MEANS DATA = SUMMARG_&TEMPDATA NOPRINT;
            WHERE EMARGIN GT 0;
            VAR &USQTY USVALUE EMARGIN;
            OUTPUT OUT = SUMMAR_&TEMPDATA (DROP = _:)
                   SUM = MARGQTY MARGVAL POSDUMPING;   
        RUN;

        /*-----------------------------------------------------------------*/
        /* 16-D. CALCULATE THE TOTAL AMOUNT OF NEGATIVE COMPARISON RESULTS */
        /*-----------------------------------------------------------------*/

        PROC MEANS DATA = SUMMARG_&TEMPDATA NOPRINT;
            WHERE EMARGIN LT 0;
            VAR EMARGIN;
            OUTPUT OUT = NEGMARG_&TEMPDATA (DROP = _:)
                   SUM = NEGDUMPING;
        RUN;

        /*------------------------------------------------*/
        /* 16-E. CALCULATE THE OVERALL MARGIN PERCENTAGES */
        /*------------------------------------------------*/

        DATA ANSWER_&TEMPDATA;
            LENGTH CALC_TYPE $11.;
            MERGE ALLVAL_&TEMPDATA SUMMAR_&TEMPDATA 
                  MINMAX_&TEMPDATA NEGMARG_&TEMPDATA;

            %IF &TEMPDATA = TRNMIXED %THEN 
            %DO;
                CALC_TYPE = "A-to-T";
            %END;
            %ELSE
            %IF &TEMPDATA = AVGMIXED %THEN
            %DO;
                CALC_TYPE = "A-to-A";
            %END;
            %ELSE 
            %DO;
                CALC_TYPE = "&METHOD";
            %END;

            IF MARGQTY = . THEN
                MARGQTY = 0;
            IF MARGVAL = . THEN
                MARGVAL = 0;
            PCTMARQ = (MARGQTY / TOTQTY) * 100;
            PCTMARV = (MARGVAL / TOTVAL) * 100;

            IF POSDUMPING = . THEN
                POSDUMPING = 0;
            IF NEGDUMPING = . THEN
                NEGDUMPING = 0;

            /*-----------------------------------------------------------*/
            /* 16-E-1.  If the sum of the positive comparison            */
            /* results is greater than the absolute value of the sum of  */
            /* the negative comparison results, then offset the positive */
            /* results with the negative to calculate total dumping.     */
            /* If not, then set total dumping to zero.                   */
            /*-----------------------------------------------------------*/

            %IF &METHOD = ALTERNATIVE %THEN
            %DO;
                TOTDUMPING = POSDUMPING;
            %END;
            %ELSE
            %DO;
                IF POSDUMPING GT ABS(NEGDUMPING) THEN
                    TOTDUMPING = POSDUMPING + NEGDUMPING;
                ELSE 
                    TOTDUMPING = 0;
            %END;
        RUN;
    %MEND CALC_CASH_DEPOSIT;

    /*-------------------------------------------------------------*/
    /* 16-F. EXECUTE THE CALC_CASH_DEPOSIT MACRO FOR ALL SCENARIOS */
    /*-------------------------------------------------------------*/

    %CALC_CASH_DEPOSIT(AVGMARG, _MEAN, STANDARD)
    %CALC_CASH_DEPOSIT(TRANMARG, , ALTERNATIVE)
    %IF  &CALC_METHOD = MIXED %THEN
    %DO;
        %CALC_CASH_DEPOSIT(AVGMIXED, _MIXED, STANDARD)
        %CALC_CASH_DEPOSIT(TRNMIXED, , ALTERNATIVE)
    %END;

    %MACRO MIXED;
        %IF &CALC_METHOD = MIXED %THEN
        %DO;
            DATA MIXED;
                SET ANSWER_AVGMIXED ANSWER_TRNMIXED;
            RUN;

            DATA ANSWER_MIXEDSPLIT;
                SET ANSWER_AVGMIXED ANSWER_TRNMIXED;
                PCTMARQ  = (MARGQTY / TOTQTY) * 100;
                PCTMARV  = (MARGVAL / TOTVAL) * 100;
            RUN;

            PROC MEANS DATA = MIXED NOPRINT;
                VAR TOTSALES TOTQTY TOTVAL MARGQTY MARGVAL
                    POSDUMPING NEGDUMPING TOTDUMPING;
                OUTPUT OUT = MIXED_SUM (DROP = _:) 
                       SUM = TOTSALES TOTQTY TOTVAL MARGQTY MARGVAL
                             POSDUMPING NEGDUMPING TOTDUMPING;
            RUN;

            PROC MEANS DATA = MIXED NOPRINT;
                VAR MINMARG;
                OUTPUT OUT = MINMARG (DROP = _:) MIN = MINMARG;
            RUN;

            PROC MEANS DATA = MIXED NOPRINT;
                VAR MAXMARG;
                OUTPUT OUT = MAXMARG (DROP = _:) MAX = MAXMARG;
            RUN;

            DATA MIXED_SUM ANSWER_MIXEDMARG (DROP = CALC_TYPE);
                LENGTH CALC_TYPE $11.;
                MERGE MIXED_SUM MINMARG MAXMARG;
                CALC_TYPE = "MIXED";
                PCTMARQ  = (MARGQTY / TOTQTY) * 100;
                PCTMARV  = (MARGVAL / TOTVAL) * 100;
            RUN;

            DATA MIXED_ALL;
                SET MIXED MIXED_SUM;
            RUN;

            PROC PRINT DATA = MIXED_ALL;
                TITLE3 "WHEN SOME SALES PASS THE COHENS-D AND OTHERS NOT, CALCULATE THE MIXED ALTERNATIVE METHOD";
                TITLE4 "COMBINE RESULTS FROM SALES NOT PASSING THE COHENS-D TEST CALCULATED A-to-A WITH OFFSETS";
                TITLE5 "WITH RESULTS FROM SALES PASSING THE COHENS-D TEST CALCULATED A-to-T WITHOUT OFFSETS";
            RUN; 
        %END;
    %MEND MIXED;

    %MIXED

    /*-------------------------------------------------------*/
    /* 16-G. CREATE MACRO VARIABLES TO TRACK WHEN MARGIN     */
    /* PERCENTAGES ARE ABOVE DE MINIMIS. IF ANY CASH DEPOSIT */
    /* RATE IN AN ADMINISTRATIVE REVIEW IS ABOVE DE MINIMIS, */
    /* THE ASSESSMENT MACRO WILL RUN.                        */
    /*-------------------------------------------------------*/

    %MACRO DE_MINIMIS(OUTDATA,TYPE,CALC);
        DATA ANSWER_&OUTDATA;
            SET ANSWER_&OUTDATA;

            WTAVGPCT_&TYPE = (TOTDUMPING / TOTVAL) * 100;
            PER_UNIT_RATE_&TYPE = TOTDUMPING / TOTQTY;

            IF WTAVGPCT_&TYPE GT &DE_MINIMIS THEN
               ABOVE_DEMIN_&TYPE = 'YES';
            ELSE
               ABOVE_DEMIN_&TYPE = 'NO';

            %IF &TYPE = STND %THEN
            %DO;
                CALL SYMPUT('ABOVE_DEMINIMIS_STND',ABOVE_DEMIN_&TYPE);
            %END;
            %IF &TYPE = ALT %THEN
            %DO;
                CALL SYMPUT('ABOVE_DEMINIMIS_ALT',ABOVE_DEMIN_ALT);
            %END;
            %IF &TYPE = MIXED %THEN
            %DO;
                CALL SYMPUT('ABOVE_DEMINIMIS_MIXED',ABOVE_DEMIN_&TYPE);
            %END;
        RUN;
    %MEND DE_MINIMIS;

    %DE_MINIMIS(AVGMARG, STND, YES)
    %DE_MINIMIS(TRANMARG, ALT, YES)

    %IF &CALC_METHOD = MIXED %THEN
    %DO;
        %DE_MINIMIS(MIXEDMARG, MIXED, YES)
    %END;
    %ELSE 
    %DO;
        %LET ABOVE_DEMINIMIS_MIXED = NA;
    %END;

    /*------------------------------------------------------------- */
    /* 16-H. PRINT CASH DEPOSIT RATE CALCULATIONS FOR ALL SCENARIOS */
    /*--------------------------------------------------------------*/

    %MACRO PRINT_CASH_DEPOSIT(OUTDATA, METHOD);
        %GLOBAL SUMVARS METHODOLOGY TITLE FOOTNOTE1 FOOTNOTE2;

        %IF &METHOD = STANDARD %THEN
        %DO;
            %LET SUMVARS = ;
            %LET METHODOLOGY = STANDARD;
            %LET TITLE = "AVERAGE-TO-AVERAGE COMPARISONS, OFFSETTING POSITIVE COMPARISON RESULTS WITH NEGATIVE COMPARISON RESULTS";
            %LET FOOTNOTE1 = "IF C IS GREATER THAN THE ABSOLUTE VALUE OF D, THEN THE ANTIDUMPING DUTIES DUE";
            %LET FOOTNOTE2 = "ARE THE SUM OF C AND D, OTHERWISE THE ANTIDUMPING DUTIES DUE ARE ZERO.";
            %MACRO TOTDUMP_LABEL;
                 TOTDUMPING = 'TOTAL AMOUNT*OF DUMPING *(E=C+D IF >0)*=============';
            %MEND TOTDUMP_LABEL;
        %END;
        %IF &METHOD = ALTERNATIVE %THEN
        %DO;
            %LET SUMVARS = ;
            %LET METHODOLOGY = A-to-T ALTERNATIVE;
            %LET TITLE = "AVERAGE-TO-TRANSACTION COMPARISONS, NO OFFSETTING OF POSITIVE COMPARISON RESULTS";
            %LET FOOTNOTE1 = "THE ANTIDUMPING DUTIES DUE ARE THE SUM OF THE POSITIVE RESULTS (C)";
            %LET FOOTNOTE2 = ;
            %MACRO TOTDUMP_LABEL;
                 TOTDUMPING = 'TOTAL AMOUNT*OF DUMPING *( E=C )*=============';
            %MEND TOTDUMP_LABEL;
        %END;
        %IF &METHOD = MIXED %THEN
        %DO;
            %LET SUMVARS = SUM TOTSALES TOTVAL TOTQTY POSDUMPING NEGDUMPING TOTDUMPING MARGVAL MARGQTY;
            %LET METHODOLOGY = MIXED ALTERNATIVE;
            %LET TITLE = "OFFSETTING POSITIVE COMPARISON RESULTS WITH NEGATIVES ONLY FOR SALES NOT PASSING COHENS-D";
            %LET FOOTNOTE1 = "FOR SALES THAT FAIL THE COHEN'S-D TEST, AD DUTIES DUE ARE THE SUM OF C AND D (IF C>|D|) OR ZERO.";
            %LET FOOTNOTE2 = "FOR SALES THAT PASS COHEN'S-D TEST, AD DUTIES DUE ARE THE SUM OF C.";
            %MACRO TOTDUMP_LABEL;
                TOTDUMPING = 'TOTAL AMOUNT  *OF DUMPING   *(SEE FOOTNOTES) *===============';
            %MEND TOTDUMP_LABEL;
        %END;

        PROC PRINT DATA = ANSWER_&OUTDATA NOOBS SPLIT='*';
            VAR CALC_TYPE TOTSALES TOTVAL TOTQTY POSDUMPING NEGDUMPING TOTDUMPING MINMARG MAXMARG MARGVAL MARGQTY
                PCTMARV PCTMARQ;
            &SUMVARS;
            TITLE3 "BUILD UP TO WEIGHT AVERAGE MARGIN";
            TITLE4 "USING THE &METHODOLOGY METHOD";
            TITLE5 &TITLE;
            FOOTNOTE1 &FOOTNOTE1;
            FOOTNOTE2 &FOOTNOTE2;
            FOOTNOTE4 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
            FOOTNOTE5 "&BDAY, &BWDATE - &BTIME";
            LABEL CALC_TYPE = 'COMPARISON*TYPE* *=========='
                  TOTSALES = ' *NUMBER OF*U.S. SALES* *=========='
                  TOTVAL   = 'TOTAL U.S.*SALES VALUE*(A)*================' 
                  TOTQTY   = 'TOTAL U.S. *QUANTITY  *(B)     *=============='
                  POSDUMPING = 'TOTAL POSITIVE*COMPARISON RESULTS*(C)*=================='
                  NEGDUMPING = 'TOTAL NEGATIVE*COMPARISON RESULTS*(D)*=================='
                  MARGVAL  = 'VALUE OF SALES*WITH POSITIVE*COMPARISON RESULTS*(F)*=================='         
                  MARGQTY  = 'QUANTITY OF SALES*WITH POSITIVE*COMPARISON RESULTS*(G) *================='
                  PCTMARV  = 'PERCENT OF SALES*WITH POSITIVE*COMPARISON RESULTS*BY VALUE*(F/A x 100)*=================='
                  PCTMARQ  = 'PERCENT OF SALES*WITH POSITIVE*COMPARISON RESULTS*BY QUANTITY*(G/B x 100)*=================='
                  MINMARG  = 'MINIMUM *COMPARISON*RESULT  *(percent)*=========='
                  MAXMARG  = 'MAXIMUM *COMPARISON*RESULT  *(percent)*==========' 
                  %TOTDUMP_LABEL;
            FORMAT TOTSALES COMMA9. TOTVAL TOTQTY POSDUMPING NEGDUMPING TOTDUMPING MARGVAL MARGQTY MINMARG MAXMARG COMMA16.2 
            PCTMARV PCTMARQ 6.2;
        RUN;
    %MEND PRINT_CASH_DEPOSIT;

    /*----------------------------------------------------------*/
    /* 16-I. EXECUTE PRINT_CASH_DEPOSIT MACRO FOR ALL SCENARIOS */
    /*----------------------------------------------------------*/

    %PRINT_CASH_DEPOSIT(AVGMARG, STANDARD)

    %IF &ABOVE_DEMINIMIS_MIXED NE NA %THEN
    %DO;
        %PRINT_CASH_DEPOSIT(MIXEDSPLIT,MIXED)
    %END;

    %PRINT_CASH_DEPOSIT(TRANMARG, ALTERNATIVE)
    
    /*--------------------------------------------------*/
    /* 16-J. PRINT CASH DEPOSIT RATES FOR ALL SCENARIOS */
    /*--------------------------------------------------*/

    %IF &CALC_METHOD = STANDARD %THEN
    %DO;
        %LET FOOTNOTE1 = "Because all sales did not pass Cohens-D Test, the Mixed Alternative Cash Deposit Rate is the same as the Cash";
        %LET FOOTNOTE2 = "Deposit Rate for the Standard Method.  Accordingly, the Mixed Alternative Method will not be used";
        %LET FOOTNOTE3 = "separately in the Meaningful Difference Test nor in the calculation of assessments in Administrative Reviews.";
        %LET ANSWER_MIXEDMARG = ; /* macro variable for mixed database nulled out */
    %END;

    %IF &CALC_METHOD = MIXED %THEN
    %DO;
        %LET FOOTNOTE1 = " ";
        %LET FOOTNOTE2 = " ";
        %LET FOOTNOTE3 = " ";
        %LET ANSWER_MIXEDMARG = ANSWER_MIXEDMARG (KEEP=WTAVGPCT_MIXED PER_UNIT_RATE_MIXED);
    %END;

    %IF &CALC_METHOD = ALTERNATIVE %THEN
    %DO;
        %LET FOOTNOTE1 = "Because all sales passed the Cohens-D Test, the Mixed Alternative Cash Deposit Rate is the same as the Cash Deposit";
        %LET FOOTNOTE2 = "Rate for the A-to-T Alternative Method.  Accordingly, the Mixed Alternative Method will not be separately";
        %LET FOOTNOTE3 = "used in the Meaningful Difference Test nor in the calculation of assessments in Administrative Reviews.";
        %LET ANSWER_MIXEDMARG = ;
    %END;

    PROC FORMAT;
        VALUE PCT_MARGIN 
            . = "N/A"
            OTHER = [COMMA9.2];
        VALUE UNIT_MARGIN
            . = "N/A"
            OTHER = [DOLLAR10.2];
    RUN;

    DATA ANSWER;
        MERGE ANSWER_AVGMARG (KEEP = WTAVGPCT_STND PER_UNIT_RATE_STND)
              &ANSWER_MIXEDMARG  
              ANSWER_TRANMARG (KEEP = WTAVGPCT_ALT PER_UNIT_RATE_ALT);
        %IF &CALC_METHOD NE MIXED %THEN
        %DO;
            WTAVGPCT_MIXED = .;
            PER_UNIT_RATE_MIXED = .;
        %END;
    RUN;

    PROC PRINT DATA = ANSWER NOOBS SPLIT = '*';
        %IF %UPCASE(&PER_UNIT_RATE) = NO %THEN
        %DO;
            VAR WTAVGPCT_STND WTAVGPCT_MIXED WTAVGPCT_ALT;
            LABEL WTAVGPCT_STND = "STANDARD METHOD*AD VALOREM*WEIGHT AVERAGE MARGIN*(E/A x 100)*(percent)* *================="
                  WTAVGPCT_MIXED = "MIXED ALTERNATIVE*METHOD*AD VALOREM*WEIGHT AVERAGE MARGIN*(percent)* *================="
                  WTAVGPCT_ALT = "A-to-T ALTERNATIVE*METHOD*AD VALOREM*WEIGHT AVERAGE MARGIN*(E/A x 100)*(percent)* *==================";
            FORMAT WTAVGPCT_STND WTAVGPCT_MIXED WTAVGPCT_ALT PCT_MARGIN.;
        %END;
        %IF %UPCASE(&PER_UNIT_RATE) = YES %THEN
        %DO;
            VAR PER_UNIT_RATE_STND PER_UNIT_RATE_MIXED PER_UNIT_RATE_ALT;
            LABEL PER_UNIT_RATE_STND = "STANDARD METHOD*PER-UNIT*WEIGHT AVERAGE MARGIN*( E/B )* *================="    
                  PER_UNIT_RATE_MIXED = "MIXED ALTERNATIVE*METHOD*PER-UNIT*WEIGHT AVERAGE MARGIN*(percent)* *=================" 
                  PER_UNIT_RATE_ALT = "A-to-T ALTERNATIVE*METHOD*PER-UNIT*WEIGHT AVERAGE MARGIN*(E/A x 100)*(percent)* *==================";
            FORMAT PER_UNIT_RATE_STND PER_UNIT_RATE_MIXED PER_UNIT_RATE_ALT UNIT_MARGIN.;
        %END;

        TITLE3 "WEIGHT AVERAGE MARGINS";
        FOOTNOTE1 &FOOTNOTE1;
        FOOTNOTE2 &FOOTNOTE2;
        FOOTNOTE3 &FOOTNOTE3;
        FOOTNOTE6 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
        FOOTNOTE7 "&BDAY, &BWDATE - &BTIME";
    RUN;

    FOOTNOTE6 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
    FOOTNOTE7 "&BDAY, &BWDATE - &BTIME";

    %LET CASH_DEPOSIT_DONE = YES;
%MEND US16_CALC_CASH_DEPOSIT;


/*************************************/
/* US-17: MEANINGFUL DIFFERENCE TEST */
/*************************************/

%MACRO US17_MEANINGFUL_DIFF_TEST;
    %GLOBAL MA_METHOD AT_METHOD;
    %LET MA_METHOD = N/A;
    %LET AT_METHOD = N/A;

    %IF &CALC_METHOD NE STANDARD %THEN
    %DO;
        %IF &CALC_METHOD EQ MIXED %THEN
        %DO;
            %LET ADD_SET = MIXEDMARG;

            DATA MIXEDMARG;
                SET  ANSWER_MIXEDMARG (KEEP = WTAVGPCT_MIXED);
                    LENGTH METHOD $18.;
                    METHOD = "MIXED ALTERNATIVE";
                    RENAME WTAVGPCT_MIXED = WTAVGPCT;
            RUN;
        %END;
        %ELSE
        %DO;
            %LET ADD_SET = ;
        %END;

        DATA TRANMARG;
            SET  ANSWER_TRANMARG (KEEP = WTAVGPCT_ALT);
                LENGTH METHOD $18.;
                METHOD = "A-to-T ALTERNATIVE";
                RENAME WTAVGPCT_ALT = WTAVGPCT;
        RUN;

        DATA MEANINGFUL_DIFF_TEST;
            LENGTH RESULT $ 36 MEANINGFUL_DIFF $ 3;
            SET &ADD_SET TRANMARG;
            IF _N_ = 1 THEN
                SET ANSWER_AVGMARG (KEEP = WTAVGPCT_STND);

            /* default values for WTAVGPCT_STND and WTAVGPCT_ALT less than de minimis */

            MEANINGFUL_DIFF = "NO";
            RELATIVE_CHANGE = .;
            RESULT = "NEITHER MARGIN IS ABOVE DE MINIMIS";

            IF WTAVGPCT GE &DE_MINIMIS THEN
            DO;
                IF WTAVGPCT_STND LT &DE_MINIMIS THEN
                DO;
                    RESULT = "MOVES ACROSS DE MINIMIS THRESHOLD";
                    MEANINGFUL_DIFF = "YES";
                END;
                ELSE
                DO;
                    RELATIVE_CHANGE = (WTAVGPCT - WTAVGPCT_STND)/WTAVGPCT_STND * 100 ;
                    IF RELATIVE_CHANGE GE 25 THEN 
                    DO;
                        MEANINGFUL_DIFF = "YES";
                        RESULT = "RELATIVE MARGIN CHANGE >= 25%";
                    END;
                    ELSE 
                    DO;
                        MEANINGFUL_DIFF = "NO";
                        RESULT = "RELATIVE MARGIN CHANGE < 25%";
                    END;
                END;
            END;

            IF METHOD = "MIXED ALTERNATIVE" THEN
                CALL SYMPUT('MA_METHOD', MEANINGFUL_DIFF);
            ELSE
            IF METHOD = "A-to-T ALTERNATIVE" THEN
                CALL SYMPUT('AT_METHOD', MEANINGFUL_DIFF);
        RUN;

        PROC FORMAT;
            VALUE RELCHNG
                . = "N/A"
                OTHER = [COMMA8.2];
        RUN;

        PROC PRINT DATA = MEANINGFUL_DIFF_TEST NOOBS SPLIT = "*";
            VAR METHOD WTAVGPCT WTAVGPCT_STND RELATIVE_CHANGE RESULT MEANINGFUL_DIFF;
            LABEL WTAVGPCT_STND = "MARGIN RATE*STANDARD METHOD*A-to-A with OFFSETS*( B )"
            WTAVGPCT = "MARGIN RATE*( A )"
            RELATIVE_CHANGE = "RELATIVE PCT*MARGIN CHANGE*(A-B)/Bx100"
            RESULT = "RESULT OF TEST"
            MEANINGFUL_DIFF = "MEANINGFUL DIFFERENCE*IN THE MARGINS?";
            FORMAT WTAVGPCT WTAVGPCT_STND RELATIVE_CHANGE RELCHNG.;
            TITLE3 "RESULTS OF THE MEANINGFUL DIFFERENCE TEST";
            TITLE5 "CASE ANALYST:  Please notify management of results so that the proper method can be selected.";
            TITLE7 "PERCENT OF SALES PASSING THE COHEN'S D TEST = %CMPRES(&PERCENT_VALUE_PASSING)";        
            FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
            FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";
        RUN;
    %END;
%MEND US17_MEANINGFUL_DIFF_TEST;

/******************************************************************/
/* US-18: IMPORTER-SPECIFIC DUTY ASSESSMENT RATES (REVIEWS ONLY)  */
/*                                                                */
/*        Calculate and print importer-specific assessment rates  */
/*        if the cash deposit rate in an administrative review is */
/*        above de minimis.                                       */
/******************************************************************/

%MACRO US18_ASSESSMENT;
    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;
        /*-------------------------------------------------------*/
        /* 18-A For all methods for which no assessments will be */
        /*      calculated, print an explanation.                */
        /*-------------------------------------------------------*/

        %MACRO NO_ASSESS(TYPE);
            %IF &ABOVE_DEMINIMIS_STND = NO OR
                &ABOVE_DEMINIMIS_MIXED = NO OR
                &ABOVE_DEMINIMIS_ALT = NO %THEN
            %DO;
                %IF &&ABOVE_DEMINIMIS_&TYPE = NO %THEN
                %DO;
                    /*-----------------------------------*/
                    /* 18-A-i All cash deposit rates are */
                    /*        below de minimis.          */
                    /*-----------------------------------*/

                    %IF &TYPE = ALT %THEN
                    %DO;
                        DATA NOCALC;
                            SET ANSWER (KEEP = WTAVGPCT_ALT);
                            REASON = "HIGHEST POSSIBLE CASH DEPOSIT RATE IS BELOW 0.5 PERCENT (de minimis)";
                        RUN;

                        PROC PRINT DATA = NOCALC NOOBS SPLIT = "*";
                            VAR REASON WTAVGPCT_ALT;
                            LABEL WTAVGPCT_ALT = "A-to-T ALTERNATIVE*METHOD*AD VALOREM*CASH DEPOSIT RATE*(percent)* *================"
                                  REASON = " ";
                            TITLE3 "NO ASSESSMENTS WILL BE CALCULATED FOR ANY METHOD SINCE THE HIGHEST POSSIBLE";
                            TITLE4 "CASH DEPOSIT RATE (FOR THE A-to-T ALTERNATIVE METHOD) IS LESS THAN DE MINIMIS";
                            FORMAT WTAVGPCT_&TYPE PCT_MARGIN.; 
                        RUN;

                        PROC SORT DATA = SUMMARG_AVGMARG
                                  OUT = IMPORTER_LIST (KEEP = US_IMPORTER) NODUPKEY;
                            BY US_IMPORTER;
                        RUN;

                        PROC PRINT DATA = IMPORTER_LIST SPLIT = '*';
                            LABEL US_IMPORTER = "&IMPORTER";
                            TITLE3 "LIST OF REPORTED IMPORTERS OR CUSTOMERS";
                        RUN;
                    %END;

                    /*---------------------------------------*/
                    /* 18-A-ii Standard Cash Deposit rate is */
                    /*         below de minimis.             */
                    /*---------------------------------------*/

                    %IF &TYPE = STND AND &&ABOVE_DEMINIMIS_ALT NE NO %THEN
                    %DO;
                        DATA NOCALC;
                            SET ANSWER (KEEP = WTAVGPCT_STND);
                            REASON = "CASH DEPOSIT RATE IS BELOW 0.5 PERCENT (de minimis)";
                        RUN;

                        PROC PRINT DATA = NOCALC NOOBS SPLIT = "*";
                            VAR REASON WTAVGPCT_STND;
                            LABEL WTAVGPCT_STND = "STANDARD METHOD*AD VALOREM*CASH DEPOSIT RATE*(percent)* *================"
                                  REASON = " ";
                            TITLE3 "NO ASSESSMENTS WILL BE CALCULATED FOR THE STANDARD METHOD";
                            FORMAT WTAVGPCT_&TYPE PCT_MARGIN.; 
                        RUN;

                        PROC SORT DATA = SUMMARG_AVGMARG
                                  OUT = IMPORTER_LIST (KEEP = US_IMPORTER) NODUPKEY;
                            BY US_IMPORTER;
                        RUN;

                        PROC PRINT DATA = IMPORTER_LIST SPLIT = '*';
                            LABEL US_IMPORTER = "&IMPORTER";
                            TITLE3 "LIST OF REPORTED IMPORTERS OR CUSTOMERS";
                        RUN;
                    %END;

                    /*----------------------------------------------*/
                    /* 18-A-iii The Cash Deposit rate for the Mixed */
                    /*          Alternative Method is below de      */
                    /*          minimis.                            */
                    /*----------------------------------------------*/

                    %IF &TYPE = MIXED AND &CALC_METHOD NE STANDARD %THEN
                    %DO;
                        %IF &&ABOVE_DEMINIMIS_ALT NE NO %THEN
                        %DO; 
                            DATA NOCALC;
                                SET ANSWER (KEEP = WTAVGPCT_&TYPE);
                                REASON = "CASH DEPOSIT RATE IS BELOW 0.5 PERCENT (de minimis)";
                            RUN;

                            PROC PRINT DATA = NOCALC NOOBS SPLIT = "*";
                                VAR REASON WTAVGPCT_&TYPE;
                                LABEL WTAVGPCT_&TYPE = "MIXED ALTERNATIVE*METHOD*AD VALOREM*CASH DEPOSIT RATE*(percent)* *================"
                                REASON = " ";
                                TITLE3 "NO ASSESSMENTS WILL BE CALCULATED FOR THE MIXED ALTERNATIVE METHOD";
                                FORMAT WTAVGPCT_&TYPE PCT_MARGIN.; 
                            RUN;

                            PROC SORT DATA = SUMMARG_AVGMARG
                                      OUT = IMPORTER_LIST (KEEP = US_IMPORTER) NODUPKEY;
                                BY US_IMPORTER;
                            RUN;

                            PROC PRINT DATA = IMPORTER_LIST SPLIT = '*';
                                LABEL US_IMPORTER = "&IMPORTER";
                                TITLE3 "LIST OF REPORTED IMPORTERS OR CUSTOMERS";
                            RUN;
                        %END;
                    %END;
                %END;
            %END;

            /*------------------------------------------------------*/
            /* 18-A-iv All sales either pass Cohens-D or do not     */
            /*         pass. The Mixed Alternative Method would be  */
            /*         the same as the A-to-T Alternative Method    */
            /*         when all sales pass, or the Standard Method  */
            /*         when all sales do not pass. Therefore,       */
            /*         no need to calculate Mixed Alternative       */
            /*         assessment rates.                            */
            /*------------------------------------------------------*/

            %IF &&ABOVE_DEMINIMIS_&TYPE = NA AND 
                &&ABOVE_DEMINIMIS_ALT NE NO %THEN
            %DO;
                DATA NOCALC;
                    REASON = "All sales either do not pass/pass the Cohens-D, Mixed Alternative Method the same as Standard/A-to-T Alternative, respectively.";
                RUN;

                %IF &ABOVE_DEMINIMIS_STND = NO %THEN
                %DO;
                    PROC PRINT DATA = NOCALC NOOBS SPLIT = "*";
                        VAR REASON;
                        LABEL REASON = " ";
                        TITLE3 "NO SEPARATE ASSESMENT CALCULATIONS WILL BE DONE USING THE MIXED ALTERNATIVE METHOD";
                        TITLE4 "(ASSESSMENTS WILL BE CALCULATED USING THE A-to-T ALTERNATIVE METHOD ONLY)";
                    RUN;
                %END;
                %ELSE
                %IF &ABOVE_DEMINIMIS_STND = YES %THEN
                %DO;
                    PROC PRINT DATA = NOCALC NOOBS SPLIT = "*";
                        VAR REASON;
                        LABEL REASON = " ";
                        TITLE3 "NO SEPARATE ASSESMENT CALCULATIONS WILL BE DONE USING THE MIXED ALTERNATIVE METHOD";
                        TITLE4 "(ASSESSMENTS WILL BE CALCULATED USING THE STANDARD AND A-to-T ALTERNATIVE METHODS)";
                    RUN;
                %END;

                PROC SORT DATA = SUMMARG_AVGMARG
                          OUT = IMPORTER_LIST (KEEP = US_IMPORTER) NODUPKEY;
                    BY US_IMPORTER;
                RUN;

                PROC PRINT DATA = IMPORTER_LIST SPLIT = '*';
                    LABEL US_IMPORTER = "&IMPORTER";
                        TITLE3 "LIST OF REPORTED IMPORTERS OR CUSTOMERS";
                RUN;
            %END;
        %MEND NO_ASSESS;

    %NO_ASSESS(STND)
    %NO_ASSESS(MIXED)
    %NO_ASSESS(ALT)

    /*-----------------------------------------------------------*/
    /* 18-B FOR ALL METHODS FOR WHICH THE CASH DEPOSIT RATES ARE */
    /*      ABOVE DE MINIMIS, CALCULATE ASSESSMENTS.             */
    /*-----------------------------------------------------------*/
                
    %IF &ABOVE_DEMINIMIS_STND = YES OR
        &ABOVE_DEMINIMIS_MIXED = YES OR
        &ABOVE_DEMINIMIS_ALT = YES %THEN
    %DO;
        %US14_WT_AVG_DATA;  /* Re-weight average data by importer. */
        %US15_RESULTS;      /* Recalculate transaction comparison  */
                            /* results using re-weighted data.     */
    
        /*----------------------------------------------------------*/
        /* 18-B-i The SUMMARG_<INDATA> dataset does not contain any */
        /*        offsetting info. Calculate amounts for offsetting */
        /*        by importer and store them in the database        */
        /*        SUMMAR_<INDATA>, leaving the database             */
        /*        SUMMARG_<INDATA> unchanged.                       */
        /*----------------------------------------------------------*/

        %MACRO CALC_ASSESS(INDATA, CTYPE, CALC_TYPE);
            PROC MEANS NWAY DATA = SUMMARG_&INDATA NOPRINT;
                CLASS US_IMPORTER SOURCEU;
                VAR ENTERED_VALUE;
                WEIGHT &USQTY;
                OUTPUT OUT = ENTVAL_&INDATA (DROP = _:)
                       N = SALES SUMWGT = ITOTQTY SUM = ITENTVAL;
            RUN;

            /*------------------------------------------------------*/
            /* 18-B-ii Calculate the sum of positive comparison     */
            /*         results.                                     */
            /*------------------------------------------------------*/

            PROC MEANS NWAY DATA = SUMMARG_&INDATA NOPRINT;
                CLASS US_IMPORTER SOURCEU;
                WHERE EMARGIN GT 0;
                VAR EMARGIN;
                OUTPUT OUT = POSMARG_IMPORTER_&INDATA (DROP = _:)
                       SUM = IPOSRESULTS;
            RUN;

            /*---------------------------------------------------*/
            /* 18-B-iii Calculate the sum of negative comparison */
            /*          results.                                 */
            /*---------------------------------------------------*/

            PROC MEANS NWAY DATA = SUMMARG_&INDATA NOPRINT;
                CLASS US_IMPORTER SOURCEU;
                WHERE EMARGIN LT 0;
                VAR EMARGIN;
                OUTPUT OUT = NEGMARG_IMPORTER_&INDATA (DROP = _:)
                       SUM = INEGRESULTS;
            RUN;

            /*------------------------------------------------------*/
            /* 18-B-iv For each importer, if the sum of the         */
            /*         positive comparison results is greater than  */
            /*         the absolute value of the sum of the         */
            /*         negative comparison results, set the total   */
            /*         comparison results to the to the sum of the  */
            /*         positive and negative comparison             */
            /*         results. Otherwise, set the total comparison */
            /*         results to zero. Calculate the ad valorem    */
            /*         and per-unit assessment rates, and the       */
            /* de minimis percent.                                  */
            /*------------------------------------------------------*/

            DATA ASSESS_&INDATA;
                LENGTH CALC_TYPE $11;
                MERGE ENTVAL_&INDATA (IN = A)
                      POSMARG_IMPORTER_&INDATA (IN = B) 
                      NEGMARG_IMPORTER_&INDATA (IN = C);
                BY US_IMPORTER SOURCEU;
                CALC_TYPE = "&CALC_TYPE";
                IF A;
                IF NOT B THEN
                    IPOSRESULTS = 0;
                IF NOT C THEN
                    INEGRESULTS = 0;

                %IF &CTYPE = STND %THEN
                %DO;
                    IF IPOSRESULTS > ABS(INEGRESULTS) THEN
                        ITOTRESULTS = IPOSRESULTS + INEGRESULTS;
                    ELSE
                        ITOTRESULTS = 0;
                %END;
                %ELSE
                %IF &CTYPE = ALT %THEN
                %DO;
                    ITOTRESULTS = IPOSRESULTS;
                %END;
            RUN;
        %MEND CALC_ASSESS;

        /*----------------------------------------------------*/
        /* 18-C EXECUTE THE CALC_ACCESS MACRO FOR ALL METHODS */
        /*----------------------------------------------------*/

        /*------------------------*/
        /* 18-C-i STANDARD METHOD */
        /*------------------------*/

        %IF &ABOVE_DEMINIMIS_STND = YES %THEN
        %DO;
            %CALC_ASSESS(IMPSTND, STND, STANDARD)
        %END;

        /*----------------------------------*/
        /* 18-C-ii MIXED ALTERNATIVE METHOD */
        /*----------------------------------*/

        %IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
        %DO;
            %CALC_ASSESS(IMPCSTN, STND, A-to-A)
            %CALC_ASSESS(IMPCTRN, ALT, A-to-T)

            /*------------------------------------------------------*/
            /* 18-C-i-a COMBINE RESULTS FROM THE PORTION OF SALES   */
            /*          CALCULATED A-to-A WITH OFFSETS, WITH THOSE  */
            /*          FROM SALES CALCULATED A-to-T WITHOUT        */
            /*          OFFSETS.                                    */
            /*------------------------------------------------------*/

            DATA ASSESS_MIXED_ALL;
               SET ASSESS_IMPCSTN ASSESS_IMPCTRN;
            RUN;

            PROC MEANS NWAY DATA = ASSESS_MIXED_ALL NOPRINT;
                CLASS US_IMPORTER SOURCEU;
                VAR SALES ITOTQTY ITENTVAL IPOSRESULTS INEGRESULTS 
                    ITOTRESULTS;
                OUTPUT OUT = ASSESS_MIXED_SUM (DROP = _:) 
                       SUM = SALES ITOTQTY ITENTVAL IPOSRESULTS
                             INEGRESULTS ITOTRESULTS;
            RUN;

            DATA ASSESS_MIXED_SUM ASSESS_MIXED (DROP = CALC_TYPE);
                LENGTH CALC_TYPE $11.;
                SET ASSESS_MIXED_SUM;
                CALC_TYPE = "MIXED";
            RUN;

            DATA ASSESS_MIXED_ALL;
                SET ASSESS_MIXED_ALL ASSESS_MIXED_SUM;
            RUN;

            PROC SORT DATA = ASSESS_MIXED_ALL OUT = ASSESS_MIXED_ALL;
                BY US_IMPORTER SOURCEU CALC_TYPE;
            RUN;

            PROC PRINT DATA = ASSESS_MIXED_ALL (OBS = &PRINTOBS);
                BY US_IMPORTER SOURCEU;
                ID US_IMPORTER SOURCEU;
                TITLE3 "FOR THE MIXED ALTERNATIVE METHOD, COMBINE";
                TITLE4 "RESULTS FROM SALES NOT PASSING COHENS-D CALCULATED A-to-A WITH OFFSETS";
                TITLE5 "WITH RESULTS FROM SALES PASSING COHENS-D CALCULATED A-to-T WITHOUT OFFSETS";
            RUN; 
        %END;

        /*-----------------------------*/
        /* 18-C-iii ALTERNATIVE METHOD */
        /*-----------------------------*/

        %IF &ABOVE_DEMINIMIS_ALT = YES %THEN
        %DO;
            %CALC_ASSESS(IMPTRAN, ALT, ALTERNATIVE)
        %END;
    %END;

    %MACRO PRINT_ASSESS(INDATA);
        DATA ASSESS_&INDATA;
            SET ASSESS_&INDATA;

            /* AD VALOREM RATE FOR ASSESSMENT */

            ASESRATE = (ITOTRESULTS / ITENTVAL)* 100;

            /* PER-UNIT RATE FOR ASSESSMENT */

            PERUNIT  = (ITOTRESULTS / ITOTQTY); 

            /* RATE FOR DE MINIMIS TEST. */

            DMINPCT  = ASESRATE;
            LENGTH DMINTEST $3. ;

            IF DMINPCT GE 0.5 THEN
            DO;
                DMINTEST = 'NO';

                %IF %UPCASE(&PER_UNIT_RATE) = NO %THEN
                %DO;
                    IF SOURCEU = 'REPORTED' THEN 
                        PERUNIT = .;
                    ELSE 
                    IF SOURCEU IN ('MIXED','COMPUTED') THEN 
                %END;

                ASESRATE = .;
            END;
            ELSE 
            IF DMINPCT LT 0.5 THEN
            DO;
                DMINTEST = 'YES';
                ASESRATE = 0;
                PERUNIT  = 0;
            END;

            DMINPCT  = INT(DMINPCT * 100) / 100;
        RUN;

        PROC PRINT DATA = ASSESS_&INDATA SPLIT = '*' WIDTH = MINIMUM;
            VAR US_IMPORTER SOURCEU ITENTVAL ITOTQTY IPOSRESULTS 
                INEGRESULTS ITOTRESULTS DMINPCT DMINTEST ASESRATE
                PERUNIT;
            LABEL US_IMPORTER  = 'IMPORTER**========'
                  SOURCEU      = 'CUSTOMS VALUE*DATA SOURCE**============='
                  ITENTVAL     = 'CUSTOMS VALUE*(A)*============='
                  ITOTQTY      = 'TOTAL QUANTITY*(B)*============'
                  IPOSRESULTS  = 'TOTAL OF*POSITIVE*COMPARISON*RESULTS*(C)*=========='
                  INEGRESULTS  = 'TOTAL OF*NEGATIVE*COMPARISON*RESULTS*(D)*=========='
                  ITOTRESULTS  = 'ANTIDUMPING*DUTIES DUE*(see footnotes)*(E)*=============='
                  DMINPCT      = 'RATE FOR*DE MINIMIS TEST*(percent)*(E/A)x100*=============='
                  DMINTEST     = 'IS THE RATE*AT OR BELOW*DE MINIMIS?**===========' 
                  ASESRATE     = '*AD VALOREM*ASSESSMENT*RATE*(percent)*(E/A)x100*=========='
                  PERUNIT      = 'PER-UNIT*ASSESSMENT*RATE*($/unit)*(E/B) *==========' ;
                  FORMAT ITENTVAL ITOTQTY COMMA16.2
                         DMINPCT ASESRATE PERUNIT COMMA8.2;
            TITLE3 "IMPORTER-SPECIFIC DE MINIMIS TEST RESULTS AND ASSESSMENT RATES";
            TITLE4 &ASSESS_TITLE4;
            TITLE5 "FOR DISPLAY PURPOSES, THE DE MINIMIS PERCENT IS NOT ROUNDED";
            FOOTNOTE1 &ASSESS_FOOTNOTE1;
            FOOTNOTE2 &ASSESS_FOOTNOTE2;
            FOOTNOTE4 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
            FOOTNOTE5 "&BDAY, &BWDATE - &BTIME";
        RUN;
    %MEND PRINT_ASSESS;

    %IF &ABOVE_DEMINIMIS_STND = YES %THEN
    %DO;
        %LET ASSESS_FOOTNOTE1 = "IF C IS GREATER THAN THE ABSOLUTE VALUE OF D, THEN THE ANTIDUMPING DUTIES DUE ";
        %LET ASSESS_FOOTNOTE2 = "ARE THE SUM OF C AND D, OTHERWISE THE ANTIDUMPING DUTIES DUE ARE ZERO.";
        %LET ASSESS_TITLE4 = "STANDARD METHOD, OFFSETTING POSITIVE COMPARISON RESULTS WITH NEGATIVES";
        %PRINT_ASSESS(IMPSTND)
    %END;

    %IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
    %DO;
        %LET ASSESS_FOOTNOTE1 = "FOR SALES THAT FAIL THE COHEN'S-D TEST, AD DUTIES DUE ARE THE SUM OF C AND D (IF C>|D|) OR ZERO.";
        %LET ASSESS_FOOTNOTE2 = "FOR SALES THAT PASS COHEN'S-D TEST, AD DUTIES DUE ARE THE SUM OF C.";
        %LET ASSESS_TITLE4 = "MIXED ALTERNATIVE METHOD: FOR SALES FAILING COHEN'S-D ONLY, OFFSET POSITIVE COMPARISON RESULTS WITH NEGATIVES";
        %PRINT_ASSESS(MIXED)
    %END;

    %IF &ABOVE_DEMINIMIS_ALT = YES %THEN
    %DO;
        %LET ASSESS_FOOTNOTE1 = "THE ANTIDUMPING DUTIES DUE ARE THE SUM OF THE POSITIVE RESULTS (C)";
        %LET ASSESS_FOOTNOTE2 = ;
        %LET ASSESS_TITLE4 = "A-to-T ALTERNATIVE METHOD: TOTAL DUMPING IS EQUAL TO TOTAL POSITIVE COMPARISON RESULTS";
        %PRINT_ASSESS(IMPTRAN)
    %END;
%END;
%MEND US18_ASSESSMENT;

/******************************************/
/* US-19: REPRINT FINAL CASH DEPOSIT RATE */
/******************************************/

%MACRO US19_FINAL_CASH_DEPOSIT;
    %IF %UPCASE(&PER_UNIT_RATE) = NO %THEN
    %DO; 
        %LET PREFIX = WTAVGPCT;
        %LET LABEL_STND = "AD VALOREM*WEIGHTED AVERAGE*MARGIN RATE*(PERCENT)*STANDARD METHOD*================";
        %LET LABEL_MIXED = "AD VALOREM*WEIGHTED AVERAGE*MARGIN RATE*(PERCENT)*MIXED ALTERNATIVE*METHOD*=================";
        %LET LABEL_ALT = "AD VALOREM*WEIGHTED AVERAGE*MARGIN RATE*(PERCENT)*A-to-T ALTERNATIVE*METHOD*==================";
        %LET CDFORMAT = PCT_MARGIN.;
    %END;
    %ELSE
    %IF %UPCASE(&PER_UNIT_RATE) = YES %THEN
    %DO;
        %LET PREFIX = PER_UNIT_RATE;
        %LET LABEL_STND = "PER-UNIT*WEIGHTED AVERAGE*MARGIN RATE*STANDARD METHOD*===============";
        %LET LABEL_MIXED = "PER-UNIT*WEIGHTED AVERAGE*MARGIN RATE*MIXED ALTERNATIVE*METHOD*=================";
        %LET LABEL_ALT = "PER-UNIT*WEIGHTED AVERAGE*RATE*A-to-T ALTERNATIVE*METHOD*==================";
        %LET CDFORMAT = UNIT_MARGIN.;
    %END;

    PROC PRINT DATA = ANSWER NOOBS SPLIT = '*';
        TITLE3 "SUMMARY OF CASH DEPOSIT RATES";
        TITLE5 "PERCENT OF SALES PASSING THE COHEN'S D TEST: %CMPRES(&PERCENT_VALUE_PASSING)";   
        TITLE6 "IS THERE A MEANINGFUL DIFFERENCE BETWEEN THE STANDARD METHOD AND THE MIXED-ALTERNATIVE METHOD: %CMPRES(&MA_METHOD)";
        TITLE7 "IS THERE A MEANINGFUL DIFFERENCE BETWEEN THE STANDARD METHOD AND THE A-to-T ALTERNATIVE METHOD: %CMPRES(&AT_METHOD)";
        TITLE8 " ";
        VAR &PREFIX._STND &PREFIX._MIXED &PREFIX._ALT;
        LABEL &PREFIX._STND = &LABEL_STND
              &PREFIX._MIXED = &LABEL_MIXED
              &PREFIX._ALT = &LABEL_ALT;
        FORMAT &PREFIX._STND  &PREFIX._MIXED &PREFIX._ALT &CDFORMAT;
        FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
        FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";
    RUN;
%MEND US19_FINAL_CASH_DEPOSIT;