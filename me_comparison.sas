/***************************************************************************/
/*                        ANTIDUMPING MARKET-ECONOMY                       */
/*                    ANALYSIS OF COMPARISON-MARKET SALES                  */
/*                                                                         */
/*                  LAST PROGRAM UPDATED SEPTEMBER 15, 2016                */
/*                                                                         */
/* Part 1:  Database and General Program Information                       */
/* Part 2:  Bring In Comparison Market Sales, Convert Date Variable, If    */
/*          Necessary, Merge Exchange Rates Into CM Sales, As Required     */
/* Part 3:  Cost Information                                               */
/* Part 4:  Comparison Market Net Price Calculations                       */
/* Part 5:  Arm's-Length Test of Affiliated Party Sales                    */
/* Part 6:  Add the Downstream Sales for Affiliated Parties That Failed    */
/*          the Arm's-Length Test and Resold Merchandise                   */
/* Part 7:  CM Values for CEP Profit Calculations                          */
/* Part 8:  Cost Test                                                      */
/* Part 9:  Weight-Averaged Comparison Market Values for Price-To-Price    */
/*          Comparisons with U.S. Sales                                    */
/* Part 10: Calculate Selling Expense and Profit Ratios for                */
/*          Constructed-Value Comparisons                                  */
/* Part 11: CM Level of Trade Adjustment                                   */
/* Part 12: Delete All Work Files in the SAS Memory Buffer, If Desired     */
/* Part 13: Calculate Run Time for This Program, If Desired                */
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

/*------------------------------------------------------------*/
/* NAME OF PROGRAMMER: <Case Analyst Name>                    */ /*(T)*/
/*                                                            */
/* PROGRAM NAME:       <Program Name>                         */ /*(T)*/
/* PROGRAM LOCATION:   <C:\>                                  */ /*(T)*/
/*------------------------------------------------------------*/

/************************************************************************/
/* PART 1: DATABASE AND GENERAL PROGRAM INFORMATION                     */
/************************************************************************/

/*------------------------------------------------------------------*/
/* 1-A:     PROCEEDING TYPE                                         */
/*------------------------------------------------------------------*/

%LET CASE_TYPE = <AR/INV>;  /*(T) For an investigation, type 'INV' */
                            /*    (without quotes)                 */
                            /*    For an administrative review,    */
                            /*    type 'AR' (without quotes)       */

/*----------------------------------------------------------------------*/
/* 1-B: DATE INFORMATION                                                */
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
/*          price-to-price comparisons of CM and US sales, comparisons  */
/*          are not made outside of designated time periods. In such    */
/*           cases, set BEGINWIN to the first day of the first time     */
/*          period. Likewise, set ENDDAY to the last day of the last    */
/*          time period.                                                */
/*----------------------------------------------------------------------*/

%LET BEGINDAY = <DDMONYYYY>;  /*(T) Day 1 of first month of CM sales to be */
                              /*    captured for comparison to U.S. sales. */
%LET ENDDAY   = <DDMONYYYY>;  /*(T) Last day of last month of CM sales to  */
                              /*    be captured for comparison to          */
                              /*    U.S. sales.                            */

/*-------------------------------------------------------------------*/
/* 1-C: LOCATION OF DATA AND MACROS PROGRAM                          */
/*                                                                   */
/*     LIBNAME =      The name (i.e., COMPANY) and location of the   */
/*                 sub-directory containing the SAS datasets for     */
/*                    this program.                                  */
/*                                                                   */
/*     %INCLUDE =     Full path of the Macro Program for this case,  */
/*                    consisting of the sub-directory containing the */
/*                    Macro Program and its file name.               */
/*-------------------------------------------------------------------*/

LIBNAME COMPANY '<C:\....>';                 /* Location of company and  */
                                             /* exchange rate data sets. */
FILENAME MACR   '<C:\...\MacrosProgram.SAS'; /* Location & name of AD-ME */
                                             /* All Macros Program.      */
%INCLUDE MACR;                               /* Use the AD-ME All Macros */
                                             /* Program.                 */

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
/*          {RESPONDENT_SEGMENT_STAGE}_CMCEP   = CM revenue/expenses for   */
/*                                               CEP profit                */
/*          {RESPONDENT_SEGMENT_STAGE}_CVSELL  = Selling & profit ratios   */
/*                                               for CV                    */
/*          {RESPONDENT_SEGMENT_STAGE}_CMWTAV  = Wt-avg CM data            */
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
/* 1-E: DATABASE INFORMATION FOR CM SALES, COSTS & EXCHANGE RATES    */
/*                                                                   */
/*     Where information may not be relevant (e.g., re: manufacturer */
/*     and prime/non-prime merchandise), 'NA' (not applicable) will  */
/*     appear as the default value.                                  */
/*-------------------------------------------------------------------*/

/*---------------------------------------------------------------*/
/*     1-E-i. EXCHANGE RATE INFORMATION:                         */
/*                                                               */
/*      The CM program needs to use exchange rates if there are  */
/*      reported adjustments in non-CM currency. If there are    */
/*      no non-CM currencies, define the macro variables         */
/*      USE_EXRATES1 and USE_EXRATES2 as NO.                     */
/*                                                               */
/*      If there are non-CM currencies, define the macro         */
/*      variable USE_EXRATES1 as YES for the first non-CM        */
/*      currency and define the macro variable EXDATA1 as the    */
/*      name of the exchange rate dataset. If there is a second  */
/*      non-CM currency, define the macro variable USE_EXRATES2  */
/*      as YES and define the macro variable EXDATA2 as the      */
/*      name of the second exchange rate dataset. If there are   */
/*      more than two non-CM currencies, please contact a SAS    */
/*      Support Team member for assistance.                      */
/*                                                               */
/*      When non-CM currencies are reported, there are three     */
/*      ways to refer to exchange rate variables in your         */
/*      CMProgram programming. If the first non-CM currency is   */
/*      from Mexico, you can code the first exchange rate        */
/*      variable as EXRATE_MEXICO, &EXRATE1, or EXRATE_&EXDATA1. */
/*      If the second non-CM currency is from Canada, you can    */
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

/*--------------------------------------------------------------*/
/* 1-E-ii. COMPARISON MARKET INFORMATION                        */
/*--------------------------------------------------------------*/

%LET CMDATA = <  >;             /*(D) CM sales dataset filename.           */
%LET   CMCONNUM = <  >;         /*(V) Control number                       */
%LET   CMCPPROD = <  >;         /*(V) Variable (usually CONNUMH) linking   */
                                /*    sales to cost data.                  */
%LET   CMCHAR = <  >;           /*(V) Product matching characteristics.    */
                                /*    List them from left to right         */
                                /*    in order of importance, with no      */
                                /*    punctuation separating them.         */
%LET   CMDATE = <  >;           /*(V) Sale date.                           */
%LET   CMQTY = <  >;            /*(V) Quantity.                            */
%LET   CMGUP  = <  >;           /*(V) Gross price. Need not be in          */
                                /*    consistent currency, used only to    */
                                /*    check for zero, negative & missing   */
                                /*    values.                              */
%LET   CMLOT  = <NA>;           /*(V) Level of trade. If not reported in   */
                                /*    the database and not required, type  */
                                /*    "NA" (without quotes).               */
                                /*    You may also type "NA" if CM & US    */
                                /*    both have only 1 LOT & those LOTs    */
                                /*    are the same.                        */
%LET   CMMANUF = <NA>;          /*(V) Manufacturer code. If not            */
                                /*    applicable, type "NA" (without       */
                                /*    quotes).                             */
