/*--------------------------------------------------------------*/
/*                                                              */
/*              NME MARGIN CALCULATION PROGRAM                  */
/*                                                              */
/*          GENERIC VERSION LAST UPDATED - AUGUST 30, 2017      */
/*                                                              */
/* PART 1:  IDENTIFY DATA, VARIABLES, AND PARAMETERS            */
/* PART 2:  GET U.S., FOP, AND SV DATA                          */
/* PART 3:  KEEP U.S. SALES INSIDE THE COURSE OF ORDINARY       */
/*          TRADE                                               */
/* PART 4:  ADD SURROGATE VALUES TO U.S. SALES                  */
/* PART 5:  MATCH U.S. SALES AND SV DATA TO FOP DATA            */
/* PART 6:  CONVERT VARIABLES INTO U.S. DOLLARS AND REVISE      */
/*          THE VARIABLE NAMES TO INCLUDE THE SUFFIX _USD       */
/*          (USING DOC EXCHANGE RATES)                          */
/* PART 7:  CALCULATE INPUTS                                    */
/* PART 8:  CALCULATE NORMAL VALUES                             */
/* PART 9A: CALCULATE NET U.S. PRICE FOR EP SALES               */
/* PART 9B: CALCULATE NET U.S. PRICE FOR CEP SALES              */
/* PART 10: CBP ENTERED VALUE BY IMPORTER                       */
/* PART 11: COHEN'S-D TEST                                      */
/* PART 12: WEIGHT AVERAGE U.S. SALES                           */
/* PART 13: COMPARISON RESULTS                                  */
/* PART 14: CORROBORATE THE PETITION RATE                       */
/* PART 15: PRINT SAMPLES OF HIGHEST AND LOWEST COMPARISON      */
/*          RESULTS                                             */
/* PART 16: CASH DEPOSIT RATES                                  */
/* PART 17: MEANINGFUL DIFFERENCE TEST                          */
/* PART 18: IMPORTER-SPECIFIC DUTY ASSESSMENT RATES             */
/*          (REVIEWS ONLY)                                      */
/* PART 19: REPRINT THE FINAL CASH DEPOSIT RATE                 */
/* PART 20: REVIEW LOG FOR ERRORS, WARNINGS, UNINIT., ETC.      */
/*--------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/*    EDITING THE PROGRAM:                                                 */
/*                                                                         */
/*          Places requiring edits are indicated by angle brackets         */
/*          (i.e., '< >'). Replace angle brackets with case-specific       */
/*          information.                                                   */
/*                                                                         */
/*          Types of Inputs:(D) = SAS dataset name                         */
/*                          (E) = Equation                                 */
/*                          (V) = Variable name                            */
/*                          (T) = Text (no specific format),               */
/*                                do NOT use punctuation marks             */
/*-------------------------------------------------------------------------*/

/*--------------------------------------------------------------*/
/* EXECUTING/RUNNING THE PROGRAM:                               */
/*                                                              */
/* In addition to executing the entire program, you can do      */
/* partial runs.  Executable points from which you can          */
/* partially run the program are indicated by /*ep* on          */
/* the left margin.  To do a partial run, just highlight the    */
/* program from one of the executable points to the top,        */
/* then submit it.                                              */
/*--------------------------------------------------------------*/

/*--------------------------------------------------------------*/
/* LOCATION OF DATA AND MACROS PROGRAM                          */
/*                                                              */
/* LIBNAME  = The name (i.e., COMPANY) and location of the      */
/*            sub-directory containing the SAS datasets for     */
/*            this program.                                     */
/*            EXAMPLE: E:\Operations\India\CORE\INV             */
/*                                                              */
/* FILENAME = Full path of the Macro Program for this case,     */
/*            consisting of the sub-directory containing the    */
/*            Macro Program and its file name.                  */
/*--------------------------------------------------------------*/

LIBNAME COMPANY '<E:\....>';                   /* (T) Location of company and  */
                                               /* exchange rate data sets.     */
FILENAME C_MACS '<E:\...\Common Macros.sas>';  /* (T) Location & Name of the   */
                                               /* Common Macros Program        */
%INCLUDE C_MACS;                               /* Use the Common Macros        */
                                               /* Program.                     */
%LET LOG_SUMMARY = YES;                        /* Default value is "YES" (no    */
                                               /* quotes). Use "NO" (no quotes) */
                                               /* to run program in parts for   */
                                               /* troubleshooting.              */

