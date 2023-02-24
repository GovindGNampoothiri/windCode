;+
;*****************************************************************************************
;
;  FUNCTION :   cont2d.pro
;  PURPOSE  :   Produces a contour plot of the distribution function with parallel and 
;                 perpendicular cuts shown.  One can also, with appropriate keywords,
;                 output thermal velocities, eratures, heat flux vectors, and 
;                 temperature anisotropies.
;
;  CALLED BY:   
;               
;
;  CALLS:
;               read_gen_ascii.pro
;               time_string.pro
;               str_element.pro
;               minmax.pro
;               extract_tags.pro
;               add_df2dp_2.pro
;               distfunc.pro
;               get_colors.pro
;               dat_3dp_str_names.pro
;               trange_str.pro
;               cal_rot.pro
;               read_shocks_jck_database.pro
;               mom_sum.pro
;               mom_translate.pro
;               get_plot_state.pro
;               one_count_level.pro
;               moments_3d.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DFPAR    :  3D data structure retrieved from get_??(el,elb,eh,pl, etc.)
;
;  EXAMPLES:    
;               ;....................................................................
;               ; => Define a time of interest
;               ;....................................................................
;               to      = time_double('1996-04-03/09:47:00')
;               ;....................................................................
;               ; => Get a Wind 3DP EESA Low data structure from level zero files
;               ;....................................................................
;               dat     = get_el(to)
;               ;....................................................................
;               ; => in the following lines, the strings correspond to TPLOT handles
;               ;      and thus may be different for each user's preference
;               ;....................................................................
;               add_vsw2,dat,'V_sw2'          ; => Add solar wind velocity to struct.
;               add_magf2,dat,'wi_B3(GSE)'    ; => Add magnetic field to struct.
;               add_scpot,dat,'sc_pot_3'      ; => Add spacecraft potential to struct.
;               ;....................................................................
;               ; => Convert to solar wind frame [assuming VSW tag values or set]
;               ;....................................................................
;               del     = convert_vframe(dat,/INTERP)
;               ;....................................................................
;               ; => Calculate pitch-angle distribution (PAD)
;               ;....................................................................
;               num_pa  = 17L            ; => # of pitch-angle bins
;               pd      = pad(del,NUM_PA=num_pa[0])
;               ;....................................................................
;               ; => Calculate corresponding velocity distribution function (DF)
;               ;....................................................................
;               df      = distfunc(pd.ENERGY,pd.ANGLES,MASS=pd.MASS,DF=pd.DATA)
;               extract_tags,del,df      ; => Put DF structure tags in DEL structure
;               ;....................................................................
;               ; => Plot DF assuming gyrotropy with one-count cut and the
;               ;      heat flux and Vsw vectors projected onto contour and
;               ;      estimates of the thermal speed and temperature anisotropy
;               ;      output
;               ;....................................................................
;               ngrid   = 30L            ; => # of grids in contour
;               vlim    = 2d4            ; => velocity limit (km/s)
;               cont2d,tad,NGRID=ngrid,VLIM=vlim,/HEAT_F,/V_TH,/ANI_TEMP,MYONEC=dat
;
;  KEYWORDS:    
;               VLIM     :  Velocity limit for x-y axes over which to plot data [km/s]
;               NGRID    :  # of isotropic velocity grids to use to triangulate the data
;                             [Default = 30L]
;               REDF     :  Option to plot red line for reduced dist. funct. on cut plot
;               CPD      :  Set to a scalar to define contours per decade
;               LIM      :  Set to plot limit structure [i.e. _EXTRA=lim in PLOT.PRO etc.]
;               NOCOLOR  :  If set, contour plot is output in gray-scale
;               VOUT     :  Set to a named variable to be returned on output specifying
;                             the velocities used to calculate the DFs
;               FILL     :  If set, contours are filled in with colors
;               CCOLORS  :  Obselete?
;               PLOT1    :  Set to a named variable to return the plot state structure
;               MYONEC   :  Allows one to print the data point in 'df' units
;                             corresponding to one count (thus below this, data can
;                             not be trusted).  The input should be the data structure
;                             corresponding to the desired structure being plotted, BUT
;                             it should be the un-manipulated version (i.e. in the
;                             spacecraft frame).  cont2d.pro will use the routine
;                             one_count_level.pro and return the parallel cut of the
;                             1-Count Level for that distribution.
;               V_TH     :  If set, program calculates and outputs the thermal speed
;                             for the input distribution [km/s]
;               MYDIST   :  Structure with format of returned structure from 
;                             distfunc.pro
;               ANI_TEMP :  If set, program calculates and outputs the Temperature 
;                             anisotropy for the input distribution
;               HEAT_F   :  If set, program calculates and outputs the projection of
;                             the heat flux vector to be overplotted on the 2D contour
;                             DF plot
;               GNORM    :  Set to a 3-element unit vector corresponding to the shock
;                             normal vector in GSE coordinates
;               DFRA     :  2-Element array specifying a DF range (s^3/km^3/cm^3) for the
;                             cuts of the distribution function
;               VCIRC    :  Scalar or array defining the value(s) to plot as a
;                             circle(s) of constant speed [km/s] on the contour
;                             plot [e.g. gyrospeed of specularly reflected ion]
;               EX_VEC0  :  3-Element unit vector for another quantity like heat flux or
;                             a wave vector
;                             [Default = undefined]
;               EX_VN0   :  A string name associated with EX_VEC0
;                             [Default = 'Vec 1']
;
;  CHANGED:  1)  Changed vlim to a keyword                 [04/10/2007   v1.1.?]
;            2)  Added keywords: VLIM, MYONEC, V_TH
;            3)  Improved error handling to prevent code breaking or segmentation faults
;            4)  Added the projection of the Solar Wind velocity on contour plots
;            5)  Changed color scale/scheme  {best results when ngrid=24}
;            6)  Changed plot positions and labels
;            7)  No longer calls distfunc.pro, now calls my_distfunc.pro
;            8)  Forced aspect ratio=1 for PS files
;            9)  Plotting options and output were altered to make parallel and
;                  perpendicular cuts of the contours an automatic result
;           10)  Added keywords: MYDIST, ANI_TEMP, HEAT_F  [08/11/2008   v1.1.48]
;           11)  Changed one count calculation             [02/25/2009   v1.1.49]
;           12)  Updated man page                          [02/25/2009   v1.1.50]
;           13)  Changed color calculation                 [02/25/2009   v1.1.51]
;           14)  Changed one count to allow for structures [02/26/2009   v1.1.52]
;           15)  Made some minor alterations, no functionality effects though
;                                                          [03/20/2009   v1.1.53]
;           16)  Added program add_df2dp.pro back to pro   [03/20/2009   v1.1.54]
;           17)  Changed contour levels calculation        [03/20/2009   v1.1.55]
;           18)  Changed add_df2dp.pro to add_df2dp_2.pro  [03/22/2009   v1.1.56]
;           19)  Changed calling of field_rot.pro          [04/17/2009   v1.1.57]
;           20)  Changed Y-Axis labels for cut-plot        [05/15/2009   v1.1.58]
;           21)  Added keyword: GNORM                      [05/15/2009   v1.1.59]
;           22)  Added programs: my_all_shocks_read.pro, my_time_string.pro, and 
;                  rot_mat.pro                             [05/15/2009   v1.2.0]
;           23)  Changed usage of HEAT_F keyword           [05/20/2009   v1.2.1]
;           24)  Added program:  my_mom3d.pro              [05/20/2009   v1.2.1]
;           25)  Added programs :  my_mom_sum.pro and my_mom_translate.pro
;                  Removed program:  my_mom3d.pro          [05/20/2009   v1.2.2]
;           26)  Fixed minor syntax error when GNORM set   [06/17/2009   v1.2.3]
;           27)  Added color-coded output definitions for GNORM and HEAT_F keywords
;                                                          [06/17/2009   v1.2.4]
;           28)  Changed plot labels and colors            [07/30/2009   v1.2.5]
;           29)  Changed treatment of one count level      [07/30/2009   v1.3.0]
;           30)  Fixed plot label on DF cut plot           [07/31/2009   v1.3.1]
;           31)  Changed program my_str_names.pro to dat_3dp_str_names.pro
;                  and my_distfunc.pro to distfunc.pro
;                  and my_convert_vframe.pro to convert_vframe.pro
;                  and my_pad_dist.pro to pad.pro
;                                                          [08/05/2009   v2.0.0]
;           32)  Changed functionality of GNORM keyword slightly by allowing one to
;                  enter a 3-element vector to avoid calling my_all_shocks_read.pro
;                  multiple times                          [08/10/2009   v2.0.1]
;           33)  Changed functionality of MYONEC keyword:  Now enter the original
;                  particle structure after adding 'VSW', 'MAGF', and 'SC_POT'
;                  before transferring into any other reference frame
;                  [Now calls one_count_level.pro]         [08/10/2009   v2.1.0]
;           34)  Fixed syntax error in MYONEC calculation  [08/11/2009   v2.1.1]
;           35)  Changed some minor message outputs        [08/13/2009   v2.1.2]
;           36)  Changed programs:
;                  and my_all_shocks_read.pro to read_shocks_jck_database.pro
;                                                          [09/16/2009   v2.1.3]
;           37)  Altered comments regarding the use of MYONEC keyword
;                                                          [12/02/2009   v2.1.4]
;           38)  Altered comments and functionality regarding the keywords
;                  V_TH, ANI_TEMP, HEAT_F, and GNORM       [02/17/2010   v2.1.5]
;           39)  Fixed a typo with Y-Axis labels for the parallel/perpendicular cuts
;                                                          [02/21/2010   v2.2.0]
;           40)  Changed color of parallel cut output and added keyword:  DFRA
;                                                          [06/21/2010   v2.3.0]
;           41)  Changed contour levels calculation slightly to depend upon
;                  DFRA keyword                            [10/01/2010   v2.4.0]
;           42)  Removed dependence on field_rot.pro       [02/15/2011   v2.5.0]
;           43)  Now plots contour lines over the blue dots marking locations of
;                  actual data points                      [10/15/2011   v2.5.1]
;           44)  Changed contour levels calculation so that DFRA keyword controls
;                  the contours                            [11/28/2011   v2.5.2]
;           45)  Added keywords:  VCIRC, EX_VEC0, and EX_VN0 and cleaned up
;                                                          [02/01/2012   v2.6.0]
;           46)  Implemented a number of superficial changes that only affect how
;                  output is manipulated in Adobe Illustrator and updated man page
;                                                          [02/02/2012   v2.6.1]
;
;   NOTES:      
;               **[changed plotting so that the plots will be automatically square]**
;               1)  Make sure structures are formatted correctly prior to calling
;                     [see Eesa_contour-plot-commands.txt crib for examples]
;
;  ADAPTED FROM: cont2d.pro  BY:  Davin Larson
;  CREATED:  04/10/2007
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/02/2012   v2.6.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO cont2d_edited,txt,dfpar,VLIM=vlim,NGRID=n,REDF=redf,CPD=cpd,LIM=lim,NOCOLOR=nocolor,VOUT=vout, $
           FILL=fill,CCOLORS=ccolors,PLOT1=plot1,MYONEC=myonec,V_TH=v_th,MYDIST=mydist, $
           ANI_TEMP=ani_temp,HEAT_F=heat_f,GNORM=gnorm,DFRA=dfra,VCIRC=vcirc,           $
           EX_VEC0=ex_vec0,EX_VN0=ex_vn0

