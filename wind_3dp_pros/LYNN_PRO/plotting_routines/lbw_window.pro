;+
;*****************************************************************************************
;
;  PROCEDURE:   lbw_window.pro
;  PURPOSE  :   This is a wrapping routine for IDL's WINDOW.PRO that opens a window, if
;                 not already open, and defines the appropriate setup (e.g., size,
;                 position, etc.).
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               is_a_number.pro
;               extract_tags.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               lbw_window,NEW_W=new_w,WIND_N=wind_n,CLEAN=clean,_EXTRA=ex_str
;
;  KEYWORDS:    
;               NEW_W        :  If set, routine will open a new window regardless of
;                                 whether the wind defined by WIND_N is already open
;                                 and in use
;                                 [Default = FALSE]
;               WIND_N       :  Scalar [integer/long] defining the IDL window to use
;                                 for plotting the data
;                                 [Default = use WINDOW with FREE keyword set]
;               CLEAN        :  If set, routine will erase all data currently plotted
;                                 in window WIND_N (only applies if WIND_N already open)
;                                 [Default = FALSE]
;               SC_FRAC      :  Scalar [float/double] defining the fraction of the
;                                 screen/monitor to use for determining the default
;                                 window size
;                                 [Default = 0.5]
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  keywords accepted by WINDOW.PRO  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               _EXTRA       :  See IDL's documentation on WINDOW.PRO
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             3)  Fixed a bug that resulted in the routine ignoring the WIND_N keyword
;                                                                   [02/19/2016   v1.1.0]
;             4)  Apparently routine still ignored WIND_N keyword --> fix
;                                                                   [06/03/2016   v1.2.0]
;
;   NOTES:      
;               1)  This routine will open up a new window unless the window defined by
;                     WIND_N is already open and the NEW_W keyword is not set
;               2)  If neither NEW_W or CLEAN is set, then the routine will not affect
;                     the currently open and used window number WIND_N
;               3)  The value of the WIND_N keyword is altered on output
;
;  REFERENCES:  
;               NA
;
;   CREATED:  10/01/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/03/2016   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO lbw_window,NEW_W=new_w,WIND_N=wind_n,CLEAN=clean,SC_FRAC=sc_frac,_EXTRA=ex_str

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number
;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Define variables related to the current device settings
dev_name       = STRLOWCASE(!D[0].NAME[0])
wstate         = -1
def_mnmx_scsz  = [0.1,0.9]
def_wpos       = [1,1]*10L
;;----------------------------------------------------------------------------------------
;;  Check device settings
;;----------------------------------------------------------------------------------------
test_xwin      = (dev_name[0] EQ 'x') OR (dev_name[0] EQ 'win')
IF (test_xwin[0]) THEN BEGIN
  ;;  Proper setting --> find out which windows are already open
  DEVICE,WINDOW_STATE=wstate
ENDIF ELSE BEGIN
  ;;  Not in proper mode --> stop
  errmsg = "The device is not currently set to 'X' or 'WIN' --> Exiting routine without operation..."
  MESSAGE,errmsg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDELSE
n_state        = N_ELEMENTS(wstate)        ;;  # of potential windows
n_win_open     = LONG(TOTAL(wstate))       ;;  # of currently open windows
good_w         = WHERE(wstate,gd_w)
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check SC_FRAC
test           = ((N_ELEMENTS(sc_frac) GE 1) AND is_a_number(sc_frac,/NOMSSG))
IF (test[0]) THEN scfrac = sc_frac[0] ELSE scfrac = 5d-1
;;  Keep fraction of screen reasonable
scfrac         = (scfrac[0] > def_mnmx_scsz[0]) < def_mnmx_scsz[1]
;;  Check NEW_W
test           = ((N_ELEMENTS(new_w) GE 1) AND KEYWORD_SET(new_w))
IF (test[0]) THEN open_new = 1b ELSE open_new = 0b
;;  Check WIND_N
test           = ((N_ELEMENTS(wind_n) GE 1) AND is_a_number(wind_n,/NOMSSG))
IF (test[0]) THEN test = (wind_n[0] GE 0)
IF (test[0]) THEN winn_on = 1b ELSE winn_on = 0b
IF (winn_on[0]) THEN BEGIN
  windn          = LONG(wind_n[0])
  ;;  Check if user specified window is already open
  test_wopen     = (TOTAL(good_w EQ windn[0]) GT 0)     ;;  TRUE --> window already open
  ;;  Check if windows are open already and WIND_N within valid range
  test           = (n_win_open[0] EQ 0) OR (test_wopen[0] EQ 0)
  IF (test[0]) THEN win_on = 0b ELSE win_on = 1b
