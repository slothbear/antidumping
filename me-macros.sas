/********************************************************************/
/*                     ANTIDUMPING MARKET-ECONOMY                   */
/*                           MACROS PROGRAM                         */
/*                                                                  */
/*                 LAST PROGRAM UPDATE JULY 10, 2018                */
/*                                                                  */
/********************************************************************/
/*                              GENERAL MACROS                      */
/*------------------------------------------------------------------*/
/*     G1_RUNTIME_SETUP                                             */
/*                                                                  */
/*     G2_TITLE_SETUP                                               */
/*     G3_COST_TIME_MVARS                                           */
/*     G4_LOT                                                       */
/*     G5_DATE_CONVERT                                              */
/*     G6_CHECK_SALES                                               */
/*     G7_EXRATES                                                   */
/*     G8_FIND_NOPRODUCTION                                         */
/*     G9_COST_PRODCHARS                                            */
/*     G10_TIME_PROD_LIST                                           */
/*     G11_INSERT_INDICES_IN                                        */
/*     G12_INSERT_INDICES_OUT                                       */
/*     G13_CALC_INDICES                                             */
/*     G14_INDEX_CALC                                               */
/*     G15_CHOOSE_COSTS                                             */
/*     G16_MATCH_NOPRODUCTION                                       */
/*     G17_FINALIZE_COSTDATA                                        */
/*     G18_DEL_ALL_WORK_FILES                                       */
/*     G19_PROGRAM_RUNTIME                                          */
/*------------------------------------------------------------------*/
/*                     HOME MARKET MACROS                           */
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
/*                       MARGIN PROGRAM MACROS                      */
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

    TITLE1 "&PROGRAM PROGRAM - &PRODUCT FROM &COUNTRY";
    TITLE2 "&SEGMENT &STAGE FOR RESPONDENT &RESPONDENT (&CASE_NUMBER)";

    FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
    FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";
%MEND G2_TITLE_SETUP;

/*********************************************/
/* G3: CREATE MACROS FOR TIME-SPECIFIC COSTS */
/*********************************************/

%MACRO G3_COST_TIME_MVARS;
    %GLOBAL HM_TIME_PERIOD NAF_TIME_PERIOD COST_TIME_PERIOD US_TIME_PERIOD
            US_TIME AND_TIME EQUAL_TIME OR_TIME FIRST_TIME COP_TIME_OUT
            COST_PERIODS TIME_ANNUAL ANNUAL_COST;

    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %LET AND_TIME = AND;
        %LET EQUAL_TIME = =;
        %LET OR_TIME = OR;
        %LET FIRST_TIME = FIRST.&US_TIME_PERIOD;
        %LET US_TIME = US_TIME_PERIOD;   /* For Level of Trade calculation */
                                         /* in HM program. */

        %LET COST_PERIODS = COST PERIODS;

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

**************************************************************************************;
** G-6: CHECK SALES FOR NEGATIVE PRICES AND QUANTITIES, DATES OUTSIDE PERIOD        **;
**************************************************************************************;