;-----------------------------------------------------------------------------------------
; => Check distribution to see if it's worth going any further
;-----------------------------------------------------------------------------------------
f       = !VALUES.F_NAN
dat3d   = dfpar
txt_name=txt
IF (dat3d.VALID EQ 0) THEN BEGIN
  MESSAGE,'There is no valid data for this 3D moment sample.',/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;########################################################################################
;; => Define version for output
;;########################################################################################
mdir           = FILE_EXPAND_PATH('wind_3dp_pros/DAVIN_PRO/')+'/'
file           = FILE_SEARCH(mdir,'cont2d.pro')
fstring        = read_gen_ascii(file[0])
test           = STRPOS(fstring,';    LAST MODIFIED:  ') GE 0
gposi          = WHERE(test,gpf)
shifts         = STRLEN(';    LAST MODIFIED:  ')
vers           = STRMID(fstring[gposi[0]],shifts[0])
vers1          = 'cont2d.pro : '+vers[0]+', output at: '
version        = vers1[0]+time_string(SYSTIME(1,/SECONDS),PREC=3)
;-----------------------------------------------------------------------------------------
; => Define some dummy and relevant parameters
;-----------------------------------------------------------------------------------------
!P.MULTI = 0
IF KEYWORD_SET(n) EQ 0 THEN n = 30
IF KEYWORD_SET(vlim) EQ 0 THEN vlim = 20000.
str_element,lim,'XRANGE',xrange
str_element,lim,'CPD',cpd
IF KEYWORD_SET(xrange) THEN vlim = MAX(xrange,/NAN)

