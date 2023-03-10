;+
;*****************************************************************************************
;
;  FUNCTION :   no_lab_scatter.pro
;  PURPOSE  :   This function used to stop labeling of tick marks for plotting over a
;                 previous plot.
;
;*****************************************************************************************
;-

FUNCTION no_lab_scatter, axis, index, t

RETURN, " "
END


;+
;*****************************************************************************************
;
;  FUNCTION :   scatter_plot_3d_input.pro
;  PURPOSE  :   This routine tests the formats the input values for scatter_plot_3d.pro
;
;  CALLED BY:   
;               scatter_plot_3d.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               [X,Y,Z]O    :  [N]-Element [float/double] array defining the
;                                [X,Y,Z]-offset of the center of all [N]-spheres
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               
;
;   CREATED:  01/25/2013
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  01/25/2013   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION scatter_plot_3d_input,xo,yo,zo

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;; => Dummy error messages
badinpt_msg    = 'Incorrect input supplied [test]...'
badstr_msg     = 'Incorrect input format...'
;;----------------------------------------------------------------------------------------
;; => Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 3) THEN BEGIN
  ;; => no input???
  MESSAGE,badinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;  Re-define parameters
xx             = REFORM(xo)
yy             = REFORM(yo)
zz             = REFORM(zo)

nx             = N_ELEMENTS(xx)
ny             = N_ELEMENTS(yy)
nz             = N_ELEMENTS(zz)
;;  Test input format
testxy         = (nx NE ny)
testxz         = (nx NE nz)
testzy         = (nz NE ny)
test           = testxy OR testxz OR testzy
IF (test) THEN BEGIN
  ;; => no input???
  MESSAGE,badstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;; => Return TRUE
;;----------------------------------------------------------------------------------------

RETURN,1
END


;+
;*****************************************************************************************
;
;  FUNCTION :   scatter_sphere_3d.pro
;  PURPOSE  :   This routine returns the position and sizes of spheres in 3-dimensions.
;
;  CALLED BY:   
;               scatter_plot_3d.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               [X,Y,Z]O    :  [N]-Element [float/double] array defining the
;                                [X,Y,Z]-offset of the center of all [N]-spheres
;               RAD[X,Y,Z]  :  Scalar [float/double] defining the [X,Y,Z]-radius of
;                                every sphere
;
;  EXAMPLES:    
;               sphr = scatter_sphere_3d(xo,yo,zo,radx,rady,radz)
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               
;
;   CREATED:  01/25/2013
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  01/25/2013   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION scatter_sphere_3d,xo,yo,zo,radx,rady,radz

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN

nn             = 100L
pp             = 2d0*!DPI*DINDGEN(nn)/(nn - 1L)
;; => Dummy error messages
badinpt_msg    = 'Incorrect input supplied...'
;;----------------------------------------------------------------------------------------
;; => Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 6) THEN BEGIN
  ;; => no input???
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;  Re-define parameters
xx             = REFORM(xo)
yy             = REFORM(yo)
zz             = REFORM(zo)
rx             = radx[0]*SIN(pp[*])
ry             = rady[0]*COS(pp[*])
rz             = radz[0]*COS(pp[*])
;;----------------------------------------------------------------------------------------
;; => Define spheres vector components
;;----------------------------------------------------------------------------------------
nx             = N_ELEMENTS(xx)
xs             = DBLARR(nx,nn)
ys             = DBLARR(nx,nn)
zs             = DBLARR(nx,nn)
sphere         = DBLARR(nx,3,nn)  ;;  [N,3,K]-Element array

testn          = (nx GT nn)       ;; which would require more for loop iterations
CASE testn[0] OF
  0L : BEGIN  ;;  Nx ??? N  => loop through Nx
    FOR j=0L, nx - 1L DO BEGIN
      xs[j,*]       = xx[j] + rx[*]
      ys[j,*]       = yy[j] + ry[*]
      zs[j,*]       = zz[j] + rz[*]
      sphere[j,0,*] = xs[j,*]
      sphere[j,1,*] = ys[j,*]
      sphere[j,2,*] = zs[j,*]
    ENDFOR
  END
  1L : BEGIN  ;;  Nx > N  => loop through N
    FOR j=0L, nn - 1L DO BEGIN
      xs[*,j]       = xx[*] + rx[j]
      ys[*,j]       = yy[*] + ry[j]
      zs[*,j]       = zz[*] + rz[j]
      temp          = [[xs[*,j]],[ys[*,j]],[zs[*,j]]]  ;;  [N,3]-Element array
      sphere[*,*,j] = temp
    ENDFOR
  END