/*--------------------------------------------*/
/* GET PROGRAM PATH/NAME AND CREATE THE SAME  */
/* NAME FOR THE LOG FILE WITH .LOG EXTENSION. */
/*--------------------------------------------*/
%GLOBAL MNAME LOG;
%LET MNAME = %SYSFUNC(SCAN(%SYSFUNC(pathname(C_MACS)), 1, '.'));
%LET LOG = %SYSFUNC(substr(&MNAME, 1, %SYSFUNC(length(&MNAME)) - %SYSFUNC(indexc(%SYSFUNC(
           reverse(%SYSFUNC(trim(&MNAME)))), '\'))))%STR(\)%SYSFUNC(DEQUOTE(&_CLIENTTASKLABEL.))%STR(.log);  

%CMAC1_WRITE_LOG;

/*--------------------------------------------------*/
/* PART 1: IDENTIFY DATA, VARIABLES, AND PARAMETERS */
/*--------------------------------------------------*/

/* TYPE IN EITHER THE WORD 'AR' (NOT 1ST REVIEW) */
/* OR THE WORD 'INV'. DO NOT TYPE THE QUOTES.    */

%LET CASE_TYPE = <INV/AR>;     /* (T) For an investigation, type 'INV' (without quotes)        */
                               /*     For an administrative review, type 'AR' (without quotes) */

/*--------------------------------------------------------------*/
/* TYPE IN THE NAMES OF THE U.S. AND FOP DATASETS. THIS PROGRAM */
/* ASSUMES THAT BOTH SOURCES OF DATA ARE ALREADY STORED AS SAS  */
/* DATSETS. IF THEY ARE NOT, CONVERT THEM TO SAS DATASETS       */
/* BEFORE RUNNING THIS PROGRAM. DO NOT USE THE FILE NAME        */
/* EXTENSION. (EX. USSALES, *NOT* USSALES.SAS7BDAT.)            */
/*--------------------------------------------------------------*/

%LET USDATA  = <        >; /* (D) NAME OF U.S. DATASET */
%LET FOPDATA = <        >; /* (D) NAME OF FOP DATASET  */

/*------------------------------------------------------------*/
/* THE FOLLOWING FOUR MACRO VARIABLES ARE USED TO CONVERT THE */
/* SURROGATE VALUE DATA, STORED AS A SPREADSHEET, INTO A SAS  */
/* DATASET. USE THE SV COMPANY SPECIFIC SUMMARY SHEET.        */
/*                                                            */
/* NOTE: VARIABLE NAMES USED IN SPREAD SHEETS NEED TO FOLLOW  */
/* THE NAMING CONVENTIONS OF SAS VARIABLE NAMES. VARIABLES    */
/* CAN BE MADE UP OF LETTERS, NUMBERS, AND THE UNDERSCORE     */
/* CHARACTER "_" AND CAN BE UP TO 32 CHARACTERS LONG. A SAS   */
/* NAME CANNOT START WITH A NUMBER.                           */
/*------------------------------------------------------------*/

/*-----------------------------------------------------------------*/
/* THE MACRO VARIABLE 'SV_PATH' IS USED TO IDENTIFY THE LOCATION   */
/* AND NAME OF THE OF THE SURROGATE VALUE DATASET.                 */
/*                                                                 */
/* EX. ON THE LAN:                                                 */
/*   E:\Operations\Peoples Republic Of China\HEDP\2015 INV\SV.xls  */
/*-----------------------------------------------------------------*/

%LET SV_PATH        = <       >; /* (T) WINDOWS EXPLORER LOCATION AND FILE     */
                                 /*     NAME (INCLUDING THE FILE EXTENSION).   */
%LET SV_NAME_RANGE  = <       >; /* (T) WORKSHEET NAME AND COLUMN RANGE        */
                                 /*     SEPARATED BY DOLLAR SIGN ($).          */
                                 /*     COLUMN RANGE REPRESENTS SURROGATE      */
                                 /*     VALUE VARIABLE NAMES. USE THE SYNTAX:  */
                                 /*     NAMEOFTHESHEET$COLUMNRANGE.            */
                                 /*     EXAMPLE: SummaryofSVs$O6:O34           */
%LET SV_VALUE_RANGE = <       >; /* (T) WORKSHEET NAME AND COLUMN RANGE        */
                                 /*     SEPARATED BY DOLLAR SIGN ($).          */
                                 /*     COLUMN RANGE REPRESENTS SURROGATE      */
                                 /*     VALUE VARIABLE VALUES. USE THE SYNTAX: */
                                 /*     NAMEOFTHESHEET$COLUMNRANGE.            */
                                 /*     EXAMPLE: SummaryofSVs$P6:P34           */

/*------------------------------------------------------------------*/
/* DATE INFORMATION                                                 */
/*                                                                  */
/*        Dates should be in SAS DATE9 format (e.g., 01JAN2010).    */
/*                                                                  */
/*        In addition to filtering U.S. sales using date of sale    */
/*        variable and keeping only those sales between the dates   */
/*        specified by BEGINDAY and ENDDAY, you can                 */
/*        also filter CEP  and EP sales separately, using different */
/*        dates and date variables.                                 */
/*------------------------------------------------------------------*/

/*----------------------------------------------------------------*/
/* CAPTURING THE FULL UNIVERSE OF U.S. SALES                      */
/*                                                                */
/*    The date of sale variable designated below as USDATE        */
/*    will be used to capture only U.S. sales between             */
/*    the dates specified by BEGINDAY and ENDAY immediately       */
/*    following.                                                  */
/*                                                                */
/*    BEGINPERIOD    is the beginning of the official POI/POR,    */
/*    regardless of when the earliest sales begin (see BEGINDAY). */
/*    It is used for titling and to calculate the quarters for    */
/*    the Differential Pricing analysis.                          */
/*                                                                */
/*    ENDPERIOD is the end of the official POI/POR, regardless    */
/*    of when the last sales occur (see ENDDAY).                  */
/*    It is used for titling.                                     */
/*                                                                */
/*  FOR INVESTIGATIONS: The universe of U.S. sales usually        */
/*    consists of sales during the POI for both EP and CEP sales. */
/*    When this is the case, set BEGINDAY to the first day of the */
/*    the POI, and ENDDAY to the last day of the POI.             */
/*                                                                */
/*  FOR REVIEWS: Reported CEP sales usually include all sales     */
/*    during the POR.  For EP    sales, they usually include all  */
/*  entries during the POR.  Accordingly, there may be EP         */
/*  transactions with sale dates prior to the POR.  Adjust        */
/*    the BEGINDAY and ENDDAY to capture the first and last       */
/*    U.S. sales.                                                 */
/*----------------------------------------------------------------*/

%LET USDATE = <        >;        /* (V) Variable representing the sale date.      */

%LET BEGINDAY = <DDMONYYYY>;     /* (T) Day 1 of first month of U.S. sales.       */
%LET ENDDAY   = <DDMONYYYY>;     /* (T) Last day of last month of U.S. sales.     */

%LET BEGINPERIOD = <DDMONYYYY>;  /* (T) Day 1 of first month of official POI/POR. */
%LET ENDPERIOD   = <DDMONYYYY>;  /* (T) Last day last month of official POI/POR.  */
    
/*----------------------------------------------------------------*/
/* ADDITIONAL FILTERING OF U.S. SALES, IF REQUIRED                */
/*                                                                */
/*  Should you additionally wish to filter U.S. sales using       */
/*    different dates and/or date variables for CEP v EP sales,   */
/*    complete the following section.    This may be useful when  */
/*    you have both EP and CEP sales in an administrative review. */
/*    In reviews, reported CEP sales usually include all sales    */
/*  during the POR.  For EP sales in reviews, reported sales      */
/*    usually include all entries during the POR.  To filter EP   */
/*    sales by entry date, for example, you would put the first   */
/*    and last days of the POR for BEGINDAY_EP and ENDDAY_EP, and */
/*    the variable for date of entry under EP_DATE_VAR.           */
/*----------------------------------------------------------------*/

%LET FILTER_CEP = <YES/NO>;             /* (T) Additionally filter CEP sales?  Type "YES" (no quotes) to filter,  */
                                        /*     "NO" to skip this part. If you typed "YES," then also complete     */
                                        /*     the three subsequent indented macro variables re: CEP.             */
    %LET CEP_DATE_VAR = <        >;     /* (V) The date variable to be used to filter CEP sales.                  */
    %LET BEGINDAY_CEP = <DDMONYYYY>;    /* (T) Day 1 of 1st month of CEP U.S. sales to be kept.                   */
    %LET ENDDAY_CEP   = <DDMONYYYY>;    /* (T) Last day of last month of CEP U.S. sales to be kept.               */

%LET FILTER_EP     = <YES/NO>;          /* (T) Additionally filter EP sales?  Type "YES" (no quotes) to filter,   */
                                        /*     "NO" to skip this part. If you typed "YES," then also complete     */
                                        /*     the three subsequent indented macro variables re: EP.              */
    %LET EP_DATE_VAR  = <  >;           /* (V) The date variable to be used to filter EP sales, e.g., entry date. */
    %LET BEGINDAY_EP  = <DDMONYYYY>;    /* (T) Day 1 of 1st month of EP U.S. sales to be kept.                    */
    %LET ENDDAY_EP    = <DDMONYYYY>;    /* (T) Last day of last month of EP U.S. sales to be kept.                */

/*----------------------------------------------------------------------------------------------------------------------*/
/* TITLES, FOOTNOTES AND AUTOMATIC NAMES FOR OUTPUT DATASETS                                                            */
/*                                                                                                                      */
/* The information below will be used in creating titles and footnotes, and naming output datasets.                     */
/*                                                                                                                      */
/* NAMES FOR INPUT/OUTPUT DATASETS: Names of all output datasets generated by this program will have a standardized     */
/* prefix using the format:  "RESPONDENT_SEGMENT_STAGE" in which:                                                       */
/*                                                                                                                      */
/* RESPONDENT = Respondent identifier (e.g., company name)                                                              */
/* SEGMENT    = Segment of proceeding (e.g., INVEST, AR6, REMAND)                                                       */
/* STAGE      = PRELIM or FINAL                                                                                         */
/*                                                                                                                      */
/* The total number of places/digits used in the RESPONDENT, SEGMENT and STAGE identifiers, combined, should NOT        */
/* exceed 21.  Letters, numbers and underscores are acceptable. No punctuation marks, blank spaces or special           */
/* characters should be used.                                                                                           */
/*                                                                                                                      */
/* The names of the output datasets this program creates are as follows:                                                */
/*                                                                                                                      */
/* {RESPONDENT_SEGMENT_STAGE}_AVGMARG/AVGMIXED/TRNMIXED/TRANMARG = Transaction results for Cash Deposit                 */
/* {RESPONDENT_SEGMENT_STAGE}_IMPSTND/IMPCSTN/IMPCTRN/IMPTRAN    = Importer-specific transaction results for assessment */
/*                                                                                                                      */
/* All output datasets will be placed in the COMPANY directory.                                                         */
/*----------------------------------------------------------------------------------------------------------------------*/

%LET PRODUCT    = %NRBQUOTE(<Product under Investigation or Review>);    /* (T) Product */
%LET COUNTRY    = %NRBQUOTE(<Country under Investigation or Review>);    /* (T) Country */

/* Between the RESPONDENT, SEGMENT and STAGE macro variables below, there should be a maximum of 21 digits. */

%LET RESPONDENT = <  >;    /* (T) Respondent identifier.  Use only letters, numbers and underscores.                                */
%LET SEGMENT    = <  >;    /* (T) Segment of the proceeding, e.g., Invest, AR1, Remand.  Use only letters, numbers and underscores. */
%LET STAGE      = <  >;    /* (T) Stage of proceeding, e.g., Prelim, Final, Remand.  Use only letters, numbers and underscores.     */

/*---------------------------------------------------------*/
/* HAVE CONTROL NUMBERS (I.E. CONNUMU) BEEN REPORTED FOR   */
/* THIS CASE? TYPE IN 'YES' IF CONTROL NUMBERS HAVE BEEN   */
/* REPORTED FOR THIS CASE. TYPE IN 'NO' IF CONTROL NUMBERS */
/* HAVE NOT BEEN REPORTED FOR THIS CASE.                   */
/*                                                         */
/* DO NOT TYPE IN THE QUOTES.                              */
/*---------------------------------------------------------*/

%LET CONNUMS = <YES/NO>; /* (T) TYPE IN 'YES' OR 'NO'.  */
                         /*     DO NOT TYPE THE QUOTES. */

/*-----------------------------------------------------------------*/
/* IF THERE ARE REPORTED CONTROL NUMBERS, TYPE IN THE U.S. AND FOP */
/* CONTROL VARIABLE NAMES. IF THERE ARE NO CONTROL NUMBERS FOR     */
/* THIS CASE, DO NOT FILL IN THE FOLLOWING TWO MACRO VARIABLE.     */
/*-----------------------------------------------------------------*/

%LET USCONNUM  = <     >; /* (V) TYPE IN THE U.S. CONTROL VARIABLE */
                          /*     NAME (EX. CONNUMU) IF CONTROL     */
                          /*     NUMBERS HAVE BEEN REPORTED.       */

%LET FOPCONNUM = <     >; /* (V) TYPE IN THE FOP CONTROL VARIABLE  */
                          /*     NAME (EX. CONNUM) IF CONTROL      */
                          /*     NUMBERS HAVE BEEN REPORTED.       */

/*------------------------------------------------------------*/
/* IF THERE ARE REPORTED CONTROL NUMBERS (I.E. CONNUMU), LIST */
/* THE PHYSICAL CHARACTERISTIC VARIABLES THAT DEFINE THE      */
/* CONTROL NUMBERS. SEPARATE THE VARIABLES WITH SPACES.       */
/* OTHERWISE, LEAVE THIS MACRO VARIABLE BLANK.                */
/*------------------------------------------------------------*/

%LET USPHVARS = <    >; /* (V) LIST THE PHYSICAL CHARACTERISTIC VARIABLES   */
                        /*     THAT ARE USED TO DEFINE THE CONNUM. SEPARATE */
                        /*     THE VARIABLES WITH SPACES.                   */

/*-----------------------------------------------------------*/
/* WERE PHYSICAL CHARACTERISTICS INCLUDED WITH THE FOP DATA? */
/* TYPE IN 'YES' IF PHYSICAL CHARACTERISTICS WERE REPORTED   */
/* WITH THE FOP DATA AND 'NO' IF THEY WERE NOT REPORTED.     */
/*                                                           */
/* DO NOT TYPE IN THE QUOTES.                                */
/*-----------------------------------------------------------*/

%LET FOPCHARS = <YES/NO>; /* (T) TYPE IN 'YES' OR 'NO'.  */
                          /*     DO NOT TYPE THE QUOTES. */

/*----------------------------------------------------------------*/
/* TYPE IN THE U.S. GROSS UNIT PRICE VARIABLE NAME (EX. GRSUPRU). */
/*----------------------------------------------------------------*/

%LET USGUP = <     >;     /* (V) TYPE IN THE GROSS UNIT PRICE */
                          /*     VARIABLE NAME (EX. GRSUPRU). */

/*-----------------------------------------------------*/
/* TYPE IN THE U.S. QUANTITY VARIABLE NAME (EX. QTYU). */
/*-----------------------------------------------------*/

%LET USQTY = <     >;     /* (V) TYPE IN THE U.S. QUANTITY */
                          /*     VARIABLE NAME (EX. QTYU). */

/*-------------------------------------------------------------*/
/* TYPE IN 'EP' IF SALES ARE ONLY EXPORT PRICE SALES, 'CEP' IF */
/* SALES ARE CONSTRUCTED EXPORT PRICE OR FURTHER MANUFACTURED  */
/* SALES OR 'BOTH' IF SALES ARE OF A MIXED TYPE.               */
/*                                                             */
/* DO NOT TYPE IN THE QUOTES.                                  */
/*-------------------------------------------------------------*/

%LET SALETYPE = <EP/CEP/BOTH>;  /* (T) TYPE IN 'EP', 'CEP', OR 'BOTH'. */
                                /*     DO NOT TYPE THE QUOTES.         */


/*-------------------------------------------------------------------*/
/* CASES INITIATED AFTER JUNE 19, 2012 MAY HAVE IRRECOVERABLE INPUT  */
/* VALUE-ADDED TAXES (VATTAXU) ON MERCHANDISE SOLD TO THE UNITED     */
/* STATES AND THOSE TAXES ARE DEDUCTED FROM THE EP OR CEP PRICES.    */
/* DEFINE THE MACRO VARIABLE VAT_TAX_TYPE TO CAPTURE WHETHER VATTAXU */
/* IS REPORTED AS A UNIT AMOUNT, AS A PERCENTAGE, OR NOT REPORTED.   */
/*-------------------------------------------------------------------*/

%LET VAT_TAX_TYPE = <AMOUNT/PERCENTAGE/NONE>; /* (T) TYPE IN 'AMOUNT' IF VATTAXU IS REPORTED */
                                              /*     AS A UNIT AMOUNT. TYPE IN 'PERCENTAGE'  */
                                              /*     IF VATTAXU IS REPORTED AS A PERCENTAGE. */
                                              /*     TYPE IN 'NONE' IF THERE IS NO VATTAXU.  */
                                              /*     DO NOT TYPE THE QUOTES.                 */

/*--------------------------------------------------------------------*/
/* CASES INITIATED AFTER JUNE 19, 2012 MAY HAVE EXPORT OR OTHER TAXES */
/* (EXTAXU) PAID ON MERCHANDISE SOLD TO THE UNITED STATES AND THOSE   */
/* TAXES ARE DEDUCTED FROM THE EP OR CEP PRICES. DEFINE THE MACRO     */
/* VARIABLE   EXPORT_TAX_TYPE TO CAPTURE WHETHER EXTAXU IS REPORTED   */
/* AS A UNIT AMOUNT, AS A PERCENTAGE, OR NOT REPORTED.                */
/*--------------------------------------------------------------------*/


%LET EXPORT_TAX_TYPE = <AMOUNT/PERCENTAGE/NONE>; /* (T) TYPE IN 'AMOUNT' IF EXTAXU IS REPORTED */
                                                 /*     AS A UNIT AMOUNT. TYPE IN 'PERCENTAGE' */
                                                 /*     IF EXTAXU IS REPORTED AS A PERCENTAGE. */
                                                 /*     TYPE 'NONE' IF THERE IS NO EXTAXU.     */
                                                 /*     DO NOT TYPE THE QUOTES.                */

/*-------------------------------------------------------*/
/* TO CORROBORATE THE PETITION RATE, INITIATION RATE, OR */
/* HIGHEST RATE. TYPE IN THE RATE AS A PERCENTAGE VALUE  */
/* (EX. 93.13, WHICH STANDS FOR A RATE OF 93.13%).       */
/*-------------------------------------------------------*/

%LET PERCENT = <    >; /* (T) TYPE IN THE PETITION RATE, INITIATION RATE, */
                       /*     OR HIGHEST RATE. TYPE IN THE PERCENTAGE AS  */
                       /*     A FRACTIONAL VALUE  (EX. 93.13 WHICH STANDS */
                       /*     FOR 93.13%).                                */

/*----------------------------------------------------------*/
/* DISPLAY THE ANTIDUMPING DUTY MARGIN AS A PER-UNIT AMOUNT */
/* INSTEAD OF A WEIGHT AVERAGED PERCENT MARGIN?             */
/*                                                          */
/* TYPE IN 'YES' TO DISPLAY THE ANTIDUMPING DUTY MARGIN AS  */
/* A PER-UNIT AMOUNT INSTEAD OF A WEIGHT AVERAGED           */
/* PERCENT MARGIN. OTHERWISE, TYPE IN A 'NO'.               */
/*                                                          */
/* DO NOT TYPE IN THE QUOTES.                               */
/*----------------------------------------------------------*/

%LET PER_UNIT_RATE = <YES/NO>; /* (T) TYPE IN 'YES' OR 'NO'.  */
                               /*     DO NOT TYPE THE QUOTES. */

/*------------------------------------------------------*/
/* FOR REVIEWS, TYPE IN THE 'IMPORTER' IF IMPORTER IS   */
/* REPORTED OR 'CUSCODU' IF IMPORTER IS NOT REPORTED.   */
/* TYPE IN 'YES' IF ENTERED VALUE IS REPORTED AND 'NO'  */
/* IF ENTERED VALUE IS NOT REPORTED.                    */
/*                                                      */
/* FOR INVESTIGATIONS, DO NOT FILL IN THESE VARIABLES.  */
/*                                                      */
/* DO NOT TYPE IN THE QUOTES.                           */
/*------------------------------------------------------*/

%LET IMPORTER = <IMPORTER/CUSCODU>; /* (V) TYPE IN 'IMPORTER' OR   */
                                    /*     'CUSCODU'. DO NOT TYPE  */
                                    /*     THE QUOTES.             */

%LET ENTERED_VALUE = <YES/NO>;      /* (V) TYPE IN 'YES' OR 'NO'.  */
                                    /*     DO NOT TYPE THE QUOTES. */

/*------------------------------------------------------------*/
/* DISPLAY THE IMPORTER-SPECIFIC MARGINS AS A PER-UNIT AMOUNT */
/* REGARDLESS OF WHETHER ENTERED VALUE IS REPORTED?           */
/*                                                            */
/* TYPE IN 'YES' TO DISPLAY THE IMPORTER-SPECIFIC MARGINS AS  */
/* A PER-UNIT AMOUNT REGARDLESS OF WHETHER ENTERED VALUE IS   */
/* REPORTED? OTHERWISE, TYPE IN A 'NO'.                       */
/*                                                            */
/* DO NOT TYPE IN THE QUOTES.                                 */
/*------------------------------------------------------------*/

%LET FORCEPERUNITASSESS = <YES/NO>; /* (T) TYPE IN 'YES' OR 'NO'.  */
                                    /*     DO NOT TYPE THE QUOTES. */

/*----------------------------------------------------------------------------------*/
/* IF THERE ARE ANY ADJUSTMENTS THAT NEED TO BE CONVERTED INTO U.S. DOLLARS, MAKE   */
/* A COPY OF THE DAILY EXCHANGE RATE DATASET(S) FROM:                               */
/*                                                                                  */
/* \\itacentral\myorg\ia\SAS\Shared Documents\Exchange Rates\SAS rates for Analysts */
/*                                                                                  */
/* AND PUT THE COPY (OR COPIES) IN THE LOCATION WHERE THE SAS DATASETS (EX. U.S.    */
/* SALES, FOP) FOR THIS CASE ARE LOCATED.                                           */
/*----------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/* FILL OUT THE FOLLOWING THREE MACRO VARIABLES IF THERE ARE ADJUSTMENTS      */
/* THAT NEED TO BE CONVERTED INTO U.S. DOLLARS FROM A FIRST FOREIGN CURRENCY. */
/* OTHERWISE FILL OUT ONLY THE FIRST MACRO VARIABLE USE_EXRATES1.             */
/*----------------------------------------------------------------------------*/

%LET USE_EXRATES1 = <YES/NO>;   /* (T) Use exchange rate #1? Type "YES" or "NO"  */
                                /*     (without quotes).                         */
%LET EXDATA1 = <  >;            /* (D) Exchange rate #1 dataset name.            */
%LET VARS_TO_USD1 = <      >;   /* (V) Type in the list of variables to convert  */
                                /*     into U.S. dollars using exchange rate #1. */
                                /*     Separate the variables with spaces.       */

/*-----------------------------------------------------------------------------*/
/* FILL OUT THE FOLLOWING THREE MACRO VARIABLES IF THERE ARE ADJUSTMENTS       */
/* THAT NEED TO BE CONVERTED INTO U.S. DOLLARS FROM A SECOND FOREIGN CURRENCY. */
/* OTHERWISE FILL OUT ONLY THE FIRST MACRO VARIABLE USE_EXRATES2.              */
/*-----------------------------------------------------------------------------*/

%LET USE_EXRATES2 = <YES/NO>;   /* (T) Use exchange rate #2? Type "YES" or "NO"  */
                                /*     (without quotes).                         */
%LET EXDATA2 = <  >;            /* (D) Exchange rate #2 dataset name.            */
%LET VARS_TO_USD2 = <      >;   /* (V) Type in the list of variables to convert  */
                                /*     into U.S. dollars using exchange rate #1. */
                                /*     Separate the variables with spaces.       */

/*-----------------------------------------------------------------*/
/* THE FOLLOWING MACRO WILL BE USED IN PART 7 TO CALCULATE INPUTS. */
/*-----------------------------------------------------------------*/

%MACRO CALCULATE_INPUTS;
    /*----------------------------------------------------------------------*/
    /* CALCULATE FRIEGHT FOR EACH FACTOR OF PRODUCTION TRANSPORTED FROM     */
    /* A SUPPLIER TO THE MANUFACTURER.                                      */
    /*                                                                      */
    /* A SIGMA CAP NEEDS TO BE DETERMINED FOR EACH TRANSPORTED FOP THAT HAS */
    /* A SV DERIVED FROM AN IMPORT STATISTIC. DETERMINE WHICH DISTANCE IS   */
    /* CLOSER TO THE MANUAFACTURER - THE DISTANCE BETWEEN THE RAW MATERIAL  */
    /* SUPPLIER TO THE FACTORY OR THE DISTANCE BETWEEN THE MANUFACTURER AND */
    /* THE NEAREST PORT OF EXIT. MULTIPLY THE SHORTER DISTANCE (THE SIGMA   */
    /* CAP) BY THE MODE SPECIFIC TRANSPORTATION CHARGE. SOMETIMES THE       */
    /* RESPONDENT SUPPLIES A SIGMA CAP DISTANCE FOR EACH TRANSPORTED FOP.   */
    /* WHEN REPORTED, THESE SIGMA CAP DISTANCES CAN BE USED.                */
    /*                                                                      */
    /* IF THE TRANSPORTED FOP HAS A SV THAT IS NOT DERIVED FROM AN IMPORT   */
    /* STATISTIC USE THE REPORTED DISTANCE VALUE.                           */
    /*                                                                      */
    /* IN THE FOLLOWING TWO EXAMPLES USE THE FOLLOWING FOUR VARIABLES:      */
    /*                                                                      */
    /*       IRONDIS  = THE RESPONDENT REPORTED DISTANCE BETWEEN THE RAW    */
    /*                  MATERIAL SUPPLIER TO THE FACTORY.                   */
    /*       DINLFTWU = THE REPONDENT REPORTED DISTANCE FROM THE PLANT TO   */
    /*                  DISTRIBUTION WAREHOUSE. NOTE: IF THE RESPONDENT     */
    /*                  DOES NOT HAVE A DISTRIBUTION WAREHOUSE, DINLFTWU    */
    /*                  WILL NOT BE REPORTED AND DOES NOT NEED TO BE USED   */
    /*                  IN THESE CALCULATIONS.                              */
    /*       DINLFTPU = THE REPONDENT REPORTED DISTANCE FROM THE PLANT OR   */
    /*                  DISTRIBUTION WAREHOUSE TO THE NEAREST PORT OF EXIT. */
    /*       TRUCK_SV = THE DEPARTMENT CALCULATED TRANSPORATION CHARGE.     */
    /*                                                                      */
    /* ASSUME IRONDIS = 10KM, DINLFTWU = 1KM, AND DINLFTPU = 5KM.           */
    /*                                                                      */
    /* EXAMPLE WHERE THE FOP SV *IS* DERIVED FROM AN IMPORT STATISTIC:      */
    /*                                                                      */
    /*          IRONORE_FRIEGHT = (DINLFTWU + DINLFTPU) * TRUCK_SV;         */
    /*                                                                      */
    /* EXAMPLE WHERE THE FOP SV *IS NOT* DERIVED FROM AN IMPORT STATISTIC:  */
    /*                                                                      */
    /*          IRONORE_FRIEGHT = IRONDIS * TRUCK_SV;                       */
    /*                                                                      */
    /*                                                                      */
    /* THE SIGMA CAP DETERMINATION CAN BE MADE WHERE THE FOP SV *IS*        */
    /* DERIVED FROM AN IMPORT STATISTIC USING THE MINIMUM FUNCTION.         */
    /*                                                                      */
    /* EXAMPLE: IRONORE_FRIEGHT = MIN(IRONDIS, (DINLFTWU + DINLFTPU))       */
    /*                          * TRUCK_SV;                                 */
    /*                                                                      */
    /*----------------------------------------------------------------------*/
    /*                                                                      */
    /* CALCULATE EACH INPUT BY ADDING THE FREIGHT CHARGES (IF APPLICABLE)   */
    /* TO THE SURROGATE VALUE AND MULTIPLYING THE RESULT TO THE FACTOR OF   */
    /* PRODUCTION.                                                          */
    /*                                                                      */
    /* NOTE: MAKE SURE TO USE THE SUFFIX '_IN' WHEN NAMING THE INPUT        */
    /* VARIABLES. THE INPUT VARIABLES WILL BE USED IN A SEPARATE INPUTS     */
    /* PANELING PROGRAM.                                                    */
    /*                                                                      */
    /* EXAMPLE: IRONORE_IN = IRONORE * (IRONORE_SV + IRONORE_FREIGHT);      */
    /*                                                                      */
    /* WHERE: IRONORE = THE RESPONDENT REPORTED FACTOR OF PRODUCTION        */
    /*        IRONORE_SV = THE DEPARTMENT CALCULATED SURROGATE VALUE        */
    /*        IRONORE_FREIGHT = THE DEPARTMENT CALCULATED FREIGHT CHARGE    */
    /*----------------------------------------------------------------------*/

    DATA INPUTS;
        SET USSALES;

        /* FREIGHT CHARGES (IF ANY) */

        <FREIGHT CHARGES (IF ANY)> /* (E) */

        /* DIRECT MATERIALS (IF ANY) */

        <DIRECT MATERIALS (IF ANY)> /* (E) */

        /* ENERGY (IF ANY) */

        <ENERGY (IF ANY)> /* (E) */

        /* LABOR (IF ANY) */

        <LABOR (IF ANY)> /* (E) */

        /* PACKING (IF ANY) */

        <PACKING (IF ANY)> /* (E) */

        /* BY-PRODUCTS (IF ANY) */

        <BY-PRODUCTS (IF ANY)> /* (E) */
    RUN;
%MEND CALCULATE_INPUTS;

/*------------------------------------------------------------------------*/
/* THE FOLLOWING MACRO WILL BE USED IN PART 8 TO CALCULATE NORMAL VALUES. */
/*------------------------------------------------------------------------*/

%MACRO CALCULATE_NORMAL_VALUES;
    DATA NVALUES;
        SET INPUTS;

         /*-----------------------------------------------*/
         /* CALCULATE THE FOLLOWING FIVE VARIABLES USING  */
         /* INPUTS CREATED ABOVE. IF THERE ARE NO INPUTS  */
         /* FOR A PARTICULAR VARIABLE, SET THE VARIABLE   */
         /* TO ZERO.                                      */
         /*-----------------------------------------------*/

         DIRECT_MATERIAL     = <   >; /* (E) Sum of the direct material inputs. */
         ENERGY              = <   >; /* (E) Sum of the energy inputs.          */
         LABOR               = <   >; /* (E) Sum of the labor inputs except     */
                                      /*     packing labor.                     */
         PACKING             = <   >; /* (E) Sum of the packing inputs and      */
                                      /*     packing labor.                     */
         BY_PRODUCTS         = <   >; /* (E) Sum of the by-products inputs.     */

         COM                 = DIRECT_MATERIAL + ENERGY + LABOR;

         OVRHD               = COM * OVRHDSV;
         TOTCOM              = COM + OVRHD;
         SGA                 = TOTCOM * SGASV;
         PROFIT              = (TOTCOM + SGA) * PROFTSV;

         NV                    = TOTCOM + SGA + PROFIT + PACKING - ABS(BY_PRODUCTS);
    RUN;
%MEND CALCULATE_NORMAL_VALUES;

/*----------------------------------------------------------------------------------*/
/* THE FOLLOWING MACRO WILL BE USED IN PARTS 9A AND 9B TO CALCULATE U.S. NET PRICES */
/*----------------------------------------------------------------------------------*/

%MACRO CALCULATE_USNETPRI;
    DATA USPRICES;
        SET NVALUES;

        /*-----------------------------------------------------------------------*/
        /* THE FOLLOWING SELECT/WHEN STATEMENT DEFINES THE VARIABLE VETAXU BASED */
        /* ON THE VALUES OF THE MACRO VARIABLES VAT_TAX_TYPE AND EXPORT_TAX_TYPE */
        /* THAT ARE DEFINED AT THE TOP OF THE PROGRAM.                           */
        /*-----------------------------------------------------------------------*/

        %IF &VAT_TAX_TYPE = NONE %THEN
        %DO;
            VATTAXU = 0;
        %END;

        %IF &EXPORT_TAX_TYPE = NONE %THEN
        %DO;
            EXTAXU = 0;
        %END;

        SELECT ("&VAT_TAX_TYPE &EXPORT_TAX_TYPE");
            WHEN ('AMOUNT NONE')           VETAXU = VATTAXU;
            WHEN ('PERCENTAGE NONE')       VETAXU = (&USGUP * VATTAXU);
            WHEN ('NONE AMOUNT')           VETAXU = EXTAXU;
            WHEN ('NONE PERCENTAGE')       VETAXU = (&USGUP * EXTAXU);
            WHEN ('AMOUNT AMOUNT')         VETAXU = VATTAXU + EXTAXU;
            WHEN ('AMOUNT PERCENTAGE')     VETAXU = VATTAXU + (&USGUP * EXTAXU);
            WHEN ('PERCENTAGE PERCENTAGE') VETAXU = (&USGUP * VATTAXU) + (&USGUP * EXTAXU);
            WHEN ('PERCENTAGE AMOUNT')     VETAXU = (&USGUP * VATTAXU) + EXTAXU;
            OTHERWISE VETAXU = 0;
        END;

        %IF &VAT_TAX_TYPE = NONE %THEN
        %DO;
            DROP VATTAXU;
        %END;

        %IF &EXPORT_TAX_TYPE = NONE %THEN
        %DO;
            DROP EXTAXU;
        %END;

        /*---------------------------------------------------*/
        /* IF A RESPONDENT ADJUSTMENT IS REPORTED IN FOREIGN */
        /* CURRENCY MAKE SURE IT HAS BEEN CONVERTED TO U.S.  */
        /* DOLLARS IN PART 6 BY MULTIPLYING THE ADJUSTMENT   */
        /* BY THE DAILY EXCHANGE RATE VARIABLE.              */
        /*---------------------------------------------------*/

        /*-----------------------------------------------------*/
        /* ADDITIONS TO U.S. STARTING PRICE (IN U.S. DOLLARS). */
        /*-----------------------------------------------------*/

        GUPADJU   = <     >; /* (E) Sum of negotiated invoice price,      */
                             /*     adjustments, or packing expenses      */
                             /*     that are not included in GRSUPRU.     */
        DISCREBU  = <     >; /* (E) Sum of U.S. discounts, rebates, and   */
                             /*     post-sale agreements.                 */
        DCMMOVEU  = <     >; /* (E) Sum of all domestic movement expenses */
                             /*     up to delivery along-side the vessel  */
                             /*     at the port of export to the U.S.     */
                             /*     Usually reported in foreign currency. */
        INTLMOVEU = <     >; /* (E) Sum of all international and U.S.     */
                             /*     movement charges, including U.S.      */
                             /*     duties, from loading onto the export  */
                             /*     vessel to delivery in U.S.            */

        %IF %UPCASE(&SALETYPE) = EP OR %UPCASE(&SALETYPE) = BOTH %THEN
        %DO;
            /*------------------------------------------------*/
            /* PART 9A: CALCULATE NET U.S. PRICE FOR EP SALES */
            /*------------------------------------------------*/

            /*--------------------------------------------------------------*/
            /* (E) DETERMINE WHETHER TO REDUCE OR INCREASE THE GROSS UNIT   */
            /*     PRICE BY ADJUSTMENTS (GUPADJU). DEPENDING ON WHETHER THE */
            /*     VALUE OF GUPADJU IS POSSITIVE OR NEGATIVE, SUBTRACT OR   */
            /*     ADD GUPADJU FROM GROSS UNIT PRICE.                       */
            /*--------------------------------------------------------------*/

            IF SALEU = 'EP' THEN
                   USNETPRI = &USGUP <+/-> GUPADJU - DISCREBU - DCMMOVEU - INTLMOVEU - VETAXU;
        %END;

        %IF %UPCASE(&SALETYPE) = BOTH %THEN
        %DO;
            ELSE
        %END;

        %IF %UPCASE(&SALETYPE) = CEP OR %UPCASE(&SALETYPE) = BOTH %THEN
        %DO;
            IF SALEU IN ('CEP' 'FMG') THEN
            DO;
                /*-------------------------------------------------*/
                /* PART 9B: CALCULATE NET U.S. PRICE FOR CEP SALES */
                /*-------------------------------------------------*/

                /*---------------------------------------------------*/
                /* IF A RESPONDENT ADJUSTMENT IS REPORTED IN FOREIGN */
                /* CURRENCY MAKE SURE IT HAS BEEN CONVERTED TO U.S.  */
                /* DOLLARS IN PART 6 BY MULTIPLYING THE ADJUSTMENT   */
                /* BY THE DAILY EXCHANGE RATE VARIABLE.              */
                /*---------------------------------------------------*/

                /*------------------------------------------*/
                /* CEP SELLING EXPENSE DEDUCTIONS FROM U.S. */ 
                /* STARTING PRICE THAT ARE INCURRED ON      */
                /* ECONOMIC ACTIVITY IN THE U.S. MARKET.    */  
                /*------------------------------------------*/
   
                COMMISNU   = <     >; /* (E) Sum of U.S. commissions.              */
                CEPIINVCCU = <     >; /* (E) Sum of CEP imputed inventory carrying */
                                      /*     costs. Typically includes INVENCARU.  */
                CEPINDSELU = <     >; /* (E) Sum of non-imputed indirects.         */
                                      /* (E) Typically includes INDIRSU.           */
                USCREDITU  = <     >; /* (E) Sum of U.S. imputed credit.           */
                USDIREXPU  = <     >; /* (E) Sum of U.S. direct selling expenses,  */
                                      /*     including repacking and excluding     */
                                      /*     USCREDITU and COMMISNU.               */
                USFURMANU  = <     >; /* (E) Sum of further manufacturing. Should  */
                                      /*     be zero unless further manufacturing  */
                                      /*     takes place in the U.S.               */

                TOTCEPISEL = CEPIINVCCU + CEPINDSELU;

                CEPSELLU   = COMMISNU + TOTCEPISEL + USCREDITU + USDIREXPU
                              + USFURMANU;
                CEPROFIT   = PROFTSV * CEPSELLU;

                /*--------------------------------------------------------------*/
                /* (E) DETERMINE WHETHER TO REDUCE OR INCREASE THE GROSS UNIT   */
                /*     PRICE BY ADJUSTMENTS (GUPADJU). DEPENDING ON WHETHER THE */
                /*     VALUE OF GUPADJU IS POSSITIVE OR NEGATIVE, SUBTRACT OR   */
                /*     ADD GUPADJU FROM GROSS UNIT PRICE.                       */
                /*--------------------------------------------------------------*/

                 USNETPRI = &USGUP <+/-> GUPADJU - DISCREBU - DCMMOVEU - INTLMOVEU - VETAXU
                          - CEPROFIT - CEPSELLU;
            END;
        %END;
    RUN;
%MEND CALCULATE_USNETPRI;

/*-------------------------------------------------*/
/* THE FOLLOWING FIVE MACRO VARIABLES WILL BE USED */
/* IN PART 11 TO RUN THE COHEN'S-D TEST.           */
/*-------------------------------------------------*/

/*----------------------------------------------------------------*/
/*  COHEN'S-D TEST                                                */
/*                                                                */
/*    Normally, the regions will correspond to the 5 Census       */
/*    regions:  Northeast, Midwest, South, West, and Puerto Rico. */
/*    (Do not include U.S. Territories other than Puerto Rico     */
/*    because they are not in the Customs Territory of the U.S.)  */
/*                                                                */
/*    If you have a region variable, type DP_REGION_DATA=REGION   */
/*    and then specify the region variable in DP_REGION=???.      */
/*    Please note that any unknown regions should be listed as    */
/*    blank spaces and not, for example, as "UNKNOWN" or "UNK."   */
/*                                                                */
/*    If you instead have a variable that has either the 2-digit  */
/*    postal state code or the zip code (5 or 9 digits), then     */
/*    indicate the same below by typing DP_REGION_DATA=STATE or   */
/*    DP_REGION_DATA=ZIP. If you need to write your own language  */
/*    to create the Census regions, do so in Sect. 2-B below      */
/*    re: changes and edits to the U.S. database.                 */
/*                                                                */
/*    If you have any unknown purchasers/customers, they should   */
/*    be reported as blank spaces and not, for example, as        */
/*    "UNKNOWN" or "UNK." If this is not the case, please edit    */
/*    the data accordingly.                                       */
/*                                                                */
/*    Usually, time periods for purposes of the Cohen's-d Test    */
/*    will be defined by quarters, beginning with the first month */
/*    of POI/POR as found in the B_PERIOD macro variable          */
/*    defined above. If you wish to use quarters                  */
/*    and do not have a variable for the same, type               */
/*    DP_TIME_CALC=YES and the program will use the sale date     */
/*    variable to assign quarters.  If you already have a         */
/*    variable for quarters or are using something other than     */
/*    quarters, type DP_TIME_CALC=NO and also indicate the        */
/*    variable containing the time periods in DP_TIME=???.        */
/*----------------------------------------------------------------*/

%LET DP_PURCHASER   = <        >; /* (V) Variable indicating customer for purposes of the  */
                                  /*     Cohen's-d test.                                   */
%LET DP_REGION_DATA = <        >; /* (T) Type either "REGION," "STATE" or "ZIP" (without   */
                                  /*     quotes) to indicate the type of data being used   */
                                  /*     to assign Census regions. Then complete the       */
                                  /*     DP_REGION macro variable immediately following.   */
%LET     DP_REGION  = <        >; /* (V) Variable indicating the DP region if you typed    */
                                  /*     "REGION" for DP_REGION_DATA, or the variable      */
                                  /*     indicating the 2-digit postal state designation   */
                                  /*     if you typed "STATE," or the variable indicating  */
                                  /*     the 5-digit zip code if you typed "ZIP."          */
%LET DP_TIME_CALC   = <YES/NO>;   /* (T) Type "YES" (without quotes) to assign quarters    */
                                  /*     using the beginning of the period.                */
%LET     DP_TIME    = <        >; /* (V) If you typed "NO" for DP_TIME_CALC because you    */
                                  /*     already have a variable for the DP time period,   */
                                  /*     indicate that variable here.                      */

/*----------------------------------------------*/
/* FORMAT, PROGRAM AND PRINT OPTIONS            */
/*----------------------------------------------*/

OPTIONS OBS = MAX;                         /* LIMIT DATA PROCESSED                       */
%LET PRINTOBS = 10;                        /* NUMBER OF OBSERVATIONS TO PRINT            */

OPTIONS PAPERSIZE = LETTER;
OPTIONS ORIENTATION = LANDSCAPE;
OPTIONS TOPMARGIN = ".25IN"
        BOTTOMMARGIN = ".25IN"
        LEFTMARGIN = ".25IN"
        RIGHTMARGIN = ".25IN";

TITLE1 "NME MARGIN CALCULATION PROGRAM - &PRODUCT FROM &COUNTRY - (&BEGINPERIOD - &ENDPERIOD)";
TITLE2 "&SEGMENT &STAGE FOR RESPONDENT &RESPONDENT";
FOOTNOTE1 "*** BUSINESS PROPRIETARY INFORMATION SUBJECT TO APO ***";
FOOTNOTE2 "&BDAY, &BWDATE - &BTIME";

OPTIONS NODATE;                            /* SUPPRESS DATE IN HEADER                    */
OPTIONS PAGENO = 1;                        /* RESET PAGE NUMBER TO 1                     */
OPTIONS FORMCHAR = '|----|+|---+=|-/<>*';  /* FOR PRINTING TABLES                        */
OPTIONS SYMBOLGEN;                         /* PRINT MACRO VARIABLE VALUES                */
OPTIONS MPRINT;                            /* PRINT MACRO RESOLUTIONS                    */
OPTIONS NOMLOGIC;                          /* PRINTS ADDITIONAL MACRO INFORMATION        */
                                           /* TYPE "MLOGIC" (WITHOUT QUOTES) TO ACTIVATE */
OPTIONS MINOPERATOR;                       /* MINOPERATOR IS REQUIRED WHEN USING THE     */
                                           /* IN(..) FUNCTION IN MACROS                  */

%LET COMMA_FORMAT = COMMA12.2;    /* Comma format using 12 total spaces and two  */
                                  /* decimal places.                             */
%LET DOLLAR_FORMAT = DOLLAR12.2;  /* Dollar format using 12 total spaces and two */
                                  /* decimal places.                             */
%LET PERCENT_FORMAT = PERCENT7.2; /* Percent format using seven total spaces and */
                                  /* two decimal places.                         */

%GLOBAL CEP_EXPENSES ENTVALUE IMPORTER USMON USMONTH USCONNUM DE_MINIMIS;

/*------------------------------------------------------------------------------*/
/* DEFINE THE FOLLOWING MACRO VARIABLES:                                        */
/*                                                                              */
/*  USCONNUM:        USED TO COMBINE U.S. SALES AND FOP DATA WITH OR WITHOUT    */
/*                   REPORTED MODELS (CONNUMS).                                 */
/*  CEP_EXPENSES:    USED TO SELECTIVELY PRINT THE VARIABLES CEPROFIT AND       */
/*                   CEPSELLU IN CASES WITH CEP SALES.                          */
/*  ENTVALUE:        USED IN REVIEWS TO CALCULATE IMPORTER SPECIFIC DUTY        */
/*                   ASSESSMENT RATES.                                          */
/*  IMPORTER:        USED IN REVIEWS TO CALCULATE IMPORTER SPECIFIC DUTY        */
/*                   ASSESSMENT RATES.                                          */
/*  USMONTH:         USED IN REVIEWS TO CREATE MONTHLY AVERAGE NET U.S. PRICES. */
/*------------------------------------------------------------------------------*/

%MACRO DEFINE_MACRO_VARS;
    %IF %UPCASE(&CONNUMS) = YES %THEN
         %LET USCONNUM = &USCONNUM;
    %ELSE
         %LET USCONNUM = ;

    %IF %UPCASE(&SALETYPE) = EP %THEN
         %LET CEP_EXPENSES = ;
    %ELSE
    %IF %UPCASE(&SALETYPE) = CEP OR %UPCASE(&SALETYPE) = BOTH %THEN
         %LET CEP_EXPENSES = CEPROFIT CEPSELLU;
    
    %IF %UPCASE(&CASE_TYPE) = INV %THEN
    %DO;
        %LET ENTVALUE = ;
        %LET IMPORTER = ;
        %LET USMONTH = ;
        %LET USMON = ;
        %LET DE_MINIMIS = 2;
    %END;
    %ELSE
    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;
        %IF %UPCASE(&ENTERED_VALUE) = YES %THEN
            %LET ENTVALUE = ENTVALUE;
        %ELSE
        %IF %UPCASE(&ENTERED_VALUE) = NO %THEN
            %LET ENTVALUE = ;

        %LET USMONTH = USMONTH;
        %LET USMON = USMONTH;
        %LET DE_MINIMIS = .5;
    %END;
%MEND DEFINE_MACRO_VARS;

%DEFINE_MACRO_VARS;

/*---------------------------------------------------------*/
/* IF CONNUMS ARE REPORTED, RUN THE CONNUM UNIQUENESS TEST */
/* TO DETERMINE IF CONNUMS ARE UNIQUE IN THE U.S. AND FOP  */
/* DATASETS WHEN MODELS AND PHYSICAL CHARACTERISTICS       */
/* DEFINING MODELS ARE REPORTED.                           */
/*---------------------------------------------------------*/

%MACRO UNIQUE_CONNUMS (DATASET);
    %IF %UPCASE(&CONNUMS) = YES %THEN
    %DO;
        PROC SORT DATA = &DATASET (KEEP = &USCONNUM &USPHVARS) 
                   OUT = CONNUM_CHECK NODUPKEY;
            BY &USCONNUM &USPHVARS;
        RUN;

        DATA NOT_UNIQUE_CONNUMS (DROP = COUNT UNIQUE)
                    UNIQUE_CONNUMS (KEEP = UNIQUE);
            SET CONNUM_CHECK END = EOF;
            BY &USCONNUM;
            IF NOT (FIRST.&USCONNUM AND LAST.&USCONNUM) THEN
            DO;
                COUNT + 1;
                OUTPUT NOT_UNIQUE_CONNUMS;
            END;
            ELSE
            IF EOF AND (COUNT = 0) THEN
            DO;
                UNIQUE = "CONNUMS IN THE &DATASET DATASET ARE UNIQUELY DEFINED";
                OUTPUT UNIQUE_CONNUMS;
            END;
        RUN;

        PROC PRINT DATA = NOT_UNIQUE_CONNUMS;
            TITLE3 "CONNUM UNIQUENESS TEST";
            TITLE4 "CONNUMS IN THE &DATASET DATASET THAT ARE NOT UNIQUELY DEFINED";
            TITLE5 "CONNUMS HAVE MORE THAN ONE UNIQUE COMBINATION";
            TITLE6 "OF PHYSICAL CHARACTERISTICS ASSOCIATED WITH THEM";
        RUN;

        PROC PRINT DATA = UNIQUE_CONNUMS SPLIT = '*' NOOBS;
            TITLE4;
            LABEL UNIQUE = '00'x;
        RUN;
    %END;
%MEND UNIQUE_CONNUMS;

/*------------------------------------*/
/* PART 2: GET U.S., FOP, AND SV DATA */
/*------------------------------------*/

/*------------------*/
/* GET U.S. DATASET */
/*------------------*/

DATA USSALES;
    SET COMPANY.&USDATA;
    USOBS = _N_;

    /* <Insert changes here, if required.> */

RUN;

/*------------------------------------------------------------------*/
/* GET USSALES COUNT FOR LOG REPORTING PURPOSES                     */
/* DO NOT EDIT CMAC2_COUNTER MACRO                                  */
/*------------------------------------------------------------------*/

	%CMAC2_COUNTER (DATASET = USSALES, MVAR=ORIG_USSALES);

/*ep*/

%MACRO SORT_US_SALES;
    %IF %UPCASE(&CONNUMS) = YES %THEN
    %DO;
        PROC SORT DATA = USSALES OUT = USSALES;
            BY &USCONNUM;
        RUN;

        %UNIQUE_CONNUMS (USSALES)
    %END;
%MEND SORT_US_SALES;

%SORT_US_SALES

PROC PRINT DATA = USSALES (OBS = &PRINTOBS);
    TITLE3 "SAMPLE PRINT OF U.S. SALES";
RUN;

/*ep*/

/*-----------------*/
/* GET FOP DATASET */
/*-----------------*/

DATA FOP;
    SET COMPANY.&FOPDATA;
    &FOPDATA._OBSORDER = _N_;

    /* <Insert changes here, if required.> */

RUN;

%MACRO SORT_FOP_SALES;
%IF %UPCASE(&CONNUMS) = YES %THEN
%DO;
    PROC SORT DATA = FOP (RENAME = &FOPCONNUM = &USCONNUM) OUT = FOP;
        BY &USCONNUM;
    RUN;

    %IF %UPCASE(&FOPCHARS) = YES %THEN
    %DO;
        %UNIQUE_CONNUMS (FOP)
    %END;
%END;
%MEND SORT_FOP_SALES;

%SORT_FOP_SALES

PROC PRINT DATA = FOP (OBS = &PRINTOBS);
    TITLE3 "SAMPLE PRINT OF FACTORS OF PRODUCTION";
RUN;

/*ep*/

/*------------------------------------------------------------------------------*/
/*                                                                              */
/* >>>>>>>>>>>>>>>>>>>>>>> READ THE FOLLOWING COMMENT <<<<<<<<<<<<<<<<<<<<<<<<< */
/*                                                                              */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* UNDER NORMAL CIRCUMSTANCES, DO NOT CHANGE ANYTHING BELOW THIS COMMENT BLOCK. */
/* IF YOU CHANGE ANYTHING BELOW THIS COMMENT BLOCK, DOCUMENT ANY CHANGES IN THE */
/* ANALYSIS MEMO AND MAKE SURE TO LET YOUR PANELIST KNOW ABOUT THESE CHANGES.   */
/*------------------------------------------------------------------------------*/

/*---------------------------------------------------*/
/* CONVERT SURROGATE VALUE NAMES INTO A SAS DATASET. */
/*---------------------------------------------------*/

PROC IMPORT OUT = SV_VAR_NAMES
    DATAFILE = "&SV_PATH" DBMS = EXCEL REPLACE;
    RANGE = "&SV_NAME_RANGE"; 
    GETNAMES = NO;
RUN;

/*----------------------------------------------------*/
/* CONVERT SURROGATE VALUE VALUES INTO A SAS DATASET. */
/*----------------------------------------------------*/

PROC IMPORT OUT = SV_VAR_VALUES
    DATAFILE = "&SV_PATH" DBMS = EXCEL REPLACE;
    RANGE = "&SV_VALUE_RANGE"; 
    GETNAMES = NO;
RUN;

/*----------------------------------------------------------*/
/* COMBINE THE LIST OF SURROGATE VALUE NAMES AND VALUES AND */
/* TRANSPOSE THEM TO CREATE THE SURROGATE VALUE DATASET.    */
/*----------------------------------------------------------*/

DATA SV;
    MERGE SV_VAR_NAMES SV_VAR_VALUES (RENAME = F1 = F2);
RUN;

PROC TRANSPOSE DATA = SV OUT = SV (DROP = _NAME_ _LABEL_);
    VAR F2;
    ID F1;
RUN;

PROC PRINT DATA = SV;
     TITLE3 "SURROGATE VALUES DATASET";
RUN;

/*ep*/

/*-------------------------------------------------------------*/
/* PART 3: KEEP U.S. SALES INSIDE THE COURSE OF ORDINARY TRADE */
/*-------------------------------------------------------------*/

/*--------------------------------------------*/
/*  Define the macro MARGIN_FILTER that will  */
/*  conditionally filter EP and/or CEP sales. */
/*--------------------------------------------*/

%MACRO MARGIN_FILTER;
    %IF %UPCASE(&FILTER_CEP) = YES %THEN
    %DO;
        ELSE
        IF (SALEU = "CEP") AND ("&BEGINDAY_CEP."D GT &CEP_DATE_VAR OR &CEP_DATE_VAR GT "&ENDDAY_CEP."D) 
            THEN OUTPUT OUTDATES;
    %END;

    %IF %UPCASE(&FILTER_EP) = YES %THEN
    %DO; 
        ELSE
        IF (SALEU = "EP") AND ("&BEGINDAY_EP."D GT &EP_DATE_VAR OR &EP_DATE_VAR GT "&ENDDAY_EP."D) 
            THEN OUTPUT OUTDATES;
    %END;
%MEND MARGIN_FILTER;

/*--------------------------------------------------*/
/*  In administrative reviews, define the USMONTH   */
/*  variable so that each month has a unique value. */
/*--------------------------------------------------*/

%MACRO GET_MONTH;
    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;
        MON = MONTH(&USDATE);
        YRDIFF = YEAR(&USDATE) - YEAR("&BEGINPERIOD"D);
        USMONTH = MON + YRDIFF * 12;
        DROP MON YRDIFF;
        %LET USMONTH = USMONTH;
    %END;
%MEND GET_MONTH;

DATA USSALES NEGDATA OUTDATES;
    SET USSALES;

    IF (&USQTY LE 0) OR (&USGUP LE 0) THEN
        OUTPUT NEGDATA;
    ELSE
    IF (&USDATE LT "&BEGINPERIOD"D) OR (&USDATE GT "&ENDPERIOD"D) THEN
        OUTPUT OUTDATES;
    %MARGIN_FILTER
    ELSE
    DO;
        %GET_MONTH
        OUTPUT USSALES;
    END;
RUN;

PROC PRINT DATA = NEGDATA (OBS = &PRINTOBS);
    TITLE3 "U.S. SALES WITH ZERO OR NEGATIVE QUANTITY OR GROSS UNIT PRICE";
RUN;

PROC PRINT DATA = OUTDATES (OBS = &PRINTOBS);
    TITLE3 "U.S. SALES OUTSIDE THE ANALYSIS PERIOD";
RUN;

/*ep*/

/*--------------------------------------------*/
/* PART 4: ADD SURROGATE VALUES TO U.S. SALES */
/*--------------------------------------------*/

DATA USSALES;
     SET USSALES;
     IF _N_ = 1 THEN
          SET SV;
RUN;

/*ep*/

/*--------------------------------------------------*/
/* PART 5: MATCH U.S. SALES AND SV DATA TO FOP DATA */
/*--------------------------------------------------*/

%MACRO COMBINE_DATA;
     %IF %UPCASE(&CONNUMS) = YES %THEN
     %DO;
          PROC SORT DATA = USSALES OUT = USSALES;
               BY &USCONNUM;
          RUN;

          PROC SORT DATA = FOP OUT = FOP;
               BY &USCONNUM;
          RUN;

          DATA USSALES NOFOP;
               MERGE USSALES (IN = US) FOP (IN = FP);
               BY &USCONNUM;
               IF US AND FP THEN
                    OUTPUT USSALES;
               ELSE
               IF US AND NOT FP THEN
                    OUTPUT NOFOP;
          RUN;

          PROC PRINT DATA = NOFOP (OBS = &PRINTOBS);
               TITLE3 "U.S. SALES AND SURROGATE VALUE DATA";
               TITLE4 "WITHOUT MATCHING FACTORS OF PRODUCTION";
          RUN;
     %END;
     %ELSE
     %DO;
          DATA USSALES;
               SET USSALES;
               IF _N_ = 1 THEN
                    SET FOP;
          RUN;
     %END;
%MEND COMBINE_DATA;

%COMBINE_DATA

/*ep*/

/*-------------------------------------------------------------------------------*/
/* PART 6: MERGE EXCHANGE RATES INTO SALES DATABASE. CONVERT VARIABLES INTO U.S. */
/*         DOLLARS AND REVISE THE VARIABLE NAMES TO INCLUDE THE SUFFIX _USD.      */
/*-------------------------------------------------------------------------------*/

%MACRO MERGE_EXRATES(USE_EXRATES = , EXDATA = ); 
    %IF %UPCASE(&USE_EXRATES) = YES %THEN
    %DO;
        /*-------------------------------------------------*/
        /* ACCESS EXCHANGE RATES DATASET AND SORT BY DATE. */
        /*-------------------------------------------------*/

           PROC SORT DATA = COMPANY.&EXDATA (RENAME = (DATE = &USDATE

                        %IF %UPCASE(&CASE_TYPE) = AR  %THEN
                        %DO;
                            &EXDATA.R = EXRATE_&EXDATA) DROP = &EXDATA.I)
                        %END;
                        %ELSE
                        %IF %UPCASE(&CASE_TYPE) = INV %THEN
                        %DO;
                            &EXDATA.I = EXRATE_&EXDATA) DROP = &EXDATA.R)
                        %END;
                  OUT = RATES;
            WHERE "&BEGINPERIOD"D LE &USDATE LE "&ENDPERIOD"D;
                   BY &USDATE;
        RUN;

        PROC PRINT DATA = RATES (OBS = &PRINTOBS);
            TITLE3 "DAILY EXCHANGE RATE DATA";
        RUN;

        /*-----------------------------------*/
        /* ADD EXCHANGE RATES TO U.S. SALES. */
        /*-----------------------------------*/

        PROC SORT DATA = USSALES OUT = USSALES;
              BY &USDATE;
        RUN;

        DATA USSALES NOEXRATE;
            MERGE USSALES (IN = US) RATES (IN = EX);
              BY &USDATE;
            IF US AND EX THEN
                OUTPUT USSALES;
            ELSE
            IF US AND NOT EX THEN
                OUTPUT NOEXRATE;
        RUN;

        PROC PRINT DATA = NOEXRATE (OBS = &PRINTOBS);
            TITLE3 "U.S. SALES WITH NO EXCHANGE RATES FOR &EXDATA";
        RUN;
    %END;
%MEND MERGE_EXRATES;

OPTIONS NOSYMBOLGEN;
%MERGE_EXRATES(USE_EXRATES = &USE_EXRATES1, EXDATA = &EXDATA1)
%MERGE_EXRATES(USE_EXRATES = &USE_EXRATES2, EXDATA = &EXDATA2)
OPTIONS SYMBOLGEN;

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

OPTIONS NOSYMBOLGEN;
%CONVERT_TO_USD (USE_EXRATES = &USE_EXRATES1, EXDATA = &EXDATA1, VARS_TO_USD = &VARS_TO_USD1)
%CONVERT_TO_USD (USE_EXRATES = &USE_EXRATES2, EXDATA = &EXDATA2, VARS_TO_USD = &VARS_TO_USD2)
OPTIONS SYMBOLGEN;

/*ep*/

/*--------------------------*/
/* PART 7: CALCULATE INPUTS */
/*--------------------------*/

%CALCULATE_INPUTS

PROC PRINT DATA = INPUTS (OBS = &PRINTOBS);
     TITLE3 "CALCULATED INPUTS";
RUN;

/*ep*/

/*---------------------------------*/
/* PART 8: CALCULATE NORMAL VALUES */
/*---------------------------------*/

%CALCULATE_NORMAL_VALUES

DATA NEGATIVE_NVALUES;
    SET NVALUES;
    WHERE NV LT 0;
RUN;

PROC PRINT DATA = NEGATIVE_NVALUES (OBS = &PRINTOBS);
    VAR &USCONNUM SALEU DIRECT_MATERIAL ENERGY LABOR COM OVRHD
        TOTCOM SGA PROFIT NV;
    TITLE3 "SAMPLE NEGATIVE NORMAL VALUES";
RUN;

PROC PRINT DATA = NVALUES (OBS = &PRINTOBS);
    TITLE3 "CALCULATED NORMAL VALUES";
RUN;

/*ep*/

/*--------------------------------------------------------------------*/
/* PART 9A AND PART 9B: CALCULATE NET U.S. PRICE FOR EP AND CEP SALES */
/*--------------------------------------------------------------------*/

%CALCULATE_USNETPRI

DATA NEGATIVE_USPRICES;
    SET USPRICES;
    WHERE USNETPRI LT 0;
RUN;

PROC PRINT DATA = NEGATIVE_USPRICES (OBS = &PRINTOBS);
    VAR &USCONNUM SALEU &USMONTH &USGUP GUPADJU DISCREBU
        DCMMOVEU INTLMOVEU &CEP_EXPENSES VETAXU USNETPRI;
    TITLE3 "SAMPLE NEGATIVE U.S. PRICES";
RUN;

PROC PRINT DATA = USPRICES (OBS = &PRINTOBS);
     TITLE3 "U.S. NET PRICE CALCULATIONS";
RUN;

PROC SORT DATA = USPRICES OUT = USPRICES;
    BY DESCENDING NV;
RUN;

PROC PRINT DATA = USPRICES (OBS = &PRINTOBS);
    VAR &USCONNUM SALEU DIRECT_MATERIAL ENERGY LABOR COM OVRHD
        TOTCOM SGA PROFIT NV &USGUP GUPADJU DISCREBU
        DCMMOVEU INTLMOVEU &CEP_EXPENSES USNETPRI;
    WHERE NV GT USNETPRI;
    TITLE3 "COMPARISON OF U.S. PRICE AND NORMAL VALUES";
    TITLE4 "WHERE NORMAL VALUES ARE GREATER THAN U.S. NET PRICES";
RUN;

/*ep*/

/*----------------------------------------*/
/* PART 10: CBP ENTERED VALUE BY IMPORTER */
/*----------------------------------------*/

%MACRO ENTVALUE;

    %IF %UPCASE(&CASE_TYPE) = AR %THEN
    %DO;        

        DATA USPRICES;
            SET USPRICES;
            LENGTH SOURCEDATA $10. ENTERED_VALUE 8. ;

            %IF %UPCASE(&IMPORTER) = NA %THEN
            %DO;
                US_IMPORTER  = 'UNSPECIFIED'; 
            %END;

            %ELSE
            %DO;
                US_IMPORTER = &IMPORTER;
            %END;

            %IF %UPCASE(&ENTERED_VALUE) EQ NO %THEN
            %DO;
                ENTERED_VALUE = .;  
            %END;

            %ELSE %IF %UPCASE(&ENTERED_VALUE) EQ YES %THEN
            %DO;
                ENTERED_VALUE = &ENTVALUE;
            %END;

            IF ENTERED_VALUE GT 0 THEN SOURCEDATA = 'REPORTED';
            ELSE 
            DO;
                SOURCEDATA = 'COMPUTED'; /* ENTERED_VALUE is computed by formula */ 
                ENTERED_VALUE = USNETPRI + DCMMOVEU;
            END;
            OUTPUT USPRICES;
        RUN;

        PROC SORT DATA = USPRICES; 
            BY US_IMPORTER SALEU SOURCEDATA;
        RUN;

        PROC MEANS NOPRINT DATA = USPRICES;
            BY US_IMPORTER SALEU SOURCEDATA;
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

        PROC SORT DATA = SOURCECHK;
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
            VAR SALEU SOURCEDATA SOURCEU SALES TOTQTY TOTEVALU;
            FORMAT SALES COMMA10. TOTQTY TOTEVALU COMMA16.2;
            LABEL    US_IMPORTER   = 'U.S. IMPORTER(S)*================'
                    SALEU          = 'TYPE OF *U.S. SALES*=========='
                    SOURCEDATA = 'ORIGINAL *SOURCE DATA*==========='
                    SOURCEU    = 'CUSTOMS VALUE*SOURCE DATA*============='
                    SALES      = 'U.S. SALES*=========='
                    TOTQTY     = 'U.S. QUANTITY*============='
                    TOTEVALU   = 'CUSTOMS ENTERED VALUE*=====================';
            TITLE3 'SOURCE OF CUSTOMS ENTERED VALUE DATA, BY IMPORTER';
        RUN; 

        PROC SORT DATA = USPRICES;
            BY US_IMPORTER;
        RUN;

        DATA USPRICES;
            MERGE USPRICES (IN=A) SOURCECHK (IN=B);
            BY US_IMPORTER;
            IF A & B
            THEN OUTPUT USPRICES;
        RUN;

    %END;

%MEND ENTVALUE;

%ENTVALUE

/*ep*/

/*-------------------------*/
/* PART 11: COHEN'S-D TEST */
/*-------------------------*/

/*--------------------------------------------------------------------------*/
/*    The Cohen's-d Test is run three ways:  1) by purchaser, 2) by region    */
/*    and 3) by time period.  U.S. sales are compared to sales to other         */
/*    purchasers/regions/periods to see if they pass the test.  At the end of    */
/*    the test, the percentage of U.S. sales found to pass the test is         */
/*    recorded.                                                                */
/*                                                                            */
/*    In the remaining sections of this program, the Cash Deposit Rate will    */
/*    be calculated three ways:  1) Standard Methodology (average-to-average    */
/*    comparisons on all sales, offsetting positive comparison results with     */
/*    negatives), 2) A-2-T Alternative Methodology (average-to-transaction      */
/*    comparisons on all sales, no offsetting of positive comparison results  */
/*    with negative ones), and 3) Mixed Alternative Methodology (applying the    */
/*    Standard Methodology to sales that do not pass the Cohen's-d Test and    */
/*    using the A-2-T Alternative Methodology on sales that do pass.            */
/*                                                                            */
/*    If no sale passes the Cohen's-d Test, the Mixed Alternative Methodology */
/*    would be the same as the Standard Methodology. In this case, the Mixed     */
/*    Alternative Methodology will not be calculated.  Similarly, the Mixed    */
/*    Alternative Methodology will also not be calculated when all sales         */
/*    pass the Cohen's-d Test since the it would be the same as the             */
/*    A-2-T Alternative Methodology.                                            */
/*--------------------------------------------------------------------------*/

%MACRO COHENS_D_TEST;

    TITLE3 "THE COHEN'S D TEST";

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
                &USDATE = "U.S. DATE*OF SALE*(&USDATE)"
            %MEND DPPERIOD_PRINT_LABEL;
        %END;        
        %IF %UPCASE(&DP_TIME_CALC) = NO %THEN
        %DO;
            %MACRO DPPERIOD_PRINT_LABEL;
            %MEND DPPERIOD_PRINT_LABEL;
        %END;        

    /*----------------------------------------------------------*/
    /*  Calculate net price for Cohen's d Analysis and set up    */
    /*    regions, purchasers and time periods.                    */
    /*----------------------------------------------------------*/

    DATA DPSALES;
        SET USPRICES;

            DP_COUNT = _N_;

            DP_NETPRI = USNETPRI;

            /*----------------------------------------------------------*/
            /*    Establish the region, time and purchaser                */
            /*    variables for the analysis when there are existing         */
            /*    variables in the data for the same.  If the time         */
            /*    variable for the analysis is being calculated by         */
            /*    using the quarter default, do that here.                */
            /*----------------------------------------------------------*/

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
                  DPMONTH=MONTH(&USDATE)+(YEAR(&USDATE)-YEAR("&BEGINPERIOD"D))*12;
                DP_PERIOD="QTR"||PUT(INT(1+(DPMONTH-FIRSTMONTH)/3),Z2.);
                DROP FIRSTMONTH DPMONTH;
                %LET DP_PERIOD = &USDATE;
                %LET PERIOD_PRINT_VARS = &DP_PERIOD DP_PERIOD;
            %END;
    RUN;

        /*----------------------------------------------------------*/
        /*    Attach region designations using state/zip codes,        */ 
        /*    when required.                                            */
        /*----------------------------------------------------------*/

        %IF %UPCASE(&DP_REGION_DATA) NE REGION %THEN
        %DO;

            PROC FORMAT;
                VALUE $REGION
                    "PR" "VI"           = "TERRITORY"

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
                        "WA"                = "WEST";
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
                        IF 500 LT INPUT(&DP_REGION, 8.) LT 100000 THEN VALID_ZIP = "YES";
                        ELSE VALID_ZIP = "NO";
                    END;
                    
                    IF VALID_ZIP = "YES" THEN STATE = ZIPSTATE(COMPRESS(&DP_REGION));
                    ELSE STATE = "";
                    %LET STATE = STATE;
                    DROP ZIPVAR_TYPE VALID_ZIP;
                %END;

                %IF %UPCASE(&DP_REGION_DATA) = STATE %THEN
                %DO;
                    %LET STATE = &DP_REGION;
                %END;

                LENGTH DP_REGION $9;
                DP_REGION = PUT(&STATE, REGION.);
            RUN;

        %END;

        DATA DPSALES USPRICES (DROP=DP_NETPRI DP_PURCHASER DP_REGION DP_PERIOD);
            SET DPSALES;
        RUN;

        PROC PRINT DATA = DPSALES (OBS=&PRINTOBS) SPLIT="*";
            VAR &USGUP GUPADJU DISCREBU DCMMOVEU INTLMOVEU VETAXU

            %IF %UPCASE(&SALETYPE) = CEP OR %UPCASE(&SALETYPE) = BOTH %THEN
            %DO;
                CEPROFIT CEPSELLU
            %END;
                DP_NETPRI DP_PURCHASER &PERIOD_PRINT_VARS &REGION_PRINT_VARS;
            LABEL DP_NETPRI = "NET PRICE*FOR COHEN'S D*ANALYSIS"
                  %DPPERIOD_PRINT_LABEL
                  DP_PERIOD = "TIME PERIOD*FOR COHEN'S D*ANALYSIS"
                  %DPREGION_PRINT_LABEL
                  DP_REGION = "REGION FOR*COHEN'S D*ANALYSIS"
                  DP_PURCHASER = "PURCHASER*FOR COHEN'S D*ANALYSIS*(&DP_PURCHASER)";
            TITLE4 "NET PRICE CALCULATIONS AND PURCHASER/TIME/REGION ASSIGNMENTS FOR COHEN'S D";
        RUN;

    /*----------------------------------------------------------*/
    /*  Calculate Information Using Comparable Merchandise        */
    /*    Criteria for Cohen's d.                                    */
    /*----------------------------------------------------------*/

    PROC SORT DATA = DPSALES (KEEP=&USCONNUM DP_NETPRI 
                                   &USQTY DP_REGION DP_PURCHASER DP_PERIOD DP_COUNT);
           BY &USCONNUM;
    RUN;

    PROC MEANS DATA = DPSALES NOPRINT VARDEF=WEIGHT;
        BY &USCONNUM;
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
        SUM TOTAL_CONNUM_QTY TOTAL_CONNUM_VALUE;
        TITLE4 "OVERALL STATISTICS FOR EACH CONTROL NUMBER (ALL SALES--NO SEPARATION OF TEST AND BASE GROUP VALUES)";
    RUN;

    /*--------------------------------------------------------------*/
    /* STAGE 1: Test Control Numbers by Region, Time and Purchaser    */
    /*--------------------------------------------------------------*/

        %MACRO COHENS_D(DP_GROUP,TITLE4);

            /*----------------------------------------------------------*/
            /*  Put sales to be tested for each round in                */
            /*    DPSALES_TEST. (All sales will remain in DPSALES.) Sales */
            /*    missing group information will not be tested, but will     */
            /*    be kept in the pool for purposes of    calculating base     */
            /*    group statistics.                                        */
            /*----------------------------------------------------------*/

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

            /*----------------------------------------------*/
            /*  Calculate test group information.            */
            /*----------------------------------------------*/

            TITLE4 " &TITLE4 ";

            PROC SORT DATA = DPSALES_TEST;
                   BY &USCONNUM &DP_GROUP;
            RUN;

            PROC MEANS DATA = DPSALES_TEST NOPRINT VARDEF=WEIGHT ;
                BY &USCONNUM &DP_GROUP;
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
                BY &USCONNUM;
                ID &USCONNUM;
                LABEL     &USCONNUM="CONTROL NUMBER"
                        &DP_GROUP="TEST*GROUP*(&DP_GROUP.)"
                        TEST_&DP_GROUP._OBS="TRANSACTIONS*  IN  *TEST GROUP"
                        TEST_&DP_GROUP._QTY="TOTAL QTY*  OF  *TEST GROUP"
                        TEST_&DP_GROUP._VALUE="TOTAL VALUE*  OF  *TEST GROUP" 
                        TEST_AVG_&DP_GROUP._PRICE="WT AVG PRICE*  OF  *TEST GROUP"
                        TEST_&DP_GROUP._STD="STANDARD*DEVIATION*TEST GROUP*PRICE";
                TITLE5 "CALCULATION OF TEST GROUP STATISTICS BY &DP_GROUP";
            RUN;

            /*--------------------------------------------------------------*/
            /*  Attach overall control number information to                 */
            /*    each test group. Then separate base v. test group             */
            /*    information re: value, quantity, observations, etc.  For     */
            /*    example, if there are three purchasers (A,B and C), when     */
            /*    purchaser A is in the test group, purchasers B and C will    */
            /*    be the base/comparison group.                                */
            /*                                                                */
            /*    If there is no base group for a control number because all     */
            /*    sales are to one purchaser, for example, (as evidenced by     */
            /*    zero obs/quantity) then no Cohen's d coefficient will be     */
            /*    calculated.                                                    */
            /*--------------------------------------------------------------*/

            DATA DPGROUP NO_BASE_GROUP;  
                MERGE &DP_GROUP (IN=A) DPCONNUM (IN=B);
                BY &USCONNUM;
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
                BY &USCONNUM;
                ID &USCONNUM;
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

            /*---------------------------------------------------------------*/
            /*  Attach sales of base group control numbers to                 */
            /*    group-level information calculated above.  In the example of */
            /*    three purchasers (A,B&C), when the DP_GROUP = A above, all      */
            /*    sales to purchasers B&C will be joined. (See the condition      */
            /*    DP_GROUP NE BASE_GROUP in the BASECALC dataset below.)         */
            /*---------------------------------------------------------------*/

            DATA BASE_PRICES;
                SET DPSALES (KEEP=&USCONNUM &DP_GROUP DP_NETPRI &USQTY);
                    RENAME     &USCONNUM = BASE_CONNUM
                            &DP_GROUP = BASE_GROUP;
            RUN;
                            
            DATA BASECALC;
                SET DPGROUP;
                DO J=1 TO LAST;
                SET BASE_PRICES POINT=J NOBS=LAST;
                    IF     &USCONNUM = BASE_CONNUM AND
                        &DP_GROUP NE BASE_GROUP THEN 
                    DO;
                        OUTPUT BASECALC;
                    END;
                END;
            RUN; 

            /*-----------------------------------------------*/
            /*  Calculate the base group standard deviation. */ 
            /*----------------------------------------------*/

            PROC SORT DATA = BASECALC;
                BY &USCONNUM &DP_GROUP;
            RUN;

            PROC MEANS NOPRINT DATA = BASECALC VARDEF = WEIGHT;
                BY &USCONNUM &DP_GROUP;
                WEIGHT &USQTY;
                VAR DP_NETPRI;
                OUTPUT OUT = BASESTD (DROP=_FREQ_ _TYPE_) STD = BASE_STD;
            RUN;

            PROC PRINT DATA = BASESTD (OBS=&PRINTOBS) SPLIT="*";
                BY &USCONNUM;
                ID &USCONNUM;
                VAR &DP_GROUP BASE_STD;
                LABEL     &USCONNUM="CONTROL NUMBER"
                        &DP_GROUP="TEST GROUP*(&DP_GROUP.)"
                        BASE_STD="STANDARD DEVIATION*IN PRICE*OF BASE GROUP";
                TITLE5 "CALCULATION OF BASE GROUP STANDARD DEVIATIONS BY &DP_GROUP";
            RUN; 

            PROC SORT DATA = DPGROUP;
                BY &USCONNUM &DP_GROUP;
            RUN;

            DATA &DP_GROUP._RESULTS;
                MERGE DPGROUP (IN=A) BASESTD (IN=B);
                BY &USCONNUM &DP_GROUP;
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
                            ELSE IF FUZZ(BASE_AVG_&DP_GROUP._PRICE - TEST_AVG_&DP_GROUP._PRICE) ^= 0  
                                THEN &DP_GROUP._RESULT = "Pass"; 

                        END;
                    END;
                END;
            RUN;

            PROC SORT DATA=&DP_GROUP._RESULTS;
                BY &DP_GROUP &USCONNUM;
            RUN;

            PROC PRINT DATA=&DP_GROUP._RESULTS (OBS=&PRINTOBS) SPLIT="*";
                BY &DP_GROUP;
                ID &DP_GROUP;
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

            /*------------------------------------------------*/
            /*  Merge results into U.S. sales data. Sales are */
            /*    flagged as either passing or not passing.     */
            /*------------------------------------------------*/

            PROC SORT DATA = DPSALES;
                BY &DP_GROUP &USCONNUM;
            RUN;

            DATA DPSALES DPSALES_PASS_&DP_GROUP;
                MERGE DPSALES (IN=A) &DP_GROUP._RESULTS (IN=B KEEP=&DP_GROUP &USCONNUM &DP_GROUP._RESULT);
                BY &DP_GROUP &USCONNUM;
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
 
    /*---------------------------------------------------*/
    /* Execute Stage 1: Cohen's d Test for region, time, */
    /* then purchaser                                    */
    /*---------------------------------------------------*/

    %COHENS_D(DP_REGION,FIRST PASS: ANALYSIS BY REGION)
    %COHENS_D(DP_PERIOD,SECOND PASS: ANALYSIS BY TIME PERIOD)
    %COHENS_D(DP_PURCHASER,THIRD AND FINAL PASS: ANALYSIS BY PURCHASER)

    /*---------------------------------------------------------------*/
    /* Stage 2: Calculate Ratios of Sales Passing the Cohen's d Test */
    /*---------------------------------------------------------------*/

        /*----------------------------------------------------------*/
        /* Sales that pass any of the three rounds of the Cohen's d    */
        /* analysis pass the test as a whole.                        */
        /*----------------------------------------------------------*/

        DATA DPSALES DPPASS (KEEP=DP_COUNT COHENS_D_PASS);
            SET DPSALES;
            FORMAT COHENS_D_PASS $3.;
            COHENS_D_PASS = "No";
            IF    DP_PURCHASER_RESULT  = "Pass" OR   
                DP_REGION_RESULT = "Pass" OR
                DP_PERIOD_RESULT = "Pass" 
            THEN COHENS_D_PASS = "Yes";
        RUN;

        PROC SORT DATA = DPSALES;
            BY &USCONNUM DP_PERIOD DP_REGION DP_PURCHASER;
        RUN;

        DATA DPSALES_PRINT;
            SET DPSALES;
            BY &USCONNUM DP_PERIOD DP_REGION DP_PURCHASER;
            IF FIRST.&USCONNUM OR FIRST.DP_PERIOD OR FIRST.DP_REGION OR FIRST.DP_PURCHASER   
            THEN OUTPUT DPSALES_PRINT;
        RUN;

        PROC SORT DATA = DPSALES_PRINT;
            BY COHENS_D_PASS &USCONNUM;
        RUN;

        DATA DPSALES_PRINT (DROP=COUNT);
            SET DPSALES_PRINT;
            BY COHENS_D_PASS &USCONNUM;
            IF FIRST.COHENS_D_PASS THEN COUNT = 1;
            COUNT + 1;
            IF COUNT LE &PRINTOBS THEN OUTPUT;
        RUN;

        PROC PRINT DATA = DPSALES_PRINT;
            ID COHENS_D_PASS;
            BY COHENS_D_PASS;
            VAR &USCONNUM 
                DP_PERIOD DP_REGION DP_PURCHASER DP_PERIOD_RESULT 
                DP_REGION_RESULT DP_PURCHASER_RESULT;
            TITLE4 "SAMPLE OF &PRINTOBS FOR EACH TYPE OF RESULT FROM THE COHEN'S-D ANALYSIS FOR";
            TITLE5 "UNIQUE COMBINATIONS OF REGION, PURCHASER AND TIME PERIOD FOR EACH CONTROL NUMBER";
        RUN;

        /*------------------------------------------------------------------*/
        /* Calculate the percentage of sales that pass the Cohen's d Test    */
        /*------------------------------------------------------------------*/

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
            FOOTNOTE1 "If some sales pass the Cohen's d Test and others do not pass, then three methods will be calculated:";
            FOOTNOTE2 "1) the Standard Method (applied to all sales), 2) the A-to-T Alternative Method (applied to all sales)";
            FOOTNOTE3 "3) and the Mixed Alternative Method which will be a combination of the A-to-A (with offsets)";
            FOOTNOTE4 "applied to sales that did not pass, and A-to-T (without offsets) applied to sales that did pass.";
            FOOTNOTE6 "If either no sale or all sales pass the Cohen's d Test, then the Mixed Alternative Method will yield the same";
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

%MEND COHENS_D_TEST;

%COHENS_D_TEST

/*ep*/

/*------------------------------------*/
/* PART 12: WEIGHT AVERAGE U.S. SALES */
/*------------------------------------*/

/*---------------------------------------------------------------------------*/
/*    Weight-average U.S. prices and adjustments and merge averaged data         */
/*    back onto the single-transaction database. The averaged variables will     */
/*    have the same names as the un-averaged ones, but with a suffix added.     */
/*    For the Standard Methodology, the suffix will be "_MEAN." For the         */
/*    Mixed Alternative Methodology, the suffix will be "_MIXED." For example, */
/*    the averaged versions of USNETPRI will be USNETPRI_MEAN for the          */
/*    Standard Methodology and USNETPRI_MIXED for the Mixed Alternative          */
/*    Methodology. Both the single-transaction and weight-averaged values      */
/*    will be in the data.  In the RESULTS macro below, the appropriate          */
/*    selection of the weight-averaged v single-transaction values will occur. */
/*---------------------------------------------------------------------------*/

/*----------------------------------------------*/
/* WEIGHT AVERAGING OF U.S. SALES DATA          */
/*----------------------------------------------*/

%MACRO WT_AVG_DATA;

    /*------------------------------------------------------------------*/
    /*    Create macro variables to keep required variables and            */
    /*    determine the weight averaging pools for U.S. sales.             */ 
    /*                                                                    */
    /*    The macro variables AR_VARS and AR_BY_VARS will contain lists     */
    /*    of additional variables needed for weight-averaging and         */
    /*    assessment purposes in administrative reviews.                  */    
    /*                                                                    */
    /*    For    administrative reviews, the weight-averaging pools will         */
    /*    also be defined by month for cash deposit calculations.  To do     */
    /*    this, the macro variable AR_BY_VARS will be used in the BY      */
    /*    statements that will either be set to a blank value for          */
    /*    investigations or the US month variable in admin. reviews.        */
    /*                                                                    */
    /*    When the Cohen's d Test determines that the Mixed Alternative    */
    /*    Method is to be used, then the DP_COUNT and COHENS_D_PASS        */
    /*    macro variabes will be to the variables by the same names in     */
    /*    order to keep track of which observations passed Cohen's d and    */
    /*    which did not.  Otherwise, the DP_COUNT and COHENS_D_PASS macro    */
    /*    variables will be set to null values.  In addition, the         */
    /*    MIXED_BY_VAR macro variable will be set to COHENS_D_PASS in     */
    /*    order to allow the weight-averaging to be constricted to within */
    /*    just sales passing the Cohen's d test.                            */
    /*                                                                    */
    /*    When an assessment calculation is warranted, the section will     */
    /*    be re-executed on an importer-specific basis.  This is done by    */
    /*    adding the IMPORTER variables to the BY statements.                */ 
    /*------------------------------------------------------------------*/

    %GLOBAL AR_VARS AR_BY_VARS TITLE4_WTAVG TITLE4_MCALC DP_COUNT COHENS_D_PASS ;

    %IF %UPCASE(&CASE_TYPE) = INV %THEN
    %DO;

        %LET AR_VARS = ; 
        %LET AR_BY_VARS = ;
        %LET TITLE4_WTAVG = "CONTROL NUMBER AVERAGING CALCULATIONS FOR CASH DEPOSIT PURPOSES";  /* For Wt.Avg. */
        %LET TITLE4_MCALC = "CALCULATIONS FOR CASH DEPOSIT PURPOSES";                           /* For results calcs */
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

            PROC SORT DATA = USPRICES;
                BY DP_COUNT;
            RUN;

            PROC SORT DATA = DPPASS;
                BY DP_COUNT;
            RUN;

            DATA USPRICES;
                MERGE USPRICES (IN=A) DPPASS (IN=B);
                BY DP_COUNT;
                IF A & B;
            RUN;
    %END;
    %ELSE
    %DO;
        %LET DP_COUNT = ;
        %LET COHENS_D_PASS = ;
    %END;

    /*------------------------------------*/
    /* SAVE USPRICES DATASET FOR ANALYSIS */
    /*------------------------------------*/

    PROC DATASETS NOLIST;
        COPY IN = WORK OUT = COMPANY;
        SELECT USPRICES;
    QUIT;

    /*--------------------------------------------------------------*/
    /*    Keep variables required for rest of calculations.            */
    /*--------------------------------------------------------------*/

    PROC SORT DATA = USPRICES 
        (KEEP =  USOBS &USMON SALEU &USCONNUM &USQTY USNETPRI NV
                &AR_VARS &DP_COUNT &COHENS_D_PASS)
        OUT = USNETPR;
        BY SALEU &USCONNUM &AR_BY_VARS &COHENS_D_PASS;
    RUN;

    /*------------------------------------------------------------------*/
    /*    Weight-average U.S. prices and adjustments. The averaged         */
    /*    variables for the Standard Method with have "_MEAN" added         */
    /*    to the end of their original names as a suffix.                 */
    /*                                                                    */
    /*    When the Mixed Alternative Method is employed, an extra            */
    /*    weight-averaging will be done that additionally includes the     */
    /*    COHENS_D_PASS variable in the BY statement.  This will allow     */
    /*    sales not passing the Cohen's d Test to be weight-averaged         */
    /*    separately from those that did pass. Weight-averaged amounts     */
    /*    will have "_MIXED" added to the end of their original names.    */
    /*------------------------------------------------------------------*/

    %MACRO WEIGHT_AVERAGE(NAMES,DP_BYVAR);

        PROC MEANS NOPRINT DATA = USNETPR;
            BY SALEU &USCONNUM &AR_BY_VARS &DP_BYVAR;
            VAR USNETPRI;
            WEIGHT &USQTY;
            OUTPUT OUT=USAVG (DROP=_FREQ_ _TYPE_) MEAN = &NAMES;
        RUN;

        DATA USNETPR;
            MERGE USNETPR (IN=A) USAVG (IN=B);
            BY SALEU &USCONNUM &AR_BY_VARS &DP_BYVAR;
        RUN;

    %MEND WEIGHT_AVERAGE;

        /*------------------------------------------------------*/
        /*    Execute WEIGHT_AVERAGE macro for Cash Deposit Rate    */
        /*------------------------------------------------------*/

        %IF &CASH_DEPOSIT_DONE = NO  %THEN
        %DO;
            %LET TITLE5 =;
            %LET TITLE6 =;
            %WEIGHT_AVERAGE(/AUTONAME, )
    
            %IF &CALC_METHOD = MIXED %THEN
            %DO;
                    %LET TITLE5 = "AVERAGED VARIABLES ENDING IN '_MEAN' TO BE USED WITH THE STANDARD METHOD"; 
                    %LET TITLE6 = "THOSE ENDING IN '_MIXED' WITH SALES NOT PASSING COHEN'S D WITH THE MIXED ALTERNATIVE METHOD.";
                    %WEIGHT_AVERAGE(USNETPRI_MIXED,COHENS_D_PASS)
            %END;
        %END;

        /*------------------------------------------------------*/
        /*    Execute WEIGHT_AVERAGE macro for Assessment            */
        /*------------------------------------------------------*/

        %IF &CASH_DEPOSIT_DONE = YES  %THEN
        %DO;

            /*----------------------------------------------------------*/
            /*    Weight-average variables for assessments                  */
            /*    using the Standard Method only if the Standard-             */
            /*    Method Cash Deposit rate is above de minimis.            */
            /*----------------------------------------------------------*/
            %IF &ABOVE_DEMINIMIS_STND = YES %THEN
            %DO;
                %LET TITLE5 =;
                %LET TITLE6 =;
                %WEIGHT_AVERAGE(/AUTONAME, )
            %END;

            /*----------------------------------------------------------*/
            /*    Weight-average variables for assessments                  */
            /*    using the Mixed Alternative Method, if required.        */
            /*----------------------------------------------------------*/
    
            %IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
            %DO;
                    %LET TITLE5 = "AVERAGED VARIABLES ENDING IN '_MEAN' TO BE USED WITH THE STANDARD METHOD"; 
                    %LET TITLE6 = "THOSE ENDING IN '_MIXED' WITH SALES NOT PASSING COHEN'S D WITH THE MIXED ALTERNATIVE METHOD.";
                    %WEIGHT_AVERAGE(USNETPRI_MIXED,COHENS_D_PASS)
            %END;
        %END;

    PROC PRINT DATA = USNETPR (OBS=&PRINTOBS);
        TITLE3 'SAMPLE OF WEIGHT-AVERAGED VALUES MERGED WITH SINGLE-TRANSACTION U.S. DATA';
        TITLE4 &TITLE4_WTAVG;
        TITLE5 &TITLE5;
        TITLE6 &TITLE6;
    RUN;

%MEND WT_AVG_DATA;

%WT_AVG_DATA

/*ep*/

/*-----------------------------*/
/* PART 13: COMPARISON RESULTS */
/*-----------------------------*/

/*--------------------------------------------------------------------------*/
/*  CALCULATE COMPARISON RESULTS USING THE STANDARD                         */
/*            METHODOLOGY, THE A-2-T ALTERNATIVE METHODOLOGY AND, WHEN        */
/*            REQUIRED, THE MIXED ALTERNATIVE METHODOLOGY.                    */
/*                                                                            */
/*    STANDARD METHODOLOGY:                                                    */
/*        - Use weight-averaged U.S. prices, offsetting positive comparison    */
/*          results with negative ones, for all sales.                         */
/*    MIXED ALTERNATIVE METHODOLOGY                                            */
/*        - A rate calculated by using single-transaction prices without         */
/*          offsetting on sales that pass the Cohen's-d Test, and weight-        */
/*          averaged U.S. prices with offsetting on sales not passing.        */
/*    A-2-T ALTERNATIVE METHODOLOGY                                            */
/*        - Use single-transaction U.S. prices without offsetting positive     */
/*          comparison results with negative ones on all sales.                */
/*                                                                            */
/*    Compare U.S. price to NV to calculate the transaction-specific            */
/*    comparison results.  (Note, no offsetting of positive comparison         */
/*    results with negatives is done at this point.)  The resulting databases */
/*    are called:                                                                */
/*                                                                            */
/*        - _AVGMARG for the Standard                                             */    
/*                Methodology on the full U.S. sales database                    */
/*        - _AVGMIXED for the portion of sales                                 */
/*                being calculated with the Standard Methodology as part of    */
/*                the Mixed Alternative Methodology.                            */
/*        - _TRNMIXED for the portion of sales                                */
/*                being calculated with the A-2-T Alternative Methodology        */
/*                as part of the Mixed Alternative Methodology.                */ 
/*        - _TRANMARG for the A-2-T Alternative                                */
/*                Methodology on the full U.S. sales database.                */    
/*                                                                            */
/*    Variables with "&SUFFIX" added to their names in the programming will      */
/*    have two or three values in the database: 1) the non-averaged/single-    */
/*     transaction value when &SUFFIX is a blank space (e.g., USPACK&SUFFIX      */
/*    becomes USPACK), 2) the weight-averaged value when &SUFFIX=_MEAN         */
/*    (e.g., USPACK&SUFFIX becomes USPACK_MEAN) for the Standard Methodology, */
/*    and sometimes 3) the weight-averaged value when &SUFFIX=_MIXED (e.g.,      */
/*    USPACK&SUFFIX becomes USPACK_MIXED) for the Mixed Alternative            */
/*    Methodology.  The selection of averaged v non-averaged values is done     */
/*    automatically.                                                            */
/*                                                                            */
/*--------------------------------------------------------------------------*/

/*----------------------------------------------------------------------*/
/*    For variables with the macro variable SUFFIX added to their names,    */
/*    weight-averaged values will be used when SUFFIX = _MEAN or _MIXED,    */
/*    but single-transaction values will be used when the suffix is a     */
/*    blank space. For example, USNETPRI will be used in calculating the     */
/*    Alternative Method, USNETPRI_MEAN for the Standard Method             */
/*    and USNETPRI_MIXED with the sales not passing Cohen's d for the     */
/*    Mixed Alternative Method.                                            */
/*                                                                        */
/*    For purposes of calculting the initial cash deposit rate, the         */
/*    IMPORTER macro variable will be set to a blank space and not enter    */ 
/*    into the calculations.  When an assessment calculation is warranted,*/
/*    the section will be re-executed on an importer-specific basis by     */
/*    setting the IMPORTER macro variable to IMPORTER.                    */
/*----------------------------------------------------------------------*/

%MACRO RESULTS; 

    %MACRO CALC_RESULTS(METHOD,CALC_TYPE,IMPORTER,OUTDATA,SUFFIX);

    /*------------------------------------------------------*/
    /*    Set up macros for this section.                        */
    /*------------------------------------------------------*/

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
                %LET TITLE5 = "MIXED ALTERNATIVE METHOD PART 1: A-to-A APPLIED TO SALES NOT PASSING COHEN'S D USING VALUES ENDING WITH SUFFIX '_MIXED'";
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
                %LET TITLE5 = ALTERNATIVE METHOD APPLIED TO ALL U.S. SALES;
                %MACRO IF_COHEN;
                %MEND IF_COHEN;
            %END;
            %IF &CALC_TYPE = MIXED %THEN
            %DO;
                %LET TITLE5 = "MIXED ALTERNATIVE METHOD PART 2: A-to-T APPLIED TO SALES PASSING COHEN'S D TEST";
                %MACRO IF_COHEN;
                        IF COHENS_D_PASS = "Yes";
                %MEND IF_COHEN;
            %END;
        %END;

    /*----------------------------------------------------------*/
    /*    Calculate Results                                        */
    /*----------------------------------------------------------*/

        DATA COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA NONVMARG_&OUTDATA; 
            SET USNETPR;
                %IF_COHEN
                UMARGIN = NV - USNETPRI&SUFFIX;
                EMARGIN = UMARGIN * &USQTY;
                USVALUE = USNETPRI&SUFFIX * &USQTY;
                PCTMARG = UMARGIN / USNETPRI&SUFFIX * 100;
                IF UMARGIN = . OR NV = . OR USNETPRI&SUFFIX = . 
                THEN OUTPUT NONVMARG_&OUTDATA; 
                ELSE OUTPUT COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA;
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

    /*--------------------------------------------------------------*/
    /*        Keep variables needed for remaining calculations and    */
    /*        put them in the database SUMMARG_<OUTDATA>.    The         */
    /*        SUMMARG_<OUTDATA> dataset does not contain any            */
    /*        offsetting information.    <OUTDATA> will be as follows    */
    /*                                                                */
    /*        AVGMARG:  Cash Deposit, Standard Method                    */
    /*        AVGMIXED: Cash Deposit, sales not passing Cohen's d for    */
    /*                  Mixed Alternative Method                        */
    /*        TRNMIXED: Cash Deposit, sales passing Cohen's d for        */    
    /*                  Mixed Alternative Method                        */
    /*        TRANMARG: Cash Deposit, A-to-T Alternative Method        */
    /*                                                                */
    /*        IMPSTND:  Assessment, Standard Method                    */
    /*        IMPCSTN:  Assessment, sales not passing Cohen's d for    */
    /*                  Mixed Alternative Method                        */    
    /*        IMPCTRN:  Assessment, sales passing Cohen's d for Mixed    */    
    /*                  Alternative Method                            */
    /*        IMPTRAN:  Assessment, A-to-T Alternative Method            */
    /*--------------------------------------------------------------*/

        PROC SORT DATA = COMPANY.&RESPONDENT._&SEGMENT._&STAGE._&OUTDATA 
            OUT = SUMMARG_&OUTDATA 
            (KEEP =    USOBS &USCONNUM &AR_BY_VARS NV
                    &USQTY USNETPRI&SUFFIX USVALUE PCTMARG  
                    EMARGIN UMARGIN SALEU &AR_VARS &COHENS_D_PASS);
            BY SALEU DESCENDING PCTMARG;
        RUN;

    %MEND CALC_RESULTS;

    /*----------------------------------------------------------*/
    /*    Execute the CALC_RESULTS macro for the appropriate        */
    /*    scenario(s).                                            */
    /*----------------------------------------------------------*/

        /*--------------------------------------------------------------*/
        /*    Cash deposit calculations.                                    */
        /*                                                                */
        /*    In all cases, the CALC_RESULTS macro will be executed using    */
        /*    the Standard Method and the A-to-T Alternative                 */
        /*    Method for the Cash Deposit Rate.  If there is a             */
        /*    mixture of sales pass and not passing Cohen's d, then the     */
        /*    CALC_RESULTS macro will be executed a third time using the     */
        /*    Mixed Alternative Method.                                    */ 
        /*                                                                */
        /*    The ABOVE_DEMINIMIS_STND, ABOVE_DEMINIMIS_MIXED and         */
        /*    ABOVE_DEMINIMIS_ALT macro variables were set to "NO" by        */
        /*    default above in US13.  They remains "NO" through the         */
        /*    calculation of the Cash Deposit rate(s). If a particular    */
        /*    Cash Deposit rate is above de minimis, its attendant macro     */
        /*    variable gets changed to "YES" to allow for its assessment  */
        /*    calculation in reviews in Sect 15-E-ii below.                 */
        /*                                                                */
        /*    If the Mixed Alternative Method is not being                 */
        /*    calculated because all sales either did or did not pass the */
        /*    Cohen's d Test, then ABOVE_DEMINIMIS_MIXED is set to "NA".    */
        /*--------------------------------------------------------------*/

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

        /*--------------------------------------------------------------*/
        /*    Assessment Calculations (Reviews Only).                        */
        /*                                                                */
        /*    For each Method for which its Cash Deposit rate is             */
        /*    above de minimis, calculate information for importer-        */
        /*    specific assessment rates.                                     */
        /*--------------------------------------------------------------*/

        %IF %UPCASE(&CASE_TYPE)= AR %THEN
        %DO;

            %IF &CASH_DEPOSIT_DONE = YES %THEN
            %DO;
                %LET ASSESS_TITLE = "IMPORTER-SPECIFIC CALCULATIONS FOR ASSESSMENT PURPOSES";
                %IF &ABOVE_DEMINIMIS_STND = YES %THEN
                %DO;
                    %CALC_RESULTS(STANDARD,STANDARD,IMPORTER,IMPSTND,_MEAN)
                %END;
                %IF &ABOVE_DEMINIMIS_MIXED = YES %THEN
                %DO;
                    %CALC_RESULTS(STANDARD,MIXED,IMPORTER,IMPCSTN,_MIXED)
                    %CALC_RESULTS(ALTERNATIVE,MIXED,IMPORTER,IMPCTRN, )
                %END;
                %IF &ABOVE_DEMINIMIS_ALT = YES %THEN
                %DO;
                    %CALC_RESULTS(ALTERNATIVE,ALTERNATIVE,IMPORTER,IMPTRAN, )
                %END;
            %END;

        %END;

%MEND RESULTS; 

%RESULTS

/*ep*/

/*-------------------------------------------*/
/* PART 14: CORROBORATE THE PETITION MARGIN. */
/*-------------------------------------------*/

%MACRO CORROBORATE;
    %MACRO CALC_CORROBORATE(OUTDATA, TITLE4);

    DATA POSCORROB_&OUTDATA;
        SET SUMMARG_&OUTDATA (KEEP = PCTMARG USVALUE &USQTY);
        IF PCTMARG GT 0;
        PERCENT = &PERCENT;

        IF PCTMARG GT &PERCENT THEN
            FLAG = 'ABOVE';
        ELSE
            FLAG = 'BELOW';
    RUN;

    PROC SORT DATA = POSCORROB_&OUTDATA OUT = POSCORROB_&OUTDATA;
        BY FLAG;
    RUN;

    PROC PRINT DATA = POSCORROB_&OUTDATA (OBS = &PRINTOBS);
        FORMAT PCTMARG PERCENT COMMA8.2;
        TITLE3 "MARGIN CORROBORATION BUILDUP";
        TITLE4 "SAMPLE OF POSITIVE COMPARISON RESULTS COMPARED TO THE PETITION RATE";
        TITLE4 "USING THE &TITLE4 METHOD";
    RUN;

    PROC MEANS NOPRINT DATA = POSCORROB_&OUTDATA;
        ID PERCENT;
        BY FLAG;
        VAR USVALUE &USQTY;
        OUTPUT OUT = CORROB_&OUTDATA (DROP = _FREQ_ _TYPE_)
               SUM = TOTFLAGVAL TOTFLAGQTY N = TOTMODS;
    RUN;

    PROC MEANS NOPRINT DATA = POSCORROB_&OUTDATA;
        VAR USVALUE &USQTY;
        OUTPUT OUT = CORROB1_&OUTDATA (DROP = _FREQ_ _TYPE_)
               SUM = SUMVAL SUMQTY N = SUMMODS;
    RUN;

    DATA CORROB_&OUTDATA;
        SET CORROB_&OUTDATA;
        IF _N_ = 1 THEN
            SET CORROB1_&OUTDATA;

        PCTVAL = TOTFLAGVAL / SUMVAL * 100;
        PCTQTY = TOTFLAGQTY / SUMQTY * 100;
        PCTMODS = TOTMODS / SUMMODS * 100;
    RUN;

    PROC PRINT DATA = CORROB_&OUTDATA;
        VAR PERCENT FLAG TOTMODS PCTMODS TOTFLAGQTY PCTQTY
            TOTFLAGVAL PCTVAL;
        FORMAT TOTMODS COMMA9. TOTFLAGQTY COMMA15.2 TOTFLAGVAL DOLLAR15.2
               PERCENT PCTMODS PCTQTY PCTVAL COMMA8.2;
        SUM TOTMODS PCTMODS TOTFLAGQTY PCTQTY TOTFLAGVAL PCTVAL;
        TITLE3 "MARGIN CORROBORATION RESULTS";
        TITLE4 "USING THE &TITLE4 METHOD";
    RUN;
    %MEND CALC_CORROBORATE;

    %CALC_CORROBORATE(AVGMARG, STANDARD)
    %IF  &CALC_METHOD NE STANDARD %THEN
    %DO;
        %CALC_CORROBORATE(TRANMARG, ALTERNATIVE)
        %IF  &CALC_METHOD = MIXED %THEN
        %DO;
            DATA SUMMARG_MIXED;
                SET SUMMARG_AVGMIXED SUMMARG_TRNMIXED;
            RUN;
            %CALC_CORROBORATE(MIXED, MIXED ALTERNATIVE)
        %END;
    %END;
%MEND CORROBORATE;

%CORROBORATE

/*ep*/

/*-----------------------------------------------------------------*/
/* PART 15: PRINT SAMPLES OF HIGHEST AND LOWEST COMPARISON RESULTS */
/*-----------------------------------------------------------------*/

%MACRO PRINT_HIGH_LOW;
    %MACRO HIGH_LOW(OUTDATA, SUFFIX, TITLE4);

    /*----------------------------------------------*/
    /* PRINT SAMPLES OF HIGHEST COMPARISON RESULTS. */
    /*----------------------------------------------*/

    PROC SORT DATA = SUMMARG_&OUTDATA OUT = SUMMARG_&OUTDATA;
        BY SALEU DESCENDING PCTMARG;
    RUN;

    DATA HIGHEST_SAMPLE_&OUTDATA;
        SET SUMMARG_&OUTDATA;
           BY SALEU;
        RETAIN HIGHNUM;
           DROP HIGHNUM;
        
        IF FIRST.SALEU THEN
            HIGHNUM = 1;

        IF (PCTMARG GT 0) AND (HIGHNUM LE &PRINTOBS) THEN
        DO;
               OUTPUT HIGHEST_SAMPLE_&OUTDATA;
            HIGHNUM + 1;
        END;
    RUN;

    PROC PRINT DATA = HIGHEST_SAMPLE_&OUTDATA;
           BY SALEU;
        VAR USOBS &USCONNUM &AR_BY_VARS NV 

        %IF &OUTDATA = MIXED %THEN
        %DO;
            USNETPRI
        %END;

            USNETPRI&SUFFIX UMARGIN &USQTY EMARGIN USVALUE PCTMARG;
           TITLE3 "SAMPLE OF HIGHEST COMPARISON RESULTS BY SALE TYPE";
        TITLE4 "USING THE &TITLE4 METHOD";
    RUN;
    /*---------------------------------------------*/
    /* PRINT SAMPLES OF LOWEST COMPARISON RESULTS. */
    /*---------------------------------------------*/

    PROC SORT DATA = SUMMARG_&OUTDATA OUT = SUMMARG_&OUTDATA;
           BY SALEU PCTMARG;
    RUN;

    DATA LOWEST_SAMPLE_&OUTDATA;
           SET SUMMARG_&OUTDATA;
           BY SALEU;
           RETAIN LOWNUM;
           DROP LOWNUM;

        IF FIRST.SALEU THEN
               LOWNUM = 1;

        IF LOWNUM LE &PRINTOBS THEN
        DO;
               OUTPUT LOWEST_SAMPLE_&OUTDATA;
            LOWNUM + 1;
           END;
    RUN;

    PROC PRINT DATA = LOWEST_SAMPLE_&OUTDATA;
        VAR USOBS &USCONNUM &AR_BY_VARS NV 

        %IF &OUTDATA = MIXED %THEN
        %DO;
            USNETPRI
        %END;

            USNETPRI&SUFFIX UMARGIN &USQTY EMARGIN USVALUE PCTMARG;
           TITLE3 "SAMPLE OF LOWEST COMPARISON RESULTS BY SALE TYPE";
        TITLE4 "USING THE &TITLE4 METHOD";
           BY SALEU;
    RUN;

    %MEND HIGH_LOW;

    %HIGH_LOW(AVGMARG, _MEAN, STANDARD)
    %IF  &CALC_METHOD NE STANDARD %THEN
    %DO;
        %HIGH_LOW(TRANMARG, , ALTERNATIVE)
        %IF  &CALC_METHOD = MIXED %THEN
        %DO;
            DATA SUMMARG_MIXED;
                SET SUMMARG_AVGMIXED SUMMARG_TRNMIXED;
            RUN;
            %HIGH_LOW(MIXED, _MIXED, MIXED ALTERNATIVE)
        %END;
    %END;
%MEND PRINT_HIGH_LOW;

%PRINT_HIGH_LOW

/*ep*/

/*-----------------------------*/
/* PART 16: CASH DEPOSIT RATES */
/*-----------------------------*/

/*--------------------------------------------------------------------------*/
/*    Calculate Cash Deposit Rates based upon the Standard, Mixed    Alternative    */
/*    (when required) and A-2-T Alternative Methodologies.                    */
/*                                                                            */
/*    For the Standard Methodology, calculated amounts from the database        */
/*    _AVGMARG will be used. Positive                                            */
/*    comparison results will be offset by negatives on all sales.            */
/*                                                                            */
/*    The Mixed Alternative Methodology will be a combination calculation.     */
/*    Sales that passed the Cohen's-d Test will be calculated using the        */
/*    _TRNMIXED database.  No offsetting of                                    */
/*    positive comparison results with negatives will be done on these sales.    */
/*    Sales that did not pass the Test will be calculated using the             */
/*    _AVGMIXED database in which these sales                                    */
/*    were weight averaged separately from those that did pass the test.         */
/*    Positive comparison results will be offset by negatives on these sales.    */
/*                                                                            */
/*    Cash Deposit Rate using the A-2-T Alternative Methodology for all sales    */
/*    will be calculated using the _TRANMARG                                    */
/*    database. No offsetting of positive comparison results with negatives.    */
/*--------------------------------------------------------------------------*/

/*------------------------------------------------------------------*/
/* CALCULATE CASH DEPOSIT RATE                                        */
/*------------------------------------------------------------------*/

%MACRO CALCULATE_CASH_DEPOSIT;

    /*------------------------------------------------------------------*/
    /*    The Standard Method will employed on all U.S. sales                */
    /*    regardless of the results of the Cohen's d Test.  Also, the     */
    /*    A-to-T Alternative Method will also be used on all sales to     */
    /*    calculate a second Cash Deposit rate.                            */
    /*                                                                    */
    /*    When there are both sales that pass and do not pass Cohen's d,  */
    /*    a Mixed Alternative Cash Deposit rate (in addition to the rates */
    /*    based on the Standard and A-to-T Alternative Methods) will be    */
    /*    calculated using a mixture of A-to-A (with offsets) and A-to-T     */
    /*    (without offsets). To calculate the Mixed rate, the A-to-A         */
    /*    Method will be employed on sales not passing the Cohen's d         */
    /*    Test, the A-to-T Method on the rest and then then two results    */
    /*    will be aggregated.                                                */
    /*------------------------------------------------------------------*/

    %MACRO CALC_CASH_DEPOSIT(TEMPDATA,SUFFIX,METHOD);

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            VAR USNETPRI&SUFFIX;
            WEIGHT &USQTY;
            OUTPUT OUT = ALLVAL_&TEMPDATA (DROP=_FREQ_ _TYPE_)
                   N=TOTSALES SUM = TOTVAL SUMWGT = TOTQTY;
        RUN;

        /*----------------------------------------------------------*/
        /* CALCULATE THE MINIMUM AND MAXIMUM COMPARISON RESULTS        */
        /*----------------------------------------------------------*/

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            VAR PCTMARG;
            OUTPUT OUT = MINMAX_&TEMPDATA (DROP=_FREQ_ _TYPE_)
                   MIN = MINMARG MAX = MAXMARG;
        RUN;

        /*--------------------------------------------------------------*/
        /* CALCULATE THE TOTAL QUANTITY AND VALUE OF SALES WITH         */
        /* POSITIVE COMPARISON RESULTS AND AMOUNT OF POSITIVE DUMPING    */
        /*--------------------------------------------------------------*/

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            WHERE EMARGIN GT 0;
            VAR &USQTY USVALUE EMARGIN;
            OUTPUT OUT = SUMMAR_&TEMPDATA (DROP=_FREQ_ _TYPE_)
                   SUM = MARGQTY MARGVAL POSDUMPING;   
        RUN;

        /*--------------------------------------------------------------*/
        /* CALCULATE THE TOTAL AMOUNT OF NEGATIVE COMPARISON RESULTS    */
        /*--------------------------------------------------------------*/

        PROC MEANS NOPRINT DATA = SUMMARG_&TEMPDATA;
            WHERE EMARGIN LT 0;
            VAR EMARGIN;
            OUTPUT OUT = NEGMARG_&TEMPDATA (DROP = _FREQ_ _TYPE_)
                   SUM = NEGDUMPING;
        RUN;

        /*--------------------------------------------------------------*/
        /*  CALCULATE THE OVERALL MARGIN PERCENTAGES                    */
        /*--------------------------------------------------------------*/

        DATA ANSWER_&TEMPDATA;
            LENGTH CALC_TYPE $11.;
            MERGE ALLVAL_&TEMPDATA SUMMAR_&TEMPDATA 
                    MINMAX_&TEMPDATA NEGMARG_&TEMPDATA;

            %IF &TEMPDATA = _TRNMIXED %THEN 
            %DO;
                CALC_TYPE = "A-to-T";
            %END;
            %ELSE %IF &TEMPDATA = _AVGMIXED %THEN
            %DO;
                CALC_TYPE = "A-to-A";
            %END;
            %ELSE 
            %DO;
                CALC_TYPE = "&METHOD";
            %END;

            IF MARGQTY = . THEN    MARGQTY = 0;
            IF MARGVAL = . THEN    MARGVAL = 0;
            PCTMARQ  = (MARGQTY / TOTQTY) * 100;
            PCTMARV  = (MARGVAL / TOTVAL) * 100;

            IF POSDUMPING = . THEN POSDUMPING = 0;
            IF NEGDUMPING = . THEN NEGDUMPING = 0;

            /*--------------------------------------------------------------*/
            /*  If the sum of the positive comparison                         */
            /*    results is greater than the absolute value of the sum of    */
            /*  the negative comparison results, then offset the positive    */
            /*    results with the negative to calculate total dumping.  If     */
            /*    not, then set total dumping to zero.                        */
            /*--------------------------------------------------------------*/

            %IF &METHOD = ALTERNATIVE  %THEN
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

    /*------------------------------------------------------------------*/
    /*  EXECUTE THE CALC_CASH_DEPOSIT MACRO FOR ALL SCENARIOS            */
    /*------------------------------------------------------------------*/

    %CALC_CASH_DEPOSIT(AVGMARG,_MEAN,STANDARD)
    %CALC_CASH_DEPOSIT(TRANMARG, ,ALTERNATIVE)
    %IF  &CALC_METHOD = MIXED %THEN
    %DO;
        %CALC_CASH_DEPOSIT(AVGMIXED,_MIXED,STANDARD)
        %CALC_CASH_DEPOSIT(TRNMIXED, ,ALTERNATIVE)
    %END;

    %MACRO MIXED;
        %IF &CALC_METHOD = MIXED %THEN
        %DO;

            DATA MIXED;
                SET ANSWER_AVGMIXED ANSWER_TRNMIXED;
            RUN;

            DATA ANSWER_MIXEDSPLIT;
                SET ANSWER_AVGMIXED ANSWER_TRNMIXED;
                PCTMARQ = (MARGQTY/TOTQTY)*100;
                PCTMARV = (MARGVAL/TOTVAL)*100;
            RUN;

            PROC MEANS NOPRINT DATA = MIXED;
                VAR TOTSALES TOTQTY TOTVAL MARGQTY MARGVAL POSDUMPING NEGDUMPING TOTDUMPING;
                OUTPUT OUT = MIXED_SUM (DROP = _FREQ_ _TYPE_) 
                SUM = TOTSALES TOTQTY TOTVAL MARGQTY MARGVAL POSDUMPING NEGDUMPING TOTDUMPING;
            RUN;

            PROC MEANS NOPRINT DATA = MIXED;
                VAR MINMARG;
                OUTPUT OUT = MINMARG (DROP = _FREQ_ _TYPE_) MIN=MINMARG;
            RUN;

            PROC MEANS NOPRINT DATA = MIXED;
                VAR MAXMARG;
                OUTPUT OUT = MAXMARG(DROP = _FREQ_ _TYPE_) MAX=MAXMARG;
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
                TITLE3 "WHEN SOME SALES PASS THE COHEN'S D AND OTHERS NOT, CALCULATE THE MIXED ALTERNATIVE METHOD";
                TITLE4 "COMBINE RESULTS FROM SALES NOT PASSING THE COHEN'S D TEST CALCULATED A-to-A WITH OFFSETS";
                TITLE5 "WITH RESULTS FROM SALES PASSING THE COHEN'S D TEST CALCULATED A-to-T WITHOUT OFFSETS";
            RUN; 

        %END;

    %MEND MIXED;
    %MIXED

    /*----------------------------------------------------------*/
    /*  CREATE MACRO VARIABLES TO TRACK WHEN MARGIN                */
    /*  PERCENTAGES ARE ABOVE DE MINIMIS. IF ANY CASH DEPOSIT   */
    /*  RATE IN AN ADMINISTRATIVE REVIEW IS ABOVE DE MINIMIS,   */
    /*  THE ASSESSMENT MACRO WILL RUN.                            */
    /*----------------------------------------------------------*/

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

    %DE_MINIMIS(AVGMARG,STND,YES)
    %DE_MINIMIS(TRANMARG,ALT,YES)
    %IF &CALC_METHOD = MIXED %THEN
    %DO;
        %DE_MINIMIS(MIXEDMARG,MIXED,YES)
    %END;
    %ELSE 
    %DO;
        %LET ABOVE_DEMINIMIS_MIXED = NA;
    %END;

    /*--------------------------------------------------------------*/
    /*  PRINT CASH DEPOSIT RATE CALCULATIONS FOR ALL SCENARIOS        */
    /*--------------------------------------------------------------*/

    %MACRO PRINT_CASH_DEPOSIT(OUTDATA,METHOD);

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
                %LET TITLE = "OFFSETTING POSITIVE COMPARISON RESULTS WITH NEGATIVES ONLY FOR SALES NOT PASSING COHEN'S D";
        %LET FOOTNOTE1 = "FOR SALES THAT FAIL THE COHEN'S-D TEST, AD DUTIES DUE ARE THE SUM OF C AND D (IF C>|D|) OR ZERO.";
        %LET FOOTNOTE2 = "FOR SALES THAT PASS COHEN'S-D TEST, AD DUTIES DUE ARE THE SUM OF C.";
            %MACRO TOTDUMP_LABEL;
                 TOTDUMPING = 'TOTAL AMOUNT  *OF DUMPING  *(SEE FOOTNOTES)';
            %MEND TOTDUMP_LABEL;
        %END;

        PROC PRINT DATA = ANSWER_&OUTDATA NOOBS SPLIT='*';
            VAR CALC_TYPE TOTSALES TOTVAL TOTQTY POSDUMPING NEGDUMPING TOTDUMPING MINMARG MAXMARG MARGVAL MARGQTY
                    PCTMARV PCTMARQ ;
                &SUMVARS;
            TITLE3 "BUILD UP TO WEIGHT AVERAGE MARGIN";
                TITLE4 "USING THE &METHODOLOGY METHOD";
                TITLE5 &TITLE;
            FOOTNOTE1 &FOOTNOTE1;
            LABEL TOTSALES = ' *NUMBER OF*U.S. SALES* *=========='
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

    /*--------------------------------------------------------------*/
    /*  EXECUTE PRINT_CASH_DEPOSIT MACRO FOR ALL SCENARIOS            */
    /*--------------------------------------------------------------*/

    %PRINT_CASH_DEPOSIT(AVGMARG,STANDARD)
    %PRINT_CASH_DEPOSIT(TRANMARG,ALTERNATIVE)
    %IF &ABOVE_DEMINIMIS_MIXED NE NA %THEN
    %DO;
        %PRINT_CASH_DEPOSIT(MIXEDSPLIT,MIXED)
    %END;
    
    /*--------------------------------------------------------------*/
    /*  PRINT CASH DEPOSIT RATES FOR ALL SCENARIOS                    */
    /*--------------------------------------------------------------*/

        %IF &CALC_METHOD = STANDARD %THEN
        %DO;
            %LET FOOTNOTE1 = "Because all sales did not pass Cohen's d Test, the Mixed Alternative Cash Deposit Rate is the same as the Cash";
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
            %LET FOOTNOTE1 = "Because all sales passed the Cohen's d Test, the Mixed Alternative Cash Deposit Rate is the same as the Cash Deposit";
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
            MERGE ANSWER_AVGMARG (KEEP=WTAVGPCT_STND PER_UNIT_RATE_STND)
                &ANSWER_MIXEDMARG
                ANSWER_TRANMARG (KEEP=WTAVGPCT_ALT PER_UNIT_RATE_ALT);
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
                LABEL     WTAVGPCT_STND = "STANDARD METHOD*AD VALOREM*WEIGHT AVERAGE MARGIN*(E/A x 100)*(percent)* *================="
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

%MEND CALCULATE_CASH_DEPOSIT;

%CALCULATE_CASH_DEPOSIT

/*ep*/

/*-------------------------------------*/
/* PART 17: MEANINGFUL DIFFERENCE TEST */
/*-------------------------------------*/
%MACRO MEANINGFUL_DIFF_TEST;

    %IF &CALC_METHOD NE STANDARD %THEN
    %DO;

        %IF &CALC_METHOD EQ MIXED %THEN
        %DO;

            %LET ADD_SET = MIXEDMARG;

            DATA MIXEDMARG;
                SET  ANSWER_MIXEDMARG (KEEP= WTAVGPCT_MIXED);
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
            SET  ANSWER_TRANMARG (KEEP= WTAVGPCT_ALT);
                LENGTH METHOD $18.;
                METHOD = "A-to-T ALTERNATIVE";
                RENAME WTAVGPCT_ALT = WTAVGPCT;
        RUN;

        DATA MEANINGFUL_DIFF_TEST;
            LENGTH RESULT $ 36 MEANINGFUL_DIFF $ 3;
            SET TRANMARG &ADD_SET;
            IF _N_ = 1 THEN SET ANSWER_AVGMARG (KEEP = WTAVGPCT_STND);

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

%MEND MEANINGFUL_DIFF_TEST;

%MEANINGFUL_DIFF_TEST

/*ep*/

/*-----------------------------------------------------------------*/
/* PART 18: IMPORTER-SPECIFIC DUTY ASSESSMENT RATES (REVIEWS ONLY) */
/*-----------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/*    Calculate and print importer-specific assessment rates if the cash      */
/*    deposit rate in an administrative review is above de minimis.            */
/*--------------------------------------------------------------------------*/

%MACRO ASSESSMENT;

%IF %UPCASE(&CASE_TYPE) = AR %THEN
%DO;

    /*------------------------------------------------------------------*/
    /*    FOR ALL METHODS FOR WHICH NO ASSESSMENTS WILL BE                */
    /*    CALCULATED, PRINT AN EXPLANATION.                                */
    /*------------------------------------------------------------------*/

    %MACRO NO_ASSESS(TYPE);

        %IF &ABOVE_DEMINIMIS_STND = NO OR
            &ABOVE_DEMINIMIS_MIXED = NO OR
            &ABOVE_DEMINIMIS_ALT = NO %THEN
        %DO;

            %IF &&ABOVE_DEMINIMIS_&TYPE = NO %THEN
            %DO;

                %MACRO PRINT_NOCALC;    
                    PROC PRINT DATA = NOCALC NOOBS SPLIT = "*";
                        VAR &VAR_LIST;
                        LABEL &LABEL;
                        TITLE3 &TITLE3;
                        TITLE4 &TITLE4;
                        %FORMAT
                    RUN;
                %MEND PRINT_NOCALC;

                /*----------------------------------------------------------*/
                /*     All cash deposit rates are below de minimis.            */
                /*----------------------------------------------------------*/

                %IF &TYPE = ALT %THEN
                %DO;
                    DATA NOCALC;
                        SET ANSWER (KEEP = WTAVGPCT_ALT);
                        REASON = "HIGHEST POSSIBLE CASH DEPOSIT RATE IS BELOW 0.5 PERCENT (de minimis)";
                    RUN;

                    %LET VAR_LIST = REASON WTAVGPCT_ALT;
                    %MACRO FORMAT;
                        FORMAT WTAVGPCT_&TYPE PCT_MARGIN.;
                    %MEND FORMAT;
                    %LET TITLE3 = "NO ASSESSMENTS WILL BE CALCULATED FOR ANY METHOD SINCE THE HIGHEST POSSIBLE";
                    %LET TITLE4 = "CASH DEPOSIT RATE (FOR THE A-to-T ALTERNATIVE METHOD) IS LESS THAN DE MINIMIS";
                    %LET LABEL =  WTAVGPCT_ALT = "A-to-T ALTERNATIVE*METHOD*AD VALOREM*CASH DEPOSIT RATE*(percent)* *================"
                            REASON = " ";
                    %PRINT_NOCALC
                %END;

                /*------------------------------------------------------*/
                /*  Standard Cash Deposit rate is below de minimis.        */
                /*------------------------------------------------------*/

                %IF &TYPE = STND AND &&ABOVE_DEMINIMIS_ALT NE NO %THEN
                %DO;
                    DATA NOCALC;
                        SET ANSWER (KEEP = WTAVGPCT_STND);
                            REASON = "CASH DEPOSIT RATE IS BELOW 0.5 PERCENT (de minimis)";
                    RUN;

                    %LET TITLE3 = "NO ASSESSMENTS WILL BE CALCULATED FOR THE STANDARD METHOD";
                    %LET TITLE4 = " ";
            
                    %LET VAR_LIST = REASON WTAVGPCT_STND;
                    %MACRO FORMAT;
                        FORMAT WTAVGPCT_&TYPE PCT_MARGIN.;
                    %MEND FORMAT;
                    %LET LABEL =  WTAVGPCT_STND = "STANDARD METHOD*AD VALOREM*CASH DEPOSIT RATE*(percent)* *================"
                            REASON = " ";
                    %PRINT_NOCALC
                %END;

                /*----------------------------------------------------------*/
                /*     The Cash Deposit rate for the Mixed Alternative        */
                /*     Method is below de minimis.                            */
                /*----------------------------------------------------------*/

                %IF &TYPE = MIXED AND &CALC_METHOD NE STANDARD %THEN
                %DO;
                    %IF &&ABOVE_DEMINIMIS_ALT NE NO %THEN
                    %DO; 

                        DATA NOCALC;
                            SET ANSWER (KEEP=WTAVGPCT_&TYPE);
                                REASON = "CASH DEPOSIT RATE IS BELOW 0.5 PERCENT (de minimis)";
                        RUN;

                        %LET VAR_LIST = REASON WTAVGPCT_&TYPE;
                        %MACRO FORMAT;
                            FORMAT WTAVGPCT_&TYPE PCT_MARGIN.;
                        %MEND FORMAT;
                        %LET TITLE3 = "NO ASSESSMENTS WILL BE CALCULATED FOR THE MIXED ALTERNATIVE METHOD";
                        %LET TITLE4 = ' ';
                        %LET LABEL =  WTAVGPCT_&TYPE = "MIXED ALTERNATIVE*METHOD*AD VALOREM*CASH DEPOSIT RATE*(percent)* *================"
                             REASON = " ";
                        %PRINT_NOCALC
                    %END;
                %END;
            %END;
        %END;

        /*----------------------------------------------------------------*/
        /* All sales either pass Cohen's d or do not pass. The Mixed      */
        /* Alternative Method would be the same as the A-to-T Alternative */
        /* Method when all sales pass, or the Standard Method when all    */
        /* sales do not pass. Therefore, no need to calculate Mixed       */
        /* Alternative assessment rates.                                  */     
        /*----------------------------------------------------------------*/           

        %IF &&ABOVE_DEMINIMIS_&TYPE = NA AND &&ABOVE_DEMINIMIS_ALT NE NO %THEN
        %DO;
                DATA NOCALC;
                    REASON= "All sales either do not pass/pass the Cohen's d, Mixed Alternative Method the same as Standard/A-to-T Alternative, respectively.";
                RUN;
                %LET VAR_LIST = REASON;
                    %MACRO FORMAT;
                    %MEND FORMAT;
                %LET TITLE3 = "NO SEPARATE ASSESMENT CALCULATIONS WILL BE DONE USING THE MIXED ALTERNATIVE METHOD";

                %IF &ABOVE_DEMINIMIS_STND = NO %THEN
                %DO;
                    %LET TITLE4 = "(ASSESSMENTS WILL BE CALCULATED USING THE A-to-T ALTERNATIVE METHOD ONLY)";
                %END;
                %ELSE
                %IF &ABOVE_DEMINIMIS_STND = YES %THEN 
                %DO;
                    %LET TITLE4 = "(ASSESSMENTS WILL BE CALCULATED USING THE STANDARD AND FULL A-to-T ALTERNATIVE METHODS)";
                %END;

                %LET LABEL =  REASON = " ";
                %PRINT_NOCALC
        %END;

        %MEND NO_ASSESS;
        %NO_ASSESS(STND)
        %NO_ASSESS(MIXED)
        %NO_ASSESS(ALT)

        /*----------------------------------------------------------------------*/
        /*    FOR ALL METHODS FOR WHICH THE CASH DEPOSIT RATES ARE ABOVE            */
        /*    DE MINIMIS, CALCULATE ASSESSMENTS.                                    */
        /*----------------------------------------------------------------------*/
                
        %IF &ABOVE_DEMINIMIS_STND = YES OR
            &ABOVE_DEMINIMIS_MIXED = YES OR
            &ABOVE_DEMINIMIS_ALT = YES %THEN
        %DO;

        %WT_AVG_DATA; /* re-weight average data by importer                                */
        %RESULTS;     /* recalculate transaction comparison results using re-weighted data */

        /*--------------------------------------------------------------------------*/
        /*    The SUMMARG_<INDATA> dataset does not contain any offsetting            */
        /*    info. Calculate amounts for offsetting by importe and store them in     */
        /*    the database SUMMAR_<INDATA>, leaving the database SUMMARG_<INDATA>     */
        /*    unchanged.                                                                */
        /*--------------------------------------------------------------------------*/

        %MACRO CALC_ASSESS(INDATA,CTYPE,CALC_TYPE);

            PROC SORT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
            RUN;
            PROC MEANS NOPRINT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
                VAR ENTERED_VALUE;
                WEIGHT &USQTY;
                OUTPUT OUT = ENTVAL_&INDATA (DROP=_FREQ_ _TYPE_)
                       N=SALES SUMWGT=ITOTQTY SUM=ITENTVAL;
            RUN;

            /*----------------------------------------------------------*/
            /*  CALCULATE THE SUM OF POSITIVE COMPARISON RESULTS        */
            /*----------------------------------------------------------*/

            PROC MEANS NOPRINT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
                WHERE EMARGIN GT 0;
                VAR EMARGIN;
                OUTPUT OUT = POSMARG_IMPORTER_&INDATA  (DROP=_FREQ_ _TYPE_)
                       SUM = IPOSRESULTS;
            RUN;

            /*----------------------------------------------------------*/
            /*  CALCULATE THE SUM OF NEGATIVE COMPARISON RESULTS        */
            /*----------------------------------------------------------*/

            PROC MEANS NOPRINT DATA = SUMMARG_&INDATA;
                BY US_IMPORTER SOURCEU;
                WHERE EMARGIN LT 0;
                VAR EMARGIN;
                OUTPUT OUT = NEGMARG_IMPORTER_&INDATA (DROP=_FREQ_ _TYPE_)
                       SUM = INEGRESULTS;
            RUN;

            /*------------------------------------------------------------------*/
            /*  For each importer, if the sum of the positive comparison        */
            /*    results is greater than the absolute value of the sum of the    */
            /*     negative comparison results, set the total comparison results    */
            /*     to the sum of the positive and negative comparison results.        */
            /*    Otherwise, set the total comparison results to zero.            */
            /*                                                                  */
            /*     Calculate the ad valorem and per-unit assessment rates, and     */
            /*    the de minimis percent.                                         */
            /*------------------------------------------------------------------*/

            DATA ASSESS_&INDATA;
                LENGTH CALC_TYPE $11;
                MERGE ENTVAL_&INDATA (IN=A) 
                POSMARG_IMPORTER_&INDATA (IN=B) 
                NEGMARG_IMPORTER_&INDATA (IN=C);
                BY US_IMPORTER SOURCEU;
                    CALC_TYPE = "&CALC_TYPE";
                    IF A;
                    IF NOT B THEN IPOSRESULTS = 0;
                    IF NOT C THEN INEGRESULTS = 0;
                    %IF &CTYPE = STND %THEN
                    %DO;
                        IF IPOSRESULTS > ABS(INEGRESULTS) THEN
                            ITOTRESULTS = IPOSRESULTS + INEGRESULTS;
                        ELSE ITOTRESULTS = 0;
                    %END;
                    %ELSE %IF &CTYPE = ALT %THEN
                    %DO;
                        ITOTRESULTS = IPOSRESULTS;
                    %END;
            RUN;

        %MEND CALC_ASSESS;

    /*------------------------------------------------------------------*/
    /*    EXECUTE THE CALC_ACCESS MACRO FOR ALL METHODs                    */
    /*------------------------------------------------------------------*/

        /*----------------------------------------------------------*/
        /*    STANDARD METHOD                                            */
        /*----------------------------------------------------------*/

        %IF &ABOVE_DEMINIMIS_STND = YES %THEN
        %DO;
                %CALC_ASSESS(IMPSTND,STND,STANDARD)
        %END;
        /*----------------------------------------------------------*/
        /*    MIXED ALTERNATIVE METHOD                                */
        /*----------------------------------------------------------*/

        %IF &ABOVE_DEMINIMIS_MIXED= YES %THEN
        %DO;
            %CALC_ASSESS(IMPCSTN,STND,A-to-A)
            %CALC_ASSESS(IMPCTRN,ALT,A-to-T)

            /*--------------------------------------------------------------*/
            /*    COMBINE RESULTS FROM THE PORTION OF SALES                    */
            /*    CALCULATED A-to-A WITH OFFSETS, WITH THOSE FROM SALES         */
            /*    CALCULATED A-to-T WITHOUT OFFSETS.                            */ 
            /*--------------------------------------------------------------*/

            DATA ASSESS_MIXED_ALL;
                SET ASSESS_IMPCSTN ASSESS_IMPCTRN;
            RUN;

            PROC SORT DATA = ASSESS_MIXED_ALL;
                BY US_IMPORTER SOURCEU;
            RUN;

            PROC MEANS NOPRINT DATA = ASSESS_MIXED_ALL;
                BY US_IMPORTER SOURCEU;
                VAR SALES ITOTQTY ITENTVAL IPOSRESULTS INEGRESULTS ITOTRESULTS;
                OUTPUT OUT = ASSESS_MIXED_SUM (DROP = _FREQ_ _TYPE_) 
                SUM = SALES ITOTQTY ITENTVAL IPOSRESULTS INEGRESULTS ITOTRESULTS;
            RUN;

            DATA ASSESS_MIXED_SUM ASSESS_MIXED (DROP=CALC_TYPE);
                LENGTH CALC_TYPE $11.;
                SET ASSESS_MIXED_SUM;
                    CALC_TYPE = "MIXED";
            RUN;

            DATA ASSESS_MIXED_ALL;
                SET ASSESS_MIXED_ALL ASSESS_MIXED_SUM;
            RUN;

            PROC SORT DATA = ASSESS_MIXED_ALL;
                BY US_IMPORTER SOURCEU CALC_TYPE;
            RUN;

            PROC PRINT DATA = ASSESS_MIXED_ALL (OBS = &PRINTOBS);
                BY US_IMPORTER SOURCEU;
                ID US_IMPORTER SOURCEU;
                TITLE3 "FOR THE MIXED ALTERNATIVE METHOD, COMBINE";
                TITLE4 "RESULTS FROM SALES NOT PASSING COHEN'S D CALCULATED A-to-A WITH OFFSETS";
                TITLE5 "WITH RESULTS FROM SALES PASSING COHEN'S D CALCULATED A-to-T WITHOUT OFFSETS";
            RUN; 

        %END;

        /*----------------------------------------------------------*/
        /*    ALTERNATIVE METHOD                                        */
        /*----------------------------------------------------------*/

        %IF &ABOVE_DEMINIMIS_ALT= YES %THEN
        %DO;
                %CALC_ASSESS(IMPTRAN,ALT,ALTERNATIVE)
        %END;

    %END;

    %MACRO PRINT_ASSESS(INDATA);

        DATA ASSESS_&INDATA;
            SET ASSESS_&INDATA;

                ASESRATE = (ITOTRESULTS / ITENTVAL)* 100; /*  AD VALOREM RATE FOR ASSESSMENT, MAY BE CHANGED BELOW */
                PERUNIT  = (ITOTRESULTS / ITOTQTY);       /* PER-UNIT RATE FOR ASSESSMENT, MAY BE CHANGED BELOW    */
                DMINPCT  = ASESRATE;                      /* RATE FOR DE MINIMIS TEST                              */
            
                LENGTH DMINTEST $3. ;

                IF DMINPCT GE 0.5 THEN
                DO;
                    DMINTEST = 'NO';
                    %IF %UPCASE(&PER_UNIT_RATE) = NO %THEN
                    %DO;
                        IF SOURCEU = 'REPORTED' THEN PERUNIT = .;
                        ELSE 
                        IF SOURCEU IN ('MIXED','COMPUTED')
                        THEN 
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

                DMINPCT  = INT(DMINPCT*100)/100;
        RUN;

        PROC PRINT DATA = ASSESS_&INDATA SPLIT='*' WIDTH = MINIMUM;
            VAR US_IMPORTER SOURCEU ITENTVAL ITOTQTY IPOSRESULTS INEGRESULTS ITOTRESULTS
                DMINPCT DMINTEST ASESRATE PERUNIT;
            LABEL US_IMPORTER  = 'IMPORTER**========'
                  SOURCEU   = 'CUSTOMS VALUE*DATA SOURCE**============='
                  ITENTVAL  = 'CUSTOMS VALUE*(A)*============='
                  ITOTQTY   = 'TOTAL QUANTITY*(B)*============'
                  IPOSRESULTS  = 'TOTAL OF*POSITIVE*COMPARISON*RESULTS*(C)*=========='
                  INEGRESULTS  = 'TOTAL OF*NEGATIVE*COMPARISON*RESULTS*(D)*=========='
                  ITOTRESULTS = 'ANTIDUMPING*DUTIES DUE*(see footnotes)*(E)*=============='
                  DMINPCT   = 'RATE FOR*DE MINIMIS TEST*(percent)*(E/A)x100*=============='
                  DMINTEST  = 'IS THE RATE*AT OR BELOW*DE MINIMIS?**===========' 
                  ASESRATE  = '*AD VALOREM*ASSESSMENT*RATE*(percent)*(E/A)x100*=========='
                  PERUNIT   = 'PER-UNIT*ASSESSMENT*RATE*($/unit)*(E/B) *==========' ;
                  FORMAT ITENTVAL ITOTQTY COMMA16.2  DMINPCT ASESRATE PERUNIT COMMA8.2;
            TITLE3 "IMPORTER-SPECIFIC DE MINIMIS TEST RESULTS AND ASSESSMENT RATES ";
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
        %LET ASSESS_FOOTNOTE1 = "THE ANTIDUMPING DUTIES DUE ARE THE SUM OF THE POSITIVE RESULTS ( C )";
        %LET ASSESS_FOOTNOTE2 =  ;
        %LET ASSESS_TITLE4 = "A-to-T ALTERNATIVE METHOD: TOTAL DUMPING IS EQUAL TO TOTAL POSITIVE COMPARISON RESULTS";
        %PRINT_ASSESS(IMPTRAN)
    %END;

%END;

%MEND ASSESSMENT;

%ASSESSMENT

/*ep*/

/*------------------------------------------*/
/* PART 19: REPRINT FINAL CASH DEPOSIT RATE */
/*------------------------------------------*/

%MACRO FINAL_CASH_DEPOSIT;

    %IF %UPCASE(&PER_UNIT_RATE) = NO %THEN
    %DO; 
        %LET PREFIX = WTAVGPCT;
        %LET LABEL_STND = "AD VALOREM*WEIGHTED AVERAGE*MARGIN RATE*(PERCENT)*STANDARD METHOD*================";
        %LET LABEL_MIXED = "AD VALOREM*WEIGHTED AVERAGE*MARGIN RATE*(PERCENT)*MIXED ALTERNATIVE*METHOD*=================";
        %LET LABEL_ALT = "AD VALOREM*WEIGHTED AVERAGE*MARGIN RATE*(PERCENT)*A-to-T ALTERNATIVE*METHOD*==================";
        %LET CDFORMAT = PCT_MARGIN.;
    %END;
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

%MEND FINAL_CASH_DEPOSIT;

%FINAL_CASH_DEPOSIT

DATA _NULL_;
    CALL SYMPUT('EDAY', UPCASE(STRIP(PUT(DATE(), DOWNAME.))));
    CALL SYMPUT('EWDATE', UPCASE(STRIP(PUT(DATE(), WORDDATE18.))));
    CALL SYMPUT('ETIME', UPCASE(STRIP(PUT(TIME(), TIMEAMPM8.))));
    TOTALDATETIME = DATETIME() - &BDATETIME;
    CALL SYMPUT('TOTALTIME', (STRIP(PUT(TOTALDATETIME, HHMM.))));
RUN;

%PUT NOTE: THIS PROGRAM FINISHED RUNNING ON &EDAY, &EWDATE, AT &ETIME.;
%PUT NOTE: THIS PROGRAM TOOK &TOTALTIME (HOURS:MINUTES) TO RUN.;

/***************************************************************************/
/* PART 20: REVIEW LOG AND REPORT SUMMARY AT THE END OF THE LOG FOR:       */
/*          (A) GENERAL SAS ALERTS SUCH AS ERRORS, WARNINGS, MISSING, ETC. */
/*          (B) PROGRAM SPECIFIC ALERTS THAT WE NEED TO LOOK OUT FOR.      */
/***************************************************************************/
%CMAC4_SCAN_LOG (ME_OR_NME =NME);
/*ep*/