temp_ra = minmax(dfpar.DATA,/POSITIVE)
IF KEYWORD_SET(mydist) THEN BEGIN  ; => if distribution function add but not part of dfpar
  dfpar2 = mydist
  extract_tags,dat3d,dfpar2
  add_df2dp_2,dat3d,VLIM=vlim,MINCNT=temp_ra[0]
ENDIF ELSE BEGIN
  dfpar2 = dfpar
  add_df2dp_2,dat3d,VLIM=vlim,MINCNT=temp_ra[0]
ENDELSE
;-----------------------------------------------------------------------------------------
; => Get rid of non-finite data
;-----------------------------------------------------------------------------------------
dfdata = dat3d.DF2D
;-----------------------------------------------------------------------------------------
;  => Recalculate distribution function for designated # of contours
;-----------------------------------------------------------------------------------------
vout     = (DINDGEN(2L*n + 1L)/n - 1L) * vlim
vx       = vout # REPLICATE(1.,2L*n + 1L)
vy       = REPLICATE(1.,2L*n + 1L) # vout

df       = distfunc(vx,vy,PARAM=dfpar2)
df_range = ALOG10(minmax(df))
;  => LBW 10/01/2010
;df_range = ALOG(minmax(df))/ALOG(10.)

gdfr = WHERE(FINITE(df_range) EQ 0,gdf)
IF (gdf GT 1) THEN BEGIN
  MESSAGE,'Infinite data range!',/INFORMATION,/CONTINUE
  RETURN
