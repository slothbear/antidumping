/***********************************************************************/
/*                    COMMON UTILITY MACROS PROGRAM                    */
/*                 FOR USE BY BOTH ME AND NME PROGRAMS                 */
/*                                                                     */
/*            GENERIC VERSION LAST UPDATED AUGUST 13, 2024             */
/*                                                                     */
/* PART 0: SET UP MACRO VARIABLES FOR RUN TIME CALCULATION             */
/* PART 1: MACRO TO WRITE LOG TO A PERMANENT FILE                      */
/* PART 2: MACRO TO GET COUNTS OF THE DATASETS                         */
/* PART 3: REVIEW AND REPORT GENERAL SAS LOG ALERTS SUCH AS ERRORS,    */
/*         WARNINGS, UNINITIALIZED VARIABLES ETC. AND PROGRAM SPECIFIC */
/*         ALERTS WE NEED TO WATCH FOR                                 */
/* PART 4: CALL LOG SCAN MACRO ON DEMAND                               */
/* PART 5: SELECTIVELY ADJUST SALE DATE BASED ON AN EARLIER DATE       */
/*         VARIABLE.                                                   */
/* PART 6: CALCULATE IMPORTER-SPECIFIC DE MINIMIS TEST RESULTS AND     */
/*         ASSESSMENT RATES.                                           */
/* PART 7: PRINT SUMMARY OF CASH DEPOSIT RATES                         */
/***********************************************************************/

%GLOBAL NVMATCH_TYPE1 NVMATCH_TYPE2 NVMATCH_TYPE3 NVMATCH_VALUE1 NVMATCH_VALUE2 NVMATCH_VALUE3;

/*---------------------------------------------------------*/
/* PART 0: SET UP MACRO VARIABLES FOR RUN TIME CALCULATION */
/*---------------------------------------------------------*/

DATA _NULL_;
    CALL SYMPUT('BDAY', STRIP(PUT(DATE(), DOWNAME.)));
    CALL SYMPUT('BWDATE', STRIP(PUT(DATE(), WORDDATE18.)));
    CALL SYMPUT('BTIME', STRIP(PUT(TIME(), TIMEAMPM8.)));
    CALL SYMPUT('BDATE',PUT(DATE(),DATE.));
    CALL SYMPUT('BDATETIME', (STRIP(PUT(DATETIME(), 20.))));
RUN;

%PUT NOTE: This program started running on &BDAY, &BWDATE at &BTIME..;

/*--------------------------------------------------------------------*/
/* PART 1: WRITE LOG TO THE PROGRAM LOCATION                          */
/*--------------------------------------------------------------------*/

%MACRO CMAC1_WRITE_LOG;
    %IF %UPCASE(&LOG_SUMMARY) = YES %THEN
    %DO;
        FILENAME LOGFILE "&LOG.";

        PROC PRINTTO LOG = LOGFILE NEW;
        RUN;
    %END;
%MEND CMAC1_WRITE_LOG;


/*--------------------------------------------------------------------*/
/* PART 2: MACRO TO GET COUNTS OF THE DATASETS                        */
/*     THAT NEED BE TO REVIEWED                                       */
/*--------------------------------------------------------------------*/

%MACRO CMAC2_COUNTER (DATASET =, MVAR =);
    %GLOBAL COUNT_&MVAR.;
    PROC SQL NOPRINT;
          SELECT COUNT(*)
           INTO :COUNT_&MVAR.
           FROM &DATASET.;
       QUIT;
%MEND CMAC2_COUNTER ;
 
/*-------------------------------------------------------------------------*/ 
/* PART 3: REVIEW LOG AND REPORT SUMMARY AT THE END OF THE LOG FOR:        */
/*     (A) GENERAL SAS ALERTS SUCH AS ERRORS, WARNINGS, UNINITIALIZED ETC. */
/*     (B) PROGRAM SPECIFIC ALERTS THAT WE NEED TO LOOK OUT FOR.           */
/*-------------------------------------------------------------------------*/