ENDCASE
;;----------------------------------------------------------------------------------------
;; => Return to user
;;----------------------------------------------------------------------------------------
RETURN,sphere
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   scatter_plot_3d.pro
;  PURPOSE  :   This routine produces simple 3-dimensional scatter plots from 3 input
;                 arrays, each with [N]-elements
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               scatter_plot_3d_input.pro
;               plot_struct_format_test.pro
;               extract_tags.pro
;               eulermat.pro
;               scatter_sphere_3d.pro
;               str_element.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               X[1,2,3]     :  [N]-Element [float/double] array defining the
;                                 [X,Y,Z]-offset of the center of all [N]-spheres
;
;  EXAMPLES:    
;               ;;-------------------------------------------
;               ;;  Construct 3D helix
;               ;;-------------------------------------------
;               n = 100L
;               z = DINDGEN(n)/(n - 1L)
;               t = 2d0*!DPI*z
;               x = COS(t)
;               y = SIN(t)
;               ;;-------------------------------------------
;               ;;  Plot scatter plot and connect the dots
;               ;;-------------------------------------------
;               scatter_plot_3d,x,y,z,/CONNECT
;               ;;-------------------------------------------
;               ;;  Project down to the Z_min plane
;               ;;-------------------------------------------
;               scatter_plot_3d,x,y,z,/ZLINE
;
;  KEYWORDS:    
;               LABELS       :  [3]-Element [string] array defining the [X,Y,Z]-axis
;                                 plot titles
;                                 [ Default = ['X','Y','Z'] ]
;               [X,Y,Z]LINE  :  If set, program will plot the projection from the
;                                 data points to the [X,Y,Z]-plane
;                                 [ Default = FALSE ]
;               LIMIT        :  IDL limit structure used with PLOT.PRO keyword _EXTRA
;                                 [see IDL documentation for more details]
;               AXESROT      :  [2]-Element array of rotation angles [degrees] about the
;                                 X-Axis and then the Z-Axis
;                                 [e.g. AXESROT=[20.,-120.]]
;               CONNECT      :  If set, program will connect the dots
;                                 [ Default = FALSE ]
;               [X,Y,Z]LOG   :  If set, program will plot the natural log of the
;                                 [X,Y,Z]-data
;
;   CHANGED:  1)  Continued to write routine                        [01/28/2013   v1.0.0]
;
;   NOTES:      
;               1)  The routine current has a hard coded setting for
;                     AXESROT = [ 30 , -15 ]
;               2)  This routine is still very kludgy...
;
;   CREATED:  01/25/2013
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  01/28/2013   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO scatter_plot_3d,x1,x2,x3,LABELS=labels,XLINE=xline,YLINE=yline,ZLINE=zline,$
                             LIMIT=limit,AXESROT=axesrot,CONNECT=connect,      $
                             XLOG=xlog,YLOG=ylog,ZLOG=zlog

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Define the default sphere radius [normalized]
def_srad       = 0.25d0*1d0
;; => Define normalized plot axis ranges
xyra           = [-1d0,1d0]
po_00          = [0.00000001d0,0.99999999d0]
;;  Define the default plot limits structure
xyzsty         = 5L
dummy          = {TITLE:'XYZ-Scatter Plot',XTITLE:'X',YTITLE:'Y',ZTITLE:'Z',$
                  XSTYLE:xyzsty,YSTYLE:xyzsty,ZSTYLE:xyzsty,T3D:1,NODATA:1, $
                  XTICKLEN:1.0,YTICKLEN:1.0,XTHICK:0.01,YTHICK:0.01}
;;----------------------------------------------------------------------------------------
;; => Check input formats
;;----------------------------------------------------------------------------------------
test           = scatter_plot_3d_input(x1,x2,x3) EQ 0
IF (test) THEN RETURN

xx             = REFORM(x1)
yy             = REFORM(x2)
zz             = REFORM(x3)
nn             = N_ELEMENTS(xx)
;;----------------------------------------------------------------------------------------
;;      **** kludge ****
;;        => hard code in rotations to avoid issues with projections [fix later]
;;----------------------------------------------------------------------------------------
axesrot        = [1d0,-0.50d0]*3d1
;;----------------------------------------------------------------------------------------
;; => Check keywords
;;----------------------------------------------------------------------------------------
IF (N_ELEMENTS(axesrot) EQ 2) THEN axrot = 1 ELSE axrot = 0

