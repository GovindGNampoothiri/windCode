;+
;*****************************************************************************************
;
;  PROCEDURE:   t_insert_nan_at_interval_se.pro
;  PURPOSE  :   This routine inserts NaNs at the start/end of every interval in a user
;                 specified time series defined by the input TPLOT handle.  The data
;                 are returned to TPLOT.  This is useful to prevent IDL from connecting
;                 lines between two given intervals of, say, burst data that are
;                 separated by more than their duration.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               is_a_number.pro
;               tnames.pro
;               get_data.pro
;               tplot_struct_format_test.pro
;               struct_value.pro
;               sample_rate.pro
;               t_interval_find.pro
;               str_element.pro
;               extract_tags.pro
;               store_data.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TPNAME       :  Scalar or [N]-element [string or integer] array defining
;                                 the TPLOT handle(s) the user wishes to alter
;
;  EXAMPLES:    
;               [calling sequence]
;               t_insert_nan_at_interval_se, tpname [,GAP_THRESH=gap_thresh]
;
;               ;;  1st:  Create a copy in case you do not like the result
;               tpname = 'time_series_1d'
;               get_data,tpname[0],DATA=temp,DLIM=dlim,LIM=lim
;               tpname = 'copy_test'
;               store_data,tpname[0],DATA=temp,DLIM=dlim,LIM=lim
;               ;;  Now run routine
;               t_insert_nan_at_interval_se,tpname
;               ;;  Plot both and compare
;               tplot,['time_series_1d','copy_test']
;
;  KEYWORDS:    
;               ******************************************
;               ***  keywords used by sample_rate.pro  ***
;               ******************************************
;               GAP_THRESH   :  Scalar defining the maximum data gap [s] allowed in
;                                 the calculation
;                                 [Default = 1.0]
;
;   CHANGED:  1)  Added keyword:  GAP_THRESH
;                                                                   [08/15/2015   v1.1.0]
;             2)  Now routine can handle TPLOT structures with more than just the X and
;                   Y tags and fixed a bug where t_interval_find.pro returned negative
;                   indices
;                                                                   [11/26/2015   v1.2.0]
;             3)  Fixed an issue where intervals were immediately adjacent (i.e., used
;                   /MERGE keyword in t_interval_find.pro)
;                                                                   [11/27/2015   v1.3.0]
;             4)  Found instances when use of /MERGE keyword in t_interval_find.pro was
;                   the incorrect approach to use
;                                                                   [11/27/2015   v1.3.1]
;             5)  Now uses new functionality of tplot_struct_format_test.pro for handling
;                   of V or V1 and V2 structure tags and
;                   and no longer calls str_element.pro
;                   now calls tplot_struct_format_test.pro
;                                                                   [11/28/2015   v1.4.0]
;             6)  Cleaned up a bit
;                                                                   [11/28/2015   v1.4.1]
;             7)  Routine can now handle TSHIFT structure tag for TPLOT structures
;                                                                   [04/21/2016   v1.5.0]
;             8)  Cleaned up and now calls struct_value.pro and extract_tags.pro and
;                   now handles structures with DY tag and other time-independent tags
;                                                                   [06/15/2016   v1.6.0]
;
;   NOTES:      
;               1)  See also:  store_data.pro, get_data.pro, tnames.pro
;
;  REFERENCES:  
;               NA
;
;   CREATED:  08/07/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/15/2016   v1.6.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO t_insert_nan_at_interval_se,tpname,GAP_THRESH=gap_thresh

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number, tnames, tplot_struct_format_test, sample_rate, $
                 t_interval_find
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Not extracted tags
excpt_tags     = ['X','Y','V','V1','V2','DY','TSHIFT']
;;  Error messages
noinput_mssg   = 'No or incorrect input was supplied...'
no_tpns_mssg   = 'No TPLOT handles match TPNAME input...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 1) OR (N_ELEMENTS(tpname) EQ 0) OR $
                 ((is_a_number(tpname,/NOMSSG) EQ 0) AND (SIZE(tpname,/TYPE) NE 7))
IF (test[0]) THEN BEGIN
  MESSAGE,noinput_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
