/***********************************************************************/
/*                    COMMON UTILITY MACROS PROGRAM                    */
/*                     FOR USE FOR BOTH ME AND NME                     */
/*                                                                     */
/*                  LAST PROGRAM UPDATE AUGUST 30, 2017                */
/*                                                                     */
/* PART 1: MACRO TO WRITE LOG TO A PERMANENT FILE                      */ 
/* PART 2: MACRO TO GET COUNTS OF THE DATASETS                         */ 
/* PART 3: REVIEW AND REPORT GENERAL SAS LOG ALERTS SUCH AS ERRORS,    */
/*         WARNINGS, UNINITIALIZED VARIABLES ETC. AND PROGRAM SPECIFIC */
/*         ALERTS WE NEED TO WATCH FOR                                 */
/* PART 4: CALL LOG SCAN MACRO ON DEMAND                               */ 
/* PART 5: IN TIME-SPECIFIC CASES, IDENTIFY CONNUM/TIME PERIODS WITH   */
/*         NO CORRESPONDING COP CONNUM/TIME PERIODS                    */
/***********************************************************************/

DATA _NULL_;
	CALL SYMPUT('BDAY', UPCASE(STRIP(PUT(DATE(), DOWNAME.))));
	CALL SYMPUT('BWDATE', UPCASE(STRIP(PUT(DATE(), WORDDATE18.))));
	CALL SYMPUT('BTIME', UPCASE(STRIP(PUT(TIME(), TIMEAMPM8.))));
	CALL SYMPUT('BDATETIME', (STRIP(PUT(DATETIME(), 20.))));
RUN;

%PUT NOTE: THIS PROGRAM WAS RUN ON &BDAY, &BWDATE, AT &BTIME..;

/*--------------------------------------------------------------------*/
/* PART 1: WRITE LOG TO THE PROGRAM LOCATION                          */
/*--------------------------------------------------------------------*/

%MACRO CMAC1_WRITE_LOG;
	%IF &LOG_SUMMARY = YES %THEN %DO;

		FILENAME LOGFILE "&LOG.";

		PROC PRINTTO LOG=LOGFILE NEW;
		RUN;

	%END;
%MEND CMAC1_WRITE_LOG;


/*--------------------------------------------------------------------*/
/* PART 2: MACRO TO GET COUNTS OF THE DATASETS                        */
/*     THAT NEED BE TO REVIEWED                                       */
/*--------------------------------------------------------------------*/

