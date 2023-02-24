;+
;*****************************************************************************************
;
;  FUNCTION :   win_setup_beamfit.pro
;  PURPOSE  :   This routine sets up the plot windows for wrapper_beam_fit_1df.pro
;
;  CALLED BY:   
;               beam_fit_1df_plot_fit.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               WTITLE     :  Scalar(or array) [string] defining the title(s) to use
;                               for the IDL window(s) to be opened
;                               [Default = 'Beam Fit Plot '+STRING(j,FORMAT='(I2.2)')]
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               1)  This is specific to wrapper_beam_fit_1df.pro
;
;   CREATED:  08/23/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/23/2012   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION win_setup_beamfit,WTITLE=wtitle

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
jstr           = STRING(LINDGEN(4L),FORMAT='(I2.2)')
def_wttl       = 'Beam Fit Plot '+jstr

;; Make sure device set to 'X'
IF (STRLOWCASE(!D.NAME) NE 'x') THEN SET_PLOT,'X'
;; Get the status of the current windows [1 = open, 0 = no associated window]
DEVICE,WINDOW_STATE=wstate
;;----------------------------------------------------------------------------------------
;; => Check keywords
;;----------------------------------------------------------------------------------------
IF ~KEYWORD_SET(wtitle)     THEN wttls = def_wttl ELSE wttls = wtitle
IF (N_ELEMENTS(wttls) NE 4) THEN wttls = def_wttl
;;----------------------------------------------------------------------------------------
;; => Get screen size to scale and position windows
;;----------------------------------------------------------------------------------------
DEVICE,GET_SCREEN_SIZE=scsize
;; keep the same aspect ratio of plot windows regardless of screen size
wdy            = 200L
aspect         = 800d0/1100d0  ;; x/y
ysize          = LONG(scsize[1] - wdy[0])
xsize          = LONG(ysize[0]*aspect[0])
wdx            = scsize[0] - (xsize[0] + 10)
wypos          = [0d0,3d0*wdy[0]/2d0]
wxpos          = [1d1,wdx[0]]
;;----------------------------------------------------------------------------------------
;; => Set up defaults
;;----------------------------------------------------------------------------------------
;; Get screen size to scale windows
wilim1         = {RETAIN:2,XSIZE:xsize[0],YSIZE:ysize[0],TITLE:wttls[0],XPOS:wxpos[0],YPOS:wypos[1]}
wilim2         = {RETAIN:2,XSIZE:xsize[0],YSIZE:ysize[0],TITLE:wttls[1],XPOS:wxpos[0],YPOS:wypos[0]}
wilim3         = {RETAIN:2,XSIZE:xsize[0],YSIZE:ysize[0],TITLE:wttls[2],XPOS:wxpos[1],YPOS:wypos[1]}
wilim4         = {RETAIN:2,XSIZE:xsize[0],YSIZE:ysize[0],TITLE:wttls[3],XPOS:wxpos[1],YPOS:wypos[0]}
wstruc         = {WIN1:wilim1,WIN2:wilim2,WIN3:wilim3,WIN4:wilim4}
;;----------------------------------------------------------------------------------------
;; Open 4 windows [if not already opened and correct size]
;;----------------------------------------------------------------------------------------
FOR j=1L, 4L DO BEGIN
  k    = j - 1L
  test = (wstate[j] NE 1)
  IF (test) THEN BEGIN
    ;; j-th Window NOT open
    WINDOW,j[0],_EXTRA=wstruc.(k)
  ENDIF ELSE BEGIN
    ;; j-th Window open => check format
    WSET,j[0]
    test = (!D.X_SIZE NE xsize[0]) OR (!D.Y_SIZE NE ysize[0])
    IF (test) THEN BEGIN
      ;; open and format
      WINDOW,j[0],_EXTRA=wstruc.(k)
    ENDIF
  ENDELSE
ENDFOR
;;----------------------------------------------------------------------------------------
;; => Return window structures to user
;;----------------------------------------------------------------------------------------