%MACRO C_MAC3_READLOG (LOG = , ME_OR_NME =);
    /*---------------------------------------------*/ 
    /* PRINT FULL LOG TO THE SAS ENTERPRISE WINDOW */
    /*---------------------------------------------*/

    DATA _NULL_;
        INFILE LOGFILE;
        INPUT;
        PUTLOG _INFILE_;
    RUN;

    /*------------------------------------------------------------------*/ 
    /* CHECK THE JOB LOG FOR ERRORS, WARNINGS, UNINTIALIZED VARIABLES,  */
    /* CONVERTED, MISSING, REPEATS AND LICENSE.                         */
    /* PRINT THE SUMMARY TO THE JOB LOG                                 */
    /*------------------------------------------------------------------*/

    DATA _NULL_;
        INFILE "&LOG." END = END MISSOVER PAD;
        INPUT LINE $250.;

        IF SUBSTR(LINE,1,6) = "ERROR " THEN DO;
        PUT 'ERROR: SYNTAX - CHECK FOR ERRORS WITHOUT A COLON USUALLY WITH A LINE NUMBER RANGE (Ex: ERROR 200-322)';
        END;

        IF UPCASE(COMPRESS(SUBSTR(LINE,1,6))) = "ERROR:"  OR
           UPCASE(COMPRESS(SUBSTR(LINE,1,6))) = "ERROR " THEN
            ERROR + 1;

        ELSE IF UPCASE(COMPRESS(SUBSTR(LINE,1,8))) = "WARNING:" THEN
        DO;
            WARNING + 1;
            LICENSE_I = INDEX((LINE),'THE BASE PRODUCT');
            LICENSE_W = INDEX((LINE),'WILL BE EXPIRING SOON');
            LICENSE_X = INDEX((LINE),'THIS UPCOMING EXPIRATION');
            LICENSE_Y = INDEX((LINE),'INFORMATION ON YOUR WARNING PERIOD');
            LICENSE_Z = INDEX((LINE),'YOUR SYSTEM IS SCHEDULED TO EXPIRE');

            IF LICENSE_I OR LICENSE_W OR LICENSE_X OR LICENSE_Y OR LICENSE_Z THEN
                LICENSE + 1;
        END;
        ELSE
        IF UPCASE(COMPRESS(SUBSTR(LINE,1,5))) = "NOTE:" THEN
        DO;
            UNINIT_I = INDEX(UPCASE(LINE),'UNINITIALIZED');
            IF UNINIT_I THEN
                UNINIT + 1;

            REPEAT_I = INDEX(UPCASE(LINE),'REPEATS OF BY VALUES');
            IF REPEAT_I THEN
                REPEAT + 1;

            CONVERTED_I = INDEX(UPCASE(LINE), 'CONVERTED');
            IF CONVERTED_I THEN
                CONVERTED + 1;

            MISSING_I = INDEX(UPCASE(LINE), 'MISSING VALUES WERE');
            IF MISSING_I THEN
                MISSING + 1;

            DIVISION_I = INDEX(UPCASE(LINE), 'DIVISION BY ZERO DETECTED');
            IF DIVISION_I THEN
                DIVISION + 1;

            Invalid_I = INDEX(UPCASE(LINE),'INVALID');
            IF Invalid_I THEN
                Invalid + 1;
        END;

        /*--------------------------------------------*/ 
        /* CREATE MACRO VARIABLES FOR REPORTING LATER */
        /*--------------------------------------------*/

        CALL SYMPUTX('ERROR', ERROR);
        CALL SYMPUTX('WARNING', (WARNING-LICENSE));
        CALL SYMPUTX('LICENSE', LICENSE);
        CALL SYMPUTX('UNINIT', UNINIT);
        CALL SYMPUTX('REPEAT', REPEAT);
        CALL SYMPUTX('CONVERTED', CONVERTED);
        CALL SYMPUTX('MISSING', MISSING);
        CALL SYMPUTX('DIVISION', DIVISION);
        CALL SYMPUTX('INVALID', INVALID);
    RUN;

    /*----------------------------------------------------------------*/ 
    /*  REVIEW THE JOB LOG FOR PROGRAM SPECIFIC ALERTS. GET COUNTS OF */
    /*  THE DATASETS THAT WERE CREATED FOR VALIDATION PURPOSES. THE   */
    /*  LIST OF DATASETS CAN VARY BASED ON THE PROGRAM EXECUTED.      */
    /*----------------------------------------------------------------*/

    %IF %UPCASE("&ME_OR_NME.") = "MEHOME" %THEN
    %DO;
        %CMAC2_COUNTER (DATASET = NEGDATA_HM, MVAR = NEGDATA_HM);
        %CMAC2_COUNTER (DATASET = OUTDATES_HM, MVAR = OUTDATES_HM);
        %CMAC2_COUNTER (DATASET = NOCOST_HMSALES, MVAR = NOCOST_HMSALES);

        %IF &RUN_ARMSLENGTH. = YES %THEN
        %DO;
            %CMAC2_COUNTER (DATASET = HMAFFOUT, MVAR = HMAFFOUT);        
        %END;

        %IF &RUN_DOWNSTREAM. = YES %THEN
        %DO;
            %CMAC2_COUNTER (DATASET = COMPANY.&DOWNSTREAMDATA, MVAR = ORIG_DSSALES);
            %CMAC2_COUNTER (DATASET = NOCOST_DOWNSTREAM, MVAR = NOCOST_DSSALES);
        %END;

        %IF &COMPARE_BY_TIME. = YES AND &RUN_RECOVERY. = YES %THEN
        %DO;
            %CMAC2_COUNTER (DATASET = RECOVERED, MVAR = RECOVERED);        
        %END;

        %CMAC2_COUNTER (DATASET = HMABOVE, MVAR = HMABOVE); 
        %CMAC2_COUNTER (DATASET = HMBELOW, MVAR = HMBELOW); 
        %CMAC2_COUNTER (DATASET = HM, MVAR = HMWTAVG); 
        %CMAC2_COUNTER (DATASET = HMAVG, MVAR = HMAVG); 
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "MEMARG" %THEN
    %DO;
        %CMAC2_COUNTER (DATASET = NEGDATA_US, MVAR = NEGDATA_US);
        %CMAC2_COUNTER (DATASET = OUTDATES_US, MVAR = OUTDATES_US);
        %CMAC2_COUNTER (DATASET = NOCOST_USSALES, MVAR = NOCOST_USSALES);
        %CMAC2_COUNTER (DATASET = NORATES, MVAR = NORATES);
        %CMAC2_COUNTER (DATASET = NO_DP_REGION_TEST, MVAR = NO_DP_REGION_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PURCHASER_TEST, MVAR = NO_DP_PURCHASER_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PERIOD_TEST, MVAR = NO_DP_PERIOD_TEST);
        
        PROC FREQ DATA = USNETPR NOPRINT;
             TABLES NVMATCH / OUT = NVMATCH_OUTPUT;
        RUN;

        PROC SORT DATA = NVMATCH_OUTPUT OUT = NVMATCH_OUTPUT;
            BY NVMATCH;
        RUN;

        %LET NVMATCH_TYPE1  = IDENTICAL;
        %LET NVMATCH_VALUE1 = 0;
        %LET NVMATCH_TYPE2  = SIMILAR;
        %LET NVMATCH_VALUE2 = 0;
        %LET NVMATCH_TYPE3  = CONSTRUCTED VALUE;
        %LET NVMATCH_VALUE3 = 0;
        %LET NVMATCH_TYPE4  = FACTS AVAILABLE;
        %LET NVMATCH_VALUE4 = 0;
        
        DATA _NULL_;
            SET NVMATCH_OUTPUT;
            SUFFIX = PUT(NVMATCH, 1.);
            CALL SYMPUTX(CATS('NVMATCH_VALUE', SUFFIX), PUT(COUNT, 8.) , 'G');
        RUN;
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "NME" %THEN
    %DO;
        %CMAC2_COUNTER (DATASET = NEGDATA, MVAR = NEGDATA);
        %CMAC2_COUNTER (DATASET = OUTDATES, MVAR = OUTDATES);
        %CMAC2_COUNTER (DATASET = NOFOP, MVAR = NOFOP);
        %IF &USE_EXRATES1 = YES %THEN
        %DO;
            %CMAC2_COUNTER (DATASET = NOEXRATE, MVAR = NOEXRATE);
        %END;
        %CMAC2_COUNTER (DATASET = NEGATIVE_NVALUES, MVAR = NEGATIVE_NVALUES);
        %CMAC2_COUNTER (DATASET = NEGATIVE_USPRICES, MVAR = NEGATIVE_USPRICES);
        %CMAC2_COUNTER (DATASET = NO_DP_REGION_TEST, MVAR = NO_DP_REGION_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PERIOD_TEST, MVAR = NO_DP_PERIOD_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PURCHASER_TEST, MVAR = NO_DP_PURCHASER_TEST);
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "DATAINT" %THEN 
    %DO;
    %END;

    /*---------------------------------------------------------------------*/ 
    /*  PRINTING SUMMARY OF GENERAL SAS ALERTS AS WELL AS PROGRAM SPECIFIC */
    /*  ALERTS SUMMARY TO THE JOB LOG                                      */
    /*---------------------------------------------------------------------*/

    %PUT ************************************************************************************;
    %PUT ************************************************************************************;
    %PUT * GENERAL SAS ALERTS:                                                              *;
    %PUT ************************************************************************************;
    %PUT *   NORMALLY, BELOW ALERTS SHOULD BE ZERO                                          *;
    %PUT *   IF THEY DO NOT HAVE ZERO INSTANCES DETERMINE IF THERE IS AN ISSUE.             *;
    %PUT ************************************************************************************;
    %PUT # OF ERRORS                       = &ERROR;
    %PUT # OF WARNINGS                     = &WARNING;
    %PUT # OF UNINITIALIZED VARIABLES      = &UNINIT;
    %PUT # OF MISSING VALUES               = &MISSING;
    %PUT # OF REPEATS OF BY VALUES         = &REPEAT;
    %PUT # OF CONVERTED VARIABLES          = &CONVERTED;
    %PUT # OF DIVISION BY ZERO DETECTED    = &DIVISION;
    %PUT # OF INVALID DATA VALUES          = &INVALID;
    %PUT # OF LICENSE WARNINGS             = &LICENSE;

    %MACRO HDR;
        %PUT ************************************************************************************;
        %PUT * PROGRAM SPECIFIC ALERTS TO VERIFY:                                               *;
        %PUT ************************************************************************************;
        %PUT *   NORMALLY, COUNTS FOR THE BELOW LISTED DATATSETS HAVE ZERO OBSERVATIONS.        *;
        %PUT *   IF THEY DO NOT HAVE ZERO RECORDS DETERMINE IF THERE IS AN ISSUE.               *;
        %PUT ************************************************************************************;
    %MEND HDR;

    %MACRO DF;
        %PUT ************************************************************************************;
        %PUT * DATA FLOW:                                                                       *;
        %PUT ************************************************************************************;
        %PUT *   THIS SECTION SHOWS THE FLOW OF SALES IN THE PROGRAM.                           *;
        %PUT ************************************************************************************;
    %MEND DF;
 
    %IF %UPCASE("&ME_OR_NME.") = "MEHOME" %THEN
    %DO;
        %HDR; 
        %PUT # OF CM SALES WITH PRICES AND/OR QTY <=0 (WORK.NEGDATA_HM)               = %CMPRES(&COUNT_NEGDATA_HM);
        %PUT # OF CM SALES OUTSIDE DATE RANGE (WORK.OUTDATES_HM)                      = %CMPRES(&COUNT_OUTDATES_HM);
        %PUT # OF CM SALES WITH NO COST DATA (WORK.NOCOST_HMSALES)                    = %CMPRES(&COUNT_NOCOST_HMSALES);
        %IF &RUN_DOWNSTREAM. = YES %THEN
        %DO;
            %PUT # OF DOWNSTREAM SALES WITH NO COST DATA (WORK.NOCOST_DOWNSTREAM)     = %CMPRES(&COUNT_NOCOST_DSSALES);
        %END; 
        %DF;
        %PUT # OF TOTAL COST OBS GOING IN (COMPANY.&COST_DATA)                        = %CMPRES(&COUNT_ORIG_COST);
        %PUT # OF COST OBS TO BE WEIGHT AVERAGED (WORK.COST)                          = %CMPRES(&COUNT_PRE_AVGCOST);
        %PUT # OF WEIGHT AVERAGED COST MODELS (WORK.AVGCOST)                          = %CMPRES(&COUNT_AVGCOST);
        %PUT # OF TOTAL CM SALES GOING IN (COMPANY.&HMDATA)                           = %CMPRES(&COUNT_ORIG_HMSALES);
        %IF &RUN_ARMSLENGTH. = YES %THEN
        %DO;
            %PUT # OF CM SALES FAILING ARMS LENGTH TEST (WORK.HMAFFOUT)               = %CMPRES(&COUNT_HMAFFOUT);
        %END; 
        %IF &RUN_DOWNSTREAM. = YES %THEN
        %DO;
            %PUT # OF TOTAL DS SALES GOING IN (COMPANY.&DOWNSTREAMDATA)               = %CMPRES(&COUNT_ORIG_DSSALES);
        %END;
        %PUT # OF CM SALES ABOVE COST TEST (WORK.HMABOVE)                             = %CMPRES(&COUNT_HMABOVE);
        %PUT # OF CM SALES FAILING THE COST TEST (WORK.HMBELOW)                       = %CMPRES(&COUNT_HMBELOW);
        %IF &COMPARE_BY_TIME. = YES AND &RUN_RECOVERY. = YES %THEN
        %DO;
            %PUT # OF CM SALES PASSING THE COST RECOVERY TEST (WORK.RECOVERED)        = %CMPRES(&COUNT_RECOVERED);
        %END;
        %PUT # OF CM TO BE WEIGHT AVERAGED (WORK.HM)                                  = %CMPRES(&COUNT_HMWTAVG);
        %PUT # OF WEIGHT AVERAGED CM MODELS (WORK.HMAVG)                              = %CMPRES(&COUNT_HMAVG);
        %PUT ************************************************************************************;
        %PUT ************************************************************************************;
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "MEMARG" %THEN
    %DO;
        %HDR;
        %PUT # OF US SALES WITH PRICES AND/OR QTY <=0 (WORK.NEGDATA_US)                    = %CMPRES(&COUNT_NEGDATA_US);
        %PUT # OF US SALES OUTSIDE DATE RANGE (WORK.OUTDATES_US)                           = %CMPRES(&COUNT_OUTDATES_US);
        %PUT # OF US SALES WITH NO COST DATA (WORK.NOCOST_USSALES)                         = %CMPRES(&COUNT_NOCOST_USSALES);
        %PUT # OF US SALES WITH NO EXCHANGE RATES (WORK.NORATES)                           = %CMPRES(&COUNT_NORATES);
        %PUT # OF US SALES WITH INVALID REGIONAL VALUES (WORK.NO_DP_REGION_TEST)           = %CMPRES(&COUNT_NO_DP_REGION_TEST);
        %PUT # OF US SALES WITH INVALID PURCHASER VALUES (WORK.NO_DP_PURCHASER_TEST)       = %CMPRES(&COUNT_NO_DP_PURCHASER_TEST);
        %PUT # OF US SALES WITH INVALID TIME VALUES (WORK.NO_DP_PERIOD_TEST)               = %CMPRES(&COUNT_NO_DP_PERIOD_TEST);
        %DF;
        %IF &COST_TYPE = CV %THEN
        %DO;
            %PUT # OF TOTAL COST OBS GOING IN (COMPANY.&COST_DATA)                         = %CMPRES(&COUNT_ORIG_COST);
            %PUT # OF COST OBS TO BE WEIGHT AVERAGED (WORK.COST)                           = %CMPRES(&COUNT_PRE_AVGCOST);
            %PUT # OF WEIGHT AVERAGED COST MODELS (WORK.AVGCOST)                           = %CMPRES(&COUNT_AVGCOST);
        %END; 
        %PUT # OF TOTAL US SALES1 (COMPANY.&USDATA)                                        = %CMPRES(&COUNT_ORIG_USSALES);
        %PUT # OF USSALES WITH IDENTICAL MODEL MATCHES (DERIVED FROM WORK.USNETPR)         = %CMPRES(&NVMATCH_VALUE1);
        %PUT # OF USSALES WITH SIMILAR MODEL MATCHES (DERIVED FROM WORK.USNETPR)           = %CMPRES(&NVMATCH_VALUE2);
        %PUT # OF USSALES WITH CONSTRUCTED VALUE MODEL MATCHES (DERIVED FROM WORK.USNETPR) = %CMPRES(&NVMATCH_VALUE3);
        %PUT # OF USSALES WITH FACTS AVAILABLE MODEL MATCHES (DERIVED FROM WORK.USNETPR)   = %CMPRES(&NVMATCH_VALUE4);
        %PUT # OF US SALES USED IN WEIGHT AVERAGING (WORK.WT_AVG_USSALES)                  = %CMPRES(&COUNT_WT_AVG_USSALES);
        %PUT ************************************************************************************;
        %PUT ************************************************************************************;
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "NME" %THEN
    %DO; 
        %HDR;
        %PUT # OF US SALES WITH PRICES AND/OR QTY <=0 (WORK.NEGDATA)                 = %CMPRES(&COUNT_NEGDATA);
        %PUT # OF US SALES OUTSIDE DATE RANGE (WORK.OUTDATES)                        = %CMPRES(&COUNT_OUTDATES);
        %PUT # OF US SALES WITH NO MATCHING FACTORS OF PRODUCTION (WORK.NOFOP)       = %CMPRES(&COUNT_NOFOP);
        %IF &USE_EXRATES1 = YES %THEN
        %DO;
            %PUT # OF US SALES WITH NO EXCHANGE RATES (WORK.NOEXRATE)                    = %CMPRES(&COUNT_NOEXRATE);
        %END;
        %PUT # OF US SALES WITH INVALID REGIONAL VALUES (WORK.NO_DP_REGION_TEST)     = %CMPRES(&COUNT_NO_DP_REGION_TEST);
        %PUT # OF US SALES WITH INVALID PURCHASER VALUES (WORK.NO_DP_PURCHASER_TEST) = %CMPRES(&COUNT_NO_DP_PURCHASER_TEST);
        %PUT # OF US SALES WITH INVALID TIME VALUES (WORK.NO_DP_PERIOD_TEST)         = %CMPRES(&COUNT_NO_DP_PERIOD_TEST);
        %DF;
        %PUT # OF US SALES GOING IN (COMPANY.&USDATA)                                = %CMPRES(&COUNT_ORIG_USSALES);
        %PUT # OF FOP OBS GOING IN (COMPANY.&FOPDATA)                                = %CMPRES(&COUNT_ORIG_FOPDATA);
        %PUT # OF US SALES WITH NEGATIVE NORMAL VALUES (WORK.NEGATIVE_NVALUES)       = %CMPRES(&COUNT_NEGATIVE_NVALUES);
        %PUT # OF US SALES WITH NEGATIVE NET US PRICES (WORK.NEGATIVE_USPRICES)      = %CMPRES(&COUNT_NEGATIVE_USPRICES);
        %PUT # OF US PRICES AFTER WEIGHT AVERAGING (WORK.USPRICES)                   = %CMPRES(&COUNT_USPRICES);
        %PUT ************************************************************************************;
        %PUT ************************************************************************************;
    %END;
