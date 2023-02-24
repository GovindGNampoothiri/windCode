;+
;*****************************************************************************************
;
;  FUNCTION :   pclose.pro
;  PURPOSE  :   Closes a PS file and returns device settings to original settings.
;
;  CALLED BY:   NA
;
;  CALLS:
;               popen_com.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:       
;               NA
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:  
;               PRINTER  :  Set to name of printer to send PS files to
;               XVIEW    :  Not sure, something to do with X-Windows
;               COMMENT  :  Appends a comment onto file
;
;  SEE ALSO:
;               popen.pro
;               print_options.pro
;               popen_com.pro
;
;   CHANGED:  1)  Davin Larson changed something...                [02/18/1999   v1.0.10]
;             2)  Re-wrote and cleaned up                          [06/10/2009   v1.1.0]
;             3)  Updated to be in accordance with newest version of pclose.pro
;                   in TDAS IDL libraries
;                   A)  Cleaned up and added some comments
;                                                                  [08/27/2012   v1.2.0]
;
;   CREATED:  ??/??/????
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  08/27/2012   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO pclose,PRINTER=printer,XVIEW=xview,COMMENT=comment

;;----------------------------------------------------------------------------------------
;; Set common blocks:
;;----------------------------------------------------------------------------------------
@popen_com.pro
;;----------------------------------------------------------------------------------------
;; Set defaults:
;;----------------------------------------------------------------------------------------
IF (!D.NAME EQ 'PS') THEN BEGIN
  DEVICE,/CLOSE
  SET_PLOT,old_device
  !P.BACKGROUND = old_plot.BACKGROUND
  !P.COLOR      = old_plot.COLOR
  !P.FONT       = old_plot.FONT
  !P.CHARSIZE   = old_plot.CHARSIZE
  PRINT,"Closing plot ",old_fname
ENDIF
;;----------------------------------------------------------------------------------------
;; Set Printer
;;----------------------------------------------------------------------------------------
IF (KEYWORD_SET(printer_name) AND NOT KEYWORD_SET(printer)) THEN printer = printer_name
;;----------------------------------------------------------------------------------------
;; Add comment(s)
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(comment) THEN BEGIN
  PRINT,'Appending comment to ',old_fname
  ;; Open
  OPENU,lu,old_fname,/APPEND,/GET_LUN
  FOR i=0L, N_ELEMENTS(comment) - 1L DO BEGIN
    PRINTF,lu,'% '+comment[i]
  ENDFOR
  FREE_LUN,lu
ENDIF
;;----------------------------------------------------------------------------------------
;; Send to printer if necessary
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(printer) THEN BEGIN
  maxque = 2
  command = 'lpq -P'+printer+' | grep -c '+GETENV('USER')
  REPEAT BEGIN
    SPAWN,command,res
    n = FIX( res[N_ELEMENTS(res) - 1L])
    IF (n GE maxque) THEN BEGIN
      PRINT,SYSTIME(),': ',n,' plots in the que.  Waiting...'
      WAIT, 60.
    ENDIF
  ENDREP UNTIL (n LT maxque)
  ;; Print
  command = 'lpr -P'+printer+' '+old_fname
  PRINT,command
  SPAWN,command
  PRINT,old_fname,' has been sent to printer '+printer
ENDIF

IF KEYWORD_SET(xview) THEN BEGIN
  SPAWN,'xv '+old_fname+' &'
ENDIF
;;----------------------------------------------------------------------------------------
;; Reset original settings prior to calling popen.pro
;;----------------------------------------------------------------------------------------
popened = 0

COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
r_orig = old_colors_com.R_ORIG
g_orig = old_colors_com.B_ORIG
b_orig = old_colors_com.G_ORIG
r_curr = old_colors_com.R_CURR
b_curr = old_colors_com.B_CURR
g_curr = old_colors_com.G_CURR
;;----------------------------------------------------------------------------------------
;; => Return to user
;;----------------------------------------------------------------------------------------

RETURN
END

