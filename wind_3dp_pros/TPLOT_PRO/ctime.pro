;*****************************************************************************************
;
;  PROCEDURE:   ctime_get_exact_data.pro
;  PURPOSE  :   Get a data structure for ctime.  If VAR is a string or a STRARR,
;                 create a structure of data structures.  Get the new values for
;                 HX and HY (i.e., the crosshairs position).  Also check the SPEC option.
;                 --> ctime.pro need never see the actual data structures.
;
;                 All work is done with pointers to reduce data duplication
;                 and increase speed.
;
;  CALLED BY:   
;               ctime.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               get_data.pro
;               str_element.pro
;               data_to_normal.pro
;
;  COMMON BLOCKS: 
;               tplot_com.pro
;               ctime_common.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries or SPEDAS IDL Libraries
;
;  INPUT:
;               ***********************
;               ***  Direct Inputs  ***
;               ***********************
;               VAR     :  TPLOT variable name
;               V       :  Data value at desired time (i.e., DATA.Y[i])
;               T       :  Time at which program is getting data (i.e., DATA.X[i])
;               PAN     :  A scalar defining the panel number
;               ************************
;               ***  Direct Outputs  ***
;               ************************
;               HX      :  X-Component of cursor position in normal coordinates
;               HY      :  Y-Component of cursor position in normal coordinates
;               SUBVAR  :  Set to a named variable to return the TPLOT handle associated
;                            with HX, HY, T, and V outputs
;               YIND    :  Set to a named variable to return the index for the minimum
;                            of the abscissa array (i.e., the minimum time index)
;               YIND2   :  Set to a named variable to return the index for the minimum
;                            of the data at YIND
;               Z       :  Z-Value at desired time
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               SPEC    :  If set, tells program that plot is a spec plot
;               DTYPE   :  Named variable to hold the data type value.  These values are:
;                            0  :  Undefined data type
;                            1  :  Normal data in x,y format
;                            2  :  Structure-type data in time,y1,y2,etc. format
;                            3  :  An array of tplot variable names
;               LOAD    :  If set, loads data in the new plot panel
;
;   CHANGED:  1)  ?? Davin changed something
;                                                                   [??/??/????   v1.0.29]
;             2)  Rewrote and organized/cleaned up
;                                                                   [06/04/2009   v1.0.30]
;             3)  Updated to be in accordance with newest version of ctime.pro
;                   in TDAS IDL libraries
;                   A)  no longer calls dimen2.pro or ndimen.pro
;                   B)  no longer uses () for arrays
;                                                                   [03/27/2012   v1.1.0]
;             4)  Added error handling to avoid missing structure tag assignments
;                                                                   [04/21/2016   v1.2.0]
;
;   NOTES:      
;               NA
;
;  REFERENCES:  
;               NA
;
;   CREATED:  ??/??/????
;   CREATED BY:  Davin Larson & Frank Marcoline
;    LAST MODIFIED:  04/21/2016   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

PRO ctime_get_exact_data,var,v,t,pan,hx,hy,subvar,yind,yind2,z,$
         SPEC=spec,DTYPE=dtype,LOAD=load

;;  Let IDL know that the following are functions
FORWARD_FUNCTION data_to_normal
;;----------------------------------------------------------------------------------------
;;  Get common block data
;;----------------------------------------------------------------------------------------
@tplot_com
COMMON ctime_common, ptr        ;this should NOT appear in ctime, it is local

time_scale     = tplot_vars.SETTINGS.TIME_SCALE
time_offset    = tplot_vars.SETTINGS.TIME_OFFSET
ytype          = tplot_vars.SETTINGS.Y[pan].TYPE
;;----------------------------------------------------------------------------------------
;;  Load data if new panel
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(load) THEN BEGIN
  ;;  Get data from VAR TPLOT handle
  get_data,var,DTYPE=dtype,ALIM=alim,PTR=ptr
  spec = 0 & str_element,alim,'SPEC',spec
  CASE dtype[0] OF
    1    :   ;;  note that if (dtype EQ 2) ctime_get_exact_data does nothing
    2    :   ;;  i.e.  ctime.pro bahaves as if (exact EQ 0)
    3    : BEGIN
      ;;  VAR is an array of TPLOT handles
      get_data,var,DATA=var_str
      IF (SIZE(var_str,/N_DIMENSIONS) EQ 0) THEN var_str = STR_SEP(STRCOMPRESS(var_str),' ')
      nd2 = N_ELEMENTS(var_str)
      ptr = {N:nd2}
      FOR i=0L, nd2 - 1L DO BEGIN
        get_data,var_str[i],PTR=subptr,DTYPE=subdtype,ALIM=subalim
        str_element,alim,'SPEC',subspec
        IF NOT KEYWORD_SET(subspec) THEN subspec = 0
        IF (subdtype NE 1) THEN BEGIN
          ptr.N = ptr.N - 1 ;too limiting...
        ENDIF ELSE BEGIN
          tag = 'd'+STRTRIM(i,2L)
          str_element,/ADD_REPLACE,subptr,'SPEC',subspec    ;;  add spec to substruct
          str_element,/ADD_REPLACE,subptr,'NAME',var_str[i] ;;  add var name to substruct
          str_element,/ADD_REPLACE,ptr,tag,subptr           ;;  add substruct to struct
        ENDELSE
      ENDFOR
    END
    ELSE : BEGIN
      MESSAGE,'Invalid value for dtype: ',dtype,/INFORMATIONAL,/CONTINUE
    END
  ENDCASE