%LET   CMPRIME  = <NA>;         /*(V) Prime/seconds code. If not           */
                                /*    applicable, type "NA" (without       */
                                /*    quotes).                             */
%LET   CM_TIME_PERIOD = <  >;   /*(V) Variable in CM data for cost-related */
                                /*     time periods, if applicable         */
%LET   CM_MULTI_CUR = <YES/NO>; /*(T) Is CM data in more than one          */
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
/*     If the respondent has reported both a CM COP database and */
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

/*------------------------------------------------------*/
/* 1-E-iii-a. TIME-SPECIFIC COSTS                       */
/*                                                      */
/*     If you type COMPARE_BY_TIME = YES on the first   */
/*     line, also complete the rest of this section     */
/*------------------------------------------------------*/

%LET COMPARE_BY_TIME = <YES/NO>;            /* (T) Calculate costs by time */
                                            /* periods? Type "YES" or "NO" */
                                            /* (without quotes).           */
%LET      INDEX_SOURCE = <CALC/INPUT/RESP>; /*(T) Type "CALC" (without     */
                                            /*    quotes) to calculate     */
                                            /*    indices within this      */
                                            /*    program. Also complete   */
                                            /*    Sect.3-D-ii-b.           */
                                            /*    Type "INPUT" (without    */
                                            /*    quotes) to input         */
                                            /*    supplied indices. Also   */
                                            /*    complete Sect.3-D-ii-a   */
                                            /*    Type "RESP" (without     */
                                            /*    quotes) if respondent    */
                                            /*    has already done the     */
                                            /*    indexing.                */
%LET      COST_TIME_PERIOD = <  >;          /*(V) Variable in cost data    */
                                            /*    for time periods, if     */
                                            /*    applicable.              */
%LET      TIME_INSIDE_POR  = <  >;          /*(T) List of values of        */
                                            /*    &COST_TIME_PERIOD        */
                                            /*    variable for periods     */
                                            /*    during the POR,          */
                                            /*    separated by commas,     */
                                            /*    quotes around character  */
                                            /*    data. E.g., "Q1", "Q2",  */
                                            /*    "Q3", "Q4"               */
%LET      TIME_OUTSIDE_POR = <NA>;          /*(T) List of values of        */
                                            /*    &COST_TIME_PERIOD        */
                                            /*    variable for periods     */
                                            /*    outside of the POR,      */
                                            /*     separated by commas,    */
                                            /*    quotes around character  */
                                            /*    data, E.g., "Q5","Q6".   */
                                            /*    If there are only        */
                                            /*    periods inside the POR,  */
                                            /*    type "NA" without quotes.*/
%LET      TIME_ANNUALIZED  = <NA>;          /*(T) List of values of        */
                                            /*    &COST_TIME_PERIOD        */
                                            /*    variable for products    */
                                            /*    that have annualized     */
                                            /*    (i.e., NOT time-specific)*/
                                            /*    costs, separated by      */
                                            /*    commas, quotes around    */
                                            /*    character data, e.g.,    */
                                            /*    "POR" If not applicable, */
                                            /*    type "NA" without quotes.*/

/*--------------------------------------------------------*/
/* 1-E-iii-b. SURROGATE COSTS FOR NON-PRODUCTION          */
/*                                                        */
/*     If you have products that were sold but not        */
/*     produced during the period and that do not already */
/*     have adequate surrogate cost information reported, */
/*     type 'MATCH_NO_PRODUCTION=YES' on the first line   */
/*     and complete the rest of this section.             */
/*--------------------------------------------------------*/

%LET MATCH_NO_PRODUCTION = <YES/NO>; /*(T) Find surrogate costs for        */
                                     /*    products not produced during    */
                                     /*    the POR?  Type "YES" or "NO"    */
                                     /*    (without quotes). If "YES,"     */
                                     /*    complete the indented macro     */
                                     /*    variables that follow.          */
%LET    COST_PROD_CHARS = <YES/NO>; /*(T) Are the product physical         */
                                    /*    characteristic variables in the  */
                                    /*    cost database? Type "YES" or     */
                                    /*    "NO" without quotes).            */
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
/*          If you select YES for THE RUN_ARMSLENGTH or RUN_CMLOTADJ    */
/*          macro variables, also complete the ones immediately         */
/*          following and indented.                                     */
/*                                                                      */
/*            Note: Results of the CMLOTADJ calculation are meaningless */
/*          unless the following criteria are met:                      */
/*               1. There are two or more levels of trade in CM data    */
/*               2. At least one of those two CM levels of trade also   */
/*                   exist in the U.S. data.                            */
/*----------------------------------------------------------------------*/

%LET RUN_ARMSLENGTH = <YES/NO>; /*(T) Run the Arm's-Length test? Type      */
                                /*    "YES" or "NO" (without quotes).      */
%LET     CMCUST    = <   >;     /*(V) Customer identifier/code             */
%LET     CMAFFL    = <   >;     /*(V) Customer affiliation code            */
%LET     NAFVALUE  = < 1 >;     /*(T) Value in data indicating             */
                                /*    unaffiliated sales. Default is       */
                                /*    numeric value of 1.                  */
%LET RUN_CMCEPTOT = <YES/NO>;   /*(T) Calculate CM revenue and expenses    */
                                /*    for CEP profit? Type "YES" or "NO"   */
                                /*    (without quotes). If you type "YES," */
                                /*    you must have a cost database.       */
%LET RUN_CMLOTADJ = <YES/NO>;   /*(T) Run LOT price pattern calculation?   */
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

%LET SALESDB = CMSALES;

%G1_RUNTIME_SETUP
%G2_TITLE_SETUP
%G3_COST_TIME_MVARS

/*----------------------------------------------------------------------*/
/* 1-I: PRIME AND MANUFACTURER MACROS AND MACRO VARIABLES               */
/*                                                                      */
/*          In the programming language, the macro variables &CMPRIM,   */
/*          &CMMANF and &COPMANF are used. Their values are determined  */
/*          by the answers in Sect.1-E-ii above.                        */
/*          For example, if you typed %LET CMMANUF=NA, then the macro   */
/*          variable &CMMANF will be set to a null/blank value.         */
/*          Otherwise, &CMMANF will be equal to the variable specified  */
/*          in %LET CMMANUF=<???>.                                      */
/*                                                                      */
/*          Similarly, &CMPRIM and &COPMANF will either be a null/blank */
/*          values, or set equal to the variables specified in          */
/*          %LET CMPRIME=<???> and %LET COPMANUF=<???>.                 */
/*----------------------------------------------------------------------*/

%CM1_PRIME_MANUF_MACROS

/*************************************************************************/
/* PART 2: BRING IN COMPARISON MARKET SALES, CONVERT DATE VARIABLE,      */
/*         IF NECESSARY, MERGE EXCHANGE RATES INTO CM SALES, AS REQUIRED */
/*************************************************************************/

/*----------------------------------------------------------------------*/
/* 2-A: BRING IN COMPARISON MARKET SALES                                */
/*                                                                      */
/*          Alter the SET statement, if necessary, to bring in more     */
/*          than one SAS database. If you need to rename variables,     */
/*          change variables from character to numeric (or vice versa), */
/*          in order to do align the various databases, make such       */
/*          changes here.                                               */
/*                                                                      */
/*          Changes to CM data using exchange rates and costs should    */
/*          wait until Part 4, below, after the cost and exchange rate  */
/*          databases are attached.                                     */
/*                                                                      */
/*          Leave the data step open through the RUN statement          */
/*          following the execution of the G4_LOT macro in Sect 2-C-ii  */
/*----------------------------------------------------------------------*/