RETURN,wstruc
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   beam_fit_1df_plot_fit.pro
;  PURPOSE  :   This is a wrapping routine that calls the necessary routines to produce
;                 a model fit of a particle beam to a bi-Maxwellian velocity distribution
;                 function (DF).  The routine has the following outline:
;
;  CALLED BY:   
;               wrapper_beam_fit_array.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               win_setup_beamfit.pro
;               delete_variable.pro
;               beam_fit_keywords_init.pro
;               beam_fit___set_common.pro
;               str_element.pro
;               beam_fit_contour_plot.pro
;               beam_fit_gen_prompt.pro
;               beam_fit_options.pro
;               beam_fit_unset_common.pro
;               beam_fit___get_common.pro
;               popen.pro
;               pclose.pro
;               remove_uv_and_beam_ions.pro
;               find_beam_peak_and_mask.pro
;               beam_fit_fit_wrapper.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DATA       :  [N]-Element array of data structures containing particle
;                               velocity distribution functions (DFs) from either the
;                               Wind/3DP instrument [use get_??.pro, ?? = e.g. phb]
;                               or from the THEMIS ESA instruments.  Regardless, the
;                               structures must satisfy the criteria needed to produce
;                               a contour plot showing the phase (velocity) space density
;                               of the DF.  The structures must also have the following
;                               two tags with finite [3]-element vectors:  VSW and MAGF.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               ***  INPUT  ***
;               VLIM       :  Scalar [float/double] defining the maximum speed [km/s]
;                               to plot for both the contour and cuts
;                               [Default = Vel. defined by maximum energy bin value]
;               NGRID      :  Scalar [long] defining the # of contour levels to use on
;                               output
;                               [Default = 30L]
;               NSMOOTH    :  Scalar [long] defining the # of points over which to
;                               smooth the DF contours and cuts
;                               [Default = 3]
;               SM_CUTS    :  If set, program plots the smoothed (by NSMOOTH points)
;                               cuts of the DF
;                               [Default:  FALSE]
;               SM_CONT    :  If set, program plots the smoothed (by NSMOOTH points)
;                               contours of DF
;                               [Default:  Smoothed to the minimum # of points]
;               DFMIN      :  Scalar [float/double] defining the minimum allowable phase
;                               (velocity) space density to plot, which is useful for
;                               ion distributions with large angular gaps in data
;                               [i.e. prevents lower bound from falling below DFMIN]
;               DFMAX      :  Scalar [float/double] defining the maximum allowable phase
;                               (velocity) space density to plot, which is useful for
;                               distributions with data spikes
;                               [i.e. prevents upper bound from exceeding DFMAX]
;               PLANE      :  Scalar [string] defining the plane projection to plot with
;                               corresponding cuts [Let V1 = MAGF, V2 = VSW]
;                                 'xy'  :  horizontal axis parallel to V1 and normal
;                                            vector to plane defined by (V1 x V2)
;                                            [default]
;                                 'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                            vertical axis parallel to V1
;                                 'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                            and vertical axis (V1 x V2)
;                               [Default = 'xy']
;               ANGLE      :  Scalar [float/double] defining the angle [deg] from the
;                               Y-Axis by which to rotate the [X,Y]-cuts
;                               [Default = 0.0]
;               FILL       :  Scalar [float/double] defining the lowest possible values
;                               to consider and the value to use for replacing zeros
;                               and NaNs when fitting to beam peak
;                               [Default = 1d-18]
;               PERC_PK    :  Scalar [float/double] defining the percentage of the peak
;                               beam amplitude, A_b [cm^(-3) km^(-3) s^(3)], to use in
;                               the fit analysis
;                               [Default = 0.01 (or 1%)]
;               SAVE_DIR   :  Scalar [string] defining the directory where the plots
;                               will be stored
;                               [Default = FILE_EXPAND_PATH('')]
;               FILE_PREF  :  [N]-Element array [string] defining the prefix associated
;                               with each PostScript plot on output
;                               [Default = 'DF_00j', j = index # of DAT]
;               FILE_MIDF  :  Scalar [string] defining the plane of projection and number
;                               grids used for contour plot levels
;                               [Default = 'V1xV2xV1_vs_V1_30Grids_']
;               INDEX      :  Scalar [long] defining the index that defines which element
;                               of an array of structures that DAT corresponds to
;                               [Default = 0]
;               EX_VECN    :  [V]-Element structure array containing extra vectors the
;                               user wishes to project onto the contour, each with
;                               the following format:
;                                  VEC   :  [3]-Element vector in the same coordinate
;                                             system as the bulk flow velocity etc.
;                                             contour plot projection
;                                             [e.g. VEC[0] = along X-GSE]
;                                  NAME  :  Scalar [string] used as a name for VEC
;                                             output onto the contour plot
;                                             [Default = 'Vec_j', j = index of EX_VECS]
;
;  KEYWORDS:    
;               ***  OUTPUT  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [all the following changed on output]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               DATA_OUT   :  Set to a named variable to return a structure containing
;                               the relevant information associated with the plots,
;                               plot analysis, and fit results
;               READ_OUT   :  Set to a named variable to return a string containing the
;                               last command line input.  This is used by the overhead
;                               routine to determine whether user left the program by
;                               quitting or if the program finished
;               PS_FNAME   :  Set to a named variable to return a string containing the
;                               list of PS file names saved during this run through the
;                               routine.  If READ_OUT = 'q', then the overhead routine
;                               will delete these files prior to moving on to the next
;                               particle distribution.
;
;  OUTLINE:     
;               The routine has the following outline:
;
;    ``````````````````````````````````````````````````````````````````````````````````
;    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
;    ´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
;                   1)  Plot the original DF [Window 1]
;                      A)  Prompt user if they wish to change the plot ranges
;                   2)  Prompt user to ask if the "core" is centered correctly
;                         i.e. was the original estimate of Vbulk correct?
;                      A)  If no  -->  adjust [use fix_vbulk_ions.pro]
;                   3)  Prompt user for the maximum velocity, Vcmax, that would
;                         encompass the "core" of the DF
;                      A)  Plot circle corresponding Vcmax [Window 1]
;                      B)  Prompt user asking whether circle fully encompasses the "core"
;                          i)  If yes  -->  Step 4
;                         ii)  If no   -->  Step 3 [keep track of "old" guess]
;                   4)  Plot "halo" only [Window 2]
;                      A)  Create mask [use remove_uv_and_beam_ions.pro]
;                      B)  Subtract masked data from original = "halo"
;                      C)  Plot result  [Window 2]
;                          i)  Prompt user to verify results
;                             a)  If good  -->  Step 5
;                             b)  If bad   -->  Step 3 [ask to increase/decrease Vcmax]
;                   5)  Find "beam" peak [use region_cursor_select.pro]
;                      A)  Find maximum of "halo", Ao [keep track of this]
;                          i)  Find corresponding indices, {i,j}, and velocities,
;                                {V_opar, V_oper}  [keep track of these]
;                      B)  Overplot crosshairs on contour [Window 2]
;                          i)  Prompt user to verify the location of the "beam" peak
;                             a)  If yes  -->  Step 6
;                             b)  If no   -->  Prompt user for better estimates
;                                                [repeat until user is satisfied]
;                   6)  Calculate cuts of DF [use find_dist_func_cuts.pro]
;                      A)  Interpolate DF along desired crosshairs through DF
;                      B)  Smooth results if desired [I suggest you do]
;                      C)  Plot "halo" and cuts corresponding to crosshairs [Window 3]
;                   7)  Determine the region that encompasses the "beam"
;                      A)  Use cursor to define rectangular region [Window 4]
;                          i)  routine will define a circle from the following:
;                                dVx = (X1 - X0)
;                                Vox = (X1 + X0)/2  (= parallel offset)
;                                dVy = (Y1 - Y0)
;                                Voy = (Y1 + Y0)/2  (= perpendicular offset)
;                                Vr  = <{dVx,dVy}>  (= radius of circle)
;                         ii)  routine will re-plot contour with new circle [Window 4]
;                        iii)  Prompt user to verify that they are satisfied with results
;                             a)  If yes  -->  Step 8
;                             b)  If no   -->  Prompt user for better estimates
;                                                [repeat until user is satisfied]
;                      B)  Use region encompassed by circle to create a beam mask
;                          i)  redefine V_bulk by location of V_bpeak in bulk flow frame
;                         ii)  convert into "beam frame" and define mask to remove all
;                                data with |V| > Vr
;                        iii)  apply mask and re-plot contour in "beam frame" [Window 4]
;                         iv)  Prompt user to verify that they are satisfied with results
;                             a)  If yes  -->  Step 8
;                             b)  If no   -->  Prompt user for better estimates
;                                                [repeat until user is satisfied]
;                   8)  Calculate moments of new distribution [use moments_3d_new.pro]
;                      A)  create copy of beam-only DF and convert into "beam frame"
;                      B)  rotate beam-only DF into FACs and triangulate
;                      C)  Perform Moment Analysis on beam-only DF to define PARAM
;
;               PARAM  :  [6]-Element array containing the following quantities:
;                           PARAM[0] = Number Density [cm^(-3)]
;                           PARAM[1] = Parallel Thermal Speed [km/s]
;                           PARAM[2] = Perpendicular Thermal Speed [km/s]
;                           PARAM[3] = Parallel Drift Speed [km/s]
;                           PARAM[4] = Perpendicular Drift Speed [km/s]
;                           PARAM[5] = *** Not Used Here ***
;
;                   9)  Fit to a bi-Maxwellian [use df_fit_beam_peak.pro]
;                      A)  Use the Moment Analysis results as initialization parameters
;                            for the Levenberg-Marquardt least-squares minimization
;                      B)  Determine weights for fit routine
;                          i)  Use square-root of counts as error estimates [= err]
;                         ii)  weights = 1/err^(1d0/4d0) [works but don't know why]
;                      C)  Set up parameter information structures
;                          i)  Let the initial guesses = PARAM
;                         ii)  Determine Constraints
;                             a)  Use Defaults
;                                   Tie N_b    :  Ao π^(3/2) V_Tpar * V_Tper^2
;                                   Limit V_ob :  assume beam mask created a relatively
;                                                   well defined region so that our
;                                                   initial estimates for the beam drift
;                                                   speeds were pretty close
;                                   Limit V_Tj :  assume initial guesses at thermal speeds
;                                                   were also close => limit to ±30%
;                             b)  Prompt user for constraints
;                      D)  Call MPFIT2DFUN.PRO
;                  10)  Construct bi-Maxwellian [use bimaxwellian.pro]
;                      A)  n_b [= π^(3/2) Ao V_Tpar V_Tper^2] is coupled to the other
;                            variables and Ao is fixed by the actual data
;                      B)  {V_opar, V_oper} = location of peak, but allow them to vary
;                            slightly to account for shifts due to smoothing etc.
;                      C)  Create bi-Maxwellian from fit results [Step 9]
;                      D)  Find cuts of model distribution and smooth to same level as
;                            cuts of actual data
;                      E)  Plot results [Window 4]
;                          i)  Re-plot contour and cuts
;                         ii)  Overplot model fit cuts
;                        iii)  Prompt user to verify if they want to change:
;                             a)  % of observed Ao
;                                Yes  -->  Re-fit using new range of data
;                                No   -->  move on
;                             b)  constraints
;                                Yes  -->  Re-fit using constraints for PARAM
;                                No   -->  move on
;               ****************************************************************
;               ***                         OUTPUT                           ***
;               ****************************************************************
;                  11)  Return data structure containing all relevant information to
;                         user, which contains:
;                      A)  Distributions [with and without masks]
;                          i)  original  [SC frame, Step 1]
;                         ii)  core only [SC frame, Step 3]
;                        iii)  halo only [SC frame, Step 4]
;                         iv)  beam only [SC frame, Step 7]
;                          v)  beam only ["beam" frame, Step 8] with extras
;                      B)  Moment Analysis Results [structure from moments_3d_new.pro]
;                      C)  Masks
;                          i)  core isolation mask
;                         ii)  beam isolation mask
;                      D)  Velocities
;                          i)  VLIM
;                         ii)  {V_opar, V_oper} for beam [bulk flow frame, Step 5]
;                        iii)  VB_REG [bulk flow frame, Step 7]
;                      E)  DFs and Cuts
;                          i)  f(v) [results from bimaxwellian.pro]
;                             a)  full 2D DF
;                             b)  cuts [results from find_dist_func_cuts.pro]
;                      F)  Keyword Settings [for each distribution plot]
;                          i)  NSMOOTH
;                         ii)  DFRA
;                        iii)  VCIRC
;                             a)  Vcmax
;                             b)  Vbmax [Vr from Step 7]
;                         iv)  PLANE
;                          v)  V_0X and V_0Y
;                             a)  Step 5
;                             b)  Step 6
;                             c)  Step 7
;                             d)  Step 8
;                         vi)  FILL and PERC_PK
;    ``````````````````````````````````````````````````````````````````````````````````
;    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
;    ´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
;
;   CHANGED:  1)  Continued to write routine                       [08/20/2012   v1.0.0]
;             2)  Continued to write routine                       [08/21/2012   v1.0.0]
;             3)  Continued to write routine                       [08/22/2012   v1.0.0]
;             4)  Continued to write routine                       [08/23/2012   v1.0.0]
;             5)  Continued to write routine                       [08/24/2012   v1.0.0]
;             6)  Continued to write routine                       [08/25/2012   v1.0.0]
;             7)  Continued to write routine                       [08/27/2012   v1.0.0]
;             8)  Continued to write routine                       [08/28/2012   v1.0.0]
;             9)  Changed name to beam_fit_1df_plot_fit.pro        [08/29/2012   v2.0.0]
;            10)  Changed initial prompt so now calls beam_fit_options.pro and
;                   changed how the routine alters commonb block variables
;                                                                  [08/31/2012   v2.1.0]
;            11)  Continued to change routine                      [09/01/2012   v2.1.1]
;            12)  Continued to change routine                      [09/03/2012   v2.1.2]
;            13)  Updated man page, cleaned up, and
;                   added keyword:  EX_VECN
;                                                                  [09/04/2012   v2.2.0]
;            14)  Continued to change routine                      [09/05/2012   v2.2.1]
;            15)  Continued to change routine                      [09/06/2012   v2.2.2]
;            16)  Continued to change routine                      [09/07/2012   v2.2.3]
;            17)  Changed common blocks:  Added VBMAX
;                                                                  [09/07/2012   v2.3.0]
;            18)  Added more points where user can change various plot parameters
;                                                                  [09/08/2012   v2.3.1]
;            19)  Fixed a typo
;                                                                  [09/11/2012   v2.3.2]
;            20)  Now performs fit and moment analysis in "core" bulk frame,
;                   not "beam" frame
;                                                                  [09/11/2012   v2.4.0]
;            21)  Cleaned up and added one-count level to plots
;                                                                  [10/09/2012   v2.5.0]
;            22)  Fixed an issue that occurred if the user tried plotting a new plane
;                   but did not keep that plane, thus resetting to the old value, which
;                   caused the file name to be incorrect
;                                                                  [10/11/2012   v2.6.0]
;
;   NOTES:      
;               1)  See routines called by this wrapping program for more information
;                     about their usage
;               2)  KEYWORD NOTES:
;                     PERC_PK   :  should be in decimal form  -->  10% = 0.10
;                     ANGLE     :  *** I do not trust values other than 0.0 currently ***
;                     V_0[X,Y]  :  will be determined by the program
;                     NSMOOTH   :  I would not recommend anything > 5-7 for cuts of DF
;                     SM_CONT   :  Setting = TRUE does not seem to help results
;                                    --> currently SMOOTH just fills NaNs when the WIDTH
;                                          parameter = 3L
;
;   CREATED:  08/18/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  10/11/2012   v2.6.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO beam_fit_1df_plot_fit,data,VLIM=vlim,NGRID=ngrid,NSMOOTH=nsmooth,SM_CUTS=sm_cuts,   $
                          SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax,PLANE=plane,          $
                          ANGLE=angle,FILL=fill,PERC_PK=perc_pk,SAVE_DIR=save_dir,      $
                          FILE_PREF=file_pref,FILE_MIDF=file_midf,INDEX=index,          $
                          EX_VECN=ex_vecn,DATA_OUT=data_out,READ_OUT=read_out,          $
                          PS_FNAME=ps_fname

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN

xyzvecf        = ['V1','V1xV2xV1','V1xV2']
xy_suff        = xyzvecf[1]+'_vs_'+xyzvecf[0]+'_'
xz_suff        = xyzvecf[0]+'_vs_'+xyzvecf[2]+'_'
yz_suff        = xyzvecf[2]+'_vs_'+xyzvecf[1]+'_'

