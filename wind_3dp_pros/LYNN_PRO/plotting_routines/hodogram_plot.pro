;*****************************************************************************************
;
;  FUNCTION :   get_hodogram_defaults.pro
;  PURPOSE  :   This routine defines the default settings for the plot setups
;
;  CALLED BY:   
;               hodogram_plot.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               extract_tags.pro
;               str_element.pro
;               test_plot_axis_range.pro
;               is_a_number.pro
;               mag__vec.pro
;               format_vector_string.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               V_IN         :  [N,3]-Element [numeric] array of 3-vectors to plot one
;                                 component versus the other
;
;  EXAMPLES:    
;               def_struc      = get_hodogram_defaults(v_in,PLANE=plane,EX_VECN=ex_vecn,$
;                                                      _EXTRA=ex_str)
;
;  KEYWORDS:    
;               PLANE        :  Scalar [string] defining the plane of projection to show
;                                 in the hodograms (i.e., defines the two components to
;                                 plot versus each other).  The allowed inputs are:
;                                   'yx'  :  plots Y vs. X
;                                   'xz'  :  plots X vs. Z
;                                   'zy'  :  plots Z vs. Y
;                                 [Default = 'yx']
;               TITLES       :  [9]-Element string array defining the plot titles to use
;                                 [Default = the array elements shown in each panel]
;               EX_VECN      :  [V]-Element structure array containing extra vectors the
;                                 user wishes to project onto each hodogram, each with
;                                 the following format:
;                                    VEC   :  [3]-Element vector in the same coordinate
;                                               basis as the input V_IN
;                                               [Default = REPLICATE(!VALUES.D_NAN,3L)]
;                                    NAME  :  Scalar [string] used as a name for VEC
;                                               to output as a label on each plot
;                                               [Default = '']
;               RMAV_OFFSET  :  If set, routine will remove any offset in the components
;                                 prior to plotting.  The offset will be determined by
;                                 finding the mean for each component to be shown,
;                                 determined by the PLANE keyword setting.
;                                 [Default = FALSE]
;               RMMD_OFFSET  :  Same as RMAV_OFFSET except this uses the median instead
;                                 of the mean to define each component offset.
;                                 [Default = FALSE]
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  keywords accepted by PLOT.PRO and OPLOT.PRO  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               _EXTRA       :  See IDL's documentation on PLOT.PRO and OPLOT.PRO
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/30/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/30/2015   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             4)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             5)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             6)  Continued to write routine
;                                                                   [10/09/2015   v1.0.0]
;             7)  Continued to write routine
;                                                                   [10/20/2015   v1.0.0]
;             8)  Continued to write routine
;                                                                   [10/20/2015   v1.0.0]
;             9)  Continued to write routine
;                                                                   [10/20/2015   v1.0.0]
;            10)  Finished writing routine
;                                                                   [10/20/2015   v1.0.0]
;            11)  Forced CHARSIZE and CHARTHICK settings when device is not set to
;                   'X' or 'WIN' and moved XYOUTS settings to get_hodogram_defaults.pro
;                                                                   [10/22/2015   v1.0.1]
;            12)  Fixed a bug when input vector for format_vector_string.pro is not
;                   entirely finite
;                                                                   [10/29/2015   v1.0.2]
;            13)  Fixed an indexing bug that occurs when the input # of points is odd
;                                                                   [02/06/2016   v1.0.3]
;
;   NOTES:      
;               1)  RMMD_OFFSET trumps RMAV_OFFSET --> If both are set, routine will use
;                     the median to define the offset, not the mean
;               2)  It is generally a good idea to remove offsets if they exist because
;                     the default XY-Range uses only the maximum absolute value
;
;  REFERENCES:  
;               NA
;
;   CREATED:  09/29/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/06/2016   v1.0.3
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION get_hodogram_defaults,v_in,PLANE=plane,TITLES=titles,EX_VECN=ex_vecn,       $
                                    RMAV_OFFSET=rmav_offset,RMMD_OFFSET=rmmd_offset, $
                                    _EXTRA=ex_str

;;  Let IDL know that the following are functions
FORWARD_FUNCTION test_plot_axis_range, is_a_number, mag__vec, format_vector_string
;;----------------------------------------------------------------------------------------
;;  Constants and Defaults
;;----------------------------------------------------------------------------------------
;;  Default constants
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
dumb1n         = d[0]
dumb2n         = REPLICATE(d,2L)
dumbxyra       = [-f,f]
;dumbxyra       = [-1e0,1e0]
dumb3n         = REPLICATE(d,3L)
dumb1s         = ''
dumb3s         = REPLICATE('',3L)
vec_str        = ['x','y','z']
;;  Default logic variables
rm_avg_on      = 0b
rm_med_on      = 0b
;;  Defaults for plots
n_plot         = 9L               ;;  # of plots on output
def_planes     = ['yx','xz','zy']
min_nvec       = 27L              ;;  Make sure there are at least this many 3-vectors
def_pttl_pre   = 'Indices: '
def_xyttls     = STRUPCASE(vec_str)+'-Component'
;;  Define plot device
dev_name       = STRLOWCASE(!D[0].NAME[0])
test_xwin      = (dev_name[0] EQ 'x') OR (dev_name[0] EQ 'win')
IF (test_xwin[0]) THEN BEGIN
  ;;  Plot to device window
  def_charsz     = 2.000
  def_chthck     = 1.500
  dypos          = 0.030    ;;  Normalized shift for XYOUTS.PRO positions
  xyoff_vl       = dypos[0]*[5e-1,1e0]
  xyoff_rv       = [0.020,0.010]
  ;;  Define XYOUTS structure for routine version
  xylim_rv       = {CHARSIZE:0.65,NORMAL:1,ORIENTATION:90.}
  xylim_vl       = {NORMAL:1,ORIENTATION:90.}