DATA CMSALES;
    SET COMPANY.&CMDATA;

    /*------------------------------------------------------------------*/
    /* 2-B: Insert and annotate any changes below.                      */
    /*------------------------------------------------------------------*/

    /* <Insert changes here, if required.> */

    /*-----------------------------------------------------------------------
    /* 2-C: LEVEL OF TRADE                                                 */
    /*                                                                     */
    /*      The variable CMLOT will be created containing the levels       */
    /*          of trade. It is this variable that is used in the          */
    /*          programming. If you typed '%LET CMLOT = NA' in             */
    /*          Sect.1-E-ii above, the variable CMLOT will be set to 0     */
    /*          (zero). Otherwise, CMLOT will be set equal to the variable */
    /*          specified in %LET CMLOT = <???>.                           */
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

    %G4_LOT(&CMLOT,CMLOT)

RUN;

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
/*          value of CMMONTH will be equal to the normal numeric       */
/*          month designation (e.g., Jan=1, Feb=2). In the second      */
/*          calendar year of the review, CMMONTH will be equal to      */
/*          the numeric month designation + 12 (e.g., Jan=1+12=13).    */
/*          Similarly, in a third calendar year, CMMONTH = month+24.   */
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

/***************************************************************************/
/* PART 3: COST INFORMATION                                                */
/*                                                                         */
/*          If the respondent has supplied separate COP and CV databases,  */
/*          combine them together in this program in sect. 3-B and make    */
/*          required adjustments, including indexing of inputs. The        */
/*          combined weight-averaged cost database calculated in this      */
/*          program can then also be used in the Margin Program with U.S.  */
/*          sales. This is preferable to calculating the two individually. */
/*                                                                         */
/*          Make required changes to items in the indicated sections as    */
/*          needed:                                                        */
/*                                                                         */
/*          Sect.3-A-i        Pre-indexing changes                         */
/*          Sect.3-B-ii-a     Align CM and U.S. CONNUMS, product chars.    */
/*          Sect.3-D-i        Indexed inputs                               */
/*          Sect.3-D-ii       Time-specific indices                        */
/*          Sect.3-F          Cost of manufacturing, G&A, interest, and    */
/*                            cost of production                           */
/***************************************************************************/

/*----------------------------------------------------------------------*/
/* 3-A     CALL UP COST DATA, INCLUDING A SEPARATE CV DATABASE, IF      */
/*          PROVIDED. MAKE PRE-INDEXING CHANGES TO DATA.                */
/*                                                                      */
/*          Make changes to cost inputs, manufacturer, etc., calculate  */
/*          major input adjustments, and make any other edits here that */
/*          need to be done before indexing is executed in section 3-E. */
/*          In order to keep track of pre-indexing information on       */
/*          inputs to be indexed and the final indexed values of the    */
/*          same, do not overwrite the reported input variable.         */
/*          Instead, create a new variable that either: 1) already      */
/*          contains the adjustments and is ready to be indexed, or     */
/*          2) contains the pre-indexed adjustments which can be        */
/*          added/subtracted/multiplied by the reported value below in  */
/*          Sect.3-D-i.                                                 */
/*                                                                      */
/*          Do NOT make changes to GNA, INTEX or the calculation        */
/*          of TOTCOM here. Instead, do these below in section 3-E,     */
/*          after indexing of inputs is completed.                      */
/*                                                                      */
/*          Also, do NOT reset missing or zero production quantities    */
/*          to positive values at this point with the exception noted   */
/*          in the next paragraph. The resetting of zero/missing        */
/*          production quantities before weight averaging will be done  */
/*          later in Section 3-E below.                                 */
/*                                                                      */
/*          For annualized (not time-specific) costs, if the respondent */
/*          has already provided surrogate cost information for a       */
/*          particular product but has put either a zero or a missing   */
/*          value for production quantity, then the default language    */
/*          in Sect. 3-B will mistakenly mark the product as one still  */
/*          requiring surrogate information. For annualized costs       */
/*          only, you can remedy this by setting the production         */
/*          quantity to a non-zero or non-missing value in Sect 3-A-i.  */
/*                                                                      */
/*          Similarly, for time-specific costs, reported surrogate      */
/*          cost information will be ignored and products instead       */
/*          designated as those still requiring surrogates if total     */
/*          production during the annual cost period is zero or missing.*/
/*          The production quantities of the surrogate product are      */
/*          required for indexing. Setting the production quantities    */
/*          to arbitrary values will calculate indexed input values     */
/*          incorrectly, with the products requiring surrogate costs    */
/*          having different indexed input values than the products     */
/*          which supplied the surrogate information.                   */
/*----------------------------------------------------------------------*/

/**********************************************************/
/* CONNUMUs in the CM and U.S. datasets that have sales   */
/* but no production in the POI/POR must be in the COP    */
/* dataset with a production quantity of 0 (zero). If     */
/* respondent does not report these CONNUMs in the cost   */
/* dataset, the analyst must add these CONNUMs to the COP */
/* dataset with a production quantity of 0 (zero).        */
/**********************************************************/


DATA COST;
    SET COMPANY.&COST_DATA /* <COMPANY.CVDATABASE> */;

    /*------------------------------------------------------*/
    /* 3-A-i: Insert pre-indexing changes.                  */
    /*------------------------------------------------------*/

    /* <Make pre-indexing changes to cost here> */

RUN;

/*ep*/

/*-----------------------------------------------------------------*/
/* 3-B SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POI/POR    */
/*-----------------------------------------------------------------*/

/*-----------------------------------------------------------------*/
/*     3-B-i IDENTIFY PRODUCTS NOT PRODUCED DURING POI/POR         */
/*           FOR WHICH SURROGATE COSTS ARE NEEDED.                 */
/*                                                                 */
/*     The macro variable &FIND_SURROGATES will be created whose   */
/*     value will be "YES" when it does find products requiring    */
/*     surrogates using the criteria specified. Otherwise,         */
/*     &FIND_SURROGATES will be set to "NO," turning off sections  */
/*     3-B-ii-a and 3-G. If &FIND_SURROGATES=NO, then you will not */
/*     need to supply information in 3-B-ii-a on U.S. product      */
/*     characteristic variables.                                   */
/*                                                                 */
/*     The %G8_FIND_NOPRODUCTION macro below identifies products   */
/*     needing surrogate cost information when total production    */
/*     during the annual cost period is zero or missing. If this   */
/*     assumption does not fit the circumstances, you will need    */
/*     to make edits accordingly.                                  */
/*                                                                 */
/*     For annualized (not time-specific) costs, if the respondent */
/*     has already provided surrogate cost information for a       */
/*     particular product but has put either a zero or a missing   */
/*     value for production quantity, then the default language    */
/*     will mistakenly think no surrogate information has been     */
/*     provided. For annualized costs only, you can remedy this    */
/*     problem by setting the production quantity to a non-zero or */
/*     non-missing value above in Sect. 3-A-i.                     */
/*                                                                 */
/*     For time-specific costs, if the respondent has reported     */
/*     either zero or missing values for production quantities     */
/*     for all quarters during the period on products with         */
/*     surrogate cost information reported, the production         */
/*     quantities for the surrogate product must be used instead.  */
/*     Replace the zero/missing values with the surrogate's        */
/*     production quantities above in Sect. 3-A-i.                 */
/*-----------------------------------------------------------------*/