ENDIF
;;  LBW III  04/21/2016   v1.2.0
;;  Keep up with removing extra/obsolete pointers
IF (SIZE(subptr,/TYPE) EQ 10) THEN HEAP_FREE,subptr,/PTR
;;----------------------------------------------------------------------------------------
;;  Get new values for v,t,z,yind2,hx,hy, and subvar
;;----------------------------------------------------------------------------------------
yind2          = -1
subvar         = ''
yind           = 0L                                 ;;  Zero the time index
CASE dtype[0] OF
  1    : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  VAR is a normal TPLOT variable in X,Y format
    ;;------------------------------------------------------------------------------------
    dt   = ABS(*ptr.X - t)                  ;;  Find the closest data.X to t 
    mini = MIN(dt,yind,/NAN)                ;;  Get the index of the min dt
    t    = (*ptr.X)[yind]
    tags = TAG_NAMES(ptr)
    wy   = WHERE(tags EQ 'Y')
    wv   = WHERE(tags EQ 'V')
    szy  = SIZE(*ptr.Y)
;;  LBW III  04/21/2016   v1.2.0
;    szv  = SIZE(*ptr.V)
    IF (wv[0] GE 0) THEN szv = SIZE(*ptr.V) ELSE szv = 0
    IF (szy[0] LT 2) THEN dim2y = 1 ELSE dim2y = szy[2]
    IF (szv[0] LT 2) THEN dim2v = 1 ELSE dim2v = szv[2]
    IF (NOT spec) THEN BEGIN
      ;;----------------------------------------------------------------------------------
      ;;  Not a spec plot
      ;;----------------------------------------------------------------------------------
;;  LBW III 03/27/2012   v1.1.0
;      IF (dimen2(*ptr.Y) GT 1L) THEN BEGIN
      IF (dim2y[0] GT 1L) THEN BEGIN
        ;;  (*ptr.Y) has 2-Dimensions
        IF (FINITE(v)) THEN BEGIN
          IF (ytype EQ 0) THEN BEGIN
            ;;  Linear
            dy = ABS((*ptr.Y)[yind,*] - v)
          ENDIF ELSE BEGIN
            ;;  Logarithmic
            dy = ABS(ALOG((*ptr.Y)[yind,*]) - ALOG(v))
          ENDELSE
          mini = MIN(dy,yind2,/NAN)
          v    = FLOAT((*ptr.Y)[yind,yind2])
        ENDIF
      ENDIF ELSE BEGIN
        ;;  (*ptr.Y) has 1-Dimension
        v = FLOAT((*ptr.Y)[yind])
      ENDELSE
    ENDIF ELSE BEGIN
      ;;----------------------------------------------------------------------------------
      ;;  A spec plot
      ;;----------------------------------------------------------------------------------
;;  LBW III  04/21/2016   v1.2.0
;      IF (FINITE(v)) THEN BEGIN
      IF (FINITE(v) AND (wv[0] GE 0)) THEN BEGIN
;;  LBW III 03/27/2012   v1.1.0
;        IF (dimen2(*ptr.V) EQ 1L) THEN BEGIN
        IF (dim2v[0] EQ 1L) THEN BEGIN
          vr = *ptr.V
        ENDIF ELSE BEGIN
          vr = REFORM((*ptr.V)[yind,*])
        ENDELSE
        IF (ytype EQ 0L) THEN BEGIN
          ;;  Linear
          mini = MIN(ABS(vr - v),yind2,/NAN)
        ENDIF ELSE BEGIN
          ;;  Logarithmic
          mini = MIN(ABS(ALOG(vr) - ALOG(v)),yind2,/NAN)
        ENDELSE
        v = FLOAT(vr[yind2])
        z = FLOAT((*ptr.Y)[yind,yind2])
      ENDIF
    ENDELSE
    t_scale = (t - time_offset)/time_scale
    hx      = data_to_normal(t_scale,tplot_vars.SETTINGS.X)
    hy      = data_to_normal(v,      tplot_vars.SETTINGS.Y[pan])
  END
  2    :      ;;  Not written yet... [structure-type data in time,y1,y2,etc. format]
  3    : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  VAR is a string [scalar or array of TPLOT handles]
    ;;------------------------------------------------------------------------------------
    yinds = LONARR(ptr.N)
    t2    = DBLARR(ptr.N)
    v2    = FLTARR(ptr.N) + v  ;;  important for when v is NaN
;;   TDAS update
;    v2    = FLTARR(ptr.N)
    FOR i=0L, ptr.N - 1L DO BEGIN
      ;;  find the substr with the nearest time
      mini     = MIN(ABS(*ptr.(i+1L).X - t),yind,/NAN)
      yinds[i] = yind
      t2[i]    = (*ptr.(i+1L).X)[yind]
    ENDFOR
    dt  = ABS(t2 - t)
    sdt = SORT(dt)
    w   = WHERE(dt EQ dt[sdt[0]],wc)  ;;  See if several have minimum at dt
    IF (FINITE(v)) THEN BEGIN
      IF (wc EQ 1L) THEN BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  one substr to consider...
        ;;--------------------------------------------------------------------------------
        j    = sdt[0]
        yind = yinds[j]
        szy  = SIZE(*ptr.(j+1L).Y)
        IF (szy[0] LT 2) THEN dim2y = 1 ELSE dim2y = szy[2]