%MEND C_MAC3_READLOG;

/*---------------------------------------*/
/* PART 4: CALL LOG SCAN MACRO ON DEMAND */
/*---------------------------------------*/

%MACRO CMAC4_SCAN_LOG (ME_OR_NME =);
    %IF %UPCASE(&LOG_SUMMARY) = YES %THEN
    %DO;
        PROC PRINTTO LOG = LOG;
        RUN;

        OPTIONS NOSYMBOLGEN NOMLOGIC NOMPRINT;   
        %C_MAC3_READLOG (LOG = &LOG., ME_OR_NME = &ME_OR_NME.);
        OPTIONS SYMBOLGEN NOMLOGIC MPRINT;
    %END;
%MEND CMAC4_SCAN_LOG;

/*-------------------------------------------------------------------------*/
/* PART 5: SELECTIVELY ADJUST SALE DATE BASED ON AN EARLIER DATE VARIABLE. */
/*-------------------------------------------------------------------------*/

%MACRO DEFINE_SALE_DATE (SALEDATE =, DATEBEFORESALE =, EARLIERDATE =);
    %IF &DATEBEFORESALE = YES %THEN
    %DO;
        &EARLIERDATE = FLOOR(&EARLIERDATE); /* Eliminates the time part of sale date */
                                            /* when defined as a datetime variable.  */
        IF &EARLIERDATE < &SALEDATE THEN
            &SALEDATE = &EARLIERDATE;
    %END;