%MACRO NOPRODUCTION;
    %GLOBAL FIND_SURROGATES;
    %LET FIND_SURROGATES = NO; /*Default value. Do not edit. */

    %IF %UPCASE(&MATCH_NO_PRODUCTION)=YES %THEN
    %DO;
        %G8_FIND_NOPRODUCTION  /* Finds products needing surrogate     */
                               /* costs by looking for total production*/
                               /* quantities per product (across all   */
                               /* POR time periods, where applicable)  */
                               /* that are less than or equal to zero, */
                               /* or have missing values. If this is   */
                               /* incorrect, please make adjustments   */
                               /* above in sect. 3-A-i before executing*/
                               /* the G8_FIND_NOPRODUCTION macro.      */

        /*-------------------------------------------------------------*/
        /*     3-B-ii ATTACH PRODUCT CHARACTERISTICS, WHEN REQUIRED    */
        /*                                                             */
        /*     When product characteristic variables are not in the    */
        /*     data, they will be taken from both the CM and U.S.      */
        /*     sales databases. To do this, the CM and U.S. control    */
        /*     numbers must be of the same type (character v. numeric) */
        /*     and length, if character. Likewise for the product      */
        /*     characteristic variables. If you need to make adjust-   */
        /*     ments to the control numbers and/or product charac-     */
        /*     teristic variables, do that here before the execution   */
        /*     of the G9_COST_PRODCHARS macros below.                  */
        /*-------------------------------------------------------------*/

        /*-------------------------------------------------------*/
        /* 3-B-ii-a: INSERT CHANGES TO CONTROL NUMBERS AND       */
        /*      PRODUCT CHARACTERISTICS IN U.S. SALES DATA.      */
        /*                                                       */
        /*     Edits to U.S. control numbers and product charac- */
        /*     teristics should be done before executing the     */
        /*     G9_COST_PRODCHARS macro.                          */
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
/*--------------------------------------------------------------------*/
/*     3-C SEPARATE PRODUCTS WITH TIME-SPECIFIC COSTS FROM THOSE      */
/*          WITH ANNUALIZED COSTS. FOR PRODUCTS WITH TIME-SPECIFIC    */
/*          COSTS, DEFINE TIME PERIODS, SEPARATING PERIODS INSIDE THE */
/*          POR FROM THOSE OUTSIDE, FILL IN ANY MISSING TIME PERIODS  */
/*          IN COST DATA.                                             */
/*--------------------------------------------------------------------*/

%MACRO SETUP_COST_PERIODS;
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;

        /*-------------------------------------------------------------*/
        /*     3-C-i SEPARATE PRODUCTS WITH TIME-SPECIFIC COSTS FROM   */
        /*           THOSE  WITH ANNUALIZED COSTS.                     */
        /*                                                             */
        /*     If there are both products with time-specific costs and */
        /*     those with annualized costs, then separate them here    */
        /*     before time periods are attached in sect. 3-C-ii. Put   */
        /*     products with annualized costs in a dataset called      */
        /*     'COST' and those with time-specific costs into a        */
        /*     dataset called 'ANNUALCOST.'                            */
        /*-------------------------------------------------------------*/

        %IF %UPCASE(&TIME_ANNUALIZED) NE NA %THEN
        %DO;
            DATA COST ANNUALCOST;
                SET COST;
                IF &COST_TIME_PERIOD IN(&TIME_ANNUALIZED) THEN
                    OUTPUT ANNUALCOST;
                ELSE
                    OUTPUT COST;
            RUN;
        %END;

        /*-------------------------------------------------------------*/
        /* 3-C-ii. COMPARE COST DATA TO A LIST OF ALL TIME PERIODS,    */
        /*         FILL IN MISSING LINES IN THE COST DATA, IF ANY.     */
        /*                                                             */
        /* The G10_TIME_PROD_LIST macro immediately below uses the     */
        /* macro variables in Sect. 1-E-iii-a above for TIME_INSIDE_POR*/
        /* and TIME_OUTSIDE_POR to make a list of all possible time    */
        /* periods. If all time periods are not represented in the     */
        /* cost data, the missing lines are added to the database,     */
        /* using annualized costs from a non-missing line to supply    */
        /* information on non-indexed variables.                       */
        /*-------------------------------------------------------------*/

        %G10_TIME_PROD_LIST(&CMCHAR)
    %END;
%MEND SETUP_COST_PERIODS;

%SETUP_COST_PERIODS

/*ep*/

/***************************************************************************/
/* 3-D     DEFINE TIME PERIODS AND INDICES, MAKE PRE-INDEXING CHANGES      */
/*          TO INPUTS, CALCULATE TIME-SPECIFIC INDEXED INPUT VALUES        */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 3-D-i: DEFINE EACH INPUT TO BE INDEXED, MAKE ADJUSTMENTS TO INPUTS,     */
/*        WHEN REQUIRED.                                                   */
/*                                                                         */
/* For each input to be indexed, create both an &INPUTi and an             */
/* &INPUTi_ADJUSTED macro variable, where 'i' is a unique indicator for    */
/* each input. The &INPUTi macro variable should be set to the variable    */
/* in the cost data to be indexed, as reported by the respondent, before   */
/* any adjustment has been made. The &INPUTi_ADJUSTED macro variable       */
/* should be set to the adjusted value (a.k.a "actual value") of the       */
/* &INPUTi variable. It is the adjusted amount that gets indexed. For      */
/* example, if you are indexing NICKEL and there is also a major-input     */
/* adjustment to NICKEL, called MAJADJ, you could write the following:     */
/*                                                                         */
/*         %LET INPUT1 = NICKEL;                                           */
/*          %LET      INPUT1_ADJUSTED = NICKEL + MAJADJ;                   */
/*                                                                         */
/* If you previously created a new variable revising the input in          */
/* Sect.3-A above (e.g., RNICKEL = NICKEL + MAJADJ), you can instead type: */
/*                                                                         */
/*         %LET INPUT1 = NICKEL;                                           */
/*          %LET      INPUT1_ADJUSTED = RNICKEL;                           */
/*                                                                         */
/* Both methods are fine.                                                  */
/*                                                                         */
/* If you have two inputs to index, activate the language for INPUT2 below */
/* and complete. For more than two inputs, copy the language below and     */
/*  call them INPUT3, INPUT4, etc.                                         */
/*-------------------------------------------------------------------------*/

%MACRO CALC_INDICES;
    %IF %UPCASE(&COMPARE_BY_TIME) = YES %THEN
    %DO;
        %IF %UPCASE(&INDEX_SOURCE) NE RESP %THEN
        %DO;
            %LET INPUT1 = <  >;           /* Variable to be indexed,   */
                                          /* unadjusted, as it appears */
                                          /* in the cost database.     */
            %LET INPUT1_ADJUSTED = <&INPUT1>; /* Value of variable to  */
                                              /* be indexed after      */
                                          /* adjustments, including any*/
                                          /* major-input adjustment.   */
                                          /* If there is no adjustment,*/
                                          /* use the default "&INPUT1" */
                                          /* (no quotes)               */
            /*
                %LET INPUT2 = <  >;
                %LET INPUT2_ADJUSTED = <&INPUT2>;
            */