%MACRO CMAC2_COUNTER (DATASET =, MVAR=);

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

        IF UPCASE(COMPRESS(SUBSTR(LINE,1,6))) = "ERROR:" THEN
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
        /* CREATE MACRO VARAIBLES FOR REPORTING LATER */
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
        %CMAC2_COUNTER (DATASET = NEGDATA_HM, MVAR=NEGDATA_HM);
        %CMAC2_COUNTER (DATASET = OUTDATES_HM, MVAR=OUTDATES_HM);
        %CMAC2_COUNTER (DATASET = NOCOST, MVAR=NOCOST);
        %IF &RUN_ARMSLENGTH. = YES %THEN
        %DO;
            %CMAC2_COUNTER (DATASET = HMAFFOUT, MVAR=HMAFFOUT);        
        %END;  
        %CMAC2_COUNTER (DATASET = HMBELOW, MVAR=HMBELOW); 
		%CMAC2_COUNTER (DATASET = HMABOVE, MVAR=HMABOVE); 
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "MEMARG" %THEN
    %DO;
        %CMAC2_COUNTER (DATASET = NEGDATA_US, MVAR=NEGDATA_US);
        %CMAC2_COUNTER (DATASET = OUTDATES_US, MVAR=OUTDATES_US);
        %CMAC2_COUNTER (DATASET = NOCOST, MVAR=NOCOST);
        %CMAC2_COUNTER (DATASET = NORATES, MVAR=NORATES);
        %CMAC2_COUNTER (DATASET = NO_DP_REGION_TEST, MVAR=NO_DP_REGION_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PURCHASER_TEST, MVAR=NO_DP_PURCHASER_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PERIOD_TEST, MVAR=NO_DP_PERIOD_TEST);
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "NME" %THEN
    %DO;
        %CMAC2_COUNTER (DATASET = NEGDATA, MVAR=NEGDATA);
        %CMAC2_COUNTER (DATASET = OUTDATES, MVAR=OUTDATES);
        %CMAC2_COUNTER (DATASET = NOFOP, MVAR=NOFOP);
        %CMAC2_COUNTER (DATASET = NOEXRATE, MVAR=NOEXRATE);
        %CMAC2_COUNTER (DATASET = NEGATIVE_NVALUES, MVAR=NEGATIVE_NVALUES);
        %CMAC2_COUNTER (DATASET = NEGATIVE_USPRICES, MVAR=NEGATIVE_USPRICES);
        %CMAC2_COUNTER (DATASET = NO_DP_REGION_TEST, MVAR=NO_DP_REGION_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PERIOD_TEST, MVAR=NO_DP_PERIOD_TEST);
        %CMAC2_COUNTER (DATASET = NO_DP_PURCHASER_TEST, MVAR=NO_DP_PURCHASER_TEST);
    %END;

    /*---------------------------------------------------------------------*/ 
    /*  PRINTING SUMMARY OF GENERAL SAS ALERTS AS WELL AS PROGRAM SPECIFIC */
    /*  ALERTS SUMMARY TO THE JOB LOG                                      */
    /*---------------------------------------------------------------------*/

    %PUT ******************************************************************************;
    %PUT ******************************************************************************;
    %PUT * GENERAL SAS ALERTS:                                                        *;
    %PUT ******************************************************************************;
    %PUT *   NORMALLY, BELOW ALERTS SHOULD BE ZERO                                    *;
    %PUT *   IF THEY DO NOT HAVE ZERO INSTANCES DETERMINE IF THERE IS AN ISSUE.       *;
    %PUT ******************************************************************************;
    %PUT # OF ERRORS                       = &ERROR;
    %PUT # OF WARNINGS                     = &WARNING;
    %PUT # OF UNINITIALIZED VARIABLES      = &UNINIT;
	%PUT # OF MISSING VALUES               = &MISSING;
    %PUT # OF REPEATS OF BY VALUES         = &REPEAT;
    %PUT # OF CONVERTED VARIABLES          = &CONVERTED;
    %PUT # OF DIVISION BY ZERO DETECTED    = &DIVISION;
	%PUT # OF INVALID DATA VALUES          = &INVALID;
	%PUT # OF LICENSE WARNINGS             = &LICENSE;
    %PUT ******************************************************************************;
    %PUT ;
    %PUT ******************************************************************************;
    %PUT * PROGRAM SPECIFIC ALERTS TO VERIFY:                                         *;
    %PUT ******************************************************************************;
    %PUT *   NORMALLY, COUNTS FOR THE BELOW LISTED DATATSETS HAVE ZERO OBSERVATIONS.  *;
    %PUT *   IF THEY DO NOT HAVE ZERO RECORDS DETERMINE IF THERE IS AN ISSUE.         *;
    %PUT ******************************************************************************;

    %IF %UPCASE("&ME_OR_NME.") = "MEHOME" %THEN
    %DO;  
	    %PUT # OF TOTAL HM SALES GOING IN (HMSALES)                              = %CMPRES(&COUNT_ORIG_HMSALES);
        %PUT # OF HM SALES WITH PRICES AND/OR QTY <=0 (NEGDATA_HM)               = %CMPRES(&COUNT_NEGDATA_HM);
        %PUT # OF HM SALES OUTSIDE DATE RANGE (OUTDATES_HM)                      = %CMPRES(&COUNT_OUTDATES_HM);
        %IF &RUN_ARMSLENGTH. = YES %THEN
        %DO;
            %PUT # OF HM SALES FAILING ARMS LENGTH TEST (HMAFFOUT)                   = %CMPRES(&COUNT_HMAFFOUT);
        %END; 
        %PUT # OF HM SALES WITH NO COST DATA (NOCOST)                            = %CMPRES(&COUNT_NOCOST);
        %PUT # OF HM SALES FAILING THE COST TEST (HMBELOW)                       = %CMPRES(&COUNT_HMBELOW);  
		%PUT # OF HM SALES ABOVE COST TEST (HMABOVE)                             = %CMPRES(&COUNT_HMABOVE);
        %PUT ******************************************************************************;
        %PUT ******************************************************************************;
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "MEMARG" %THEN
    %DO;
	    %PUT # OF TOTAL US SALES (USSALES)                                      = %CMPRES(&COUNT_ORIG_USSALES);
        %PUT # OF US SALES WITH PRICES AND/OR QTY <=0 (NEGDATA_US)              = %CMPRES(&COUNT_NEGDATA_US);
        %PUT # OF US SALES OUTSIDE DATE RANGE (OUTDATES_US)                     = %CMPRES(&COUNT_OUTDATES_US);
        %PUT # OF US SALES WITH NO COST DATA (NOCOST)                           = %CMPRES(&COUNT_NOCOST);
        %PUT # OF US SALES WITH NO EXCHANGE RATES (NORATES)                     = %CMPRES(&COUNT_NORATES);
        %PUT # OF US SALES WITH INVALID REGIONAL VALUES (NO_DP_REGION_TEST)     = %CMPRES(&COUNT_NO_DP_REGION_TEST);
        %PUT # OF US SALES WITH INVALID PURCHASER VALUES (NO_DP_PURCHASER_TEST) = %CMPRES(&COUNT_NO_DP_PURCHASER_TEST);
        %PUT # OF US SALES WITH INVALID TIME VALUES (NO_DP_PERIOD_TEST)         = %CMPRES(&COUNT_NO_DP_PERIOD_TEST);
		%PUT # OF US SALES USED IN WEIGHT AVERAGING                             = %CMPRES(&COUNT_WT_AVG_USSALES);
        %PUT *******************************************************************************;
        %PUT *******************************************************************************;
    %END;
    %ELSE
    %IF %UPCASE("&ME_OR_NME.") = "NME" %THEN
    %DO;
		%PUT # OF US SALES GOING IN(USSALES)                                    = %CMPRES(&COUNT_ORIG_USSALES);
		%PUT # OF US SALES WITH PRICES AND/OR QTY <=0 (NEGDATA)                 = %CMPRES(&COUNT_NEGDATA);
        %PUT # OF US SALES OUTSIDE DATE RANGE (OUTDATES)                        = %CMPRES(&COUNT_OUTDATES);
        %PUT # OF US SALES WITH NO MATCHING FACTORS OF PRODUCTION (NOFOP)       = %CMPRES(&COUNT_NOFOP);
        %PUT # OF US SALES WITH NO EXCHANGE RATES (NOEXRATE)                    = %CMPRES(&COUNT_NOEXRATE);
        %PUT # OF US SALES WITH NEGATIVE NORMAL VALUES (NEGATIVE_NVALUES)       = %CMPRES(&COUNT_NEGATIVE_NVALUES);
        %PUT # OF US SALES WITH NEGATIVE NET US PRICES (NEGATIVE_USPRICES)      = %CMPRES(&COUNT_NEGATIVE_USPRICES);
        %PUT # OF US SALES WITH INVALID REGIONAL VALUES (NO_DP_REGION_TEST)     = %CMPRES(&COUNT_NO_DP_REGION_TEST);
        %PUT # OF US SALES WITH INVALID PURCHASER VALUES (NO_DP_PURCHASER_TEST) = %CMPRES(&COUNT_NO_DP_PURCHASER_TEST);
        %PUT # OF US SALES WITH INVALID TIME VALUES (NO_DP_PERIOD_TEST)         = %CMPRES(&COUNT_NO_DP_PERIOD_TEST);
		%PUT # OF US SALES GOING IN(USSALES)                                    = %CMPRES(&COUNT_ORIG_USSALES);
        %PUT *******************************************************************************;
        %PUT *******************************************************************************;
    %END;