%MEND DEFINE_SALE_DATE;

/*-----------------------------------------------------------------------------------*/
/* PART 6: CALCULATE IMPORTER-SPECIFIC DE MINIMIS TEST RESULTS AND ASSESSMENT RATES. */
/*-----------------------------------------------------------------------------------*/

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

	DATA ASSESS_&INDATA;
        SET ASSESS_&INDATA;
		IF PERUNIT NE . THEN
			&INDATA.RATE = CATX(' ', ROUND(PERUNIT,.01), '($/Unit)');
		ELSE
        IF PERUNIT = . THEN
			&INDATA.RATE = CATX(' ', ROUND(ASESRATE,.01), '(%)');
		ELSE
        IF PERUNIT = 0 THEN
			&INDATA.RATE = CATX(' ',0,'(%)');
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

/*---------------------------------------------*/
/* PART 7: PRINT SUMMARY OF CASH DEPOSIT RATES */
/*---------------------------------------------*/

%MACRO US19_FINAL_CASH_DEPOSIT;
    %IF %UPCASE(&PER_UNIT_RATE) = NO %THEN
    %DO; 
        %LET PREFIX = WTAVGPCT;
        %LET LABEL_STND = "WEIGHTED AVERAGE*MARGIN RATE*STANDARD *METHOD*================";
        %LET LABEL_MIXED = "WEIGHTED AVERAGE*MARGIN RATE*MIXED ALTERNATIVE*METHOD*=================";
        %LET LABEL_ALT = "WEIGHTED AVERAGE*MARGIN RATE*A-to-T ALTERNATIVE*METHOD*==================";
        %LET CDFORMAT = PCT_MARGIN.;
    %END;
    %ELSE
    %IF %UPCASE(&PER_UNIT_RATE) = YES %THEN
    %DO;
        %LET PREFIX = PER_UNIT_RATE;
        %LET LABEL_STND = "*WEIGHTED AVERAGE*MARGIN RATE*STANDARD METHOD*===============";
        %LET LABEL_MIXED = "*WEIGHTED AVERAGE*MARGIN RATE*MIXED ALTERNATIVE*METHOD*=================";
        %LET LABEL_ALT = "*WEIGHTED AVERAGE*RATE*A-to-T ALTERNATIVE*METHOD*==================";
        %LET CDFORMAT = UNIT_MARGIN.;
    %END;

    %IF %UPCASE(&ABOVE_DEMINIMIS_ALT) = YES %THEN 
    %DO;
        %IF %UPCASE(&CASE_TYPE) = AR %THEN 
        %DO;
            DATA IMPANSWER; 
    	        LENGTH US_IMPORTER $ 32;

		  %IF %UPCASE(&ABOVE_DEMINIMIS_MIXED) = YES %THEN
		  %DO;
    	        MERGE 

				%IF %UPCASE(&ABOVE_DEMINIMIS_STND) = YES %THEN
				%DO;
                        ASSESS_IMPSTND (RENAME = (IMPSTNDRATE = &PREFIX._STND))
                %END;
		                ASSESS_MIXED (RENAME = (MIXEDRATE = &PREFIX._MIXED))
	 	  %END;

	      %IF %UPCASE(&ABOVE_DEMINIMIS_MIXED) = NA %THEN
	      %DO;	
			   MERGE 

		   %IF %UPCASE(&ABOVE_DEMINIMIS_STND) = YES %THEN
			%DO;
                     ASSESS_IMPSTND (RENAME = (IMPSTNDRATE = &PREFIX._STND))
		   %END;
	  %END;
		  	

		  %IF %UPCASE(&ABOVE_DEMINIMIS_MIXED)  = NO %THEN 
		  %DO;
                SET
		  %END;
                    ASSESS_IMPTRAN (RENAME = (IMPTRANRATE = &PREFIX._ALT));

		  %IF %UPCASE(&ABOVE_DEMINIMIS_MIXED) = YES %THEN
          %DO;
	            BY US_IMPORTER;
		  %END;

            RUN;

            DATA IMPANSWER;
	            SET IMPANSWER (RENAME = (US_IMPORTER = CLASSIFICATION)
	        		           KEEP = US_IMPORTER &PREFIX._ALT 

	        	%IF %UPCASE(&ABOVE_DEMINIMIS_STND) = YES %THEN
	        	%DO;
	        	    &PREFIX._STND
	        	%END;

	        	%IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
	        	%DO;
                    &PREFIX._MIXED
		        %END;
                              );
                %IF %UPCASE(&ABOVE_DEMINIMIS_STND) = NO %THEN
                %DO;
                    &PREFIX._STND = '0 (%)';
                %END;
        
                %IF %UPCASE(&ABOVE_DEMINIMIS_MIXED) = NO  %THEN
                %DO;
                    &PREFIX._MIXED = '0 (%)';
                %END;

    			%IF %UPCASE(&ABOVE_DEMINIMIS_MIXED) = NA  %THEN
                %DO;
                    &PREFIX._MIXED = 'NA';
                %END;
            RUN;
        %END;
    %END;

    DATA ANSWER;
    	SET ANSWER;
    	LENGTH CLASSIFICATION $ 32;
    	CLASSIFICATION = 'Cash Deposit Rates';

    	%IF %UPCASE(&PER_UNIT_RATE) = NO %THEN 
    	%DO;
    		STNDCDRATE = CATX(' ', ROUND(&PREFIX._STND, .01), '(%)');
    		IF &PREFIX._MIXED NE . THEN
            DO;
    			MIXEDCDRATE = CATX(' ', ROUND(&PREFIX._MIXED, .01), '(%)');
    		END;
    		ALTCDRATE = CATX(' ', ROUND(&PREFIX._ALT, .01), '(%)');
    	%END;
    	%IF %UPCASE(&PER_UNIT_RATE) = YES %THEN 
    	%DO;
    		STNDCDRATE = CATX(' ', ROUND(&PREFIX._STND, .01), '($/Unit)');
    		IF &PREFIX._MIXED NE . THEN
            DO;
    				MIXEDCDRATE = CATX(' ', ROUND(&PREFIX._MIXED, .01), '($/Unit)');
	    	END;
			ALTCDRATE = CATX(' ', ROUND(&PREFIX._ALT, .01), '($/Unit)');
    	%END;

        CALL SYMPUT("CDALTRATE", PUT(&PREFIX._ALT, 8.2));
	RUN;
	
    DATA ANSWER;
    	SET ANSWER (KEEP = CLASSIFICATION STNDCDRATE MIXEDCDRATE ALTCDRATE);
    	RENAME STNDCDRATE = &PREFIX._STND MIXEDCDRATE = &PREFIX._MIXED ALTCDRATE = &PREFIX._ALT;
    RUN;

    %IF %UPCASE(&CASE_TYPE) = AR AND %UPCASE(&ABOVE_DEMINIMIS_ALT) = YES %THEN 
    %DO;	
        DATA ANSWER;
        	SET ANSWER IMPANSWER;
        RUN;
    %END;

    DATA ANSWER;
        SET ANSWER NOBS = ANSWERCOUNT;
	    CALL SYMPUT("ANSWEROBSCOUNT", ANSWERCOUNT);
    RUN;

    %IF %CMPRES(&PERCENT_VALUE_PASSING) = 0.00% OR %CMPRES(&PERCENT_VALUE_PASSING) = 100.00% %THEN 
    %DO;
        DATA ANSWER;
		    SET ANSWER;
		    &PREFIX._MIXED = 'N/A';
	    RUN;
    %END;

    %IF %UPCASE(&CASE_TYPE) = AR AND &ANSWEROBSCOUNT > 1 %THEN 
	%DO;
		%LET LABEL_CLASS = "CASH DEPOSIT RATES (Row 1)*AND IMPORTER-SPECIFIC*DUTY ASSESSMENT RATES*(Rows 2 and below)";
	%END;
	%ELSE
    %DO;
		%LET LABEL_CLASS = '00'x;
	%END;

    PROC PRINT DATA = ANSWER NOOBS SPLIT = '*';
        TITLE3 "SUMMARY OF CASH DEPOSIT RATES";

        %IF %UPCASE(&CASE_TYPE) = AR AND &ANSWEROBSCOUNT > 1 %THEN 
        %DO;
            TITLE4 "AND IMPORTER-SPECIFIC ASSESSMENT RATES";
        %END;

        TITLE6 "PERCENT OF SALES PASSING THE COHEN'S D TEST: %CMPRES(&PERCENT_VALUE_PASSING)";   
        TITLE7 "IS THERE A MEANINGFUL DIFFERENCE BETWEEN THE STANDARD METHOD AND THE MIXED-ALTERNATIVE METHOD: %CMPRES(&MA_METHOD)";
        TITLE8 "IS THERE A MEANINGFUL DIFFERENCE BETWEEN THE STANDARD METHOD AND THE A-to-T ALTERNATIVE METHOD: %CMPRES(&AT_METHOD)";
        TITLE9 " ";
        VAR CLASSIFICATION &PREFIX._STND &PREFIX._MIXED &PREFIX._ALT;
        LABEL &PREFIX._STND = &LABEL_STND
              &PREFIX._MIXED = &LABEL_MIXED
              &PREFIX._ALT = &LABEL_ALT
    		  CLASSIFICATION = &LABEL_CLASS;
        FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
        FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";
    RUN;
%MEND US19_FINAL_CASH_DEPOSIT;