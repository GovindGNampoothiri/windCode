;+
;*****************************************************************************************
;
;  FUNCTION :   fill_range.pro
;  PURPOSE  :   This is a general purpose routine that creates an array from an input
;                 start (ST) and end (EN) value with a user defined interval (DIND) or
;                 number of elements (UNIFORM).
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               is_a_number.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               ST       :  Scalar [numeric] defining the start value of the output array
;               EN       :  Scalar [numeric] defining the end value of the output array
;
;  EXAMPLES:    
;               [calling sequence]
;               array = fill_range(st, en [,DIND=dind] [,UNIFORM=uniform])
;
;               ;;  Output array maintains input data type
;               s              = 0
;               e              = 25
;               ind            = fill_range(s,e)
;               HELP, ind, MIN(ind,/NAN), MAX(ind,/NAN), OUTPUT=out
;               FOR j=0L, N_ELEMENTS(out) - 1L DO PRINT,';; ',out[j]
;               ;; IND             INT       = Array[26]
;               ;; <Expression>    INT       =        0
;               ;; <Expression>    INT       =       25
;
;               ;;  Output array maintains input data type
;               s              = 0d0
;               e              = 25d3
;               ind            = fill_range(s,e)
;               HELP, ind, MIN(ind,/NAN), MAX(ind,/NAN), OUTPUT=out
;               FOR j=0L, N_ELEMENTS(out) - 1L DO PRINT,';; ',out[j]
;               ;; IND             DOUBLE    = Array[25001]
;               ;; <Expression>    DOUBLE    =        0.0000000
;               ;; <Expression>    DOUBLE    =        25000.000
;
;               ;;  Example of DIND keyword usage
;               s              = 0
;               e              = 25
;               di             = 5
;               ind            = fill_range(s,e,DIND=di)
;               HELP, ind, MIN(ind,/NAN), MAX(ind,/NAN), OUTPUT=out
;               FOR j=0L, N_ELEMENTS(out) - 1L DO PRINT,';; ',out[j]
;               ;; IND             INT       = Array[6]
;               ;; <Expression>    INT       =        0
;               ;; <Expression>    INT       =       25
;
;               ;;  Example of UNIFORM keyword usage (output 5-element array)
;               s              = 0
;               e              = 25
;               uni            = 5
;               ind            = fill_range(s,e,UNIFORM=uni)
;               HELP, ind, MIN(ind,/NAN), MAX(ind,/NAN), OUTPUT=out
;               FOR j=0L, N_ELEMENTS(out) - 1L DO PRINT,';; ',out[j]
;               ;; IND             INT       = Array[5]
;               ;; <Expression>    INT       =        0
;               ;; <Expression>    INT       =       25
;
;               ;;  UNIFORM keyword takes precidence over DIND keyword
;               s              = 0d0
;               e              = 25d0
;               uni            = 5
;               di             = 5
;               ind            = fill_range(s,e,DIND=di,UNIFORM=uni)
;               HELP, ind, MIN(ind,/NAN), MAX(ind,/NAN), uni, di, OUTPUT=out
;               FOR j=0L, N_ELEMENTS(out) - 1L DO PRINT,';; ',out[j]
;               ;; IND             DOUBLE    = Array[5]
;               ;; <Expression>    DOUBLE    =        0.0000000
;               ;; <Expression>    DOUBLE    =        25.000000
;               ;; UNI             LONG      =            5
;               ;; DI              DOUBLE    =        6.2500000
;
;               ;;  Example of bad UNIFORM keyword usage
;               s              = 0d0
;               e              = 25d0
;               uni            = 5d30
;               ind            = fill_range(s,e,UNIFORM=uni)
;               % FILL_RANGE: # of array elements setting (i.e., UNIFORM) is too large!
;               % Program caused arithmetic error: Floating illegal operand
;               HELP, ind, MIN(ind,/NAN), MAX(ind,/NAN), uni, OUTPUT=out
;               FOR j=0L, N_ELEMENTS(out) - 1L DO PRINT,';; ',out[j]
;               ;; IND             BYTE      =    0
;               ;; <Expression>    BYTE      =    0
;               ;; <Expression>    BYTE      =    0
;               ;; UNI             DOUBLE    =    5.0000000e+30
;
;  KEYWORDS:    
;               DIND     :  Scalar [numeric] defining the difference between adjacent
;                             values in the output array
;                             [Default = 1]
;               UNIFORM  :  Scalar [numeric] defining the number of elements for the
;                             output array (e.g., if ST and EN are not integers).
;                             If set, then changes DIND to the following:
;                               N    = UNIFORM
;                               DIND = (EN - ST)/(N - 1)
;                             [Default = 1 + (EN - ST)/DIND]
;
;   CHANGED:  1)  Finished writing routine
;                                                                   [06/07/2016   v1.0.0]
;
;   NOTES:      
;               1)  If the UNIFORM is properly set, it will alter the DIND value to
;                     create an array with exactly UNIFORM elements.  This can result
;                     in degenerate element values for integer-based input types, so
;                     be careful.
;
;  REFERENCES:  
;               
;
;   CREATED:  06/07/2016
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/07/2016   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION fill_range,st,en,DIND=dind,UNIFORM=uniform

