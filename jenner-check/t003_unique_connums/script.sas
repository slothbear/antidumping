/* jenner-check bundle: UNIQUE_CONNUMS from nme-margin-calculation.sas
   (slothbear/antidumping)
   Source: nme-margin-calculation.sas, "CONNUM UNIQUENESS TEST" -- checks
   that each control number (CONNUM) in a sales dataset maps to exactly one
   combination of physical characteristics, which is the model-matching
   backbone the whole antidumping margin calculation depends on.
   Reproduced verbatim; only the call site and its mock U.S. sales dataset
   are new. */

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

/* Repo's real call-site setup (see nme-margin-calculation.sas, "PART 2:
   GET U.S., FOP, AND SV DATA"): CONNUMS turns the test on/off, USCONNUM
   names the control-number variable, USPHVARS lists the physical
   characteristic variables that make up the model match. */
%LET CONNUMS = YES;
%LET USCONNUM = CONNUM;
%LET USPHVARS = GRADE FINISH;

/* Stand-in for COMPANY.&USDATA: a small U.S. sales extract where one
   CONNUM (C002) is intentionally reported with two different GRADE/FINISH
   combinations, so the uniqueness test has something real to catch. */
DATA USSALES;
    LENGTH CONNUM $4 GRADE $10 FINISH $10;
    INPUT CONNUM $ GRADE $ FINISH $;
    DATALINES;
C001 STANDARD POLISHED
C001 STANDARD POLISHED
C002 STANDARD POLISHED
C002 PREMIUM  POLISHED
C003 PREMIUM  MATTE
C003 PREMIUM  MATTE
;
RUN;

%UNIQUE_CONNUMS (USSALES);