ENDIF ELSE BEGIN
  test_wopen     = 0b
  windn          = -1L
  win_on         = 0b
ENDELSE
;;  Check CLEAN
test           = ((N_ELEMENTS(clean) GE 1) AND KEYWORD_SET(clean))
IF (test[0]) THEN erase_win = 1b ELSE erase_win = 0b
;;  Check _EXTRA
test           = (SIZE(ex_str,/TYPE) NE 8)
IF (test[0]) THEN lim_on = 0b ELSE lim_on = 1b
;;----------------------------------------------------------------------------------------
;;  Define plot LIMITS structure for WINDOW.PRO
;;----------------------------------------------------------------------------------------
;;  Check if window is open and set --> get current position
test           = test_wopen[0]
IF (test[0]) THEN BEGIN
  ;;  Window WIND_N is open --> check if it is the currently set window
  test = ((!D[0].WINDOW[0] EQ windn[0]) AND (!D[0].WINDOW[0] GE 0))
  IF (test[0]) THEN DEVICE,GET_WINDOW_POSITION=cur_wpos ELSE cur_wpos = def_wpos
ENDIF ELSE cur_wpos = def_wpos
;;  Define default structure
DEVICE,GET_SCREEN_SIZE=s_size
wsz            = s_size*scfrac[0]
wxysz          = wsz[0] > wsz[1]
win_ttl        = 'Plots'
def_win_str    = {RETAIN:2,XSIZE:wxysz[0],YSIZE:wxysz[0],TITLE:win_ttl[0],$
                  XPOS:cur_wpos[0],YPOS:cur_wpos[0]}
;;  Extract user defined limits options if set
IF (lim_on[0]) THEN BEGIN
  ;;  Get keywords specific to WINDOW.PRO only
  tags           = ['COLORS','FREE','PIXMAP','RETAIN','TITLE','XPOS','YPOS','XSIZE','YSIZE']
  extract_tags,win_str,ex_str,TAGS=tags
  test           = (SIZE(win_str,/TYPE) NE 8)
  IF (test[0]) THEN lim_off = 1b ELSE lim_off = 0b
ENDIF ELSE lim_off = 1b
IF (lim_off[0]) THEN BEGIN
  ;;  Let IDL decide how to use window
  win_str        = def_win_str
ENDIF ELSE BEGIN
  ;;  See if user has all the base settings
  def_tags       = TAG_NAMES(def_win_str)
  usr_tags       = TAG_NAMES(win_str)
  extract_tags,win_str,def_win_str,EXCEPT_TAGS=usr_tags
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Setup plot window
;;----------------------------------------------------------------------------------------
IF (test_xwin[0]) THEN BEGIN
  IF (win_on[0]) THEN BEGIN
    ;;  Open window (if not already open)
    test          = (test_wopen[0] EQ 0) AND (windn[0] LE 31) AND open_new[0]
;    test          = (test_wopen[0] EQ 0) AND (windn[0] LT 31) AND open_new[0]
;    test          = test_wopen[0] AND (windn[0] LT 31) AND open_new[0]
    IF (test[0]) THEN WINDOW,windn[0],_EXTRA=win_str
  ENDIF ELSE BEGIN
    test          = (windn[0] GE 0) AND (windn[0] LE 31)
    IF (test[0]) THEN BEGIN
      ;;  Open user-defined window number
      WINDOW,windn[0],_EXTRA=win_str
    ENDIF ELSE BEGIN
      ;;  Let IDL decide which window to use
      WINDOW,/FREE,_EXTRA=win_str
      ;;  Reset/Define window number being used
      windn         = !D[0].WINDOW[0]
    ENDELSE
  ENDELSE
ENDIF     ;;   ELSE : the device is set to PS or some other device (should not get here)
;;  Set and show window
WSET,windn[0]
WSHOW,windn[0]
;;  Reset/Define window number being used
wind_n         = windn[0]
;;----------------------------------------------------------------------------------------
;;  Clear window, if desired
;;----------------------------------------------------------------------------------------
;;  Clear plot window (in case previously used)
IF (erase_win[0]) THEN ERASE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END