osvers         = !VERSION.OS_FAMILY
IF (osvers NE 'unix') THEN slash = '\' ELSE slash = '/'
defdir         = FILE_EXPAND_PATH('')+slash[0]
;; => Define contour plotting routine
func_cont      = 'beam_fit_contour_plot'
;; => Define default contour plotting range
def_dfmin      = 1d-18
def_dfmax      = 1d-2
;; => Dummy error messages
noinpt_msg     = 'No input supplied...'
notstr_msg     = 'DAT must be an IDL structure...'
notvdf_msg     = 'DAT must be an ion velocity distribution IDL structure...'
;; => Position of contour plot [square]
;;               Xo    Yo    X1    Y1
pos_0con       = [0.22941,0.515,0.77059,0.915]
;; => Position of 1st DF cuts [square]
pos_0cut       = [0.22941,0.050,0.77059,0.450]
;;----------------------------------------------------------------------------------------
;; => Check input
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(data)  EQ 0) OR (N_PARAMS() NE 1)
IF (test) THEN BEGIN
  MESSAGE,noinpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF

str            = data[0]
test0          = test_wind_vs_themis_esa_struct(str,/NOM)
test           = (test0.(0) + test0.(1)) NE 1
IF (test) THEN BEGIN
  MESSAGE,notvdf_msg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check keywords
;;----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(fill)     THEN miss   = 1d-18       ELSE miss     = fill[0]
IF NOT KEYWORD_SET(perc_pk)  THEN perc   = 1d-2        ELSE perc     = perc_pk[0]
IF NOT KEYWORD_SET(plane)    THEN projxy = 'xy'        ELSE projxy   = STRLOWCASE(plane[0])
test           = ((projxy[0] EQ 'xy') OR (projxy[0] EQ 'xz') OR (projxy[0] EQ 'yz')) EQ 0
IF (test)                    THEN projxy = 'xy'
IF (projxy[0] EQ 'xz')       THEN gels   = [2L,0L]     ELSE gels     = [0L,1L]
;; => Define parameters
tag_pref       = ['DF2D','VELX','VELY','TR','VX_GRID','VY_GRID','GOOD_IND']
;;  Define suffix for structure tags
tagsuf         = '_'+STRUPCASE(projxy[0])
tags           = STRLOWCASE(tag_pref+tagsuf[0])

IF NOT KEYWORD_SET(sm_cont)  THEN scon   = 0           ELSE scon     = 1
IF NOT KEYWORD_SET(sm_cuts)  THEN sm_cut = 0           ELSE sm_cut   = 1
IF NOT KEYWORD_SET(nsmooth)  THEN ns     = 3           ELSE ns       = LONG(nsmooth)
;; => Define index
IF ~KEYWORD_SET(index)       THEN ind0   = 0L          ELSE ind0 = index[0]
;; => Define # of levels to use for contour.pro
IF ~KEYWORD_SET(ngrid)       THEN ngrid  = 30L

;IF (KEYWORD_SET(dfra) AND (N_ELEMENTS(dfra) EQ 2)) THEN dfra_in  = dfra
IF KEYWORD_SET(dfmin)        THEN dfmin_in = dfmin[0]
IF KEYWORD_SET(dfmax)        THEN dfmax_in = dfmax[0]

IF NOT KEYWORD_SET(save_dir) THEN sdir   = defdir      ELSE sdir     = save_dir[0]
;; Check for trailing slash
test = STRMID(sdir[0],0,/REVERSE_OFFSET)
IF (test[0] NE '/' AND test[0] NE '\') THEN sdir = sdir[0]+slash[0]
;; => Define default prefix and mid-section of file name
def_pref       = 'DF_'+STRING(ind0[0],FORMAT='(I4.4)')+'_'
def_midf       = xy_suff[0]+STRING(ngrid[0],FORMAT='(I4.4)')+'Grids_'
;; => Define plot file name pre-prefix and mid-section
IF ~KEYWORD_SET(file_pref)   THEN pref0  = def_pref[0] ELSE pref0    = file_pref[ind0[0]]
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
;; => Define plot file name prefix
pref           = pref0[0]+midf[0]
;;----------------------------------------------------------------------------------------
;; => Make copies of DAT
;;----------------------------------------------------------------------------------------
dat            = data[ind0]
dat_orig       = dat[0]
dat_core       = dat[0]
dat_halo       = dat[0]
dat_beam       = dat[0]
dat_mask       = dat[0]
;;----------------------------------------------------------------------------------------
;; => Open Plot Windows
;;----------------------------------------------------------------------------------------
;; Define Window titles
w_tt_suff      = [' [Core Bulk Frame]',' [Core Bulk Frame]',' [Core Bulk Frame]',$
                  ' [Beam Bulk Frame]']
wttls          = ['Entire Distribution','Halo Distribution','Beam Cuts',$
                  'Beam Distribution']+w_tt_suff
wilims         = win_setup_beamfit(WTITLE=wttls)
;;----------------------------------------------------------------------------------------
;; => Reset input/output
;;----------------------------------------------------------------------------------------
delete_variable,plot_str,vlim_out,dfra_out,dfmin_out,dfmax_out,vb_reg
delete_variable,dfpar_out,dfper_out,vpar_out,vper_out,df_out,vc_xoff,vc_yoff,model
;; => Clean up previous common block settings specific to each DF
specific_com    = ['vsw','vcmax','v_bx','v_by','vb_reg','vbmax']
beam_fit_keywords_init,dat,/CLEAN_UP,KEY_CLEAN=specific_com
;; => Define current value for VSW in common block
vsw            = dat_orig[0].VSW
beam_fit___set_common,'vsw',vsw,STATUS=status
;;----------------------------------------------------------------------------------------
;; => Add to output structure
;;----------------------------------------------------------------------------------------
;;  Populate output structure
str_element,data_out,'DAT.IDL_DIST.ORIG',dat_orig,/ADD_REPLACE
str_element,data_out,'DAT.IDL_DIST.CORE',dat_orig,/ADD_REPLACE
str_element,data_out,'DAT.IDL_DIST.HALO',dat_orig,/ADD_REPLACE
str_element,data_out,'DAT.IDL_DIST.BEAM.BULK_FRAME',dat_orig,/ADD_REPLACE
str_element,data_out,'DAT.IDL_DIST.BEAM.BEAM_FRAME',dat_orig,/ADD_REPLACE
str_element,data_out,'VELOCITY.ORIG.VSW',dat_orig.VSW,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;; => Plot original
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;========================================================================================
JUMP_STEP_1:
;;========================================================================================
;; Reset inputs/outputs
delete_variable,read_out,value_out,status,defined,name_out
delete_variable,vc_xoff,vc_yoff,model,vcirc
windn          = 1
beam_fit_change_parameter,data,INDEX=ind0,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vc_xoff,     $
                               VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,WINDN=windn,  $
                               PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                               DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                               DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                               VPER_OUT=vper_out,DATA_OUT=data_out,READ_OUT=name_out,    $
                               DAT_PLOT=dat_orig,ONE_C=1
;; => Check if user wishes to quit
IF (name_out EQ 'q') THEN BEGIN
  read_out = 'q'
  RETURN
ENDIF
;; Make sure the change was not a switch of index
test           = (name_out EQ 'next') OR (name_out EQ 'prev') OR (name_out EQ 'index')
IF (test) THEN BEGIN
  ;;  Delete output structure
  delete_variable,data_out
  ;;  Change index input and leave
  index          = ind0
  read_out       = name_out
  ;;  Return
  RETURN
ENDIF
;; => Redefine structure [in case user changed something]
dat            = dat_orig[0]
;; => Check if user changed VSW
new_vsw        = dat_orig[0].VSW
test           = TOTAL(new_vsw EQ vsw) NE 3
IF (test) THEN BEGIN
  ;;  Change VSW in each structure copy
  dat_orig.VSW   = new_vsw
  dat_core.VSW   = new_vsw
  dat_halo.VSW   = new_vsw
  dat_beam.VSW   = new_vsw
  dat_mask.VSW   = new_vsw
ENDIF
;;----------------------------------------------------------------------------------------
;; => Define plot file name
;;----------------------------------------------------------------------------------------
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(ns)) THEN ns = 3L
ns_str         = STRCOMPRESS(STRING(ns,FORMAT='(I2.2)'),/REMOVE_ALL)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_cut)) THEN BEGIN
  smct_sf = '_00pts-SM-Cuts'
ENDIF ELSE BEGIN
  smct_sf = '_'+ns_str[0]+'pts-SM-Cuts'
ENDELSE
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_con)) THEN BEGIN
  smco_sf = '_03pts-SM-Cont'
ENDIF ELSE BEGIN
  smco_sf = '_'+ns_str[0]+'pts-SM-Cont'
ENDELSE