;;  LBW III 03/27/2012   v1.1.0
;        IF (dimen2(*ptr.(j+1).y) GT 1L) THEN BEGIN
        IF (dim2y[0] GT 1L) THEN BEGIN
          ;;  Y is 2D, get nearest line
          IF (ytype EQ 0L) THEN BEGIN
            ;;  Linear
            dy = ABS((*ptr.(j+1L).Y)[yind,*] - v)
          ENDIF ELSE BEGIN
            ;;  Logarithmic
            dy = ABS(ALOG((*ptr.(j+1L).Y)[yind,*]) - ALOG(v))
          ENDELSE
          mini  = MIN(dy,yind2,/NAN)
          v2[j] = (*ptr.(j+1L).Y)[yind,yind2]
        ENDIF ELSE BEGIN
          ;;  Y is 1D, get nearest line
          v2[j] = (*ptr.(j+1L).Y)[yind]
        ENDELSE
      ENDIF ELSE BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Multiple substructures exist
        ;;--------------------------------------------------------------------------------
        j    = w[0]
        y    = ((*ptr.(j+1L).Y)[yinds[j],*])[*]  ;;  [*] works better than REFORM
        IF (ytype EQ 0L) THEN dy = ABS(y - v) ELSE dy = ABS(ALOG(y) - ALOG(v))
        mini = MIN(dy,yind2,/NAN)
        FOR i=1L, wc - 1L DO BEGIN
          y2    = ((*ptr.(w[i]+1L).Y)[yinds[w[i]],*])[*]
          IF (ytype EQ 0L) THEN dy = ABS(y2 - v) ELSE dy = ABS(ALOG(y2) - ALOG(v))
          mini2 = MIN(dy,yind22,/NAN)
          IF (mini2 LT mini) THEN BEGIN
            j = w[i] & mini = mini2 & yind2 = yind22
          ENDIF
        ENDFOR
        v2[j] = (*ptr.(j+1L).Y)[yinds[j],yind2]
        szy   = SIZE(*ptr.(j+1L).Y)
        IF (szy[0] LT 2) THEN dim2y = 1 ELSE dim2y = szy[2]
;;  LBW III 03/27/2012   v1.1.0
;        IF (dimen2(*ptr.(j+1L).Y) EQ 1L) THEN yind2 = -1
        IF (dim2y[0] EQ 1L) THEN yind2 = -1
      ENDELSE
    ENDIF ELSE BEGIN
      j = sdt[0]
    ENDELSE
    t       = t2[j]
    v       = FLOAT(v2[j])
    subvar  = ptr.(j+1L).NAME
    t_scale = (t - time_offset)/time_scale
    hx      = data_to_normal(t_scale,tplot_vars.SETTINGS.X)
    hy      = data_to_normal(v,      tplot_vars.SETTINGS.Y[pan])
  END
  ELSE : BEGIN
    MESSAGE,'Invalid value for dtype: ',dtype,/INFORMATIONAL,/CONTINUE
  END
ENDCASE
;;  Define indices for return values
yind           = LONG(yind)
yind2          = FIX(yind2)
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END


;*****************************************************************************************
;
;  FUNCTION :   time_round.pro
;  PURPOSE  :   This program determines the granularity of the time string returned.
;
;  CALLED BY:   
;               ctime.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               interp.pro
;               time_double.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries or SPEDAS IDL Libraries
;
;  INPUT:
;               TIME       :  [N]-Element [string] array of times of the form:
;                               'YYYY-MM-DD/HH:MM:SS.xxxxxxxx
;                               where the length of 'xxxxxxxx' depends upon RES
;               RES        :  Scalar [numeric] defining the resolution of time data
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               PRECISION  :  Scalar [numeric] defining the number of decimal places
;                               beyond seconds to use
;                               [Default = 6]
;               DAYS       :  If set, the resolution is in # of days
;               HOURS      :  " " hours
;               MINUTES    :  " " minutes
;               SECONDS    :  " " seconds
;
;   CHANGED:  1)  Davin Larson & Frank Marcoline created it
;                                                                   [??/??/????   v1.0.0]
;             2)  Rewrote and organized/cleaned up
;                                                                   [06/04/2009   v1.0.1]
;             3)  Updated to be in accordance with newest version of ctime.pro
;                   in TDAS IDL libraries
;                   A)  no longer calls dimen2.pro or ndimen.pro
;                   B)  no longer uses () for arrays
;                                                                   [03/27/2012   v1.1.0]
;             4)  Added error handling and cleaned up Man. page
;                                                                   [04/21/2016   v1.1.1]
;
;   NOTES:      
;               NA
;
;  REFERENCES:  
;               NA
;
;   CREATED:  ??/??/????
;   CREATED BY:  Davin Larson & Frank Marcoline
;    LAST MODIFIED:  04/21/2016   v1.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION time_round,time,res,PRECISION=prec,$  ; res must be a scaler!
                     DAYS    = days   ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     HOURS   = hours  ,$       ; Keywords for setting time granularity.
                     MINUTES = minutes,$       ;
                     SECONDS = seconds         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  Let IDL know that the following are functions
FORWARD_FUNCTION interp, time_double
;;----------------------------------------------------------------------------------------
;;  Define default/dummy variables
;;----------------------------------------------------------------------------------------
res0           =  [0,[1,2,5,10,20,30,60]*1d0,[2,5,10,20,30,60]*6d1,[2,4,6,12,24]*36d2]
prc0           = -[0, 0,0,0, 0, 0, 0, 1,      1,1, 1, 1, 1, 2,      2,2,2, 2, 3]
n              = N_ELEMENTS(res0)
;;----------------------------------------------------------------------------------------
;;  Define resolution
;;----------------------------------------------------------------------------------------
res            = ABS(res[0])
;;  LBW III  04/21/2016   v1.1.1
;prec = 6
IF (N_ELEMENTS(prec) EQ 0) THEN prec = 6
IF (LONG(prec) LT 0) THEN prec = 6
IF (res[0] EQ 0) THEN RETURN,time  ;; don't round

