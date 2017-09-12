/***************************************************************************/
/*                        ANTIDUMPING MARKET-ECONOMY                       */
/*                      ANALYSIS OF HOME MARKET SALES                      */
/*                                                                         */
/*                    LAST PROGRAM UPDATED AUGUST 30, 2017                 */
/*                                                                         */
/* Part 1:  Database and General Program Information                       */
/* Part 2:  Bring in Home Market Sales, Convert Date Variable, If          */
/*          Necessary, Merge Exchange Rates into HM Sales, As Required     */
/* Part 3:  Cost Information                                               */
/* Part 4:  Home Market Net Price Calculations                             */
/* Part 5:  Arm's-Length Test of Affiliated Party Sales                    */
/* Part 6:  Add the Downstream Sales for Affiliated Parties That Failed    */
/*          the Arm's-Length Test and Resold Merchandise                   */
/* Part 7:  HM Values for CEP Profit Calculations                          */
/* Part 8:  Cost Test                                                      */
/* Part 9:  Weight-Averaged Home Market Values for Price-To-Price          */
/*          Comparisons with U.S. Sales                                    */
/* Part 10: Calculate Selling Expense and Profit Ratios for                */
/*          Constructed-Value Comparisons                                  */
/* Part 11: HM Level of Trade Adjustment                                   */
/* Part 12: Delete All Work Files in the SAS Memory Buffer, If Desired     */
/* Part 13: Calculate Run Time for This Program, If Desired                */
/* Part 14: Review Log for Errors, Warnings, Uninitialized etc.            */
/***************************************************************************/

/*---------------------------------------------------------------------*/
/*    EDITING THE PROGRAM:                                             */
/*                                                                     */
/*          Places requiring edits are indicated by angle brackets     */
/*          (i.e., '< >'). Replace angle brackets with case-specific   */
/*          information.                                               */
/*                                                                     */
/*          Types of Inputs:(D) = SAS dataset name                     */
/*                          (V) = Variable name                        */
/*                          (T) = Text (no specific format),           */
/*                                do NOT use punctuation marks         */
/*---------------------------------------------------------------------*/

/*---------------------------------------------------------------------*/
/*     EXECUTING/RUNNING THE PROGRAM:                                  */
/*                                                                     */
/*          In addition to executing the entire program, you can do    */
/*          partial runs. Executable points from which you can         */
/*          partially run the program are indicated by '/*ep*' on      */
/*          the left margin. To do a partial run, just highlight the   */
/*          program from one of the executable points to the top,      */
/*          then submit it.                                            */
/*---------------------------------------------------------------------*/

/************************************************************************/
/* PART 1: DATABASE AND GENERAL PROGRAM INFORMATION                     */
/************************************************************************/

/*---------------------------------------------------------------------*/
/* 1-A: LOCATION OF DATA AND MACROS PROGRAM                            */
/*                                                                     */
/*     LIBNAME =      The name (i.e., COMPANY) and location of the     */
/*                    sub-directory containing the SAS datasets for    */
/*                    this program.                                    */
/*                    EXAMPLE: E:\Operations\Fiji\AR_2016\Hangers\Acme */
/*                                                                     */
/*     FILENAME =     Full path of the Macro Program for this case,    */
/*                    consisting of the sub-directory containing the   */
/*                    Macro Program and its file name.                 */
/*---------------------------------------------------------------------*/

LIBNAME COMPANY '<E:\....>';                   /* (T) Location of company and  */
                                               /* exchange rate data sets.     */
FILENAME MACR   '<E:\...\ME Macros.sas>';      /* (T) Location & name of AD-ME */
                                               /* All Macros Program.          */
%INCLUDE MACR;                                 /* Use the AD-ME All Macros     */
                                               /* Program.                     */
FILENAME C_MACS '<E:\...\Common Macros.sas>';  /* (T) Location & Name of the   */
                                               /* Common Macros Program        */
%INCLUDE C_MACS;                               /* Use the Common Macros        */
                                               /* Program.                     */
%LET LOG_SUMMARY = YES;                        /* Default value is "YES" (no    */
                                               /* quotes). Use "NO" (no quotes) */
                                               /* to run program in parts for   */
                                               /* troubleshooting.              */