IF (N_ELEMENTS(limit) EQ 0) THEN BEGIN
  ;;  LIMIT not set => use default
  lims = dummy
ENDIF ELSE BEGIN
  ;;  LIMIT set
  IF (SIZE(limit,/TYPE) NE 8) THEN BEGIN
    ;; Incorrect format => use default
    lims = dummy
  ENDIF ELSE BEGIN
    ;;  correct format --> test further
    lim0 = limit
    temp = plot_struct_format_test(lim0,/SURFACE,/REMOVE_BAD)
    IF (SIZE(temp,/TYPE) NE 8) THEN BEGIN
      ;; Incorrect format => use default
      lims = dummy
    ENDIF ELSE BEGIN
      ;;  correct format --> extract relevant tags from DUMMY
      extract_tags,lims,dummy,/PRESERVE  ;;  extract_tags, [new struct], [old struct]
      vecu = ['X','Y','Z']
      extract_tags,lims,temp,EXCEPT=[vecu+'STYLE',vecu+'TICKLEN',vecu+'THICK']
    ENDELSE
  ENDELSE
ENDELSE

IF KEYWORD_SET(xlog) THEN xlog = 1 ELSE xlog = 0
IF KEYWORD_SET(ylog) THEN ylog = 1 ELSE ylog = 0
IF KEYWORD_SET(zlog) THEN zlog = 1 ELSE zlog = 0
;;----------------------------------------------------------------------------------------
;;    ----SET UP THE PLOT WINDOW----
;;----------------------------------------------------------------------------------------
xyzp_win    = {X:!X,Y:!Y,Z:!Z,P:!P}
charsize0   = !P.CHARSIZE
region0     = !P.REGION
margs       = [1,1]
IF (STRLOWCASE(!D.NAME) EQ 'x') THEN BEGIN
  WINDOW,8,TITLE=vcname,XSIZE=1000L,YSIZE=1000L,YPOS=100L,XPOS=100L,RETAIN=2
  WSET,8
  WSHOW,8
  chsz        = 3.0   ;; => CHARSIZE
  thick0      = 1.0
  !X.MARGIN   = margs
  !Y.MARGIN   = margs
  !Z.MARGIN   = margs
ENDIF ELSE BEGIN
  chsz        = 2.5   ;; => CHARSIZE
  thick0      = 2.5
  !X.MARGIN   = margs
  !Y.MARGIN   = margs
  !Z.MARGIN   = [0,0]
ENDELSE
!P.MULTI    = 0
!P.REGION   = [0.,0.,1.,1.]

omargs      = [0,0]
!X.OMARGIN  = omargs
!Y.OMARGIN  = omargs
!Z.OMARGIN  = omargs
;;----------------------------------------------------------------------------------------
;;  Normalize each component separately
;;    =>  0 ??? |X| ??? 1
;;----------------------------------------------------------------------------------------
max_xyz        = [MAX(ABS(xx),/NAN),MAX(ABS(yy),/NAN),MAX(ABS(zz),/NAN)]
xxn            = xx/max_xyz[0]
yyn            = yy/max_xyz[1]
zzn            = zz/max_xyz[2]

