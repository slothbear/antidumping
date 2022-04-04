/***************************************************************************/
/*                        ANTIDUMPING MARKET ECONOMY                       */
/*                        MARGIN CALCULATION PROGRAM                       */
/*                                                                         */
/*               GENERIC VERSION LAST UPDATED MARCH 28, 2022               */
/*                                                                         */
/* Part 1:  Database and General Program Information                       */
/* Part 2:  Bring In U.S. Sales, Convert Date Variable, If Necessary,      */
/*          Merge Exchange Rates into Sales, If Required                   */
/* Part 3:  Cost Information                                               */
/* Part 4:  Calculate the Net U.S. Price                                   */
/* Part 5:  Convert Comparison Market Net Prices and Adjustments into CM   */
/*          Currency, If Required                                          */
/* Part 6:  Create Concordance of Price-To-Price Matching Instructions     */
/* Part 7:  Level of Trade Adjustment, If Required                         */
/* Part 8:  Combine U.S. Sales with CM Matches, Calculate Transaction-     */
/*          Specific Lot Adjustments, CEP and Commission Offsets           */
/* Part 9:  Calculate CEP and Commission Offsets For Constructed Value     */
/*          Comparisons                                                    */
/* Part 10: Combine Price-2-Price Comparisons with Sales Compared To CV    */
/* Part 11: Cohen's-d Test                                                 */
/* Part 12: Weight Average U.S. Sales                                      */
/* Part 13: Calculate FUPDOL, NV, PUDD, Etc. Using the Standard Method,    */
/*          the A-to-T Alternative Method and, When Required, the Mixed    */
/*          Alternative Method                                             */
/* Part 14: Cash Deposit Rates                                             */
/* Part 15: Meaningful Difference Test                                     */
/* Part 16: Assessment Rates (Administrative Reviews Only)                 */
/* Part 17: Reprint the Final Cash Deposit Rate                            */
/* Part 18: Delete All Work Files in the SAS Memory Buffer, If Desired     */
/* Part 19: Calculate Run Time for This Program, If Desired                */
/* Part 20: Review Log for Errors, Warnings, Uninit. etc.                  */ 
/***************************************************************************/

/*-----------------------------------------------------------------------*/
/* EDITING THE PROGRAM:                                                  */
/*                                                                       */
/* Places requiring edits are indicated by angle brackets (i.e., '< >'). */
/* Replace angle brackets with case-specific information.                */
/*                                                                       */
/*          Types of Inputs: (D) = SAS dataset name                      */
/*                           (V) = Variable name                         */
/*                           (T) = Text (no specific format),            */
/*                                do NOT use punctuation marks           */
/*                                                                       */
/* If there are angle brackets that are commented out, replacing the     */
/* angles brackets with case specific code is optional. For example:     */
/*                                                                       */
/*          <Insert changes here, if required.>                          */
/*-----------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*/
/*     EXECUTING/RUNNING THE PROGRAM:                                      */
/*                                                                         */
/*          In addition to executing the entire program, you can do        */
/*          partial runs. Executable points from which you can             */
/*          partially run the program are indicated by '/*ep*' on          */
/*          the left margin. To do a partial run, just highlight the       */
/*          program from one of the executable points to the top,          */
/*          then submit it.                                                */
/*-------------------------------------------------------------------------*/

/***************************************************************************/
/* PART 1: DATABASE AND GENERAL PROGRAM INFORMATION                        */
/***************************************************************************/

/*-------------------------------------------------------------------------*/
/* 1-A: LOCATION OF DATA AND MACROS PROGRAM                                */
/*                                                                         */
/*     LIBNAME =      The name (i.e., COMPANY) and location of the         */
/*                    sub-directory containing the SAS datasets for        */
/*                    this program.                                        */
/*                    EXAMPLE: E:\Operations\Fiji\AR_2016\Hangers\Acme     */
/*                                                                         */
/*     FILENAME =     Full path of the Macro Program for this case,        */
/*                    consisting of the sub-directory containing the       */
/*                    Macro Program and its file name.                     */
/*-------------------------------------------------------------------------*/

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
%LET LOG_SUMMARY = YES;                        /* Default value is "YES" (no   */
                                               /* quotes). Use "NO" (no        */
                                               /* quotes) to run program in    */
                                               /* parts for troubleshooting.   */

/*-----------------------------------------------------------------------------*/
/* WRITE LOG TO THE PROGRAM DIRECTORY - DO NOT MOVE/CHANGE THIS SECTION        */
/*-----------------------------------------------------------------------------*/