df_ra_out      = [dfmin_out[0],dfmax_out[0]]
df_sfxa        = STRCOMPRESS(STRING(df_ra_out,FORMAT='(E10.1)'),/REMOVE_ALL)
df_suff        = 'DF_'+df_sfxa[0]+'-'+df_sfxa[1]
vlimsuf        = STRING(vlim_out[0],FORMAT='(I5.5)')+'km-s_'
suffix         = vlimsuf[0]+smct_sf[0]+smco_sf[0]+df_suff[0]
;;---------------------------------------------
;; => Reset/Fix file_midf
;;---------------------------------------------
ngrid          = beam_fit___get_common('ngrid',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then get defaults
  ngrid          = beam_fit___get_common('def_ngrid',DEFINED=defined)
ENDIF
def_val_str    = STRING(ngrid[0],FORMAT='(I2.2)')+'Grids_'
projxy         = beam_fit___get_common('plane',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then use default
  projxy    = 'xy'
ENDIF
test           = ((projxy[0] EQ 'xy') OR (projxy[0] EQ 'xz') OR (projxy[0] EQ 'yz')) EQ 0
IF (test) THEN projxy = 'xy'
CASE projxy[0] OF
  'xy'  :  file_midf = xy_suff[0]+def_val_str[0]
  'xz'  :  file_midf = xz_suff[0]+def_val_str[0]
  'yz'  :  file_midf = yz_suff[0]+def_val_str[0]
ENDCASE
beam_fit___set_common,'file_midf',file_midf,STATUS=status
;; => Define plot file name prefix
file_midf      = beam_fit___get_common('file_midf',DEFINED=defined)
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
pref           = pref0[0]+midf[0]
;; e.g. 'IESA_Burst_1998-08-09_0801x09.494_V1xV2xV1_vs_V1_30Grids_Entire_BulkFrame_Center-Cuts_02500km-s_00pts-SM-Cuts_03pts-SM-Cont_DF_1.0E-14-1.0E-08'
fname          = sdir[0]+pref[0]+'Entire_BulkFrame_Center-Cuts_'+suffix[0]
;;----------------------------------------------------------------------------------------
;; => Save Contour Plot
;;----------------------------------------------------------------------------------------
popen,fname[0],/PORT
  beam_fit_contour_plot,dat_orig,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vc_xoff,               $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
pclose
ps_fname       = fname[0]    ;; initialize PS_FNAME
;;----------------------------------------------------------------------------------------
;; => Add to output structure
;;----------------------------------------------------------------------------------------
projxy         = beam_fit___get_common('plane',DEFINED=defined)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
miss           = beam_fit___get_common('fill',DEFINED=defined)

prefs          = 'KEYWORDS.ORIG.'
str_element,data_out,prefs[0]+'PLANE',projxy,/ADD_REPLACE
str_element,data_out,prefs[0]+'NSMOOTH',ns,/ADD_REPLACE
str_element,data_out,prefs[0]+'SM_CUTS',sm_cut,/ADD_REPLACE
str_element,data_out,prefs[0]+'SM_CONT',sm_con,/ADD_REPLACE
str_element,data_out,prefs[0]+'FILL',miss,/ADD_REPLACE
str_element,data_out,prefs[0]+'VLIM',vlim_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFRA',dfra_in,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFMIN',df_min_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFMAX',df_max_out,/ADD_REPLACE
;;========================================================================================
JUMP_STEP_2:
;;========================================================================================
str_element,data_out,'DAT.IDL_DIST.ORIG',dat_orig,/ADD_REPLACE
str_element,data_out,'VELOCITY.ORIG.VSW',dat_orig.VSW,/ADD_REPLACE

str_element,data_out,'DAT.DF.ORIG.'+tags[0],df_out,/ADD_REPLACE
str_element,data_out,'DAT.DF.ORIG.'+tags[4],vpar_out,/ADD_REPLACE
str_element,data_out,'DAT.DF.ORIG.'+tags[5],vper_out,/ADD_REPLACE
str_element,data_out,'DAT.DF.ORIG.DFPARA',dfpar_out,/ADD_REPLACE
str_element,data_out,'DAT.DF.ORIG.DFPERP',dfper_out,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;; => Find Vcmax
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
true           = 1
vcmax          = 0d0  ;; initialization of max "core" speed
WHILE (true) DO BEGIN
  ;; Define parameters
  windn          = 1
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  WHILE (read_out NE 'y' AND read_out NE 'q') DO BEGIN
    ;;====================================================================================
    JUMP_VCMAX_AGAIN:
    ;;====================================================================================
    ;; Reset inputs/outputs
    delete_variable,name_out,new_value,old_value,defined
    ;; Define parameters
    windn          = 1
    ;;------------------------------------------------------------------------------------
    ;;  Plot to initialize PLOT_STR keyword
    ;;------------------------------------------------------------------------------------
    WSET,windn[0]
    WSHOW,windn[0]
    beam_fit_contour_plot,dat_orig,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vc_xoff,               $
                                  VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                  PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                  DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                  DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                  VPER_OUT=vper_out
    ;;------------------------------------------------------------------------------------
    ;;  Call prompting routine
    ;;------------------------------------------------------------------------------------
    WSET,windn[0]
    WSHOW,windn[0]
    ;; Prompt options
    read_in        = 'vcmax'
    beam_fit_options,data,read_in,INDEX=ind0,WINDN=windn,PLOT_STR=plot_str, $
                                  READ_OUT=name_out,VALUE_OUT=new_value,    $
                                  OLD_VALUE=old_value
    ;; => Check if user wishes to quit
    IF (name_out EQ 'q') THEN BEGIN
      read_out = 'q'
      RETURN
    ENDIF
    ;; => Get VCMAX
    vcmax_00       = beam_fit___get_common('vcmax',DEFINED=defined)
    ;;------------------------------------------------------------------------------------
    ;;  Plot results and ask if okay
    ;;------------------------------------------------------------------------------------
    WSET,windn[0]
    WSHOW,windn[0]
    beam_fit_contour_plot,dat_orig,VCIRC=vcmax_00,VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                  VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                  PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                  DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                  DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                  VPER_OUT=vper_out
    ;;------------------------------------------------------------------------------------
    ;;  Ask if okay
    ;;------------------------------------------------------------------------------------
    pro_out        = ["[Type 'q' to quit at any time]"]
    str_out        = "Does the black circle encompass all [or enough] of the core (y/n)?  "
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,WINDN=windn,FORM_OUT=7)
    ;; => Check if user wishes to quit
    IF (name_out EQ 'q') THEN BEGIN
      read_out = 'q'
      RETURN
    ENDIF
    IF (read_out EQ 'debug') THEN STOP
    IF (read_out EQ 'n') THEN BEGIN
      ;;  User does not like original guess
      ;;  Reset output
      read_out       = ''    ;; output value of decision
      IF (N_ELEMENTS(old_value) NE 0) THEN vcmax_old = old_value[0]
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;; => Get VCMAX
    ;;------------------------------------------------------------------------------------
    new_value  = beam_fit___get_common('vcmax',DEFINED=defined)
    IF (defined EQ 0) THEN BEGIN
      ;; somehow it didn't get defined
      ;;   => Reset output
      read_out       = ''    ;; output value of decision
      ;; Jump back until this variable gets defined
      GOTO,JUMP_VCMAX_AGAIN
    ENDIF ELSE BEGIN
      vcmax          = new_value[0]
    ENDELSE
    ;;  Keep track of old value
    test           = (read_out EQ 'y') AND (N_ELEMENTS(vcmax_old) EQ 0) AND $
                     (N_ELEMENTS(old_value) NE 0)
    IF (test) THEN vcmax_old = old_value[0]
    ;;  If leaving, make sure VCMAX is set/defined
    test           = (read_out EQ 'y') AND (N_ELEMENTS(vcmax) EQ 0)
    IF (test) THEN BEGIN
      ;; See if we can get VCMAX from common block
      new_value      = beam_fit___get_common('vcmax',DEFINED=defined)
      IF (defined EQ 0) THEN BEGIN
        ;; Failed
        read_out       = ''    ;; output value of decision
        ;; Jump back until this variable gets defined
        GOTO,JUMP_VCMAX_AGAIN
      ENDIF ELSE BEGIN
        ;; Success!
        vcmax          = new_value[0]
      ENDELSE
    ENDIF
  ENDWHILE
  ;;--------------------------------------------------------------------------------------
  ;;  Vcmax accepted for now, so create mask and plot "halo" only
  ;;--------------------------------------------------------------------------------------
  ;; => Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;; => Reset "core" and "halo" data
  dfdata         = dat_mask.DATA
  dat_core.DATA  = dfdata
  dat_halo.DATA  = dfdata
  ;;--------------------------------------------------------------------------------------
  ;;  Create mask
  ;;--------------------------------------------------------------------------------------
  v_thresh       = vcmax[0]
  v_uv           = 50e1     ;; related to UV contamination
  mask_aa        = remove_uv_and_beam_ions(dat_halo,V_THRESH=v_thresh[0],V_UV=v_uv[0])
  dfdata        *= mask_aa
  ;;  Apply mask to halo data
  dat_core.DATA  = dfdata
  dat_halo.DATA  = dat_halo.DATA - dfdata
  ;;--------------------------------------------------------------------------------------
  ;;  Plot "halo" only
  ;;--------------------------------------------------------------------------------------
  ;; Define parameters
  windn          = 2
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_halo,VCIRC=vcmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  ;;--------------------------------------------------------------------------------------
  ;;  Ask if Vcmax estimate is okay
  ;;--------------------------------------------------------------------------------------
  vcmax_str      = STRTRIM(STRING(vcmax[0],FORMAT='(f25.2)'),2L)
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  pro_out        = ["[Type 'q' to quit at any time]"]
  WHILE (read_out NE 'y' AND read_out NE 'q' AND read_out NE 'n') DO BEGIN
    str_out        = "Did your estimate of Vcmax ("+vcmax_str[0]+$
                     " km/s) remove all [or enough] of the core (y/n)?  "
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,WINDN=windn,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
    IF (read_out EQ 'n') THEN BEGIN
      ;;  User does not think so
      ;;  Reset output
      read_out       = ''    ;; output value of decision
      vcmax_old      = vcmax[0]
      ;;  Jump back
      GOTO,JUMP_VCMAX_AGAIN
    ENDIF
  ENDWHILE
  ;; => Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;--------------------------------------------------------------------------------------
  ;; => User was pleased with results
  ;;--------------------------------------------------------------------------------------
  ;; allow to leave
  true           = 0
ENDWHILE
;;----------------------------------------------------------------------------------------
;; => Check if user wants to change any of the plot ranges
;;----------------------------------------------------------------------------------------
old_vsw        = dat_halo[0].VSW
windn          = 2
beam_fit_change_parameter,data,INDEX=ind0,VCIRC=vcmax,VB_REG=vb_reg,VC_XOFF=vc_xoff,     $
                               VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,WINDN=windn,  $
                               PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                               DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                               DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                               VPER_OUT=vper_out,DATA_OUT=data_out,READ_OUT=name_out,    $
                               DAT_PLOT=dat_halo,ONE_C=1
;; => Check if user wishes to quit
IF (name_out EQ 'q') THEN BEGIN
  read_out = 'q'
  RETURN
ENDIF
;; Make sure the change was not a switch of index
test           = (name_out EQ 'next') OR (name_out EQ 'prev') OR (name_out EQ 'index')
IF (test) THEN BEGIN
  ;;  Delete output structure
  delete_variable,data_out
  ;;  Change index input and leave
  index          = ind0
  read_out       = name_out
  ;;  Return
  RETURN
ENDIF
;; => Check if user changed VSW
new_vsw        = dat_halo[0].VSW
test           = TOTAL(new_vsw EQ old_vsw) NE 3
IF (test) THEN BEGIN
  ;;  Change VSW in each structure copy
  dat_orig.VSW   = new_vsw
  dat_core.VSW   = new_vsw
  dat_halo.VSW   = new_vsw
  dat_beam.VSW   = new_vsw
  dat_mask.VSW   = new_vsw
ENDIF
;;----------------------------------------------------------------------------------------
;; => Define plot file name
;;----------------------------------------------------------------------------------------
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(ns)) THEN ns = 3L
ns_str         = STRCOMPRESS(STRING(ns,FORMAT='(I2.2)'),/REMOVE_ALL)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_cut)) THEN BEGIN
  smct_sf = '_00pts-SM-Cuts'
