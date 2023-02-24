;+
;*****************************************************************************************
;
;  FUNCTION :   is_a_3_vector.pro
;  PURPOSE  :   This routine tests an input to determine if it is a single or array of
;                 3-vectors.  The routine will return TRUE if the input is either a
;                 [3]- or [N,3]-element array, otherwise it will return FALSE.  The
;                 input must be numeric as well.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               is_a_number.pro
;               format_2d_vec.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               VV      :  Scalar or array to test
;
;  EXAMPLES:    
;               [calling sequence]
;               test = is_a_3_vector(vv [,V_OUT=v_out] [,/NOMSSG])
;
;               vv   = FINDGEN(10,3)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     1
;
;               vv   = FINDGEN(10,4)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     0
;
;               vv   = FINDGEN(10,2)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     0
;
;               vv   = FINDGEN(3)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     1
;
;               vv   = FINDGEN(4)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     0
;
;               vv   = FINDGEN(9)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     0
;
;               vv   = REPLICATE('',10,3)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     0
;
;               vv   = REPLICATE({X:15,Y:FINDGEN(3)},3)
;               PRINT,';;  ', is_a_3_vector(vv,/NOMSSG)
;               ;;     0
;
;  KEYWORDS:    
;               V_OUT   :  Set to a named variable to return the re-formatted VV input
;                            as a two dimensional [N,3]-element array of 3-vectors
;               NOMSSG  :  If set, routine will not print out warning message
;                            [Default = FALSE]
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               1)  See also:  valid_num.pro, is_a_number.pro, format_2d_vec.pro
;               2)  Input must be numeric type (i.e., is_a_number.pro returns TRUE)
;
;  REFERENCES:  
;               NA
;
;   CREATED:  11/24/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/24/2015   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION is_a_3_vector,vv,V_OUT=v_out,NOMSSG=nomssg

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number, format_2d_vec
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
test_vec       = 1b
;;  Dummy error messages
no_inpt_msg    = 'User must supply at least one 3-vector'
badvfor_msg    = 'Incorrect input format:  VV must be a [3]- or [N,3]-element [numeric] array of 3-vectors'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 1) OR (is_a_number(vv,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  IF ~KEYWORD_SET(nomssg) THEN MESSAGE,no_inpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check vector formats
v1_2d          = format_2d_vec(vv)    ;;  If a vector, routine will force to [N,3]-elements, even if N = 1
test           = ((N_ELEMENTS(v1_2d) LT 3) OR ((N_ELEMENTS(v1_2d) MOD 3) NE 0))
IF (test[0]) THEN BEGIN
  IF ~KEYWORD_SET(nomssg) THEN MESSAGE,badvfor_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Define output result
v_out          = v1_2d
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,test_vec[0]
END