/*-------------------------------------------------------------------------*/
/* 3-D-ii INSERTING INDICES INTO THE COST DATA                             */
/*                                                                         */
/*     The indices can either be calculated outside of this program and    */
/*     then input in, or they can be calculated within this program. If    */
/*     your indices have already been supplied to you from an outside      */
/*     source, complete Sect.3-D-ii-a immediately below. If, on the        */
/*     other hand, you are calculating the indices within this program,    */
/*     complete section 3-D-ii-b.                                          */
/*-------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------*/
/* 3-D-ii-a INPUTTING SUPPLIED TIME-SPECIFIC INDICES                       */
/*                                                                         */
/*     The G11_INSERT_INDICES_IN macro and the G12_INSERT_INDICES_OUT      */
/*     macro will generate language linking indices to periods as          */
/*     follows:                                                            */
/*                                                                         */
/*          IF {COST_TIME_PERIOD}={first period in list} THEN              */
/*          INPUTi_INDEX = {first index in list for INPUTi}                */
/*                                                                         */
/*     If there are multiple sets of indices that depend on various        */
/*     conditions, list each of the conditions under a separate            */
/*     CONDITION_i macro variable. State the conditions without any        */
/*     "IF" or "THEN" verbage. For example, if indices vary according      */
/*     to GRADE, you would type something like:                            */
/*                                                                         */
/*          CONDITION_A = GRADE IN("101")                                  */
/*          CONDITION_B = GRADE IN("102")                                  */
/*                                                                         */
/*     If there is no condition in your case (i.e., one set of indices)    */
/*     set the condition to "NA" (no quotes) for one CONDITION_i macro     */
/*     variable, and use it in the G11_INSERT_INDICES_IN macro and the     */
/*     G12_INSERT_INDICES_OUT macro, if required.                          */
/*                                                                         */
/*     For each relevant combination of condition and input, execute a     */
/*     G11_INSERT_INDICES_IN and, if there are cost periods outside of     */
/*     the POR, a G12_INSERT_INDICES_OUT macro.                            */
/*-------------------------------------------------------------------------*/

            %IF %UPCASE(&INDEX_SOURCE) = INPUT %THEN
            %DO;
                /* List of values of indices for periods in POR, in */
                /* order as time periods in TIME_INSIDE_POR macro,  */
                /* same separated by blank space, no quotes around  */
                /* values.                                          */

                %LET CONDITION_A = <NA>;

                /* E.g., 1.0  1.1  1.2  1.3  */

                %LET     INDEX1A_IN_POR = <  >;

                /* List of values of indices for periods outside of */
                /* POR, in same order as time periods in            */
                /* TIME_OUTSIDE_POR macro, separated by blank space,*/
                /* no quotes around values. E.g., 0.7  0.8  0.9     */

                %LET     INDEX1A_OUT_POR = <  >;

                /*
                    %LET CONDITION_B = <NA>;
                    %LET     INDEX1B_IN_POR = <  >;
                    %LET     INDEX1B_OUT_POR = <  > ;
                */

                DATA COSTPOR;
                    SET COSTPOR;

                    /* Ex. for condition A with input 1: */

            %G11_INSERT_INDICES_IN(&INPUT1,&CONDITION_A,&INDEX1A_IN_POR)

                   /* Ex. for condition B with input 1: */
         /*
             %G11_INSERT_INDICES_IN(&INPUT1,&CONDITION_B,&INDEX1B_IN_POR)
         */

                   /* Ex. for condition A with input 2: */
         /*
             %G11_INSERT_INDICES_IN(&INPUT2,&CONDITION_A,&INDEX2A_IN_POR)
         */

                   /* Ex. for condition B with input 2: */
         /*
             %G11_INSERT_INDICES_IN(&INPUT2,&CONDITION_B,&INDEX2B_IN_POR)
         */

                RUN;

                %IF %UPCASE(&TIME_OUTSIDE_POR) NE NA %THEN
                %DO;
                    DATA COSTOUTPOR;
                       SET COSTOUTPOR;

                        /* Ex. for condition A with input 1 */

           %G12_INSERT_INDICES_OUT(&INPUT1,&CONDITION_A,&INDEX1A_OUT_POR)

                        /* Ex. for condition B with input 1 */

        /*
            %G12_INSERT_INDICES_OUT(&INPUT1,&CONDITION_B,&INDEX1B_OUT_POR)
        */

                        /* Ex. for condition A with input 2 */

        /*
            %G12_INSERT_INDICES_OUT(&INPUT2,&CONDITION_A,&INDEX2A_OUT_POR)
        */

                        /* Ex. for condition B with input 2 */

        /*
            %G12_INSERT_INDICES_OUT(&INPUT2,&CONDITION_B,&INDEX2B_OUT_POR)
        */
                    RUN;
                %END;
             %END;

/*---------------------------------------------------------------------*/
/* 3-D-ii-b CALCULATING INDICES WITHIN THIS PROGRAM                    */
/*                                                                     */
/*     The G13_CALC_INDICES macro calculates the indices based on the  */
/*     grouping indicated in the INDEX_GROUPi macro variable. Within   */
/*     each group, there must be at least one line of cost data with   */
/*     production for each cost time period.                           */
/*                                                                     */
/*     Under the INDEX_GROUPi macro variable, list the variables to be */
/*     used in defining the groupings (i.e., the "BY" variables) for   */
/*     calculating the indices (e.g., MANUF GRADE). If there is no     */
/*     grouping variable since you are calculating indices across the  */
/*     whole database for a particular input, type "INDEX_GROUP=NA."   */
/*     You may have different groupings for different inputs. Execute  */
/*     the INDICES macro for each input/grouping pair. You can use a   */
/*     particular grouping for more than one input.                    */
/*---------------------------------------------------------------------*/

            %IF %UPCASE(&INDEX_SOURCE) = CALC %THEN
            %DO;
                %LET INDEX_GROUP1 = <??>; /* List the variables to be  */
                                          /* used to group/sort the    */
                                          /* data for calculating      */
                                          /* indices on input1.        */
                /*
                    %LET INDEX_GROUP2 = <??>;
                */
                                      /* List the variables to be used */
                                      /* to group/sort the data for    */
                                      /* calculating indices on input2.*/
                %MACRO RUN_INDICES;
                    %INDICES(&INPUT1,&INPUT1_ADJUSTED,&INDEX_GROUP1)

                    /* Ex. for input1 and grouping1  */
                    /*
                       %INDICES(&INPUT2,&INPUT2_ADJUSTED,&INDEX_GROUP2)*/
                    */
                                      /* Ex. for input2 and grouping2  */
                 %MEND RUN_INDICES;

                 %G13_CALC_INDICES
             %END;

/*--------------------------------------------------------------------*/
/* 3-D-iii CALCULATE TIME-SPECIFIC INDEXED INPUT VALUES               */
/*                                                                    */
/*     Whether you inputted supplied indices in Sect.3-D-ii-a or      */
/*     calculated indices in Sect.3-D-ii-b, you must execute a        */
/*     G14_INDEX_CALC macro for each input. This macro will use the   */
/*     indices to calculate period-specific indexed input amounts. If */
/*     there is more than one input to be indexed, execute a          */
/*     G14_INDEX_CALC macro for each.                                 */
/*--------------------------------------------------------------------*/

            /* Ex. for input 1 */

            %G14_INDEX_CALC(&INPUT1,&INPUT1_ADJUSTED,&INPUT1._INDEX)

            /* Ex. for input 2 */
            /*
                %G14_INDEX_CALC(&INPUT2,&INPUT2_ADJUSTED,&INPUT2._INDEX)
            */
        %END;
    %END;
%MEND CALC_INDICES;

%CALC_INDICES

/*ep*/