%GLOBAL MNAME LOG;
%LET MNAME = %SYSFUNC(SCAN(%SYSFUNC(pathname(C_MACS)), 1, '.'));
%LET LOG = %SYSFUNC(substr(&MNAME, 1, %SYSFUNC(length(&MNAME)) - %SYSFUNC(indexc(%SYSFUNC(
           reverse(%SYSFUNC(trim(&MNAME)))), '\'))))%STR(\)%SYSFUNC(DEQUOTE(&_CLIENTTASKLABEL.))%STR(.log);  

%CMAC1_WRITE_LOG;

/*------------------------------------------------------------------*/
/* 1-B: PROCEEDING TYPE                                             */
/*------------------------------------------------------------------*/

/*-----------------------------------------------*/
/* TYPE IN EITHER THE WORD 'AR' (NOT 1ST REVIEW) */
/* OR THE WORD 'INV'. DO NOT TYPE THE QUOTES.    */
/*-----------------------------------------------*/

%LET CASE_TYPE = <AR/INV>;  /*(T) For an investigation, type 'INV' */
                            /*    (without quotes)                 */
                            /*    For an administrative review,    */
                            /*    type 'AR' (without quotes)       */

/*------------------------------------------*/
/* TYPE IN THE CASE NUMBER (EX. A-357-812). */
/*------------------------------------------*/

%LET CASE_NUMBER = <  >;    /*(T) Case Number */

/*-------------------------*/
/* TYPE IN YOUR FULL NAME. */
/*-------------------------*/

%LET PROGRAMMER = <  >;     /*(T) Case Analyst responsible for programming */

/*--------------------------------------------------------------------*/
/* 1-C: DATE INFORMATION                                              */
/*                                                                    */
/* Dates should be written in SAS DATE9 format (e.g., 01JAN2020).     */
/*                                                                    */
/* USSALEDATE:                                                        */
/*                                                                    */
/* The date of sale variable defined by the macro variable            */
/* USSALEDATE will be used to capture all U.S. sales within the date  */
/* range specified by the macro variables USBEGINDAY and USENDAY.     */
/*                                                                    */
/* USDATEBEFORESALE and USEARLIERDATE:                                */
/*                                                                    */
/* If there are reported dates before the sale date and you want      */
/* the earlier dates to be assigned to sale date, define the macro    */
/* variable USDATEBEFORESALE to 'YES' and assign the variable with    */
/* earlier dates to the macro variable USEARLIERDATE (ex. SHIPDATU).  */
/* Otherwise define the macro variable USDATEBEFORESALE to 'NO' and   */
/* ignore the macro variable USEARLIERDATE.                           */
/*                                                                    */
/* USBEGINDAY and USENDDAY:                                           */
/*                                                                    */
/* Define the macro variables USBEGINDAY and USENDDAY to correspond   */
/* to the universe of U.S. sales that you want to use.                */
/*                                                                    */
/* For Investigations USBEGINDAY often corresponds to the first day   */
/* of the first month of the POR and USENDDAY often corresponds to    */
/* the last day of the last month of the POR, respectively,           */
/* covering all U.S. sales dates.                                     */
/*                                                                    */
/* For Reviews USBEGINDAY often corresponds to the first day of the   */
/* first month of the POR and USENDDAY often corresponds to the last  */
/* day of the last month of the POR, respectively, covering, all U.S. */
/* sales dates. Reported CEP sales usually include all sales during   */
/* the POR. For EP sales, they usually include all entries during     */
/* the POR. Accordingly, there may be U.S. sales transactions with    */
/* sale dates prior to the POR. In these cases, adjust USBEGINDAY to  */
/* to correspond to the first day of the month of the earliest sale   */
/* you want to keep.                                                  */
/*                                                                    */
/* HMBEGINWINDOW:                                                     */
/*                                                                    */
/* The macro variable HMBEGINWINDOW  refers to the beginning of the   */
/* window period in an Administrative Review. It is used to define    */
/* the variable USMONTH that represents the month and year of the     */
/* sale. It is not required for Investigations.                       */
/*                                                                    */
/* QUARTERLY COMPARISONS: When making quarterly price-to-price        */
/* comparisons of CM and U.S. sales, comparisons are not made outside */
/* of designated time periods. In such cases, set HMBEGINWINDOW to    */
/* the first day of the first time period.                            */
/*                                                                    */
/* Note: In a review the Margin Calculation macro variable            */
/* HMBEGINWINDOW needs to have the same value as the ME Comparison    */
/* Market Program macro variable HMBEGINDAY so that model matching    */
/* will work properly.                                                */
/*--------------------------------------------------------------------*/

%LET USSALEDATE = <        >;       /* (V) Variable representing the  */
                                    /*     U.S. sale date.            */
%LET USDATEBEFORESALE = <YES/NO>;   /* (T) Adjust sale date based on  */
                                    /*     an earlier date variable?  */
                                    /*     Type 'YES' (no quotes) to  */
                                    /*     adjust the sale date, or   */
                                    /*     'NO' to skip this part.    */
                                    /*     If you typed 'YES' then    */
                                    /*     also complete the macro    */
                                    /*     variable USEARLIERDATE.    */
%LET    USEARLIERDATE = <        >; /* (V) Variable representing the  */
                                    /*     earlier date variable.     */
%LET USBEGINDAY = <DDMONYYYY>;      /* (T) Please see above 1-C: DATE */
                                    /*     INFORMATION for guidance.  */
%LET USENDDAY = <DDMONYYYY>;        /* (T) Please see above 1-C: DATE */
                                    /*     INFORMATION for guidance.  */

/* Note: In a review the Margin Calculation macro variable             */
/* HMBEGINWINDOW needs to have the same value as the CM macro variable */
/* variable HMBEGINDAY so that model matching will work properly.      */

%LET HMBEGINWINDOW  = <DDMONYYYY>;   /* (T) Please see above 1-C: DATE */
                                     /*     INFORMATION for guidance.  */
                                     /*     NOT required for           */
                                     /*     investigations.            */

/*--------------------------------------------------------------*/
/* 1-C-ii: ADDITIONAL FILTERING OF U.S. SALES, IF REQUIRED      */
/*                                                              */
/*  Should you additionally wish to filter U.S. sales using     */
/*  different dates and/or date variables for CEP v EP sales,   */
/*  complete the following section. This may be useful when     */
/*  you have both EP and CEP sales in an administrative review. */
/*  In reviews, reported CEP sales usually include all sales    */
/*  during the POR. For EP sales in reviews, reported sales     */
/*  usually include all entries during the POR. To filter EP    */
/*  sales by entry date, for example, you would put the first   */
/*  and last days of the POR for BEGINDAY_EP and ENDDAY_EP, and */
/*  the variable for date of entry under EP_DATE_VAR.           */
/*--------------------------------------------------------------*/

%LET FILTER_CEP = <YES/NO>;          /*(T) Additionally filter CEP sales?  */
                                     /*    Type "YES" (no quotes) to       */
                                     /*    filter, "NO" to skip this part. */
                                     /*    If you typed "YES," then also   */
                                     /*    complete the three subsequent   */
                                     /*    indented macro variables.       */
%LET    CEP_DATE_VAR = <  >;         /*(V) The date variable to be used to */
                                     /*    filter CEP sales                */
%LET    BEGINDAY_CEP = <DDMONYYYY>;  /*(T) Day 1 of 1st month of CEP U.S.  */
                                     /*    sales to be kept.               */
%LET    ENDDAY_CEP   = <DDMONYYYY>;  /*(T) Last day of last month of CEP   */
                                     /*    U.S. sales to be kept.          */

%LET FILTER_EP = <YES/NO>;           /*(T) Additionally filter EP sales?   */
                                     /*    Type "YES" (no quotes) to       */
                                     /*    filter, "NO" to skip this part. */
                                     /*    If you typed "YES," then also   */
                                     /*    complete the three subsequent   */
                                     /*    indented macro variables.       */
%LET    EP_DATE_VAR  = <  >;         /*(V) The date variable to be used to */
                                     /*    filter EP sales, such as,       */
                                     /*    entry date.                     */
%LET    BEGINDAY_EP  = <DDMONYYYY>;  /*(T) Day 1 of 1st month of EP U.S.   */
                                     /*    sales to be kept.               */
%LET    ENDDAY_EP    = <DDMONYYYY>;  /*(T) Last day of last month of EP    */
                                     /*    U.S. sales to be kept.          */

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
/*          {RESPONDENT_SEGMENT_STAGE}_HMCEP   = CM revenue/expenses for   */
/*                                               CEP profit                */
/*          {RESPONDENT_SEGMENT_STAGE}_CVSELL  = Selling & profit ratios   */
/*                                               for CV                    */
/*          {RESPONDENT_SEGMENT_STAGE}_HMWTAV  = Wt-avg CM data            */
/*          {RESPONDENT_SEGMENT_STAGE}_LOTADJ  = LOT adjustment factors    */
/*                                                                         */
/*          All output datasets will be placed in the COMPANY directory.   */
/*-------------------------------------------------------------------------*/

%LET PRODUCT = %NRBQUOTE(<Product under Investigation or Review>);    /*(T) Product */
%LET COUNTRY = %NRBQUOTE(<Country under Investigation or Review>);    /*(T) Country */

/*-------------------------------------------------------------------------*/
/* The macro variables BEGINPERIOD and ENDPERIOD refer to the beginning    */
/* and at the end of the official POI/POR. They are used for titling.      */
/* BEGINPERIOD is also used in the Cohen’s d Test.                         */
/*                                                                         */
/* Typically, these dates refer to the first day of the first month for    */
/* the POI/POR for the BEGINPERIOD and the last day of the last month of   */
/* the POI/POR for the ENDPERIOD.  However, for first administrative       */
/* reviews BEGINPERIOD is dependent on the injury results of the           */
/* International Trade Commission (ITC) and the first day of suspension of */
/* liquidation. Please confirm the BEGINPERIOD with the Federal Register   */
/* Notice initiating the first administrative review.                      */
/*-------------------------------------------------------------------------*/

%LET BEGINPERIOD = <DDMONYYYY>;  /* (T) First day of the official POI/POR. */
%LET ENDPERIOD = <DDMONYYYY>;    /* (T) Last day of the official POI/POR.  */

/*------------------------------------------------------------------------*/
/* Between the RESPONDENT, SEGMENT and STAGE macro variables below, there */
/* should be a maximum of 21 digits.                                      */
/*------------------------------------------------------------------------*/

%LET RESPONDENT = <  >;  /*(T) Respondent identifier. Use only letters, numbers  */
                         /*    and underscores. No punctuation marks, blank      */
                         /*    spaces or special characters should be used.      */
%LET SEGMENT    = <  >;  /*(T) Segment of the proceeding, e.g., Invest, AR1,     */
                         /*    Remand. Use only letters, numbers and underscores */
                         /*    No punctuation marks, blank spaces or special     */
                         /*    characters should be used.                        */
%LET STAGE      = <  >;  /*(T) Stage of proceeding, e.g., Prelim, Final, Remand. */
                         /*    Use only letters, numbers and underscores. No     */
                         /*    punctuation marks, blank spaces or special        */
                         /*    characters should be used.                        */

/*-------------------------------------------------------------------*/
/* 1-E: DATABASE INFORMATION FOR U.S. AND CM SALES, COSTS AND        */
/*      EXCHANGE RATES                                               */
/*                                                                   */
/*     Where information may not be relevant (e.g., re: manufacturer */
/*     and prime/non-prime merchandise), 'NA' (not applicable) will  */
/*     appear as the default value.                                  */
/*-------------------------------------------------------------------*/

/*--------------------------------------------------------------*/
/*     1-E-i. EXCHANGE RATE INFORMATION:                        */
/*                                                              */
/*          If, for example, you are using Mexican pesos, type  */
/*          %LET EXDATA1 = MEXICO immediately following. Then,  */
/*          in your programming later on, you would use any of  */
/*          the following methods to refer that exchange rate:  */
/*                                                              */
/*               EXRATE_MEXICO or                               */
/*               &EXRATE1 or                                    */
/*               EXRATE_&EXDATA1                                */
/*                                                              */
/*          Use EXDATA1     for the CM currency, when required. */
/*          It is &EXRATE1 that is used to convert costs and    */
/*          the CM net price into U.S. dollars.                 */
/*                                                              */
/*          If your Comparison Market is reported in more than  */
/*          onecurrency, you must update section 9-B-i in the   */
/*          CM program, as well as sections 1-E-i, 1-E-v, and   */
/*          Part 5 of the Margin program. Instructions for      */
/*          filling out those sections are contained at the     */
/*          beginning of each relevant section.                 */
/*                                                              */
/*          In the event either exchange rate is not required,  */
/*          dummy variables with neutral values are created.    */
/*          (See section 4-A below.)                            */
/*--------------------------------------------------------------*/

%LET USE_EXRATES1 = <YES/NO>;  /*(T) Use exchange rate #1? Type "YES" or */
                               /*    "NO" (without quotes).              */
%LET     EXDATA1   = <  >;     /*(D) Exchange rate dataset name. Use the */
                               /*    currency Cost data is reported in.  */
%LET USE_EXRATES2 = <YES/NO>;  /*(T) Use exchange rate #2? Type "YES" or */
                               /*  "NO" (without quotes).                */
%LET     EXDATA2   = <  >;     /*(D) Exchange rate dataset name.         */

/*--------------------------------------------------------------*/
/* 1-E-ii. U.S. SALES INFORMATION                               */
/*--------------------------------------------------------------*/

%LET USDATA      = <  >;   /*(D) U.S. sales dataset filename.            */
%LET     USBARCODE = <  >; /*(T) Bar code number(s) of U.S. dataset(s)   */
                           /*    used in this program.                   */
%LET     USCONNUM = <  >;  /*(V) Control number                          */
%LET     USCVPROD = <  >;  /*(V) Variable (usually CONNUMU) linking      */
                           /*    sales to cost data.                     */

/* Note: For model matching to work, physical characteristic variables   */
/* need to be defined as all character or all numeric. Physical          */
/* characteristic variable values need to be all numeric.                */ 

%LET     USCHAR   = <  >;  /*(V) Product matching characteristics. List  */
                           /*    them from left to right importance,     */
                           /*    with no punctuation separating them.    */
                           /*    Do not surrounded the values with       */
                           /*    quotes.                                 */
%LET     SALETYPE = <  >;  /*(V/T) Variable indicating type of U.S. sales*/
                           /*      (EP vs. CEP), if any. If there is no  */
                           /*      variable and U.S. sales are all       */
                           /*      of one type, then type either EP or   */
                           /*      CEP (without quotes) to indicates     */
                           /*      which type.                           */
%LET     USQTY    = <  >;  /*(V) Quantity                                */
%LET     USGUP    = <  >;  /*(V) Gross price. Need not be in consistent  */
                           /*    currency, used only to check for zero,  */
                           /*    negative and missing values.            */
%LET     USLOT    = <NA>;  /*(V) Level of trade. If not reported in the  */
                           /*    database and not required, type "NA"    */
                           /*    (without quotes). You may also type     */
                           /*    "NA" if CM & US both have only 1 LOT    */
                           /*    and those LOTs are the same.            */

/* Note: Specify a U.S. manufacturer variable if there is also a         */
/*       manufacturer variable reported in the CM sales or in straight   */
/*       to CV situation with manufacturer reported in the Cost data.    */

%LET     USMANUF  = <NA>;  /*(V) Manufacturer code. If not applicable,   */
                           /*    type "NA" (without quotes).             */

/* Note: Specify a U.S. prime variable if there is also a prime variable */
/*       reported in the CM sales or in straight to CV situation with    */
/*       prime reported in the Cost data.                                */

%LET     USPRIME  = <NA>;  /*(V) Prime/seconds code. If not applicable,  */
                           /*    type "NA" (without quotes).             */
%LET     ENTERVAL = <NA>;  /*(V) Variable for reported entered value. If */
                           /*    there is no variable, type "NA" (without*/
                           /*    quotes.)                                */
%LET IMPORTER = <IMPORTER/CUSCODU>; /* (V) Type in 'IMPORTER' or         */
                           /*    'CUSCODU'. Do not type the quotes.      */
%LET     EX1_VARS = <NA>;  /*(V) Variables in EXDATA1 currency to be     */
                           /*    converted into U.S. dollars, including  */
                           /*    packing. If not applicable, type "NA"   */
                           /*    (without quotes). The converted         */
                           /*    variables in U.S. dollars will have the */
                           /*    names of the old ones with the suffix   */
                           /*    '_USD' added.                           */
%LET     EX2_VARS = <NA>;  /*(V) Variables in EXDATA2 currency to be     */
                           /*    converted into U.S. dollars, including  */
                           /*    packing. If not applicable, type "NA"   */
                           /*    (without quotes). The converted         */
                           /*    variables in U.S. dollars will have the */
                           /*    names of the old ones with the suffix   */
                           /*    '_USD' added.                           */

/*-----------------------------------------------------------------*/
/* 1-E-ii-b. COHEN'S-D TEST                                        */
/*                                                                 */
/*     Normally, the regions will correspond to the 5 Census       */
/*     regions:  Northeast, Midwest, South, West, and Puerto Rico. */
/*     (Do not include U.S. Territories other than Puerto Rico     */
/*     because they are not in the Customs Territory of the U.S.)  */
/*                                                                 */
/*     If you have a region variable, type DP_REGION_DATA=REGION   */
/*     and then specify the region variable in DP_REGION=???.      */
/*     Please note that any unknown regions should be listed as    */
/*     blank spaces and not, for example, as "UNKNOWN" or "UNK."   */
/*                                                                 */
/*     If you instead have a variable that has either the 2-digit  */
/*     postal state code or the zip code (5 or 9 digits), then     */
/*     indicate the same below by typing DP_REGION_DATA=STATE or   */
/*     DP_REGION_DATA=ZIP. If you need to write your own language  */
/*     to create the Census regions, do so in Sect. 2-B below      */
/*     re: changes and edits to the U.S. database.                 */
/*                                                                 */
/*     If you have any unknown purchasers/customers, they should   */
/*     be reported as blank spaces and not, for example, as        */
/*     "UNKNOWN" or "UNK." If this is not the case, please edit    */
/*     the data accordingly.                                       */
/*                                                                 */
/*     Usually, time periods for purposes of the Cohen's-d Test    */
/*     will be defined by quarters, beginning with the first month */
/*     of POI/POR as found in the BEGINPERIOD macro variable       */
/*     defined above in Sect.1-B-i. If you wish to use quarters    */
/*     and do not have a variable for the same, type               */
/*     DP_TIME_CALC=YES and the program will use the sale date     */
/*     variable to assign quarters. If you already have a          */
/*     variable for quarters or are using something other than     */
/*     quarters, type DP_TIME_CALC=NO and also indicate the        */
/*     variable containing the time periods in DP_TIME=???.        */
/*-----------------------------------------------------------------*/

%LET DP_PURCHASER = <  >;                 /*(V) Variable indicating        */
                                          /*    customer for purposes of   */
                                          /*    the DP analysis.           */
%LET DP_REGION_DATA = <REGION/STATE/ZIP>; /*(T) Type either "REGION",      */
                                          /*    "STATE", or "ZIP" (without */
                                          /*    quotes) to indicate the    */
                                          /*    type of data being used    */
                                          /*    to assign Census regions.  */
                                          /*    Then complete the          */
                                          /*    DP_REGION macro            */
                                          /*    variable immediately       */
                                          /*    following.                 */
%LET      DP_REGION = <  >;               /*(V) Variable indicating the    */
                                          /*    DP region if you typed     */
                                          /*    "REGION" for               */
                                          /*    DP_REGION_DATA, or the     */
                                          /*    variable indicating the    */
                                          /*    2-digit postal state       */
                                          /*    designation if you typed   */
                                          /*    "STATE," or the variable   */
                                          /*    indicating the 5-digit zip */
                                          /*    code if you typed "ZIP."   */
%LET DP_TIME_CALC = <YES/NO>;             /*(T) Type "YES" (without        */
                                          /*    quotes)to assign quarters  */
                                          /*    using the beginning of     */
                                          /*    the period.                */
%LET      DP_TIME = <  >;                 /*(V) If you typed "NO" for      */
                                          /*    DP_TIME_CALC because you   */
                                          /*    already have a variable    */
                                          /*    for the DP time period,    */
                                          /*    indicate that variable     */
                                          /*    here.                      */

/*-----------------------------------------------------------------------*/
/* 1-E-iii. NORMAL VALUE PREFERENCE AND CONSTRUCTED VALUE DATA SELECTION */
/*                                                                       */
/*      Set the macro variable NV_TYPE to "P2P" if at least one CM sale  */
/*      survives the CM Program. The Margin Program will try to make     */
/*      Price-to-Price comparisons or all U.S. sales and make            */
/*      Price-to-CV comparisons for any U.S. sales the program cannot    */
/*      find a model match for.                                          */
/*                                                                       */
/*      Set the macro variable NV_TYPE to "CV" if no CM sales survive    */
/*      the CM Program or you want to make Price-to-CV comparison for    */
/*      all U.S. sales.                                                  */
/*                                                                       */
/*      Set the macro variable COST_TYPE to "HM" if at least one CM      */
/*      sale survives the CM Program.                                    */
/*                                                                       */
/*      Set the macro variable COST_TYPE to "CV" if no CM sales survive  */
/*      the CM Program or you want to make Price-to-CV comparison for    */
/*      all U.S. sales.                                                  */
/*-----------------------------------------------------------------------*/

%LET NV_TYPE = <P2P/CV>;   /*(T) Type "P2P" (without quotes) if you have  */
                           /*    CM data for price-to-price comparisons.  */
                           /*    Sales not finding a price-to-price       */
                           /*    comparison will then be matched to CV.   */
                           /*    Type "CV" (without quotes) to compare    */
                           /*    U.S. sales directly to CV.               */

%LET COST_TYPE = <CM/CV>;  /*(T) Type "CM" (without quotes) when    */
                           /*    pulling costs from the CM program. */
                           /*    Type "CV" (without quotes) when    */
                           /*    calculating CV in this Margin      */
                           /*    program.                           */

/*----------------------------------------------------------------*/
/* 1-E-iv. COMPARISON MARKET INFORMATION                          */
/*                                                                */
/*     Complete the next section if you typed NV_TYPE = P2P above */
/*     because you have CM sales for Price-2-Price comparisons.   */
/*                                                                */
/*     If information in the CM sales data is in more than one    */
/*     currency, type CM_MULTI_CUR = YES directly below. You will */
/*     then also have to edit Part 5 below to (re)calculate the   */
/*     CM net price, etc., using currency conversions on the date */
/*     of the U.S. sale.                                          */
/*----------------------------------------------------------------*/

/* Note: Specify a CM manufacturer variable if there is also a           */
/*       manufacturer variable reported in the U.S. sales.               */

%LET HMMANUF = <YES/NO>;      /*(T) Is there a CM manufacturer variable? */
                              /*    Type "YES" or "NO" (without quotes). */

/* Note: Specify a CM prime variable if there is also a prime            */
/*       variable reported in the U.S. sales.                            */

%LET HMPRIME = <YES/NO>;      /*(T) Is there a CM prime variable? Type   */
                              /*    "YES" or "NO" (without quotes).      */

/* Note: For model matching to work, physical characteristic variables   */
/* need to be defined as all character or all numeric. Physical          */
/* characteristic variable values need to be all numeric.                */

%LET HMCHAR = <  >;           /*(V) Product matching characteristics.    */
                              /*    List them from left to right         */
                              /*    in order of importance, with no      */
                              /*    punctuation separating them. Do not  */
                              /*    surround the values with quotes.     */
%LET HM_MULTI_CUR = <YES/NO>; /*(T) Is CM data in more than one          */
                              /*    currency? Type "YES" or "NO"         */
                              /*    (without quotes). If it is "YES",    */
                              /*    then you must also fill out sections */
                              /*    1-E-i and 9-B-i of the CM program,   */
                              /*    as well as sections 1-E-i, and       */
                              /*    Part 5 of the Margin program.        */

/*--------------------------------------------------------------*/
/* 1-E-v. COST DATA MODEL MODIFIERS                             */
/*                                                              */
/*     Both macro variables COP_MANUF and COP_PRIME need to be  */
/*     defined in Price-to-Price and Straight-to-CV situations. */
/*--------------------------------------------------------------*/

%LET COP_MANUF = <YES/NO>;     /*(V) Are there manufacturer variables */
                               /*    in both the sales and the cost   */
                               /*    datasets? Type "YES" or "NO"     */
                               /*    (without quotes).                */
%LET COP_PRIME = <YES/NO>;     /*(T) Are there prime variables in     */
                               /*    both the sales and the cost      */
                               /*    datasets? Type "YES" or "NO"     */
                               /*    (without quotes).                */

/*-----------------------------------------------------------------*/
/* 1-E-vi-a. QUARTERLY CONSTRUCTED VALUE CALCULATIONS              */
/*                                                                 */
/*     To restrict sales comparisons and the calculation of costs  */
/*     to within designated time periods, type "YES" and complete  */
/*     Section 1-E-vi-a. If, instead, you type "NO", you can skip  */
/*     can Section 1-E-vi-a.                                       */
/*                                                                 */
/*     If you have sales and cost data coming from the HM program, */
/*     those, too, should be calculated on a time-specific         */
/*     basis when making comparisons to U.S. sales based on time.  */
/*                                                                 */
/*     Note: You do not need a separate cost database to restrict  */
/*     sales comparison to within time periods. However, the VCOMs */
/*     and TCOMs in the sales databases should also be calculated  */
/*     on a time-specific basis.                                   */
/*-----------------------------------------------------------------*/

%LET COMPARE_BY_TIME = <YES/NO>; /*(T) Calculate costs by time     */
                                 /*    periods? Type "YES" or "NO" */
                                 /*    (without quotes). If        */
                                 /*    "YES," then also complete   */
                                 /*    Section 1-E-vi-a below.     */

/*-------------------------------------------------------------*/
/* 1-E-vi-a. QUARTERLY CONSTRUCTED VALUE CALCULATIONS          */
/*                                                             */
/*     Complete this section if you type all of the following: */
/*                                                             */
/*          COST_TYPE           = CV  (1-E-iii)                */
/*          COMPARE_BY_TIME     = YES (immediately above)      */
/*-------------------------------------------------------------*/

/* Note: The cost time period variable needs to be defined as a two  */
/* digit character variable. The cost time period variable values    */
/* need to be all numeric and left justified.                        */

%LET      COST_TIME_PERIOD = < >;    /*(V) Variable in cost data     */
                                     /*    for time periods.         */
%LET      TIME_INSIDE_POR  = < >;    /*(T) List of values of         */
                                     /*    &COST_TIME_PERIOD         */
                                     /*    variable for periods      */
                                     /*    during the POR,           */
                                     /*    separated by commas, and  */
                                     /*    surrounded by quotes      */
                                     /*    Values in the variables   */
                                     /*    must only be numbers,     */
                                     /*    i.e. '-1', '0', '1', '2', */
                                     /*    '3', etc.                 */
%LET      DIRMAT_VARS = < >;         /*(V) List the direct materials */
                                     /*    variables in the          */
                                     /*    cost dataset that will    */
                                     /*    need to be indexed.  I.e. */
                                     /*    COIL ZINC SCRAPS.  List   */
                                     /*    the variables separately  */
                                     /*    do not put in quotes or   */
                                     /*    separate using commas.    */
%LET      TOTCOM = < >;              /*(V) Reported total cost of    */
                                     /*    manufacturing, often      */
                                     /*    TOTCOM.                   */
/*-----------------------------------------------------*/
/* 1-E-vii. HIGH INFLATION COSTS                       */
/*                                                     */
/* If you type COMPARE_BY_HIGH_INFLATION = YES on the  */
/* first line  also complete the rest of this section. */
/*-----------------------------------------------------*/

%LET COMPARE_BY_HIGH_INFLATION = <YES/NO>; /*(T) Calculate high inflation?     */
                                           /*    Type "YES" or "NO"            */
                                           /*    (without quotes).             */
%LET      COST_YEAR_MONTH = <  >;          /*(V) Variable in Cost data         */
                                           /*    representing year and month.  */
%LET      LAST_YEAR_MONTH = <yyyymm>;      /*(T) Last year and month of in the */
                                           /*    form YYYYMM.                  */

/*-------------------------------------------------------------*/
/* 1-E-viii. CV DATA ONLY FOR U.S. SALES                       */
/*                                                             */
/*     If you type COST_TYPE = CV above in Section 1-E-iii     */
/*     because you do NOT have cost data coming from the CM    */
/*     program, complete the following sections:               */
/*                                                             */
/*     1-E-iv-ii. CV DATA ONLY FOR U.S. SALES                  */
/*     1-E-iv-iii. SURROGATE COSTS FOR NON-PRODUCTION          */
/*-------------------------------------------------------------*/

%LET COST_DATA = <  >;    /*(D) Cost dataset name                   */
%LET COSTBARCODE = <  >;  /*(T) Bar code number(s) of cost          */
                          /*    dataset(s) used in this program.    */
%LET COST_MATCH = <  >;   /*(V) The variable (usually CONNUM)       */
                          /*    linking cost data to sales data.    */
%LET COST_QTY = <  >;     /*(V) Production quantity                 */

/* Note: Specify a Cost manufacturer if there is also a             */
/*       manufacturer reported in the U.S. sales.                   */

%LET COST_MANUF = <NA>;   /*(V) Manufacturer code. If not           */
                          /*    applicable, type "NA" (without      */
                          /*    quotes).                            */

/* Note: Specify a Cost prime variable if there is also a prime     */
/*       variable reported in the U.S. sales.                       */

%LET COST_PRIME = <NA>;   /*(V) Prime code. If not applicable,      */
                          /*    type "NA" (without quotes).         */

%LET USE_COST_DUTY_DRAWBACK = <YES/NO>;     /*(T) Make Cost duty drawback      */
                                            /*    available for use in         */
                                            /*    calculating the net U.S.     */
                                            /*    price? Type "YES" or "NO"    */
                                            /*    (without quotes). If "YES,"  */
                                            /*    then also define the macro   */
                                            /*    variable COST_DUTY_DRAWBACK  */
                                            /*    below.                       */
%LET      COST_DUTY_DRAWBACK =  <  >;       /*(V) Variable in Cost data        */
                                            /*    representing duty drawback.  */

/*---------------------------------------------------------*/
/* 1-E-ix. SURROGATE COSTS FOR NON-PRODUCTION              */
/*                                                         */
/*     Complete the following section if you have products */
/*     that were sold but not produced during the period,  */
/*     and those products do not already have adequate     */
/*     surrogate cost information reported.                */
/*---------------------------------------------------------*/

%LET MATCH_NO_PRODUCTION = <YES/NO>; /*(T) Find surrogate costs for products*/
                                     /*    not produced during the POR?     */
                                     /*    Type "YES" or "NO" (without      */
                                     /*    quotes). If "YES," complete      */
                                     /*    the indented macro variables     */
                                     /*    that follow.                     */
%LET   COST_PROD_CHARS = <YES/NO>;   /*(T) Are the product physical         */
                                     /*    characteristic variables in the  */
                                     /*    cost database? Type "YES" or     */
                                     /*    "NO" without quotes).            */

/* Note: For model matching to work, physical characteristic variables      */
/* need to be defined as all character or all numeric. Physical             */
/* characteristic variable values need to be all numeric.                   */

%LET   COST_CHAR = <  >;             /*(V) Product matching characteristics */
                                     /*    in cost data. List them from     */
                                     /*    left-to-right in order of        */
                                     /*    importance, with no punctuation  */
                                     /*    separating them. Do not surround */
                                     /*    the values with quotes.          */

/*------------------------------------------------------------------*/
/* 1-F: CONDITIONAL PROGRAMMING OPTIONS:                            */
/*------------------------------------------------------------------*/

%LET LOT_ADJUST = <NO/HM/INPUT>;  /*(T) Type "NO" (without quotes) when    */
                                  /*    not making an LOT adjustment. Type */
                                  /*    "HM" (without quotes) if using     */
                                  /*    info. from CM sales. Type "INPUT"  */
                                  /*    (without quotes) if using info.    */
                                  /*    from a source other than CM sales. */
                                  /*    If you typed "INPUT," then also    */
                                  /*    complete Sect. 7-A-i below.        */
%LET CEPROFIT = <CALC/INPUT>;     /*(T) Type "CALC" (without quotes) to    */
                                  /*    use CM and U.S. expense and        */
                                  /*    revenue data. You must have a cost */
                                  /*    database if you type "CALC." Type  */
                                  /*    "INPUT" (without quotes) to supply */
                                  /*    an alternative CEP profit rate     */
                                  /*    when not calculating the same.     */
%LET CEPRATE = <  >;              /*(T) If you typed "LET CEPROFIT=INPUT"  */
                                  /*    directly above, the alternative    */
                                  /*    CEP profit rate in decimal form.   */
%LET ALLOW_CEP_OFFSET = <YES/NO>; /*(T) Allow CEP offset? Type "YES" or    */
                                  /*    "NO" (without quotes).             */
%LET CVSELL_TYPE = <CM/OTHER>;    /*(T) Type "CM" (without quotes) when    */
                                  /*    using CM selling & profit info.    */
                                  /*    Type "OTHER" (without quotes)      */
                                  /*    if using info. from a source       */
                                  /*    other than CM sales.               */
                                  /*    If you typed "OTHER," then also    */
                                  /*    complete Sect. 9-A below. This     */
                                  /*    macro variable is required only    */
                                  /*    if you will have CV comparisons.   */
%LET PER_UNIT_RATE = <YES/NO>;    /*(T) Only print per-unit (and not ad    */
                                  /*    valorem) cash deposit and, if      */
                                  /*    applicable, assessment rates even  */
                                  /*    when entered values are reported?  */
                                  /*    Type "YES" or "NO" (without quotes)*/

/*------------------------------------------------------------------*/
/* 1-G: FORMAT, PROGRAM AND PRINT OPTIONS                           */
/*------------------------------------------------------------------*/

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

%LET DEL_WORKFILES = NO;   /*(T) Delete all work library files?  Default       */
                           /*    is NO. If you type "YES" (without             */
                           /*    quotes), you may increase program speed,      */
                           /*    but will not be able examine files in         */
                           /*    the work library for diagnostic purposes.     */
%LET CALC_RUNTIME = YES;   /*(T) Calculate program run time? If you don't      */
                           /*    like to see this info., type "NO" (without    */
                           /*    quotes)                                       */
OPTION NOSYMBOLGEN;        /* SYMBOLGYN prints macro variable resolutions.     */
                           /* Reset to "NOSYMBOLGEN" (without quotes) to       */
                           /* deactivate.                                      */
OPTION MPRINT;             /* MPRINT prints macro resolutions, type            */
                           /* "NOMPRINT" (without quotes) to deactivate.       */
OPTION NOMLOGIC;           /* MLOGIC prints additional info. on macros,        */
                           /* type "MLOGIC" (without quotes) to activate.      */
OPTION MINOPERATOR;        /* MINOPERATOR is required when using the IN(..)    */
                           /* function in macros.                              */
OPTION OBS = MAX;          /* Indicates the number of OBS to process in each   */
                           /* data set. Default setting of MAX processes all   */
                           /* transactions. If you have large datasets and     */
                           /* initially wish to debug the program using a      */
                           /* limited number of transactions, you can reset    */
                           /* this option by typing in a number.               */
OPTION NODATE;             /* Suppresses date in header                        */
OPTION PAGENO = 1;         /* Restarts page numbering at Page 1                */
OPTION YEARCUTOFF = 1960;  /* Specifies the first year of a 100-year span that */
                           /* is used to read a two-digit year                 */
OPTION SPOOL;              /* Aids finding location of syntax error in macros  */
OPTION VARINITCHK = ERROR; /* An uninitialized variable will generate an ERROR */
OPTION FORMCHAR = '|----|+|---+=|-/\<>*';          /* For printing tables      */

/*------------------------------------------------------------------*/
/* 1-H:      GENERATE PROGRAM-SPECIFIC TITLES, FOOTNOTES            */
/*               AND MACROS NEEDED TO EXECUTE THE PROGRAM.          */
/*------------------------------------------------------------------*/

%LET SALESDB = USSALES; 
%G1_RUNTIME_SETUP
%G2_TITLE_SETUP     
%G3_COST_TIME_MVARS     

/*----------------------------------------------------------------------*/
/* 1-I: PRIME AND MANUFACTURER MACROS AND MACRO VARIABLES               */
/*                                                                      */
/*                                                                      */
/*     In the programming language, the macro variables &USPRIM,        */
/*     &SALES_COST_MANF (for merging sales with costs), &USMANF         */
/*     (for merging U.S. sales with CM sales for P2P comparisons),      */
/*     &HMPRIM, &HM_P2P_MANF and &CVMANF are used. Their values         */
/*     are determined by the answers in Sect. 1-E above.                */
/*                                                                      */
/*     If you type %LET USMANUF=NA, then the manufacturer-related       */
/*     macro variables for U.S. sales (&US_COST_MANF and &USMANF        */
/*     will be set to null/blank values. Since you need manufacturer    */
/*     designations in both U.S. & CM sales for them to merge by        */
/*     manufacturer, &HM_P2P_MANF will also be set to a null/blank      */
/*     value. Similarly, &COST_MANF will be set to null/blank values    */
/*     if %LET USMANUF=NA. Otherwise, &US_COST_MANF and &USMANF         */
/*     will be set to the variable indicated by %LET USMANUF=<???>      */
/*     when manufacturer is also relevant for cost and CM sales,        */
/*     respectively.                                                    */
/*                                                                      */
/*     If you type %LET HMMANUF=NO, then &HM_P2P_MANF will be set to    */
/*     a null/blank value as will &USMANF. Otherwise, &HMMANF           */
/*     will be equal to HMMANF, the standardized variable name          */
/*     assigned in the CM program, as long as U.S. manufacturer is      */
/*     also relevant.                                                   */
/*                                                                      */
/*     Similarly, &USPRIM and &HMPRIM will be set to null/blank values  */
/*     if you type either %LET USPRIME=NA or %LET HMPRIME=NA.           */
/*     Otherwise, they will be set to the variables indicated in        */
/*     %LET USPRIME=<???> and %LET HMPRIME=<???> when prime is          */
/*     relevant for both U.S. and CM sales.                             */
/*----------------------------------------------------------------------*/

%US1_MACROS 

/***************************************************************************/
/* PART 2: BRING IN U.S. SALES, CONVERT DATE VARIABLE, IF NECESSARY, MERGE */
/*         EXCHANGE RATES INTO SALES, IF REQUIRED.                         */
/***************************************************************************/

/*----------------------------------------------------------------------*/
/* 2-A: BRING IN U.S. SALES DATA                                        */
/*                                                                      */
/*          Alter the SET statement, if necessary, to bring in more     */
/*          than one SAS database. If you need to rename variables,     */
/*          change variables from character to numeric (or vice versa), */
/*          in order to do align the various databases, make such       */
/*          changes here.                                               */
/*                                                                      */
/*          Changes to U.S. data using exchange rates and costs should  */
/*          wait until Part 4, below, after the cost and exchange rate  */
/*          databases are attached.                                     */
/*                                                                      */
/*          Leave the data step open through the RUN statement          */
/*          following the execution of the US2_SALETYPE macro in        */
/*          Sect. 2-E.                                                  */
/*----------------------------------------------------------------------*/

DATA USSALES;
    SET COMPANY.&USDATA;
    &USSALEDATE = FLOOR(&USSALEDATE); /* Eliminates the time part of sale date when defined as a datetime variable. */

    /* <Selectively adjust sale date based on an earlier date variable.> */

    %DEFINE_SALE_DATE (SALEDATE = &USSALEDATE, DATEBEFORESALE = &USDATEBEFORESALE, EARLIERDATE = &USEARLIERDATE); 

    /*------------------------------------------------------------------*/
    /* 2-B: Insert and annotate any changes below.                      */
    /*------------------------------------------------------------------*/

    /* <Insert changes here, if required.> */          

    /*---------------------------------------------------------------------*/
    /* 2-C: LEVEL OF TRADE                                                 */
    /*                                                                     */
    /*      The variable USLOT will be created containing the levels       */
    /*          of trade. It is this variable that is used in the          */
    /*          programming. If you typed '%LET USLOT = NA' in             */
    /*          Sect. 1-E-ii above, the variable USLOT will be set to 0    */
    /*          (zero). Otherwise, USLOT will be set equal to the variable */
    /*          specified in %LET USLOT = <???>.                           */
    /*                                                                     */
    /*           If you have a level of trade variable and need to make    */
    /*       changes to its values, or you do not have one but need to     */
    /*           create one, make those edits before the G4_LOT.           */
    /*---------------------------------------------------------------------*/

    %G4_LOT(&USLOT,USLOT)

    /*---------------------------------------------------------------------*/
    /* 2-D: CREATE U.S. SALE TYPE PROGRAMMING VARIABLE                    */
    /*                                                                     */
    /*     The variable SALE_TYPE will be created, indicating whether U.S. */
    /*     sales are EP or CEP. It is this variable that will be used in   */
    /*     the programming language. If there is a variable already in     */
    /*     the data and you typed %LET SALETYPE={{variable name}} in       */
    /*     in Sect. I-E-ii above, SALE_TYPE will be set equal to that      */
    /*     variable. If no variable exists in the reported data,           */
    /*     SALE_TYPE will be set equal to "EP" if you typed                */
    /*     %LET SALETYPE=EP, or "CEP" if you typed %LET SALETYPE=CEP.      */
    /*---------------------------------------------------------------------*/

    %US2_SALETYPE

    /*------------------------------------------------------------------------*/
    /* 2-E: CREATE THE U.S. QUARTER VARIABLE IN QUARTERLY COST CASES, AND     */
    /*      THE U.S. YEARMONTH VARIABLE IN HIGH INFLATION COST CASES.         */
    /*------------------------------------------------------------------------*/

    %CREATE_QUARTERS(&USSALEDATE, MARGIN)   /* Assigns quarters to US sales based on */
                                            /* the date of sale variable and the     */
                                            /* first day of the POR/POI. The         */
                                            /* values will be '-1', '0', '1', etc.   */
    %CREATE_YEAR_MONTH(&USSALEDATE, US)     /* In high inflation cases creates the   */
                                            /* variable YEARMONTHH representing the  */
                                            /* year and month of sale date.          */
RUN;

/*ep*/

/*---------------------------------------------------------------------*/
/* 2-F: GET COUNTS OF USSALES DATASET FOR LOG REPORT                   */
/*---------------------------------------------------------------------*/

%CMAC2_COUNTER (DATASET = COMPANY.&USDATA, MVAR = ORIG_USSALES);

/*ep*/

/*------------------------------------------------------------------*/
/* 2-E: TEST FORMAT OF DATE VARIABLE(s) AND CONVERT, WHEN NECESSARY */
/*                                                                  */
/*     This section tests the sale date variable and additional     */
/*     variables used to filter CEP and EP sales to see if they are */
/*     in SAS date format. If not, an attempt will be made to       */
/*     convert them using language that will work for many cases,   */
/*     but not all. Should the language not convert your data       */
/*     correctly, contact a SAS Support Team member for assistance. */
/*------------------------------------------------------------------*/

%G5_DATE_CONVERT

/*ep*/

/*-------------------------------------------------------------------*/
/* 2-F: CHECK FOR NEGATIVE AND MISSING DATA, AND FOR DATES           */
/*          OUTSIDE THE POI OR WINDOW. CREATE THE MONTH VARIABLE     */
/*          FOR AN ADMINISTRATIVE REVIEW.                            */
/*                                                                   */
/*          Sales with gross price or quantity variables that have   */
/*          missing values or values less than or equal to zero will */
/*          be taken out of the database only to make the program    */
/*          run smoothly. This is not a policy decision. You may     */
/*          have to make adjustments to such sales.                  */
/*                                                                   */
/*          Sales outside the POI (for an investigation) or POR      */
/*          (for administrative reviews) will be set aside.          */
/*                                                                   */
/*          In an administrative review, a month variable will be    */
/*          created giving each month in the window period a unique  */
/*          number. In the first calendar year of the review (as     */
/*          designated by the BEGINWINDOW macro variable), the value */
/*          of USMONTH will be equal to the normal numeric month     */
/*          designation (e.g., Jan=1, Feb=2). In the second          */
/*          calendar year of the review, USMONTH will be equal to    */
/*          the numeric month designation + 12 (e.g., Jan=1+12=13).  */
/*          Similarly, in a third calendar year, USMONTH = month+24. */
/*-------------------------------------------------------------------*/

%G6_CHECK_SALES

/*ep*/

/*------------------------------------------------------------------*/
/* 2-G: MERGE IN EXCHANGE RATES, AS REQUIRED                        */
/*                                                                  */
/*          For both potential exchange rates in Sect. 1-E-i above, */
/*          macro variables with neutral values are first created.  */
/*          These neutral values will be over-written with actual   */
/*          exchange rate data, as required.                        */
/*------------------------------------------------------------------*/

%G7_EXRATES 

/*ep*/

/*---------------------------------------------------------------------*/
/* 2-H: CONVERT FOREIGN-CURRENCY VARIABLES INTO U.S. DOLLARS           */
/*                                                                     */
/*     New variables will be created, having the names of the old ones */
/*     with the suffix "_USD" added (<oldname>_USD), and set equal to  */
/*     the values of old variables multiplied by the indicated         */
/*     exchange rate. For example, if you type %LET EX1_VARS=DMOVEU,   */
/*     then DMOVEU_USD = DMOVEU*&EXRATE1.                              */
/*---------------------------------------------------------------------*/
 
%US3_USD_CONVERSION

/*ep*/

/******************************************************************/
/* PART 3: COST INFORMATION                                       */
/*                                                                */
/* Determine whether information from the CM program, U.S. sales  */
/* database or from a CV-only database will be used.              */
/*                                                                */
/* If the respondent has supplied separate COP and CV databases,  */
/* combine them together in CM program in Sect. 3-A and make      */
/* required adjustments. The combined weight-averaged cost        */
/* database calculated in CM Program can then also be used in     */
/* this Margin Program with U.S. sales. This is preferable to     */
/* calculating the two separately.                                */
/*                                                                */
/* When a CV-only database has been supplied, make required       */
/* changes to items in the indicated sections below:              */
/*                                                                */
/* Sect. 3-A-i Cost of manufacturing, G&A, interest, and cost of  */
/*             production                                         */
/******************************************************************/

/*-------------------------------------------------------------*/
/* 3-A CALL UP CV DATABASE, IF PROVIDED.                       */
/*                                                             */
/* Calculate major input adjustments.                          */
/*                                                             */
/* Do NOT make changes to GNA, INTEX or the calculation        */
/* of TOTCOM here. Instead, do these below in Sect. 3-C.       */
/*                                                             */
/* Also, do NOT reset missing or zero production quantities    */
/* to positive values at this point with the exception noted   */
/* in the next paragraph. The resetting of zero/missing        */
/* production quantities before weight averaging will be done  */
/* later in Sect. 3-E below.                                   */
/*                                                             */
/* For annualized (not quarterly) costs, if the respondent     */
/* has already provided surrogate cost information for a       */
/* particular product but has put either a zero or a missing   */
/* value for production quantity, then the default language    */
/* in Sect. 3-B will mistakenly mark the product as one still  */
/* requiring surrogate information. For annualized costs       */
/* only, you can remedy this by setting the production         */
/* quantity to a non-zero or non-missing value in Sect 3-A-i.  */
/*-------------------------------------------------------------*/

%MACRO SETUP_COST;
    %GLOBAL FIND_SURROGATES;
    %LET FIND_SURROGATES = NO;   /*Default value, do not edit. */

    %IF %UPCASE(&COST_TYPE) = CV %THEN
    %DO;
        DATA COST;
            SET COMPANY.&COST_DATA;

            /*------------------------------------------------------------*/
            /* 3-A-i: Insert and annotate any major input changes below.  */
            /* Insert language for creating the cost time period variable */
            /* The variable needs to be defined as a two-digit character  */
            /* variable. The cost time period variable values need        */
            /* to be all numeric and left justified. E.g. '-1', '0', '1', */
            /* '2', etc.  The first quarter of the POI/POR must be '1'.   */
            /*------------------------------------------------------------*/

            /* <Insert major input changes here, if required.> */          
        RUN;

        /*--------------------------------------------------------------*/
        /* 3-a-ii: GET COST COUNT FOR LOG REPORTING                     */
        /*--------------------------------------------------------------*/

        %CMAC2_COUNTER (DATASET = COMPANY.&COST_DATA, MVAR = ORIG_COST);

        /*-----------------------------------------------------------------*/
        /* 3-B SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POI/POR    */
        /*                                                                 */
        /* The macro variable &FIND_SURROGATES will be created whose value */
        /* will be "YES" when it does find products requiring surrogates   */
        /* using the criteria specified. Otherwise, &FIND_SURROGATES will  */
        /* be set to "NO," turning off sections 3-B and 3-G.               */
        /*-----------------------------------------------------------------*/

        /*------------------------------------------------------------*/
        /* 3-B-i IDENTIFY PRODUCTS NOT PRODUCED DURING POI/POR        */
        /*       FOR WHICH SURROGATE COSTS ARE NEEDED.                */
        /*                                                            */
        /* The %G8_FIND_NOPRODUCTION macro below identifies products  */
        /* needing surrogate cost information when total production   */
        /* during the cost period is zero or missing. If this         */
        /* assumption does not fit the circumstances, you will need   */
        /* to make edits accordingly.                                 */
        /*                                                            */
        /* For annualized (not quarterly nor high inflation) costs,   */
        /* if the respondent has already provided surrogate cost      */
        /* information for a particular product but has put either a  */
        /* zero or a missing value for production quantity, then the  */
        /* default language will mistakenly think no surrogate        */
        /* information has been provided. For annualized costs only,  */
        /* you can remedy this problem by setting the production      */
        /* quantity to a non-zero or non-missing value above in       */
        /* Section 3-A-i.                                             */
        /*------------------------------------------------------------*/

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

            /*----------------------------------------------------*/
            /* 3-B-ii ATTACH PRODUCT CHARACTERISTICS, IF REQUIRED */
            /*                                                    */
            /* When product characteristic variables are not      */
            /* in the cost data, they will be taken from the      */
            /* U.S. sales data.                                   */
            /*----------------------------------------------------*/

            %G9_COST_PRODCHARS
        %END;

        PROC PRINT DATA = COST (OBS = &PRINTOBS);
            WHERE &COST_QTY IN (., 0);
            TITLE3 "RESPONDENTS REPORTED COST WITH MISSING OR ZERO PRODUCTION QUANTITY";
            TITLE4 "BY DEFAULT THE PROGRAM WILL SET PRODUCTION QUATITY TO ONE (1)";
            TITLE5 "IF YOU WANT THE PROGRAM TO FIND SURROGATE COST FOR THESE CONNUMS WITHOUT PRODUCTION QUANTITY";
            TITLE6 "TURN ON SECTION 1-E-ix. SURROGATE COSTS FOR NON-PRODUCTION";
        RUN;
                    
        /*---------------------------------------------------------------*/
        /* 3-C: Quarterly Cost Situations                                */
        /*---------------------------------------------------------------*/
        /*                                                               */
        /* If you have CV and quarterly cost, input the period raw       */
        /* material average purchase cost. There must be a separate      */
        /* average purchase cost table for each of the direct materials  */
        /* that are subject to quarterly costs. I.E. there should be a   */
        /* separate  table for each variable listed in the               */
        /* %LET DIRMAT_VARS in section 1-E-vi-a above.                   */
        /*---------------------------------------------------------------*/

        PROC FORMAT;
            /************************************************/
            /* Example 1: Average per-unit purchase cost of */
            /*            HR COIL by period.                */
            /************************************************/

            /*    VALUE $COIL_INPUT                                 */
            /*        '-1' = <average purchase cost for the period> */
            /*        '0' = <average purchase cost for the period>  */
            /*        '1' = <average purchase cost for the period>  */
            /*        '2' = <average purchase cost for the period>  */
            /*        '3' = <average purchase cost for the period>  */
            /*        '4' = <average purchase cost for the period>  */
            /*        '5' = <average purchase cost for the period>  */
            /*        '6' = <average purchase cost for the period>  */
            /*        '7' = <average purchase cost for the period>; */

            /************************************************/
            /* Example 2: Average per-unit purchase cost of */
            /*            ZINC by period.                   */
            /************************************************/

            /*    VALUE $ZINC_INPUT                                 */
            /*        '-1' = <average purchase cost for the period> */
            /*        '0' = <average purchase cost for the period>  */
            /*        '1' = <average purchase cost for the period>  */
            /*        '2' = <average purchase cost for the period>  */
            /*        '3' = <average purchase cost for the period>  */
            /*        '4' = <average purchase cost for the period>  */
            /*        '5' = <average purchase cost for the period>  */
            /*        '6' = <average purchase cost for the period>  */
            /*        '7' = <average purchase cost for the period>; */

            /************************************************/
            /* Example 3: Average per-unit purchase cost of */
            /*            SCRAP by period.                  */
            /************************************************/

            /*    VALUE $SCRAPS_INPUT                               */
            /*        '-1' = <average purchase cost for the period> */
            /*        '0' = <average purchase cost for the period>  */
            /*        '1' = <average purchase cost for the period>  */
            /*        '2' = <average purchase cost for the period>  */
            /*        '3' = <average purchase cost for the period>  */
            /*        '4' = <average purchase cost for the period>  */
            /*        '5' = <average purchase cost for the period>  */
            /*        '6' = <average purchase cost for the period>  */
            /*        '7' = <average purchase cost for the period>; */
        RUN;

        %G10_TIME_PROD_LIST
        %G11_CREATE_TIME_COST_DB
        %G12_ZERO_PROD_IN_PERIODS
        %G13_CREATE_COST_PROD_TIMES

        /*-------------------------------------------------------------------*/
        /* 3-D: High Inflation Situations                                    */
        /*                                                                   */
        /* Create monthly inflation indexes for high inflation adjustments.  */
        /* Indexes are based in the CM country producer price index (PPI).   */
        /* Wrap the year/month and index values in quotes.                   */
        /*-------------------------------------------------------------------*/

        %MACRO CREATE_HIGH_INFLATION_INDEXES;
            %IF %UPCASE(&COMPARE_BY_HIGH_INFLATION) = YES %THEN
            %DO;
                PROC FORMAT;
                    VALUE $PRICE_INDEX
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>'
                        '<yyyymm>' = '<PPI for yyyymm>';
                RUN;
            %END;
        %MEND CREATE_HIGH_INFLATION_INDEXES;

        %CREATE_HIGH_INFLATION_INDEXES

        /******************************************************************/
        /* 3-E: CALCULATE TOTAL COST OF MANUFACTURING, GNA, INTEREST, AND */
        /*      TOTAL COST OF PRODUCTION.                                 */
        /******************************************************************/

        DATA COST;
            SET COST;  

            /* If respondents report surrogate cost for sales CONNUMs with no production, */
            /* the following IF statement will set the missing or zero production         */
            /* quantity to one so that the surrogate cost will be used.                   */

            IF &COST_QTY IN (.,0) THEN 
                &COST_QTY = 1;
                                          
            TCOMCOP = <  >;               /* Total cost of manufacturing.        */
            VCOMCOP = <TCOMCOP - FOH>;    /* Variable cost of manufacturing      */
                                          /* equal to TCOMCOP less fixed costs.  */
            GNACOP = <  >;                /* General and administrative expense. */
            INTEXCOP = <  >;              /* Interest expense.                   */

            TOTALCOP = TCOMCOP + GNACOP + INTEXCOP; /* Total cost of production. */
        RUN;

        /*-----------------------------------------------*/
        /* 3-F: WEIGHT-AVERAGE COST DATA, WHEN REQUIRED. */
        /*-----------------------------------------------*/

        %G15_CHOOSE_COSTS

        /*--------------------------------------------------------------------*/
        /* 3-G: FIND SURROGATE COSTS FOR PRODUCTS NOT PRODUCED DURING POR     */
        /*--------------------------------------------------------------------*/

        %G16_MATCH_NOPRODUCTION

        /*ep*/

        /*--------------------------------------------------------------------*/
        /* 3-H: GET COST COUNT FOR LOG REPORTING                              */
        /*--------------------------------------------------------------------*/

        %CMAC2_COUNTER (DATASET = COST, MVAR = PRE_AVGCOST);

        /*--------------------------------------------------------------------*/
        /* 3-J: GET COST COUNT FOR LOG REPORTING                              */
        /*--------------------------------------------------------------------*/

        %CMAC2_COUNTER (DATASET = AVGCOST, MVAR = AVGCOST);
    %END;
%MEND SETUP_COST;

%SETUP_COST

/*ep*/

/*--------------------------------------------------------------------*/
/* 3-I: MERGE COSTS WITH U.S. SALES DATA                              */
/*--------------------------------------------------------------------*/

/**/ %LET COST_PRIM = ;
/**/ %LET SALES_COST_PRIME = ;
/**/ %LET EQUAL_COST_PRIME = ;

%G17_FINALIZE_COSTDATA 

/*ep*/

/***************************************************************************/
/* PART 4: CALCULATE THE NET U.S. PRICE                                    */
/***************************************************************************/

/*---------------------------------------------------------------------------*/
/* 4-A: CALCULATION OF AGGREGATE PRICE ADJUSTMENT VARIABLES                  */
/*                                                                           */
/* All aggregate variables should be in U.S. dollars after any adjustments.  */
/* If you have any variables originally in non-USD currency that you listed  */
/* in Sect. I-E-ii under EX1_VARS = ??? or EX2_VARS = ???, these variables   */
/* are now converted into U.S. dollars and have new names. Use the new       */
/* names below. The new names consist of the old names with the suffix       */
/* "_USD" added. For example, if you typed "%LET EX1_VARS = TRUCKING" in     */
/* Sect. I-E-ii, the new variable TRUCKING_USD has been created and set      */
/* equal to TRUCKING * &EXRATE1.                                             */
/*                                                                           */
/* If you want to use the Cost based duty drawback in the calculation        */
/* USNETPRI, the duty drawback variable will need to be converted to USD by  */
/* multiplying the variable by an exchange rate variable such as &EXRATE1.   */
/*---------------------------------------------------------------------------*/

DATA USSALES;
    SET USSALES;

    USGUP = <&USGUP>;    /* Gross unit price. Default is to use the        */
                         /* variable selected for the &USGUP macro in      */
                         /* Section 1-E-ii above                           */
    USGUPADJ = <0>;      /* Price adjustments to be added to USGUP,        */
                         /* including duty drawback, CVD export subsidies. */
                         /* If using Cost based duty drawback in the       */
                         /* variable will need to be converted to USD by   */
                         /* multiplying the variable by an exchange rate   */
                         /* variable such as &EXRATE1.                     */
    USDISREB = <0>;      /* Discounts, rebates and other price adjust-     */
                         /* ments to be subtracted from USGUP              */
    USDOMMOVE = <0>;     /* Domestic U.S. movement expenses up to delivery */
                         /* alongside the vessel at port of export         */
    USINTLMOVE = <0>;    /* International and U.S. movement expenses,      */
                         /* including U.S. duties, from loading onto the   */
                         /* vessel to delivery in U.S.                     */
    USCREDIT = <0>;      /* Imputed credit                                 */
    USDIRSELL = <0>;     /* Direct selling expenses for circumstance of    */
                         /* sale (COS) adjustments. Excludes imputed       */
                         /* credit (USCREDIT) and any direct selling       */
                         /* expenses incurred in the U.S. on CEP sales.    */
                         /* Includes all direct selling on EP sales and    */
                         /* any direct selling on CEP sales NOT incurred   */
                         /* in the U.S.                                    */
    USCOMM = <0>;        /* All commissions on EP sales and those on CEP   */
                         /* sales incurred outside of the U.S. Do NOT      */
                         /* include commissions on CEP sales incurred in   */
                         /* the U.S. here, instead include these in        */
                         /* CEPOTHER.                                      */
    USICC = <0>;         /* Imputed inventory carrying costs, excluding    */
                         /* CEP inventory carrying costs.                  */
    USISELL = <0>;       /* Indirect selling expenses, excluding USICC     */
                         /* and any CEP indirects.                         */
    CEPICC = <0>;        /* CEP (incurred in the U.S.) inventory carrying  */
                         /* cost expenses. Will be set to zero for EP      */
                         /* sales.                                         */
    CEPISELL = <0>;      /* CEP (incurred in the U.S.) indirect selling    */
                         /* expenses. Will be set to zero for EP sales.    */
    CEPOTHER = <0>;      /* Any other CEP (incurred in the U.S.)           */
                         /* commissions, direct selling, further           */
                         /* manufacturing, etc. expenses not included in   */
                         /* CEPICC or CEPISELL. Will be set to zero for    */
                         /* EP sales.                                      */
    USPACK = <0>;        /* Export packing to the U.S.                     */

/*----------------------------------------------------------------------*/
/* 4-A-i: INDIRECTS FOR COMMISSION OFFSETS                              */
/*                                                                      */
/*  Calculation of indirect selling expenses for purposes of commission */
/*     offsets, USINDCOMM.                                              */
/*----------------------------------------------------------------------*/

    %US4_INDCOMM
RUN;

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-B: CEP PROFIT RATE                                                    */
/*                                                                         */
/* If you typed %LET CEPPROFIT = CALC in Sect. 1-F above, the US5_CEPRATE  */
/* macro will use revenue and expense information from U.S. and CM sales   */
/* to calculate the overall CEP profit ratio. Total amounts for cost of    */
/* goods sold, revenue, selling expenses and movement will be calculated   */
/* for each U.S. transaction, and then converted from U.S. dollars into CM */
/* currency using EXRATE1. The overall amounts for COGS, revenue and       */
/* expenses on U.S. sales will then be calculated and combined with CM     */
/* data to calculate CEP profit rate.                                      */
/*                                                                         */
/* If you typed %LET CALC_CEPPROFIT = INPUT above, the profit rate         */
/* supplied by %LET CEPRATE=<???> will be used for the CEP profit ratio.   */
/* CEP selling expense amounts will be set to zero for EP sales.           */
/*-------------------------------------------------------------------------*/

%US5_CEPRATE

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-C: CALCULATE NET U.S. PRICE                                           */
/*-------------------------------------------------------------------------*/

PROC SORT DATA = USSALES;
    BY SALE_TYPE;
RUN;

/*ep*/

DATA USSALES SALES;
    SET USSALES;
    BY SALE_TYPE;

    IF FIRST.SALE_TYPE THEN
        COUNT = 0;

    COUNT + 1;

    IF UPCASE(SALE_TYPE) = 'EP' THEN 
    DO;
        CEPRATIO = 0;
        CEPROFIT = 0;
        USNETPRI = USGUP + USGUPADJ - USDISREB - USDOMMOVE - USINTLMOVE;
    END;
    ELSE
    IF UPCASE(SALE_TYPE) = 'CEP' THEN
    DO;
        CEPROFIT = (USCREDIT + CEPICC + CEPISELL + CEPOTHER) * CEPRATIO;

        USNETPRI = USGUP + USGUPADJ - USDISREB - USDOMMOVE - USINTLMOVE
                 - USCREDIT - CEPICC - CEPISELL - CEPOTHER - CEPROFIT;
    END;

    OUTPUT USSALES;

    IF COUNT LE &PRINTOBS THEN
        OUTPUT SALES;
RUN;

/*ep*/

PROC PRINT DATA = SALES;
    ID SALE_TYPE;
    TITLE3 'SAMPLE OF U.S. NET PRICE CALCULATIONS';
RUN;

/*ep*/

/*-------------------------------------------------------------------------*/
/* 4-D: DEFINE CUSTOMS ENTERED VALUE FOR ADMINISTRATIVE REVIEWS            */
/*-------------------------------------------------------------------------*/

%US6_ENTVALUE 

/*ep*/

/***************************************************************************/
/* PART 5: CONVERT COMPARISON MARKET NET PRICES AND ADJUSTMENTS INTO CM    */
/*         CURRENCY, IF REQUIRED                                           */
/*                                                                         */
/*     If CM sales data has more than one currency, the HMDATA macro       */
/*     immediately following will create another macro called,             */
/*     MULTIPLE_CURR, which will get executed in the US10_P2PCALC below    */
/*     in Part 8. Accordingly, you will not see anything in your log       */
/*     about the calculation of CM net price, etc., at this point.         */
/***************************************************************************/

%MACRO HMDATA;
    %IF %UPCASE(&NV_TYPE) = P2P %THEN
    %DO;
        %MACRO MULTIPLE_CURR;
            %IF %UPCASE(&HM_MULTI_CUR) = YES %THEN
            %DO;

/*----------------------------------------------------------------------*/
/* 5-A: If the comparison market database is reported in more than one  */
/*      currency, the CM net price needs to be recalculated in CM       */
/*      currency using an exchange rate based on the sale date of the   */
/*      matching U.S. sale. CM sales have been weight averaged in the   */
/*      CM Program so the CM net price will be calculated on a model    */
/*      (HMCONNUM) basis.                                               */
/*                                                                      */
/*      Edit the formula for CM net price (HMNETPRI) and, if required,  */
/*      inventory carrying costs (HMICC), indirect selling expenses     */
/*      (HMISELL), commissions (HMCOMM), and surrogate commissions      */
/*      (HMINDCOM). Make sure HMNETPRI, HMICC, HMISELL, HMCOMM, and     */
/*      HMINDCOM are calculated all in CM currency.                     */
/*----------------------------------------------------------------------*/
 
                HMNETPRI = <HMGUP + HMGUPADJ - HMDISREB - HMMOVE
                         -  HMCRED - HMDSELL - HMCOMM - HMPACK>;
                <HMICC = ???;>     /* deactivate or delete if */
                                   /* editing not required.   */
                <HMISELL = ???;>   /* deactivate or delete if */
                                   /* editing not required.   */
                <HMCOMM = ???;>    /* deactivate or delete if */
                                   /* editing not required.   */
                <HMINDCOM = ???;>  /* deactivate or delete if */
                                   /* editing not required.   */
            %END;
        %MEND MULTIPLE_CURR;
    %END;
%MEND HMDATA;

%HMDATA

/*ep*/

/***************************************************************************/
/* PART 6: CREATE CONCORDANCE OF PRICE-TO-PRICE MATCHING INSTRUCTIONS      */
/*                                                                         */
/*     U.S. models not finding a suitable match will be compared to        */
/*     constructed value.                                                  */
/***************************************************************************/

%US7_CONCORDANCE

/*ep*/

/***************************************************************************/
/*  PART 7: LEVEL OF TRADE ADJUSTMENT, IF REQUIRED                         */
/*                                                                         */
/*     If you typed %LET LOT_ADJUST = HM above in Sect. 1-F, information   */
/*     calculated in the CM program will be merged with the U.S. sales by  */
/*     the US8_LOTADJ macro.                                               */
/*                                                                         */
/*     If you typed %LET LOT_ADJUST = NO, then the US8_LOTADJ macro will   */
/*     set LOTADJ = 0, resulting in no adjustment for LOT.                 */
/*                                                                         */
/*     If you typed %LET LOT_ADJUST = INPUT because you will be making an  */
/*     LOT adjustment using information other than that from the CM sales, */
/*     edit the sample language below in Sect. 7-A-i. There should be an   */
/*     adjustment ratio (LOTADJ) for each combination of U.S. and CM LOT.  */
/*     The amount of the LOT adjustment (LOTADJMT) later calculated will   */
/*     be equal to HMNETPRI * LOTADJ, and then added to HMNETPRI in        */
/*     calculating FUPDOL.                                                 */
/***************************************************************************/

%MACRO LOT_ADJUSTMENT;
    %IF &CALC_P2P = YES %THEN
    %DO;
        %US8_LOTADJ 

        %IF %UPCASE(&LOT_ADJUST) = INPUT %THEN
        %DO;
            DATA ISMODELS; 
                SET ISMODELS;
                LOTHDATA = 'YES'; 

/*------------------------------------------------------------------*/
/*     7-A-i Create a line for each combination of U.S. and CM LOT. */
/*------------------------------------------------------------------*/

                /*
                IF USLOT = <??> AND HMLOT = <??> THEN LOTADJ = <??>;
                */
            RUN;
        %END;

/*---------------------------------------------------------------------*/
/*     7-A-ii EDIT LOT ADJUSTMENT AND CEP OFFSET, IF REQUIRED.         */
/*                                                                     */
/*     The default programming below sets any CEP Offset to zero when  */
/*     there is a valid LOT adjustment calculated (i.e., when there    */
/*     there is a difference in LOT and there is LOT adjustment info.) */
/*                                                                     */
/*     The macro P2P_ADJUSTMT_LOTADJ is created below but not used     */
/*     until the US10_P2PCALC macro gets executed in Part 8.           */
/*     Accordingly, you will not see anything in your log about the    */
/*     calculation of LOTADJMT at this point.                          */
/*---------------------------------------------------------------------*/

          %MACRO P2P_ADJUSTMT_LOTADJ;
               %IF %UPCASE(&LOT_ADJUST) NE NO %THEN
               %DO;
                    IF LOTHDATA = 'YES' AND LOTDIFF GT 0 THEN
                    DO;
                    LOTADJMT = HMNETPRI * LOTADJ;
                         USECEPOFST = 'NO';
                    END;
               %END;
          %MEND P2P_ADJUSTMT_LOTADJ;
     %END;
%MEND LOT_ADJUSTMENT;

%LOT_ADJUSTMENT

/*ep*/

/***************************************************************************/
/* PART 8: COMBINE U.S. SALES WITH CM MATCHES, CALCULATE TRANSACTION LOT   */
/*         -SPECIFIC LOT ADJUSTMENTS, CEP AND COMMISSION OFFSETS           */
/*                                                                         */
/*     Convert CM commissions and information required for offsets into    */
/*     U.S. dollars. Calculate the LOT adjustment, commission and CEP      */
/*     offsets.                                                            */
/***************************************************************************/

%US10_LOT_ADJUST_OFFSETS 

/*ep*/

/***************************************************************************/
/* PART 9: CALCULATE CEP AND COMMISSION OFFSETS FOR CONSTRUCTED VALUE      */
/* COMPARISONS                                                             */
/***************************************************************************/

%MACRO CV_CALCS;
    %IF &CALC_CV = YES %THEN
    %DO;

/*-------------------------------------------------------------------------*/
/*     9-A CV SELLING EXPENSE RATES WHEN MAKING STRAIGHT COMPARISONS OF    */
/*          U.S. SALES TO CV, OR WHEN THERE IS NO SUITABLE CM DATA ON      */
/*          SELLING EXPENSES AND PROFIT.                                   */
/*                                                                         */
/*     Supply rates for CV selling expenses and profit in decimal format.  */
/*     The rates will be multiplied by total cost to calculate per-unit    */
/*     expense amounts.                                                    */
/*-------------------------------------------------------------------------*/

        %IF %UPCASE(&NV_TYPE) = CV OR %UPCASE(&CVSELL_TYPE) = OTHER %THEN
        %DO;
            DATA NVCV;
                SET USSALES;

                DSELCVR  = <???>; /* direct selling expenses, as a      */
                                  /* ratio of cost                      */
                CREDCVR = <???>;  /* credit expenses, as a ratio of     */
                                  /* price                              */
                ISELCVR = <???>;  /* indirect selling, excluding        */
                                  /* inventory carrying costs, as a     */
                                  /* ratio of cost                      */
                COMMCVR = <???>;  /* commissions, as a ratio of cost    */
                ICOMCVR = <???>;  /* surrogate commission equal either  */
                                  /* to zero (when COMMCV greater than  */
                                  /* zero) or to the sum of indirect    */
                                  /* selling and inventory carry costs, */
                                  /* as a ratio of cost                 */
                INVCVR = <???>;   /* inventory carrying costs, as a     */
                                  /* ratio of cost                      */
                PRATECV = <???>;  /* profit, as a ratio of cost         */
                CVSELLPR = 'YES'; /* do not edit.                       */

                %NVMATCH          /* do not edit.                       */
            RUN;
        %END;

/*-------------------------------------------------------------------------*/
/*     9-B CV SELLING EXPENSE RATES CALCULATED IN THE CM PROGRAM           */
/*                                                                         */
/*     When there is suitable information on CV selling expense and profit */
/*     rates calculated in the CM program, the US11_CVSELL_OFFSETS macro   */
/*     will merge the information with U.S. sales to be compared to CV.    */
/*-------------------------------------------------------------------------*/

        %US11_CVSELL_OFFSETS
    %END;
%MEND CV_CALCS;

%CV_CALCS

/*ep*/

/***************************************************************************/
/* PART 10: COMBINE PRICE-2-PRICE COMPARISONS WITH SALES COMPARED TO CV    */
/***************************************************************************/

%US12_COMBINE_P2P_CV  

/*ep*/

/***************************************************************************/
/* PART 11: COHEN'S-D TEST                                                 */
/*                                                                         */
/*    The Cohen's-d Test is run three ways:  1) by purchaser, 2) by region */
/*    and 3) by time period. U.S. sales are compared to sales to other     */
/*    purchasers/regions/periods to see if they pass the test. At the end  */
/*    of the test, the percentage of U.S. sales found to pass the test is  */
/*    recorded.                                                            */
/*                                                                         */
/*    In the remaining sections of this program, the Cash Deposit Rate     */
/*    will be calculated three ways:  1) Standard Method (average-to       */
/*    -average comparisons on all sales, offsetting positive comparison    */
/*    results with negatives), 2) A-to-T Alternative Method (average-to-   */
/*    transaction comparisons on all sales, no offsetting of positive      */
/*    comparison results with negative ones), and 3) Mixed Alternative     */
/*    Method (A-to-A with offsets for sales that do not pass the           */
/*    Cohen's-d Test and A-to-T with no offsets on sales that do pass.     */
/*                                                                         */
/*    If no sale passes the Cohen's-d Test, the Mixed Alternative Method   */
/*    would be the same as the Standard Method. In this case, the Mixed    */
/*    Alternative Method will not be calculated. Similarly, the Mixed      */
/*    Alternative Method will also not be calculated when all sales        */
/*    pass the Cohen's-d Test since the it would be the same as the        */
/*    A-to-T Alternative Method.                                           */
/***************************************************************************/

%US13_COHENS_D_TEST

/*ep*/

/***************************************************************************/
/* PART 12: WEIGHT AVERAGE U.S. SALES                                      */
/*                                                                         */
/*     Weight-average U.S. prices and adjustments and merge averaged data  */
/*     back onto the single-transaction database. The averaged variables   */
/*     will have the same names as the un-averaged ones, but with a        */
/*     suffix added. For the Standard Method, the suffix will be "_MEAN."  */
/*     For the Mixed Alternative Method, the suffix will be "_MIXED."  For */
/*     example, the averaged versions of USNETPRI will be USNETPRI_MEAN    */
/*     for the Standard Method and USNETPRI_MIXED for the Mixed            */
/*     Alternative Method. Both the single-transaction and weight-averaged */
/*     values will be in the data. In the US15_RESULTS macro below, the    */
/*     appropriate selection of the weight-averaged v single-transaction   */
/*     values will occur.                                                  */
/***************************************************************************/

%US14_WT_AVG_DATA

/*ep*/

/***************************************************************************/
/* DATA COUNT FOR LOG REPORTING PURPOSE                            */
/***************************************************************************/

%CMAC2_COUNTER (DATASET = USSALES, MVAR = WT_AVG_USSALES);

/*ep*/

/***************************************************************************/
/* PART 13: CALCULATE FUPDOL, NV, PUDD, ETC. USING THE STANDARD METHOD,    */
/*          THE A-to-T ALTERNATIVE METHOD AND, WHEN REQUIRED, THE MIXED    */
/*          ALTERNATIVE METHOD                                             */
/*                                                                         */
/*     STANDARD METHOD:                                                    */
/*          - Use weight-averaged U.S. prices, offsetting positive         */
/*            comparison results with negative ones, for all sales.        */
/*     MIXED ALTERNATIVE METHOD:                                           */
/*          - A rate calculated by using single-transaction prices without */
/*            offsetting on sales that pass the Cohen's-d Test, and weight-*/
/*            averaged U.S. prices with offsetting on sales not passing.   */
/*     A-to-T ALTERNATIVE METHOD                                           */
/*          - Use single-transaction U.S. prices without offsetting        */
/*            positive comparison results with negative ones on all sales. */
/*                                                                         */
/*   Calculate FUPDOL by converting CM net price (including the DIFMER     */
/*   and LOT adjustments) into U.S. dollars and adding U.S. packing.       */
/*   Calculate normal value (NV) from FUPDOL by doing COS adjustments      */
/*   and offsets. Compare U.S. price to NV to calculate the transaction-   */
/*   specific comparison results. (Note, no offsetting of positive         */
/*   comparison results with negatives is done at this point.)  The        */
/*   resulting databases are put in the COMPANY library as the following:  */
/*                                                                         */
/*          - &RESPONDENT._&SEGMENT._&STAGE_AVGMARG for the Standard       */
/*                    Method on the full U.S. sales database               */
/*          - &RESPONDENT._&SEGMENT._&STAGE._AVGMIXED for the portion of   */
/*                    sales being calculated with the Standard Method as   */
/*                    part of the Mixed Alternative Method.                */
/*          - &RESPONDENT._&SEGMENT._&STAGE._TRNMIXED for the portion of   */
/*                    sales being calculated with the A-to-T Alternative   */
/*                    Method as part of the Mixed Alternative Method.      */
/*          - &RESPONDENT._&SEGMENT._&STAGE._TRANMARG for the A-to-T       */
/*                    Alternative Method on the full U.S. sales database.  */
/*                                                                         */
/*   Variables with "&SUFFIX" added to their names in the programming will */
/*   have two or three values in the database: 1) the non-averaged/single- */
/*   transaction value when &SUFFIX is a blank space (e.g., USPACK&SUFFIX  */
/*   becomes USPACK), 2) the weight-averaged value when &SUFFIX=_MEAN      */
/*   (e.g., USPACK&SUFFIX becomes USPACK_MEAN) for the Standard Method,    */
/*   and sometimes 3) the weight-averaged value when &SUFFIX=_MIXED (e.g., */
/*   USPACK&SUFFIX becomes USPACK_MIXED) for the Mixed Alternative         */
/*   Method. The selection of averaged v non-averaged values is done       */
/*   automatically.                                                        */
/*                                                                         */
/*   The calculation of the foreign unit price in dollars (i.e., FUPDOL)   */
/*   is below. Typically, FUPDOL does not require editing except in        */
/*   unusual circumstances such as the reporting of CM sales information   */
/*   in a currency other than that used to report costs. If you need to    */
/*   edit the calculation of FUPDOL below, be sure to keep the "&SUFFIX"   */
/*   endings for USPACK&SUFFIX.                                            */
/***************************************************************************/

/*----------------------------------------------------------------------*/
/* 13-A Calculate FUPDOL for Price-to-Price Comparisons                 */
/*----------------------------------------------------------------------*/

%MACRO FUPDOL_P2P;  
    FUPDOL = ((HMNETPRI - DIFMER + LOTADJMT) * &XRATE1) + USPACK&SUFFIX;
%MEND FUPDOL_P2P;

/*----------------------------------------------------------------------*/
/* 13-B Calculate FUPDOL for Comparisons to Constructed Value           */
/*----------------------------------------------------------------------*/

%MACRO FUPDOL_CV; 
    FUPDOL = ((TOTCV - DSELCV - CREDCV - COMMCV) * &XRATE1) + USPACK&SUFFIX;
%MEND FUPDOL_CV;

/*----------------------------------------------------------------------*/
/* 13-C Execute comparison Result Calculations                          */
/*----------------------------------------------------------------------*/

%US15_RESULTS

/*ep*/

/***************************************************************************/
/* PART 14: CASH DEPOSIT RATES                                             */
/*                                                                         */
/*   Calculate Cash Deposit Rates based upon the Standard, Mixed           */
/*   Alternative (when  required) and A-to-T Alternative Methods.          */
/*                                                                         */
/*   For the Standard Method, calculated amounts from the database         */
/*   &RESPONDENT._&SEGMENT._&STAGE_AVGMARG will be used. Positive          */
/*   comparison results will be offset by negatives on all sales.          */
/*                                                                         */
/*   The Mixed Alternative Method will be a combination calculation.       */
/*   Sales that passed the Cohen's-d Test will be calculated using the     */
/*   &RESPONDENT._&SEGMENT._&STAGE._TRNMIXED database. No offsetting of    */
/*   positive comparison results with negatives will be done on these      */
/*   sales. Sales that did not pass the Test will be calculated using      */
/*   the &RESPONDENT._&SEGMENT._&STAGE_AVGMIXED database in which these    */
/*   sales were weight averaged separately from those that did pass the    */
/*   test. Positive comparison results will be offset by negatives on      */
/*   these sales.                                                          */
/*                                                                         */
/*   Cash Deposit Rate using the A-to-T Alternative Method for all sales   */
/*   will be calculated using the &RESPONDENT._&SEGMENT._&STAGE._TRANMARG  */
/*   database. No database. No offsetting of positive comparison results   */
/*   with negatives.                                                       */
/***************************************************************************/

%US16_CALC_CASH_DEPOSIT

/*ep*/

/***************************************************************************/
/* PART 15: MEANINGFUL DIFFERENCE TEST                                     */
/*                                                                         */
/*     Compare the cash deposit rate based on the Standard Method to rates */
/*     based on the Mixed Alternative (when required) and the A-to-T       */
/*     Alternative Methods to see if there is a Meaningful Difference.     */
/*     A Meaningful Difference occurs if:                                  */
/*                                                                         */
/*     - the Standard rate is de minimis/zero and the other is not, or     */
/*     - the Standard rate is above de minimis and the other is 25%        */
/*       greater than the Standard rate.                                   */
/***************************************************************************/

%US17_MEANINGFUL_DIFF_TEST

/*ep*/

/***************************************************************************/
/* PART 16: ASSESSMENT RATES (ADMINISTRATIVE REVIEWS ONLY)                 */
/*                                                                         */
/*     Assessment calculations will be done for each Method with a Cash    */
/*     Deposit Rate above de minimis. U.S. sales data will be weight-      */
/*     averaged again by importer before calculating the assessment rates. */
/*     The databases containing the importer transaction-specific          */
/*     comparison results (before offsetting, when required) for the       */
/*     various methods are as follows:                                     */
/*                                                                         */
/*      IMPSTND:  Assessment, Standard Method                              */
/*      IMPCSTN:  Assessment, sales not passing Cohens-d for Mixed         */
/*                Alternative Method                                       */
/*      IMPCTRN:  Assessment, sales passing Cohens-d for Mixed Alternative */
/*                Method                                                   */
/*      IMPTRAN:  Assessment, A-to-T Alternative Method                    */
/***************************************************************************/

%US18_ASSESSMENT 

/*ep*/

/***************************************************************************/
/* PART 17: REPRINT THE FINAL CASH DEPOSIT RATE                            */
/***************************************************************************/

%US19_FINAL_CASH_DEPOSIT

/*ep*/

/***************************************************************************/
/* PART 18: DELETE ALL WORK FILES IN THE SAS MEMORY BUFFER WHEN REQUESTED  */
/***************************************************************************/

%G18_DEL_ALL_WORK_FILES

/*ep*/

/***************************************************************************/
/* PART 19: CALCULATE RUN TIME FOR THIS PROGRAM WHEN REQUESTED             */
/***************************************************************************/

%G19_PROGRAM_RUNTIME

/*ep*/

/***************************************************************************/
/* PART 20: REVIEW LOG AND REPORT SUMMARY AT THE END OF THE LOG FOR:       */
/*          (A) GENERAL SAS ALERTS SUCH AS ERRORS, WARNINGS, MISSING, ETC. */
/*          (B) PROGRAM SPECIFIC ALERTS THAT WE NEED TO LOOK OUT FOR.      */
/***************************************************************************/

%CMAC4_SCAN_LOG (ME_OR_NME = MEMARG);

/*ep*/