ENDIF ELSE BEGIN
  smct_sf = '_'+ns_str[0]+'pts-SM-Cuts'
ENDELSE
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_con)) THEN BEGIN
  smco_sf = '_03pts-SM-Cont'
ENDIF ELSE BEGIN
  smco_sf = '_'+ns_str[0]+'pts-SM-Cont'
ENDELSE

df_ra_out      = [dfmin_out[0],dfmax_out[0]]
df_sfxa        = STRCOMPRESS(STRING(df_ra_out,FORMAT='(E10.1)'),/REMOVE_ALL)
df_suff        = 'DF_'+df_sfxa[0]+'-'+df_sfxa[1]
vlimsuf        = STRING(vlim_out[0],FORMAT='(I5.5)')+'km-s_'
suffix         = vlimsuf[0]+smct_sf[0]+smco_sf[0]+df_suff[0]
;;---------------------------------------------
;; => Reset/Fix file_midf
;;---------------------------------------------
ngrid          = beam_fit___get_common('ngrid',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then get defaults
  ngrid          = beam_fit___get_common('def_ngrid',DEFINED=defined)
ENDIF
def_val_str    = STRING(ngrid[0],FORMAT='(I2.2)')+'Grids_'
projxy         = beam_fit___get_common('plane',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then use default
  projxy    = 'xy'
ENDIF
test           = ((projxy[0] EQ 'xy') OR (projxy[0] EQ 'xz') OR (projxy[0] EQ 'yz')) EQ 0
IF (test) THEN projxy = 'xy'
CASE projxy[0] OF
  'xy'  :  file_midf = xy_suff[0]+def_val_str[0]
  'xz'  :  file_midf = xz_suff[0]+def_val_str[0]
  'yz'  :  file_midf = yz_suff[0]+def_val_str[0]
ENDCASE
beam_fit___set_common,'file_midf',file_midf,STATUS=status
;; => Define plot file name prefix
file_midf      = beam_fit___get_common('file_midf',DEFINED=defined)
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
pref           = pref0[0]+midf[0]
;; e.g. 'IESA_Burst_1998-08-09_0801x09.494_V1xV2xV1_vs_V1_30Grids_Halo_BulkFrame_Center-Cuts_02500km-s_00pts-SM-Cuts_03pts-SM-Cont_DF_1.0E-14-1.0E-08'
fname          = sdir[0]+pref[0]+'Halo_BulkFrame_Center-Cuts_'+suffix[0]
;;----------------------------------------------------------------------------------------
;; => Save Contour Plot
;;----------------------------------------------------------------------------------------
popen,fname[0],/PORT
  beam_fit_contour_plot,dat_halo,VCIRC=vcmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
pclose
ps_fname       = [fname[0],ps_fname]    ;; add to PS_FNAME
;;----------------------------------------------------------------------------------------
;; => Add to output structure
;;----------------------------------------------------------------------------------------
projxy         = beam_fit___get_common('plane',DEFINED=defined)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
miss           = beam_fit___get_common('fill',DEFINED=defined)

prefs          = 'KEYWORDS.HALO.'
str_element,data_out,prefs[0]+'PLANE',projxy,/ADD_REPLACE
str_element,data_out,prefs[0]+'NSMOOTH',ns,/ADD_REPLACE
str_element,data_out,prefs[0]+'SM_CUTS',sm_cut,/ADD_REPLACE
str_element,data_out,prefs[0]+'SM_CONT',sm_con,/ADD_REPLACE
str_element,data_out,prefs[0]+'FILL',miss,/ADD_REPLACE
str_element,data_out,prefs[0]+'VLIM',vlim_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFRA',dfra_in,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFMIN',df_min_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFMAX',df_max_out,/ADD_REPLACE
;;========================================================================================
JUMP_STEP_3:
;;========================================================================================
str_element,data_out,'DAT.IDL_DIST.CORE',dat_core,/ADD_REPLACE
str_element,data_out,'DAT.IDL_DIST.HALO',dat_halo,/ADD_REPLACE
str_element,data_out,'MASKS.CORE',mask_aa,/ADD_REPLACE

str_element,data_out,'VELOCITY.CORE.VSW',dat_core.VSW,/ADD_REPLACE
str_element,data_out,'VELOCITY.CORE.VCMAX',vcmax[0],/ADD_REPLACE

prefs          = 'DAT.DF.HALO.'
str_element,data_out,prefs[0]+tags[0],df_out,/ADD_REPLACE
str_element,data_out,prefs[0]+tags[4],vpar_out,/ADD_REPLACE
str_element,data_out,prefs[0]+tags[5],vper_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFPARA',dfpar_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFPERP',dfper_out,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;; => Find "beam" peak
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
true           = 1
v_b_old        = [0d0,0d0]
WHILE (true) DO BEGIN
  ;; Define parameters
  windn          = 3
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  ;;--------------------------------------------------------------------------------------
  ;;  Plot "halo" DF
  ;;--------------------------------------------------------------------------------------
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_halo,VCIRC=vcmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  WHILE (read_out NE 'y' AND read_out NE 'q') DO BEGIN
    ;; Define parameters
    windn          = 3
    ;;------------------------------------------------------------------------------------
    ;;  Call prompting routine
    ;;------------------------------------------------------------------------------------
    read_in        = 'vbeam'
    beam_fit_options,data,read_in,INDEX=ind0,WINDN=windn,PLOT_STR=plot_str, $
                                  READ_OUT=name_out,VALUE_OUT=new_value,    $
                                  OLD_VALUE=old_value
    ;;  Check output
    v_bx           = beam_fit___get_common('v_bx',DEFINED=defined)
    v_by           = beam_fit___get_common('v_by',DEFINED=defined)
    ;;------------------------------------------------------------------------------------
    ;;  Plot results and ask if okay
    ;;------------------------------------------------------------------------------------
    WSET,windn[0]
    WSHOW,windn[0]
    beam_fit_contour_plot,dat_halo,VCIRC=vcmax_00,VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                  VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                  PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                  DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                  DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                  VPER_OUT=vper_out
    ;;------------------------------------------------------------------------------------
    ;;  Ask if okay
    ;;------------------------------------------------------------------------------------
    str_out        = "Do the crosshairs look centered on the peak of the 'beam' (y/n)?  "
    pro_out        = ["[Type 'q' to quit at any time]"]
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,WINDN=windn,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
    IF (read_out EQ 'n') THEN BEGIN
      ;;  User does not like original guess
      ;;  Reset output
      read_out       = ''    ;; output value of decision
      v_b_old        = [v_bx[0],v_by[0]]
    ENDIF
    IF (read_out EQ 'y' AND v_b_old[0] EQ 0 AND v_b_old[1] EQ 0) THEN v_b_old      = [v_bx[0],v_by[0]]
  ENDWHILE
  ;; => Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;--------------------------------------------------------------------------------------
  ;;  Re-plot "halo" with crosshairs on beam peak
  ;;--------------------------------------------------------------------------------------
  ;; Define parameters
  windn          = 3
  ;;  Plot
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_halo,VCIRC=vcmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  ;; allow to leave
  true           = 0
ENDWHILE
;;----------------------------------------------------------------------------------------
;; => Check if user wants to change any of the plot ranges
;;----------------------------------------------------------------------------------------
old_vsw        = dat_halo[0].VSW
windn          = 3
beam_fit_change_parameter,data,INDEX=ind0,VCIRC=vcmax,VB_REG=vb_reg,VC_XOFF=vc_xoff,     $
                               VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,WINDN=windn,  $
                               PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                               DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                               DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                               VPER_OUT=vper_out,DATA_OUT=data_out,READ_OUT=name_out,    $
                               DAT_PLOT=dat_halo,ONE_C=1
;; => Check if user wishes to quit
IF (name_out EQ 'q') THEN BEGIN
  read_out = 'q'
  RETURN
ENDIF
;; Make sure the change was not a switch of index
test           = (name_out EQ 'next') OR (name_out EQ 'prev') OR (name_out EQ 'index')
IF (test) THEN BEGIN
  ;;  Delete output structure
  delete_variable,data_out
  ;;  Change index input and leave
  index          = ind0
  read_out       = name_out
  ;;  Return
  RETURN
ENDIF
;; => Check if user changed VSW
new_vsw        = dat_halo[0].VSW
test           = TOTAL(new_vsw EQ old_vsw) NE 3
IF (test) THEN BEGIN
  ;;  Change VSW in each structure copy
  dat_orig.VSW   = new_vsw
  dat_core.VSW   = new_vsw
  dat_halo.VSW   = new_vsw
  dat_beam.VSW   = new_vsw
  dat_mask.VSW   = new_vsw
ENDIF
;;----------------------------------------------------------------------------------------
;; => Define plot file name
;;----------------------------------------------------------------------------------------
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(ns)) THEN ns = 3L
ns_str         = STRCOMPRESS(STRING(ns,FORMAT='(I2.2)'),/REMOVE_ALL)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_cut)) THEN BEGIN
  smct_sf = '_00pts-SM-Cuts'
ENDIF ELSE BEGIN
  smct_sf = '_'+ns_str[0]+'pts-SM-Cuts'
ENDELSE
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_con)) THEN BEGIN
  smco_sf = '_03pts-SM-Cont'
ENDIF ELSE BEGIN
  smco_sf = '_'+ns_str[0]+'pts-SM-Cont'
ENDELSE