;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Define allowed number types
all_num_type   = [1,2,3,4,5,12,13,14,15]
nt_by_size     = [1,2,12,3,13,14,15,4,5]
;;  Dummy error messages
noinpt_msg     = 'User must supply two numeric inputs...'
badinp_msg     = 'Bad input:  Inputs must satisfy (EN GE ST) and both must be real numeric inputs'
badtyp_msg     = 'Bad input type:  ST and EN must both be real numeric inputs'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() NE 2) OR (is_a_number(st,/NOMSSG) EQ 0) OR $
                 (is_a_number(en,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  ;;  No input
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Make sure EN ??? ST and not complex
s              = st[0]
e              = en[0]
s_t            = SIZE(s[0],/TYPE)
e_t            = SIZE(e[0],/TYPE)
test           = (s[0] GT e[0]) AND (TOTAL(s_t[0] EQ all_num_type) GE 1) AND $
                                    (TOTAL(e_t[0] EQ all_num_type) GE 1)
IF (test[0]) THEN BEGIN
  ;;  No input
  MESSAGE,badinp_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Make sure RANGE spans more than one element
test           = (s[0] EQ e[0])
IF (test[0]) THEN RETURN,s[0]        ;;  Just return first element of array
del            = DOUBLE(e[0] - s[0]) ;;  Define difference
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check DIND
test_di        = ((N_ELEMENTS(dind) GT 0) AND is_a_number(dind,/NOMSSG))
IF (test_di[0]) THEN test_di = (DOUBLE(dind[0]) LE del[0])
IF (test_di[0]) THEN di = DOUBLE(dind[0]) ELSE di = 1d0 < del[0]
;;  Check UNIFORM
test_un        = ((N_ELEMENTS(uniform) GT 0) AND is_a_number(uniform,/NOMSSG))
IF (test_un[0]) THEN test_un = (uniform[0] GT 0)
IF (test_un[0]) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  UNIFORM is set --> change DIND
  ;;--------------------------------------------------------------------------------------
  IF (LONG(uniform[0]) LE 0) THEN BEGIN
    ;;  UNIFORM > Max LONG integer value (i.e., 2,147,483,647)
    IF (ULONG(uniform[0]) LE 0) THEN BEGIN
      ;;  UNIFORM > Max ULONG integer value (i.e., 4,294,967,296)
      IF (LONG64(uniform[0]) LE 0) THEN BEGIN
        ;;  UNIFORM > Max LONG64 integer value (i.e., 9,223,372,036,854,775,807)
        IF (ULONG64(uniform[0]) LE 0) THEN BEGIN
          ;;  UNIFORM > Max LONG64 integer value (i.e., 18,446,744,073,709,551,615)
          ;;  Array size is too large!!!
          errmsg = '# of array elements setting (i.e., UNIFORM) is too large!'
          MESSAGE,errmsg[0],/INFORMATIONAL,/CONTINUE
          RETURN,0b
        ENDIF ELSE nn = ULONG64(uniform[0])
      ENDIF ELSE nn = LONG64(uniform[0])
    ENDIF ELSE nn = ULONG(uniform[0])
  ENDIF ELSE nn = LONG(uniform[0])
ENDIF ELSE BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  UNIFORM not set --> change N
  ;;--------------------------------------------------------------------------------------
  test_str = {T0:  LONG(del[0]/di[0]),T1:  ULONG(del[0]/di[0]),$
              T2:LONG64(del[0]/di[0]),T3:ULONG64(del[0]/di[0])}
  tests    = 0b
  FOR j=0L, N_TAGS(test_str) - 1L DO tests = [tests,(test_str.(j) GE 1)]
  tests    = tests[1:*]
  good  = WHERE(tests GE 1,gd)
  CASE good[0] OF
    -1   : BEGIN
      ;;  Array size too large!
      errmsg = '# of array elements setting (i.e., DIND too small) is too large!'
      MESSAGE,errmsg[0],/INFORMATIONAL,/CONTINUE
      RETURN,0b
    END
    ELSE : nn = 1 + test_str.(good[0])
  ENDCASE
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Determine factors and functions
;;----------------------------------------------------------------------------------------
;;  Redefine DIND
di             = del[0]/(nn[0] - 1d0)
temp           = DBLARR(nn[0])
szt            = SIZE([s[0],e[0]],/TYPE)
CASE szt[0] OF
  1    : output = BYTE(DINDGEN(nn[0])*di[0] + s[0])
  2    : output = FIX(DINDGEN(nn[0])*di[0] + s[0])
  3    : output = LONG(DINDGEN(nn[0])*di[0] + s[0])
  4    : output = FLOAT(DINDGEN(nn[0])*di[0] + s[0])
  5    : output = DINDGEN(nn[0])*di[0] + s[0]
  12   : output = UINT(DINDGEN(nn[0])*di[0] + s[0])
  13   : output = ULONG(DINDGEN(nn[0])*di[0] + s[0])
  14   : output = LONG64(DINDGEN(nn[0])*di[0] + s[0])
  15   : output = ULONG64(DINDGEN(nn[0])*di[0] + s[0])
  ELSE : BEGIN
    MESSAGE,badtyp_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN,0b
  END
ENDCASE
;;  Alter input keywords if they changed
IF (test_di[0]) THEN dind    = di[0]
IF (test_un[0]) THEN uniform = nn[0]
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,output
END