tpns           = tnames(tpname)
good           = WHERE(tpns NE '',gd)
test           = (gd[0] EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,no_tpns_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define relevant variables
;;----------------------------------------------------------------------------------------
g_tpns         = tpns[good]
n_tpns         = N_ELEMENTS(g_tpns)
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check GAP_THRESH
test           = (N_ELEMENTS(gap_thresh) GT 0) AND is_a_number(gap_thresh,/NOMSSG)
IF (test[0]) THEN gap_thsh = ABS(gap_thresh[0]) ELSE gap_thsh = 1d0
;;----------------------------------------------------------------------------------------
;;  Insert NaNs if intervals exist
;;----------------------------------------------------------------------------------------
srate          = -1e0
se_int         = [-1,-1]
FOR k=0L, n_tpns[0] - 1L DO BEGIN                                       ;;  TPLOT handle FOR loop
  ;;  Reset logic variables
  v1_v2_on       =  0b
  vv_1d_on       =  0b
  vv_2d_on       =  0b
  IF (N_ELEMENTS(tshift) GT 0) THEN dumb = TEMPORARY(tshift)
  ;;--------------------------------------------------------------------------------------
  ;;  Get data
  ;;--------------------------------------------------------------------------------------
  get_data,g_tpns[k],DATA=temp,DLIM=dlim,LIM=lim
  test           = tplot_struct_format_test(temp,TEST__V=test__v,TEST_V1_V2=test_v1_v2,$
                                            TEST_DY=test_dy,/NOMSSG)
;  test           = tplot_struct_format_test(temp,TEST__V=test__v,TEST_V1_V2=test_v1_v2,/NOMSSG)
  kstr           = STRTRIM(STRING(k[0],FORMAT='(I)'),2L)
  IF (test[0] EQ 0) THEN PRINT,';;  Not a structure --> skipping TPNAME['+kstr[0]+']'
  IF (test[0] EQ 0) THEN CONTINUE
  xx             = temp.X
  yy             = temp.Y
  szdt           = SIZE(xx,/DIMENSIONS)
  szdd           = SIZE(yy,/DIMENSIONS)
  ;str_element,temp,'TSHIFT',tshift
  tshift         = struct_value(temp,'TSHIFT',DEFAULT=0d0)
  ;;--------------------------------------------------------------------------------------
  ;;  Determine sample rate [samples per second]
  ;;--------------------------------------------------------------------------------------
  srate          = sample_rate(xx,GAP_THRESH=gap_thsh[0],/AVE,OUT_MED_AVG=sr_medavg)
  test           = (srate[0] LE 0) OR (FINITE(srate[0]) EQ 0) OR (N_ELEMENTS(sr_medavg) LT 2)
  IF (test[0]) THEN PRINT,';;  Bad sample rate estimate --> skipping TPNAME['+kstr[0]+']'
  IF (test[0]) THEN CONTINUE
  med_sr         = sr_medavg[0]                     ;;  Median sample rate [sps]
  med_dt         = 1d0/med_sr[0]                    ;;  Median sample period [s]
  ;;--------------------------------------------------------------------------------------
  ;;  Find intervals (if present) [corresponding start/end indices]
  ;;--------------------------------------------------------------------------------------
  se_int         = t_interval_find(xx,GAP_THRESH=2d0*med_dt[0],/NAN)
  test           = (se_int[0] LT 0) OR (N_ELEMENTS(se_int) LT 2)
  IF (test[0]) THEN PRINT,';;  No subintervals found --> skipping TPNAME['+kstr[0]+']'
  IF (test[0]) THEN CONTINUE
  n_int          = N_ELEMENTS(se_int[*,0])          ;;  # of intervals
  nt             = N_TAGS(temp)                     ;;  # of structure tags
  ;;--------------------------------------------------------------------------------------
  ;;  First check intervals
  ;;--------------------------------------------------------------------------------------
  upp_max        = (szdt[0] - 1L)
  test_upp       = (se_int[(n_int[0] - 1L),1] LT upp_max[0])
  IF (test_upp[0]) THEN BEGIN
    ;;  Add a final interval onto end of current list
    s_i_add = (se_int[(n_int[0] - 1L),1] + 1L) < upp_max[0]
    e_i_add = upp_max[0]
    se_add  = REFORM([s_i_add[0],e_i_add[0]],1,2)
    se_int  = [se_int,se_add]
  ENDIF
  ;;  Look for negative values
  s_int          = se_int[*,0] > 0
  e_int          = se_int[*,1] < upp_max[0]
  low            = LINDGEN(upp_max[0])
  upp            = low + 1L
  test_low       = s_int[upp] LT s_int[low]
  test_upp       = s_int GT e_int
  bad_low        = WHERE(test_low,bd_low)
  bad_upp        = WHERE(test_upp,bd_upp)
  IF (bd_low GT 0) THEN bindl  = upp[bad_low] ELSE bindl = -1
  bindu          = bad_upp
  IF (bd_low GT 0) THEN se_int[bindl,0] = se_int[bindl,1] < upp_max[0]
  IF (bd_upp GT 0) THEN se_int[bindu,0] = se_int[bindu,1] < upp_max[0]
  ;;  Clean up
  s_int          = 0
  e_int          = 0
  ;;--------------------------------------------------------------------------------------
  ;;  Check for V or V1 and V2
  ;;--------------------------------------------------------------------------------------
  ;;  Check for DY
  IF (test_dy[0] GT 0) THEN BEGIN
    uny        = temp.DY
    test_uy    = 1b
  ENDIF ELSE test_uy = 0b
  ;;  Check for V
  vv_1d_on       = (test__v[0] EQ 1)                ;;  TRUE : IFF V is 1D
  vv_2d_on       = (test__v[0] EQ 2)                ;;  TRUE : IFF V is 2D
  IF (vv_1d_on[0] OR vv_2d_on[0]) THEN BEGIN
    vv         = temp.V
  ENDIF
  ;;  Check for V1 and V2
  v1_v2_on       = test_v1_v2[0]
  IF (v1_v2_on[0]) THEN BEGIN
    ;;  Both V1 and V2 present --> define variables
    v1             = temp.V1
    v2             = temp.V2
  ENDIF
  szdvv          = SIZE(vv,/DIMENSIONS)
  szdv1          = SIZE(v1,/DIMENSIONS)
  szdv2          = SIZE(v2,/DIMENSIONS)
  ;;--------------------------------------------------------------------------------------
  ;;  Insert NaNs at start/end of intervals
  ;;--------------------------------------------------------------------------------------
  szyn           = SIZE(yy,/N_DIMENSIONS)
  szyd           = SIZE(yy,/DIMENSIONS)
  FOR j=0L, n_int[0] - 1L DO BEGIN                                      ;;  Interval expansion FOR loop
    ;;------------------------------------------------------------------------------------
    ;;  Expand X
    ;;------------------------------------------------------------------------------------
    se       = REFORM(se_int[j,*])
    up_dn_xx = xx[se] + [-1d0,1d0]*med_dt[0]
    temp_xx  = [up_dn_xx[0],xx[se[0]:se[1]],up_dn_xx[1]]
    nn       = N_ELEMENTS(temp_xx)
    ;;------------------------------------------------------------------------------------
    ;;  Check dimensions of Y
    ;;------------------------------------------------------------------------------------
    CASE szyn[0] OF
      1 : BEGIN
        temp_y1  = yy[se[0]:se[1]]
        up_dn_yy = f
        IF (test_uy[0]) THEN temp_dy1 = dy[se[0]:se[1]]
      END
      2 : BEGIN
        temp_y1  = yy[se[0]:se[1],*]
        up_dn_yy = REPLICATE(f,1,szyd[1])
        IF (test_uy[0]) THEN temp_dy1 = dy[se[0]:se[1],*]
        IF (vv_2d_on[0]) THEN BEGIN
          temp_vv  = vv[se[0]:se[1],*]
          up_dn_vv = REFORM(temp_vv[0,*],1,szdvv[1])
        ENDIF ELSE BEGIN
          IF (vv_1d_on[0]) THEN temp_vv = vv
        ENDELSE
      END
      3 : BEGIN
        temp_y1  = yy[se[0]:se[1],*,*]
        up_dn_yy = REPLICATE(f,1,szyd[1],szyd[2])
        IF (test_uy[0]) THEN temp_dy1 = dy[se[0]:se[1],*,*]
        IF (v1_v2_on[0]) THEN BEGIN
          temp_v1  = v1[se[0]:se[1],*]
          temp_v2  = v2[se[0]:se[1],*]
          up_dn_v1 = REFORM(temp_v1[0,*],1,szdv1[1])
          up_dn_v2 = REFORM(temp_v2[0,*],1,szdv2[1])
        ENDIF
      END
      ELSE : STOP        ;;  >3 dimensions?
    ENDCASE
    ;;------------------------------------------------------------------------------------
    ;;  Expand Y
    ;;------------------------------------------------------------------------------------
    temp_yy  = [up_dn_yy,temp_y1,up_dn_yy]
    IF (test_uy[0]) THEN BEGIN
      ;;  Expand DY
      temp_dy = [up_dn_yy,temp_dy1,up_dn_yy]
      IF (j EQ 0) THEN new_dy = temp_dy ELSE new_dy = [new_dy,temp_dy]
    ENDIF
    ;;  Add to new output arrays
    IF (j EQ 0) THEN BEGIN
      new_xx = temp_xx
      new_yy = temp_yy
    ENDIF ELSE BEGIN
      new_xx = [new_xx,temp_xx]
      new_yy = [new_yy,temp_yy]
    ENDELSE
    ;;------------------------------------------------------------------------------------
    ;;  Expand V or V1 and V2 (if present)
    ;;------------------------------------------------------------------------------------
    IF (vv_2d_on[0]) THEN BEGIN
      temp_vv1 = [up_dn_vv,temp_vv,up_dn_vv]
      IF (j EQ 0) THEN new_vv = temp_vv1 ELSE new_vv = [new_vv,temp_vv1]
    ENDIF ELSE BEGIN
      IF (vv_1d_on[0]) THEN new_vv = temp_vv
    ENDELSE
    ;;  Check for V1 and V2
    IF (v1_v2_on[0]) THEN BEGIN
      ;;  Expand
      temp_vv1 = [up_dn_v1,temp_v1,up_dn_v1]
      temp_vv2 = [up_dn_v2,temp_v2,up_dn_v2]
      IF (j EQ 0) THEN BEGIN
        new_v1 = temp_vv1
        new_v2 = temp_vv2
      ENDIF ELSE BEGIN
        new_v1 = [new_v1,temp_vv1]
        new_v2 = [new_v2,temp_vv2]
      ENDELSE
    ENDIF
  ENDFOR                                                                ;;  Interval expansion FOR loop
  ;;  Return data back to TPLOT
  IF (v1_v2_on[0] OR (vv_1d_on[0] OR vv_2d_on[0])) THEN BEGIN
    IF (vv_1d_on[0] OR vv_2d_on[0]) THEN BEGIN
      new_struc = {X:new_xx,Y:new_yy,V:new_vv,TSHIFT:tshift[0]}
    ENDIF ELSE BEGIN
      new_struc = {X:new_xx,Y:new_yy,V1:new_v1,V2:new_v2,TSHIFT:tshift[0]}
    ENDELSE
  ENDIF ELSE BEGIN
    new_struc = {X:new_xx,Y:new_yy,TSHIFT:tshift[0]}
  ENDELSE
  ;;  Check for DY
  IF (test_uy[0]) THEN str_element,new_struc,'DY',new_dy,/ADD_REPLACE  ;;  Add DY (if present)
  ;;  Add remaining time-independent tags
  extract_tags,new_struc,temp,EXCEPT_TAGS=excpt_tags
;  ;;  Check for TSHIFT
;  IF (N_ELEMENTS(tshift) GT 0) THEN str_element,new_struc,'TSHIFT',tshift[0],/ADD_REPLACE  ;;  Add TSHIFT (if present)
  store_data,g_tpns[k],DATA=new_struc,DLIM=dlim,LIM=lim
ENDFOR                                                                  ;;  TPLOT handle FOR loop
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END