/***************************************************************************/
/* 3-E  AFTER INDEXING INPUTS, IF REQUIRED, CALCULATE TOTAL COST OF        */
/*      MANUFACTURING, GNA, INTEREST AND TOTAL COST OF PRODUCTION.         */
/*                                                                         */
/* When there are both time-specific and annualized costs, both are        */
/* combined into one database called, COST.                                */
/*                                                                         */
/* For each input whose cost is varying in time (i.e., is time-specific),  */
/* a new variable has been created called, FINAL_{input variable name}.    */
/* For example, if one such input is NICKEL, then the new variable will be */
/* called, FINAL_NICKEL. In time periods in which there is production of a */
/* product, FINAL_{input variable name} is equal to the actual value. For  */
/* time  periods with no production and, accordingly, production quantity  */
/* is either zero or missing, the value for FINAL_{input variable name} is */
/* equal to the indexed value of the input. Use the variable FINAL_{input  */
/* variable name} to recalculate total cost of manufacturing for time-     */
/* specific products.                                                      */
/***************************************************************************/

DATA COST;
    SET COST &ANNUAL_COST; /* Macro variable ANNUAL_COST will be a null */
                               /* value when there is no annualized data.   */

    IF &COST_QTY IN (.,0) THEN
        &COST_QTY = 1;

    TCOMCOP = <  >;     /* Total cost of manufacturing. For       */
                        /* inputs with time-specific values,      */
                        /* build up total cost of manufacturing   */
                        /* using FINAL_{old input variable name}. */

/*-------------------------------------------------------------*/
/*  If you have both time-specific and annualized costs, you   */
/*  will need separate equations for total cost of manufactur- */
/*  ing. Deactivate the single line above for TCOMCOP and      */
/*  instead use the language below.                            */
/*-------------------------------------------------------------*/

    /* For annualized costs. */
    /*
        IF &COST_TIME_PERIOD IN(&TIME_ANNUALIZED) THEN
            TCOMCOP = <  >;
    */

    /* For time-specific costs */
    /*
        ELSE
            TCOMCOP = <  >;
    */

/*------------------------------------------------------------*/
/* If you have time-specific costs and at least one control   */
/* number has time periods with no production, you will need  */
/* to recalculate GNA and interest expenses using the TCOMCOP */
/* based on the FINAL_{input name} variables, even if the GNA */
/* and interest ratios have not changed.                      */
/*------------------------------------------------------------*/

    VCOMCOP = <TCOMCOP - FOH>; /* Variable cost of manufacturing */
                               /* equal to TCOMCOP less fixed    */
                               /* costs.                         */
    GNACOP = <  >;             /* General and administrative     */
                               /* expense.                       */
    INTEXCOP = <  >;           /* Interest expense.              */

    TOTALCOP = TCOMCOP + GNACOP + INTEXCOP;     /* Total cost of */
                                                /* production.   */
RUN;

/*ep*/

/*-----------------------------------------------*/
/* 3-F: WEIGHT-AVERAGE COST DATA, WHEN REQUIRED. */
/*-----------------------------------------------*/

%G15_CHOOSE_COSTS

/*ep*/

/*-------------------------------------------------------------------------*/
/* 3-G: FIND SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POR          */
/*-------------------------------------------------------------------------*/

%G16_MATCH_NOPRODUCTION

/*ep*/

/*-------------------------------------------------------------------------*/
/* 3-H: MERGE COSTS WITH CMSALES AND OUTPUT A COST DATABASE FOR USE WITH   */
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

/***************************************************************************/
/* PART 4: COMPARISON MARKET NET PRICE CALCULATIONS                        */
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

%CM2_MIXEDCURR(&SALESDB)

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-A-ii: SPLIT MIXED-CURRENCY VARIABLES USING CASE-SPECIFIC LANGUAGE.    */
/*                                                                         */
/*     In the absence of a variable indicating which transactions are in   */
/*     each currency, you must first turn off the macros that use a        */
/*     currency-indicating variable. You can do this either by typing      */
/*     'LET MIXEDCURR = NA' in 1-E-ii above, or by deactivating both the   */
/*     SETUP_MIXEDCURR_VAR and CM2_MIXEDCURR macros immediately above in   */
/*     section 4-A-i. Then, immediately below, activate the data step and  */
/*     write your own case-specific language. The language you write       */
/*     should split mixed-currency variables into multiple single-currency */
/*     variables.                                                          */
/*-------------------------------------------------------------------------*/

    /*
    DATA CMSALES;
        SET CMSALES;

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
/*     costs are incurred (usually CM currency). For example, if you have  */
/*     two movement expenses in CM currency (INLFTCH and INFLTWH)and one   */
/*     in US dollars (INSUREH), first create CM- and USD-specific movement */
/*     variables, leaving them in their original currency. Then set the    */
/*     aggregate variable (CMMOVE) equal to the sum of the two currency-   */
/*     specific variables, converting into CM currency as needed. Here is  */
/*     an example using the variables above and a CM market of Brazil:     */
/*                                                                         */
/*              MOVE_CM = INLFTCH + INFLTWH;                               */
/*              MOVE_USD = INSUREH;                                        */
/*              CMMOVE = MOVE_CM + (MOVE_USD/EXRATE_BRAZIL);               */
/*                                                                         */
/*     NOTE1:   Remember to use the new, split names for mixed-variables   */
/*              from section 4-A-i above.                                  */
/*                                                                         */
/*     NOTE2:   It is the unconverted, single-currency aggregate variables */
/*              (i.e., MOVE_CM and MOVE_USD in the example) and NOT CMMOVE */
/*              that should be weight-averaged at the end of this program  */
/*              for price-2-price comparisons with U.S. sales.             */
/*              (See Sect. 9-B-i below.)                                   */
/*                                                                         */
/*     When you have aggregate variables whose components are all in a     */
/*     currency other than the CM currency, first create an unconverted    */
/*     currency-specific aggregate variable and then do the conversion in  */
/*     the final CM aggregate variable. If, in the example earlier in this */
/*     note, INFLTCH, INFLTWH and INSUREH were all in U.S. dollars, you    */
/*     would type:                                                         */
/*                                                                         */
/*          MOVE_USD = INLFTCH + INFLTWH + INSUREH;                        */
/*          CMMOVE = MOVE_USD/EXRATE_BRAZIL;                               */
/*                                                                         */
/*     You would then have an unconverted aggregate variable (i.e.,        */
/*     MOVE_USD) to use in the final weight average in Sect. Part 10-B-i.  */
/*     (Note:  you would NOT use the converted CMMOVE in the weight        */
/*     average in this case.)                                              */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/* 4-B-i: CALCULATION OF AGGREGATE VARIABLES:                              */
/*-------------------------------------------------------------------------*/