%MEND C_MAC3_READLOG;

/*--------------------------------------------------------------------*/
/* PART 4: CALL LOG SCAN MACRO ON DEMAND
/*--------------------------------------------------------------------*/
%MACRO CMAC4_SCAN_LOG (ME_OR_NME =);
  	%IF &LOG_SUMMARY = YES %THEN %DO;

		PROC PRINTTO LOG = LOG;
		RUN;

		OPTIONS NOSYMBOLGEN NOMLOGIC MPRINT;
		%C_MAC3_READLOG (LOG = &LOG., ME_OR_NME = &ME_OR_NME.);
		OPTIONS SYMBOLGEN MLOGIC MPRINT;
  	%END;
%MEND CMAC4_SCAN_LOG;

/*--------------------------------------------------------------------------*/
/* PART 5: IN TIME-SPECIFIC COST CASES, IDENTIFY CONNUM/TIME PERIODS WITH   */
/*         NO CORRESPONDING COP CONNUM/TIME PERIODS. STOP THE PROGRAM IF    */
/*         MISSING CONNUM/TIME PERIODS ARE FOUND AND ISSUE AN ERROR MESSAGE */
/*         ASKING THE ANALYST TO CONTACT THE SAS SUPPORT TEAM FOR HELP.     */
/*--------------------------------------------------------------------------*/