ENDIF ELSE BEGIN
  ;;  Plot to PS file
  def_charsz     = 1.100
  def_chthck     = 1.250
  dypos          = 0.025    ;;  Normalized shift for XYOUTS.PRO positions
  xyoff_vl       = dypos[0]*[5e-1,5e-1]
  xyoff_rv       = [0.015,0.010]
  ;;  Define XYOUTS structure for routine version
  xylim_rv       = {CHARSIZE:0.55,NORMAL:1,ORIENTATION:90.}
  xylim_vl       = {CHARSIZE:0.70,NORMAL:1,ORIENTATION:90.}
ENDELSE
;;  Define XYOUTS structures and offsets
tags           = ['XYOUTS_XY_OFF','XYOUTS_STRUC']
vl_struc       = CREATE_STRUCT(tags,xyoff_vl,xylim_vl)
rv_struc       = CREATE_STRUCT(tags,xyoff_rv,xylim_rv)
xyo_strs       = {RV:rv_struc,VL:vl_struc}
;;  Define default plot structures
def_xyminr     = 5L
def_plimits    = {YSTYLE:1,XSTYLE:1,NODATA:1,XRANGE:dumbxyra,YRANGE:dumbxyra,$
                  XTITLE:dumb1s[0],YTITLE:dumb1s[0],CHARSIZE:def_charsz[0],  $
                  CHARTHICK:def_chthck[0],XMINOR:def_xyminr[0],YMINOR:[0]}
def_olimits    = {COLOR:50,LINESTYLE:0,THICK:1e0}
def_ptags      = TAG_NAMES(def_plimits[0])
def_otags      = TAG_NAMES(def_olimits[0])
;;  Default for EX_VECN
tags_exv       = ['VEC','NAME']
dumb_exv       = CREATE_STRUCT(tags_exv,dumb3n,dumb1s)
tags_exvo      = ['VEC','NAME','PERC_'+['N','S'],'VEC_S']
dumb_exvo      = CREATE_STRUCT(tags_exvo,dumb3n[0:1],dumb1s[0],dumb1n[0],dumb1s[0],dumb1s[0])
;;----------------------------------------------------------------------------------------
;;  Define default plot positions by row/column
;;----------------------------------------------------------------------------------------
full_xy_range  = [5d-2,95d-2]
def_xymarg     = 5d-2             ;;  rough margin size in normalized units
xy_pos_size    = (full_xy_range[1] - full_xy_range[0] - 4d0*def_xymarg[0])/3d0  ;;  size of each window [NORMAL]
del_xy_psze    = 2d0*def_xymarg[0] + xy_pos_size[0]  ;;  space between end of one window and start of the next [NORMAL]
row_1_lx       = full_xy_range[0] + [0d0,1d0,2d0]*del_xy_psze[0]
row_1_rx       = row_1_lx + xy_pos_size[0]
ypos_1_bx      = 1d0 - def_xymarg[0] - xy_pos_size[0]
col_1_bx       = ypos_1_bx[0] - [0d0,1d0,2d0]*del_xy_psze[0]
col_1_tx       = col_1_bx + xy_pos_size[0]
;;  Define plot positions [left-2-right, top-2-bottom]
p_posi         = DBLARR(n_plot[0]/3L,n_plot[0]/3L,4L)      ;;  [Xo,Yo,X1,Y1]
FOR row=0L, n_plot[0]/3L - 1L DO BEGIN
  FOR col=0L, n_plot[0]/3L - 1L DO BEGIN
    p_posi[row,col,*] = [row_1_lx[col],col_1_bx[row],row_1_rx[col],col_1_tx[row]]
  ENDFOR
