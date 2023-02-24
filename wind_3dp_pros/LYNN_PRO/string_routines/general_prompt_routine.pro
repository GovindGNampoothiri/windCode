;+
;*****************************************************************************************
;
;  FUNCTION :   general_prompt_routine.pro
;  PURPOSE  :   Prompts user for information related to STR_OUT or informs user with
;                 information defined by PRO_OUT or ERRMSG.  The routine returns
;                 the output from the prompt if the user set STR_OUT.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               get_zeros_mins_maxs_type.pro
;               is_a_number.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TEST_IN    :  Scalar [see FORM_OUT] that is used to initialize the
;                               prompt return variable
;                               [Default = {not set} ]
;
;  EXAMPLES:    
;               [calling sequence]
;               val__out = general_prompt_routine([test_in] [,STR_OUT=str_out]         $
;                                                 [,PRO_OUT=pro_out] [,ERRMSG=errmsg]  $
;                                                 [,FORM_OUT=form_out]                 )
;
;  KEYWORDS:    
;               STR_OUT    :  Scalar [string] that tells the user what to enter at
;                               prompt
;               PRO_OUT    :  Scalar(or array) [string] containing instructions for
;                               input
;               ERRMSG     :  Scalar(or array) [string] containing error messages the
;                               user wishes to print to screen
;               FORM_OUT   :  Scalar [integer/long] defining the type code of the prompt
;                               input and output.  Let us define the following:
;                                    FPN = floating-point #
;                                    SP  = single-precision
;                                    DP  = double-precision
;                                    UI  = unsigned integer
;                                    SI  = signed integer
;                               Possible values include:
;                                  1  :  BYTE     [8-bit UI]
;                                  2  :  FIX      [16-bit SI]
;                                  3  :  LONG     [32-bit SI]
;                                  4  :  FLOAT    [32-bit, SP, FPN]
;                                  5  :  DOUBLE   [64-bit, DP, FPN]
;                                  6  :  COMPLEX  [32-bit, SP, FPN for Real and Imaginary]
;                                  7  :  STRING   [0 to 2147483647 characters]
;                                  9  :  DCOMPLEX [64-bit, DP, FPN for Real and Imaginary]
;                                 12  :  UINT     [16-bit UI]
;                                 13  :  ULONG    [32-bit UI]
;                                 14  :  LONG64   [64-bit SI]
;                                 15  :  ULONG64  [64-bit UI]
;                               [Default = 7]
;
;   CHANGED:  1)  Finished writing routine and moved to ~/wind_3dp_pro/LYNN_PRO
;                                                                   [04/29/2015   v1.0.0]
;             2)  Fixed a bug in type determining case statement and updated Man. page
;                                                                   [09/08/2016   v1.1.0]
;             3)  Fixed a bug in type function and now calls get_zeros_mins_maxs_type.pro
;                                                                   [05/18/2017   v1.2.0]
;
;   NOTES:      
;               1)  See IDL documentation for SIZE.PRO for possible type codes
;               2)  If FORM_OUT = 7, then the routine will force a lower-case output
;
;  REFERENCES:  
;               NA
;
;   CREATED:  04/28/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/18/2017   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION general_prompt_routine,test_in,STR_OUT=str_out,PRO_OUT=pro_out,ERRMSG=errmsg,$
                                FORM_OUT=form_out

;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Define separators for prompts
str_sta        = "=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>"
str_end        = "<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<="
;;  Define separators for error messages
str_ers        = "&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>&>"
str_ere        = "<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&<&"
;;  Define separators for instructions
str_pro        = "-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|"
;;  Define allowed types
all_type_str   = get_zeros_mins_maxs_type()     ;;  Get all type info for system
allowed_types  = all_type_str.TYPES             ;;  Array of allowed type code values
all_ok_zero    = all_type_str.ZEROS             ;;  Structure containing type-dependent zeros
all_ok_func    = all_type_str.FUNCS             ;;  Structure containing type-dependent conversion function names
;;;  Define allowed type codes
;allowed_types  = [ 1, 2, 3, 4, 5, 6, 7, 9,12,13,14,15]
;;  Define default prompt output
def_prompt_pre = "Please enter the desired value [with type code ="
def_prompt_suf = "]:  "
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test_key       = ~KEYWORD_SET(str_out) AND ~KEYWORD_SET(pro_out) AND $
                 ~KEYWORD_SET(errmsg)