/*------------------------------------------------------------------*/
/* GET PROGRAM PATH/NAME AND CREATE THE SAME NAME FOR THE LOG FILE  */
/* WITH .LOG EXTENSION                                              */
/*------------------------------------------------------------------*/
%GLOBAL MNAME LOG;
%LET MNAME = %SYSFUNC(SCAN(%SYSFUNC(pathname(C_MACS)), 1, '.'));
%LET LOG = %SYSFUNC(substr(&MNAME, 1, %SYSFUNC(length(&MNAME)) - %SYSFUNC(indexc(%SYSFUNC(
           reverse(%SYSFUNC(trim(&MNAME)))), '\'))))%STR(\)%SYSFUNC(DEQUOTE(&_CLIENTTASKLABEL.))%STR(.log);  

%CMAC1_WRITE_LOG;

/*------------------------------------------------------------------*/
/* 1-B:     PROCEEDING TYPE                                         */
/*------------------------------------------------------------------*/

%LET CASE_TYPE = <AR/INV>;  /*(T) For an investigation, type 'INV' */
                            /*    (without quotes)                 */
                            /*    For an administrative review,    */
                            /*    type 'AR' (without quotes)       */

/*----------------------------------------------------------------------*/
/* 1-C: DATE INFORMATION                                                */
/*                                                                      */
/*          Dates should be in SAS DATE9 format (e.g., 01JAN2010).      */
/*                                                                      */
/*      FOR INVESTIGATIONS: BEGINDAY and ENDDAY usually correspond      */
/*          to the first and last dates of the POI.                     */
/*      FOR REVIEWS: Adjust BEGINDAY and ENDDAY to match the first      */
/*          day of the first month and the last day of the last month   */
/*          of the window period, respectively, covering all U.S. sale  */
/*          dates. Reported CEP sales usually include all sales during  */
/*          the POR. For EP sales, they usually include all entries     */
/*          during the POR. Accordingly, there may be U.S. sales        */
/*          transactions with sale dates prior to the POR. For example, */
/*          if the first EP entry in the POR was in June (first month   */
/*          of POR) but that entry had a sale date back in April, the   */
/*          window period would have to include the three months prior  */
/*          to April. February would then be the beginning of the       */
/*          window period.                                              */
/*                                                                      */
/*          TIME-SPECIFIC COMPARISONS: When making time-specific        */
/*          price-to-price comparisons of HM and US sales, comparisons  */
/*          are not made outside of designated time periods. In such    */
/*          cases, set BEGINWIN to the first day of the first time      */
/*          period. Likewise, set ENDDAY to the last day of the last    */
/*          time period.                                                */
/*----------------------------------------------------------------------*/

%LET BEGINDAY = <DDMONYYYY>;  /*(T) Day 1 of first month of HM sales to be */
                              /*    captured for comparison to U.S. sales. */
%LET ENDDAY   = <DDMONYYYY>;  /*(T) Last day of last month of HM sales to  */
                              /*    be captured for comparison to          */
                              /*    U.S. sales.                            */

/*-------------------------------------------------------------------------*/
/* 1-D: TITLES, FOOTNOTES AND AUTOMATIC NAMES FOR OUTPUT DATASETS          */
/*                                                                         */
/*        The information below will be used in creating titles, footnotes */
/*        and the names of output datasets for later use in the U.S. Sales */
/*        Margin Program.                                                  */
/*                                                                         */
/*          NAMES FOR OUTPUT DATASETS:                                     */
/*                                                                         */
/*      Names of all output datasets generated by this program will have a */
/*      standardized prefix using the format:  "RESPONDENT_SEGMENT_STAGE"  */
/*      in which:                                                          */
/*                                                                         */
/*         RESPONDENT  = Respondent identifier (e.g., company name)        */
/*         SEGMENT     = Segment of proceeding (e.g., INVEST, AR6, REMAND) */
/*         STAGE       = PRELIM or FINAL                                   */
/*                                                                         */
/*      The total number of places/digits used in the RESPONDENT, SEGMENT  */
/*      and STAGE identifiers, combined, should NOT exceed 21. Letters,    */
/*      numbers and underscores are acceptable. No punctuation marks,      */
/*      blank spaces or special characters should be used.                 */
/*                                                                         */
/*      The names of the output datasets this program creates, where       */
/*      applicable, are the following:                                     */
/*                                                                         */
/*          {RESPONDENT_SEGMENT_STAGE}_COST    = Wt-avg costs              */
/*          {RESPONDENT_SEGMENT_STAGE}_HMCEP   = HM revenue/expenses for   */
/*                                               CEP profit                */
/*          {RESPONDENT_SEGMENT_STAGE}_CVSELL  = Selling & profit ratios   */
/*                                               for CV                    */
/*          {RESPONDENT_SEGMENT_STAGE}_HMWTAV  = Wt-avg HM data            */
/*          {RESPONDENT_SEGMENT_STAGE}_LOTADJ  = LOT adjustment factors    */
/*                                                                         */
/*          All output datasets will be placed in the COMPANY directory.   */
/*-------------------------------------------------------------------------*/

%LET PRODUCT      = <  >;     /*(T) Product */
%LET COUNTRY      = <  >;     /*(T) Country */

/*------------------------------------------------------------------------*/
/* Between the RESPONDENT, SEGMENT and STAGE macro variables below, there */
/* should be a maximum of 21 digits.                                      */
/*------------------------------------------------------------------------*/

%LET RESPONDENT = <  >;  /*(T) Respondent identifier. Use only letters,   */
                         /*    numbers and underscores.                   */
%LET SEGMENT    = <  >;  /*(T) Segment of the proceeding, e.g., Invest,   */
                         /*    AR1, Remand. Use only letters, numbers     */
                         /*    and underscores.                           */
%LET STAGE      = <  >;  /*(T) Stage of proceeding, e.g., Prelim, Final,  */
                         /*    Remand. Use only letters, numbers and      */
                         /*    underscores.                               */

/*-------------------------------------------------------------------*/
/* 1-E: DATABASE INFORMATION FOR HM SALES, COSTS & EXCHANGE RATES    */
/*                                                                   */
/*     Where information may not be relevant (e.g., re: manufacturer */
/*     and prime/non-prime merchandise), 'NA' (not applicable) will  */
/*     appear as the default value.                                  */
/*-------------------------------------------------------------------*/

/*---------------------------------------------------------------*/
/*     1-E-i. EXCHANGE RATE INFORMATION:                         */
/*                                                               */
/*      The HM program needs to use exchange rates if there are  */
/*      reported adjustments in non-HM currency. If there are    */
/*      no non-HM currencies, define the macro variables         */
/*      USE_EXRATES1 and USE_EXRATES2 as NO.                     */
/*                                                               */
/*      If there are non-HM currencies, define the macro         */
/*      variable USE_EXRATES1 as YES for the first non-HM        */
/*      currency and define the macro variable EXDATA1 as the    */
/*      name of the exchange rate dataset. If there is a second  */
/*      non-HM currency, define the macro variable USE_EXRATES2  */
/*      as YES and define the macro variable EXDATA2 as the      */
/*      name of the second exchange rate dataset. If there are   */
/*      more than two non-HM currencies, please contact a SAS    */
/*      Support Team member for assistance.                      */
/*                                                               */
/*      When non-HM currencies are reported, there are three     */
/*      ways to refer to exchange rate variables in your         */
/*      HMProgram. If the first non-HM currency is               */
/*      from Mexico, you can code the first exchange rate        */
/*      variable as EXRATE_MEXICO, &EXRATE1, or EXRATE_&EXDATA1. */
/*      If the second non-HM currency is from Canada, you can    */
/*      code the second exchange rate variable as EXRATE_CANADA, */
/*      &EXRATE2, or EXRATE_&EXDATA2.                            */
/*                                                               */
/*      NOTE: This program assumes that you are converting       */
/*            everything into the currency in which costs are    */
/*            reported. If this is not the case, please          */
/*            contact a SAS Support Team member for assistance.  */
/*---------------------------------------------------------------*/

%LET USE_EXRATES1 = <YES/NO>;  /*(T) Use exchange rate #1? Type "YES" or */
                               /*    "NO" (without quotes).              */
%LET     EXDATA1   = <  >;     /*(D) Exchange rate dataset name.         */

%LET USE_EXRATES2 = <YES/NO>;  /*(T) Use exchange rate #2? Type "YES" or */
                               /*  "NO" (without quotes).                */
%LET     EXDATA2   = <  >;     /*(D) Exchange rate dataset name.         */

/*--------------------------------------------------------*/
/* 1-E-ii. HOME MARKET INFORMATION                        */
/*--------------------------------------------------------*/

%LET HMDATA = <  >;             /*(D) HM sales dataset filename.           */
%LET   HMCONNUM = <  >;         /*(V) Control number                       */
%LET   HMCPPROD = <  >;         /*(V) Variable (usually CONNUMH) linking   */
                                /*    sales to cost data.                  */
%LET   HMCHAR = <  >;           /*(V) Product matching characteristics.    */
                                /*    List them from left to right         */
                                /*    in order of importance, with no      */
                                /*    punctuation separating them.         */
%LET   HMDATE = <  >;           /*(V) Sale date.                           */
%LET   HMQTY = <  >;            /*(V) Quantity.                            */
%LET   HMGUP  = <  >;           /*(V) Gross price. Need not be in          */
                                /*    consistent currency, used only to    */
                                /*    check for zero, negative & missing   */
                                /*    values.                              */
%LET   HMLOT  = <NA>;           /*(V) Level of trade. If not reported in   */
                                /*    the database and not required, type  */
                                /*    "NA" (without quotes).               */
                                /*    You may also type "NA" if HM & US    */
                                /*    both have only 1 LOT & those LOTs    */
                                /*    are the same.                        */
%LET   HMMANUF = <NA>;          /*(V) Manufacturer code. If not            */
                                /*    applicable, type "NA" (without       */
                                /*    quotes).                             */
%LET   HMPRIME  = <NA>;         /*(V) Prime/seconds code. If not           */
                                /*    applicable, type "NA" (without       */
                                /*    quotes).                             */
%LET   HM_TIME_PERIOD = <  >;   /*(V) Variable in HM data for cost-related */
                                /*     time periods, if applicable         */
%LET   HM_MULTI_CUR = <YES/NO>; /*(T) Is HM data in more than one          */
                                /*    currency? Type "YES" or "NO"         */
                                /*    (without quotes).                    */
%LET   MIXEDCURR = <YES/NO/NA>; /*(T) Are there mixed-currency variables   */
                                /*    that need to be split into separate  */
                                /*    currency variables?                  */
                                /*    Type "NO" (without quotes) if there  */
                                /*    is no mixed-currency variable.       */
                                /*    Type "YES" (without quotes) if there */
                                /*    are mixed-currency variables AND     */
                                /*    there is currency-indicating         */
                                /*    variable (see 4-A below).            */
                                /*    Type "NA" (without quotes) if there  */
                                /*    are mixed-currency variables BUT     */
                                /*    there is no currency-indicating      */
                                /*    variable (see 4-A below).            */

/*---------------------------------------------------------------*/
/* 1-E-iii. COST OF PRODUCTION DATA                              */
/*                                                               */
/*     If the respondent has reported both a HM COP database and */
/*     a U.S. CV database, it is best to combine them below in   */
/*     Part 3 and calculate one weight-averaged cost database.   */
/*---------------------------------------------------------------*/

%LET     COST_DATA = <  >;    /*(D) Cost dataset name                   */
%LET     COST_QTY = <  >;     /*(V) Production quantity                 */
%LET     COST_MATCH = <  >;   /*(V) The variable (usually CONNUM)       */
                              /*    linking cost data to sales data.    */
%LET     COST_MANUF = <NA>;   /*(V) Manufacturer code. If not           */
                              /*    applicable, type "NA" (without      */
                              /*    quotes).                            */

/*--------------------------------------------------*/
/* 1-E-iii-a. TIME-SPECIFIC COSTS                   */
/*                                                  */
/* If you type COMPARE_BY_TIME = YES on the first   */
/* line, also complete the rest of this section.    */
/*--------------------------------------------------*/

%LET COMPARE_BY_TIME = <YES/NO>;     /*(T) Calculate costs by        */
                                     /*    time periods? Type "YES"  */
                                     /*    or "NO" (without quotes). */
%LET      COST_TIME_PERIOD = <  >;   /*(V) Variable in cost data     */
                                     /*    for time periods.         */
%LET      TIME_INSIDE_POR  = <  >;   /*(T) List of values of         */
                                     /*    &COST_TIME_PERIOD         */
                                     /*    variable for periods      */
                                     /*    during the POR,           */
                                     /*    separated by commas,      */
                                     /*    quotes around character   */
                                     /*    data. E.g., "Q1", "Q2",   */
                                     /*    "Q3", "Q4"                */
%LET      USDATA = <  >;             /*(D) U.S. sales data set.      */
%LET      USCONNUM = <  >;           /*(V) U.S. control number.      */
%LET      US_TIME_PERIOD = <  >;     /*(V) Variable defining the     */
                                     /*    U.S. time period.         */

/*----------------------------------------------------*/
/* 1-E-iii-b. SURROGATE COSTS FOR NON-PRODUCTION      */
/*                                                    */
/* If you have products that were sold but not        */
/* produced during the period and that do not already */
/* have adequate surrogate cost information reported, */
/* type 'YES' (without quotes)on the first line and   */
/* complete the rest of this section.                 */
/*----------------------------------------------------*/

%LET MATCH_NO_PRODUCTION = <YES/NO>; /*(T) Find surrogate costs for        */
                                     /*    products not produced during    */
                                     /*    the POR?  Type "YES" or "NO"    */
                                     /*    (without quotes). If "YES,"     */
                                     /*    complete the indented macro     */
                                     /*    variables that follow.          */
%LET    COST_PROD_CHARS = <YES/NO>;  /*(T) Are the product physical        */
                                     /*    characteristic variables in the */
                                     /*    cost database? Type "YES" or    */
                                     /*    "NO" without quotes).           */
%LET    COST_CHAR = <  >; /*(V) Product matching characteristics in cost   */
                          /*    data. List them from left-to-right in      */
                          /*    order of importance, with no punctuation   */
                          /*    separating them. If no product             */
                          /*    characteristics in cost data, complete the */
                          /*    indented macro variables.                  */
%LET        USDATA = <  >;   /*(D) U.S. sales data set. Needed only if     */
                             /*    no product matching characteristics     */
                             /*    in cost data.                           */
%LET        USCVPROD = <  >; /*(V) U.S. product matching to &CVPROD.       */
                             /*    Needed only if no product matching      */
                             /*    characteristics in cost data.           */
%LET        USCHAR = <  >;   /*(V) Product matching characteristics in     */
                             /*    U.S. data. List them from               */
                             /*    left-to-right in order of importance,   */
                             /*    with no punctuation separating them.    */
                             /*    Needed only if there is no product      */
                             /*    matching characteristics in cost data.  */

/*----------------------------------------------------------------------*/
/* 1-F: CONDITIONAL PROGRAMMING OPTIONS:                                */
/*                                                                      */
/*      For each conditional programming macro below, select            */
/*          either YES (to run) or NO (not to run). The conditional     */
/*      programming macros all begin with %LET RUN_ and indicate        */
/*          that YES or NO answers are expected. Answer all YES/NO      */
/*          questions.                                                  */
/*                                                                      */
/*          If you select YES for THE RUN_ARMSLENGTH or RUN_HMLOTADJ    */
/*          macro variables, also complete the ones immediately         */
/*          following and indented.                                     */
/*                                                                      */
/*            Note: Results of the HMLOTADJ calculation are meaningless */
/*          unless the following criteria are met:                      */
/*               1. There are two or more levels of trade in HM data    */
/*               2. At least one of those two HM levels of trade also   */
/*                   exist in the U.S. data.                            */
/*----------------------------------------------------------------------*/

%LET RUN_ARMSLENGTH = <YES/NO>; /*(T) Run the Arm's-Length test? Type      */
                                /*    "YES" or "NO" (without quotes).      */
%LET     HMCUST    = <   >;     /*(V) Customer identifier/code             */
%LET     HMAFFL    = <   >;     /*(V) Customer affiliation code            */
%LET     NAFVALUE  = < 1 >;     /*(T) Value in data indicating             */
                                /*    unaffiliated sales. Default is       */
                                /*    numeric value of 1.                  */
%LET RUN_HMCEPTOT = <YES/NO>;   /*(T) Calculate HM revenue and expenses    */
                                /*    for CEP profit? Type "YES" or "NO"   */
                                /*    (without quotes). If you type "YES," */
                                /*    you must have a cost database.       */
%LET RUN_HMLOTADJ = <YES/NO>;   /*(T) Run LOT price pattern calculation?   */
                                /* Type "YES" or "NO" (without quotes).    */

/*------------------------------------------------------------------*/
/* 1-G: FORMAT, PROGRAM AND PRINT OPTIONS                           */
/*------------------------------------------------------------------*/

OPTIONS PAPERSIZE = LETTER;
OPTIONS ORIENTATION = LANDSCAPE;
OPTIONS TOPMARGIN = ".25IN"
        BOTTOMMARGIN = ".25IN"
        LEFTMARGIN = ".25IN"
        RIGHTMARGIN = ".25IN";

/*-------------------------------------------------------------*/
/* 1-G-i Options that usually do not require edits.            */
/*-------------------------------------------------------------*/

/*-------------------------------------------------------------*/
/*     1-G-i-a Printing Formats                                */
/*                                                             */
/*  In sections where a large number of observations may       */
/*  print, the program limits the number of observations       */
/*  to 25, by default. To change this, adjust the PRINTOBS     */
/*  number below.                                              */
/*                                                             */
/*     By editing the default formats used below, you can      */
/*     change the way values are displayed when the formats    */
/*     are used. When you increase the number of decimals      */
/*     (the number to the right of the decimal in the format), */
/*     you must also increase the maximum number of places     */
/*     displayed, which is the number to the left of the       */
/*     decimal. (Commas, decimal points, dollar signs, percent */
/*     symbols, etc. all occupy space.)  For example, the      */
/*     COMMA12.2 format looks like '1,000,000.00' To display   */
/*     four decimal places you would type "COMMA14.4"          */
/*-------------------------------------------------------------*/

%LET PRINTOBS = 25;               /*(T) Number of obs to print on     */
                                  /*    statements that are sampled.  */
%LET COMMA_FORMAT = COMMA12.2;    /* Comma format using 12 total      */
                                  /* spaces and two decimal places.   */
%LET DOLLAR_FORMAT = DOLLAR12.2;  /* Dollar format using 12 total     */
                                  /* spaces and two decimal places.   */
%LET PERCENT_FORMAT = PERCENT8.2; /* Percent format using seven total */
                                  /* spaces and two decimal places.   */

/*----------------------------------------------------------*/
/*     1-G-i-b Programming Options                          */
/*----------------------------------------------------------*/

%LET DEL_WORKFILES = NO; /*(T) Delete all work library files?  Default    */
                         /*    is NO. If you type "YES" (without          */
                         /*    quotes), you may increase program speed,   */
                         /*    but will not be able examine files in      */
                         /*    the work library for diagnostic purposes.  */
%LET CALC_RUNTIME = YES; /*(T) Calculate program run time? If you don't   */
                         /*    like to see this info., type "NO" (without */
                         /*    quotes)                                    */
OPTIONS NOSYMBOLGEN;     /* SYMBOLGYN prints macro variable resolutions.  */
                         /* Reset to "NOSYMBOLGEN" (without quotes) to    */
                         /* deactivate.                                   */
OPTIONS MPRINT;          /* MPRINT prints macro resolutions, type         */
                         /* "NOMPRINT" (without quotes) to deactivate.    */
OPTIONS NOMLOGIC;        /* MLOGIC prints additional info. on macros,     */
                         /* type "MLOGIC" (without quotes) to activate.   */
OPTIONS MINOPERATOR;     /* MINOPERATOR is required when using the IN(..) */
                         /* function in macros.                           */
OPTIONS OBS = MAX;       /* Indicates the number of OBS to process in each*/
                         /* data set. Default setting of MAX processes all*/
                         /* transactions. If you have large datasets and  */
                         /* initially wish to debug the program using a   */
                         /* limited number of transactions, you can reset */
                         /* this option by typing in a number.            */
OPTIONS NODATE PAGENO = 1 YEARCUTOFF = 1960;
OPTIONS FORMCHAR = '|----|+|---+=|-/\<>*';

/*------------------------------------------------------------------*/
/* 1-H:      GENERATE PROGRAM-SPECIFIC TITLES, FOOTNOTES            */
/*               AND MACROS NEEDED TO EXECUTE THE PROGRAM.          */
/*------------------------------------------------------------------*/

%LET SALESDB = HMSALES;

%G1_RUNTIME_SETUP
%G2_TITLE_SETUP
%G3_COST_TIME_MVARS

/*----------------------------------------------------------------------*/
/* 1-I: PRIME AND MANUFACTURER MACROS AND MACRO VARIABLES               */
/*                                                                      */
/*          In the programming language, the macro variables &HMPRIM,   */
/*          &HMMANF and &COPMANF are used. Their values are determined  */
/*          by the answers in Sect.1-E-ii above.                        */
/*          For example, if you typed %LET HMMANUF=NA, then the macro   */
/*          variable &HMMANF will be set to a null/blank value.         */
/*          Otherwise, &HMMANF will be equal to the variable specified  */
/*          in %LET HMMANUF=<???>.                                      */
/*                                                                      */
/*          Similarly, &HMPRIM and &COPMANF will either be a null/blank */
/*          values, or set equal to the variables specified in          */
/*          %LET HMPRIME=<???> and %LET COPMANUF=<???>.                 */
/*----------------------------------------------------------------------*/

%HM1_PRIME_MANUF_MACROS

/*************************************************************************/
/* PART 2: BRING IN HOME MARKET SALES, CONVERT DATE VARIABLE,            */
/*         IF NECESSARY, MERGE EXCHANGE RATES INTO HM SALES, AS REQUIRED */
/*************************************************************************/

/*----------------------------------------------------------------------*/
/* 2-A: BRING IN HOME MARKET SALES                                      */
/*                                                                      */
/*          Alter the SET statement, if necessary, to bring in more     */
/*          than one SAS database. If you need to rename variables,     */
/*          change variables from character to numeric (or vice versa), */
/*          in order to do align the various databases, make such       */
/*          changes here.                                               */
/*                                                                      */
/*          Changes to HM data using exchange rates and costs should    */
/*          wait until Part 4, below, after the cost and exchange rate  */
/*          databases are attached.                                     */
/*                                                                      */
/*          Leave the data step open through the RUN statement          */
/*          following the execution of the G4_LOT macro in Sect 2-C-ii  */
/*----------------------------------------------------------------------*/

DATA HMSALES;
    SET COMPANY.&HMDATA;
 
    /*------------------------------------------------------------------*/
    /* 2-B: Insert and annotate any changes below.                      */
    /*------------------------------------------------------------------*/

    /* <Insert changes here, if required.> */          

    /*-----------------------------------------------------------------------
    /* 2-C: LEVEL OF TRADE                                                 */
    /*                                                                     */
    /*      The variable HMLOT will be created containing the levels       */
    /*          of trade. It is this variable that is used in the          */
    /*          programming. If you typed '%LET HMLOT = NA' in             */
    /*          Sect.1-E-ii above, the variable HMLOT will be set to 0     */
    /*          (zero). Otherwise, HMLOT will be set equal to the variable */
    /*          specified in %LET HMLOT = <???>.                           */
    /*---------------------------------------------------------------------*/

    /*------------------------------------------------------------------*/
    /* 2-C-i: MAKE CHANGES TO LEVEL OF TRADE, IF REQUIRED               */
    /*------------------------------------------------------------------*/

    /*-----------------------------------------------------------*/
    /*  If you have a level of trade variable and need to make   */
    /*  changes to its values, or you don't have one but need to */
    /*  create one, make those edits here before the %G4_LOT.    */
    /*-----------------------------------------------------------*/

    /*  < Make changes to/create LOT variable, if required > */

    /*------------------------------------------------------------------*/
    /* 2-C-ii: CREATE THE LEVEL OF TRADE PROGRAMMING VARIABLE           */
    /*------------------------------------------------------------------*/

    %G4_LOT(&HMLOT,HMLOT)

RUN;

/*ep*/

    /*------------------------------------------------------------------*/
    /* 2-C-iii: GET HMSALES COUNT FOR LOG REPORTING                     */
    /*------------------------------------------------------------------*/

	%CMAC2_COUNTER (DATASET = HMSALES, MVAR=ORIG_HMSALES);

/*ep*/

/*----------------------------------------------------------------------*/
/* 2-D: TEST FORMAT OF DATE VARIABLE AND CONVERT, WHEN NECESSARY        */
/*                                                                      */
/*          This section tests the sale date variable to see if it is   */
/*          in SAS date format. If not, an attempt will be made to      */
/*          convert it using language that will work for many cases,    */
/*          but not all. Should the language not convert your data      */
/*          correctly, contact a SAS Support Team member for assistance.*/
/*----------------------------------------------------------------------*/

%G5_DATE_CONVERT

/*ep*/

/*---------------------------------------------------------------------*/
/* 2-E: CHECK FOR NEGATIVE AND MISSING DATA, AND FOR DATES             */
/*          OUTSIDE THE POI OR WINDOW. CREATE THE MONTH VARIABLE       */
/*          FOR AN ADMINISTRATIVE REVIEW.                              */
/*                                                                     */
/*          Sales with gross price or quantity variables that have     */
/*          missing values or values less than or equal to zero will   */
/*          be taken out of the database only to make the program      */
/*          run smoothly. This is not a policy decision. You may       */
/*          have to make adjustments to such sales.                    */
/*                                                                     */
/*          Sales outside the POI (for an investigation) or window     */
/*          period (for administrative reviews) will be set aside.     */
/*                                                                     */
/*          In an administrative review, a month variable will be      */
/*          created giving each month in the window period a unique    */
/*          number. In the first calendar year of the review, the      */
/*          value of HMMONTH will be equal to the normal numeric       */
/*          month designation (e.g., Jan=1, Feb=2). In the second      */
/*          calendar year of the review, HMMONTH will be equal to      */
/*          the numeric month designation + 12 (e.g., Jan=1+12=13).    */
/*          Similarly, in a third calendar year, HMMONTH = month+24.   */
/*---------------------------------------------------------------------*/

%G6_CHECK_SALES

/*ep*/

/*--------------------------------------------------------------------*/
/* 2-F: MERGE IN EXCHANGE RATES, AS REQUIRED                          */
/*                                                                    */
/*          For both potential exchange rates in Section I-E-i above, */
/*          macro variables with neutral values are first created.    */
/*          These neutral values will be over-written with actual     */
/*          exchange rate data, as required.                          */
/*--------------------------------------------------------------------*/

%G7_EXRATES

/*ep*/

/******************************************************************/
/* PART 3: COST INFORMATION                                       */
/*                                                                */
/* If the respondent has supplied separate COP and CV databases,  */
/* combine them together in this program in sect. 3-B and make    */
/* required adjustments. The combined weight-averaged cost        */
/* database calculated in this program can then also be used in   */
/* the Margin Program with U.S. sales. This is preferable to      */
/* calculating the two individually.                              */
/*                                                                */
/* Make required changes to items in the indicated sections as    */
/* needed:                                                        */
/*                                                                */
/* Section 3-A-i        Major input adjustments                   */
/* Section 3-B-ii-a     Align HM and U.S. CONNUMS, product chars. */
/* Section 3-C          Cost of manufacturing, G&A, interest, and */
/*                      cost of production                        */
/******************************************************************/

/*--------------------------------------------------------------*/
/* 3-A CALL UP COST DATA, INCLUDING A SEPARATE CV DATABASE,     */
/*     IF PROVIDED.                                             */
/*                                                              */
/* Make changes to cost inputs, manufacturer, etc., calculate   */
/* major input adjustments.                                     */
/*                                                              */
/* Do NOT make changes to GNA, INTEX or the calculation         */
/* of TOTCOM here. Instead, do these below in Section 3-C.      */
/*                                                              */
/* Also, do NOT reset missing or zero production quantities     */
/* to positive values at this point with the exception noted    */
/* in the next paragraph. The resetting of zero/missing         */
/* production quantities before weight averaging will be done   */
/* later in Section 3-C below.                                  */
/*                                                              */
/* For annualized (not time-specific) costs, if the respondent  */
/* has already provided surrogate cost information for a        */
/* particular product but has put either a zero or a missing    */
/* value for production quantity, then the default language     */
/* in Section 3-B will mistakenly mark the product as one       */
/* still requiring surrogate information. For annualized costs  */
/* only, you can remedy this by setting the production quantity */
/* to a non-zero or non-missing value in Section 3-A-i.         */
/*                                                              */
/* CONNUMUs in the HM and U.S. datasets that have sales but no  */
/* production in the POI/POR must be in the COP dataset with a  */
/* production quantity of 0 (zero). If respondent does not      */
/* report these CONNUMs in the cost dataset, the analyst must   */
/* add these CONNUMs to the COP dataset with a production       */
/* quantity of 0 (zero).                                        */
/*--------------------------------------------------------------*/

DATA COST;
    SET COMPANY.&COST_DATA /* <COMPANY.CVDATABASE> */;

    /*-----------------------------------------------------------*/
    /* 3-A-i: Insert and annotate any major input changes below. */
    /*-----------------------------------------------------------*/

    /* <Insert major input changes here, if required.> */          
RUN;

/*ep*/

/*--------------------------------------------------------------*/
/* 3-B SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POI/POR */
/*--------------------------------------------------------------*/

/*-------------------------------------------------------------*/
/* 3-B-i IDENTIFY PRODUCTS NOT PRODUCED DURING POI/POR         */
/*       FOR WHICH SURROGATE COSTS ARE NEEDED.                 */
/*                                                             */
/* The macro variable &FIND_SURROGATES will be created whose   */
/* value will be "YES" when it does find products requiring    */
/* surrogates using the criteria specified. Otherwise,         */
/* &FIND_SURROGATES will be set to "NO," turning off sections  */
/* 3-B-ii-a and 3-E. If &FIND_SURROGATES = NO, then you will   */
/* not need to supply information in 3-B-ii-a on U.S. product  */
/* characteristic variables.                                   */
/*                                                             */
/* The %G8_FIND_NOPRODUCTION macro below identifies products   */
/* needing surrogate cost information when total production    */
/* during the annual cost period is zero or missing. If this   */
/* assumption does not fit the circumstances, you will need    */
/* to make edits accordingly.                                  */
/*                                                             */
/* For annualized (not time-specific) costs, if the respondent */
/* has already provided surrogate cost information for a       */
/* particular product but has put either a zero or a missing   */
/* value for production quantity, then the default language    */
/* will mistakenly think no surrogate information has been     */
/* provided. For annualized costs only, you can remedy this    */
/* problem by setting the production quantity to a non-zero or */
/* non-missing value above in section 3-A-i.                   */
/*-------------------------------------------------------------*/

%MACRO NOPRODUCTION;
    %GLOBAL FIND_SURROGATES;
    %LET FIND_SURROGATES = NO; /* Default value. Do not edit. */

    %IF %UPCASE(&MATCH_NO_PRODUCTION) = YES %THEN
    %DO;
        %G8_FIND_NOPRODUCTION  /* Finds products needing surrogate    */
                               /* costs by looking for total produc-  */
                               /* tion quantities per product that    */
                               /* are less than or equal to zero,     */
                               /* or have missing values. If this     */
                               /* is incorrect, please make adjust-   */
                               /* ments above in Section 3-A-i before */
                               /* executing the G8_FIND_NOPRODUCTION  */
                               /* macro.                              */

        /*---------------------------------------------------------*/
        /* 3-B-ii ATTACH PRODUCT CHARACTERISTICS, WHEN REQUIRED    */
        /*                                                         */
        /* When product characteristic variables are not in the    */
        /* data, they will be taken from both the HM and U.S.      */
        /* sales databases. To do this, the HM and U.S. control    */
        /* numbers must be of the same type (character v. numeric) */
        /* and length, if character. Likewise for the product      */
        /* characteristic variables. If you need to make adjust-   */
        /* ments to the control numbers and/or product charac-     */
        /* teristic variables, do that here before the execution   */
        /* of the G9_COST_PRODCHARS macros below.                  */
        /*---------------------------------------------------------*/

        /*-------------------------------------------------------*/
        /* 3-B-ii-a: Insert changes to control numbers and       */
        /*           product characteristics in U.S. sales data. */
        /*                                                       */
        /* Edits to U.S. control numbers and product charac-     */
        /* teristics should be done before executing the         */
        /* G9_COST_PRODCHARS macro.                              */
        /*-------------------------------------------------------*/

        %IF %UPCASE(&COST_PROD_CHARS) = NO %THEN
        %DO;
            DATA USSALES (KEEP=&USCVPROD &USCHAR);
                SET COMPANY.&USDATA;

                /* Make changes to U.S. control numbers and product */
                /* characteristic variables here, if required.      */

            RUN;
        %END;

        %G9_COST_PRODCHARS
    %END;
%MEND NOPRODUCTION;

%NOPRODUCTION

/*ep*/

/*****************************************************************/
/* 3-C CALCULATE TOTAL COST OF MANUFACTURING, GNA, INTEREST, AND */
/*     TOTAL COST OF PRODUCTION.                                 */
/*****************************************************************/

DATA COST;
    SET COST;

    IF &COST_QTY IN (.,0) THEN
        &COST_QTY = 1;

    TCOMCOP = <  >;               /* Total cost of manufacturing.        */
    VCOMCOP = <TCOMCOP - FOH>;    /* Variable cost of manufacturing      */
                                  /* equal to TCOMCOP less fixed costs.  */
    GNACOP = <  >;                /* General and administrative expense. */
    INTEXCOP = <  >;              /* Interest expense.                   */

    TOTALCOP = TCOMCOP + GNACOP + INTEXCOP; /* Total cost of production. */
RUN;

/*ep*/

/*-----------------------------------------------*/
/* 3-D: WEIGHT-AVERAGE COST DATA, WHEN REQUIRED. */
/*-----------------------------------------------*/

%G15_CHOOSE_COSTS

/*ep*/

/*-------------------------------------------------------------------------*/
/* 3-E: FIND SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POR          */
/*-------------------------------------------------------------------------*/

%G16_MATCH_NOPRODUCTION

/*ep*/

/*-------------------------------------------------------------------------*/
/* 3-F: MERGE COSTS WITH HMSALES AND OUTPUT A COST DATABASE FOR USE WITH   */
/*      U.S. SALES DATA                                                    */
/*                                                                         */
/* The output database will be named using the standardized naming         */
/* convention 'RESPONDENT_SEGMENT_STAGE'_COST. The variables in the        */
/* database will have the following standardized names: COST_MATCH,        */
/* COST_QTY, COST_MANUF (if, applicable), AVGVCOM, AVGTCOM, AVGGNA,        */
/* AVGINT and AVGCOST.                                                     */
/*-------------------------------------------------------------------------*/

%G17_FINALIZE_COSTDATA

/*ep*/

/*-----------------------------------------------------------------------*/
/* 3-G: IN TIME-SPECIFIC COST CASES, IDENTIFY CONNUM/TIME PERIODS WITH   */
/*      NO CORRESPONDING COP CONNUM/TIME PERIODS. STOP THE PROGRAM IF    */
/*      MISSING CONNUM/TIME PERIODS ARE FOUND AND ISSUE AN ERROR MESSAGE */
/*      ASKING THE ANALYST TO CONTACT THE SAS SUPPORT TEAM FOR HELP.     */
/*-----------------------------------------------------------------------*/

%MACRO US_CONNUM_PERIOD_LIST;
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        DATA US_INDEX_CHECK;
            SET COMPANY.&USDATA;

            /******************************************************/
            /* 3-G-i: Create time-specific variable if necessary. */
            /******************************************************/
 
            /* <Create time-specific variable> */
        RUN;
    %END;
%MEND US_CONNUM_PERIOD_LIST;

%US_CONNUM_PERIOD_LIST

%G18_FIND_MISSING_TIME_PERIODS(HM)

/***************************************************************************/
/* PART 4: HOME MARKET NET PRICE CALCULATIONS                              */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 4-A: SPLIT MIXED-CURRENCY VARIABLES INTO SINGLE-CURRENCY VARIABLES      */
/*                                                                         */
/* Mixed-currency variables are ones that have values in more than one     */
/* currency. Frequently, there is another variable that indicates which    */
/* transactions are in what currency. If this is the case, use the         */
/* language below in Sect. 4-A-i to split the mixed-currency variables     */
/* into separate, single-currency variables. Sometimes, there is no        */
/* currency-indicating variable. If not, please skip to section 4-A-ii     */
/* below.                                                                  */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/* 4-A-i: SPLIT MIXED-CURRENCY VARIABLES USING A CURRENCY-INDICATING       */
/*        VARIABLE.                                                        */
/*                                                                         */
/*     The single-currency variables will have the same names as the       */
/*     mixed-currency variables, but with a suffix added according to the  */
/*     currency. The suffix for each currency will be the values specified */
/*     directly below when creating the macro variables CURR1, CURR2 and   */
/*     CURR3.                                                              */
/*                                                                         */
/*     For example, if the variable REBATEH is a mixed-currency variable   */
/*     with both peso and U.S. dollar values indicated by "PESO" and "USD" */
/*     under the variable CURRENCY, you would type:                        */
/*                                                                         */
/*          LET CURRTYPE = CURRENCY                                        */
/*          LET CUR1 = PESO                                                */
/*          LET CUR2 = USD                                                 */
/*          LET CUR3 = NA                                                  */
/*                                                                         */
/*     The single-currency variables created would be called REBATEH_PESO  */
/*     and REBATEH_USD.                                                    */
/*                                                                         */
/*     In the example above, a peso-denominated transaction for which      */
/*     REBATEH=100 would result in REBATEH_PESO=100 and REBATEH_USD=0.     */
/*     If it were instead a dollar-denominated transaction, the opposite   */
/*     would happen with REBATEH_PESO=0 and REBATEH_USD=100.               */
/*-------------------------------------------------------------------------*/

%MACRO SETUP_MIXEDCURR_VAR;
    %IF %UPCASE(&MIXEDCURR) = YES %THEN
    %DO;
        %GLOBAL MIXEDVARS CURRTYPE CUR1 CUR2 CUR3;
        %LET MIXEDVARS = <  >; /*(V) List all mixed-currency variables.    */
        %LET CURRTYPE  = <  >; /*(V) Variable that indicates the currency  */
                               /*    of each transaction. Type "NA"        */
                               /*    (without quotes) when a currency is   */
                               /*    not used.                             */
        %LET CUR1 = <  >;      /*(T) How transactions in currency #1 are   */
                               /*    indicated exactly in {CURRTYPE}. (No  */
                               /*    quotes.)                              */
        %LET CUR2 = <  >;      /*(T) How transactions in currency #2 are   */
                               /*    indicated exactly in {CURRTYPE}. (No  */
                               /*    quotes.)                              */
        %LET CUR3 = <NA>;      /*(T) How transactions in currency #3 are   */
                               /*    indicated exactly in {CURRTYPE}. (No  */
                               /*    quotes.) Default "NA" (without        */
                               /*    quotes) when not used.                */
    %END;

%MEND SETUP_MIXEDCURR_VAR;

%SETUP_MIXEDCURR_VAR;

%HM2_MIXEDCURR(&SALESDB)

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-A-ii: SPLIT MIXED-CURRENCY VARIABLES USING CASE-SPECIFIC LANGUAGE.    */
/*                                                                         */
/*     In the absence of a variable indicating which transactions are in   */
/*     each currency, you must first turn off the macros that use a        */
/*     currency-indicating variable. You can do this either by typing      */
/*     'LET MIXEDCURR = NA' in 1-E-ii above, or by deactivating both the   */
/*     SETUP_MIXEDCURR_VAR and HM2_MIXEDCURR macros immediately above in   */
/*     section 4-A-i. Then, immediately below, activate the data step and  */
/*     write your own case-specific language. The language you write       */
/*     should split mixed-currency variables into multiple single-currency */
/*     variables.                                                          */
/*-------------------------------------------------------------------------*/

    /*
    DATA HMSALES;
        SET HMSALES;

        < Put case-specific language splitting mixed-currency
          variables here >
    RUN;
    */

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-B:     CREATE AGGREGATE PRICE ADJUSTMENT VARIABLES AND NET PRICES     */
/*                                                                         */
/*     If a particular aggregate variable is not applicable, then set it   */
/*     equal to zero.                                                      */
/*                                                                         */
/*     The final aggregate variables should be in the currency in which    */
/*     costs are incurred (usually HM currency). For example, if you have  */
/*     two movement expenses in HM currency (INLFTCH and INFLTWH)and one   */
/*     in US dollars (INSUREH), first create HM- and USD-specific movement */
/*     variables, leaving them in their original currency. Then set the    */
/*     aggregate variable (HMMOVE) equal to the sum of the two currency-   */
/*     specific variables, converting into HM currency as needed. Here is  */
/*     an example using the variables above and a HM market of Brazil:     */
/*                                                                         */
/*              MOVE_HM = INLFTCH + INFLTWH;                               */
/*              MOVE_USD = INSUREH;                                        */
/*              HMMOVE = MOVE_HM + (MOVE_USD/EXRATE_BRAZIL);               */
/*                                                                         */
/*     NOTE1:   Remember to use the new, split names for mixed-variables   */
/*              from section 4-A-i above.                                  */
/*                                                                         */
/*     NOTE2:   It is the unconverted, single-currency aggregate variables */
/*              (i.e., MOVE_HM and MOVE_USD in the example) and NOT HMMOVE */
/*              that should be weight-averaged at the end of this program  */
/*              for price-2-price comparisons with U.S. sales.             */
/*              (See Sect. 9-B-i below.)                                   */
/*                                                                         */
/*     When you have aggregate variables whose components are all in a     */
/*     currency other than the HM currency, first create an unconverted    */
/*     currency-specific aggregate variable and then do the conversion in  */
/*     the final HM aggregate variable. If, in the example earlier in this */
/*     note, INFLTCH, INFLTWH and INSUREH were all in U.S. dollars, you    */
/*     would type:                                                         */
/*                                                                         */
/*          MOVE_USD = INLFTCH + INFLTWH + INSUREH;                        */
/*          HMMOVE = MOVE_USD/EXRATE_BRAZIL;                               */
/*                                                                         */
/*     You would then have an unconverted aggregate variable (i.e.,        */
/*     MOVE_USD) to use in the final weight average in Sect. Part 10-B-i.  */
/*     (Note:  you would NOT use the converted HMMOVE in the weight        */
/*     average in this case.)                                              */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/* 4-B-i: CALCULATION OF AGGREGATE VARIABLES:                              */
/*-------------------------------------------------------------------------*/

DATA HMSALES;
    SET HMSALES;

    %GLOBAL NETPRICE;
    %MACRO NETPRICE;
        HMGUP  = <&HMGUP>; /* Gross unit price. Default is to use        */
                           /* the variable selected for the &HMGUP       */
                           /* macro in Sect. 1-E-ii above                */
        HMGUPADJ  = <0>;   /* Price adjustments to be added to HMGUP     */
        HMDISREB  = <0>;   /* Discounts, rebates & other price           */
                           /* adjustments to be subtracted from HMGUP    */
        HMMOVE    = <0>;   /* Movement expenses                          */
        HMCRED    = <0>;   /* Imputed credit expense                     */
        HMDSELL   = <0>;   /* Direct selling expenses, excluding HMCRED  */
        HMICC     = <0>;   /* Imputed inventory carrying expenses        */
        HMISELL   = <0>;   /* Indirect selling expenses, excluding HMICC */
                           /*                                            */
        HMCOMM    = <0>;   /* Commissions                                */
        HMPACK    = <0>;   /* Packing                                    */

        /*-----------------------------------------------------------*/
        /* 4-B-i-a: Indirect selling expenses for commission offsets.*/
        /*-----------------------------------------------------------*/

        HMINDCOM  = <0>;   /* Set default value of zero for when     */
                           /* HMCOMM is greater than zero.           */

        /*-----------------------------------------------------------*/
        /* 4-B-i-b: When the variables going into both HMISELL and   */
        /*          HMICC are reported entirely in HM currency, use  */
        /*          the default language immediately following.      */
        /*-----------------------------------------------------------*/
 
        IF HMCOMM = 0 THEN
            HMINDCOM = HMISELL + HMICC;

        /*-----------------------------------------------------------*/
        /*  4-B-i-c: If either HMISELL or HMICC are split into       */
        /*           multiple currencies or reported in non-HM       */
        /*           currency, deactivate the default language above */
        /*           and activate the exemplary language immediately */
        /*           following adjusting for circumstances.          */
        /*-----------------------------------------------------------*/

        /*               
        IF HMCOMM = 0 THEN  
        DO;
          HMINDCOM_MXN = INDIRSH_MXN + HMICC; 
          HMINDCOM_USD = INDIRSH_USD;
          HMINDCOM = HMINDCOM_MXN + (HMINDCOM_USD/EXRATE_MEXICO);
        END;
        */

        /*-------------------------------------------------------------*/
        /* 4-B-ii: CALCULATION OF NET PRICES:                          */
        /*-------------------------------------------------------------*/

        /* Net price for price comparisons. */
        /* Deduct imputed credit expenses . */

        HMNETPRI  = HMGUP + HMGUPADJ - HMDISREB - HMMOVE
                  - HMDSELL - HMCRED - HMCOMM - HMPACK;

        /* Net price for the cost test.    */
        /* Do NOT deduct imputed expenses. */

        HMNPRICOP = HMGUP + HMGUPADJ - HMDISREB - HMMOVE
                  - HMDSELL - HMISELL - HMCOMM - HMPACK;

        /* Net price for calculating the credit */
        /* ratio for CV selling expenses.       */

        CVCREDPR = HMGUP + HMGUPADJ - HMDISREB - HMMOVE;
    %MEND NETPRICE;

    %NETPRICE
RUN;

/*ep*/

PROC PRINT DATA = HMSALES (OBS = &PRINTOBS);
    TITLE3 "SAMPLE OF NET PRICE CALCULATIONS FOR HOME MARKET SALES";
RUN;

/*ep*/

/***************************************************************************/
/* PART 5: ARMS-LENGTH TEST OF AFFILIATED PARTY SALES                      */
/***************************************************************************/

%HM3_ARMSLENGTH

/*ep*/

/***************************************************************************/
/*     PART 6: ADD THE DOWNSTREAM SALES FOR AFFILIATED PARTIES THAT FAILED */
/*             THE ARMS-LENGTH TEST AND RESOLD MERCHANDISE                 */
/*                                                                         */
/*     Merge exchange rates and cost data with downstream sales. Create    */
/*     level of trade information, and calculate aggregate variables and   */
/*     net prices. Combine downstream and HM data.                         */
/*                                                                         */
/*     Activate the language in all of Sect. 6 and adjust accordingly.     */
/***************************************************************************/

%MACRO DOWNSTREAM;
    %LET DOWNSTREAMDATA = <  >;   /* (D) Downstream sales dataset filename.*/
    %LET SALESDB = DOWNSTREAM;    /*     Do not edit. Allows certain macros*/
                                  /*     (G5_DATE_CONVERT,HM2_MIXEDCURR)   */
                                  /*     to work on downstream sales.      */                                      
    DATA DOWNSTREAM;
        SET COMPANY.&DOWNSTREAMDATA;

/*-------------------------------------------------------------------------*/
/*     6-A-i: ALIGN VARIABLES IN HM AND DOWNSTREAM DATABASES               */
/*                                                                         */
/*     Variables in the downstream sales database must have the same names */
/*     and types (i.e., character v numeric) as those in the HM sales data */
/*     for the macro variables in Sect. 1-E-ii above, which are:           */
/*                                                                         */
/*          HMDATE                                                         */
/*          HMQTY                                                          */
/*          HMGUP                                                          */
/*          HMMANUF                                                        */
/*          HMPRIM                                                         */
/*          HMLOT                                                          */
/*          HMCONNUM                                                       */
/*          HMCPMATCH                                                      */
/*          HMCHAR                                                         */
/*                                                                         */
/*     If the variable names or types in the downstream data are           */
/*     different than those in the original HM sales data, make the        */
/*     required adjustments.                                               */
/*-------------------------------------------------------------------------*/

        <Rename variables on downstream sales and change variable 
         types, if necessary, to match HM sales data. Make other
         changes to downstream sales data here.>

/*-------------------------------------------------------------------------*/
/*     6-A-ii: CREATE THE HMLOT VARIABLE FOR DOWNSTREAM SALES              */
/*                                                                         */
/*     Note:  If in section 1-E-ii above for HM sales "LET HMLOT = NA"     */
/*     (because HM sales were the same LOT as U.S. sales), but downstream  */
/*     sales are at a different LOT, replace "NA" for the HM sales with a  */
/*     variable name. If no LOT variable was reported, create one in both  */
/*     the HM and downstream databases. The newly created variables should */
/*     have the same name and type (i.e., character v numeric).            */
/*-------------------------------------------------------------------------*/

        <Create a LOT variable for downstream sales or edit an 
         existing variable here, when required.>

        %G4_LOT(&HMLOT,HMLOT) 
    RUN;

/*---------------------------------------------------------------------*/
/*     6-A-iii: DATE VARIABLE CHECK, CREATION OF MONTH VARIABLE        */
/*                IN ADMINISTRATIVE REVIEWS, SALES DATA CHECK          */
/*                                                                     */
/*     Check the format of the date variable and convert if necessary. */
/*     Create the month variable in administrative reviews. Check for  */
/*     zero, missing and negative gross prices and quantities.         */
/*---------------------------------------------------------------------*/

    %G5_DATE_CONVERT
    %G6_CHECK_SALES

/*-------------------------------------------------------------------*/
/*      6-B: MERGE EXCHANGE RATES INTO DOWNSTREAM SALES, IF REQUIRED */
/*-------------------------------------------------------------------*/

    %G7_EXRATES

/*--------------------------------------------------------------*/
/*      6-C: MERGE COST DATA INTO DOWNSTREAM SALES, IF REQUIRED */
/*--------------------------------------------------------------*/

    %G17_FINALIZE_COSTDATA

/*------------------------------------------------------------------*/
/*      6-D:  CALCULATION OF AGGREGATE VARIABLES AND NET PRICES FOR */
/*               DOWNSTREAM SALES                                   */
/*------------------------------------------------------------------*/

    DATA DOWNSTREAM;
        SET DOWNSTREAM;

/*----------------------------------------------------------------------*/
/*      6-D-i:  SPLIT MIXED-CURRENCY VARIABLES WITH SAME LANGUAGE USED  */
/*                     FOR ORIGINAL HM SALES                            */
/*                                                                      */
/*     If the language in Part 4-A-i is also applicable to downstream   */
/*     sales, then just execute the two macros immediately below, i.e., */
/*     %SETUP_MIXEDCURR_VAR and %HM2_MIXEDCURR(DOWNSTREAM), by          */
/*     activating them.                                                 */
/*----------------------------------------------------------------------*/

        <%SETUP_MIXEDCURR_VAR>
        <%HM2_MIXEDCURR(DOWNSTREAM)>

/*----------------------------------------------------------------------*/
/*      6-D-ii: SPLIT MIXED-CURRENCY VARIABLES USING LANGUAGE           */
/*              DIFFERENT THAN THAT FOR ORIGINAL HM SALES               */
/*                                                                      */
/*     If the language in Part 4-A-i is not applicable to downstream    */
/*     sales, then edit the language below.                             */
/*----------------------------------------------------------------------*/

/*----------------------------------------------------------------------*/
/*      6-D-ii-a:  When there is a currency-indicating variable, using  */
/*                 the language below                                   */
/*----------------------------------------------------------------------*/

    %MACRO SETUP_MIXEDCURR_VAR;
       %IF %UPCASE(&MIXEDCURR) = YES %THEN
       %DO;
           %GLOBAL MIXEDVARS CURRTYPE CUR1 CUR2 CUR3;
           %LET MIXEDVARS = < >;   /*(V) List all mixed-currency       */
                                   /*    variables.                    */
           %LET CURRTYPE = < >;    /*(V) Variable that indicates the   */
                                   /*    currency of each transaction. */
                                   /*    Type "NA" (without quotes)    */
                                   /*    when a currency is not used.  */
           %LET CUR1 = <NA>;       /*(T) How transactions in currency  */
                                   /*    #1 are indicated exactly in   */
                                   /*    {CURRTYPE}. (No quotes.)      */
           %LET CUR2 = <NA>;       /*(T) How transactions in currency  */
                                   /*    #2 are indicated exactly in   */
                                   /*    {CURRTYPE}. (No quotes.)      */
           %LET CUR3 = <NA>;       /*(T) How transactions in currency  */
                                   /*    #3 are indicated exactly in   */
                                   /*    {CURRTYPE}. (No quotes.)      */
       %END;
    %MEND SETUP_MIXEDCURR_VAR;

    %SETUP_MIXEDCURR_VAR
    %HM2_MIXEDCURR(DOWNSTREAM)

/*---------------------------------------------------------------*/
/*      6-D-ii-b: When there is no currency-indicating variable, */
/*          write case-specific language below.                  */
/*---------------------------------------------------------------*/

    <Put case-specific language splitting mixed-currency variables here>

/*----------------------------------------------------------------*/
/*      6-D-iii: AGGREGATE VARIABLE AND NET PRICE CALCULATIONS ON */
/*               DOWNSTREAM SALES                                 */
/*----------------------------------------------------------------*/
          
    DATA DOWNSTREAM;
        SET DOWNSTREAM;

/*--------------------------------------------------------------------*/
/*      6-D-iii-a:  AGGREGATE VARIABLES AND NET PRICE CALCULATIONS    */
/*             ARE THE SAME FOR DOWNSTREAM SALES AS FOR THE ORIGINAL  */
/*                HM SALES                                            */
/*                                                                    */
/*     If the calculations for the aggregate variables and net prices */
/*     are the same for the downstream sales as for the original HM   */
/*     original HM sales, you need only activate the %NETPRICE macro  */
/*     immediately below this note.                                   */
/*--------------------------------------------------------------------*/
        <%NETPRICE>   /* Activate this line to duplicate the     */
                      /* calculations of the aggregate variables */
                      /* and net prices from Section 4-B.        */

/*-------------------------------------------------------------------*/
/*      6-D-iii-b: AGGREGATE VARIABLES AND NET PRICE CALCULATIONS    */
/*             ARE DIFFERENT FOR DOWNSTREAM SALES THAN FOR THE       */
/*               ORIGINAL HM SALES                                   */
/*                                                                   */
/*     If not all aggregate variable calculations are the same, you  */
/*     will need to copy out the aggregate variable and net price    */
/*     calculations from section 4-B and edit accordingly for the    */
/*     downstream sales. For every aggregate variable used in        */
/*     Section 4-B above for the original HM sales, including        */
/*     currency-specific ones, you will need to specify a value for  */
/*     the downstream sales. If you do not specify a value for a     */
/*     particular aggregate variable, that variable will be assigned */
/*     missing values in the downstream sales.                       */
/*-------------------------------------------------------------------*/

        <create values for all aggregate variables in section 4-B 
         and copy net price calculations>
     
    RUN;

    PROC PRINT DATA = DOWNSTREAM (OBS = &PRINTOBS);
        TITLE3 "SAMPLE OF DOWNSTREAM SALES WITH NET PRICE CALCULATIONS";
    RUN;

/*-------------------------------------------------------------------------*/
/*      6-E: COMBINE ORIGINAL HM SALES WITH DOWNSTREAM SALES               */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/*     6-E-i: CREATION OF NEEDED VARIABLES IN HM SALES BEFORE COMBINING    */
/*            WITH DOWNSTREAM SALES                                        */
/*                                                                         */
/*     You may need to create new currency-specific aggregate variables in */
/*     the original HM sales for any aggregate variable in the downstream  */
/*     sales that is not already in the HM sales data. If you do, activate  /
/*     the language immediately following and edit accordingly. You should */
/*     assign values equal to zero for those new aggregate variables in the*/
/*     original HM sales before they are combined with downstream sales in */
/*     next step. If you do not assign a zero, then missing values will be */
/*     assigned, instead, once the HM and downstream sales databases are   */
/*     combined.                                                           */
/*-------------------------------------------------------------------------*/

    DATA HMSALES;
       SET HMSALES;
        <In HMSALES, add aggregate variables that appear in
         downstream data but are not in HM data, and set the
         values of those variables to zero.> 
    RUN;

/*------------------------------------------------------------*/
/*     6-E-ii: COMBINE ORIGINAL HM SALES AND DOWNSTREAM SALES */
/*------------------------------------------------------------*/

    %LET SALESDB = HMSALES;

    DATA HMSALES;
        SET HMSALES DOWNSTREAM;
    RUN;
%MEND DOWNSTREAM;

/* %DOWNSTREAM */

/*ep*/

/***************************************************************************/
/* PART 7: HM VALUES FOR CEP PROFIT CALCULATIONS                           */
/*                                                                         */
/*     If required, an output dataset will be created using the            */
/*     standardized naming convention, 'RESPONDENT_SEGMENT_STAGE'_HMCEP.   */
/***************************************************************************/

%HM4_CEPTOT

/*ep*/

/***************************************************************************/
/* PART 8: COST TEST                                                       */
/***************************************************************************/

%HM5_COSTTEST

/*ep*/

/***************************************************************************/
/* DATA COUNT FOR LOG REPORTING PURPOSE                            */
/***************************************************************************/

%CMAC2_COUNTER (DATASET = HMSALES, MVAR=HMSALES_CTEST);

/*ep*/

/***************************************************************************/
/* PART 9:  WEIGHT-AVERAGED HOME MARKET VALUES FOR PRICE-TO-PRICE          */
/*               COMPARISONS WITH U.S. SALES                               */
/*                                                                         */
/*     Create an output dataset using the standardized naming convention,  */
/*     'RESPONDENT_SEGMENT_STAGE'_HMWTAVG. Rename certain variables to     */
/*     standardized names: HMCONNUM, HMLOT and, if applicable, HMMANF,     */
/*     HMPRIME, VCOMHM and TCOMHM.                                         */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 9-A: SELECT HM DATA TO WEIGHT AVERAGE                                   */
/*                                                                         */
/*     If there is a Cost Test, then above-cost sales will be used in the  */
/*     calculation of weighted-average HM sales. If there was no Cost      */
/*     then all HM sales, after the Arms-Length Test and inclusion of      */
/*     downstream sales, if required, will be used.                        */
/*-------------------------------------------------------------------------*/

     %HM6_DATA_4_WTAVG

/*ep*/

/*-------------------------------------------------------------------------*/
/* 9-B: SELECT HM VARIABLES TO WEIGHT AVERAGE                              */
/*                                                                         */
/*     HM weighted-average values will be converted into U.S. dollars in   */
/*     the Margin Program using exchange rates on the U.S. sale dates.     */
/*     Therefore, it is IMPORTANT TO WEIGHT-AVERAGE ONLY SINGLE-CURRENCY   */
/*     HM VARIABLES IN THEIR ORIGINAL CURRENCY.                            */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/* 9-B-i: HM DATA IS IN MORE THAN ONE CURRENCY                             */
/*                                                                         */
/*     If amounts in the HM database were reported in more than one        */
/*     currency, then edit the %LET WTAVGVARS macro variable directly      */
/*     below.                                                              */
/*                                                                         */
/*     Look at the aggregate variable calculations Part 4-B-i. Those       */
/*     aggregate variables that are comprised entirely of variables        */
/*     originally reported in the HM currency can be left as is. However,  */
/*     those aggregate variables that are either: 1) converted into a      */
/*     currency other than the original, or 2) are a mixture of            */
/*     currencies, must be edited. Mixed currency aggregate variables      */
/*     must be split apart by currency. List all single-currency           */
/*     components in original currency. Ex.: if you have in Part 4-B-i:    */
/*     HMMOVE = MOVE_EURO + MOVE_USD/&EXRATE_EURO, replace the "HMMOVE"    */
/*     below with "MOVE_EURO" and "MOVE_USD"                               */
/*-------------------------------------------------------------------------*/

%MACRO WTAVGVARS;
    %GLOBAL WGTAVGVARS;

    %IF %UPCASE(&HM_MULTI_CUR) = YES %THEN
    %DO;
    %IF %UPCASE(&HM_MULTI_CUR) = YES OR %UPCASE(&MIXEDCURR) = YES %THEN
        %LET WGTAVGVARS = <HMGUP HMGUPADJ HMDISREB HMMOVE
                           HMCRED HMDSELL HMCOMM HMICC HMISELL
                           HMINDCOM HMPACK>;
    %END;

/*-------------------------------------------------------------------------*/
/* 9-B-ii: HM DATA IS ALL IN ONE CURRENCY                                  */
/*                                                                         */
/*     If amounts in the HM database were reported entirely in one         */
/*     currency, and use of an exchange rate was not required, aggregate   */
/*     amounts will be automatically weight-averaged.                      */
/*-------------------------------------------------------------------------*/

    %ELSE
    %IF %UPCASE(&HM_MULTI_CUR) = NO AND %UPCASE(&MIXEDCURR) = NO %THEN
    %DO;
        %LET WGTAVGVARS = HMNETPRI HMCRED HMDSELL HMCOMM
                          HMICC HMISELL HMINDCOM;
    %END;
%MEND WTAVGVARS;

%WTAVGVARS

/*-------------------------------------------------------------------------*/
/* 9-C: WEIGHT-AVERAGE HM DATA                                             */
/*                                                                         */
/*     Standardize names of certain HM variables that will be carried to   */
/*     the Margin Calculation Program: HMCONNUM, HMLOT and, if applicable, */
/*     HMMANF, HMPRIME, HMVCOM and HM_TIME_PERIOD. Create and output       */
/*     database using the standardized naming convention,                  */
/*     'RESPONDENT_SEGMENT_STAGE'_HMWTAVG.                                 */
/*-------------------------------------------------------------------------*/

%HM7_WTAVG_DATA

/*ep*/

/***************************************************************************/
/* PART 10: CALCULATE SELLING EXPENSE AND PROFIT RATIOS FOR                */
/*             CONSTRUCTED-VALUE COMPARISONS                               */
/*                                                                         */
/*     Create an output dataset using the standardized naming convention,  */
/*     'RESPONDENT_SEGMENT_STAGE'_HMCV.                                    */
/***************************************************************************/

%HM8_CVSELL

/*ep*/

/***************************************************************************/
/* PART 11: HM LEVEL OF TRADE ADJUSTMENT                                   */
/*                                                                         */
/*     Create LOT adjustment factors. Output a dataset using the           */
/*     standardized naming convention, 'RESPONDENT_SEGMENT_STAGE'_LOTADJ.  */
/***************************************************************************/

%HM9_LOTADJ

/*ep*/

/***************************************************************************/
/* PART 12: DELETE ALL WORK FILES IN THE SAS MEMORY BUFFER, IF DESIRED     */
/***************************************************************************/

%G18_DEL_ALL_WORK_FILES

/*ep*/

/***************************************************************************/
/* PART 13: CALCULATE RUN TIME FOR THIS PROGRAM, IF DESIRED                */
/***************************************************************************/

%G19_PROGRAM_RUNTIME

/*ep*/

/***************************************************************************/
/* PART 14: REVIEW LOG AND REPORT SUMMARY AT THE END OF THE LOG FOR:       */
/*          (A) GENERAL SAS ALERTS SUCH AS ERRORS, WARNINGS, MISSING, ETC. */
/*          (B) PROGRAM SPECIFIC ALERTS THAT WE NEED TO LOOK OUT FOR.      */
/***************************************************************************/

%CMAC4_SCAN_LOG(ME_OR_NME = MEHOME); 

/*ep*/