;;  LBW III  04/21/2016   v1.1.1
;resn           = FLOOR(interp(FINDGEN(n),res0,res))
;;  interpolate to user desired resolution
resn           = FLOOR(interp(FINDGEN(n),res0,res[0]))
;;  Define resolution and precision
IF (resn[0] LE 0) THEN BEGIN
  prec = -FLOOR(ALOG10(res[0]*1.0001d0)) < 10
  res  = 10d0^(-prec[0])
ENDIF ELSE BEGIN
  res  = res0[resn[0] < (n[0] - 1L)]
  prec = prc0[resn[0] < (n[0] - 1L)]
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Change resolution if user defines different granularity
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(days)    THEN res = days*864d2
IF KEYWORD_SET(hours)   THEN res = hours*36d2
IF KEYWORD_SET(minutes) THEN res = minutes*6d1
IF KEYWORD_SET(seconds) THEN res = seconds*1d0
;;  Make sure in Unix time
rtime          = time_double(time)
IF (res[0] GE 1) THEN BEGIN
  ;;  desired resolution is ≥ 1
  RETURN, res[0] * ROUND(rtime/res[0])
ENDIF ELSE BEGIN
  ;;  desired resolution is < 1
  time0 = ROUND(time)
  RETURN, time0 + res[0] * ROUND((rtime - time0)/res[0])
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

END


;+
;*****************************************************************************************
;
;  PROCEDURE:   ctime.pro
;  PURPOSE  :   Interactively uses the cursor to select a time (or times) for TPLOT
;
;  CALLED BY:   
;               tplot.pro
;               tlimit.pro
;
;  INCLUDES:
;               ctime_get_exact_data.pro
;               time_round.pro
;
;  CALLS:
;               tplot_com.pro
;               struct_value.pro
;               dprint.pro
;               normal_to_data.pro
;               time_string.pro
;               ctime_get_exact_data.pro
;               time_round.pro
;               tplot_cut.pro
;               append_array.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries or SPEDAS IDL Libraries
;
;  INPUT:
;               ************************
;               ***  Direct Outputs  ***
;               ************************
;               TIME          :  Named variable in which to return the selected time
;                                  (seconds since Jan 1st, 1970)
;               Y             :  Named variable in which to return the y value
;               Z             :  Named variable in which to return the z value
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               APPEND        :  If set, points are appended to the input arrays,
;                                  instead of overwriting the old values.
;               EXACT         :  Get the time,y, and (if applicable) z values from the
;                                  data arrays.  If on a multi-line plot, get the value
;                                  from the line closest to the cursor along y.
;               NPOINTS       :  Max number of points to return
;               INDS          :  Return the indices into the data arrays for the points
;                                  nearest the recorded times to this named variable.
;               VINDS         :  Return the second dimension of the v or y array.
;                                  TIME[i]   :  data.X[INDS[i]]
;                                  Y[i]      :  data.Y[INDS[i],VINDS[i]]
;                                  V[i]      :  data.V[VINDS[i]]
;                                               or data.V[INDS[i],VINDS[i]]
;                                  ;; ...........................................
;                                  ;; where data, inds, and vinds are defined by:
;                                  ;; ...........................................
;                                  get_data,VNAME[i],DATA=data,INDS=inds,VINDS=vinds
;               PANEL         :  Set to a named variable to return an array of tplot
;                                  panel numbers coresponding to the variables points
;                                  were chosen from.
;               ROUTINE_NAME  :  Scalar string defining a routine to call every time
;                                  the button changes
;               CUT           :  If set, ROUTINE_NAME -> tplot_cut.pro
;               COUNTS        :  If set, cursor is updated
;               VNAME         :  Set to a named variable to return an array of tplot
;                                  variable names, cooresponding to the variables points
;                                  were chosen from.
;               PROMPT        :  Optional prompt string
;               LOCAL_TIME    :  If set, prompt displays local time instead of UTC
;               PSYM          :  If set to a psym number, the cooresponding psym is
;                                  plotted at selected points
;               SILENT        :  Do not print data point information
;               NOSHOW        :  Do not show the plot window.
;               DEBUG         :  Avoids default error handling.  Useful for debugging.
;               COLOR         :  An alternative color for the crosshairs.  
;                                  0<=color<=!d.n_colors-1
;               SLEEP         :  Sleep time (seconds) between polling the cursor for
;                                  events.  Increasing SLEEP will slow ctime down, but
;                                  will prevent ctime from monopolizing cpu time.
;                                  [Defaults to 0.1 seconds.]
;               DAYS          :  Sets time granularity to days
;               HOURS         :  Sets time granularity to hours
;               MINUTES       :  Sets time granularity to minutes
;               SECONDS       :  Sets time granularity to seconds
;                                  For example with MINUTES=1, CTIME will find the
;                                    nearest minute to cursor position.
;
;   CHANGED:  1)  ?? Davin changed something
;                                                                   [11/01/2002   v1.0.44]
;             2)  Rewrote and organized/cleaned up
;                                                                   [06/04/2009   v1.0.45]
;             3)  Fixed issue of allocating X-Window on iMac
;                                                                   [08/10/2009   v1.1.0]
;             4)  Second attempt to fix issue of allocating X-Window on iMac...
;                                                                   [09/21/2009   v1.2.0]
;             5)  Updated to be in accordance with newest version of ctime.pro
;                   in TDAS IDL libraries
;                   A)  no longer calls data_type.pro
;                   A)  now calls struct_value.pro and dprint.pro
;                   B)  no longer uses () for arrays
;                   C)  new keywords:  ROUTINE_NAME, CUT, and LOCAL_TIME
;                                                                   [03/27/2012   v1.3.0]
;             6)  Cleaned up routine and Man. page
;                                                                   [04/21/2016   v1.3.1]
;
;   NOTES:      
;               1)  If you use the keyword EXACT, ctime may run noticeablly slower.
;                     Reduce the number of time you cross panels, especially with
;                     tplots of large data sets.
;               2)  ****WARNING!****
;                     If ctime crashes, you may need to call:
;                     IDL> DEVICE,SET_GRAPH=3,/CURSOR_CROSSHAIR
;               3)  See also:  tlimit.pro
;
;  REFERENCES:  
;               NA
;
;   CREATED:  ??/??/????
;   CREATED BY:  Davin Larson & Frank Marcoline
;    LAST MODIFIED:  04/21/2016   v1.3.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO ctime,time,value,zvalue,                     $
                     APPEND       = append      ,$  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     EXACT        = exact       ,$  ;
                     NPOINTS      = npoints     ,$  ; Keywords for setting ctime mode and
                     INDS         = inds        ,$  ; for returning data.
                     VINDS        = inds2       ,$  ;
                     PANEL        = panel       ,$  ;
                     ROUTINE_NAME = routine_name,$  ; this routine is called everytime the
                     CUT          = cut         ,$  ;
                     COUNTS       = n           ,$  ; curser is updated.
                     VNAME        = vname       ,$  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     PROMPT       = prompt      ,$  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     LOCAL_TIME   = local_time  ,$  ; Displays local time instead of UTC
                     PSYM         = psym        ,$  ;
                     SILENT       = silent      ,$  ; Less common keywords for affecting
                     NOSHOW       = noshow      ,$  ;   ctime mode, graphics and text
                     DEBUG        = debug       ,$  ;   output.
                     COLOR        = color       ,$  ;
                     SLEEP        = sleep       ,$  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     DAYS         = days        ,$  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                     HOURS        = hours       ,$  ; Keywords for setting time
                     MINUTES      = minutes     ,$  ;   granularity.
                     SECONDS      = seconds         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  Let IDL know that the following are functions