IF (N_PARAMS() NE 1) THEN BEGIN
  ;;  Nothing is set --> return nothing
  IF (test_key[0]) THEN RETURN,0b
ENDIF ELSE BEGIN
  ;;  User set input --> use to define output format
  test           = (N_ELEMENTS(test_in) GT 0)
  form_out       = SIZE(test_in,/TYPE)
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(form_out) EQ 0) OR (is_a_number(form_out,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  ;;  Use default = string
  type_out = 7
ENDIF ELSE BEGIN
  f0       = FIX(form_out[0])
  test     = (TOTAL(f0[0] EQ allowed_types) GT 0)
  IF (test[0]) THEN type_out = f0[0] ELSE type_out = 7
ENDELSE
;;  Define default prompt if necessary
type_out_str   = STRTRIM(STRING(type_out[0],FORMAT='(I)'),2L)
def_prompt     = def_prompt_pre[0]+type_out_str[0]+def_prompt_suf[0]
IF (test_key) THEN str_out = def_prompt[0]
;;----------------------------------------------------------------------------------------
;;  Define functions and intialize output
;;----------------------------------------------------------------------------------------
good           = WHERE(allowed_types EQ type_out[0],gd)
IF (gd[0] GT 0) THEN BEGIN
  ;;  Define type-dependent zero and function name
  read_out       = all_ok_zero.(good[0])
  func           = all_ok_func.(good[0])
  IF (type_out[0] EQ 7) THEN func = 'STRLOWCASE'
ENDIF ELSE BEGIN
  ;;  Default to string type
  read_out       = ''
  func           = 'STRLOWCASE'
  type_out       = 7
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define error handling
;;----------------------------------------------------------------------------------------
default_out    = read_out[0]

CATCH, error_status
IF (error_status NE 0) THEN BEGIN 
  PRINT, 'Error index: ', error_status
  PRINT, 'Error message: ', !ERROR_STATE.MSG
  ;;  Deal with error
  read_out       = default_out[0]           ;; Use default output
  ;;  Cancel error handler
  CATCH, /CANCEL
  ;;  Return to user
  RETURN,read_out
ENDIF
;;----------------------------------------------------------------------------------------
;;  Print out procedure/instructions
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(pro_out) GT 0) AND (SIZE(pro_out,/TYPE) EQ 7)
IF (test) THEN BEGIN
  npro           = N_ELEMENTS(pro_out)
  PRINT, ""
  PRINT, str_pro[0]
  FOR j=0L, npro - 1L DO PRINT,pro_out[j]
  PRINT, str_pro[0]
  PRINT, ""
ENDIF
;;----------------------------------------------------------------------------------------
;;  Prompt user
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(str_out) GT 0) AND (SIZE(str_out,/TYPE) EQ 7)
IF (test) THEN BEGIN
  PRINT, ""
  PRINT, str_sta[0]
  READ,read_out,PROMPT=str_out
  PRINT, str_end[0]
  PRINT, ""
  read_out       = CALL_FUNCTION(func[0],read_out[0])
ENDIF
;;----------------------------------------------------------------------------------------
;;  Print out user supplied error message
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(errmsg) GT 0) AND (SIZE(errmsg,/TYPE) EQ 7)
IF (test) THEN BEGIN
  nerr           = N_ELEMENTS(errmsg)
  PRINT, ""
  PRINT, str_ers[0]
  FOR j=0L, nerr - 1L DO PRINT,errmsg[j]
  PRINT, str_ere[0]
  PRINT, ""
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,read_out
END