xran           = [MIN(xx,/NAN),MAX(xx,/NAN)]
yran           = [MIN(yy,/NAN),MAX(yy,/NAN)]
zran           = [MIN(zz,/NAN),MAX(zz,/NAN)]
;; Expand range
fac            = 1.10
IF (xran[0] LT 0) THEN xran[0] *= fac[0] ELSE xran[0] /= fac[0]
IF (xran[1] LT 0) THEN xran[1] /= fac[0] ELSE xran[1] *= fac[0]
IF (yran[0] LT 0) THEN yran[0] *= fac[0] ELSE yran[0] /= fac[0]
IF (yran[1] LT 0) THEN yran[1] /= fac[0] ELSE yran[1] *= fac[0]
IF (zran[0] LT 0) THEN zran[0] *= fac[0] ELSE zran[0] /= fac[0]
IF (zran[1] LT 0) THEN zran[1] /= fac[0] ELSE zran[1] *= fac[0]
;;----------------------------------------------------------------------------------------
;; => Determine the dominant plane of the points
;;----------------------------------------------------------------------------------------
xsum           = TOTAL(ABS(xxn),/NAN)
ysum           = TOTAL(ABS(yyn),/NAN)
zsum           = TOTAL(ABS(zzn),/NAN)
asums          = [xsum,ysum,zsum]
asums          = asums/NORM(asums)
sp             = REVERSE(SORT(asums))
;; => Find the magnitude of the projection of the two largest components and test if
;;      value > 65%
tplane         = SQRT(asums[sp[0]]^2 + asums[sp[1]]^2) GT 0.65
testxy         = ((sp[0] EQ 0) OR (sp[0] EQ 1)) AND ((sp[1] EQ 0) OR (sp[1] EQ 1))
testxz         = ((sp[0] EQ 0) OR (sp[0] EQ 2)) AND ((sp[1] EQ 0) OR (sp[1] EQ 2))
testyz         = ((sp[0] EQ 1) OR (sp[0] EQ 2)) AND ((sp[1] EQ 1) OR (sp[1] EQ 2))
test           = WHERE([testxy, testxz, testyz],tt)
;; => Determine rotations for 3D axes
CASE test[0] OF
  0 : BEGIN
    ;; => Vector mostly in XY-Plane
    axr =  15d0   ; => rotation [deg] about graphed X-axis
    azr = -11d1   ; => " " Z-axis
  END
  1 : BEGIN
    ;; => Vector mostly in XZ-Plane
    axr =  20d0   ; => rotation [deg] about graphed X-axis
    azr = -12d1   ; => " " Z-axis
  END
  2 : BEGIN
    ;; => Vector mostly in YZ-Plane
    axr =  20d0   ; => rotation [deg] about graphed X-axis
    azr = -14d1   ; => " " Z-axis
  END
ENDCASE

;; => make sure user hasn't specified rotation angles to override defaults
IF KEYWORD_SET(axesrot) THEN BEGIN
  IF (axrot) THEN BEGIN
    axr = axesrot[0]
    azr = axesrot[1]
  ENDIF ELSE BEGIN
    errmssg = 'Incorrect keyword usage [AXESROT]:  Must be 2-Element array!'
    MESSAGE,errmssg,/INFORMATIONAL,/CONTINUE
    PRINT,''
    PRINT,'Using default values...'
  ENDELSE