FORWARD_FUNCTION struct_value, normal_to_data, time_string, time_round
;;----------------------------------------------------------------------------------------
;;  Load common blocks
;;----------------------------------------------------------------------------------------
@tplot_com.pro
;;----------------------------------------------------------------------------------------
;;  Make sure window is set correctly
;;----------------------------------------------------------------------------------------
;;   TDAS update
wndw = struct_value(tplot_vars,'settings.window',DEFAULT=-1)
IF (wndw EQ -1) THEN BEGIN
  dprint,DLEVEL=0,'TPLOT has not yet been initialized!,  Returning.'
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Get/Set default values
;;----------------------------------------------------------------------------------------
tplot_d     = tplot_vars.SETTINGS.D
tplot_x     = tplot_vars.SETTINGS.X
tplot_y     = tplot_vars.SETTINGS.Y
time_scale  = tplot_vars.SETTINGS.TIME_SCALE
time_offset = tplot_vars.SETTINGS.TIME_OFFSET
tplot_var   = tplot_vars.OPTIONS.VARNAMES
;;   TDAS update
IF KEYWORD_SET(cut) THEN routine_name = 'tplot_cut'
;;----------------------------------------------------------------------------------------
;;  Check some system variable parameters
;;----------------------------------------------------------------------------------------
flags = 256 + 128 + 16 + 8
IF (!D.FLAGS AND flags) NE flags THEN BEGIN
  m = 'Current device ('+!D.NAME+') does not support enough features.  See !D.FLAGS'
  MESSAGE,m,/INFORMATIONAL
  RETURN
ENDIF
IF (tplot_d.NAME NE !D.NAME) THEN BEGIN
  MESSAGE,'Device has changed from "'+tplot_d.NAME+'" to "'+!D.NAME+'" since the Last TPLOT.',/INFORMATIONAL
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Make sure we have the correct window
;;----------------------------------------------------------------------------------------
current_window = !D.WINDOW
WSET,tplot_vars.SETTINGS.WINDOW
IF (tplot_d.X_SIZE NE !D.X_SIZE OR tplot_d.Y_SIZE NE !D.Y_SIZE) THEN BEGIN
  WSET,current_window
  MESSAGE,'TPLOT window has been resized!',/CONTINUE
  RETURN
ENDIF
IF NOT KEYWORD_SET(noshow) THEN WSHOW;,ICON=0 ;open the window
;;----------------------------------------------------------------------------------------
;;  check keywords and set defaults
;;----------------------------------------------------------------------------------------
;IF (data_type(sleep) EQ 0)  THEN sleep  = 0.01                 ;if not set: 0.01, if set 0: 0
IF (SIZE(sleep,/TYPE) EQ 0)  THEN sleep  = 0.01                 ;;  if not set: 0.01, if set 0: 0
IF NOT KEYWORD_SET(exact)    THEN exact  = 0    ELSE exact  = 1
IF NOT KEYWORD_SET(npoints)  THEN max    = 2000 ELSE max    = npoints > 1
IF NOT KEYWORD_SET(silent)   THEN silent = 0
IF (NOT silent) THEN BEGIN
;  IF (data_type(prompt) ne 7) THEN BEGIN
  IF (SIZE(prompt,/TYPE) NE 7) THEN BEGIN
    PROMPT='Use button 1 to select time, 2 to erase time, and 3 to quit.'
  ENDIF
  prompt2 = ' point         name:             date/time              yvalue'
  IF (exact) THEN BEGIN
    STRPUT,prompt2,'comp',21 
    prompt2 = prompt2[0]+'        (zvalue)'
  ENDIF
  PRINT,PROMPT,prompt2,FORMAT='(a)'