%MACRO G6_CHECK_SALES;
    %GLOBAL MONTH;
    %LET MONTH = ;    /* Null value for macro variables &HMMONTH or &USMONTH for investigations. */

    %MACRO CHECK_SALES(SALES_MONTH, QTY,GUP, DATE, SALES, DBTYPE, DB);

    DATA &SALES NEGDATA_&DB OUTDATES_&DB;
        SET &SALES;
        IF &QTY LE 0 OR &GUP LE 0 THEN OUTPUT NEGDATA_&DB;
        ELSE IF "&BEGINDAY."D GT &DATE OR &DATE GT "&ENDDAY."D THEN OUTPUT OUTDATES_&DB;
        %MARGIN_FILTER
        ELSE DO;

            /*--------------------------------------------------------------------*/
            /* In administrative reviews, define HMMONTH and USMONTH variables so */
            /* that each month has a unique value.                                */
            /*--------------------------------------------------------------------*/

            %IF %UPCASE(&CASE_TYPE) = AR %THEN
            %DO;
                %IF &DBTYPE = US %THEN
                %DO;
                    %LET BEGIN = &BEGINWINDOW;
                %END;
                %ELSE
                %DO;
                    %LET BEGIN = &BEGINDAY;
                %END;
                MON    = MONTH(&DATE);
                YRDIFF = YEAR(&DATE) - YEAR("&BEGIN."D);
                &SALES_MONTH = MON + YRDIFF*12;
                DROP MON YRDIFF;
                %LET MONTH = &SALES_MONTH;
            %END;

            OUTPUT &SALES;
        END;
    RUN;

        PROC PRINT DATA = NEGDATA_&DB (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF &DBTYPE SALES WITH NEGATIVE VALUES FOR GROSS PRICE OR QUANTITY";
            TITLE5 "NOTE:  Default programming removes these sales from the calculations.";
            TITLE6 "Should this not be appropriate, adjust accordingly.";
        RUN;

        PROC PRINT DATA = OUTDATES_&DB (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF &DBTYPE SALES OUTSIDE THE PERIOD OF ANALYSIS";
        RUN;

    %MEND CHECK_SALES;

    %IF %UPCASE(&SALESDB) = HMSALES %THEN
    %DO;
        %MACRO MARGIN_FILTER;
        %MEND MARGIN_FILTER;

        %CHECK_SALES(HMMONTH, &HMQTY, &HMGUP, &HMSALEDATE, HMSALES, HOME MARKET, HM);
    %END;    
    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN
    %DO;
        %MACRO MARGIN_FILTER;
        %MEND MARGIN_FILTER;

        %CHECK_SALES(HMMONTH, &HMQTY, &HMGUP, &HMSALEDATE, DOWNSTREAM, DOWNSTREAM, DS);
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

        %CHECK_SALES(USMONTH, &USQTY, &USGUP, &USSALEDATE, USSALES, US, US);
    %END;

%MEND G6_CHECK_SALES;

**************************************************************************************;
** G-7: MERGE EXCHANGE RATES INTO SALES DATABASE                                    **;
**************************************************************************************;

%MACRO G7_EXRATES;
    %GLOBAL EXRATE1 XRATE1 EXRATE2 XRATE2;

    %MACRO MERGE_RATES(USE_EXRATES, EXDATA, EXRATE, XRATE,DATE); 
        **------------------------------------------------------------------------------**;
        **     Set values for exchange rate macro variables when exchange rate is             **;
        **    not required.                                                                    **;
        **------------------------------------------------------------------------------**;

        %IF %UPCASE(&USE_EXRATES) = NO %THEN
        %DO;

            %LET &EXRATE = ; 
            %LET &XRATE = 1; 

        %END;

        **------------------------------------------------------------------------------**;
        **     Merge Exchange Rates, when required.                                        **;
        **------------------------------------------------------------------------------**;

        %IF %UPCASE(&USE_EXRATES) = YES %THEN
        %DO;

            %LET &EXRATE = EXRATE_&EXDATA;
            %LET &XRATE = EXRATE_&EXDATA;

        **--------------------------------------------------------------------------**;
        **     First establish whether date variable is in proper format before         **;
        **    attempting to merge exchange rates.                                     **;
        **--------------------------------------------------------------------------**;
    
            %IF &DATE_FORMAT = YES %THEN
            %DO;

            **----------------------------------------------------------------------**;
            **     If date variable is in proper format, merge in format before           **;
            **    attempting to merge exchange rates.                                 **;
            **----------------------------------------------------------------------**;

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
        %MERGE_RATES(&USE_EXRATES1,&EXDATA1,EXRATE1,XRATE1,&HMSALEDATE);
        %MERGE_RATES(&USE_EXRATES2,&EXDATA2,EXRATE2,XRATE2,&HMSALEDATE);
    %END;

    %IF %UPCASE(&SALESDB) = USSALES %THEN
    %DO;
        %MERGE_RATES(&USE_EXRATES1,&EXDATA1,EXRATE1,XRATE1,&USSALEDATE);
        %MERGE_RATES(&USE_EXRATES2,&EXDATA2,EXRATE2,XRATE2,&USSALEDATE);
    %END;

    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN
    %DO;
        %MERGE_RATES(&USE_EXRATES1,&EXDATA1,EXRATE1,XRATE1,&HMSALEDATE);
        %MERGE_RATES(&USE_EXRATES2,&EXDATA2,EXRATE2,XRATE2,&HMSALEDATE);
    %END;

%MEND G7_EXRATES;

/**************************************************************/
/* G-8 IDENTIFY PRODUCTS REQUIRING SURROGATE COSTS            */
/*                                                            */
/*     CONNUMUs in the HM and U.S. datasets that have sales   */
/*     but no production in the POI/POR must be in the COP    */
/*     dataset with a production quantity of 0 (zero). If     */
/*     respondent does not report these CONNUMs in the cost   */
/*     dataset, the analyst must add these CONNUMs to the COP */
/*     dataset with a production quantity of 0 (zero).        */
/**************************************************************/

%MACRO G8_FIND_NOPRODUCTION;
    %GLOBAL TIME_ANNUALIZED;
    %LET TIME_ANNUALIZED = NA;

    PROC SORT DATA = COST OUT = COST;
        BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
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
            WHERE &COST_TIME_PERIOD IN(&TIME_INSIDE_POR &TIME_ANNUAL);
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

    PROC MEANS NOPRINT DATA = COST;
        BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;     
        %WHERE_STMT 
        VAR &COST_QTY;
        OUTPUT OUT = TOTPRODQTY (DROP=_FREQ_ _TYPE_) 
               SUM = TOT_CONNUM_PROD_QTY;
    RUN;

    DATA COST (DROP = TOT_CONNUM_PROD_QTY 
               RENAME = (NOPROD_TIME_TYPE = COST_TIME_TYPE)) 
         NOPRODUCTION (KEEP = &COST_MATCH &PROD_CHARS NOPROD_TIME_TYPE
                              &COST_TIME_PERIOD 
                       RENAME = (&COST_MATCH = NO_PRODUCTION_CONNUM
                                 %RENAME_TIME_TYPE));                 
         MERGE COST (IN = A) TOTPRODQTY (IN = B);
         BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
         IF A;

         %NOPROD_TIME_TYPE
         IF TOT_CONNUM_PROD_QTY LE 0 THEN
             OUTPUT NOPRODUCTION;
         ELSE
             OUTPUT COST;
    RUN;

    PROC CONTENTS NOPRINT DATA = NOPRODUCTION 
                          OUT = NOPROD (KEEP = NOBS);
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
%MEND G8_FIND_NOPRODUCTION;

**************************************************************************************;
**    G-9 ATTACH PRODUCT CHARACTERISTIC TO COST DATA, WHEN REQUIRED                     **;
**************************************************************************************;

%MACRO G9_COST_PRODCHARS;
    %IF %UPCASE(&FIND_SURROGATES) = YES AND %UPCASE(&COST_PROD_CHARS) = NO %THEN 
    %DO;
        %MACRO GETCHARS;

            %IF %UPCASE(&SALESDB) = HMSALES %THEN
            %DO;

                PROC SORT DATA = USSALES NODUPKEY OUT = USCONNUMLIST (KEEP=&USCVPROD &USCHAR);
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
                                 RENAME %SYSFUNC(COMPRESS(%SCAN(&USCHAR,&I,%STR( )))) 
                                 = %SYSFUNC(COMPRESS(%SCAN(&HMCHAR,&I,%STR( )))) %NRSTR(;); 
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
                BY &COST_MATCH &COST_TIME_PERIOD;
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

**************************************************************************************;
** G-10. FILL IN MISSING LINES IN COST DATA, WHEN REQUIRED                            **;
**************************************************************************************;

%MACRO G10_TIME_PROD_LIST(SALES_CHAR);

    **------------------------------------------------------------------------------**;
    **  Make a list of all time periods in the sales data.                            **;
    **------------------------------------------------------------------------------**;
    
    %MACRO MAKE_TIMELIST; 
    %GLOBAL LIST_TIMES;
            %IF %UPCASE(&TIME_OUTSIDE_POR) = NA %THEN
            %DO;
                %LET LIST_TIMES = &TIME_INSIDE_POR;
            %END;
            %ELSE %IF %UPCASE(&TIME_OUTSIDE_POR) NE NA %THEN
            %DO;
                %LET LIST_TIMES = &TIME_INSIDE_POR. , &TIME_OUTSIDE_POR;
            %END;
    %MEND MAKE_TIMELIST;
    %MAKE_TIMELIST;

    **------------------------------------------------------------------------------**;
    **  Create a database of all time periods.                                        **;
    **------------------------------------------------------------------------------**;
    
    PROC CONTENTS DATA = COST
                  OUT = TIME (KEEP = NAME TYPE LENGTH) NOPRINT;
    RUN;

    DATA _NULL_;
        SET TIME;
        IF NAME = "&COST_TIME_PERIOD";
            FORMAT_LENGTH = LEFT(COMPRESS(TRIM(PUT(LENGTH,8.))));
            CALL SYMPUT ("FORMAT_LENGTH",FORMAT_LENGTH);
            IF TYPE = 2 THEN 
            DO;
                FORMAT_PREFIX = "$";
            END;
            ELSE 
            DO;
                FORMAT_PREFIX = "";
            END;
            TIMEFORMAT = LEFT(COMPRESS(TRIM(FORMAT_PREFIX||FORMAT_LENGTH||".")));
            %GLOBAL TIME_FORMAT;
            CALL SYMPUT("TIME_FORMAT",TIMEFORMAT);
    RUN;
        
    DATA TIMELIST;
        FORMAT &COST_TIME_PERIOD &TIME_FORMAT;    
        %MACRO LISTTIMES;
            %LET I = 1;
            %LET LISTTIME = ;
            %DO %UNTIL (%SCAN(%QUOTE(&LIST_TIMES),&I,%STR(,)) = %STR());
                %LET LISTTIME = &LISTTIME
                &COST_TIME_PERIOD = %SCAN(%QUOTE(&LIST_TIMES),&I,%STR(,))%NRSTR(;) OUTPUT%NRSTR(;);
                &LISTTIME
                %LET I = %EVAL(&I + 1);
            %END;
        %MEND LISTTIMES;
        %LISTTIMES;
    RUN;

    PROC SORT DATA = TIMELIST OUT = TIMELIST NODUPKEY;
        BY &COST_TIME_PERIOD;
    RUN;

    **-------------------------------------------------------------------------**;
    **  Compare the database of all time periods to the cost data, determine   **;
    **  whether the cost data is missing any lines. Fill in any missing lines. **;
    **-------------------------------------------------------------------------**;
 
    %IF %UPCASE(&MATCH_NO_PRODUCTION)=NO OR %UPCASE(&FIND_SURROGATES)=NO %THEN
        %LET PROD_CHAR = ;
    %ELSE %IF %UPCASE(&FIND_SURROGATES)=YES %THEN
    %DO;
        %IF %UPCASE(&COST_PROD_CHARS) = YES %THEN 
            %LET PROD_CHAR = &COST_CHAR;
        %IF %UPCASE(&COST_PROD_CHARS) = NO %THEN 
            %LET PROD_CHAR = &SALES_CHAR;
    %END;

    PROC SORT DATA = COST NODUPKEY OUT = CONNUMLIST (KEEP= &COST_MANF &COST_MATCH &PROD_CHAR);
        BY &COST_MANF &COST_MATCH;
    RUN;

    PROC SQL;
        CREATE TABLE TIMEPRODLIST AS
        SELECT *
        FROM CONNUMLIST /*, TIMELIST*/;
    QUIT;

    PROC SORT DATA = TIMEPRODLIST OUT = TIMEPRODLIST;
        BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
    RUN;
 
    PROC SORT DATA = COST OUT = COST;
        BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
    RUN;

    DATA MISSCOST (KEEP = &COST_MANF &COST_MATCH &COST_TIME_PERIOD); 
        MERGE TIMEPRODLIST (IN=A) COST (IN=B);
        BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD; 
        IF A AND NOT B;
    RUN;

    PROC SORT DATA = COST OUT = FILLDATA (DROP=&COST_QTY &COST_TIME_PERIOD) NODUPKEY;
        WHERE &COST_QTY GT 0;
        BY &COST_MANF &COST_MATCH; 
    RUN;

    PROC SORT DATA = MISSCOST OUT = MISSCOST;
        BY &COST_MANF &COST_MATCH; 
    RUN;

    DATA MISSCOST;
        MERGE MISSCOST (IN=A) FILLDATA (IN=B);
        BY &COST_MANF &COST_MATCH; 
        IF A;
        FILL_DATA = "YES";
    RUN;

    DATA COST;
        SET COST MISSCOST;
    RUN;

%MEND G10_TIME_PROD_LIST;

**************************************************************************************;
** G-11 INSERT SUPPLIED INDICES INTO COST DATA FOR COST PERIODS IN POR                **;
**************************************************************************************;

%MACRO G11_INSERT_INDICES_IN(INPUT, CONDITION, INDEX_IN);
    %IF %UPCASE(&CONDITION) = NA %THEN
    %DO;
        %MACRO CONDITION_START;
        %MEND CONDITION_START;
        %MACRO CONDITION_END;
        %MEND CONDITION_END;
    %END;
    %IF %UPCASE(&CONDITION) NE NA %THEN
    %DO;
        %MACRO CONDITION_START;
            IF &CONDITION THEN DO;
        %MEND CONDITION_START;
        %MACRO CONDITION_END;
            END;
        %MEND CONDITION_END;
    %END;

    %CONDITION_START;
    %MACRO DEF_INDEX_IN;
        %LET I = 1;
        %LET DEF_IN_INDEX = ;
        %DO %UNTIL (%SCAN(&INDEX_IN, &I, %STR( )) = %STR());
            %LET DEF_IN_INDEX = &DEF_IN_INDEX
            IF COMPRESS(&COST_TIME_PERIOD) = %SYSFUNC(COMPRESS(%SCAN(%QUOTE(&TIME_INSIDE_POR),&I,%STR(,)))) 
            THEN &INPUT._INDEX = %SYSFUNC(COMPRESS(%SCAN(&INDEX_IN,&I,%STR( )))) %NRSTR(;);
            &DEF_IN_INDEX 
            %LET I = %EVAL(&I + 1);
        %END;
    %MEND DEF_INDEX_IN;
    %DEF_INDEX_IN
    %CONDITION_END
%MEND G11_INSERT_INDICES_IN;

**************************************************************************************;
** G-12 INSERT SUPPLIED INDICES INTO COST DATA FOR COST PERIODS OUTSIDE POR            **;
**************************************************************************************;

%MACRO G12_INSERT_INDICES_OUT(INPUT, CONDITION, INDEX_OUT); 
    %IF %UPCASE(&CONDITION) = NA %THEN
    %DO;
        %MACRO CONDITION_START;
        %MEND CONDITION_START;

        %MACRO CONDITION_END;
        %MEND CONDITION_END;
    %END;
    %IF %UPCASE(&CONDITION) NE NA %THEN
    %DO;
        %MACRO CONDITION_START;
            IF &CONDITION THEN DO;
        %MEND CONDITION_START;

        %MACRO CONDITION_END;
            END;
        %MEND CONDITION_END;
    %END;

    %CONDITION_START;
    %MACRO DEF_INDEX_OUT;
        %LET I = 1;
        %LET DEF_OUT_INDEX = ;
        %DO %UNTIL (%SCAN(&INDEX_OUT, &I, %STR( )) = %STR());
            %LET DEF_OUT_INDEX = &DEF_OUT_INDEX
            IF COMPRESS(&COST_TIME_PERIOD) = %SYSFUNC(COMPRESS(%SCAN(%QUOTE(&TIME_OUTSIDE_POR),&I,%STR(,)))) 
            THEN &INPUT._INDEX = %SYSFUNC(COMPRESS(%SCAN(&INDEX_OUT,&I,%STR( )))) %NRSTR(;);
            &DEF_OUT_INDEX 
            %LET I = %EVAL(&I + 1);
        %END;
    %MEND DEF_INDEX_OUT;
    %DEF_INDEX_OUT
    %CONDITION_END

%MEND G12_INSERT_INDICES_OUT;

**************************************************************************************;
**    G-13 CALCULATE TIME- AND INPUT-SPECIFIC INDICES                                    **;
**************************************************************************************;

%MACRO G13_CALC_INDICES;
    DATA INDEX;
        SET COST;
    RUN;

    %MACRO INDICES(INPUT,INPUT_ADJUSTED, INDEX_GROUP);
        DATA INDEX;
            SET INDEX;
            &INPUT._ADJUSTED = &INPUT_ADJUSTED;
        RUN;

        %IF &INDEX_GROUP = NA %THEN
        %DO;

            %LET INDEX_GROUP = GROUP;

            DATA INDEX;
                SET INDEX;
                GROUP = 'ALL';
            RUN;

        %END;

        PROC PRINT DATA = INDEX (OBS=&PRINTOBS);
            TITLE3 "SAMPLE OF COST DATA WITH PRE-INDEXING ADJUSTMENTS FOR &INPUT";
        RUN;

        PROC SORT DATA = INDEX OUT = INDEX;
            BY &INDEX_GROUP &COST_TIME_PERIOD;
        RUN;

        PROC MEANS NOPRINT DATA=INDEX; 
            WHERE &COST_QTY GT .;
            BY &INDEX_GROUP &COST_TIME_PERIOD;
            WEIGHT &COST_QTY;
            VAR &INPUT._ADJUSTED;
            OUTPUT OUT=&INPUT.GRP (DROP = _FREQ_ _TYPE_) MEAN = AVG_INDEXGRP_PERIOD_&INPUT ;
        RUN;

        DATA COUNT;
            VARLIST = " &INDEX_GROUP"; /* There must be a blank space in between the left quote and &INDEX_GROUP. */
            START=FINDC(TRIM(VARLIST),' ','B');
            LASTVAR = SUBSTR(VARLIST,START);
            CALL SYMPUT('LASTVAR',LASTVAR);
        RUN;

        %LET BASEPERIOD = %SCAN(%QUOTE(&TIME_INSIDE_POR),1,%STR(,)); 

        DATA INDEX_GRP;         
            MERGE INDEX (IN=A) &INPUT.GRP (IN=B);
            BY &INDEX_GROUP &COST_TIME_PERIOD;
            IF A & B;

                FORMAT &INPUT._INDEX 6.4;

                IF FIRST.&LASTVAR THEN PERIOD1_&INPUT = AVG_INDEXGRP_PERIOD_&INPUT ;
                RETAIN PERIOD1_&INPUT;

                IF &COST_TIME_PERIOD IN(&BASEPERIOD) THEN &INPUT._INDEX = 1;
                ELSE &INPUT._INDEX = AVG_INDEXGRP_PERIOD_&INPUT / PERIOD1_&INPUT ;
        RUN;

        PROC SORT DATA = INDEX_GRP NODUPKEY
                  OUT = INDEXLIST_&INPUT (KEEP = &COST_MANF &COST_TIME_PERIOD &INDEX_GROUP 
                                                 AVG_INDEXGRP_PERIOD_&INPUT PERIOD1_&INPUT &INPUT._INDEX );
            BY &INDEX_GROUP &COST_TIME_PERIOD;
        RUN;
      
        PROC PRINT DATA = INDEXLIST_&INPUT;
            TITLE3 "CALCULATION OF INDICES FOR &INPUT";
        RUN;

        DATA INDEX;
            MERGE INDEX (IN=A) INDEXLIST_&INPUT (IN=B KEEP=&COST_MANF &INDEX_GROUP &COST_TIME_PERIOD &INPUT._INDEX);
            BY &COST_MANF &INDEX_GROUP &COST_TIME_PERIOD;
        RUN;

    %MEND INDICES;

    %RUN_INDICES;

    DATA COST;
        SET INDEX;
    RUN;

%MEND G13_CALC_INDICES;

**************************************************************************************;
** G-14 CALCULATE TIME-SPECIFIC COSTS, WHEN REQUIRED                                **;
**************************************************************************************;

**------------------------------------------------------------------------------**;
**  For time period in the  POR, calculate product-specific total cost of        **;
**  input to be indexed                                                            **;
 **------------------------------------------------------------------------------**;

%MACRO G14_INDEX_CALC(INPUT, INPUT_ADJUSTED, INDEX);
    %IF %UPCASE(&TIME_OUTSIDE_POR) NE NA %THEN
    %DO;
        DATA COSTPOR COSTOUTPOR;
            SET COST;
                IF &COST_TIME_PERIOD IN(&TIME_INSIDE_POR) THEN OUTPUT COSTPOR;
                ELSE OUTPUT COSTOUTPOR;
        RUN;
    %END;

    %IF %UPCASE(&TIME_OUTSIDE_POR) = NA %THEN
    %DO;
        DATA COSTPOR;
            SET COST;
        RUN;
    %END;

    %PUT NOTE: This next step may generate missing values when &INPUT or &COST_QTY have missing values, but this will not affect the calculations.;

    DATA COSTPOR;
        SET COSTPOR;
            IF FILL_DATA = "YES" THEN &INPUT = .; /*For transactions not in reported cost data for which data from 
                                                    the same product in a reported time period was used to supply
                                                    information on non-indexed fields, set to missing items to be indexed.    */
            &INPUT._B4_INDEX = &INPUT_ADJUSTED;    
            TOTQTR_&INPUT._BASEPERIOD = &INPUT._B4_INDEX*&COST_QTY/&INDEX; /* value of input to be indexed by product and quarter, restated in base-period equivalents */
    RUN;

    PROC SORT DATA = COSTPOR OUT = COSTPOR;
        BY &COST_MANF &COST_MATCH;
    RUN;

    PROC MEANS NOPRINT DATA = COSTPOR;
        BY &COST_MANF &COST_MATCH;     
        VAR TOTQTR_&INPUT._BASEPERIOD &COST_QTY;
        OUTPUT OUT = BASEPERIOD (DROP=_FREQ_ _TYPE_) 
            SUM = TOTAL_CONNUM_&INPUT._BASEPERIOD  TOT_CONNUM_PROD_QTY;    /*total value of input to be indexed by product in base-period equivalents */
    RUN;

    **------------------------------------------------------------------------------**;
    ** Calculate Indexed Input Costs                                                **;
    **------------------------------------------------------------------------------**;

        **--------------------------------------------------------------------------**;
        ** Attach base-year information to cost file in order to calculate indexed    **;
        ** input costs. For products with no production during the POR, put them    **;
        ** aside for later matching to most similar product.                         **;
        **--------------------------------------------------------------------------**;

    DATA COSTPOR;                 
        MERGE COSTPOR (IN=A) BASEPERIOD (IN=B);
        BY &COST_MANF &COST_MATCH;
        IF A & B;
            INDEXED_&INPUT = &INDEX * TOTAL_CONNUM_&INPUT._BASEPERIOD / TOT_CONNUM_PROD_QTY ;
    RUN;

    PROC PRINT DATA = COSTPOR (OBS=&PRINTOBS);
        BY &COST_MANF &COST_MATCH;
        ID &COST_MANF &COST_MATCH;
        VAR &COST_TIME_PERIOD &INPUT._B4_INDEX &COST_QTY &INDEX TOTQTR_&INPUT._BASEPERIOD 
                TOTAL_CONNUM_&INPUT._BASEPERIOD TOT_CONNUM_PROD_QTY  INDEXED_&INPUT;
        TITLE3 "CALCULATION OF INDEXED &INPUT COSTS FOR PERIODS DURING THE POR";
        TITLE4 "Note: TOTQTR_&INPUT._BASEPERIOD will be missing for certain time periods if &INPUT or &COST_QTY were missing";
        TITLE5 "in reported data because there was no production.  This will not affect the calculation of INDEXED_&INPUT.";

    RUN;

    **------------------------------------------------------------------------------**;
    ** Create Date for Periods Outside the POR by Indexing Base Period Costs        **;
    **------------------------------------------------------------------------------**;

    %GLOBAL BASEPERIOD_INDEXED_INPUT BASEPERIOD_INDEX;
    %LET BASEPERIOD_INDEX = ;
    %LET BASEPERIOD_INDEXED_INPUT = ;

    %IF %UPCASE(&TIME_OUTSIDE_POR) NE NA %THEN
    %DO;

        %LET BASEPERIOD_INDEXED_INPUT = BASEPERIOD_INDEXED_&INPUT;
        %LET BASEPERIOD_INDEX = BASEPERIOD_&INDEX;


        PROC SORT DATA = COSTPOR OUT = COSTPOR;
            BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD; 
        RUN;

        DATA BASEQTR (DROP = &INPUT._B4_INDEX &COST_QTY TOTQTR_&INPUT._BASEPERIOD 
                    TOTAL_CONNUM_&INPUT._BASEPERIOD TOT_CONNUM_PROD_QTY &COST_TIME_PERIOD);
            SET COSTPOR (RENAME=(&INDEX=&BASEPERIOD_INDEX INDEXED_&INPUT=&BASEPERIOD_INDEXED_INPUT));
            BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
            IF &FIRST_COST_MANF FIRST.&COST_MATCH;
        RUN; 

        **--------------------------------------------------------------------------**;
        ** For non-indexed cost components, take information from the base time        **;
        ** period for each product.                                                    **;
        **--------------------------------------------------------------------------**;

        PROC SORT DATA = COSTOUTPOR OUT = COSTOUTPOR;
            BY &COST_MANF &COST_MATCH; 
        RUN;

        DATA COSTOUTPOR;
            MERGE COSTOUTPOR (IN=A) BASEQTR (IN=B);
            BY &COST_MANF &COST_MATCH;
            IF A & B;
            INDEXED_&INPUT = &BASEPERIOD_INDEXED_INPUT / &BASEPERIOD_INDEX * &INDEX; 
        RUN;

        PROC PRINT DATA = COSTOUTPOR (OBS = &PRINTOBS);
            VAR &COST_MANF &COST_MATCH &COST_TIME_PERIOD &BASEPERIOD_INDEXED_INPUT BASEPERIOD_&INDEX &INDEX INDEXED_&INPUT;
            TITLE3 "CALCULATION OF INDEXED &INPUT COSTS FOR TIME PERIODS OUTSIDE THE POR";
        RUN;

        **--------------------------------------------------------------------------**;
        ** Combine cost data for periods during the POR with constructed costs        **;
        **  for periods outside the POR.                                            **;
        **--------------------------------------------------------------------------**;

        DATA COST;
            SET COSTPOR COSTOUTPOR;  
        RUN;

    %END;

    %IF %UPCASE(&TIME_OUTSIDE_POR) = NA %THEN
    %DO;

        DATA COST;
            SET COSTPOR;
        RUN;

    %END;

    PROC SORT DATA = COST OUT = COST;
        BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
    RUN;

    PROC PRINT DATA = COST (OBS=&PRINTOBS);
        BY &COST_MANF &COST_MATCH;
        ID &COST_MANF &COST_MATCH;
        VAR &COST_TIME_PERIOD &INDEX TOTAL_CONNUM_&INPUT._BASEPERIOD  
             TOT_CONNUM_PROD_QTY &BASEPERIOD_INDEXED_INPUT INDEXED_&INPUT;
        TITLE3 "SUMMARY OF CALCULATION OF INDEXED &INPUT COSTS, ALL PERIODS";
    RUN;

    DATA COST;
        SET COST;
        FINAL_&INPUT = &INPUT_ADJUSTED; /* default value of reported costs for input */
            FORMAT ACTUAL_INDEX $7.;
            ACTUAL_INDEX = "ACTUAL";
        IF &COST_QTY LE 0 THEN 
            DO;
                FINAL_&INPUT = INDEXED_&INPUT; /* for periods with no production */
                ACTUAL_INDEX = "INDEXED";
            END;

            DROP &INDEX TOTQTR_&INPUT._BASEPERIOD TOTAL_CONNUM_&INPUT._BASEPERIOD
                   TOT_CONNUM_PROD_QTY &BASEPERIOD_INDEXED_INPUT &BASEPERIOD_INDEX;
    RUN;

    PROC SORT DATA = COST OUT = COST_SAMPLE;
        BY ACTUAL_INDEX &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
    RUN;

    DATA COST_SAMPLE;
        SET COST_SAMPLE;
        BY ACTUAL_INDEX &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
        IF FIRST.ACTUAL_INDEX THEN COUNT = 0;
        COUNT + 1;
        IF COUNT LE 10 THEN OUTPUT;
    RUN;

    PROC PRINT DATA = COST_SAMPLE SPLIT="*";
        BY ACTUAL_INDEX;
        ID ACTUAL_INDEX;
        VAR &COST_MANF &COST_MATCH &COST_TIME_PERIOD &COST_QTY &INPUT &INPUT._B4_INDEX INDEXED_&INPUT FINAL_&INPUT;
            LABEL     &COST_MATCH = "CONTROL*NUMBER"
                    &COST_TIME_PERIOD = "TIME*PERIOD"
                    &COST_QTY = "PRODUCTION*QUANTITY"
                    &INPUT = "REPORTED*AMOUNT"
                    &INPUT._B4_INDEX = "ACTUAL*AMOUNT"
                    INDEXED_&INPUT = "INDEXED*AMOUNT" 
                    ACTUAL_INDEX = "SELECT ACTUAL*OR INDEXED?" 
                    FINAL_&INPUT = "FINAL AMOUNT*FOR CALCS";
        TITLE3 "SELECTION OF ACTUAL v INDEXED &INPUT COSTS";
    RUN;

    DATA COST;
        SET COST;
            DROP &INPUT._B4_INDEX INDEXED_&INPUT ACTUAL_INDEX;
    RUN;

%MEND G14_INDEX_CALC;

/**************************************/
/* G-15: WEIGHT AVERAGE COST DATABASE */
/**************************************/

%MACRO G15_CHOOSE_COSTS;
    PROC FORMAT;
        VALUE $TIMETYPE
            'NA' = 'N/A'
            'AN' = 'Annualized'
            'TS' = 'Time Specific';
    RUN;

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
                         ID &PRODCHARS COST_TIME_TYPE;
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
                
            PROC SORT DATA = COST OUT = COST;                                   
                BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
            RUN;

            PROC MEANS DATA = COST NOPRINT;
                BY &COST_MANF &COST_MATCH &COST_TIME_PERIOD;
                %IDCHARS
                VAR VCOMCOP TCOMCOP GNACOP INTEXCOP TOTALCOP;
                WEIGHT &COST_QTY;
                OUTPUT OUT = AVGCOST (DROP = _FREQ_ _TYPE_) SUMWGT = &COST_QTY
                       MEAN = AVGVCOM AVGTCOM AVGGNA AVGINT AVGCOST;
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
%MEND G15_CHOOSE_COSTS;

/*******************************************************************/
/* G-16: FIND SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POR */
/*******************************************************************/

%MACRO G16_MATCH_NOPRODUCTION;
    %IF %UPCASE(&FIND_SURROGATES) = YES %THEN
    %DO;
        %GLOBAL CHARNAMES_NOPROD CHARNAMES_DIF;
        %LET CHARNAMES = ;
        %LET DIFNAMES = ;

        /********************************************/
        /* DEFINE MACRO VARIABLES THAT WILL BE USED */
        /* WHEN THERE IS TIME-SPECIFIC COST.        */
        /********************************************/

        %IF %UPCASE(&COMPARE_BY_TIME) = NO %THEN
        %DO;
            %LET NPQ = ;
            %LET NPQ_IF = 1;
            %LET NPQ_FIRST_DOT = NO_PRODUCTION_CONNUM;
            %LET NPQ_PAGEBY = NO_PRODUCTION_CONNUM;
        %END;
        %ELSE
        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            %LET NPQ = NO_PRODUCTION_QUARTER;
            %LET NPQ_IF = NO_PRODUCTION_QUARTER = &COST_TIME_PERIOD;
            %LET NPQ_FIRST_DOT = NO_PRODUCTION_QUARTER;
            %LET NPQ_PAGEBY = NO_PRODUCTION_QUARTER;
        %END;

        %MACRO CHAR_MACROS;
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
        %MEND CHAR_MACROS;
        %CHAR_MACROS

        DATA NOPRODUCTION;
            SET NOPRODUCTION;
                %MACRO RENAMECHARS;
                    %LET I = 1;
                    %LET RENAMECALC = ;
                    %DO %UNTIL (%SCAN(&PRODCHAR, &I, %STR( )) = %STR());
                        %LET RENAMECALC = &RENAMECALC
                        RENAME %SYSFUNC(COMPRESS(%SCAN(&PRODCHAR,&I,%STR( )))) 
                        = %SYSFUNC(COMPRESS(%SCAN(&CHARNAMES_NOPROD,&I,%STR( ))))%NRSTR(;); 
                        %LET I = %EVAL(&I + 1);
                    %END;
                    &RENAMECALC
                %MEND RENAMECHARS;
                %RENAMECHARS
        RUN;
    
/*      %LET TIMEDROP = ;                                */
/*      %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN        */
/*      %DO;                                             */
/*            %LET TIMEDROP=(DROP=&COST_TIME_PERIOD);    */
/*      %END;                                            */

        PROC SORT DATA = NOPRODUCTION
                  OUT = NOPRODCONNUMS /*&TIMEDROP*/ NODUPKEY;
            BY NO_PRODUCTION_CONNUM &NPQ NOPROD_TIME_TYPE;
        RUN;

        PROC SORT DATA = COST
                  OUT = COSTPRODUCTS (KEEP = &COST_MATCH &COST_TIME_PERIOD
                        &PRODCHAR COST_TIME_TYPE) NODUPKEY;
            BY &COST_MATCH &COST_TIME_PERIOD COST_TIME_TYPE;
        RUN;

        DATA SIMCOST;
            SET NOPRODCONNUMS;
                DO J = 1 TO LAST;
                SET COSTPRODUCTS POINT = J NOBS = LAST;
                IF &NPQ_IF THEN
                DO;
                    ARRAY NOPROD (*) &CHARNAMES_NOPROD;
                    ARRAY COSTPROD (*) &PRODCHAR;
                    ARRAY DIFCHR (*) &CHARNAMES_DIF;

                    DO I = 1 TO DIM(DIFCHR);
                        DIFCHR(I) = ABS(NOPROD(I) - COSTPROD(I));
                    END;
                    DROP I;
                    COST_TYPE = 'SURROGATE';
                    OUTPUT SIMCOST;
                END;
            END;
        RUN;

        PROC SORT DATA = SIMCOST OUT = SIMCOST;
            BY NO_PRODUCTION_CONNUM &NPQ &CHARNAMES_DIF;
        RUN;

        DATA SIMCOST SIMCOST_TS (DROP = &CHARNAMES_DIF NOPROD_TIME_TYPE COST_TIME_TYPE) 
             SIMCOST_AN (DROP = &CHARNAMES_DIF NOPROD_TIME_TYPE COST_TIME_TYPE)
             TOP5SIMCOST;
            SET SIMCOST;
            BY NO_PRODUCTION_CONNUM &NPQ &CHARNAMES_DIF;
                IF FIRST.&NPQ_FIRST_DOT THEN CHOICE = 0;
                CHOICE + 1;
                IF CHOICE = 1 THEN 
                DO;
                    OUTPUT SIMCOST;
                    IF NOPROD_TIME_TYPE IN("AN","NA") THEN OUTPUT SIMCOST_AN;
                    ELSE OUTPUT SIMCOST_TS;
                END; 
                IF CHOICE LE 5 THEN OUTPUT TOP5SIMCOST; 
        RUN;

        PROC PRINT DATA = TOP5SIMCOST (OBS = 50);
            BY NO_PRODUCTION_CONNUM &NPQ;
            PAGEBY &NPQ_PAGEBY;
            FORMAT NOPROD_TIME_TYPE COST_TIME_TYPE $TIMETYPE.;
            VAR NOPROD_TIME_TYPE &CHARNAMES_NOPROD &COST_MATCH &COST_TIME_PERIOD COST_TIME_TYPE &PRODCHAR &CHARNAMES_DIF CHOICE;
            TITLE3 "CHECK TOP 5 SIMILAR MATCHES FOR SURRROGATE COSTS";
        RUN;

        PROC PRINT DATA = SIMCOST (OBS = 50) SPLIT='*';
            VAR NO_PRODUCTION_CONNUM &NPQ NOPROD_TIME_TYPE &CHARNAMES_NOPROD &COST_MATCH COST_TIME_TYPE &PRODCHAR &CHARNAMES_DIF;
            LABEL &COST_MATCH  = "SURROGATE*CONNUM"
                  &COST_TIME_PERIOD = "SURROGATE*PERIOD";
            FORMAT NOPROD_TIME_TYPE COST_TIME_TYPE $TIMETYPE.;
            TITLE3 "SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING THE COST ACCOUNTING PERIOD";
        RUN;

        %LET SIMCOSTTIME = ;

        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            %LET SIMCOSTTIME = SIMCOSTTIME;

            PROC SQL;
                CREATE TABLE SIMCOSTTIME AS
                SELECT *
                FROM SIMCOST_TS/*, TIMELIST*/;
            QUIT;
        %END;

        DATA SIMCOSTALLTIME;
            SET &SIMCOSTTIME SIMCOST_AN;
        RUN;

        DATA AVGCOST;
            SET AVGCOST (DROP=COST_TIME_TYPE);
                COST_TYPE = 'CALCULATED';
        RUN;

        PROC SORT DATA = AVGCOST OUT = AVGCOST;
            BY &COST_MATCH &COST_TIME_PERIOD;
        RUN;

        PROC SORT DATA = SIMCOSTALLTIME (KEEP = NO_PRODUCTION_CONNUM
                                                &COST_MATCH COST_TYPE
                                                &COST_TIME_PERIOD)
                  OUT = SIMCOSTALLTIME;
            BY &COST_MATCH &COST_TIME_PERIOD;
        RUN;

        %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
        %DO;
            %MACRO MISS_TIME_DATA;
                TIME_MISSING (KEEP = NO_PRODUCTION_CONNUM &COST_MATCH
                                     COST_TYPE &COST_TIME_PERIOD)
            %MEND MISS_TIME_DATA;

            %MACRO MISS_TIME_OUTPUT;
                IF A & B THEN OUTPUT NOPRODUCTION; 
                IF A & NOT B THEN OUTPUT TIME_MISSING;
            %MEND MISS_TIME_OUTPUT;

            %MACRO PRINT_TIME_MISSING;
                PROC PRINT DATA = TIME_MISSING (OBS=&PRINTOBS);
                    TITLE3 "SAMPLE OF PRODUCTS WHOSE SURROGATE COSTS ARE MISSING TIME PERIODS";
                RUN;
            %MEND PRINT_TIME_MISSING;
        %END;
        %ELSE %IF %UPCASE(&COMPARE_BY_TIME) = NO %THEN
        %DO;
            %MACRO MISS_TIME_DATA;
            %MEND MISS_TIME_DATA;

            %MACRO MISS_TIME_OUTPUT;
            %MEND MISS_TIME_OUTPUT;

            %MACRO PRINT_TIME_MISSING;
            %MEND PRINT_TIME_MISSING;
        %END;

        DATA NOPRODUCTION (DROP = &COST_MATCH)%MISS_TIME_DATA;
            MERGE SIMCOSTALLTIME (IN = A) AVGCOST (IN = B DROP = COST_TYPE);
            BY &COST_MATCH &COST_TIME_PERIOD;
            %MISS_TIME_OUTPUT
            IF A & B;
        RUN;

        %PRINT_TIME_MISSING  

  DATA AVGCOST (DROP = &PRODCHAR);
      SET AVGCOST NOPRODUCTION
             (RENAME = (NO_PRODUCTION_CONNUM = &COST_MATCH));
  RUN;

/* End of section finding similar costs for products with no production during the period. */

    PROC SORT DATA = AVGCOST OUT = AVGCOST;
        BY COST_TYPE &COST_MATCH;
    RUN;

    DATA COSTCHECK (DROP = COUNT);
        SET AVGCOST;
        BY COST_TYPE &COST_MATCH;
            IF FIRST.COST_TYPE THEN COUNT = 0;
            COUNT + 1;
        IF COUNT LE 10;
    RUN;

        PROC PRINT DATA = COSTCHECK (OBS=&PRINTOBS);
            BY COST_TYPE;
            ID COST_TYPE;
            TITLE3 "SAMPLE OF COST COMPONENT CALCULATIONS FOR CALCULATED AND SURROGATE COSTS";
        RUN;
    %END; 
%MEND G16_MATCH_NOPRODUCTION;

/********************************************************************/
/* G-17: MERGE COST DATA WITH SALES DATA. SAVE DATA FROM HM PROGRAM */
/*       FOR USE WITH U.S. SALES, WHEN REQUIRED.                    */
/********************************************************************/
        
%MACRO G17_FINALIZE_COSTDATA;
    %MACRO MERGE_COST(SALES, SALES_MATCH, SALES_TIME, COSTDB);
        PROC SORT DATA = &SALES OUT = &SALES;    
            BY &SALES_MATCH &SALES_COST_MANF &SALES_TIME;
        RUN;

        PROC SORT DATA = &COSTDB OUT = AVGCOST;
            BY &COST_MATCH &COST_MANF &COST_TIME_PERIOD;
        RUN;

        DATA &SALES NOCOST;
        MERGE &SALES (IN = A)
              AVGCOST (IN = B RENAME = (&COST_MATCH = &SALES_MATCH 
                                        &COST_MANF &EQUAL_COST_MANF
                                        &SALES_COST_MANF &COST_TIME_PERIOD
                                        &EQUAL_TIME &SALES_TIME));
            BY &SALES_MATCH &SALES_COST_MANF &SALES_TIME;
            IF A AND B THEN
                OUTPUT &SALES;
            ELSE
            IF A & NOT B THEN
                OUTPUT NOCOST;
        RUN;

        PROC PRINT DATA = NOCOST (OBS = &PRINTOBS);
            TITLE3 "SAMPLE OF &SALES_DB SALES WITH NO COSTS";
        RUN;
     %MEND MERGE_COST;
    
    %IF %UPCASE(&SALESDB) = HMSALES %THEN 
    %DO;
        %MERGE_COST(HMSALES, &HMCPPROD, &HM_TIME_PERIOD, AVGCOST);

        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST 
             (RENAME =(&COST_MATCH = COST_MATCH 
                       &COST_QTY = COST_QTY 
                       &COST_TIME_PERIOD &EQUAL_TIME &COP_TIME_OUT
                       &COST_MANF &EQUAL_COST_MANF &COP_MANF_OUT));
            SET AVGCOST;
        RUN;
    %END;

    %IF %UPCASE(&SALESDB) = DOWNSTREAM %THEN 
    %DO;
        %MERGE_COST(DOWNSTREAM, &HMCPPROD, &HM_TIME_PERIOD, AVGCOST);
    %END;
    %ELSE
    %IF %UPCASE(&SALESDB) = USSALES %THEN 
    %DO;
        %IF %UPCASE(&COST_TYPE) = HM %THEN
        %DO;
            %MERGE_COST(USSALES, &USCVPROD, &US_TIME_PERIOD, 
                        COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST);
        %END;
        %IF %UPCASE(&COST_TYPE) = CV %THEN
        %DO;
            %MERGE_COST(USSALES, &USCVPROD, &US_TIME_PERIOD, AVGCOST);
        %END;
    %END;
%MEND G17_FINALIZE_COSTDATA;

/********************************************/
/* G18: DELETE ALL WORK FILES IN SAS BUFFER    */
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

**************************************************************************************;
** HM-1:  CREATE MACROS AND MACRO VARIABLES REGARDING PRIME/NON-PRIME MERCHANDISE    **;
**        AND MANUFACTURER DESIGNATION                                                   **;
**************************************************************************************;

%MACRO HM1_PRIME_MANUF_MACROS;
    %GLOBAL HMMANF SALES_COST_MANF AND_SALES_MANF EQUAL_SALES_MANF
            COST_MANF AND_COST_MANF EQUAL_COST_MANF MANF_LABEL COP_MANF_OUT FIRST_COST_MANF
            HMPRIM PRIME_PRINT PRIME_LABEL PRIME_TITLE AND_PRIME EQUAL_PRIME ;
    

    **------------------------------------------------------------------------------**;
    **  Create null values for macros when sales manufacturer is not relevant        **;
    **------------------------------------------------------------------------------**;

    %IF %UPCASE(&HMMANUF) = NA %THEN 
    %DO;
        %LET HMMANF = ;                /* manufacturer for sales data */
        %LET SALES_COST_MANF = ;    /* sales manufacturer for merging with costs */
        %LET AND_SALES_MANF = ;        /* AND operator for sales manufacturer purposes */
        %LET EQUAL_SALES_MANF = ;    /* EQUAL operator for sales manufacturer purposes */
        %LET COST_MANF = ;             /* cost manufacturer for merging with sales */
        %LET AND_COST_MANF = ;         /* AND operator for cost manufacturer purposes */
        %LET EQUAL_COST_MANF = ;     /* EQUAL operator for cost manufacturer purposes */
        %LET MANF_LABEL = ;            /* label for sales manufacturer */
        %LET COP_MANF_OUT = ;        /* Cost manufacturer variable for output cost dataset */
        %LET FIRST_COST_MANF = ;    /* 'FIRST.' language for cost manufacturer */
    %END;

    **------------------------------------------------------------------------------**;
    **  Create macros when sales manufacturer is relevant.                            **;
    **------------------------------------------------------------------------------**;

    %IF %UPCASE(&HMMANUF) NE NA %THEN 
    %DO;
        %LET HMMANF = &HMMANUF;
        %LET AND_SALES_MANF = AND ;
        %LET EQUAL_SALES_MANF = = ;
        %LET MANF_LABEL = &HMMANF = "MANUFACTURER*CODE *============" ;

        %IF %UPCASE(&COST_MANUF) = NA %THEN
        %DO;
            %LET SALES_COST_MANF = ;
            %LET COST_MANF = ;
            %LET AND_COST_MANF = ; 
            %LET EQUAL_COST_MANF = ;
            %LET COP_MANF_OUT = ; 
        %END;
        %IF %UPCASE(&COST_MANUF) NE NA %THEN
        %DO;
            %LET SALES_COST_MANF = &HMMANUF;
            %LET COST_MANF = &COST_MANUF;
            %LET AND_COST_MANF = AND ;
            %LET EQUAL_COST_MANF = = ;
            %LET COP_MANF_OUT = COST_MANUF; 
            %LET FIRST_COST_MANF = FIRST.&&COST_MANF OR;
        %END;
    %END;

    **------------------------------------------------------------------------------**;
    **  Create null macros when prime v nonprime is not relevant.                   **;
    **------------------------------------------------------------------------------**;

    %IF %UPCASE(&HMPRIME) = NA %THEN  
    %DO;
        %LET HMPRIM = ;            /* prime code for sales data */
        %LET AND_PRIME = ;         /* AND operator for prime v nonprime purposes */
        %LET EQUAL_PRIME = ;     /* EQUAL operator for prime v nonprime purposes */
        %LET PRIME_TITLE = ;     /* prime v nonprime text for titles */
        %MACRO PRIME_PRINT;        
        %MEND PRIME_PRINT;         /* printing instructions for prime v nonprime */
        %LET PRIME_LABEL = ;    /* printing label for prime code */
    %END;

    **------------------------------------------------------------------------------**;
    **  Create macros when prime/non-prime is relevant.                             **;
    **------------------------------------------------------------------------------**;

    %IF %UPCASE(&HMPRIME) NE NA %THEN 
    %DO;
        %LET HMPRIM=&HMPRIME;
        %LET AND_PRIME = & ;
        %LET EQUAL_PRIME = = ;
        %LET PRIME_TITLE = PRIME/NONPRIME ;
        %MACRO PRIME_PRINT;
            BY &HMPRIM;
            ID &HMPRIM;
            SUMBY &HMPRIM;
            PAGEBY &HMPRIM;
        %MEND PRIME_PRINT;
        %LET PRIME_LABEL = &HMPRIM = "PRIME/SECOND*QUALITY MDSE*============" ;
     %END;

%MEND HM1_PRIME_MANUF_MACROS;

**************************************************************************************;
**  HM2: SPLIT MIXED-CURRENCY VARIABLES INTO SINGLE-CURRENCY VARIABLES               **;
**************************************************************************************;

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
            IF FIRST.&CURRTYPE THEN COUNT = 0;
            COUNT + 1;
            IF COUNT LE 10 THEN OUTPUT CURRALL;
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
        /*------------------------------------------------------------*/
        /*     Create the macro variables, as needed, for non-affiliated */
        /*     manufacturer and prime.                                   */
        /*------------------------------------------------------------*/
    
        %GLOBAL NAFMANF NAFMANF_DEF NAFPRIME NAFPRIME_DEF
                CHK4SIM NAFVCOM_DEF MAKE_NAFCHARS NAFCHAR DIFCHAR;

        %IF %UPCASE(&HMMANUF) = NA %THEN    /* Create null values when manufacturer is not relevant.  */
        %DO;
            %LET NAFMANF = ;
            %MACRO NAFMANF_DEF;
            %MEND NAFMANF_DEF;
        %END;
        %ELSE
        %IF %UPCASE(&HMMANUF) NE NA %THEN   /* Create values when manufacturer is relevant  */
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

            PROC SORT DATA = HMSALES OUT = HMSALES;
                BY &HMAFFL HMLOT &HMMANF &HMPRIM &HMCUST;
            RUN;

            PROC MEANS NOPRINT DATA = HMSALES;
                BY &HMAFFL HMLOT &HMMANF &HMPRIM ;
                VAR &HMQTY;
                OUTPUT OUT = TOTS (DROP = _TYPE_ _FREQ_)
                       N = SALES SUM = TOTQTY;
            RUN;

            PROC SORT DATA = HMSALES OUT = NUMCUST NODUPKEY;
                BY &HMAFFL HMLOT &HMMANF &HMPRIM &HMCUST;
            RUN;
 
            PROC SUMMARY NOPRINT DATA = NUMCUST;
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

            PROC SORT DATA = HMAFF OUT = HMAFF;
                BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            RUN;

            PROC MEANS NOPRINT DATA = HMAFF;
                BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
                ID AVGVCOM AVGTCOM &HMCHAR;
                VAR HMNETPRI;
                WEIGHT &HMQTY;
                OUTPUT OUT = TOTAFF (DROP = _FREQ_ _TYPE_)
                       N = AFFOBS SUMWGT = AFFQTY MEAN = AFFNETPR;
            RUN;

            PROC PRINT DATA = TOTAFF (OBS = &PRINTOBS);
                TITLE3 "SAMPLE OF AFFILIATED WEIGHTED-AVERAGE NET PRICES";
            RUN;

            PROC SORT DATA = TOTAFF OUT = TOTAFF;
                BY HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM &HMCUST;
            RUN;

            /*--------------------------------------------------------------*/
            /* HM3-C: Weight-average net prices of non-affiliated customers    */
            /*--------------------------------------------------------------*/
   
            PROC SORT DATA = HMNAF OUT = HMNAF;
                BY HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            RUN;

            PROC MEANS DATA = HMNAF NOPRINT;
                BY HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
                ID NAFLOT &NAFMANF &NAFPRIME &NAF_TIME_PERIOD NAFCONN NAFVCOM &NAFCHAR;
                VAR HMNETPRI;
                WEIGHT &HMQTY;
                OUTPUT OUT = TOTNAF (DROP = _FREQ_ _TYPE_)
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

            /*-----------------------------------------------------*/
            /* HM3-E: Identify similar product matches at the same */
            /*        LOT only if cost data are available.         */
            /*-----------------------------------------------------*/

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
                               &AND_PRIME &NAFPRIME &EQUAL_PRIME &HMPRIM 
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

        **--------------------------------------------------------------------------**;
        ** HM3-I: For each product sold to an affiliate with an identical or        **;
        **        similar match, calculate the percent ratio (PCTRATIO) of            **; 
        **        the weighted-average affiliated price to the weighted-average        **;
        **        non-affiliated price.                                                **;
        **--------------------------------------------------------------------------**;

         PROC SORT DATA = TOTAFF OUT = TOTAFF; 
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
        RUN;

        PROC SORT DATA = ALLCOMP OUT = ALLCOMP;
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
        RUN;
 
        DATA ALLCOMP;
            MERGE TOTAFF (IN = A) ALLCOMP (IN = B);
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
            IF A;
            IF MATCH = '' THEN
                MATCH = 'NONE';
            IF NAFADJPR = . THEN
                PCTRATIO = .;
            ELSE PCTRATIO = (AFFNETPR / NAFADJPR) * 100;
          RUN;

        PROC SORT DATA = ALLCOMP OUT = ALLCOMP;
            BY &HMCUST HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM;
        RUN;

        PROC PRINT DATA=ALLCOMP (OBS=&PRINTOBS); 
            BY &HMCUST;
            ID &HMCUST;
                VAR HMLOT &HMMANF &HMPRIM &HM_TIME_PERIOD &HMCONNUM 
                    AFFOBS AFFQTY AFFNETPR AVGVCOM AVGTCOM 
                NAFLOT &NAF_TIME_PERIOD NAFCONN NAFOBS NAFQTY NAFNETPR NAFVCOM 
                MATCH DIFMER COSTDIFF NAFADJPR PCTRATIO; 
            TITLE3 "SAMPLE RATIOS OF AFFILIATED TO UNAFFILIATED PRICES";
           RUN;

        **--------------------------------------------------------------------------**;
        ** HM3-J: Calculate the overall CUSRATIO for each affiliated customer, and    **;
        **        keep affiliated customers with CUSRATIOs at or between 98-102 pct    **;
        **--------------------------------------------------------------------------**;

         PROC MEANS NOPRINT DATA = ALLCOMP;
             BY &HMCUST; 
             VAR PCTRATIO;
             WEIGHT AFFQTY;
             OUTPUT OUT=AFFCUST (DROP=_FREQ_ _TYPE_)
                    N=NUMCOMP MEAN = CUSRATIO;
        RUN;

        PROC MEANS NOPRINT DATA = HMAFF;
            BY &HMCUST;
            OUTPUT OUT = AFFOBS (DROP=_FREQ_ _TYPE_) N=AFFOBS;
        RUN;

         DATA AFFCUST;
             MERGE AFFCUST (IN=A) AFFOBS (IN=B);
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
                  AFFOBS   = 'CUSTOMER *SALES *============'
                  NUMCOMP  = 'CUSTOMER *WT-AVG PRICES*COMPARED *============='
                  CUSRATIO = 'CUSTOMER *WT-AVG PRICE*RATIO *============'
                  RESULTS  = 'CUSTOMER*TEST *RESULTS*========'
                  PASSOBS  = 'TOTAL SALES *PASSING TEST*============'
                  FAILOBS  = 'TOTAL SALES *FAILING TEST*============';
            FORMAT AFFOBS NUMCOMP PASSOBS FAILOBS COMMA12.;
            TITLE3 "TEST RESULTS FOR AFFILIATED CUSTOMER(S)";
        RUN;

        **------------------------------------------------------**;
        ** HM3-K: Discard HM sales that fail the CUSRATIO test. **;
        **------------------------------------------------------**;

        PROC SORT DATA = AFFCUST OUT = FAIL (KEEP = &HMCUST CUSRATIO);
            WHERE RESULTS = 'FAIL';
            BY &HMCUST;
        RUN;

        PROC SORT DATA = HMSALES OUT = HMSALES;
            BY &HMCUST;
        RUN;

        DATA HMSALES HMAFFOUT;
            MERGE HMSALES (IN=INA) FAIL (IN=INB);
            BY &HMCUST;
            IF INA AND INB 
            THEN OUTPUT HMAFFOUT;
            ELSE IF INA AND NOT INB
            THEN OUTPUT HMSALES;
        RUN;
    %END;
%MEND HM3_ARMSLENGTH;

/***********************************************/
/* HM-4: HM VALUES FOR CEP PROFIT CALCULATIONS */
/***********************************************/

%MACRO HM4_CEPTOT;
    %IF %UPCASE(&RUN_HMCEPTOT) = YES %THEN
    %DO;
        DATA HMSALES;
            SET HMSALES;
                REVENUH  = (HMGUP + HMGUPADJ - HMDISREB) * &HMQTY;
                COGSH    = (AVGCOST + HMPACK) * &HMQTY;
                SELLEXPH = (HMDSELL + HMISELL + HMCOMM) * &HMQTY;
                MOVEEXPH = HMMOVE*&HMQTY;
        RUN;

        PROC MEANS NOPRINT DATA = HMSALES;
            VAR REVENUH COGSH SELLEXPH MOVEEXPH;
            OUTPUT OUT = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMCEP (DROP = _FREQ_ _TYPE_)
                   SUM = TOTREVH TOTCOGSH TOTSELLH TOTMOVEH;
        RUN;

        PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMCEP;
            TITLE3 "HM VALUES FOR CEP PROFIT CALCULATIONS";
        RUN;
    %END;
%MEND HM4_CEPTOT;

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

    PROC SORT DATA = HMSALES OUT = HMSALES;
        BY &HMMANF &HMPRIM COSTTYPE;
    RUN;

    PROC MEANS NOPRINT DATA = HMSALES;
        BY &HMMANF &HMPRIM COSTTYPE;
        VAR HMNETPRI;
        WEIGHT &HMQTY;
        OUTPUT OUT = COSTSUMM (DROP = _FREQ_ _TYPE_)
               N = SALES SUMWGT = TOTQTY SUM = TOTVALUE;
        RUN;

    PROC PRINT DATA = COSTSUMM;
        SUM SALES TOTQTY TOTVALUE;
        FORMAT TOTQTY COMMA16.4 TOTVALUE COMMA21.4;
        TITLE3 "SUMMARY OF COST TEST";
    RUN;

    PROC PRINT DATA = HMBELOW (OBS = &PRINTOBS);
        VAR SEQH &HMCONNUM &HMMANF &HMPRIM &HM_TIME_PERIOD
            HMNPRICOP AVGCOST COPTEST PCTQABOV COSTTYPE;
        TITLE3 "SAMPLE OF BELOW COST HM SALES";
    RUN;

    PROC PRINT DATA = HMABOVE (OBS = &PRINTOBS);
        VAR SEQH &HMCONNUM &HMMANF &HMPRIM &HM_TIME_PERIOD
            HMNPRICOP AVGCOST COPTEST PCTQABOV COSTTYPE;
        TITLE3 "SAMPLE OF ABOVE COST HM SALES";
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
    /* HM5-C: Cost Recovery Test for Time-Specific Cost          */
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
            PROC MEANS NOPRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST;
                BY &COP_MANF_OUT COST_MATCH;
                VAR AVGCOST;
                WEIGHT COST_QTY;
               OUTPUT OUT = CONNUMCOST (DROP=_FREQ_ _TYPE_) MEAN = CONNUM_COST;
            RUN;

            PROC SORT DATA = HMBELOW OUT = HMBELOW;
                BY &SALES_COST_MANF &HMPRIM &HMCONNUM;
            RUN;

            PROC SORT DATA = HMSALES OUT = HMSALES;
                BY &SALES_COST_MANF &HMPRIM &HMCONNUM;
            RUN;

            PROC MEANS NOPRINT DATA = HMSALES;
                BY &SALES_COST_MANF &HMPRIM &HMCONNUM;
                VAR HMNPRICOP;
                WEIGHT &HMQTY;
                OUTPUT OUT = CONNUMPRICE (DROP = _FREQ_ _TYPE_)
                       MEAN = CONNUM_PRICE;
            RUN;

            DATA HMBELOW4TEST;
                MERGE HMBELOW (IN = A) CONNUMPRICE (IN = B); 
            BY &SALES_COST_MANF &HMPRIM &HMCONNUM;
                IF A & B;
              /*IF &HM_TIME_PERIOD IN(&LIST_TIMES);*/
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
                      AVGCOST = "TIME-SPECIFIC*COST"
                      CONNUM_PRICE = "CONTROL NUMBER*AVERAGE PRICE" 
                      CONNUM_COST = "AVERAGE COST*ALL PERIODS" 
                      COSTTYPE = "CLASSIFICATION*AFTER TEST";
                 TITLE3 "SAMPLE OF RESULTS OF COST-RECOVERY TEST PERFORMED ON";
                 TITLE4 "SALES PREVIOUSLY FOUND TO BE BELOW THE TIME-SPECIFIC COST";
             RUN;

             DATA HMABOVE;
                 SET HMABOVE RECOVERED (DROP = RECOVERED CONNUM_PRICE CONNUM_COST);
             RUN;
        %END;
    %END;
%MEND HM5_COSTTEST;

/*********************************************/
/* HM-6: SELECT HM DATA FOR WEIGHT AVERAGING */
/*                                           */
/*  Use above-cost HM sales.                 */
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
    %GLOBAL MANUF_RENAME PRIME_RENAME TIME_PER_RENAME TIME_PERIOD_RENAME;

    %IF %UPCASE(&COMPARE_BY_TIME) EQ NO %THEN 
    %DO;
        %LET TIME_PER_RENAME = ;
            %MACRO TIME_PERIOD_RENAME;
            %MEND TIME_PERIOD_RENAME;
    %END;
    %ELSE
    %IF %UPCASE(&COMPARE_BY_TIME) EQ YES %THEN
    %DO;
        %LET TIME_PER_RENAME = &HM_TIME_PERIOD=HM_TIME_PERIOD;
            %MACRO TIME_PERIOD_RENAME;
                RENAME &HM_TIME_PERIOD=HM_TIME_PERIOD;
            %MEND TIME_PERIOD_RENAME;
    %END;

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
        
    PROC MEANS NOPRINT DATA = HM;
        BY &HMMANF &HMPRIM HMLOT &MONTH &HMCONNUM &HM_TIME_PERIOD; 
        ID &HMCHAR AVGVCOM;
        VAR &WGTAVGVARS;
        WEIGHT &HMQTY;
        OUTPUT OUT = HMAVG (DROP = _FREQ_ _TYPE_) MEAN = &WGTAVGVARS; 
    RUN;

    DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMWTAV;
        SET HMAVG;
        RENAME &HMCONNUM = HMCONNUM AVGVCOM = HMVCOM;
        %MANUF_RENAME
        %PRIME_RENAME 
        %TIME_PERIOD_RENAME
    RUN;

    PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMWTAV (OBS = &PRINTOBS);
        TITLE3 "SAMPLE OF WEIGHT-AVERAGED HM VALUES FOR PRICE-TO-PRICE COMPARISON WITH U.S. SALES";
    RUN;
%MEND HM7_WTAVG_DATA;

/************************************************************************/
/* HM-8: CALCULATE SELLING EXPENSE AND PROFIT RATIOS FOR CV COMPARISONS */
/************************************************************************/

%MACRO HM8_CVSELL;
    PROC SORT DATA = HM OUT = HM;
        BY HMLOT;
    RUN;

    PROC MEANS NOPRINT DATA = HM;
        BY HMLOT;
        VAR HMDSELL HMISELL HMCOMM HMCRED HMICC
            HMINDCOM HMNPRICOP CVCREDPR AVGCOST;
        WEIGHT &HMQTY;
        OUTPUT OUT = CVSELLOT (DROP = _FREQ_ _TYPE_)
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
        TITLE3 "COMPARISON-MARKET SELLING EXPENSE RATIOS AND PROFIT RATES FOR CV";
    RUN;
%MEND HM8_CVSELL;

**************************************************************************************;
** HM-9: CALCULATE LEVEL OF TRADE ADJUSTMENT                                        **;
**************************************************************************************;

%MACRO HM9_LOTADJ;

    %IF %UPCASE(&RUN_HMLOTADJ) = YES %THEN
    %DO;
        PROC SORT DATA = HM (KEEP = HMLOT &HMCONNUM &HM_TIME_PERIOD HMNETPRI &HMQTY 
                             RENAME = (&HMCONNUM = HMCONNUM ))
                  OUT=LOTS;
        BY HMLOT HMCONNUM &HM_TIME_PERIOD;
        RUN;

        PROC MEANS NOPRINT DATA=LOTS;
        BY HMLOT HMCONNUM &HM_TIME_PERIOD;
            VAR HMNETPRI;
            WEIGHT &HMQTY;
            OUTPUT OUT=LOT1 (DROP=_FREQ_ _TYPE_)
                   MEAN = HMPRICE SUMWGT=HMQTY;
        RUN;

        DATA LOT2;
            SET LOT1;
            RENAME HMLOT = USLOT HMCONNUM = USCONNUM &HM_TIME_PERIOD &EQUAL_TIME &US_TIME 
                   HMPRICE = USPRICE HMQTY = USQTY;
        RUN;

        DATA DIFF (KEEP=HMLOT HMCONNUM USCONNUM USLOT &HM_TIME_PERIOD &US_TIME
                        GNUM GQTY LNUM LQTY ENUM EQTY DIFF QTY);
            SET LOT2;

            DO J=1 TO LAST;
                SET LOT1 POINT=J NOBS=LAST;

            IF USCONNUM=HMCONNUM &AND_TIME &HM_TIME_PERIOD &EQUAL_TIME &US_TIME THEN
                DO;
                    DIFF  = (USPRICE-HMPRICE)/HMPRICE;
                    QTY   = USQTY+HMQTY;
                    GNUM  = 0;
                    GQTY  = 0;
                    LNUM  = 0;
                    LQTY  = 0;
                    ENUM  = 0;
                    EQTY  = 0;

                    IF USPRICE GT HMPRICE THEN
                    DO;
                        GNUM = 1;
                        GQTY = USQTY+HMQTY;
                    END;
                    ELSE
                    IF USPRICE LT HMPRICE THEN 
                    DO;
                        LNUM = 1;
                        LQTY = USQTY+HMQTY;
                    END;
                    ELSE
                    DO;
                        ENUM = 1;
                        EQTY = USQTY+HMQTY;
                    END;
                    OUTPUT DIFF;
                END; 
            END;
        RUN;

        PROC SORT DATA = DIFF OUT = DIFF;
        BY USLOT HMLOT;
        RUN;

        PROC MEANS NOPRINT DATA=DIFF;
        BY USLOT HMLOT;
            VAR GNUM GQTY LNUM LQTY ENUM EQTY;
            OUTPUT OUT=RESULTS (DROP=_FREQ_ _TYPE_)
                   SUM=GTNUM GTQTY LTNUM LTQTY EQNUM EQQTY;
        RUN;

        PROC MEANS NOPRINT DATA=DIFF;
        BY USLOT HMLOT;
            VAR DIFF;
            WEIGHT QTY;
            OUTPUT OUT=RESULTS2 (DROP=_FREQ_ _TYPE_) MEAN = LOTADJ;
        RUN;

        DATA RESULTS;
            MERGE RESULTS RESULTS2;
        BY USLOT HMLOT;

            NUM = GTNUM+LTNUM+EQNUM;
            QTY = GTQTY+LTQTY+EQQTY;

            GTNPCT = GTNUM*100/NUM;
            GTQPCT = GTQTY*100/QTY;
            LTNPCT = LTNUM*100/NUM;
            LTQPCT = LTQTY*100/QTY;
            EQNPCT = EQNUM*100/NUM;
            EQQPCT = EQQTY*100/QTY;
        RUN;

        PROC PRINT DATA=RESULTS  NOOBS SPLIT='*';
            FORMAT GTNPCT LTNPCT EQNPCT GTQPCT LTQPCT EQQPCT 6.2
                   LOTADJ 6.4;
            LABEL USLOT    = 'WHEN THIS*U.S. LOT IS*COMPARED TO'
                  HMLOT    = 'THIS HM LOT'
                  GTNPCT  = 'MODELS*ABOVE'
                  GTQPCT  = 'QUANTITY*ABOVE'
                  LTNPCT  = 'MODELS*BELOW'
                  LTQPCT  = 'QUANTITY*BELOW'
                  EQNPCT  = 'MODELS*EQUAL'
                  EQQPCT  = 'QUANTITY*EQUAL'
                  LOTADJ = 'LOT ADJUSMENT*FACTOR*(LOTADJ)';
        VAR USLOT HMLOT LOTADJ 
            GTNPCT EQNPCT LTNPCT GTQPCT EQQPCT LTQPCT;
            TITLE3 "COMPARISON OF U.S. LOT TO HM LOT (ALL FIGURES GIVEN IN PERCENTAGES OF TOTAL)";
        RUN;

    DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._LOTADJ (KEEP=USLOT HMLOT LOTADJ);
            SET RESULTS;
        RUN;
    %END;
%MEND HM9_LOTADJ;


/*********************************************************************/
/* US-1: CREATE MACROS AND MACRO VARIABLES REGARDING PRIME/NON-PRIME */
/*       MERCHANDISE, MANUFACTURER DESIGNATION, COST AND MONTHS      */
/*********************************************************************/

%MACRO US1_MACROS;
    %GLOBAL USMANF HMMANF AND_P2P_MANF EQUAL_P2P_MANF MANF_LABEL
            SALES_COST_MANF COST_MANF AND_COST_MANF EQUAL_COST_MANF 
            USPRIM HMPRIM EQUAL_PRIME AND_PRIME PRIME_LABEL PRIME_TITLE
            USMON HMMON DE_MINIMIS;

    /*----------------------------------------------------------------*/
    /*  1-A CREATE MACROS RE: INVESTIGATIONS v ADMINISTRATIVE REVIEWS */
    /*----------------------------------------------------------------*/

    %IF %UPCASE(&CASE_TYPE) = INV %THEN
    %DO;
        %LET USMON =  ;
        %LET HMMON =  ; 
        %LET DE_MINIMIS = 2;
    %END;
    %ELSE
    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;
        %LET USMON = USMONTH;
        %LET HMMON = HMMONTH;
        %LET DE_MINIMIS = .5;
    %END;

    /*-------------------------------------*/
    /*  1-B CREATE MACROS RE: MANUFACTURER */
    /*-------------------------------------*/

    /*-----------------------------------------------------------------------------*/
    /*  1-B-i Create null values for macros when U.S. manufacturer is not relevant */
    /*-----------------------------------------------------------------------------*/
    
    %IF %UPCASE(&USMANUF) = NA %THEN 
    %DO;
        %LET USMANF = ;             /* U.S. sales manufacturer for merging with HM sales */
        %LET HMMANF = ;             /* HM sales manufacturer for merging with U.S. sales */
        %LET AND_P2P_MANF = ;       /* AND operator for sales manufacturer purposes */
        %LET EQUAL_P2P_MANF = ;     /* EQUAL operator for sales manufacturer purposes */
        %LET SALES_COST_MANF = ;    /* U.S. sales manufacturer for merging with costs */
        %LET COST_MANF = ;          /* cost manufacturer for merging with sales */
        %LET AND_COST_MANF = ;      /* AND operator for manufacturer re: costs */
        %LET EQUAL_COST_MANF = ;    /* EQUAL operator for manufacturer re: costs */
        %LET MANF_LABEL = ;         /* label for sales manufacturer */
    %END;

    /*----------------------------------------------------------------*/
    /*  1-B-ii Create macros when U.S. sales manufacturer is relevant */
    /*----------------------------------------------------------------*/

    %IF %UPCASE(&USMANUF) NE NA %THEN 
    %DO;
        /*---------------------------------------------------------*/
        /*  1-B-ii-a Create macros when U.S. sales manufacturer is */
        /*             relevant but HM manufacturer is not.          */
        /*---------------------------------------------------------*/

        %IF %UPCASE(&HMMANUF = NO) %THEN
        %DO;    
            %LET USMANF = ;
            %LET HMMANF = ;
            %LET AND_P2P_MANF = ;    
            %LET EQUAL_P2P_MANF = ;
            %LET MANF_LABEL = ;
        %END;

        /*------------------------------------------------------------------*/
        /*  1-B-ii-b Create macros when U.S. sales manufacturer is relevant    */
        /*           and HM manufacturer is also relevant.                  */
        /*------------------------------------------------------------------*/
    
        %ELSE
        %IF %UPCASE(&HMMANUF = YES) %THEN
        %DO;    
            %LET USMANF = &USMANUF;
            %LET HMMANF = HMMANF;
            %LET AND_P2P_MANF = AND ;    
            %LET EQUAL_P2P_MANF = = ;
            %LET MANF_LABEL = MANUFACTURER;
        %END;    

        /*-------------------------------------------------*/
        /*  1-B-ii-c Create macros for cost data when U.S. */
        /*           sales manufacturer is relevant.       */
        /*-------------------------------------------------*/

        /*---------------------------------------------------------*/
        /*  Create macros when cost data comes from the HM program */
        /*---------------------------------------------------------*/

        %IF %UPCASE(&COP_MANUF) = NO %THEN
        %DO;
             %LET SALES_COST_MANF = ;
             %LET COST_MANF = ;
             %LET AND_COST_MANF = ;
             %LET EQUAL_COST_MANF = ;
        %END;
        %ELSE
        %IF %UPCASE(&COP_MANUF)=YES %THEN
        %DO;
            %LET SALES_COST_MANF = &USMANUF;
            %LET COST_MANF = COST_MANUF;
            %LET AND_COST_MANF = AND ;
            %LET EQUAL_COST_MANF = = ;
        %END;

        /*----------------------------------------------------------------------*/
        /*  Create macros when there are direct comparisons of U.S. sales to CV    */
        /*----------------------------------------------------------------------*/

        %IF %UPCASE(&COST_TYPE) = CV %THEN
        %DO;
            %IF %UPCASE(&COST_MANUF) EQ NA %THEN
            %DO;
                %LET SALES_COST_MANF = ;
                %LET COST_MANF = ;
                %LET AND_COST_MANF = ;
                %LET EQUAL_COST_MANF = ;
            %END;
            %ELSE
            %IF %UPCASE(&COST_MANUF) NE NA %THEN
            %DO;
                %LET SALES_COST_MANF = &USMANUF;
                %LET COST_MANF = &COST_MANUF;
                %LET AND_COST_MANF = AND ;
                %LET EQUAL_COST_MANF = = ;
            %END;
        %END;
    %END;

    /*-------------------------------------------------------------*/
    /*  1-C CREATE MACROS WHEN COST DATA COMES FROM THE HM PROGRAM */
    /*-------------------------------------------------------------*/

    %IF %UPCASE(&COST_TYPE)=HM %THEN
    %DO;
        %LET COST_MATCH = COST_MATCH;    /* Variable linking costs to sales */

        %IF %UPCASE(&COMPARE_BY_TIME)= NO %THEN
        %DO;
            %LET COST_TIME_PERIOD = ; 
        %END;
        %IF %UPCASE(&COMPARE_BY_TIME)= YES %THEN
        %DO;
             %LET COST_TIME_PERIOD = COST_TIME_PERIOD; 
       %END;
    %END;

    /*------------------------------------------------------*/
    /*  1-D CREATE MACROS RE: PRIME v. NONPRIME MERCHANDISE */
    /*------------------------------------------------------*/

    /*------------------------------------------------------------------*/
    /*  1-D-i Create null macros when prime v nonprime is not relevant. */
    /*------------------------------------------------------------------*/

    %IF %UPCASE(&USPRIME) = NA %THEN  
    %DO;
        %LET USPRIM = ;       /* prime code for U.S. sales data */
        %LET HMPRIM = ;       /* prime code for HM sales data */
        %LET AND_PRIME = ;    /* AND operator for prime v nonprime purposes */
        %LET EQUAL_PRIME = ;  /* EQUAL operator for prime v nonprime purposes */
        %LET PRIME_TITLE = ;  /* prime v nonprime text for titles */
        %LET PRIME_LABEL = ;  /* printing label for prime code */
    %END;

    /*---------------------------------------------------------*/
    /*  1-D-ii Create macros when prime/non-prime is relevant. */
    /*---------------------------------------------------------*/

    %IF %UPCASE(&USPRIME) NE NA %THEN
    %DO;
        %IF %UPCASE(&HMPRIME) = YES %THEN 
        %DO;
            %LET USPRIM = &USPRIME;
            %LET HMPRIM = HMPRIME;
            %LET AND_PRIME = AND ;
            %LET EQUAL_PRIME = = ;
            %LET PRIME_TITLE = PRIME/NONPRIME ;
            %LET PRIME_LABEL = &USPRIM = "PRIME/SECOND*QUALITY MDSE*============" ;
        %END;
        %ELSE
        %IF %UPCASE(&HMPRIME) = NO %THEN 
        %DO;
            %LET USPRIM = ;
            %LET HMPRIM = ;
            %LET AND_PRIME = ;
            %LET EQUAL_PRIME = ;
            %LET PRIME_TITLE = ;
            %LET PRIME_LABEL = ;
        %END;
     %END;
%MEND US1_MACROS;

**************************************************************************************;
** US-2: CREATE VARIABLE CALLED, SALE_TYPE, INDICATING EP v CEP                        **;
**************************************************************************************;

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
        CEP_FIND = INDEX((UPCASE(SALE_TYPE)),"CEP");
        RUN;

        PROC MEANS NOPRINT DATA = USSALES;
            VAR CEP_FIND;
            OUTPUT OUT = CEPFIND (DROP=_FREQ_ _TYPE_) MAX=CEPFIND;
        RUN;

        DATA _NULL_;
            SET CEPFIND;
            IF CEPFIND GT 0 THEN CEP_PRESENT = "YES";
            ELSE CEP_PRESENT = "NO";
            CALL SYMPUT("CEP_PRESENT",CEP_PRESENT);
        RUN;

        DATA USSALES;
        SET USSALES;

    %END;

%MEND US2_SALETYPE; 

/**********************************************************************/
/** US-3: CONVERT NON-U.S. DOLLAR VARIABLES INTO U.S. DOLLAR AMOUNTS **/
/**********************************************************************/

%MACRO US3_USD_CONVERSION;

/* New - Replace the above macro with this Macro. This uses Array and doesn't loop thru. Cleaner log, reduces confusion*/
/* New - DROP THE ORIGINAL NON-CONVERTED VARIABLES */

%MACRO CONVERT_TO_USD (USE_EXRATES = , EXDATA = , VARS_TO_USD =);
    %IF %UPCASE(&USE_EXRATES) = YES AND %UPCASE(&EX1_VARS) ^= NA %THEN
    %DO;
        DATA USSALES;
            SET USSALES;

            /*************************************************/
            /** THE FOLLOWING ARRAY USES THE MACRO VARIABLE **/
            /** VAR_TO_USD TO CONVERT ADJUSTMENTS EXPRESSED **/
            /** IN FOREIGN CURRENCY TO U.S. DOLLARS.        **/
            /*************************************************/

            ARRAY CONVERT (*) &VARS_TO_USD;

            %LET I = 1;

            /****************************************************/
            /** CREATE A LIST OF REVISED VARIABLES NAMES WITH  **/
            /** THE SUFFIX _USD. LOOP THROUGH THE VARIABLES IN **/
            /** THE ORIGINAL LIST AND ADD THE REVISED VARIABLE **/
            /** NAMES TO THE MACRO VARIABLE VARS_IN_USD.       **/
            /****************************************************/

            %LET VARS_IN_USD = ;
            %DO %UNTIL (%SCAN(&VARS_TO_USD, &I, %STR( )) = %STR());
                %LET VARS_IN_USD = &VARS_IN_USD
                %SYSFUNC(COMPRESS(%SCAN(&VARS_TO_USD, &I, %STR( )) _USD));
                %LET I = %EVAL(&I + 1);
            %END;
            %LET VARS_IN_USD = %CMPRES(&VARS_IN_USD);

            ARRAY CONVERTED (*) &VARS_IN_USD;

            /*********************************************************/
            /** CONVERT THE ORIGINAL VARIABLES IN THE ARRAY CONVERT **/
            /** TO U.S DOLLARS USING THE DAILY EXCHANGE RATE AND    **/
            /** ASSIGN THE NEW VALUES TO NEW VARIABLES WITH THE     **/
            /** ORIGINAL NAME AND THE SUFFIX _USD THAT ARE IN THE   **/
            /** ARRAY CONVERTED.                                    **/
            /**                                                     **/
            /** FOR EXAMPLE, IF THE VARIABLE COAL_SV IS DENOMINATED **/
            /** IN A FOREIGN CURRENCY, THE VARIABLE COAL_SV_USD IS  **/
            /** CREATED AND DENOMINATED IN U.S. DOLLARS.            **/
            /*********************************************************/

            DO I = 1 TO DIM(CONVERT);
                CONVERTED(I) = CONVERT(I) * EXRATE_&EXDATA;
            END;
        RUN;

        PROC PRINT DATA = USSALES (OBS=&PRINTOBS);
            VAR &USSALEDATE EXRATE_&EXDATA &VARS_TO_USD &VARS_IN_USD;
            TITLE3 "SAMPLE OF FOREIGN CURRENCY VARIABLES CONVERTED INTO U.S. DOLLARS USING EXRATE_&EXDATA";
        RUN;

        /************************************************/
        /** DROP THE ORIGINAL NON-CONVERTED VARIABLES. **/
        /************************************************/

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

**************************************************************************************;
** US-4: COMMISSION OFFSETS ON U.S. SALES                                             **;
**************************************************************************************;

%MACRO US4_INDCOMM;

    USINDCOMM = 0;   /* Set default value of zero for when USCOMM is greater than zero.  */                    
    IF USCOMM = 0 THEN USINDCOMM = USICC + USISELL;     /* Value when USCOMM equal zero.  */

%MEND US4_INDCOMM;

**************************************************************************************;
** US-5: CALCULATE CEP PROFIT                                                        **;
**************************************************************************************;

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

                **------------------------------------------------------------------**; 
                ** 5-A: Convert COGSU, REVENU, SELLEXPU, and MOVEU into HM currency.**;
                **      Do not include any imputed expenses.                         **; 
                **------------------------------------------------------------------**; 

                REVENU   = ((USGUP + USGUPADJ - USDISREB) / &XRATE1) * &USQTY;
                COGSU    = (AVGCOST+ ((USPACK + CEPOTHER) / &XRATE1)) * &USQTY;
                 SELLEXPU = ((USDIRSELL + USCOMM + USISELL + 
                             CEPISELL) / &XRATE1) * &USQTY;
                MOVEXPU  = ((USDOMMOVE + USINTLMOVE) / &XRATE1) * &USQTY;
            RUN;

            PROC MEANS NOPRINT DATA = USCEP;
                VAR REVENU COGSU SELLEXPU MOVEXPU;
                OUTPUT OUT=USCEPTOT (DROP=_FREQ_ _TYPE_)
                       SUM=TOTREVU TOTCOGSU TOTSELLU TOTMOVEU;
            RUN;
            
            DATA CEPTOT;
                SET USCEPTOT;
                IF _N_=1 THEN SET COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMCEP;

                TOTREV   = TOTREVH  + TOTREVU;
                TOTCOGS  = TOTCOGSH + TOTCOGSU;
                TOTSELL  = TOTSELLH + TOTSELLU;
                TOTMOVE  = TOTMOVEH + TOTMOVEU;
                TOTEXP   = TOTCOGS  + TOTSELL+TOTMOVE;
                TOTPROFT = TOTREV - TOTEXP;

                IF TOTPROFT LT 0 
                THEN CEPRATIO = 0;
                ELSE CEPRATIO = TOTPROFT / TOTEXP;
            RUN;

            PROC PRINT DATA=CEPTOT;
                TITLE3 "CEP PROFIT CALCULATIONS";
            RUN;

            **--------------------------------------------------**;
            ** 5-B: Bring the CEP profit ratio into U.S. sales **;
            **--------------------------------------------------**;

            DATA USSALES;
                SET USSALES;
                IF _N_=1 THEN SET CEPTOT (KEEP=CEPRATIO);
            RUN;

        %END;
    %END;

%MEND US5_CEPRATE;

*****************************************;
** US-6: CBP entered value by importer **;
*****************************************;

%MACRO US6_ENTVALUE;

    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;        

        DATA USSALES;
            SET USSALES;
            LENGTH SOURCEDATA $10. ENTERED_VALUE 8.;

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

        PROC SORT DATA = USSALES OUT = USSALES; 
            BY US_IMPORTER SALE_TYPE SOURCEDATA;
        RUN;

        PROC MEANS NOPRINT DATA = USSALES;
            BY US_IMPORTER SALE_TYPE SOURCEDATA;
            VAR ENTERED_VALUE;
            WEIGHT &USQTY;
            OUTPUT OUT = IMPDATA (DROP=_FREQ_ _TYPE_)
                         N=SALES SUMWGT=TOTQTY SUM=TOTEVALU;
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

    %GLOBAL CALC_P2P CALC_CV NVMATCH;

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

        DATA HMSALES;
            SET COMPANY.&RESPONDENT._&SEGMENT._&STAGE._HMWTAV;
        RUN;

        PROC SORT DATA = HMSALES OUT = HMMODELS;
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM;
        RUN;

        PROC PRINT DATA = HMMODELS (OBS = &PRINTOBS);
            VAR &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM &HMCHAR HMVCOM;
            TITLE3 "SAMPLE OF HOME MARKET PRODUCTS FOR CONCORDANCE";
        RUN;

        PROC SORT DATA = USSALES OUT = USMODELS (KEEP = &USMANF &USPRIM USLOT &US_TIME_PERIOD  
                                                        &USMON &USCONNUM &USCHAR AVGVCOM
                                                        AVGTCOM AVGCOST) NODUPKEY;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
        RUN;

        PROC PRINT DATA = USMODELS (OBS = &PRINTOBS);
            VAR &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM &USCHAR AVGVCOM AVGTCOM;
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

                    IF WNDORDER LE 6                                           /* sales are contemporaneous  */
                       &AND_P2P_MANF &USMANF &EQUAL_P2P_MANF &HMMANF           /* same manufacturer */
                       &AND_PRIME &USPRIM &EQUAL_PRIME &HMPRIM                 /* same prime/non-prime indicator */ 
                       &AND_TIME &US_TIME_PERIOD &EQUAL_TIME &HM_TIME_PERIOD   /* same cost-related time periods */
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
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
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

                    IF 0.20 GE COSTDIFF GT .                                       /* DIFMER less than 20 percent    */
                       AND WNDORDER LE 6                                           /* sales are contemporaneous      */
                       &AND_P2P_MANF &USMANF &EQUAL_P2P_MANF &HMMANF               /* same manufacturer              */
                       &AND_PRIME &USPRIM &EQUAL_PRIME &HMPRIM                     /* same prime/non-prime indicator */ 
                       &AND_TIME &US_TIME_PERIOD &EQUAL_TIME &HM_TIME_PERIOD THEN  /* same cost-related time periods */
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
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM
               NVMATCH &DIFCHAR LOTDIFF WNDORDER COSTDIFF;
        RUN;

        DATA P2PMODS P2PTOP5;
            SET P2PMODELS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM
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
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
            PAGEBY &USCONNUM;
            FORMAT NVMATCH NVFMT.;
            VAR &USCHAR &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM &HMCHAR 
                AVGVCOM AVGTCOM HMVCOM DIFMER &DIFCHAR
                NVMATCH LOTDIFF WNDORDER COSTDIFF CHOICE;
            TITLE3 "CONCORDANCE CHECK - TOP 5 POSSIBLE MATCHES FOR SAMPLE U.S. MODELS";
        RUN;

        PROC SORT DATA = HMMODELS OUT = HMMODELS;
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM;
        RUN;

        PROC SORT DATA = P2PMODS OUT = P2PMODS;
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM;
        RUN;

        DATA P2PMODS;
            MERGE P2PMODS (IN = A) HMMODELS (IN = B);
            BY &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM;
            IF A & B THEN OUTPUT P2PMODS;
        RUN;

        PROC SORT DATA = USMODELS OUT = USMODELS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
        RUN;

        PROC SORT DATA = P2PMODS OUT = P2PMODS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
        RUN;

        /*----------------------------------------------------------*/
        /* 7-E-iv: Merge identical and similar matches into         */
        /*         USMODELS (all U.S. products).  If a U.S. product */
        /*         has no P2P match, it will be matched to CV.      */
        /*----------------------------------------------------------*/
             
        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD 
             ISMODELS (DROP = AVGCOST CHOICE)
             CVMODELS (KEEP = &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM
                              NVMATCH AVGCOST);
            MERGE USMODELS (IN = A) P2PMODS (IN = B);
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;

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
            OUT = CV (KEEP=NOBS);
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
            BY &USMANF &USPRIM USLOT &USCONNUM &US_TIME_PERIOD &USMON;
        RUN;

        PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CONCORD (OBS = &PRINTOBS);
            FORMAT NVMATCH NVFMT.;
            VAR &USMANF &USPRIM USLOT &USMON &USCONNUM &US_TIME_PERIOD &USCHAR
                &HMMANF &HMPRIM HMLOT &HM_TIME_PERIOD &HMMON HMCONNUM &HMCHAR 
                AVGVCOM AVGTCOM HMVCOM DIFMER &DIFCHAR 
                NVMATCH LOTDIFF WNDORDER COSTDIFF;
            TITLE3 "FULL CONCORDANCE - THE BEST MODEL MATCH SELECTIONS";
        RUN;
    %END;
%MEND US7_CONCORDANCE;

****************************************************;
** US-8: Merge HM LOT adjustments into U.S. sales **;
****************************************************;

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
            TITLE3 "HM LOT ADJUSTMENT FACTOR";
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

    %ELSE %IF %UPCASE(&LOT_ADJUST) = NO %THEN
    %DO;

        DATA ISMODELS; 
            SET ISMODELS;
            LENGTH LOTHDATA $3.;
            LOTHDATA = 'NO';  /* LOT data is not available */
            LOTADJ = 0;
        RUN;

    %END;

%MEND US8_LOTADJ;

**************************************************************************;
** US-9: CALCULATE COMMISSION AND CEP OFFSETS, NV AND COMPARISON        **;
**         RESULTS                                                        **;
**                                                                        **;
**    Calculate commission offsets, and then use any remaining HM         **;
**    indirects (RINDSELLH) to compute the CEP offset.                    **;    
**************************************************************************;

%MACRO US9_OFFSETS;

        /* Commissions are greater in the HM than in the U.S. market. */
        IF COMMDOL GT USCOMM THEN
        DO;
            COMOFFSET = -1 * MIN(USINDCOMM,(COMMDOL-USCOMM));
            RINDSELLH = INDDOL;
        END;

        /* Commissions are greater in the U.S. market than in the HM. */
        ELSE IF USCOMM GT COMMDOL THEN
        DO;
            COMOFFSET = MIN(ICOMMDOL,(USCOMM-COMMDOL));
            RINDSELLH = INDDOL - COMOFFSET;
        END;

        /* Commissions are equal in both markets */
        ELSE
        DO;                    
            COMOFFSET = 0; 
            RINDSELLH = INDDOL;
        END;

        /* CEP Offset */
        IF USECEPOFST = 'YES'
        THEN CEPOFFSET = MIN((CEPICC + CEPISELL), RINDSELLH);
        ELSE CEPOFFSET = 0;

%MEND US9_OFFSETS;

****************************************************************;
** US-10: PRICE-2-PRICE TRANSACTION-SPECIFIC LOT ADJUSTMENTS, **;
**        COMMISSION AND CEP OFFSETS                          **;
****************************************************************;

%MACRO US10_LOT_ADJUST_OFFSETS;

    %IF &CALC_P2P = YES %THEN
    %DO;

        PROC SORT DATA = ISMODELS (DROP = &USCHAR &HMCHAR &DIFCHAR) OUT = ISMODELS;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
        RUN;

        PROC SORT DATA = USSALES OUT = USSALES;
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM;
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
            MERGE USSALES (IN=A) ISMODELS (IN=B);
            BY &USMANF &USPRIM USLOT &US_TIME_PERIOD &USMON &USCONNUM ;
            IF A & B THEN
            DO;
                LENGTH USECEPOFST $3.;                  /* CEP offset indicator */
                USECEPOFST = 'NO';
                %MULTIPLE_CURR; /* Convert HM values in non-HM currency into HM currency, if necessary */
                LOTADJMT   = 0;
                %P2P_ADJUSTMT_CEP;
                %P2P_ADJUSTMT_LOTADJ;
                 INDDOL   = (HMICC + HMISELL) * &XRATE1; /* HM total indirects */
                COMMDOL  = HMCOMM * &XRATE1;            /* HM commissions */
                ICOMMDOL = HMINDCOM * &XRATE1;          /* HM surrogate commission */
                %US9_OFFSETS                             /* Calculate offsets */
                FARATE   = 0;                              /* P2P facts available rate */
                OUTPUT NVIDSIM;
            END;
        RUN;

        PROC PRINT DATA = NVIDSIM (OBS=&PRINTOBS);
            TITLE3 "CALCULATION OF COMMISSION OFFSETS FOR PRICE-TO-PRICE COMPARISONS";
        RUN;

    %END;

%MEND US10_LOT_ADJUST_OFFSETS;

**************************************************************************;
** US-11: SELLING EXPENSES,PROFIT AND OFFSETS FOR CONSTRUCTED VALUE    **;
**************************************************************************;

%MACRO US11_CVSELL_OFFSETS; 

    %IF %UPCASE(&CVSELL_TYPE) = HM %THEN
    %DO;

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._CVSELL (RENAME = (HMLOT = USLOT))
                  OUT = HMCVSELL;
            BY USLOT;
        RUN;

        PROC PRINT DATA = HMCVSELL;
            TITLE3 "HOME MARKET SELLING EXPENSE & PROFIT RATIOS FOR CV";
        RUN;

        PROC SORT DATA = CVMODELS OUT = CVMODELS;
            BY USLOT;
        RUN;

        DATA CVMODS NOCVSELL;
            MERGE CVMODELS (IN=A) HMCVSELL (IN=B);
            BY USLOT;
            LENGTH CVSELLPR $3.;

             IF A & NOT B THEN
            DO;
                DSELCV     = 0;
                ISELCV   = 0;
                COMMCV   = 0;
                ICOMMCV  = 0;
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
            DSELCV   = DSELCVR * AVGCOST;  /* HM direct selling, excluding CREDCV */
            ISELCV   = ISELCVR * AVGCOST;  /* HM indirect selling, excluding INVCARCV */
            COMMCV   = COMMCVR * AVGCOST;  /* HM commissions */
            ICOMMCV  = ICOMCVR * AVGCOST;  /* HM surrogate commission */
            INVCARCV = INVCVR  * AVGCOST;  /* HM inventory carrying exp */
            CVPROFIT = PRATECV * AVGCOST;  /* Amount of CV profit, in HM currency */

            LENGTH USECEPOFST $3.;  /* CEP offset indicater */
            USECEPOFST = 'NO';
            LOTDIFF    = 0;
            LOTADJMT   = 0;
            %CV_ADJUSTMT_CEP    /* Reset CEP offset indicator when allowing a CEP offset */

            TOTCV    = AVGCOST + DSELCV + ISELCV + COMMCV + CVPROFIT;
            CREDCV   = CREDCVR * TOTCV;
        
            INDDOL   = (ISELCV + INVCARCV)* &XRATE1; /* CV total indirects for offsets */
            COMMDOL  = COMMCV  * &XRATE1;              /* CV commissions  for offsets */
            ICOMMDOL = ICOMMCV * &XRATE1;              /* CV surrogate commission for offsets */
            %US9_OFFSETS;
            FARATE   = 0;  /* CV facts available rate */
    RUN;

    PROC PRINT DATA = NVCV (OBS = &PRINTOBS);
        TITLE3 "CALCULATION OF CONSTRUCTED VALUE AND COMMISSION OFFSETS FOR CV COMPARISONS";
    RUN;

%MEND US11_CVSELL_OFFSETS;

**************************************************************************;
** US-12: COMBINE SALES WITH P2P COMPARISONS WITH THOSE COMPARED TO CV    **;
**                                                                        **;
**    In addition to the variables that are required for both P2P and     **;
**    CV comparisons from this point forward, there are some required for **;
**    just P2P and others for just CV.  Below, the macro variables         **;
**    P2P_VARS and CV_VARS  are created which contain lists of such extra    **;
**    variables required for each type of comparison. When, for example    **;
**    there are P2P comparisons, P2P_VARS will be set to: HMNETPRI DIFMER    **;
**    LOTDIFF LOTADJMT, allowing these variables to be carried forward    **;
**    for later use.  However, when there is no P2P comparison, P2P_VARS    **;
**    will be set to a blank value so that the calculations will not call    **;
**    for these non-existent variables.                                    **;
**************************************************************************;

%MACRO US12_COMBINE_P2P_CV; 

    %GLOBAL P2P_VARS CV_VARS ;

    %IF &CALC_P2P = YES AND &CALC_CV = YES %THEN
    %DO;

        DATA  USSALES; 
            SET NVIDSIM NVCV (DROP=DSELCVR ISELCVR COMMCVR ICOMCVR INVCVR CREDCVR AVGCOST);
        RUN;

        %LET P2P_VARS    =  HMNETPRI DIFMER LOTDIFF LOTADJMT; /* P2P vars required */
        %LET CV_VARS     =  DSELCV ISELCV COMMCV ICOMMCV INVCARCV CREDCV CVPROFIT TOTCV; /* CV vars to keep */

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

**************************************************************************;
** US-13:  COHENS-D ANALYSIS                                            **;
**************************************************************************;
 
%MACRO US13_COHENS_D_TEST;

    TITLE3 "THE COHENS-D TEST";

    **********************************************************************;
    **     US-13-A. Create macros needed re: manufacturer and prime          **;
    **             for price comparisons                                    **;
    **********************************************************************;

        %IF %UPCASE(&NV_TYPE) = CV %THEN
        %DO;
            %LET HMMANUF= NO;
            %LET HMPRIME= NO;
        %END;

        %IF %UPCASE(&USMANUF) EQ NA OR %UPCASE(&HMMANUF)= NO %THEN
        %DO;
            %MACRO DPMANF_RENAME;
            %MEND DPMANF_RENAME;
            %MACRO DPMANF_CONDITION;
            %MEND DPMANF_CONDITION;
        %END;

        %IF %UPCASE(&USMANUF) EQ NA OR %UPCASE(&HMMANUF)= NO %THEN
        %DO;
            %MACRO DPMANF_RENAME;
            %MEND DPMANF_RENAME;
            %MACRO DPMANF_CONDITION;
            %MEND DPMANF_CONDITION;
        %END;

        %ELSE %IF %UPCASE(&USMANUF) NE NA AND %UPCASE(&HMMANUF)=YES %THEN
        %DO;
            %MACRO DPMANF_RENAME;
                &USMANF =BASE_MANUF 
            %MEND DPMANF_RENAME;
            %MACRO DPMANF_CONDITION;
                &USMANF  =BASE_MANUF AND 
            %MEND DPMANF_CONDITION;
        %END;

        %IF %UPCASE(&USPRIME) EQ NA OR %UPCASE(&HMPRIME) = NO %THEN
        %DO;
            %MACRO DPPRIME_RENAME;
            %MEND DPPRIME_RENAME;
            %MACRO DPPRIME_CONDITION;
            %MEND DPPRIME_CONDITION;
        %END;

        %ELSE %IF %UPCASE(&USPRIME) NE NA AND %UPCASE(&HMPRIME) = YES %THEN
        %DO;
            %MACRO DPPRIME_RENAME;
                &USPRIM = BASE_PRIME
            %MEND DPPRIME_RENAME;
            %MACRO DPPRIME_CONDITION;
                &USPRIM  = BASE_PRIME AND
            %MEND DPPRIME_CONDITION;
        %END;
        %IF %UPCASE(&DP_REGION_DATA) = REGION %THEN
        %DO;
            %MACRO DPREGION_PRINT_LABEL ;
            %MEND DPREGION_PRINT_LABEL;
        %END;
        %ELSE 
        %DO;
            %MACRO DPREGION_PRINT_LABEL;
                &DP_REGION = "SOURCE FOR*DP REGION*(&DP_REGION)"
            %MEND DPREGION_PRINT_LABEL;
        %END;
        %IF %UPCASE(&DP_TIME_CALC) = YES %THEN
        %DO;
            %MACRO DPPERIOD_PRINT_LABEL;
                &USSALEDATE = "U.S. DATE*OF SALE*(&USSALEDATE)"
            %MEND DPPERIOD_PRINT_LABEL;
        %END;        
        %IF %UPCASE(&DP_TIME_CALC) = NO %THEN
        %DO;
            %MACRO DPPERIOD_PRINT_LABEL;
            %MEND DPPERIOD_PRINT_LABEL;
        %END;        

    **********************************************************************;
    **  US-13-B Calculate net price for Cohens-d Analysis and set up    **;
    **            regions, purchasers and time periods.                    **;
    **********************************************************************;

    DATA DPSALES;
        SET USSALES;

            DP_COUNT = _N_;

            DP_NETPRI = USGUP + USGUPADJ - USDISREB - USDOMMOVE - 
                        USINTLMOVE - USCREDIT - USDIRSELL - USCOMM -  
                        CEPICC - CEPISELL - CEPOTHER - CEPROFIT;

            **************************************************************;
            **    US-13-B-i Establish the region, time and purchaser         **;
            **    variables for the analysis when there are existing         **;
            **    variables in the data for the same.  If the time         **;
            **    variable for the analysis is being calculated by         **;
            **    using the quarter default, do that here.                **;
            **************************************************************;

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
                        IF FINDC(&DP_REGION,"-1234567890 ","K") GT 0 THEN VALID_ZIP = "NO";
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

        DATA DPSALES USSALES (DROP=DP_NETPRI DP_PURCHASER DP_REGION DP_PERIOD);
            SET DPSALES;
        RUN;

        PROC PRINT DATA = DPSALES (OBS=&PRINTOBS) SPLIT="*";
            VAR USGUP USGUPADJ USDISREB USDOMMOVE USINTLMOVE USCREDIT USDIRSELL  
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

    **********************************************************************;
    **  US-13-C. Calculate Information Using Comparable Merchandise        **;
    **             Criteria for Cohens-D.                                    **;
    **********************************************************************;

    PROC SORT DATA = DPSALES (KEEP = &USMANF &USPRIM USLOT &USCONNUM DP_NETPRI 
                                     &USQTY DP_REGION DP_PURCHASER DP_PERIOD DP_COUNT)
              OUT = DPSALES;
           BY &USMANF &USPRIM USLOT &USCONNUM;
    RUN;

    PROC MEANS DATA = DPSALES NOPRINT VARDEF=WEIGHT;
        BY &USMANF &USPRIM USLOT &USCONNUM;
        VAR DP_NETPRI;
        WEIGHT &USQTY;
        OUTPUT OUT = DPCONNUM (DROP=_TYPE_ _FREQ_)
            N = TOTAL_CONNUM_OBS
            SUMWGT = TOTAL_CONNUM_QTY
            SUM = TOTAL_CONNUM_VALUE
            MEAN = AVG_CONNUM_PRICE
            MIN = MIN_CONNUM_PRICE
            MAX = MAX_CONNUM_PRICE
            STD = STD_CONNUM_PRICE;
    RUN;

    PROC PRINT DATA = DPCONNUM (OBS=&PRINTOBS) SPLIT="*";
        LABEL    &USCONNUM="CONTROL NUMBER"
                TOTAL_CONNUM_OBS="NUMBER*  OF  *OBSERVATIONS" 
                TOTAL_CONNUM_QTY="  TOTAL *QUANTITY"
                TOTAL_CONNUM_VALUE=" TOTAL *VALUE "
                AVG_CONNUM_PRICE="AVERAGE*PRICE "
                MIN_CONNUM_PRICE="LOWEST*PRICE "
                MAX_CONNUM_PRICE="HIGHEST*PRICE "
                STD_CONNUM_PRICE="STANDARD*DEVIATION*IN PRICE";
        BY &USMANF &USPRIM USLOT;
        ID &USMANF &USPRIM USLOT;
        SUM TOTAL_CONNUM_QTY TOTAL_CONNUM_VALUE;
        TITLE4 "OVERALL STATISTICS FOR EACH CONTROL NUMBER (ALL SALES--NO SEPARATION OF TEST AND BASE GROUP VALUES)";
    RUN;

    **************************************************************************;
    ** US-13-D. STAGE 1: Test Control Numbers by Region, Time and Purchaser    **;
    **************************************************************************;

        %MACRO COHENS_D(DP_GROUP,TITLE4);

            **************************************************************;
            **  US-13-D-ii-a. Put sales to be tested for each round in    **;
            **    DPSALES_TEST. (All sales will remain in DPSALES.) Sales **;
            **    missing group information will not be tested, but will     **;
            **    be kept in the pool for purposes of    calculating base     **;
            **    group statistics.                                        **;
            **************************************************************;

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

            ******************************************************;
            **  US-13-D-ii-b. Calculate test group information. **;
            ******************************************************;

            TITLE4 "&TITLE4";

            PROC SORT DATA = DPSALES_TEST OUT = DPSALES_TEST;
                   BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
            RUN;

            PROC MEANS DATA = DPSALES_TEST NOPRINT VARDEF=WEIGHT ;
                BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
                VAR DP_NETPRI;
                WEIGHT &USQTY;
                OUTPUT OUT = &DP_GROUP (DROP=_TYPE_ _FREQ_)
                       N = TEST_&DP_GROUP._OBS
                       SUMWGT = TEST_&DP_GROUP._QTY
                       SUM = TEST_&DP_GROUP._VALUE
                       MEAN = TEST_AVG_&DP_GROUP._PRICE
                       STD = TEST_&DP_GROUP._STD;
            RUN;

            PROC PRINT DATA = &DP_GROUP (OBS=&PRINTOBS) SPLIT="*";
                BY &USMANF &USPRIM USLOT &USCONNUM;
                ID &USMANF &USPRIM USLOT &USCONNUM;
                LABEL     &USCONNUM="CONTROL NUMBER"
                        &DP_GROUP="TEST*GROUP*(&DP_GROUP.)"
                        TEST_&DP_GROUP._OBS="TRANSACTIONS*  IN  *TEST GROUP"
                        TEST_&DP_GROUP._QTY="TOTAL QTY*  OF  *TEST GROUP"
                        TEST_&DP_GROUP._VALUE="TOTAL VALUE*  OF  *TEST GROUP" 
                        TEST_AVG_&DP_GROUP._PRICE="WT AVG PRICE*  OF  *TEST GROUP"
                        TEST_&DP_GROUP._STD="STANDARD*DEVIATION*TEST GROUP*PRICE";
                TITLE5 "CALCULATION OF TEST GROUP STATISTICS BY &DP_GROUP";
            RUN;

            ******************************************************************;
            **  US-13-D-ii-c. Attach overall control number information to     **;
            **    each test group. Then separate base v. test group             **;
            **    information re: value, quantity, observations, etc.  For     **;
            **    example, if there are three purchasers (A,B and C), when     **;
            **    purchaser A is in the test group, purchasers B and C will    **;
            **    be the base/comparison group.                                **;
            **                                                                **;
            **    If there is no base group for a control number because all     **;
            **    sales are to one purchaser, for example, (as evidenced by     **;
            **    zero obs/quantity) then no Cohens-d coefficient will be     **;
            **    calculated.                                                    **;
            ******************************************************************;

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

            ******************************************************************;
            **  US-13-D-ii-d. Attach sales of base group control numbers to    **;
            **    group-level information calculated above.  In the example of**;
            **    three purchasers (A,B&C), when the DP_GROUP = A above, all     **;
            **    sales to purchasers B&C will be joined. (See the condition     **;
            **    DP_GROUP NE BASE_GROUP in the BASECALC dataset below.)        **;
            ******************************************************************;

            DATA BASE_PRICES;
                SET DPSALES (KEEP=&USMANF &USPRIM USLOT &USCONNUM &DP_GROUP DP_NETPRI &USQTY);
                    RENAME     %DPMANF_RENAME
                            USLOT = BASELOT
                            %DPPRIME_RENAME
                            &USCONNUM = BASE_CONNUM
                            &DP_GROUP = BASE_GROUP;
            RUN;
                            
            DATA BASECALC;
                SET DPGROUP;
                DO J=1 TO LAST;
                SET BASE_PRICES POINT=J NOBS=LAST;
                    IF     %DPMANF_CONDITION
                        USLOT = BASELOT AND
                        %DPPRIME_CONDITION
                        &USCONNUM = BASE_CONNUM AND
                        &DP_GROUP NE BASE_GROUP THEN 
                    DO;
                        OUTPUT BASECALC;
                    END;
                END;
            RUN; 

            ******************************************************************;
            **  US-13-D-ii-e. Calculate the base group standard deviation.    **; 
            ******************************************************************;

            PROC SORT DATA = BASECALC OUT = BASECALC;
                BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
            RUN;

            PROC MEANS NOPRINT DATA = BASECALC VARDEF = WEIGHT;
                BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
                WEIGHT &USQTY;
                VAR DP_NETPRI;
                OUTPUT OUT = BASESTD (DROP=_FREQ_ _TYPE_) STD = BASE_STD;
            RUN;

            PROC PRINT DATA = BASESTD (OBS=&PRINTOBS) SPLIT="*";
                BY &USMANF &USPRIM USLOT &USCONNUM;
                ID &USMANF &USPRIM USLOT &USCONNUM;
                VAR &DP_GROUP BASE_STD;
                LABEL     &USCONNUM="CONTROL NUMBER"
                        &DP_GROUP="TEST GROUP*(&DP_GROUP.)"
                        BASE_STD="STANDARD DEVIATION*IN PRICE*OF BASE GROUP";
                TITLE5 "CALCULATION OF BASE GROUP STANDARD DEVIATIONS BY &DP_GROUP";
            RUN; 

            PROC SORT DATA = DPGROUP OUT = DPGROUP;
                BY &USMANF &USPRIM USLOT &USCONNUM &DP_GROUP;
            RUN;

            DATA &DP_GROUP._RESULTS;
                MERGE DPGROUP (IN=A) BASESTD (IN=B);
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

            ******************************************************************;
            **  US-13-D-ii-f. Merge results into U.S. sales data. Sales are **;
            **  flagged as either passing or not passing.                   **;
            ******************************************************************;

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
 
    **************************************************************************;
    ** US-13-D-iii. Execute Stage 1: Cohens-d Test for region, time,         **;
    **                then purchaser                                             **;
    **************************************************************************;

    %COHENS_D(DP_REGION,FIRST PASS: ANALYSIS BY REGION)
    %COHENS_D(DP_PERIOD,SECOND PASS: ANALYSIS BY TIME PERIOD)
    %COHENS_D(DP_PURCHASER,THIRD AND FINAL PASS: ANALYSIS BY PURCHASER)

    ******************************************************************************;
    ** US-13-E. Stage 2: Calculate Ratios of Sales Passing the Cohens-d Test    **;
    ******************************************************************************;

        **************************************************************************;
        ** US-13-E-i. Sales that pass any of the three rounds of the Cohens-d     **
        ** analysis pass the test as a whole.                                    **;
        **************************************************************************;

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

        **********************************************************************************;
        ** US-13-E-iii. Calculate the percentage of sales that pass the Cohens-d Test    **
        **********************************************************************************;

        PROC MEANS NOPRINT DATA= DPSALES;
            VAR DP_NETPRI;
            WEIGHT &USQTY;
            OUTPUT OUT = OVERALL (DROP=_FREQ_ _TYPE_) SUM = TOTAL_VALUE;
        RUN;

        PROC MEANS NOPRINT DATA= DPSALES;
          WHERE COHENS_D_PASS = "Yes";
          VAR DP_NETPRI;
          WEIGHT &USQTY;
          OUTPUT OUT = PASS (DROP=_FREQ_ _TYPE_) SUM = PASS_VALUE;
        RUN;

        DATA OVERALL_DPRESULTS;
            MERGE OVERALL (IN=A) PASS (IN=B);
            IF NOT B THEN DO;
                PASS_VALUE = 0;
            END;
            PERCENT_VALUE_PASSING = PASS_VALUE/TOTAL_VALUE;
            LENGTH CALC_METHOD $11.;
            IF PERCENT_VALUE_PASSING = 0 THEN
                CALC_METHOD = 'STANDARD';
            ELSE
                IF PERCENT_VALUE_PASSING EQ 1 THEN CALC_METHOD = 'ALTERNATIVE';
                ELSE CALC_METHOD = 'MIXED';
            %GLOBAL CALC_METHOD;
            CALL SYMPUT("CALC_METHOD",CALC_METHOD);
        RUN;

        PROC PRINT DATA = OVERALL_DPRESULTS SPLIT="*" NOOBS;
            VAR PASS_VALUE TOTAL_VALUE PERCENT_VALUE_PASSING;
            FORMAT PASS_VALUE TOTAL_VALUE &COMMA_FORMAT.
                PERCENT_VALUE_PASSING &PERCENT_FORMAT.;
            LABEL    PASS_VALUE="VALUE OF*PASSING SALES*=============" 
                    TOTAL_VALUE="VALUE OF*ALL SALES*=========" 
                    PERCENT_VALUE_PASSING ="PERCENT OF*SALES PASSING*BY VALUE*=============";
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
    /*--------------------------------------------------------------*/
    /* 14-A Create macro variables to keep required variables and   */
    /*      determine the weight averaging pools for U.S. sales.    */
    /*                                                              */
    /*      The macro variables AR_VARS and AR_BY_VARS will contain */
    /*      lists of additional variables needed for weight-        */
    /*      averaging and assessment purposes in administrative     */
    /*      reviews.                                                */
    /*                                                              */
    /*      For administrative reviews, the weight-averaging pools  */
    /*      will also be defined by month for cash deposit do       */
    /*      calculations. To this, the macro variable AR_BY_VARS    */
    /*      will be used in the BY statements that will either be   */
    /*      set to a blank value for investigations or the US month */
    /*      variable in administrative reviews.                     */
    /*                                                              */
    /*      When the Cohens-d Test determines that the Mixed        */
    /*      Alternative Method is to be used, then    the DP_COUNT  */
    /*      and COHENS_D_PASS macro variables will be to the        */
    /*      variables by the same names in order to keep track of   */
    /*      which observations passed Cohens-d and which did not.   */
    /*      Otherwise, the DP_COUNT and COHENS_D_PASS macro         */
    /*      variables will be set to null values. In addition, the  */
    /*      MIXED_BY_VAR macro variable will be set to COHENS_D_PASS*/
    /*      in order to allow the weight-averaging to be constricted*/
    /*      to within just sales passing the Cohens-d test.         */
    /*                                                              */
    /*      When an assessment calculation is warranted, the section*/
    /*      will be re-executed on an importer-specific basis. This */
    /*      is done by adding the US_IMPORTER variables to the BY   */
    /*      statements.                                             */
    /*--------------------------------------------------------------*/

    %GLOBAL AR_VARS AR_BY_VARS TITLE4_WTAVG TITLE4_MCALC
            DP_COUNT COHENS_D_PASS ;

    %IF %UPCASE(&CASE_TYPE) = INV %THEN
    %DO;
        %LET AR_VARS = ; 
        %LET AR_BY_VARS = ;

        /* For weight averaging */

        %LET TITLE4_WTAVG = "CONTROL NUMBER AVERAGING CALCULATIONS FOR CASH DEPOSIT PURPOSES";

        /* For results calculations */

        %LET TITLE4_MCALC = "CALCULATIONS FOR CASH DEPOSIT PURPOSES";
    %END;

    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;

        %LET AR_VARS = US_IMPORTER SOURCEU ENTERED_VALUE;
        %IF &CASH_DEPOSIT_DONE = NO %THEN
        %DO;
            %LET AR_BY_VARS = &USMON;
            %LET TITLE4_WTAVG = "CONTROL NUMBER AVERAGING CALCULATIONS FOR CASH DEPOSIT PURPOSES"; 
            %LET TITLE4_MCALC = "CALCULATIONS FOR CASH DEPOSIT PURPOSES"; 
        %END;
        %ELSE %IF &CASH_DEPOSIT_DONE = YES %THEN
        %DO;
            %LET AR_BY_VARS = &USMON US_IMPORTER;
            %LET TITLE4_WTAVG = "IMPORTER-SPECIFIC AVERAGING CALCULATIONS FOR ASSESSMENT PURPOSES";
            %LET TITLE4_MCALC = "IMPORTER-SPECIFIC CALCULATIONS FOR ASSESSMENT PURPOSES";
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

    /*--------------------------------------------------------------*/
    /* 14-C Weight-average U.S. prices and adjustments. The averaged*/
    /*      variables for the Standard Method with have "_MEAN"     */
    /*      added to the end of their original names as a suffix.   */
    /*                                                              */
    /*      When the Mixed Alternative Method is employed, an extra */
    /*      weight-averaging will be done that additionally includes*/
    /*      the COHENS_D_PASS variable in the BY statement. This    */
    /*      will allow sales not passing the Cohens-D Test to be    */
    /*      eight-averaged separately from those that did pass.     */
    /*      Weight-averaged amounts will have "_MIXED" added to the */
    /*      end of their original names.                            */
    /*--------------------------------------------------------------*/

    %MACRO WEIGHT_AVERAGE(NAMES, DP_BYVAR);
        PROC MEANS NOPRINT DATA = USNETPR;
            BY &USMANF &USPRIM USLOT SALE_TYPE &USCONNUM
               &US_TIME_PERIOD &AR_BY_VARS &DP_BYVAR;
            VAR USNETPRI USPACK USCOMM USCREDIT USDIRSELL
                CEPOFFSET COMOFFSET;
            WEIGHT &USQTY;
            OUTPUT OUT=USAVG (DROP=_FREQ_ _TYPE_) MEAN = &NAMES;
        RUN;

        DATA USNETPR;
            MERGE USNETPR (IN=A) USAVG (IN=B);
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

**************************************************************************;
** US-15: FUPDOL, NORMAL VALUE AND COMPARISON RESULTS                    **;
**                                                                        **;
**    For variables with the macro variable SUFFIX added to their names,    **;
**    weight-averaged values will be used when SUFFIX = _MEAN or _MIXED,    **;
**    but single-transaction values will be used when the suffix is a     **;
**    blank space. For example, USNETPRI will be used in calculating the     **;
**    Alternative Method, USNETPRI_MEAN for the Standard Method             **;
**    and USNETPRI_MIXED with the sales not passing Cohens-D for the         **;
**    Mixed Alternative Method.                                            **;
**                                                                        **;
**    For purposes of calculting the initial cash deposit rate, the         **;
**    IMPORTER macro variable will be set to a blank space and not enter    **; 
**    into the calculations.  When an assessment calculation is warranted,**;
**    the section will be re-executed on an importer-specific basis by     **;
**    setting the IMPORTER macro variable to US_IMPORTER.                    **;
***************************************************************************;

%MACRO US15_RESULTS; 
    %MACRO CALC_RESULTS(METHOD,CALC_TYPE,IMPORTER,OUTDATA,SUFFIX);

    **--------------------------------------------------------------**;
    **    15-A. Set up macros for this section.                        **;
    **--------------------------------------------------------------**;

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

    **--------------------------------------------------------------**;
    **    15-B. Calculate Results                                        **;
    **--------------------------------------------------------------**;

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
            TITLE4 &TITLE4_MCALC;
            TITLE5 &TITLE5;
        RUN;

        PROC PRINT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA (OBS=&PRINTOBS) SPLIT="*";
            TITLE3 "SAMPLE OF &AVG_TITLE COMPARISON RESULT CALCULATIONS &OFFSET_TITLE";
            LABEL UMARGIN = "PER-UNIT*COMPARISON*RESULTS*(UMARGIN)"
                  EMARGIN = "TRANSACTION*COMPARISON*RESULTS*(EMARGIN)"
                  PCTMARG = "COMPARISON*RESULT AS*PCT OF VALUE*(PCTMARG)";
            TITLE4 &TITLE4_MCALC;
            TITLE5 &TITLE5;
        RUN;

    **--------------------------------------------------------------**;
    **    15-C. Keep variables needed for remaining calculations and    **;
    **        put them in the database SUMMARG_<OUTDATA>.    The         **;
    **        SUMMARG_<OUTDATA> dataset does not contain any            **;
    **        offsetting information.    <OUTDATA> will be as follows    **;
    **                                                                **;
    **        AVGMARG:  Cash Deposit, Standard Method                    **;
    **        AVGMIXED: Cash Deposit, sales not passing Cohens-d for    **;
    **                  Mixed Alternative Method                        **;
    **        TRNMIXED: Cash Deposit, sales passing Cohens-d for        **;    
    **                  Mixed Alternative Method                        **;
    **        TRANMARG: Cash Deposit, A-to-T Alternative Method        **;
    **                                                                **;
    **        IMPSTND:  Assessment, Standard Method                    **;
    **        IMPCSTN:  Assessment, sales not passing Cohens-d for    **;
    **                  Mixed Alternative Method                        **;    
    **        IMPCTRN:  Assessment, sales passing Cohens-d for Mixed    **;    
    **                  Alternative Method                            **;
    **        IMPTRAN:  Assessment, A-to-T Alternative Method            **;
    **--------------------------------------------------------------**;

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA 
                  OUT = SUMMARG_&OUTDATA (KEEP = &IMPORTER &USQTY USNETPRI&SUFFIX
                        USVALUE PCTMARG EMARGIN UMARGIN &USMANF SALE_TYPE NVMATCH 
                        USECEPOFST CEPOFFSET COMOFFSET &AR_VARS &COHENS_D_PASS);
            BY &IMPORTER SALE_TYPE NVMATCH DESCENDING PCTMARG;
        RUN;

    %MEND CALC_RESULTS;

    **------------------------------------------------------------------**;
    **    15-D. Execute the CALC_RESULTS macro for the appropriate        **;
    **          scenario(s).                                                **;
    **------------------------------------------------------------------**;

        **--------------------------------------------------------------**;
        **    15-D-i. Cash deposit calculations.                            **;
        **                                                                **;
        **    In all cases, the CALC_RESULTS macro will be executed using    **;
        **    the Standard Method and the A-to-T Alternative                 **;
        **    Method for the Cash Deposit Rate.  If there is a             **;
        **    mixture of sales pass and not passing Cohens-D, then the     **;
        **    CALC_RESULTS macro will be executed a third time using the     **;
        **    Mixed Alternative Method.                                    **; 
        **                                                                **;
        **    The ABOVE_DEMINIMIS_STND, ABOVE_DEMINIMIS_MIXED and         **;
        **    ABOVE_DEMINIMIS_ALT macro variables were set to "NO" by        **;
        **    default above in US13.  They remains "NO" through the         **;
        **    calculation of the Cash Deposit rate(s). If a particular    **;
        **    Cash Deposit rate is above de minimis, its attendant macro     **;
        **    variable gets changed to "YES" to allow for its assessment  **;
        **    calculation in reviews in Sect 15-E-ii below.                 **;
        **                                                                **;
        **    If the Mixed Alternative Method is not being                 **;
        **    calculated because all sales either did or did not pass the **;
        **    Cohens-D Test, then ABOVE_DEMINIMIS_MIXED is set to "NA"    **;
        **--------------------------------------------------------------**;

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

        **--------------------------------------------------------------**;
        **    15-D-ii. Assessment Calculations (Reviews Only).            **;
        **                                                                **;
        **    For each Method for which its Cash Deposit rate is             **;
        **    above de minimis, calculate information for importer-        **;
        **    specific assessment rates.                                     **;
        **--------------------------------------------------------------**;

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
        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            VAR USNETPRI&SUFFIX;
            WEIGHT &USQTY;
            OUTPUT OUT = ALLVAL_&TEMPDATA (DROP =_FREQ_ _TYPE_)
                   N = TOTSALES SUM = TOTVAL SUMWGT = TOTQTY;
        RUN;

        /*------------------------------------------------------------*/
        /* 16-B. CALCULATE THE MINIMUM AND MAXIMUM COMPARISON RESULTS */
        /*------------------------------------------------------------*/

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            VAR PCTMARG;
            OUTPUT OUT = MINMAX_&TEMPDATA (DROP =_FREQ_ _TYPE_)
                   MIN = MINMARG MAX = MAXMARG;
        RUN;

        /*-------------------------------------------------------*/
        /* 16-C. CALCULATE THE TOTAL QUANTITY AND VALUE OF SALES */
        /*    WITH POSITIVE COMPARISON RESULTS AND AMOUNT OF     */
        /*    POSITIVE DUMPING                                   */
        /*-------------------------------------------------------*/

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            WHERE EMARGIN GT 0;
            VAR &USQTY USVALUE EMARGIN;
            OUTPUT OUT = SUMMAR_&TEMPDATA (DROP =_FREQ_ _TYPE_)
                   SUM = MARGQTY MARGVAL POSDUMPING;   
        RUN;

        /*-----------------------------------------------------------------*/
        /* 16-D. CALCULATE THE TOTAL AMOUNT OF NEGATIVE COMPARISON RESULTS */
        /*-----------------------------------------------------------------*/

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            WHERE EMARGIN LT 0;
            VAR EMARGIN;
            OUTPUT OUT = NEGMARG_&TEMPDATA (DROP = _FREQ_ _TYPE_)
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

            PROC MEANS NOPRINT DATA = MIXED;
                VAR TOTSALES TOTQTY TOTVAL MARGQTY MARGVAL
                    POSDUMPING NEGDUMPING TOTDUMPING;
                OUTPUT OUT = MIXED_SUM (DROP = _FREQ_ _TYPE_) 
                       SUM = TOTSALES TOTQTY TOTVAL MARGQTY MARGVAL
                             POSDUMPING NEGDUMPING TOTDUMPING;
            RUN;

            PROC MEANS NOPRINT DATA = MIXED;
                VAR MINMARG;
                OUTPUT OUT = MINMARG (DROP = _FREQ_ _TYPE_) MIN = MINMARG;
            RUN;

            PROC MEANS NOPRINT DATA = MIXED;
                VAR MAXMARG;
                OUTPUT OUT = MAXMARG (DROP = _FREQ_ _TYPE_) MAX = MAXMARG;
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
    %PRINT_CASH_DEPOSIT(TRANMARG, ALTERNATIVE)

    %IF &ABOVE_DEMINIMIS_MIXED NE NA %THEN
    %DO;
        %PRINT_CASH_DEPOSIT(MIXEDSPLIT,MIXED)
    %END;
    
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

    %LET CASH_DEPOSIT_DONE = YES;
%MEND US16_CALC_CASH_DEPOSIT;

/*************************************/
/* US-17: MEANINGFUL DIFFERENCE TEST */
/*************************************/

%MACRO US17_MEANINGFUL_DIFF_TEST;
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
            TITLE6 "CASE ANALYST:  Please notify management of results so that the proper method can be selected.";
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
            PROC SORT DATA = SUMMARG_&INDATA OUT = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
            RUN;

            PROC MEANS NOPRINT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
                VAR ENTERED_VALUE;
                WEIGHT &USQTY;
                OUTPUT OUT = ENTVAL_&INDATA (DROP=_FREQ_ _TYPE_)
                       N = SALES SUMWGT = ITOTQTY SUM = ITENTVAL;
            RUN;

            /*------------------------------------------------------*/
            /* 18-B-ii Calculate the sum of positive comparison     */
            /*         results.                                     */
            /*------------------------------------------------------*/

            PROC MEANS NOPRINT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
                WHERE EMARGIN GT 0;
                VAR EMARGIN;
                OUTPUT OUT = POSMARG_IMPORTER_&INDATA (DROP = _FREQ_ _TYPE_)
                       SUM = IPOSRESULTS;
            RUN;

            /*---------------------------------------------------*/
            /* 18-B-iii Calculate the sum of negative comparison */
            /*          results.                                 */
            /*---------------------------------------------------*/

            PROC MEANS NOPRINT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
                WHERE EMARGIN LT 0;
                VAR EMARGIN;
                OUTPUT OUT = NEGMARG_IMPORTER_&INDATA
                       (DROP = _FREQ_ _TYPE_) SUM = INEGRESULTS;
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

            PROC SORT DATA = ASSESS_MIXED_ALL OUT = ASSESS_MIXED_ALL;
                BY US_IMPORTER SOURCEU;
            RUN;

            PROC MEANS NOPRINT DATA = ASSESS_MIXED_ALL;
               BY US_IMPORTER SOURCEU;
               VAR SALES ITOTQTY ITENTVAL IPOSRESULTS INEGRESULTS 
                   ITOTRESULTS;
               OUTPUT OUT = ASSESS_MIXED_SUM (DROP = _FREQ_ _TYPE_) 
                      SUM = SALES ITOTQTY ITENTVAL IPOSRESULTS
                            INEGRESULTS ITOTRESULTS;
            RUN;

            DATA ASSESS_MIXED_SUM ASSESS_MIXED (DROP=CALC_TYPE);
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
        VAR &PREFIX._STND &PREFIX._MIXED &PREFIX._ALT;
        LABEL &PREFIX._STND = &LABEL_STND
              &PREFIX._MIXED = &LABEL_MIXED
              &PREFIX._ALT = &LABEL_ALT;
        FORMAT &PREFIX._STND  &PREFIX._MIXED &PREFIX._ALT &CDFORMAT;
        FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
        FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";
    RUN;
%MEND US19_FINAL_CASH_DEPOSIT;