ENDIF
PRINT,';; ', axr[0], azr[0]
;;----------------------------------------------------------------------------------------
;; => Define axes ranges and set up 3D coordinate mapping
;;      ** kludgy at the moment **
;;----------------------------------------------------------------------------------------
mxran          = MAX(ABS([xran,yran,zran]),/NAN)
rx             = def_srad[0]*MAX(ABS(xran),/NAN)/mxran[0]
ry             = def_srad[0]*MAX(ABS(yran),/NAN)/mxran[0]
rz             = def_srad[0]*MAX(ABS(zran),/NAN)/mxran[0]
;;  Re-scale radii according to rotations [rotate about Z then about X]
rad_vec        = REPLICATE(MAX(ABS([rx[0], ry[0], rz[0]]),/NAN),3L)
rotm           = eulermat(0d0,azr[0],axr[0],/DEG)
rot_vec        = ABS(REFORM(rotm ## rad_vec))
radx           = rot_vec[0]
rady           = rot_vec[1]
radz           = rot_vec[2]
;mxrad          = MIN(ABS([radx,rady,radz]),/NAN)
;radm           = SQRT(radx[0]^2 + rady[0]^2 + radz[0]^2)
radm           = 25d0
radx           = [0d0,1d0]*radx[0]/radm[0]
rady           = [0d0,1d0]*rady[0]/radm[0]
radz           = [0d0,1d0]*radz[0]/radm[0]
rads           = [radx[1],rady[1],radz[1]]
mnrad          = MIN(ABS(rads),/NAN,lrn)
mxrad          = MAX(ABS(rads),/NAN,lrx)
mdrad          = MEDIAN(ABS(rads))

SCALE3,XRANGE=xran,YRANGE=yran,ZRANGE=zran,AX=axr[0],AZ=azr[0]
;;  Convert to normalized coordinates
rad_xyz        = ABS(CONVERT_COORD(radx,rady,radz,/DATA,/TO_NORMAL,/T3D))
xyz            = TRANSPOSE([[xx],[yy],[zz]])
nor_xyz        = CONVERT_COORD(xyz,/DATA,/TO_NORMAL,/T3D)
xxn            = REFORM(nor_xyz[0,*])
yyn            = REFORM(nor_xyz[1,*])
zzn            = REFORM(nor_xyz[2,*])
;;  Determine size and location of spheres
;spheres        = scatter_sphere_3d(xx,yy,zz,radx[1],rady[1],radz[1])  ;;  [N,3,K]-Element array
;spheres        = scatter_sphere_3d(xxn,yyn,zzn,rad_xyz[0,1],rad_xyz[1,1],rad_xyz[2,1])  ;;  [N,3,K]-Element array
;spheres        = scatter_sphere_3d(xx,yy,zz,mxrad[0],mxrad[0],mxrad[0])  ;;  [N,3,K]-Element array
spheres        = scatter_sphere_3d(xx,yy,zz,mdrad[0],mdrad[0],mdrad[0])  ;;  [N,3,K]-Element array
;;----------------------------------------------------------------------------------------
;; => Define plot position
;;----------------------------------------------------------------------------------------
dposxyz        = CONVERT_COORD(po_00,po_00,po_00,/NORMAL,/TO_DATA,/T3D)
nposxyz        = ABS(CONVERT_COORD(xran,yran,zran,/DATA,/TO_NORMAL,/T3D))
t3xr           = REFORM(dposxyz[0,*])
t3yr           = REFORM(dposxyz[1,*])
t3zr           = REFORM(dposxyz[2,*])

xrann          = REFORM(nposxyz[0,*])
yrann          = REFORM(nposxyz[1,*])
zrann          = REFORM(nposxyz[2,*])
;; => Define plot position in normalized coordinates
;;     Format = [(X_0,Y_0),(X_1,Y_1),(Z_0,Z_1)]
nposi          = [po_00[0],po_00[0],po_00[1],po_00[1],po_00]  ;;  normalized positions
dposi          = [t3xr[0],t3yr[0],t3xr[1],t3yr[1],t3zr]       ;;  data oriented positions
;;----------------------------------------------------------------------------------------
;; => Setup plot limits structures
;;----------------------------------------------------------------------------------------
lim0           = lims
str_element,lim0,    'DATA',    0,/ADD_REPLACE
str_element,lim0,  'NORMAL',    1,/ADD_REPLACE
str_element,lim0,'POSITION',nposi,/ADD_REPLACE
;str_element,lim0,    'DATA',    1,/ADD_REPLACE
;str_element,lim0,'POSITION',dposi,/ADD_REPLACE
str_element,lim0,'CHARSIZE', chsz,/ADD_REPLACE
str_element,lim0,  'XRANGE', t3xr,/ADD_REPLACE
str_element,lim0,  'YRANGE', t3yr,/ADD_REPLACE
str_element,lim0,  'ZRANGE', t3zr,/ADD_REPLACE
str_element,lim0, 'XMARGIN',margs,/ADD_REPLACE
str_element,lim0, 'YMARGIN',margs,/ADD_REPLACE
str_element,lim0, 'ZMARGIN',margs,/ADD_REPLACE
str_element,lim0,    'XLOG', xlog,/ADD_REPLACE
str_element,lim0,    'YLOG', ylog,/ADD_REPLACE
str_element,lim0,    'ZLOG', zlog,/ADD_REPLACE
str_element,lim0, 'TITLE',/DELETE
str_element,lim0,'XTITLE',/DELETE
str_element,lim0,'YTITLE',/DELETE
str_element,lim0,'ZTITLE',/DELETE

;limx           = {XRANGE:xran,T3D:1,CHARSIZE:chsz,XAXIS:0,XSTYLE:1,DATA:1,XMARGIN:margs}
;limy           = {YRANGE:yran,T3D:1,CHARSIZE:chsz,YAXIS:0,YSTYLE:1,DATA:1,YMARGIN:margs}
;limz           = {ZRANGE:zran,T3D:1,CHARSIZE:chsz,ZAXIS:1,ZSTYLE:1,DATA:1,ZMARGIN:margs}
;limx2          = {XAXIS:1,T3D:1,DATA:1,XSTYLE:1,CHARSIZE:chsz}
;limy2          = {YAXIS:1,T3D:1,DATA:1,YSTYLE:1,CHARSIZE:chsz}
;limz2          = {ZAXIS:1,T3D:1,DATA:1,ZSTYLE:1,CHARSIZE:chsz}
limx           = {XRANGE:xran,T3D:1,CHARSIZE:chsz,XAXIS:0,XSTYLE:1,NORMAL:1,XMARGIN:margs}
limy           = {YRANGE:yran,T3D:1,CHARSIZE:chsz,YAXIS:0,YSTYLE:1,NORMAL:1,YMARGIN:margs}
limz           = {ZRANGE:zran,T3D:1,CHARSIZE:chsz,ZAXIS:1,ZSTYLE:1,NORMAL:1,ZMARGIN:margs}
limx2          = {XRANGE:xran,XAXIS:1,T3D:1,NORMAL:1,XSTYLE:1,CHARSIZE:chsz}
limy2          = {YRANGE:yran,YAXIS:1,T3D:1,NORMAL:1,YSTYLE:1,CHARSIZE:chsz}
limz2          = {ZRANGE:zran,ZAXIS:1,T3D:1,NORMAL:1,ZSTYLE:1,CHARSIZE:chsz}
str_element, limx,    'XLOG', xlog,/ADD_REPLACE
str_element, limy,    'YLOG', ylog,/ADD_REPLACE
str_element, limz,    'ZLOG', zlog,/ADD_REPLACE
str_element,limx2,    'XLOG', xlog,/ADD_REPLACE
str_element,limy2,    'YLOG', ylog,/ADD_REPLACE
str_element,limz2,    'ZLOG', zlog,/ADD_REPLACE

lim_pro        = {T3D:1,THICK:thick0,DATA:1}
;;----------------------------------------------------------------------------------------
;; => Create a set of blank 3D axes
;;----------------------------------------------------------------------------------------
SURFACE,FINDGEN(2,2),_EXTRA=lim0

;; => Set up axes
tlen           = 1.0
yposi_1        = 1.0
;; => X-Axis
AXIS,xrann[0],yrann[0],zrann[0],_EXTRA=limx
AXIS,xrann[0],yrann[1],zrann[0],_EXTRA=limx2,XTICKLEN=tlen[0],XTICKFORMAT='no_lab_scatter'
;AXIS,0d0,yrann[1],zrann[0],_EXTRA=limx2,XTICKLEN=tlen[0],XTICKFORMAT='no_lab_scatter'
;; => Y-Axis
AXIS,xrann[0],0d0,zrann[0],_EXTRA=limy
AXIS,xrann[1],0d0,zrann[0],_EXTRA=limY2,YTICKLEN=tlen[0],YTICKFORMAT='no_lab_scatter'
;; => Z-Axis
AXIS,xrann[0],yrann[1],0d0,_EXTRA=limz
AXIS,xrann[0],yrann[1],0d0,_EXTRA=limz2,ZTICKFORMAT='no_lab_scatter'

;stop
;;; => X-Axis
;AXIS,-1d0,yran[0],zran[0],_EXTRA=limx
;AXIS,-1d0,yran[1],zran[0],_EXTRA=limx2,XTICKLEN=tlen[0],XTICKFORMAT='no_lab_scatter'
;;; => Y-Axis
;AXIS,xran[0],-1d0,zran[0],_EXTRA=limy
;AXIS,xran[1],-1d0,zran[0],_EXTRA=limY2,YTICKLEN=tlen[0],YTICKFORMAT='no_lab_scatter'
;;; => Z-Axis
;AXIS,xran[0],yran[1],-1d0,_EXTRA=limz
;AXIS,xran[0],yran[1],-1d0,_EXTRA=limz2,ZTICKFORMAT='no_lab_scatter'
;;----------------------------------------------------------------------------------------
;; => Plot 3D scatter
;;----------------------------------------------------------------------------------------
FOR j=0L, nn - 1L DO BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Overplot x-projection if desired
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(xline) THEN BEGIN
    ;;  Start at:  {  X_0, Y[j], Z[j] }
    PLOTS,xran[0],yy[j],zz[j],_EXTRA=lim_pro,LINESTYLE=2
    ;;   Move to:  { X[j], Y[j], Z[j] }
    PLOTS,  xx[j],yy[j],zz[j],_EXTRA=lim_pro,LINESTYLE=2,/CONTINUE
    ;;    End at:  {  X_0, Y[j], Z[j] }
    PLOTS,xran[0],yy[j],zz[j],_EXTRA=lim_pro,PSYM=3
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Overplot y-projection if desired
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(yline) THEN BEGIN
    ;;  Start at:  { X[j],  Y_0, Z[j] }
    PLOTS,xx[j],yran[0],zz[j],_EXTRA=lim_pro,LINESTYLE=2
    ;;   Move to:  { X[j], Y[j], Z[j] }
    PLOTS,xx[j],  yy[j],zz[j],_EXTRA=lim_pro,LINESTYLE=2,/CONTINUE
    ;;    End at:  { X[j],  Y_0, Z[j] }
    PLOTS,xx[j],yran[0],zz[j],_EXTRA=lim_pro,PSYM=3
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Overplot z-projection if desired
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(zline) THEN BEGIN
    ;;  Start at:  { X[j], Y[j],  Z_0 }
    PLOTS,xx[j],yy[j],zran[0],_EXTRA=lim_pro,LINESTYLE=2
    ;;   Move to:  { X[j], Y[j], Z[j] }
    PLOTS,xx[j],yy[j],  zz[j],_EXTRA=lim_pro,LINESTYLE=2,/CONTINUE
    ;;    End at:  { X[j], Y[j],  Z_0 }
    PLOTS,xx[j],yy[j],zran[0],_EXTRA=lim_pro,PSYM=3
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Plot the spheres
  ;;--------------------------------------------------------------------------------------
;  PLOTS,xx[j],yy[j],zz[j],_EXTRA=lim_pro,PSYM=3,SYMSIZE=3.0
;  POLYFILL,REFORM(spheres[j,*,*]),/T3D,/NORMAL,COLOR= 50L
  POLYFILL,REFORM(spheres[j,*,*]),/T3D,/DATA,COLOR= 50L
  ;;--------------------------------------------------------------------------------------
  ;;  Connect the dots if desired
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(connect) THEN BEGIN
    IF (j GT 0) THEN BEGIN
      k = j - 1L
      ;;  Start at:  {  X[j-1], Y[j-1], Z[j-1] }
      PLOTS,xx[k],yy[k],zz[k],_EXTRA=lim_pro,LINESTYLE=2,COLOR=250L
      ;;   Move to:  { X[j], Y[j], Z[j] }
      PLOTS,xx[j],yy[j],zz[j],_EXTRA=lim_pro,LINESTYLE=2,/CONTINUE,COLOR=250L
    ENDIF
  ENDIF
ENDFOR
;;----------------------------------------------------------------------------------------
;; => Output Axes and Plot Titles
;;----------------------------------------------------------------------------------------
fac            = 1.05
lim_xyo        = {DATA:1,T3D:1,CHARSIZE:chsz,ALIGNMENT:0.5,TEXT_AXES:1}
mxx            = DBLARR(2)
myy            = DBLARR(2)
mzz            = DBLARR(2)
mxx            = [xran[1],yran[0],zran[0]]
myy            = [xran[0],yran[1],zran[0]]
IF (mxx[0] LT 0) THEN mxx[0] /= fac ELSE mxx[0] *= fac
IF (mxx[1] LT 0) THEN mxx[1] *= fac ELSE mxx[1] /= fac
IF (myy[0] LT 0) THEN myy[0] *= fac ELSE myy[0] /= fac
IF (myy[1] LT 0) THEN myy[1] /= fac ELSE myy[1] *= fac
mzz            = myy
mzz[2]         = zran[1]
IF (mzz[2] LT 0) THEN mzz[2] /= fac ELSE mzz[2] *= fac

XYOUTS,mxx[0],mxx[1],Z=mxx[2],lims.XTITLE,_EXTRA=lim_xyo
XYOUTS,myy[0],myy[1],Z=myy[2],lims.YTITLE,_EXTRA=lim_xyo
XYOUTS,mzz[0],mzz[1],Z=mzz[2],lims.ZTITLE,_EXTRA=lim_xyo
;;----------------------------------------------------------------------------------------
;; => Output a pseudo plot label/title
;;----------------------------------------------------------------------------------------
IF (STRLEN(lims.TITLE) GT 10) THEN BEGIN
  chsz2 = chsz*2d0/3d0
  xpos2 = 0.55
ENDIF ELSE BEGIN
  chsz2 = chsz
  xpos2 = 0.65
ENDELSE

XYOUTS,xpos2[0],0.95,lims.TITLE,/NORMAL,CHARSIZE=chsz2
;;----------------------------------------------------------------------------------------
;; => Return plot window to original state
;;----------------------------------------------------------------------------------------
!X   = xyzp_win.X
!Y   = xyzp_win.Y
!Z   = xyzp_win.Z
!P   = xyzp_win.P

RETURN
END