ENDIF
;;----------------------------------------------------------------------------------------
;;;;;; set graphics function, move cursor to screen, and plot original crosshairs
;the graphics function is set to (bitwise) "xor" rather than standard "copy"
;((a xor b) xor b) = a,  lets call your plot "a" and the crosshairs "b"
;plot "a", set the graphics function to "xor", and plot "b" twice and you get "a"
;this way we don't damage your plot
;;----------------------------------------------------------------------------------------
DEVICE,GET_GRAPHICS=old,SET_GRAPHICS=6   ;;  Set xor graphics function
IF NOT KEYWORD_SET(color) THEN BEGIN
  color = !D.N_COLORS - 1
ENDIF ELSE BEGIN
  color = (color > 0) < (!D.N_COLORS - 1)
ENDELSE

px = 0.5                        ;;  Pointer (cursor) x and y positions
py = 0.5
hx = 0.5                        ;;  crossHairs       x and y positions
hy = 0.5
;;----------------------------------------------------------------------------------------
;;  when cursor,x,y,/dev is called and the cursor is off of the plot, (x,y)=(-1,-1)
;;----------------------------------------------------------------------------------------
CURSOR,testx,testy,/DEV,/NOWAIT                     ;;  find current cursor location
IF ((testx EQ -1) AND (testy EQ -1)) THEN BEGIN
  ;;  if cursor not on current window
  ;;   => move cursor to middle of window
  TVCRS,px,py,/NORM
ENDIF ELSE BEGIN
  ;;  cursor is on window
  ;;   => find normal coords
  pxpypz = CONVERT_COORD(testx,testy,/DEV,/TO_NORM)
  px = pxpypz[0]
  py = pxpypz[1]
  hx = px
  hy = py
ENDELSE
PLOTS,[0,1],[hy,hy], COLOR=color,/NORM,/THICK,LINES=0
PLOTS,[hx,hx],[0,1], COLOR=color,/NORM,/THICK,LINES=0
opx = px                        ;;  store values for later comparison
opy = py
ohx = hx                        ;;  store values for later crossHairs deletion
ohy = hy
;;----------------------------------------------------------------------------------------
;if EXACT set, px & py will differ from hx & hy, else they will be the same
;use p{x,y} when working with pointer and h{x,y} when working with crosshairs
;;;;;;
;;;;;; set up output formats
;;----------------------------------------------------------------------------------------
spaces = '                 '                            ;;  wipes out z output from form5 and form6
IF (!D.NAME EQ 'X') THEN BEGIN
  cr    = STRING(13b)                                   ;;  a carriage return (no new line)
;;  changed the following to increase the precision of the output
;;  LBW III 03/27/2012   v1.1.0
;  form1 = "(4x,a15,': ',6x,a19,x,g10.4,a,a,$)"         ;transient output line
;  form2 = "(4x,a15,': [',i2,']  ',a19,x,g10.4,a,a,$)"   ;;  transient output line, EXACT
;  form3 = "(i4,a15,': ',6x,a21,x,g10.4,a)"              ;;  recorded point output line
;  form4 = "(i4,a15,': [',i2,']  ',a19,x,g10.4,a)"       ;;  recorded point output, EXACT
;  form5 = "(4x,a15,': [',i2,']  ',a19,x,g10.4,x,g,a,$)" ;;  transient, EXACT, SPEC
;  form6 = "(i4,a15,': [',i2,']  ',a19,x,g10.4,x,g)"     ;;  recorded,  EXACT, SPEC
  form1 = "(4x,a18,': ',6x,a23,x,g10.4,a,a,$)"              ;;  transient output line
  form2 = "(4x,a18,': [',i2,']  ',a23,x,g10.4,a,a,$)"       ;;  transient output line, EXACT
  form3 = "(i4,a18,': ',6x,a23,x,g10.4,a)"                  ;;  recorded point output line
  form4 = "(i4,a18,': [',i2,']  ',a23,x,g10.4,a)"           ;;  recorded point output, EXACT
  form5 = "(4x,a18,': [',i2,']  ',a23,x,g10.4,x,g10.4,a,$)" ;;  transient, EXACT, SPEC
  form6 = "(i4,a18,': [',i2,']  ',a23,x,g10.4,x,g10.4)"     ;;  recorded,  EXACT, SPEC
ENDIF ELSE BEGIN
  ;;  these are for compatibility with MS-Windows
  cr    = ''
  form1 = "(4x,a15,': ',6x,a21,x,g,a,a,TL79,$)"         ;;  same as above six formats
  form2 = "(4x,a15,': (',i2,')  ',a19,x,g,a,a,TL79,$)"
  form3 = "(i4,a15,': ',6x,a21,x,g,a)"
  form4 = "(i4,a15,': (',i2,')  ',a19,x,g,a)"
  form5 = "(4x,a15,': (',i2,')  ',a19,x,g,x,g,a,TL79,$)"
  form6 = "(i4,a15,': (',i2,')  ',a19,x,g,x,g)"
ENDELSE
;;----------------------------------------------------------------------------------------
;;;;;; get and print initial position and panel in tplot data coordinates
;;----------------------------------------------------------------------------------------
pan = WHERE(py GE tplot_y[*].WINDOW[0] AND py LE tplot_y[*].WINDOW[1])
pan = pan[0]
t   = normal_to_data(px,tplot_x) * time_scale + time_offset
;;   TDAS update
;IF (pan GE 0) THEN BEGIN
IF (pan GE 0 AND pan LT N_ELEMENTS(tplot_var)) THEN BEGIN
  v =  normal_to_data(py,tplot_y[pan])
  var = tplot_var[pan]