%GLOBAL HM_MISS_LIST US_MISS_LIST;
 
%MACRO G18_FIND_MISSING_TIME_PERIODS(PROGRAM);
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        /*---------------------------------------------------------------*/
        /* Create a unique list of Cost CONNUM/time period combinations. */
        /*---------------------------------------------------------------*/

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._COST
                         (KEEP = &COST_MATCH &COST_TIME_PERIOD)
                  OUT = COST_CONNUM_QTR_LIST NODUPKEY;
            BY &COST_MATCH &COST_TIME_PERIOD;
        RUN;
 
        %MACRO CHECK_FOR_MISSING(TYPE, DATASET, CONNUM, TIME_PERIOD);
            /*----------------------------------------------------------*/
            /* Create a unique list of CONNUM/time period combinations. */
            /*----------------------------------------------------------*/

            PROC SORT DATA = &DATASET (KEEP = &&&TYPE.CONNUM &&&TIME_PERIOD)
                      OUT = &DATASET._CONNUM_QTR_LIST
                            (RENAME = (&CONNUM = &COST_MATCH
                                       &&&TIME_PERIOD = &COST_TIME_PERIOD))
                            NODUPKEY;
                BY &CONNUM &&&TIME_PERIOD;
            RUN;

            /*----------------------------------------------------*/
            /* Identify CONNUM/time periodS with no corresponding */
            /* COP CONNUM/time periods.                           */
            /*----------------------------------------------------*/

            DATA MISSING_&TYPE._COST_LIST;
                MERGE &DATASET._CONNUM_QTR_LIST (IN = SL)
                      COST_CONNUM_QTR_LIST (IN = CT);
                BY &COST_MATCH &COST_TIME_PERIOD;
                IF SL AND NOT CT THEN
                    OUTPUT;
            RUN;

            PROC PRINT DATA = MISSING_&TYPE._COST_LIST;
                TITLE3 "&TYPE CONNUM/TIME PERIODS WITHOUT COP CONNUM/TIME PERIODS";
            RUN;

            DATA _NULL_;
                IF 0 THEN
                    SET MISSING_&TYPE._COST_LIST NOBS = N;
                CALL SYMPUTX("&TYPE._MISS_LIST", N);
                STOP;
            RUN;
        %MEND CHECK_FOR_MISSING;

        %IF &PROGRAM = HM %THEN
        %DO;
            %CHECK_FOR_MISSING(HM, HMSALES, &HMCONNUM, HM_TIME_PERIOD)
        %END;

        %CHECK_FOR_MISSING(US, US_INDEX_CHECK, &USCONNUM, US_TIME_PERIOD)

        %MACRO COST_ERROR_CHECK (DATASET, DATASET_OBS);
            %IF &&&DATASET_OBS %THEN
            %DO;
                OPTIONS OBS = 0;
                %PUT ERROR: RESPONDENTS DID NOT REPORT TIME SPECIFIC COST FOR ALL &DATASET SALES.;
                %PUT ERROR: PLEASE CONTACT THE SAS SUPPORT TEAM TO ADD INDEXING LANGUAGE TO THE PROGRAM.;
            %END;
        %MEND COST_ERROR_CHECK;

        %IF &PROGRAM = HM %THEN
        %DO;
           %COST_ERROR_CHECK(HM, HM_MISS_LIST)
        %END;

        %COST_ERROR_CHECK(U.S., US_MISS_LIST)
    %END;
%MEND G18_FIND_MISSING_TIME_PERIODS;