DATA CMSALES;
    SET CMSALES;

    %GLOBAL NETPRICE;
    %MACRO NETPRICE;
        CMGUP  = <&CMGUP>; /* Gross unit price. Default is to use        */
                           /* the variable selected for the &CMGUP       */
                           /* macro in Sect. 1-E-ii above                */
        CMGUPADJ  = <0>;   /* Price adjustments to be added to CMGUP     */
        CMDISREB  = <0>;   /* Discounts, rebates & other price           */
                           /* adjustments to be subtracted from CMGUP    */
        CMMOVE    = <0>;   /* Movement expenses                          */
        CMCRED    = <0>;   /* Imputed credit expense                     */
        CMDSELL   = <0>;   /* Direct selling expenses, excluding CMCRED  */
        CMICC     = <0>;   /* Imputed inventory carrying expenses        */
        CMISELL   = <0>;   /* Indirect selling expenses, excluding CMICC */
                           /*                                            */
        CMCOMM    = <0>;   /* Commissions                                */
        CMPACK    = <0>;   /* Packing                                    */

        /*-----------------------------------------------------------*/
        /* 4-B-i-a: Indirect selling expenses for commission offsets.*/
        /*-----------------------------------------------------------*/

        CMINDCOM  = <0>;   /* Set default value of zero for when     */
                           /* CMCOMM is greater than zero.           */

        /*-----------------------------------------------------------*/
        /* 4-B-i-b: When the variables going into both CMISELL and   */
        /*          CMICC are reported entirely in CM currency, use  */
        /*          the default language immediately following.      */
        /*-----------------------------------------------------------*/

        IF CMCOMM = 0 THEN
            CMINDCOM = CMISELL + CMICC;

        /*-----------------------------------------------------------*/
        /*  4-B-i-c: If either CMISELL or CMICC are split into       */
        /*           multiple currencies or reported in non-CM       */
        /*           currency, deactivate the default language above */
        /*           and activate the exemplary language immediately */
        /*           following adjusting for circumstances.          */
        /*-----------------------------------------------------------*/

        /*
        IF CMCOMM = 0 THEN
        DO;
          CMINDCOM_MXN = INDIRSH_MXN + CMICC;
          CMINDCOM_USD = INDIRSH_USD;
          CMINDCOM = CMINDCOM_MXN + (CMINDCOM_USD/EXRATE_MEXICO);
        END;
        */

        /*-------------------------------------------------------------*/
        /* 4-B-ii: CALCULATION OF NET PRICES:                          */
        /*-------------------------------------------------------------*/

        /* Net price for price comparisons. */
        /* Deduct imputed credit expenses . */

        CMNETPRI  = CMGUP + CMGUPADJ - CMDISREB - CMMOVE
                  - CMDSELL - CMCRED - CMCOMM - CMPACK;

        /* Net price for the cost test.    */
        /* Do NOT deduct imputed expenses. */

        CMNPRICOP = CMGUP + CMGUPADJ - CMDISREB - CMMOVE
                  - CMDSELL - CMISELL - CMCOMM - CMPACK;

        /* Net price for calculating the credit */
        /* ratio for CV selling expenses.       */

        CVCREDPR = CMGUP + CMGUPADJ - CMDISREB - CMMOVE;
    %MEND NETPRICE;

    %NETPRICE
RUN;

/*ep*/

PROC PRINT DATA = CMSALES (OBS = &PRINTOBS);
    TITLE3 "SAMPLE OF NET PRICE CALCULATIONS FOR COMPARISON-MARKET SALES ";
RUN;

/*ep*/

/***************************************************************************/
/* PART 5: ARMS-LENGTH TEST OF AFFILIATED PARTY SALES                      */
/***************************************************************************/

%CM3_ARMSLENGTH

/*ep*/

/***************************************************************************/
/*     PART 6: ADD THE DOWNSTREAM SALES FOR AFFILIATED PARTIES THAT FAILED */
/*             THE ARMS-LENGTH TEST AND RESOLD MERCHANDISE                 */
/*                                                                         */
/*     Merge exchange rates and cost data with downstream sales. Create    */
/*     level of trade information, and calculate aggregate variables and   */
/*     net prices. Combine downstream and CM data.                         */
/*                                                                         */
/*     Activate the language in all of Sect. 6 and adjust accordingly.     */
/***************************************************************************/

%MACRO DOWNSTREAM;
    %LET DOWNSTREAMDATA = <  >;   /* (D) Downstream sales dataset filename.*/
    %LET SALESDB = DOWNSTREAM;    /*     Do not edit. Allows certain macros*/
                                  /*     (G5_DATE_CONVERT,CM2_MIXEDCURR)   */
                                  /*     to work on downstream sales.      */
    DATA DOWNSTREAM;
        SET COMPANY.&DOWNSTREAMDATA;

/*-------------------------------------------------------------------------*/
/*     6-A-i: ALIGN VARIABLES IN CM AND DOWNSTREAM DATABASES               */
/*                                                                         */
/*     Variables in the downstream sales database must have the same names */
/*     and types (i.e., character v numeric) as those in the CM sales data */
/*     for the macro variables in Sect. 1-E-ii above, which are:           */
/*                                                                         */
/*          CMDATE                                                         */
/*          CMQTY                                                          */
/*          CMGUP                                                          */
/*          CMMANUF                                                        */
/*          CMPRIM                                                         */
/*          CMLOT                                                          */
/*          CMCONNUM                                                       */
/*          CMCPMATCH                                                      */
/*          CMCHAR                                                         */
/*                                                                         */
/*     If the variable names or types in the downstream data are           */
/*     different than those in the original CM sales data, make the        */
/*     required adjustments.                                               */
/*-------------------------------------------------------------------------*/

        <Rename variables on downstream sales and change variable
         types, if necessary, to match CM sales data. Make other
         changes to downstream sales data here.>

/*-------------------------------------------------------------------------*/
/*     6-A-ii: CREATE THE CMLOT VARIABLE FOR DOWNSTREAM SALES              */
/*                                                                         */
/*     Note:  If in section 1-E-ii above for CM sales "LET CMLOT = NA"     */
/*     (because CM sales were the same LOT as U.S. sales), but downstream  */
/*     sales are at a different LOT, replace "NA" for the CM sales with a  */
/*     variable name. If no LOT variable was reported, create one in both  */
/*     the CM and downstream databases. The newly created variables should */
/*     have the same name and type (i.e., character v numeric).            */
/*-------------------------------------------------------------------------*/

        <Create a LOT variable for downstream sales or edit an
         existing variable here, when required.>

        %G4_LOT(&CMLOT,CMLOT)
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
/*                     FOR ORIGINAL CM SALES                            */
/*                                                                      */
/*     If the language in Part 4-A-i is also applicable to downstream   */
/*     sales, then just execute the two macros immediately below, i.e., */
/*     %SETUP_MIXEDCURR_VAR and %CM2_MIXEDCURR(DOWNSTREAM), by          */
/*     activating them.                                                 */
/*----------------------------------------------------------------------*/

        <%SETUP_MIXEDCURR_VAR>
        <%CM2_MIXEDCURR(DOWNSTREAM)>

/*----------------------------------------------------------------------*/
/*      6-D-ii: SPLIT MIXED-CURRENCY VARIABLES USING LANGUAGE           */
/*              DIFFERENT THAN THAT FOR ORIGINAL CM SALES               */
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
    %CM2_MIXEDCURR(DOWNSTREAM)

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
/*                CM SALES                                            */
/*                                                                    */
/*     If the calculations for the aggregate variables and net prices */
/*     are the same for the downstream sales as for the original CM   */
/*     original CM sales, you need only activate the %NETPRICE macro  */
/*     immediately below this note.                                   */
/*--------------------------------------------------------------------*/

        <%NETPRICE>   /* Activate this line to duplicate the     */
                      /* calculations of the aggregate variables */
                      /* and net prices from Section 4-B.        */