ENDIF ELSE BEGIN
  v   = !VALUES.F_NAN
  var = 'Null'
ENDELSE
;;  Hard code in a higher precision
PRINT,FORMAT=form1,var,time_string(t,PREC=3,LOCAL_TIME=local_time),FLOAT(v),cr
;;----------------------------------------------------------------------------------------
;;;;;; create an error handling routine
;;----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(debug) THEN BEGIN
  CATCH,myerror
  IF (myerror NE 0) THEN BEGIN                              ;;  begin error handler
    PLOTS,[0,1],[ohy,ohy], COLOR=color,/NORM,/THICK,LINES=0 ;;  erase crosshairs
    PLOTS,[hx,hx],[0,1],   COLOR=color,/NORM,/THICK,LINES=0
    PRINT
    PRINT,'Error: ',!ERROR                                  ;;  report problem
    PRINT,!ERR_STRING
    TVCRS,0                                                 ;;  turn off cursor
    DEVICE,SET_GRAPHICS=old                                 ;;  restore old graphics state
    WSET,current_window                                     ;;  restore old window
    RETURN                                                  ;;  exit on error
  ENDIF
ENDIF                                                       ;;  end error handler
;;----------------------------------------------------------------------------------------
;;;;;; set the initial values for internal and output variables
;;----------------------------------------------------------------------------------------
button=0
IF NOT KEYWORD_SET(append) THEN BEGIN
  time   = 0
  value  = 0
  panel  = 0
  vname  = ''
  inds   = 0
  inds2  = 0
  zvalue = 0
ENDIF

n            =  0
ind          = -1
ind2         = -1
lastvalidvar = var              ;;  record previous data variable (not 'Null')
oldbutton    = 0                ;;  record last button pressed
IF ((exact NE 0) AND (var NE 'Null')) THEN BEGIN
  ctime_get_exact_data,var,v,t,pan,hx,hy,subvar,ind,ind2,z,$
                       SPEC=spec,DTYPE=dtype,/LOAD
ENDIF
;;----------------------------------------------------------------------------------------
;;;;;;  here we are:  the main loop...
;;----------------------------------------------------------------------------------------
WHILE (n LT max) DO BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  the main loop calls cursor, 
  ;;  which waits until there is a button press or cursor movement
  ;;  the old crosshairs are reploted (erased), the new crosshairs are ploted
  ;;;;; get new position, update crosshairs
  ;;--------------------------------------------------------------------------------------
  CURSOR,px,py,/CHANGE,/NORM    ;;  get the new position
;;   TDAS update
;  button = !ERR                 ;;  get the new button state
  button = !MOUSE.BUTTON        ;;  get the new button state
  hx     = px                   ;;  correct   assignments in the case of (EXACT EQ 0)
  hy     = py                   ;;  temporary assignments in the case of (EXACT NE 0)
  ;;  unplot old cross
  PLOTS,[0,1],[ohy,ohy], COLOR=color,/NORM,/THICK,LINES=0
  PLOTS,[ohx,ohx],[0,1], COLOR=color,/NORM,/THICK,LINES=0 
  IF (button EQ 4) THEN GOTO,quit ;;  yikes! i used a goto!
  IF (exact EQ 0) THEN BEGIN
    ;;  plot new crosshairs
    PLOTS,[0,1],[hy,hy], COLOR=color,/NORM,/THICK,LINES=0
    PLOTS,[hx,hx],[0,1], COLOR=color,/NORM,/THICK,LINES=0
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;;; Get new data values and crosshair positions from pointer position values,
  ;;;; if we are not deleting the last data point.
  ;;--------------------------------------------------------------------------------------
  IF ((opx NE px) OR (opy NE py) OR (button NE 2)) THEN BEGIN 
    t   =  normal_to_data(px,tplot_x) * time_scale + time_offset
    res = 1d0/tplot_x.S[1]/!D.X_SIZE
    t   = time_round(t,res,DAYS=days,HOURS=hours,MINUTES=minutes,SECONDS=seconds,PREC=3)
;;  Hard code in a higher precision
;    t = time_round(t,res,days=days,hours=hours,minutes=minutes,seconds=seconds,prec=prec)
    pan = (WHERE(py GE tplot_y[*].WINDOW[0] AND py LE tplot_y[*].WINDOW[1]))[0]
;;   TDAS update
;    IF (pan GE 0) THEN BEGIN
    IF (pan GE 0 AND pan LT N_ELEMENTS(tplot_var)) THEN BEGIN
      v   = normal_to_data(py,tplot_y[pan])
      var = tplot_var[pan]
    ENDIF ELSE BEGIN
      v   =  !VALUES.F_NAN
      var = 'Null'
    ENDELSE
    ind2 = -1
;;   TDAS update
    IF (SIZE(routine_name,/TYPE) EQ 7) THEN BEGIN
      DEVICE,SET_GRAPHICS=old
      WSET,current_window
      CALL_PROCEDURE,routine_name,var,t
      WSET,tplot_vars.SETTINGS.WINDOW
      DEVICE,SET_GRAPHICS=6
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Check if user wants exact values
    ;;------------------------------------------------------------------------------------
    IF (exact NE 0) THEN BEGIN 
      IF (var NE 'Null') THEN BEGIN
        ;;  get data points
        load = (var NE lastvalidvar)
        ctime_get_exact_data,var,v,t,pan,hx,hy,subvar,ind,ind2,z,$
                             SPEC=spec,DTYPE=dtype,LOAD=load
      ENDIF
      ;;  plot new crosshairs
      PLOTS,[0,1],[hy,hy], COLOR=color,/NORM,/THICK,LINES=0
      PLOTS,[hx,hx],[0,1], COLOR=color,/NORM,/THICK,LINES=0
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Print the new data if SILENT is not set
    ;;------------------------------------------------------------------------------------
    IF (NOT silent) THEN BEGIN
      IF KEYWORD_SET(subvar) THEN varn = var+"->"+subvar ELSE varn = var