df_ra_out      = [dfmin_out[0],dfmax_out[0]]
df_sfxa        = STRCOMPRESS(STRING(df_ra_out,FORMAT='(E10.1)'),/REMOVE_ALL)
df_suff        = 'DF_'+df_sfxa[0]+'-'+df_sfxa[1]
vlimsuf        = STRING(vlim_out[0],FORMAT='(I5.5)')+'km-s_'
suffix         = vlimsuf[0]+smct_sf[0]+smco_sf[0]+df_suff[0]
;;---------------------------------------------
;; => Reset/Fix file_midf
;;---------------------------------------------
ngrid          = beam_fit___get_common('ngrid',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then get defaults
  ngrid          = beam_fit___get_common('def_ngrid',DEFINED=defined)
ENDIF
def_val_str    = STRING(ngrid[0],FORMAT='(I2.2)')+'Grids_'
projxy         = beam_fit___get_common('plane',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then use default
  projxy    = 'xy'
ENDIF
test           = ((projxy[0] EQ 'xy') OR (projxy[0] EQ 'xz') OR (projxy[0] EQ 'yz')) EQ 0
IF (test) THEN projxy = 'xy'
CASE projxy[0] OF
  'xy'  :  file_midf = xy_suff[0]+def_val_str[0]
  'xz'  :  file_midf = xz_suff[0]+def_val_str[0]
  'yz'  :  file_midf = yz_suff[0]+def_val_str[0]
ENDCASE
beam_fit___set_common,'file_midf',file_midf,STATUS=status
;; => Define plot file name prefix
file_midf      = beam_fit___get_common('file_midf',DEFINED=defined)
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
pref           = pref0[0]+midf[0]
;; e.g. 'IESA_Burst_1998-08-09_0801x09.494_V1xV2xV1_vs_V1_30Grids_Halo_BulkFrame_Beam-Cuts_02500km-s_00pts-SM-Cuts_03pts-SM-Cont_DF_1.0E-14-1.0E-08'
fname          = sdir[0]+pref[0]+'Halo_BulkFrame_Beam-Cuts_'+suffix[0]
;;----------------------------------------------------------------------------------------
;; => Save Contour Plot
;;----------------------------------------------------------------------------------------
popen,fname[0],/PORT
  beam_fit_contour_plot,dat_halo,VCIRC=vcmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
pclose
ps_fname       = [fname[0],ps_fname]    ;; add to PS_FNAME
;;----------------------------------------------------------------------------------------
;; => Add to output structure
;;----------------------------------------------------------------------------------------
;;========================================================================================
JUMP_STEP_4:
;;========================================================================================
v_bx           = beam_fit___get_common('v_bx',DEFINED=defined)
v_by           = beam_fit___get_common('v_by',DEFINED=defined)

str_element,data_out,'VELOCITY.BEAM.BULK_FRAME.V_0X',v_bx[0],/ADD_REPLACE
str_element,data_out,'VELOCITY.BEAM.BULK_FRAME.V_0Y',v_by[0],/ADD_REPLACE

prefs          = 'DAT.DF.BEAM.BULK_FRAME.'
str_element,data_out,prefs[0]+tags[0],df_out,/ADD_REPLACE
str_element,data_out,prefs[0]+tags[4],vpar_out,/ADD_REPLACE
str_element,data_out,prefs[0]+tags[5],vper_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFPARA',dfpar_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFPERP',dfper_out,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;; => Find "beam" region [similar to VCMAX procedure]
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
vb_x_str       = STRTRIM(STRING(v_bx[0],FORMAT='(f25.2)'),2L)
vb_y_str       = STRTRIM(STRING(v_by[0],FORMAT='(f25.2)'),2L)
;; => Find "beam" frame and create new mask
dat_beam       = dat_halo[0]
true           = 1
;;                 X0  Y0  X1  Y1
vb_reg         = [0d0,0d0,0d0,0d0]
vb_reg_old     = [0d0,0d0,0d0,0d0]
vbmax          = 0d0  ;; initialization of max "beam" thermal speed
vbmax_old      = 0d0
v_bulk_old     = DBLARR(3L)  ;; Core Bulk Flow Frame Velocity
v_bulk_new     = DBLARR(3L)  ;; "Beam Frame" Bulk Flow Velocity
v_bulk_old     = dat_beam[0].VSW
vbulk_c        = data_out.VELOCITY.ORIG.VSW
WHILE (true) DO BEGIN
  ;; Define parameters
  windn          = 4
  ;;--------------------------------------------------------------------------------------
  ;;  Reset plotting parameters
  ;;--------------------------------------------------------------------------------------
  ;;  Unset bulk velocity
  beam_fit_unset_common,'vsw',STATUS=status
  ;; Unset VBMAX keyword
  beam_fit_unset_common,'vbmax',STATUS=status
  ;;  Reset center of circle position
  delete_variable,vc_xoff,vc_yoff,vcirc
  ;;--------------------------------------------------------------------------------------
  ;;  Plot "halo" DF [no VCIRC]
  ;;--------------------------------------------------------------------------------------
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=0d0,VB_REG=vb_reg,VC_XOFF=vc_xoff,                 $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  ;;--------------------------------------------------------------------------------------
  ;; => Inform user of procedure
  ;;--------------------------------------------------------------------------------------
  ;; Define string outputs for procedural information
  pro_out        = ["     You will now be asked whether you wish to enter a single",$
                    "velocity radius of a circle that would encompass the entire 'beam'",$
                    "or to use the mouse cursor to define a region that would encompass",$
                    "the entire 'beam'.  The circle will be centered on the crosshairs",$
                    "[at ("+vb_x_str[0]+", "+vb_y_str[0]+") km/s] you determined in the previous step.",$
                    "     Thus, if you choose the 2nd option, the velocity radius of the",$
                    "circle will be found from the average distance between the four",$
                    "corners selected and the center."]
  info_out       = beam_fit_gen_prompt(PRO_OUT=pro_out,FORM_OUT=7)
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  read_out2      = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  WHILE (read_out NE 'y' AND read_out NE 'q') DO BEGIN
    ;;====================================================================================
    JUMP_VBMAX_AGAIN:
    ;;====================================================================================
    ;; => Reset "beam" data
    dat_beam       = dat_halo[0]
    ;;------------------------------------------------------------------------------------
    ;;  Call prompting routine
    ;;------------------------------------------------------------------------------------
    WSET,windn[0]
    WSHOW,windn[0]
    ;; Prompt options
    read_in        = 'vbmax'
    beam_fit_options,data,read_in,INDEX=ind0,WINDN=windn,PLOT_STR=plot_str, $
                                  READ_OUT=name_out,VALUE_OUT=new_value,    $
                                  OLD_VALUE=old_value
    ;; => Check if user wishes to quit
    IF (name_out EQ 'q') THEN BEGIN
      read_out = 'q'
      RETURN
    ENDIF
    IF (name_out EQ 'debug') THEN STOP
    ;; => Get VBMAX
    vbmax_00       = beam_fit___get_common('vbmax',DEFINED=defined)
    ;; Define the offsets for the center of the circle
    vc_xoff        = v_bx[0]
    vc_yoff        = v_by[0]
    ;;------------------------------------------------------------------------------------
    ;;  Plot results
    ;;------------------------------------------------------------------------------------
    WSET,windn[0]
    WSHOW,windn[0]
    beam_fit_contour_plot,dat_beam,VCIRC=vbmax_00[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,         $
                                  VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                  PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                  DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                  DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                  VPER_OUT=vper_out
    ;;------------------------------------------------------------------------------------
    ;;  Ask if okay
    ;;------------------------------------------------------------------------------------
    pro_out        = ["Make sure circle is entirely outside region of interest.",$
                      "","[Type 'q' to quit at any time]"]
    str_out        = "Does the black circle encompass all [or enough] of the 'beam' (y/n)?  "
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,WINDN=windn,FORM_OUT=7)
    ;; => Check if user wishes to quit
    IF (name_out EQ 'q') THEN BEGIN
      read_out = 'q'
      RETURN
    ENDIF
    IF (read_out EQ 'debug') THEN STOP
    IF (read_out EQ 'n') THEN BEGIN
      ;;  User does not like original guess
      ;;  Reset output
      read_out       = ''    ;; output value of decision
      IF (N_ELEMENTS(old_value) NE 0) THEN vbmax_old = old_value[0]
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;; => Get VBMAX
    ;;------------------------------------------------------------------------------------
    new_value  = beam_fit___get_common('vbmax',DEFINED=defined)
    IF (defined EQ 0) THEN BEGIN
      ;; somehow it didn't get defined
      ;;   => Reset output
      read_out       = ''    ;; output value of decision
      ;; Jump back until this variable gets defined
      GOTO,JUMP_VBMAX_AGAIN
    ENDIF ELSE BEGIN
      vbmax          = new_value[0]
    ENDELSE
    ;;------------------------------------------------------------------------------------
    ;;  Keep track of old value
    ;;------------------------------------------------------------------------------------
    test           = (read_out EQ 'y') AND (N_ELEMENTS(vbmax_old) EQ 0) AND $
                     (N_ELEMENTS(old_value) NE 0)
    IF (test) THEN vbmax_old = old_value[0]
    ;;  If leaving, make sure VBMAX is set/defined
    test           = (read_out EQ 'y') AND (N_ELEMENTS(vbmax) EQ 0)
    IF (test) THEN BEGIN
      ;; See if we can get VBMAX from common block
      new_value      = beam_fit___get_common('vbmax',DEFINED=defined)
      IF (defined EQ 0) THEN BEGIN
        ;; Failed
        read_out       = ''    ;; output value of decision
        ;; Jump back until this variable gets defined
        GOTO,JUMP_VBMAX_AGAIN
      ENDIF ELSE BEGIN
        ;; Success!
        vbmax          = new_value[0]
      ENDELSE
    ENDIF
  ENDWHILE
  ;;--------------------------------------------------------------------------------------
  ;;  VBMAX accepted for now, so create mask and plot "beam" only first
  ;;    If user likes, then shift to 'beam' frame and plot again
  ;;--------------------------------------------------------------------------------------
  ;; => Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;; => Reset "beam" data
  dat_copy       = dat_orig[0]
  data_h         = dat_halo[0].DATA
  dat_beam       = dat_halo[0]
  ;;--------------------------------------------------------------------------------------
  ;;  VBMAX accepted for now, so create mask and plot "beam" at center
  ;;--------------------------------------------------------------------------------------
  v_thresh       = vbmax[0]
  mask_bb        = find_beam_peak_and_mask(dat_beam,PLANE=projxy[0],V_0X=v_bx,V_0Y=v_by,$
                                           NSMOOTH=nsmooth,V_THRESH=v_thresh[0],$
                                           V_B_GSE=vb_gse)
  ;; => Apply mask to data
  data_h        *= mask_bb
  ;; => Change DATA tag in DAT_BEAM
  dat_beam.DATA  = data_h
  ;;--------------------------------------------------------------------------------------
  ;;  Plot "beam" in bulk frame
  ;;--------------------------------------------------------------------------------------
  ;; Define parameters
  windn          = 4
  ;;  Plot
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vbmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,/ONE_C,       $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  ;;--------------------------------------------------------------------------------------
  ;;  Ask if VBMAX estimate is okay
  ;;--------------------------------------------------------------------------------------
  vbmax_str      = STRTRIM(STRING(vbmax[0],FORMAT='(f25.2)'),2L)
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  str_out        = "Does your estimate of VBMAX ("+vbmax_str[0]+$
                   " km/s) encompass all [or enough] of the beam (y/n)?  "
  pro_out        = ["[Type 'q' to quit at any time]"]
  WHILE (read_out NE 'y' AND read_out NE 'q' AND read_out NE 'n') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,WINDN=windn,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
    IF (read_out EQ 'n') THEN BEGIN
      ;;  User does not think so
      ;;  Reset "beam" data
      dat_beam       = dat_halo[0]
      v_bx           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0X
      v_by           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0Y
      ;;  Reset center of "beam" peak offsets
      beam_fit___set_common,'v_bx',v_bx,STATUS=status
      beam_fit___set_common,'v_by',v_by,STATUS=status
      ;;  Reset output
      read_out       = ''    ;; output value of decision
      vbmax_old      = vbmax[0]
      vb_reg_old     = vb_reg
      ;;  Jump back
      GOTO,JUMP_VBMAX_AGAIN
    ENDIF
  ENDWHILE
  ;; => Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;--------------------------------------------------------------------------------------
  ;;  User was pleased with results
  ;;    => Plot masked results and check again
  ;;--------------------------------------------------------------------------------------
  ;; => Change VSW tag in DAT_BEAM
  dat_beam.VSW   = vb_gse
  ;;  Reset circle offsets
  vc_xoff        = 0d0
  vc_yoff        = 0d0
  ;;  Change center of "beam" peak to origin
  beam_fit___set_common,'v_bx',0d0,STATUS=status
  beam_fit___set_common,'v_by',0d0,STATUS=status
  ;;--------------------------------------------------------------------------------------
  ;;  Plot DF in "beam" frame
  ;;--------------------------------------------------------------------------------------
  ;; Define parameters
  windn          = 4
  ;;  Plot
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vbmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,              $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  ;;--------------------------------------------------------------------------------------
  ;;  Ask if VBMAX estimate is okay
  ;;--------------------------------------------------------------------------------------
  vbmax_str      = STRTRIM(STRING(vbmax[0],FORMAT='(f25.2)'),2L)
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  str_out        = "Are you still pleased with your estimate of VBMAX ("+vbmax_str[0]+$
                   " km/s) (y/n)?  "
  pro_out        = ["[Type 'q' to quit at any time]"]
  WHILE (read_out NE 'y' AND read_out NE 'q' AND read_out NE 'n') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,WINDN=windn,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
    IF (read_out EQ 'n') THEN BEGIN
      ;;  User does not think so
      ;;  Reset "beam" data
      dat_beam       = dat_halo[0]
      v_bx           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0X
      v_by           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0Y
      ;;  Reset center of "beam" peak offsets
      beam_fit___set_common,'v_bx',v_bx,STATUS=status
      beam_fit___set_common,'v_by',v_by,STATUS=status
      ;;  Reset output
      read_out       = ''    ;; output value of decision
      vbmax_old      = vbmax[0]
      vb_reg_old     = vb_reg
      ;;  Jump back
      GOTO,JUMP_VBMAX_AGAIN
    ENDIF
  ENDWHILE
  ;; => Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;--------------------------------------------------------------------------------------
  ;;  User was pleased with results
  ;;    => Re-plot masked results and move on
  ;;--------------------------------------------------------------------------------------
  ;; Define parameters
  windn          = 4
  ;;  Plot
  WSET,windn[0]
  WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vbmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,              $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
  ;; keep track of new "bulk" velocity
  v_bulk_new     = dat_beam[0].VSW
  ;; allow to leave
  true           = 0
ENDWHILE
;;----------------------------------------------------------------------------------------
;; => Check if user wants to change any of the plot ranges
;;----------------------------------------------------------------------------------------
old_vsw        = dat_beam[0].VSW
windn          = 4
beam_fit_change_parameter,data,INDEX=ind0,VCIRC=vbmax,VB_REG=vb_reg,VC_XOFF=vc_xoff,     $
                               VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,WINDN=windn,  $
                               PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                               DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                               DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                               VPER_OUT=vper_out,DATA_OUT=data_out,READ_OUT=name_out,    $
                               DAT_PLOT=dat_beam,ONE_C=0
;; => Check if user wishes to quit
IF (name_out EQ 'q') THEN BEGIN
  read_out = 'q'
  RETURN
ENDIF
;; Make sure the change was not a switch of index
test           = (name_out EQ 'next') OR (name_out EQ 'prev') OR (name_out EQ 'index')
IF (test) THEN BEGIN
  ;;  Delete output structure
  delete_variable,data_out
  ;;  Change index input and leave
  index          = ind0
  read_out       = name_out
  ;;  Return
  RETURN
ENDIF
;; => Check if user changed VSW
new_vsw        = dat_beam[0].VSW
test           = TOTAL(new_vsw EQ old_vsw) NE 3
IF (test) THEN BEGIN
  ;;  Change VSW in ONLY beam structure
  dat_beam.VSW   = new_vsw
ENDIF
;;----------------------------------------------------------------------------------------
;; => Define plot file name [Beam Only in Core Bulk Frame]
;;----------------------------------------------------------------------------------------
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(ns)) THEN ns = 3L
ns_str         = STRCOMPRESS(STRING(ns,FORMAT='(I2.2)'),/REMOVE_ALL)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_cut)) THEN BEGIN
  smct_sf = '_00pts-SM-Cuts'