/*-------------------------------------------------------------------*/
/*      6-D-iii-b: AGGREGATE VARIABLES AND NET PRICE CALCULATIONS    */
/*             ARE DIFFERENT FOR DOWNSTREAM SALES THAN FOR THE       */
/*               ORIGINAL CM SALES                                   */
/*                                                                   */
/*     If not all aggregate variable calculations are the same, you  */
/*     will need to copy out the aggregate variable and net price    */
/*     calculations from section 4-B and edit accordingly for the    */
/*     downstream sales. For every aggregate variable used in        */
/*     Section 4-B above for the original CM sales, including        */
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
/*      6-E: COMBINE ORIGINAL CM SALES WITH DOWNSTREAM SALES               */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/*     6-E-i: CREATION OF NEEDED VARIABLES IN CM SALES BEFORE COMBINING    */
/*            WITH DOWNSTREAM SALES                                        */
/*                                                                         */
/*     You may need to create new currency-specific aggregate variables in */
/*     the original CM sales for any aggregate variable in the downstream  */
/*     sales that is not already in the CM sales data. If you do, activate  /
/*     the language immediately following and edit accordingly. You should */
/*     assign values equal to zero for those new aggregate variables in the*/
/*     original CM sales before they are combined with downstream sales in */
/*     next step. If you do not assign a zero, then missing values will be */
/*     assigned, instead, once the CM and downstream sales databases are   */
/*     combined.                                                           */
/*-------------------------------------------------------------------------*/

    DATA CMSALES;
       SET CMSALES;
        <In CMSALES, add aggregate variables that appear in
         downstream data but are not in CM data, and set the
         values of those variables to zero.>
    RUN;

/*------------------------------------------------------------*/
/*     6-E-ii: COMBINE ORIGINAL CM SALES AND DOWNSTREAM SALES */
/*------------------------------------------------------------*/

    %LET SALESDB = CMSALES;

    DATA CMSALES;
        SET CMSALES DOWNSTREAM;
    RUN;
%MEND DOWNSTREAM;

/* %DOWNSTREAM */

/*ep*/

/***************************************************************************/
/* PART 7: CM VALUES FOR CEP PROFIT CALCULATIONS                           */
/*                                                                         */
/*     If required, an output dataset will be created using the            */
/*     standardized naming convention, 'RESPONDENT_SEGMENT_STAGE'_CMCEP.   */
/***************************************************************************/

%CM4_CEPTOT

/*ep*/

/***************************************************************************/
/* PART 8: COST TEST                                                       */
/***************************************************************************/

%CM5_COSTTEST

/*ep*/

/***************************************************************************/
/* PART 9:  WEIGHT-AVERAGED COMPARISON MARKET VALUES FOR PRICE-TO-PRICE    */
/*               COMPARISONS WITH U.S. SALES                               */
/*                                                                         */
/*     Create an output dataset using the standardized naming convention,  */
/*     'RESPONDENT_SEGMENT_STAGE'_CMWTAVG. Rename certain variables to     */
/*     standardized names: CMCONNUM, CMLOT and, if applicable, CMMANF,     */
/*     CMPRIME, VCOMCM and TCOMCM.                                         */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 9-A: SELECT CM DATA TO WEIGHT AVERAGE                                   */
/*                                                                         */
/*     If there is a Cost Test, then above-cost sales will be used in the  */
/*     calculation of weighted-average CM sales. If there was no Cost      */
/*     then all CM sales, after the Arms-Length Test and inclusion of      */
/*     downstream sales, if required, will be used.                        */
/*-------------------------------------------------------------------------*/

     %CM6_DATA_4_WTAVG

/*ep*/

/*-------------------------------------------------------------------------*/
/* 9-B: SELECT CM VARIABLES TO WEIGHT AVERAGE                              */
/*                                                                         */
/*     CM weighted-average values will be converted into U.S. dollars in   */
/*     the Margin Program using exchange rates on the U.S. sale dates.     */
/*     Therefore, it is IMPORTANT TO WEIGHT-AVERAGE ONLY SINGLE-CURRENCY   */
/*     CM VARIABLES IN THEIR ORIGINAL CURRENCY.                            */
/*-------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/* 9-B-i: CM DATA IS IN MORE THAN ONE CURRENCY                             */
/*                                                                         */
/*     If amounts in the CM database were reported in more than one        */
/*     currency, then edit the %LET WTAVGVARS macro variable directly      */
/*     below.                                                              */
/*                                                                         */
/*     Look at the aggregate variable calculations Part 4-B-i. Those       */
/*     aggregate variables that are comprised entirely of variables        */
/*     originally reported in the CM currency can be left as is. However,  */
/*     those aggregate variables that are either: 1) converted into a      */
/*     currency other than the original, or 2) are a mixture of            */
/*     currencies, must be edited. Mixed currency aggregate variables      */
/*     must be split apart by currency. List all single-currency           */
/*     components in original currency. Ex.: if you have in Part 4-B-i:    */
/*     CMMOVE = MOVE_EURO + MOVE_USD/&EXRATE_EURO, replace the "CMMOVE"    */
/*     below with "MOVE_EURO" and "MOVE_USD"                               */
/*-------------------------------------------------------------------------*/

%MACRO WTAVGVARS;
    %GLOBAL WGTAVGVARS;

    %IF %UPCASE(&CM_MULTI_CUR) = YES %THEN
    %DO;
    %IF %UPCASE(&CM_MULTI_CUR) = YES OR %UPCASE(&MIXEDCURR) = YES %THEN
        %LET WGTAVGVARS = <CMGUP CMGUPADJ CMDISREB CMMOVE
                           CMCRED CMDSELL CMCOMM CMICC CMISELL
                           CMINDCOM CMPACK>;
    %END;

/*-------------------------------------------------------------------------*/
/* 9-B-ii: CM DATA IS ALL IN ONE CURRENCY                                  */
/*                                                                         */
/*     If amounts in the CM database were reported entirely in one         */
/*     currency, and use of an exchange rate was not required, aggregate   */
/*     amounts will be automatically weight-averaged.                      */
/*-------------------------------------------------------------------------*/

    %ELSE
    %IF %UPCASE(&CM_MULTI_CUR) = NO AND %UPCASE(&MIXEDCURR) = NO %THEN
    %DO;
        %LET WGTAVGVARS = CMNETPRI CMCRED CMDSELL CMCOMM
                          CMICC CMISELL CMINDCOM;
    %END;
%MEND WTAVGVARS;

%WTAVGVARS

/*-------------------------------------------------------------------------*/
/* 9-C: WEIGHT-AVERAGE CM DATA                                             */
/*                                                                         */
/*     Standardize names of certain CM variables that will be carried to   */
/*     the Margin Calculation Program: CMCONNUM, CMLOT and, if applicable, */
/*     CMMANF, CMPRIME, CMVCOM and CM_TIME_PERIOD. Create and output       */
/*     database using the standardized naming convention,                  */
/*     'RESPONDENT_SEGMENT_STAGE'_CMWTAVG.                                 */
/*-------------------------------------------------------------------------*/

%CM7_WTAVG_DATA

/*ep*/

/***************************************************************************/
/* PART 10: CALCULATE SELLING EXPENSE AND PROFIT RATIOS FOR                */
/*             CONSTRUCTED-VALUE COMPARISONS                               */
/*                                                                         */
/*     Create an output dataset using the standardized naming convention,  */
/*     'RESPONDENT_SEGMENT_STAGE'_CMCV.                                    */
/***************************************************************************/

%CM8_CVSELL

/*ep*/

/***************************************************************************/
/* PART 11: CM LEVEL OF TRADE ADJUSTMENT                                   */
/*                                                                         */
/*     Create LOT adjustment factors. Output a dataset using the           */
/*     standardized naming convention, 'RESPONDENT_SEGMENT_STAGE'_LOTADJ.  */
/***************************************************************************/

%CM9_LOTADJ

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