ENDFOR
;;  Reform into a [P,4]-Element array {P = # of plots}
positions      = REFORM(TRANSPOSE(p_posi,[1,0,2]),n_plot[0]/3L*n_plot[0]/3L,4L)
;;----------------------------------------------------------------------------------------
;;  Define variables
;;----------------------------------------------------------------------------------------
vin00          = REFORM(v_in)    ;;  should have already been formatted in wrapping routine
;;  Determine dimensions of input
szdv1          = SIZE(vin00,/DIMENSIONS)
n_v            = szdv1[0]               ;;  # of 3-vectors
;;  Define # of points per plot and associated indices
n_per_plot     = (n_v[0] - 1L)/n_plot[0]
ind__low       = LINDGEN(n_plot[0])*n_per_plot[0]
ind_high       = ind__low + (n_per_plot[0] + 1L)
;;  Keep within valid index bounds
ind__low       = ind__low > 0L
ind_high       = ind_high < (n_v[0] - 1L)
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check RMMD_OFFSET
test           = (N_ELEMENTS(rmmd_offset) GT 0) AND KEYWORD_SET(rmmd_offset)
IF (test[0]) THEN rm_med_on = 1b
;;  Check RMAV_OFFSET
test           = ((N_ELEMENTS(rmav_offset) GT 0) AND KEYWORD_SET(rmav_offset)) AND $
                  ~KEYWORD_SET(rm_med_on)
IF (test[0]) THEN rm_avg_on = 1b
test           = (rm_med_on OR rm_avg_on)
IF (test[0]) THEN BEGIN
  ;;  Define offset
  vec_off        = dumb3n
  CASE 1 OF
    rm_med_on  :  FOR j=0L, 2L DO vec_off[j] = MEDIAN(vin00[*,j])
    rm_avg_on  :  FOR j=0L, 2L DO vec_off[j] = MEAN(vin00[*,j],/NAN)
  ENDCASE
  ;;  Remove offset
  vin2d          = vin00 - (REPLICATE(1d0,n_v[0]) # vec_off)
ENDIF ELSE BEGIN
  ;;  Retain offset
  vin2d          = vin00
ENDELSE
;;  Check PLANE
test           = (N_ELEMENTS(plane) EQ 0) OR (SIZE(plane,/TYPE) NE 7)
IF (test[0]) THEN proj = def_planes[0] ELSE proj = STRLOWCASE(plane[0])
CASE proj[0] OF
  'yx'  :  BEGIN              ;;  Plot Y vs. X
    xind           = 0L
    yind           = 1L
  END
  'xz'  :  BEGIN              ;;  Plot X vs. Z
    xind           = 2L
    yind           = 0L
  END
  'zy'  :  BEGIN              ;;  Plot Z vs. Y
    xind           = 1L
    yind           = 2L
  END
  ELSE  :  BEGIN              ;;  Plot Y vs. X
    ;;  Bad input --> use default
    proj           = 'yx'
    xind           = 0L
    yind           = 1L
  END
ENDCASE
xdata          = vin2d[*,xind[0]]
ydata          = vin2d[*,yind[0]]
def_xttl       = def_xyttls[xind[0]]
def_yttl       = def_xyttls[yind[0]]
def_proj_pre   = 'V'+proj[0]+'/|V| = '
;;  Define output arrays
xyinds         = [xind[0],yind[0]]
xydata         = [[xdata],[ydata]]
;;  Define default data range [generally wise to remove offsets if possible]
def_xyran      = 1.05*[-1d0,1d0]*MAX(ABS(xydata),/NAN)
;;  Add to default plot limits structure
str_element,def_plimits,'XRANGE',def_xyran,/ADD_REPLACE
str_element,def_plimits,'YRANGE',def_xyran,/ADD_REPLACE
str_element,def_plimits,'XTITLE',def_xttl[0],/ADD_REPLACE
str_element,def_plimits,'YTITLE',def_yttl[0],/ADD_REPLACE
;;  Check TITLES
test           = (N_ELEMENTS(titles) LT n_plot[0]) OR (SIZE(titles,/TYPE) NE 7)
IF (test[0]) THEN BEGIN
  ;;  Not set or incorrectly formatted --> define defaults
  pttls          = STRARR(n_plot[0])
  indlhstr       = STRARR(n_plot[0],2L)
  indlhstr[*,0]  = STRTRIM(STRING(ind__low,FORMAT='(I)'),2L)
  indlhstr[*,1]  = STRTRIM(STRING(ind_high,FORMAT='(I)'),2L)
  pttls          = def_pttl_pre[0]+indlhstr[*,0]+'-'+indlhstr[*,1]
  pttls[n_plot[0] - 1L] = 'start = diamond; end = square'
  except_tt      = ['']     ;;  Do not get TITLE keyword from _EXTRA
ENDIF ELSE BEGIN
  ;;  Correctly formatted input
  pttls          = titles
  except_tt      = ['TITLE']     ;;  Do not get TITLE keyword from _EXTRA
ENDELSE
;;  Check EX_VECN
test           = (N_ELEMENTS(ex_vecn) GT 0) AND (SIZE(ex_vecn,/TYPE) EQ 8)
IF (test[0]) THEN ex_von = 1b ELSE ex_von = 0b
;;  Check _EXTRA
test           = (SIZE(ex_str,/TYPE) NE 8)
IF (test[0]) THEN lim_on = 0b ELSE lim_on = 1b
;;----------------------------------------------------------------------------------------
;;  Define plot LIMITS structure for PLOT.PRO and OPLOT.PRO
;;----------------------------------------------------------------------------------------
IF (lim_on[0]) THEN BEGIN
  ;;  Get structure info related to each plot type
  extract_tags,plimits0,ex_str,/PLOT
  extract_tags,olimits0,ex_str,/OPLOT
  ;;  Check if either was defined
  test           = (SIZE(plimits0,/TYPE) NE 8)
  IF (test[0]) THEN BEGIN
    ;;  Use default
    plimits = def_plimits
  ENDIF ELSE BEGIN
    ;;  Remove unnecessary/conflicting tags
    extract_tags,plimits,plimits0,EXCEPT_TAGS=[except_tt,'COLOR']
  ENDELSE
  test           = (SIZE(olimits0,/TYPE) NE 8)
  IF (test[0]) THEN BEGIN
    olimits = def_olimits
  ENDIF ELSE BEGIN
    ;;  Remove unnecessary/conflicting tags
    extract_tags,olimits,olimits0,EXCEPT_TAGS=['NSUM']
  ENDELSE
ENDIF ELSE BEGIN
  ;;  Use defaults
  plimits = def_plimits
  olimits = def_olimits
ENDELSE
;;  Make sure only one structure [just in case]
plimits        = plimits[0]
olimits        = olimits[0]
;;----------------------------------------------------------------------------------------
;;  Add base minimum tags (from defaults) if not already present
;;----------------------------------------------------------------------------------------
except_tp      = TAG_NAMES(plimits[0])
except_to      = TAG_NAMES(olimits[0])
;;  Check if only one of the plot ranges were set
ran_tag        = STRUPCASE(vec_str[0:1]+'range')
test_xr        = (TOTAL(ran_tag[0] EQ STRUPCASE(except_tp)) EQ 1)
test_yr        = (TOTAL(ran_tag[1] EQ STRUPCASE(except_tp)) EQ 1)
;test_xr        = (TOTAL(ran_tag[0] EQ STRMID(except_tp,1L)) EQ 1)
;test_yr        = (TOTAL(ran_tag[1] EQ STRMID(except_tp,1L)) EQ 1)
;;  PLOT
FOR j=0L, N_ELEMENTS(def_ptags) - 1L DO BEGIN
  test     = (TOTAL(def_ptags[j] EQ except_tp) GT 0)
  IF (test[0]) THEN CONTINUE
  ;;  Default tag not found --> Add
  CASE STRLOWCASE(def_ptags[j]) OF
    'ystyle'     :  str_element,plimits,def_ptags[j],1,/ADD_REPLACE
    'xstyle'     :  str_element,plimits,def_ptags[j],1,/ADD_REPLACE
    'nodata'     :  str_element,plimits,def_ptags[j],1,/ADD_REPLACE
    'xrange'     :  BEGIN
      IF (test_xr[0]) THEN BEGIN
        str_element,plimits,ran_tag[0],new_xran
;        str_element,plimits,ran_tag[1],new_xran
        ;;  Check axis range
        test     = (test_plot_axis_range(new_xran) EQ 0)
;        test     = ~test_plot_axis_range(new_xran)
        IF (test[0]) THEN new_xran = def_xyran
      ENDIF ELSE BEGIN
        new_xran = def_xyran
      ENDELSE
      ;;  Add to structure
      str_element,plimits,def_ptags[j],new_xran,/ADD_REPLACE
    END
    'yrange'     :  BEGIN
      IF (test_yr[0]) THEN BEGIN
        str_element,plimits,ran_tag[1],new_yran
;        str_element,plimits,ran_tag[0],new_yran
        ;;  Check axis range
        test     = (test_plot_axis_range(new_yran) EQ 0)
;        test     = ~test_plot_axis_range(new_yran)
        IF (test[0]) THEN new_yran = def_xyran
      ENDIF ELSE BEGIN
        new_yran = def_xyran
      ENDELSE
      ;;  Add to structure
      str_element,plimits,def_ptags[j],new_yran,/ADD_REPLACE
    END
    'xtitle'     :  str_element,plimits,def_ptags[j],             def_xttl[0],/ADD_REPLACE
    'ytitle'     :  str_element,plimits,def_ptags[j],             def_yttl[0],/ADD_REPLACE
    'charsize'   :  IF (test_xwin[0]) THEN str_element,plimits,def_ptags[j], def_plimits[0].CHARSIZE,/ADD_REPLACE
    'charthick'  :  IF (test_xwin[0]) THEN str_element,plimits,def_ptags[j],def_plimits[0].CHARTHICK,/ADD_REPLACE
    'xminor'     :  str_element,plimits,def_ptags[j],           def_xyminr[0],/ADD_REPLACE
    'yminor'     :  str_element,plimits,def_ptags[j],           def_xyminr[0],/ADD_REPLACE
    ELSE         :  STOP   ;;  shouldn't happen --> debug
  ENDCASE
ENDFOR
;;  OPLOT
FOR j=0L, N_ELEMENTS(def_otags) - 1L DO BEGIN
  test     = (TOTAL(def_otags[j] EQ except_to) GT 0)
  IF (test[0]) THEN CONTINUE
  ;;  Default tag not found --> Add
  CASE STRLOWCASE(def_otags[j]) OF
    'color'      :  str_element,olimits,    def_otags[j],def_olimits[0].COLOR[0],/ADD_REPLACE
    'linestyle'  :  str_element,olimits,def_otags[j],def_olimits[0].LINESTYLE[0],/ADD_REPLACE
    'thick'      :  str_element,olimits,    def_otags[j],def_olimits[0].THICK[0],/ADD_REPLACE
  ENDCASE
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Define structure for overplotting projected vectors
;;----------------------------------------------------------------------------------------
IF (ex_von[0]) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Check format of extra vector structure
  ;;--------------------------------------------------------------------------------------
  exv_tags       = STRUPCASE(TAG_NAMES(ex_vecn[0]))
  exv_ntgs       = N_TAGS(ex_vecn[0]) < 10L     ;;  keep user from stalling routine indefinitely...
  tmatch         = 0
  FOR k=0L, exv_ntgs[0] - 1L DO tmatch += TOTAL(exv_tags[k] EQ tags_exv)
  test           = (exv_ntgs[0] LT N_ELEMENTS(tags_exv)) OR (tmatch[0] LT N_ELEMENTS(tags_exv))
  IF (test[0]) THEN BEGIN
    ;;  Bad format --> no vectors projected
    out_exv        = dumb_exvo
  ENDIF ELSE BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  1st level format is good --> check 2nd level
    ;;------------------------------------------------------------------------------------
    t_vec          = ex_vecn[0].VEC
    t_nme          = ex_vecn[0].NAME
    test           = ((N_ELEMENTS(t_vec) NE 3L) OR (is_a_number(t_vec,/NOMSSG) EQ 0)) OR $
                      (SIZE(t_nme,/TYPE) NE 7)
    IF (test[0]) THEN BEGIN
      ;;  2nd level bad --> no vectors projected
      out_exv        = dumb_exvo
    ENDIF ELSE BEGIN
      ;;----------------------------------------------------------------------------------
      ;;  2nd level good --> use
      ;;----------------------------------------------------------------------------------
      ;;  Get XY-Ranges for scaling output
      extract_tags,xyranges,plimits,TAGS=ran_tag
      mnran          = MIN([xyranges.XRANGE,xyranges.YRANGE],/NAN)
      mxran          = MAX([xyranges.XRANGE,xyranges.YRANGE],/NAN)
      diff           = ABS(mxran[0] - mnran[0])
      scale          = diff[0]/2d0       ;;  Scale used for projected vectors
      ;;  Define dummy structures to fill
      n_exv          = N_ELEMENTS(ex_vecn) < 3L   ;;  keep to less than 3 to avoid clutter
      out_exv        = REPLICATE(dumb_exvo[0],n_exv[0])
      nt             = N_TAGS(dumb_exvo[0])
      FOR k=0L, n_exv[0] - 1L DO BEGIN
        kstr           = STRTRIM(STRING(k[0],FORMAT='(I)'),2L)
        ;;--------------------------------------------------------------------------------
        ;;  Define vector: its values, its magnitude, and its name
        ;;--------------------------------------------------------------------------------
        ;;  Define vector name
        t_nme          = ex_vecn[k].NAME[0]
        ;;  Define vector and magnitude
        t_vec          = DOUBLE(ex_vecn[k].VEC)
        test_vfin      = (TOTAL(FINITE(t_vec)) EQ 3) AND (TOTAL(ABS(t_vec) GT 0) GT 1)
        IF (test_vfin[0]) THEN t_mag = mag__vec(t_vec) ELSE t_mag = d
        ;;  Define used components and magnitude
;        t_mag          = mag__vec(t_vec)
;        proj_vec       = t_vec[xyinds]
;        proj_mag       = SQRT(TOTAL(proj_vec^2,/NAN))
;        IF (STRLEN(t_nme) LT 5) THEN BEGIN
;          out_proj_pre = t_nme[0]+proj[0]+'/|'+t_nme[0]+'| = '
;          vec_string   = t_nme[0]+' = '+format_vector_string(t_vec,PRECISION=3)
;          ;;  Define string version of vector
;          vec_string   = tvname[0]+' = '+format_vector_string(t_vec,PRECISION=3)
;        ENDIF ELSE BEGIN
;          tvname       = 'V'+kstr[0]
;          out_proj_pre = tvname[0]+proj[0]+'/|'+tvname[0]+'| = '
;          ;;  Define string version of vector
;          vec_string   = tvname[0]+' = '+format_vector_string(t_vec,PRECISION=3)
;        ENDELSE
        ;;--------------------------------------------------------------------------------
        ;;  Define percent/fraction in plane of projection
        ;;--------------------------------------------------------------------------------
        test_vnme      = (STRLEN(t_nme) LT 5)
        IF (test_vnme[0]) THEN tvname = t_nme[0] ELSE tvname = 'V'+kstr[0]
        out_proj_pre   = tvname[0]+proj[0]+'/|'+tvname[0]+'| = '
        IF (test_vfin[0]) THEN BEGIN
          ;;  Define used components and magnitude
          proj_vec       = t_vec[xyinds]
          proj_mag       = SQRT(TOTAL(proj_vec^2,/NAN))
          ;;  Define percent/fraction in plane
          proj_perc_n    = 1d2*(proj_mag[0]/t_mag[0])
          vec_str_suff   = format_vector_string(t_vec,PRECISION=3)
        ENDIF ELSE BEGIN
          ;;  Not finite or all zeros --> use dummy values
          proj_vec       = REPLICATE(d,2)
          proj_mag       = d
          proj_perc_n    = d
          vec_str_suff   = '< +NaN, +NaN, +NaN >'
        ENDELSE
        vec_string     = tvname[0]+' = '+vec_str_suff
        temps          = STRTRIM(STRING(FORMAT='(f12.2)',proj_perc_n[0]),2)
        proj_perc_s    = out_proj_pre[0]+temps[0]+'%'
        ;;--------------------------------------------------------------------------------
        ;;  Alter plot titles
        ;;--------------------------------------------------------------------------------
        pttls[k]      += '; '+proj_perc_s[0]
        ;;  Define values to actually plot
        out_vec        = 85d-2*proj_vec*scale[0]/proj_mag[0]
        IF (test_vfin[0]) THEN out_vec = 85d-2*proj_vec*scale[0]/proj_mag[0] ELSE out_vec = REPLICATE(d,2)
        ;;--------------------------------------------------------------------------------
        ;;  Define dummy structure to use for filling k-th output structure
        ;;--------------------------------------------------------------------------------
        dumb           = CREATE_STRUCT(tags_exvo,out_vec,t_nme[0],proj_perc_n[0],proj_perc_s[0],vec_string[0])
        ;;  Fill k-th structure
        FOR j=0L, nt[0] - 1L DO out_exv[k].(j) = dumb[0].(j)
      ENDFOR
    ENDELSE
  ENDELSE
ENDIF ELSE BEGIN
  ;;  User supplied no extra vectors to project
  out_exv        = dumb_exvo
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define output structure
;;----------------------------------------------------------------------------------------
tags           = ['XYINDS','XYDATA','P_TITLES','P_LIMITS','O_LIMITS','EX_VEC','XYO_STRS','POSITIONS']
struct         = CREATE_STRUCT(tags,xyinds,xydata,pttls,plimits,olimits,out_exv,xyo_strs,positions)
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struct
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   hodogram_plot.pro
;  PURPOSE  :   This routine produces a hodogram (i.e., plot one 3-vector component
;                 versus another) plot as a series of nine plots to show the evolution
;                 of the two vector components in time.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               get_hodogram_defaults.pro
;
;  CALLS:
;               time_string.pro
;               is_a_number.pro
;               format_2d_vec.pro
;               get_hodogram_defaults.pro
;               routine_version.pro
;               lbw_window.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               V_IN         :  [N,3]-Element [numeric] array of 3-vectors to plot one
;                                 component versus the other
;
;  EXAMPLES:    
;               ;;  Define titles and ranges directly
;               xyran          = [-1,1]*15d0
;               hodogram_plot,v_in,PLANE='yx',WIND_N=wind_n,XRANGE=xyran,YRANGE=xyran,$
;                                  XTITLE='Ex [SC, mV/m]',YTITLE='Ey [SC, mV/m]'
;               ;;  Or, define titles and ranges indirectly
;               xyran          = [-1,1]*15d0
;               ex_str         = {XRANGE:xyran,YRANGE:xyran,XTITLE:'Ex [SC, mV/m]',$
;                                 YTITLE:'Ey [SC, mV/m]'}
;               hodogram_plot,v_in,PLANE='yx',WIND_N=wind_n,_EXTRA=ex_str
;
;  KEYWORDS:    
;               PLANE        :  Scalar [string] defining the plane of projection to show
;                                 in the hodograms (i.e., defines the two components to
;                                 plot versus each other).  The allowed inputs are:
;                                   'yx'  :  plots Y vs. X
;                                   'xz'  :  plots X vs. Z
;                                   'zy'  :  plots Z vs. Y
;                                   [Default = 'yx']
;               TITLES       :  [9]-Element string array defining the plot titles to use
;                                 [Default = the array elements shown in each panel]
;               EX_VECN      :  [V]-Element structure array containing extra vectors the
;                                 user wishes to project onto each hodogram, each with
;                                 the following format:
;                                    VEC   :  [3]-Element vector in the same coordinate
;                                               basis as the input V_IN
;                                               [Default = REPLICATE(!VALUES.D_NAN,3L)]
;                                    NAME  :  Scalar [string] used as a name for VEC
;                                               to output as a label on each plot
;                                               [Default = '']
;               WIND_N       :  Scalar [integer/long] defining the IDL window to use
;                                 for plotting the data
;                                 [Default = use WINDOW with FREE keyword set]
;               WIND_TTLE    :  Scalar [string] defining the title of the plot Window
;                                 [Default = 'Hodogram Plots']
;               VERSION      :  Scalar [string or integer] defining whether [TRUE] or
;                                 not [FALSE] to output the current routine version and
;                                 date to be placed on outside of lower-right-hand
;                                 corner.  If a string is supplied, the string is output.
;                                 If TRUE is supplied, then routine_version.pro is
;                                 called to get the current version and date/time for
;                                 output.  If FALSE is supplied, nothing is output.
;                                 See NOTES section below for more details.
;                                 [Default  :  current UTC time]
;               RMAV_OFFSET  :  If set, routine will remove any offset in the components
;                                 prior to plotting.  The offset will be determined by
;                                 finding the mean for each component to be shown,
;                                 determined by the PLANE keyword setting.
;                                 [Default = FALSE]
;               RMMD_OFFSET  :  Same as RMAV_OFFSET except this uses the median instead
;                                 of the mean to define each component offset.
;                                 [Default = FALSE]
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  keywords accepted by PLOT.PRO and OPLOT.PRO  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               _EXTRA       :  See IDL's documentation on PLOT.PRO and OPLOT.PRO
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/30/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/30/2015   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             4)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             5)  Continued to write routine
;                                                                   [10/01/2015   v1.0.0]
;             6)  Continued to write routine
;                                                                   [10/09/2015   v1.0.0]
;             7)  Continued to write routine
;                                                                   [10/20/2015   v1.0.0]
;             8)  Continued to write routine
;                                                                   [10/20/2015   v1.0.0]
;             9)  Continued to write routine
;                                                                   [10/20/2015   v1.0.0]
;            10)  Finished writing routine
;                                                                   [10/20/2015   v1.0.0]
;            11)  Forced CHARSIZE and CHARTHICK settings when device is not set to
;                   'X' or 'WIN' and moved XYOUTS settings to get_hodogram_defaults.pro
;                                                                   [10/22/2015   v1.0.1]
;            12)  Updated Man. page and cleaned up a little
;                                                                   [10/26/2015   v1.0.2]
;            13)  Fixed a bug in get_hodogram_defaults.pro
;                                                                   [10/29/2015   v1.0.3]
;            14)  Fixed an indexing bug that occurs when the input # of points is odd
;                                                                   [02/06/2016   v1.0.4]
;
;   NOTES:      
;               1)  It's generally a good idea if the user defines the XY titles and
;                     plot ranges, and the plot titles before hand, but the routine can
;                     do this for the user as well.
;               2)  The get_hodogram_defaults.pro will automatically redefine up to
;                     three of the plot titles by adding information regarding the
;                     percent of the vectors in EX_VECN that is projected onto the plane
;                     shown.
;               3)  Do not provide the current time if you define VERSION when calling
;                     because the routine will do this for you by default.  For instance,
;                     the output from routine_version.pro looks something like:
;                     'routine_version.pro : 08/08/2012   v1.0.0, 2012-08-08/14:27:08.951'
;                     but the VERSION keyword here expects only:
;                     'routine_version.pro : 08/08/2012   v1.0.0'
;
;  REFERENCES:  
;               NA
;
; ADAPTED FROM: hodo_plot.pro    BY: Lynn B. Wilson III
;   CREATED:  09/29/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/06/2016   v1.0.4
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO hodogram_plot,v_in,PLANE=plane,TITLES=titles,EX_VECN=ex_vecn,WIND_N=wind_n,$
                       WIND_TTLE=wind_ttle,VERSION=version,                    $
                       RMAV_OFFSET=rmav_offset,RMMD_OFFSET=rmmd_offset,        $
                       _EXTRA=ex_str

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number, format_2d_vec, get_hodogram_defaults
;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
n_plot         = 9L               ;;  # of plots on output
def_planes     = ['yx','xz','zy']
min_nvec       = 27L              ;;  Make sure there are at least this many 3-vectors
def_pttl_pre   = 'Indices:  '
def_win_ttl    = 'Hodogram Plots'
;;  Define plot device
dev_name       = STRLOWCASE(!D[0].NAME[0])
test_xwin      = (dev_name[0] EQ 'x') OR (dev_name[0] EQ 'win')
IF (test_xwin[0]) THEN BEGIN
  ;;  Plot to device window
  symsz          = 2.0      ;;  Size of symbols