ENDIF ELSE BEGIN
  smct_sf = '_'+ns_str[0]+'pts-SM-Cuts'
ENDELSE
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_con)) THEN BEGIN
  smco_sf = '_03pts-SM-Cont'
ENDIF ELSE BEGIN
  smco_sf = '_'+ns_str[0]+'pts-SM-Cont'
ENDELSE

df_ra_out      = [dfmin_out[0],dfmax_out[0]]
df_sfxa        = STRCOMPRESS(STRING(df_ra_out,FORMAT='(E10.1)'),/REMOVE_ALL)
df_suff        = 'DF_'+df_sfxa[0]+'-'+df_sfxa[1]
vlimsuf        = STRING(vlim_out[0],FORMAT='(I5.5)')+'km-s_'
suffix         = vlimsuf[0]+smct_sf[0]+smco_sf[0]+df_suff[0]
;;---------------------------------------------
;; => Reset/Fix file_midf
;;---------------------------------------------
ngrid          = beam_fit___get_common('ngrid',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then get defaults
  ngrid          = beam_fit___get_common('def_ngrid',DEFINED=defined)
ENDIF
def_val_str    = STRING(ngrid[0],FORMAT='(I2.2)')+'Grids_'
projxy         = beam_fit___get_common('plane',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then use default
  projxy    = 'xy'
ENDIF
test           = ((projxy[0] EQ 'xy') OR (projxy[0] EQ 'xz') OR (projxy[0] EQ 'yz')) EQ 0
IF (test) THEN projxy = 'xy'
CASE projxy[0] OF
  'xy'  :  file_midf = xy_suff[0]+def_val_str[0]
  'xz'  :  file_midf = xz_suff[0]+def_val_str[0]
  'yz'  :  file_midf = yz_suff[0]+def_val_str[0]
ENDCASE
beam_fit___set_common,'file_midf',file_midf,STATUS=status
;; => Define plot file name prefix
file_midf      = beam_fit___get_common('file_midf',DEFINED=defined)
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
pref           = pref0[0]+midf[0]
;; e.g. 'IESA_Burst_1998-08-09_0801x09.494_V1xV2xV1_vs_V1_30Grids_Beam_BulkFrame_Beam-Cuts_02500km-s_00pts-SM-Cuts_03pts-SM-Cont_DF_1.0E-14-1.0E-08'
fname          = sdir[0]+pref[0]+'Beam_BulkFrame_Beam-Cuts_'+suffix[0]
;;----------------------------------------------------------------------------------------
;; => Save Contour Plot
;;----------------------------------------------------------------------------------------
vobx           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0X
voby           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0Y
vc_xoff        = vobx
vc_yoff        = voby
;;  Go back to core bulk frame and save
vbulk_b        = dat_beam.VSW
vbulk_c        = data_out.VELOCITY.ORIG.VSW
dat_beam.VSW   = vbulk_c  ;; Reset beam VSW to bulk frame
popen,fname[0],/PORT
  ;;  Reset center of "beam" peak offsets
  beam_fit___set_common,'v_bx',v_bx,STATUS=status
  beam_fit___set_common,'v_by',v_by,STATUS=status
  ;;  Reset core bulk speed
  beam_fit___set_common,'vsw',vbulk_c,STATUS=status
  beam_fit_contour_plot,dat_beam,VCIRC=vbmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,ONE_C=1,      $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
pclose
ps_fname       = [fname[0],ps_fname]    ;; add to PS_FNAME
;;----------------------------------------------------------------------------------------
;; => Define plot file name [Beam Only in Beam Bulk Frame]
;;----------------------------------------------------------------------------------------
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(ns)) THEN ns = 3L
ns_str         = STRCOMPRESS(STRING(ns,FORMAT='(I2.2)'),/REMOVE_ALL)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_cut)) THEN BEGIN
  smct_sf = '_00pts-SM-Cuts'
ENDIF ELSE BEGIN
  smct_sf = '_'+ns_str[0]+'pts-SM-Cuts'
ENDELSE
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_con)) THEN BEGIN
  smco_sf = '_03pts-SM-Cont'
ENDIF ELSE BEGIN
  smco_sf = '_'+ns_str[0]+'pts-SM-Cont'
ENDELSE