ENDIF
blow = WHERE(ABS(df_range) LT 1d-40 OR ABS(df_range) GT 1d40,blo)
IF (blo GT 0) THEN BEGIN
  MESSAGE,'Bad data range!',/INFORMATION,/CONTINUE
  RETURN
ENDIF
;------------------------------
; => Get parallel and perpendicular dist. func. cuts
;-----------------------------------------------------------------------------------------
plot1  = get_plot_state()
dfpara = distfunc(vout,0.,PARAM=dfpar2)    ; => vparallel cut (black line)
dfperp = distfunc(0.,vout,PARAM=dfpar2)    ; => vperp cut (blue line)

; => Get One count level StART

IF KEYWORD_SET(myonec) THEN BEGIN
  o_type = SIZE(myonec,/TYPE)
  CASE o_type[0] OF
    8    : BEGIN
      dfonec = one_count_level(myonec,VLIM=vlim,NGRID=n,NUM_PA=17L)  ; => LBW III 10/15/2011   v2.5.1
    END
    ELSE : BEGIN
      MESSAGE,'Incorrect keyword format: MYONEC (Must be a structure)',/INFORMATIONAL,/CONTINUE
      dfonec = REPLICATE(f,2L*n + 1L)
    END
  ENDCASE
  OPLOT,vout*1e-3,dfonec,LINESTYLE=4,COLOR=150L
  XYOUTS,.60,.380,'- - - : One-Count Level',/NORMAL,COLOR=150L
ENDIF

; => Get One count level END

write_csv,+txt_name+'_xz.txt',vout*1e-3,dfpara,vout*1e-3,dfperp,dfonec


str_element,dfpar2,'TIME',VALUE=t
str_element,dfpar2,'END_TIME',VALUE=t2
strn  = dat_3dp_str_names(dfpar2)
title = ''  ; title of plot

!P.MULTI = [0,1,2]
ndec     = 4
title    = dat3d.PROJECT_NAME+'  '+dat3d.DATA_NAME
title   += '!C'+trange_str(dat3d.TIME,dat3d.END_TIME)

OPENW, f1,'./time.txt',/GET_LUN,/APPEND
printf,f1,time_string(dat3d.TIME)
FREE_LUN,f1


temp  = moments_3d(dat3d,SC_POT=dat3d.SC_POT,MAGDIR=dat3d.MAGF)

    tperp = 5e-1*(temp.MAGT3[0] + temp.MAGT3[1])
    tpara = temp.MAGT3[2]
    tanis = tperp/tpara

OPENW, f1,'./anisotropy.txt',/GET_LUN,/APPEND
printf,f1,time_string(dat3d.TIME),tanis
FREE_LUN,f1




RETURN
END


