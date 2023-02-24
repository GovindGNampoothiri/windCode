;+
;*****************************************************************************************
;
;  FUNCTION :   make_3dmap.pro
;  PURPOSE  :   Program returns a 2-dimensional array of bin values that reflect
;                 the 3D mapping.
;
;  CALLED BY:   
;               plot3d.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               str_element.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP or SPEDAS IDL Libraries
;
;  INPUT:
;               DAT      :  Scalar [structure] containing a particle velocity
;                             distribution with at least the following structure tags:
;                               NENERGY  :  Scalar defining the # of energy bins, E
;                               NBINS    :  Scalar defining the # of solid angle bins, A
;                               BINS     :  [E,A]-Element array of TRUE/FALSE values
;                                             defining which bins are to be used
;                               PHI      :  [E,A]-Element array of azimuthal angles [deg]
;                               THETA    :  [E,A]-Element array of poloidal angles [deg]
;                               DPHI     :  [E,A]-Element array of azimuthal angle
;                                             uncertainties [deg]
;                               DTHETA   :  [E,A]-Element array of poloidal angle
;                                             uncertainties [deg]
;                             where E = # of energy bins and A = # of solid angle bins.
;               NX       :  Scalar [long] defining the # of elements in the 1st
;                             dimension of output array
;                             [Default = 64]
;               NY       :  Scalar [long] defining the # of elements in the 2nd
;                             dimension of output array
;                             [Default = 32]
;
;  EXAMPLES:    
;               [calling sequence]
;               map = make_3dmap(dat, nx, ny [,HIGHEST=highest])
;
;  KEYWORDS:    
;               HIGHEST  :  If set, force the highest bin number to prevail for 
;                             overlapping bins.
;                             [Default = FALSE]
;
;   CHANGED:  1)  Davin Larson changed something...
;                                                                   [10/22/1999   v1.0.7]
;             2)  Re-wrote and cleaned up
;                                                                   [06/22/2009   v1.1.0]
;             3)  Fixed typo
;                                                                   [09/18/2009   v1.1.1]
;             4)  Fixed typo
;                                                                   [12/07/2011   v1.1.2]
;             5)  Updated Man. page, cleaned up routine, and fixed a bug
;                                                                   [06/02/2016   v1.2.0]
;             6)  Fixed a bug
;                                                                   [06/03/2016   v1.2.1]
;
;   NOTES:      
;               1)  If there are any overlapping bins, then the lowest bin number 
;                     will win, unless the HIGHEST keyword is set.
;               2)  theta +/- dtheta should be in the range:  -90 to +90 degrees
;
;  REFERENCES:  
;               1)  Carlson et al., (1983), "An instrument for rapidly measuring
;                      plasma distribution functions with high resolution,"
;                      Adv. Space Res. Vol. 2, pp. 67-70.
;               2)  Curtis et al., (1989), "On-board data analysis techniques for
;                      space plasma particle instruments," Rev. Sci. Inst. Vol. 60,
;                      pp. 372.
;               3)  Lin et al., (1995), "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125.
;               4)  Paschmann, G. and P.W. Daly (1998), "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst.
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;
;   CREATED:  02/08/1996
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  06/03/2016   v1.2.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION make_3dmap,dat0,nx0,ny0,HIGHEST=highest

;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
;  LBW III  06/02/2016   v1.2.0
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Error messages
noinput_mssg   = 'Incorrect number of inputs were supplied...'
baddinp_msg    = 'Incorrect input:  DAT must be an IDL structure...'
baddfor_msg    = 'Incorrect input format:  DAT must be a valid velocity distribution with appropriate structure tags...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
;  LBW III  06/02/2016   v1.2.0
test           = (N_PARAMS() LT 1)
IF (test[0]) THEN BEGIN
  MESSAGE,noinput_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,REPLICATE(-1,64,32)
ENDIF
test           = (SIZE(dat0,/TYPE) NE 8)
IF (test[0]) THEN BEGIN
  MESSAGE,baddinp_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,REPLICATE(-1,64,32)