df_ra_out      = [dfmin_out[0],dfmax_out[0]]
df_sfxa        = STRCOMPRESS(STRING(df_ra_out,FORMAT='(E10.1)'),/REMOVE_ALL)
df_suff        = 'DF_'+df_sfxa[0]+'-'+df_sfxa[1]
vlimsuf        = STRING(vlim_out[0],FORMAT='(I5.5)')+'km-s_'
suffix         = vlimsuf[0]+smct_sf[0]+smco_sf[0]+df_suff[0]
;; => Define plot file name prefix
file_midf      = beam_fit___get_common('file_midf',DEFINED=defined)
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
pref           = pref0[0]+midf[0]
;; e.g. 'IESA_Burst_1998-08-09_0801x09.494_V1xV2xV1_vs_V1_30Grids_Beam_BeamFrame_Beam-Cuts_02500km-s_00pts-SM-Cuts_03pts-SM-Cont_DF_1.0E-14-1.0E-08'
fname          = sdir[0]+pref[0]+'Beam_BeamFrame_Beam-Cuts_'+suffix[0]
;;----------------------------------------------------------------------------------------
;; => Save Contour Plot
;;----------------------------------------------------------------------------------------
vc_xoff        = 0d0
vc_yoff        = 0d0
;;  Go back to "beam" bulk frame
dat_beam.VSW   = vbulk_b
popen,fname[0],/PORT
  ;;  Reset center of "beam" peak offsets
  beam_fit___set_common,'v_bx',0d0,STATUS=status
  beam_fit___set_common,'v_by',0d0,STATUS=status
  ;;  Reset core bulk speed
  beam_fit___set_common,'vsw',vbulk_b,STATUS=status
  beam_fit_contour_plot,dat_beam,VCIRC=vbmax[0],VB_REG=vb_reg,VC_XOFF=vc_xoff,            $
                                VC_YOFF=vc_yoff,MODEL=model,EX_VECN=ex_vecn,ONE_C=0,      $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
pclose
ps_fname       = [fname[0],ps_fname]    ;; add to PS_FNAME
;;----------------------------------------------------------------------------------------
;; => Add to output structure
;;----------------------------------------------------------------------------------------
projxy         = beam_fit___get_common('plane',DEFINED=defined)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
miss           = beam_fit___get_common('fill',DEFINED=defined)

prefs          = 'KEYWORDS.BEAM.'
str_element,data_out,prefs[0]+'PLANE',projxy,/ADD_REPLACE
str_element,data_out,prefs[0]+'NSMOOTH',ns,/ADD_REPLACE
str_element,data_out,prefs[0]+'SM_CUTS',sm_cut,/ADD_REPLACE
str_element,data_out,prefs[0]+'SM_CONT',sm_con,/ADD_REPLACE
str_element,data_out,prefs[0]+'FILL',miss,/ADD_REPLACE
str_element,data_out,prefs[0]+'VLIM',vlim_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFRA',dfra_in,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFMIN',df_min_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFMAX',df_max_out,/ADD_REPLACE


str_element,data_out,'DAT.IDL_DIST.BEAM.BULK_FRAME',dat_beam,/ADD_REPLACE
str_element,data_out,'MASKS.BEAM',mask_bb,/ADD_REPLACE
str_element,data_out,'VELOCITY.BEAM.VBMAX',vbmax[0],/ADD_REPLACE
str_element,data_out,'VELOCITY.BEAM.VB_REG',vb_reg,/ADD_REPLACE
str_element,data_out,'VELOCITY.BEAM.SC_FRAME.V_B_GSE',vb_gse,/ADD_REPLACE

prefs          = 'DAT.DF.BEAM.BEAM_FRAME.'
str_element,data_out,prefs[0]+tags[0],df_out,/ADD_REPLACE
str_element,data_out,prefs[0]+tags[4],vpar_out,/ADD_REPLACE
str_element,data_out,prefs[0]+tags[5],vper_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFPARA',dfpar_out,/ADD_REPLACE
str_element,data_out,prefs[0]+'DFPERP',dfper_out,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;; => Fit to "beam" peak
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;; => Ask user if they want to fit in "core" bulk frame or "beam" bulk frame
read_out       = ''
pro_out        = ["You will now be asked whether you want to fit the beam peak in the",$
                  "'beam' bulk frame or 'core' bulk frame.  The results should not",$
                  "differ drastically in regards to density and thermal speeds, but",$
                  "the fitting routine does appear to have less trouble when in the",$
                  "'beam' bulk frame.","","[Type 'q' to quit at any time]"]
str_out        = "To fit in the 'core' bulk frame type 'c', otherwise type 'b':  "
WHILE (read_out NE 'c' AND read_out NE 'b' AND read_out NE 'q') DO BEGIN
  read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
  IF (read_out EQ 'debug') THEN STOP
ENDWHILE
;; => Check if user wishes to quit
IF (read_out EQ 'q') THEN RETURN
;; => Determine the frame they wish to fit in
IF (read_out EQ 'c') THEN BEGIN
  ;;  Go back to "core" bulk frame for fitting
  ;;    => See if this reduces IDL contour closing errors/artifacts...
  dat_beam.VSW   = vbulk_c  ;; Reset beam VSW to bulk frame
  ;;  Reset center of "beam" peak offsets for "core" bulk frame
  vobx           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0X
  voby           = data_out.VELOCITY.BEAM.BULK_FRAME.V_0Y
  beam_fit___set_common,'v_bx',vobx,STATUS=status
  beam_fit___set_common,'v_by',voby,STATUS=status
  mid_str        = 'Beam_BulkFrame_Beam-Model-Cuts_'
  bframe         = 0
ENDIF ELSE BEGIN
  ;;  Reset center of "beam" peak offsets to zero
  dat_beam.VSW   = vbulk_b  ;; Reset beam VSW to bulk frame
  beam_fit___set_common,'v_bx',0d0,STATUS=status
  beam_fit___set_common,'v_by',0d0,STATUS=status
  mid_str        = 'Beam_BeamFrame_Beam-Model-Cuts_'
  bframe         = 1
ENDELSE
;; => Define plot params
windn          = 4
dat_mom        = dat_beam[0]
;; => Fit and plot
beam_fit_fit_wrapper,dat_mom,VCIRC=vbmax[0],EX_VECN=ex_vecn,WINDN=windn,  $
                             DATA_OUT=data_out,READ_OUT=read_out,         $
                             PLOT_STR=plot_str,MODEL_OUT=fv_cuts,         $
                             BFRAME=bframe
;; => Check if user wishes to quit
IF (read_out EQ 'q') THEN RETURN
;;----------------------------------------------------------------------------------------
;; => Define plot file name
;;----------------------------------------------------------------------------------------
ns             = beam_fit___get_common('nsmooth',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(ns)) THEN ns = 3L
ns_str         = STRCOMPRESS(STRING(ns,FORMAT='(I2.2)'),/REMOVE_ALL)
sm_cut         = beam_fit___get_common('sm_cuts',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_cut)) THEN BEGIN
  smct_sf = '_00pts-SM-Cuts'
ENDIF ELSE BEGIN
  smct_sf = '_'+ns_str[0]+'pts-SM-Cuts'
ENDELSE
sm_con         = beam_fit___get_common('sm_cont',DEFINED=defined)
IF (defined EQ 0 OR ~KEYWORD_SET(sm_con)) THEN BEGIN
  smco_sf = '_03pts-SM-Cont'
ENDIF ELSE BEGIN
  smco_sf = '_'+ns_str[0]+'pts-SM-Cont'
ENDELSE

df_ra_out      = [dfmin_out[0],dfmax_out[0]]
df_sfxa        = STRCOMPRESS(STRING(df_ra_out,FORMAT='(E10.1)'),/REMOVE_ALL)
df_suff        = 'DF_'+df_sfxa[0]+'-'+df_sfxa[1]
vlimsuf        = STRING(vlim_out[0],FORMAT='(I5.5)')+'km-s_'
suffix         = vlimsuf[0]+smct_sf[0]+smco_sf[0]+df_suff[0]
;;---------------------------------------------
;; => Reset/Fix file_midf
;;---------------------------------------------
ngrid          = beam_fit___get_common('ngrid',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then get defaults
  ngrid          = beam_fit___get_common('def_ngrid',DEFINED=defined)
ENDIF
def_val_str    = STRING(ngrid[0],FORMAT='(I2.2)')+'Grids_'
projxy         = beam_fit___get_common('plane',DEFINED=defined)
IF (defined EQ 0) THEN BEGIN
  ;; => If not set, then use default
  projxy    = 'xy'
ENDIF
test           = ((projxy[0] EQ 'xy') OR (projxy[0] EQ 'xz') OR (projxy[0] EQ 'yz')) EQ 0
IF (test) THEN projxy = 'xy'
CASE projxy[0] OF
  'xy'  :  file_midf = xy_suff[0]+def_val_str[0]
  'xz'  :  file_midf = xz_suff[0]+def_val_str[0]
  'yz'  :  file_midf = yz_suff[0]+def_val_str[0]
ENDCASE
beam_fit___set_common,'file_midf',file_midf,STATUS=status
;; => Define plot file name prefix
file_midf      = beam_fit___get_common('file_midf',DEFINED=defined)
IF ~KEYWORD_SET(file_midf)   THEN midf   = def_midf[0] ELSE midf     = file_midf[0]
pref           = pref0[0]+midf[0]
;; e.g. 'IESA_Burst_1998-08-09_0801x09.494_V1xV2xV1_vs_V1_30Grids_Beam_BulkFrame_Beam-Model-Cuts_00pts-SM-Cuts_03pts-SM-Cont_02500km-s_DF_1.0E-14-1.0E-08'
fname          = sdir[0]+pref[0]+mid_str[0]+suffix[0]
;;----------------------------------------------------------------------------------------
;; => Save Contour Plot
;;----------------------------------------------------------------------------------------
popen,fname[0],/PORT
  ;; Define circle offsets
  vox_b          = fv_cuts.V_0_PARA
  voy_b          = fv_cuts.V_0_PERP
  ;; Plot contour and cuts
  beam_fit_contour_plot,dat_beam,VCIRC=vbmax[0],VB_REG=vb_reg,VC_XOFF=vox_b,              $
                                VC_YOFF=voy_b,MODEL=fv_cuts,EX_VECN=ex_vecn,ONE_C=0,      $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
pclose
;;----------------------------------------------------------------------------------------
;; => Return to user
;;----------------------------------------------------------------------------------------
ps_fname       = [fname[0],ps_fname]    ;; add to PS_FNAME

RETURN
END