ENDIF ELSE BEGIN
  ;;  Plot to PS file
  symsz          = 1.5      ;;  Size of symbols
ENDELSE
;;  Define today's date/time
today_str      = 'Output at:  '+time_string(SYSTIME(1,/SECONDS),PREC=4)+' UTC'
;;  Dummy error messages
no_inpt_msg    = 'User must supply an array of 3-vectors'
badvfor_msg    = 'Incorrect input format:  V_IN must be an [N,3]-element [numeric] array of 3-vectors'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 1) OR (is_a_number(v_in,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,no_inpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Check vector format
vin2d          = format_2d_vec(v_in)    ;;  If a vector, routine will force to [N,3]-elements, even if N = 1
test           = ((N_ELEMENTS(vin2d) LT 3L*min_nvec[0]) OR ((N_ELEMENTS(vin2d) MOD 3) NE 0))
IF (test[0]) THEN BEGIN
  MESSAGE,badvfor_msg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Determine dimensions of input
szdv1          = SIZE(vin2d,/DIMENSIONS)
n_v            = szdv1[0]               ;;  # of 3-vectors
;;  Define # of points per plot and associated indices
n_per_plot     = (n_v[0] - 1L)/n_plot[0]
ind__low       = LINDGEN(n_plot[0])*n_per_plot[0]
ind_high       = ind__low + (n_per_plot[0] + 1L)
;;  Keep within valid index bounds
ind__low       = ind__low > 0L
ind_high       = ind_high < (n_v[0] - 1L)
;;----------------------------------------------------------------------------------------
;;  Get defaults and plot parameters
;;----------------------------------------------------------------------------------------
def_struc      = get_hodogram_defaults(vin2d,PLANE=plane,TITLES=titles,EX_VECN=ex_vecn,$
                                       RMAV_OFFSET=rmav_offset,RMMD_OFFSET=rmmd_offset,$
                                       _EXTRA=ex_str)
;;---------------------------------------------
;;  Define defaults structure outputs
;;---------------------------------------------
xyinds         = def_struc.XYINDS
xydata         = def_struc.XYDATA
;;  Define plot structures
pttls          = def_struc.P_TITLES
plimits        = def_struc.P_LIMITS
olimits        = def_struc.O_LIMITS
;;  Define extra vector structures
ex_vecs        = def_struc.EX_VEC
out_exvs       = (TOTAL(FINITE(ex_vecs.VEC)) GT 1)
n_exvs         = N_ELEMENTS(ex_vecs)
;;  Define XYOUTS structures and offsets
xyoff_vl       = def_struc.XYO_STRS.VL.XYOUTS_XY_OFF
xylim_vl       = def_struc.XYO_STRS.VL.XYOUTS_STRUC
xyoff_rv       = def_struc.XYO_STRS.RV.XYOUTS_XY_OFF
xylim_rv       = def_struc.XYO_STRS.RV.XYOUTS_STRUC
;;  Define plot positions
positions      = def_struc.POSITIONS
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check WIND_TTLE
test           = (N_ELEMENTS(wind_ttle) EQ 0) OR (SIZE(wind_ttle,/TYPE) NE 7)
IF (test[0]) THEN win_ttl = def_win_ttl[0] ELSE win_ttl = wind_ttle[0]
;;  Check VERSION
test           = (N_ELEMENTS(version) LT 1) OR (SIZE(version,/TYPE) NE 7)
IF (test[0]) THEN BEGIN
  ;;  Not set --> use default
  r_version      = today_str[0]
ENDIF ELSE BEGIN
  ;;  Is set --> Either TRUE/FALSE or string
  test_on        = 0b
  test_str       = 0b
  test           = (SIZE(version,/TYPE) NE 7)
  IF (test[0]) THEN test_on = KEYWORD_SET(version) ELSE test_str = 1b
  IF (test_on[0]) THEN BEGIN
    ;;  VERSION = TRUE
    r_version      = routine_version('hodogram_plot.pro')
  ENDIF ELSE BEGIN
    IF (test_on[0]) THEN BEGIN
      ;;  VERSION is a string
      r_version      = version[0]
      test           = (r_version[0] EQ '')  ;;  Make sure user didn't pass an empty string
      IF (test[0]) THEN r_version = today_str[0] ELSE r_version = r_version[0]+', '+today_str[0]
    ENDIF ELSE BEGIN
      ;;  VERSION = FALSE --> output nothing
      r_version      = ''
    ENDELSE
  ENDELSE
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Setup plot window
;;----------------------------------------------------------------------------------------
dev_name       = STRLOWCASE(!D[0].NAME[0])
test_xwin      = (dev_name[0] EQ 'x') OR (dev_name[0] EQ 'win')
IF (test_xwin[0]) THEN BEGIN
  ;;  Device window is to be used
  DEVICE,GET_SCREEN_SIZE=s_size
  wsz            = s_size*5d-1
  wxysz          = wsz[0] > wsz[1]
  win_str        = {RETAIN:2,XSIZE:wxysz[0],YSIZE:wxysz[0],TITLE:win_ttl[0]}
  lbw_window,WIND_N=wind_n,/CLEAN,_EXTRA=win_str
;  lbw_window,/NEW_W,WIND_N=wind_n,/CLEAN,_EXTRA=win_str
ENDIF ELSE BEGIN
  ;;  Check if user plans to save
  test_save      = (dev_name[0] NE 'ps') AND (dev_name[0] NE 'z')
  IF (test_save[0]) THEN STOP    ;;  bad device setting --> debug or deal with...
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Plot data
;;----------------------------------------------------------------------------------------
;;  Setup !P system variable
!P.MULTI       = [n_plot[0],3,3]
;;  Define logic for WHILE loop
test           = 1b
jj             = 0L
symst          = 4L      ;;  Diamond at start
symen          = 6L      ;;  Square at end
nvlab_out      = 0L
WHILE (test[0]) DO BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Define parameters for this iteration/plot
  ;;--------------------------------------------------------------------------------------
  ttle           = pttls[jj]
  dnel           = ind__low[jj]
  upel           = ind_high[jj]
  xdat           = xydata[dnel[0]:upel[0],0]
  ydat           = xydata[dnel[0]:upel[0],1]
  nx             = N_ELEMENTS(xdat) - 1L
  posi           = REFORM(positions[jj,*])
  ;;--------------------------------------------------------------------------------------
  ;;  Plot initial blank plot
  ;;--------------------------------------------------------------------------------------
  PLOT,xdat,ydat,TITLE=ttle[0],POSITION=posi,_EXTRA=plimits
    ;;  Define plot origin
    x_orig   = MEAN(plimits.XRANGE,/NAN)
    y_orig   = MEAN(plimits.YRANGE,/NAN)
    ;;  Output crosshairs onto blank plot
    OPLOT,plimits.XRANGE,[y_orig[0],y_orig[0]],THICK=2.0
    OPLOT,[x_orig[0],x_orig[0]],plimits.YRANGE,THICK=2.0
    ;;  Output data onto blank plot
    OPLOT,xdat,ydat,_EXTRA=olimits
    ;;  Output start/end points
    OPLOT,[xdat[0L]],[ydat[0L]],COLOR=250,SYMSIZE=symsz,PSYM=symst
    OPLOT,[xdat[nx]],[ydat[nx]],COLOR=250,SYMSIZE=symsz,PSYM=symen
    ;;------------------------------------------------------------------------------------
    ;;  Project extra vectors onto each plot (if supplied)
    ;;------------------------------------------------------------------------------------
    IF (out_exvs) THEN BEGIN
      vec_cols = LINDGEN(n_exvs[0])*(250L - 30L)/(n_exvs[0] - 1L) + 30L
      ;;  Plot vectors
      FOR nexv=0L, n_exvs[0] - 1L DO BEGIN
        out_str = ex_vecs[nexv]
        test    = (TOTAL(FINITE(out_str[0].VEC)) LT 2)
        IF (test[0]) THEN CONTINUE      ;;  Not finite --> do not plot/show
        t_vec   = out_str[0].VEC
        x_out   = [x_orig[0],t_vec[0]]
        y_out   = [y_orig[0],t_vec[1]]
        ARROW,x_out[0],y_out[0],x_out[1],y_out[1],/DATA,THICK=2.0,COLOR=vec_cols[nexv]
      ENDFOR
      ;;----------------------------------------------------------------------------------
      ;;  ***
      ;;  Outputting of the names/labels
      ;;  ***
      ;;----------------------------------------------------------------------------------
      ;;  Get current position of plot axes
      x_loc          = !X.WINDOW       ;;  {X0,X1} = {start,end} of X-Axis [normalized units]
      y_loc          = !Y.WINDOW       ;;  {Y0,Y1} = {start,end} of Y-Axis [normalized units]
      test_lab       = (jj[0] EQ (n_plot[0] - 3L - (n_exvs[0] - nvlab_out[0])))
      ;;  Output vector labels
      IF (test_lab[0]) THEN BEGIN
        x_pos          = x_loc[1] + xyoff_vl[0]
        y_pos          = y_loc[0] + xyoff_vl[1]
        nexv           = nvlab_out[0]
        test           = (nexv[0] LE (n_exvs[0] - 1L))
        IF (test[0]) THEN BEGIN
          out_str        = ex_vecs[nexv]
          test           = (out_str[0].VEC_S[0] NE '')
          IF (test[0]) THEN BEGIN
            ;;  Output vector
            vecs_out = out_str[0].VEC_S[0]
            XYOUTS,x_pos[0],y_pos[0],vecs_out[0],COLOR=vec_cols[nexv],_EXTRA=xylim_vl
          ENDIF
        ENDIF
        ;;  Increment counters
        nvlab_out   += 1
      ENDIF
      ;;----------------------------------------------------------------------------------
      ;;  Output arrow labels
      ;;----------------------------------------------------------------------------------
      IF (jj EQ n_plot[0] - 2L) THEN BEGIN
        ;;  Output labels outside last plot
        x_pos          = x_loc[1] + xyoff_vl[0]
        y_pos          = y_loc[1] - xyoff_vl[0]*2
        FOR nexv=0L, n_exvs[0] - 1L DO BEGIN
          out_str = ex_vecs[nexv]
          test    = (out_str[0].NAME[0] EQ '')
          IF (test[0]) THEN CONTINUE      ;;  Not finite --> do not plot/show
          t_name  = out_str[0].NAME[0]
          XYOUTS,x_pos[0],y_pos[0],t_name[0],/NORMAL,COLOR=vec_cols[nexv]
          ;;  Shift vertically
          y_pos   -= xyoff_vl[0]
        ENDFOR
      ENDIF
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Output routine version
    ;;------------------------------------------------------------------------------------
    test_rr        = (jj EQ n_plot[0] - 1L) AND (r_version[0] NE '')
    IF (test_rr) THEN BEGIN
      ;;  Get current position of plot axes
      x_loc          = !X.WINDOW       ;;  {X0,X1} = {start,end} of X-Axis [normalized units]
      y_loc          = !Y.WINDOW       ;;  {Y0,Y1} = {start,end} of Y-Axis [normalized units]
      x_pos          = x_loc[1] + xyoff_rv[0]
      y_pos          = y_loc[0] + xyoff_rv[1]
      XYOUTS,x_pos[0],y_pos[0],r_version[0],_EXTRA=xylim_rv
    ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Increment and test
  ;;--------------------------------------------------------------------------------------
  test           = (jj[0] LT n_plot[0] - 1L)
  jj            += test[0]
ENDWHILE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END