ENDIF
dat            = dat0[0]             ;;  in case user provided an array of structures
;  LBW III  06/02/2016   v1.2.0
str_element,dat,'NENERGY',nener
str_element,dat,  'NBINS',nbins
str_element,dat,   'BINS',bins
str_element,dat, 'DTHETA',dtheta0
str_element,dat,  'THETA',theta0
str_element,dat,   'DPHI',dphi0
str_element,dat,    'PHI',phi0
test           = (N_ELEMENTS(nener) EQ 0) OR (N_ELEMENTS(nbins) EQ 0) OR  $
                 (N_ELEMENTS(bins) EQ 0) OR (N_ELEMENTS(dtheta0) EQ 0) OR $
                 (N_ELEMENTS(theta0) EQ 0) OR (N_ELEMENTS(dphi0) EQ 0) OR $
                 (N_ELEMENTS(phi0) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,baddfor_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,REPLICATE(-1,64,32)
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define default parameters and check input format
;;----------------------------------------------------------------------------------------
;  LBW III  06/02/2016   v1.2.0
;IF (N_ELEMENTS(nx) EQ 0) THEN nx = 64
;IF (N_ELEMENTS(ny) EQ 0) THEN ny = 32
IF (N_ELEMENTS(nx0) EQ 0) THEN nx = 64L ELSE nx = LONG(nx0[0]) > 0L
IF (N_ELEMENTS(ny0) EQ 0) THEN ny = 32L ELSE ny = LONG(ny0[0]) > 0L
;  LBW III  06/02/2016   v1.2.0
IF (nx[0] EQ 0) THEN nx = 64L  ;;  prevent user from sending zero
IF (ny[0] EQ 0) THEN ny = 32L  ;;  prevent user from sending zero

;  LBW III  06/02/2016   v1.2.0
;IF (N_ELEMENTS(bins) EQ dat.NENERGY*dat.NBINS) THEN BEGIN
IF (N_ELEMENTS(bins) EQ nener[0]*nbins[0]) THEN BEGIN
  bins = TOTAL(bins,1,/NAN) GT 0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define relevant parameters
;;----------------------------------------------------------------------------------------
;  LBW III  06/02/2016   v1.2.0
;phi            = TOTAL(dat.PHI,1,/NAN,/DOUBLE)/TOTAL(FINITE(dat.PHI),1)         ;;  Avg. (over energies) Phi [deg]
;theta          = TOTAL(dat.THETA,1,/NAN,/DOUBLE)/TOTAL(FINITE(dat.THETA),1)     ;;  Avg. (over energies) Theta [deg]
;dphi           = TOTAL(dat.DPHI,1,/NAN,/DOUBLE)/TOTAL(FINITE(dat.DPHI),1)
;dtheta         = TOTAL(dat.DTHETA,1,/NAN,/DOUBLE)/TOTAL(FINITE(dat.DTHETA),1)
phi            = TOTAL(phi0,1,/NAN,/DOUBLE)/TOTAL(FINITE(phi0),1)         ;;  Avg. (over energies) Phi [deg]
theta          = TOTAL(theta0,1,/NAN,/DOUBLE)/TOTAL(FINITE(theta0),1)     ;;  Avg. (over energies) Theta [deg]
dphi           = TOTAL(dphi0,1,/NAN,/DOUBLE)/TOTAL(FINITE(dphi0),1)
dtheta         = TOTAL(dtheta0,1,/NAN,/DOUBLE)/TOTAL(FINITE(dtheta0),1)
nbins          = N_ELEMENTS(phi)                                          ;;  # of data bins

p1             = ROUND((phi - dphi/2d0)*nx[0]/36d1)
p2             = ROUND((phi + dphi/2d0)*nx[0]/36d1) - 1L
t1             = ROUND((theta - dtheta/2d0 + 9d1)*ny[0]/18d1)
t2             = ROUND((theta + dtheta/2d0 + 9d1)*ny[0]/18d1) - 1L
;;----------------------------------------------------------------------------------------
;;  Do some error handling to prevent indexing errors in FOR loop below
;;----------------------------------------------------------------------------------------
map            = REPLICATE(-1,nx[0],ny[0])                                ;;  3D map to return
gtt            = WHERE(t2 GT t1,ctt)
IF (ctt GT 1L) THEN BEGIN
  t1    = t1[gtt]
  t2    = t2[gtt]
  p1    = p1[gtt]
  p2    = p2[gtt]
;  LBW III  12/07/2011
  nbins = ctt                                         ;;  # of data bins
ENDIF ELSE BEGIN
  MESSAGE, 'No Valid Data',/CONTINUE,/INFORMATIONAL
  RETURN,map
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Determine mapping
;;----------------------------------------------------------------------------------------
FOR b1=0L, ctt[0] - 1L DO BEGIN
;  IF KEYWORD_SET(highest) THEN b = b1 ELSE b = gbins - b1 - 1L
;  LBW III  12/07/2011
  IF KEYWORD_SET(highest) THEN b = b1[0] ELSE b = nbins[0] - b1[0] - 1L
  IF ((bins[b[0]] GT 0) AND (p2[b[0]] NE -1) AND (p1[b[0]] NE -1)) THEN BEGIN
    np = p2[b[0]] - p1[b[0]] - 1L
    IF (np[0] LE 0) THEN CONTINUE
;  LBW III  06/02/2016   v1.2.0
;    IF (np eq 0) THEN CONTINUE
    p  = INDGEN(np[0])
    p += p1[b[0]]
    pi = (p + nx[0]) MOD nx[0]   ;;  Array of phi-indices
    t  = INDGEN(t2[b[0]] - t1[b[0]] + 1L) + t1[b[0]]
    ti = (t + ny[0]) MOD ny[0]   ;;  Array of theta-indices
    IF (N_ELEMENTS(ti) GE 1) THEN BEGIN
;  LBW III  06/03/2016   v1.2.1
;      barr       = REPLICATE(b[0],N_ELEMENTS(pi),N_ELEMENTS(ti))
;      map[pi,ti] = barr
      FOR i=0L, N_ELEMENTS(ti[0]) - 1L DO BEGIN
        map[pi,ti[i]] = b[0]
      ENDFOR
    ENDIF ELSE BEGIN
      ;;  Not enough elements to add to map
      MESSAGE, 'Invalid Data',/CONTINUE,/INFORMATIONAL
    ENDELSE
  ENDIF
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,map
END