;;   TDAS update
;;  Hard code in a higher precision
;      tstr = time_string(t,PREC=prec,LOCAL_TIME=local_time)
      tstr = time_string(t,PREC=3,LOCAL_TIME=local_time)
      IF (ind2 EQ -1) THEN BEGIN
        PRINT,FORMAT=form1,varn,tstr,v,spaces,cr
      ENDIF ELSE BEGIN
        IF (spec) THEN BEGIN
          PRINT,FORMAT=form5,varn,ind2,tstr,v,z,cr
        ENDIF ELSE BEGIN
          PRINT,FORMAT=form2,varn,ind2,tstr,v,spaces,cr
        ENDELSE
      ENDELSE
    ENDIF
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;;; got the current data
  ;;;; if a button state changes, take action:
  ;;--------------------------------------------------------------------------------------
  IF (button NE oldbutton) THEN BEGIN 
    CASE button OF
      1    : BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  record the new data and print output line
        ;;--------------------------------------------------------------------------------
        append_array,time,t
        append_array,value,v
        IF KEYWORD_SET(spec) THEN BEGIN
          ;;  Add Z-Value onto output
          append_array,zvalue,z
        ENDIF ELSE BEGIN
          append_array,zvalue,!VALUES.F_NAN
        ENDELSE
        IF KEYWORD_SET(subvar) THEN BEGIN
          append_array,vname,subvar
        ENDIF ELSE BEGIN
          append_array,vname,var
        ENDELSE
        append_array,panel,pan
        np = N_ELEMENTS(time)
        append_array,inds,ind
        append_array,inds2,ind2 > 0     ;;  if ind2 eq -1 set to zero
        IF (NOT silent) THEN BEGIN
          IF (ind2 EQ -1) THEN BEGIN
            PRINT,FORMAT=form3,np-1L,varn,tstr,v,spaces
          ENDIF ELSE BEGIN
            IF (spec) THEN BEGIN
              PRINT,FORMAT=form6,np-1L,varn,ind2,tstr,v,z
            ENDIF ELSE BEGIN
              PRINT,FORMAT=form4,np-1L,varn,ind2,tstr,v,spaces
            ENDELSE
          ENDELSE
        ENDIF
        IF KEYWORD_SET(psym) THEN PLOTS,(t - time_offset),v,PSYM=psym
        n += 1L
      END
      2    : BEGIN                      ;;  delete last data and print output line
        np = N_ELEMENTS(time)
        IF (np GE 2) THEN BEGIN
          time   = time[0L:(np - 2L)]
          value  = value[0L:(np - 2L)]
          vname  = vname[0L:(np - 2L)]
          panel  = panel[0L:(np - 2L)]
          inds   = inds[0L:(np - 2L)]
          inds2  = inds2[0L:(np - 2L)]
          zvalue = zvalue[0L:(np - 2L)]
          IF (NOT silent) THEN BEGIN
            PRINT,FORMAT="(79x,a,TL79,'last sample (',i0,') deleted.')",cr,np - 1L
          ENDIF
          n -= 1L
        ENDIF ELSE BEGIN
          IF ((np NE 0) AND (time[0] NE 0)) THEN BEGIN 
            time   = 0
            value  = 0
            panel  = 0
            vname  = ''
            inds   = 0
            inds2  = 0
            zvalue = 0
            IF (NOT silent) THEN BEGIN
              PRINT,FORMAT="(79x,a,TL79,'Zero sample (',i0,') set to zero.')",cr,np - 1L
            ENDIF
            n = (n - 1L) > 0
          ENDIF
        ENDELSE
      END
      ELSE :  ;;  do nothing (if 4 then we exited already)
    ENDCASE
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;;; store the current information, and pause (reduce interrupts on cpu)
  ;;--------------------------------------------------------------------------------------
  IF (var NE 'Null') THEN lastvalidvar = var
  oldpanel  = pan
  oldbutton = button
  opx       = px
  opy       = py
  ohx       = hx
  ohy       = hy
  WAIT, sleep                   ;;  Be nice
ENDWHILE ;;;;;; end main loop
;;----------------------------------------------------------------------------------------
;;;;;; erase the crosshairs
;;----------------------------------------------------------------------------------------
PLOTS,[0,1],[hy,hy], COLOR=color,/NORM,/THICK,LINES=0 
PLOTS,[hx,hx],[0,1], COLOR=color,/NORM,/THICK,LINES=0 
;;----------------------------------------------------------------------------------------
;;;;;; return life to normal
;;----------------------------------------------------------------------------------------
;=========================================================================================
QUIT: 
;=========================================================================================
PRINT,cr,FORMAT='(79x,a,TL79,$)' ;;  clear the line
TVCRS                            ;;  turn off cursor
DEVICE,SET_GRAPHICS=old          ;;  restore old graphics state
WSET,current_window              ;;  restore old window
;;   TDAS update
;IF NOT KEYWORD_SET(noshow) THEN WSHOW
IF (N_ELEMENTS(time) EQ 1L) THEN BEGIN
  ;;  turn outputs into scalars
  time   = time[0]
  value  = value[0]
  panel  = panel[0]
  vname  = vname[0]
  inds   = inds[0]
  inds2  = inds2[0]
  zvalue = zvalue[0]
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END


