;+
;*****************************************************************************************
;
;  FUNCTION :   grid_on_spherical_shells.pro
;  PURPOSE  :   This routine takes an input function, ƒ(r,ø,∑), [where r = radius,
;                 ∑ = latitude, and ø = longitude] and grids the data onto spherical
;                 shells of constant radius.  The routine allows the user to grid the
;                 data using a number of methods allowed by GRIDDATA.PRO that do not
;                 require triangles from a Delaunay triangulation routine.
;
;  CALLED BY:   
;               grid_mcp_esa_data_sphere.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               DATA       :  [R,N]-Element array of data representing the function
;                               ƒ(r,ø,∑) [R = # of radial shells in the data and
;                               N = # of angular bins].  The units are not necessarily
;                               important for the functionality of this routine.
;               LON_IN     :  [R,N]-Element array of longitudes [degrees], ø,
;                               corresponding to the points in ƒ(r,ø,∑).
;               LAT_IN     :  [R,N]-Element array of latitudes [degrees], ∑,
;                               corresponding to the points in ƒ(r,ø,∑).
;
;  EXAMPLES:    
;               test = grid_on_spherical_shells(data,lon,lat,NLON=nlon,NLAT=nlat,$
;                                               GRID_METH="invdist")
;
;  KEYWORDS:    
;               NLON       :  Scalar [long] defining the # of longitude bins to use,
;                               which define the # L used in the comments throughout
;                               [Default = 30]
;               NLAT       :  Scalar [long] defining the # of poloidal bins to use,
;                               which define the # T used in the comments throughout
;                               [Default = 30]
;               GRID_METH  :  Scalar [string] defining the gridding method to use
;                               in GRIDDATA.PRO.  The allowed methods are:
;                                 "invdist"   :  "InverseDistance"
;                                                  Data points closer to the grid points
;                                                  have more effect than those which are
;                                                  further away.
;                                                  [Default]
;                                 "kriging"   :  "Kriging"
;                                                  Data points and their spatial variance
;                                                  are used to determine trends which are
;                                                  applied to the grid points.
;                                 "mincurve"  :  "MinimumCurvature"
;                                                  A plane of grid points is conformed to
;                                                  the data points while trying to
;                                                  minimize the amount of bending in the
;                                                  plane.
;                                 "polyregr"  :  "PolynomialRegression"
;                                                  Each interpolant is a least-squares
;                                                  fit of a polynomial in X and Y of the
;                                                  specified power to the specified data
;                                                  points.
;                                 "radfunc"   :  "RadialBasisFunction"
;                                                  The effects of data points are
;                                                  weighted by a function of their radial
;                                                  distance from a grid point.
;
;   CHANGED:  1)  Changed error handling placement and usage and
;                   removed use of EXECUTE.PRO
;                                                                   [06/22/2013   v1.1.0]
;             2)  Changed location to ~/general_math directory and cleaned up
;                                                                   [05/15/2014   v1.1.1]
;
;   NOTES:      
;               1)  An example use of this routine would be to use it to grid the
;                     data from one of the multi-channel plate electrostatic analyzers
;                     from THEMIS, Wind, Cluster, etc.
;               2)  The output is a structure containing an [R,L,T]-element array of
;                     data projected onto regular spherically concentric grids at each
;                     input radius, r.  The output also contains the grid locations in
;                     longitude, ø, and latitude, ∑.
;
;   CREATED:  04/23/2013
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/15/2014   v1.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION grid_on_spherical_shells,data,lon_in,lat_in,NLON=nlon0,NLAT=nlat0,$
                                  GRID_METH=grid_meth

;;----------------------------------------------------------------------------------------
;; => Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
miss           = !VALUES.D_NAN
;;  Dummy error messages
baddim_msg     = 'The dimensions of DATA must match both LON_IN and LAT_IN!'
failed_msg     = ';;  Failed at E-Index = '
;;----------------------------------------------------------------------------------------
;;  Error handling
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 3) THEN RETURN,0b

CATCH, error_status
IF (error_status NE 0) THEN BEGIN
  ;;  Cancel error handler
  CATCH, /CANCEL
  ;;  Print error message
  PRINT, 'Error index: ', error_status
  PRINT, 'Error message: ', !ERROR_STATE.MSG
  test           = (N_ELEMENTS(failed_msg) NE 0 AND N_ELEMENTS(eind) NE 0)
  IF (test) THEN PRINT, failed_msg[0], eind
  ;;  Deal with error
  IF (N_ELEMENTS(miss)  EQ 0) THEN miss  = !VALUES.D_NAN
  IF (N_ELEMENTS(n_e)   EQ 0) THEN n_e   = 15L
  IF (N_ELEMENTS(nlon0) EQ 0) THEN nlon  = 30L ELSE nlon  = LONG(nlon0[0])
  IF (N_ELEMENTS(nlat0) EQ 0) THEN nlat  = 30L ELSE nlat  = LONG(nlat0[0])
  tags           = ['F_SPH_GRID','SPH_LON','SPH_LAT']
  f_grid_out     = REPLICATE(miss[0],n_e[0],nlon[0],nlat[0])  ;;  Triangulated and gridded ƒ
  sph_lon        = REPLICATE(miss[0],n_e[0],nlon[0])          ;;  Gridded ø [deg]
  sph_lat        = REPLICATE(miss[0],n_e[0],nlat[0])          ;;  Gridded ∑ [deg]
  struc          = CREATE_STRUCT(tags,f_grid_out,sph_lon,sph_lat)
  ;;  Jump to after triangulate
  RETURN,struc
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check input format
;;----------------------------------------------------------------------------------------
szd            = SIZE(data,/DIMENSIONS)
szl            = SIZE(lon_in,/DIMENSIONS)
szt            = SIZE(lat_in,/DIMENSIONS)
test_form      = (szd NE szl) OR (szd NE szt)
test           = TOTAL(test_form) NE 0
IF (test) THEN BEGIN
  MESSAGE,baddim_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check keywords
;;----------------------------------------------------------------------------------------
IF (N_ELEMENTS(nlon0)     EQ 0) THEN nlon  = 30L ELSE nlon  = LONG(nlon0[0])
IF (N_ELEMENTS(nlat0)     EQ 0) THEN nlat  = 30L ELSE nlat  = LONG(nlat0[0])
IF (N_ELEMENTS(grid_meth) EQ 0) THEN gmeth = 0   ELSE gmeth = 1

IF (gmeth) THEN g_meth = STRLOWCASE(grid_meth[0]) ELSE g_meth = "invdist"
;;----------------------------------------------------------------------------------------
;;  Define relevant parameters
;;----------------------------------------------------------------------------------------
n_e            = szd[0]                                     ;;  # of radial shells [ = R]
n_a            = szd[0]                                     ;;  # of angle bins    [ = N]
ef_dat         = REFORM(data)                               ;;  ƒ(E,∑,ø)
phi            = REFORM(lon_in)                             ;;  Longitudes, ø [deg]
theta          = REFORM(lat_in)                             ;;  Latitudes, ∑ [deg]
;;----------------------------------------------------------------------------------------
;;  Define output variables
;;----------------------------------------------------------------------------------------
f_grid_out     = REPLICATE(miss[0],n_e[0],nlon[0],nlat[0])  ;;  Triangulated and gridded ƒ
sph_lon        = REPLICATE(miss[0],n_e[0],nlon[0])          ;;  Gridded ø [deg]
sph_lat        = REPLICATE(miss[0],n_e[0],nlat[0])          ;;  Gridded ∑ [deg]
;;----------------------------------------------------------------------------------------
;;  Grid the data
;;----------------------------------------------------------------------------------------
ppout          = 1
FOR eind=0L, n_e - 1L DO BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Reset temporary variables
  ;;--------------------------------------------------------------------------------------
  longitude      = REFORM(phi[eind,*])*1d0
  latitude       = REFORM(theta[eind,*])*1d0
  f_xyz          = REFORM(ef_dat[eind,*])*1d0        ;;  f = ƒ(∑,ø)
  ;;--------------------------------------------------------------------------------------
  ;;  Remove zeros from ƒ(E,∑,ø)
  ;;--------------------------------------------------------------------------------------
  bad            = WHERE(f_xyz LE 0d0,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
  IF (bd GT 0) THEN f_xyz[bad] = !VALUES.F_NAN
  ;;  try using minimum # of points as threshold
  IF (gd GT 15) THEN BEGIN  ;;  Finite values exist
    ;;------------------------------------------------------------------------------------
    ;;  Reset values
    ;;------------------------------------------------------------------------------------
    min_x          = 0d0
    max_x          = 0d0
    sph_grid       = 0d0
    sphlon         = 0d0
    sphlat         = 0d0
    ;;------------------------------------------------------------------------------------
    ;;  The following is necessary to avoid a co-linear points test failure...
    ;;------------------------------------------------------------------------------------
    fcopy          = DOUBLE(f_xyz[good])     ;;  will be rearranged in TRIANGULATE
    xcopy          = DOUBLE(longitude[good])
    ycopy          = DOUBLE(latitude[good])
    ;;  Define ƒ(∑,ø) range
    min_x          = MIN(f_xyz,/NAN)
    max_x          = MAX(f_xyz,/NAN)
    ;;------------------------------------------------------------------------------------
    ;;  Define output grid boundaries and spacing
    ;;------------------------------------------------------------------------------------
    min_lon        = 1d0*FLOOR(MIN(longitude,/NAN))
    max_lon        = 1d0*CEIL(MAX(longitude,/NAN))
    min_lat        = 1d0*FLOOR(MIN(latitude,/NAN))
    max_lat        = 1d0*CEIL(MAX(latitude,/NAN))
    bnds           = [min_lon[0],min_lat[0],max_lon[0],max_lat[0]]
    ;;  Define output grid spacing
    boundsout      = bnds
    gsout          = [bnds[2] - bnds[0], bnds[3] - bnds[1]]
    gsout          = gsout/DOUBLE([(nlon[0] - 1L), (nlat[0] - 1L)])
    ;;------------------------------------------------------------------------------------
    ;;  Define output grid longitude and latitude locations
    ;;------------------------------------------------------------------------------------
    sphlon         = DINDGEN(nlon[0])*(bnds[2] - bnds[0])/(nlon[0] - 1L) + bnds[0]
    sphlat         = DINDGEN(nlat[0])*(bnds[3] - bnds[1])/(nlat[0] - 1L) + bnds[1]
    ;;------------------------------------------------------------------------------------
    ;;  Setup:  Grid input
    ;;------------------------------------------------------------------------------------
    gout_str = {SPHERE:1,DEGREES:1,DUPLICATES:"All",EPSILON:1d-2}
    GRID_INPUT,xcopy,ycopy,fcopy,xyz_out,f_out,_EXTRA=gout_str[0]
    ;;  Define spherical output grid
    dims     = [nlon[0],nlat[0]]
    ;;------------------------------------------------------------------------------------
    ;;  Define spherical grid method
    ;;------------------------------------------------------------------------------------
    CASE g_meth[0] OF
      "invdist"   : BEGIN
        ;;  Inverse Distance method
        method   = 'Inverse Distance'
        ex_str   = {MISSING:miss[0],DIMENSION:dims,DELTA:gsout,METHOD:"InverseDistance",$
                    INVERSE_DISTANCE:1,SPHERE:1}
        ;;  Grid the data
        sph_grid = GRIDDATA(xyz_out,f_out,_EXTRA=ex_str[0])
      END
      "kriging"   :  BEGIN
        ;;  Kriging method with Gaussian variogram
        method   = 'Kriging [with Gaussian variogram]'
        vran     = 8d0*(gsout[1] + gsout[0])/2d0
        vari     = [3,vran[0],0,1]
        ex_str   = {MISSING:miss[0],DIMENSION:dims,DELTA:gsout,METHOD:"Kriging",$
                    KRIGING:1,SPHERE:1,VARIOGRAM:vari}
        ;;  Grid the data
        sph_grid = GRIDDATA(xyz_out,f_out,_EXTRA=ex_str[0])
      END
      "mincurve"  :  BEGIN
        ;;  Minimum Curvature method
        method   = 'Minimum Curvature'
        ;; Calculate output longitude and latitude
        lon_out  = ATAN(REFORM(xyz_out[1,*]),REFORM(xyz_out[0,*]))*18d1/!DPI
        xyz_mag  = SQRT(TOTAL(xyz_out^2,1,/NAN))
        colatout = ACOS(REFORM(xyz_out[2,*])/xyz_mag)*18d1/!DPI
        lat_out  = 9d1 - colatout
        ex_str   = {NX:nlon[0],NY:nlat[0],BOUNDS:bnds,GS:gsout,METHOD:"MinimumCurvature",$
                    CONST:1,DOUBLE:1,SPHERE:1}
        ;;  Grid the data
        sph_grid = MIN_CURVE_SURF(f_out,lon_out,lat_out,_EXTRA=ex_str[0])
      END
      "polyregr"  :  BEGIN
        ;;  Polynomial Regression method [cubic spline]
        method   = 'Polynomial Regression [cubic spline]'
        ;; Calculate output longitude and latitude
        lon_out  = ATAN(REFORM(xyz_out[1,*]),REFORM(xyz_out[0,*]))*18d1/!DPI
        xyz_mag  = SQRT(TOTAL(xyz_out^2,1,/NAN))
        colatout = ACOS(REFORM(xyz_out[2,*])/xyz_mag)*18d1/!DPI
        lat_out  = 9d1 - colatout
        ex_str   = {MISSING:miss[0],DIMENSION:dims,DELTA:gsout,METHOD:"PolynomialRegression",$
                    POLYNOMIAL_REGRESSION:1,POWER:3}
        ;;  Print warning...
        PRINT,''
        PRINT,'Polynomial Regression should NOT be used for spherical coordinates...'
        PRINT,''
        ;;  Grid the data
        sph_grid = GRIDDATA(lon_out,lat_out,f_out,_EXTRA=ex_str[0])
      END
      "radfunc"   :  BEGIN
        ;;  Radial Basis Function method [Thin Plate Spline]
        method   = 'Radial Basis Function [Thin Plate Spline]'
        ex_str   = {MISSING:miss[0],DIMENSION:dims,DELTA:gsout,METHOD:"RadialBasisFunction",$
                    RADIAL_BASIS_FUNCTION:1,SPHERE:1,FUNCTION_TYPE:4}
        ;;  Grid the data
        sph_grid = GRIDDATA(xyz_out,f_out,_EXTRA=ex_str[0])
      END
      ELSE        :  BEGIN  ;;  Use default
        ;;  Inverse Distance method [Default]
        method   = 'Inverse Distance'
        ex_str   = {MISSING:miss[0],DIMENSION:dims,DELTA:gsout,METHOD:"InverseDistance",$
                    INVERSE_DISTANCE:1,SPHERE:1}
        ;;  Grid the data
        sph_grid = GRIDDATA(xyz_out,f_out,_EXTRA=ex_str[0])
      END
    ENDCASE
    ;;====================================================================================
    JUMP_SKIP:
    ;;====================================================================================
    ;;------------------------------------------------------------------------------------
    ;;  Check output format
    ;;------------------------------------------------------------------------------------
    ;;  Make sure gridded data was not extrapolated incorrectly
    test           = FINITE(sph_grid) AND (sph_grid LE max_x[0]) AND (sph_grid GE min_x[0])
    good_sph       = WHERE(test,gd_sph,COMPLEMENT=bad_sph,NCOMPLEMENT=bd_sph)
    IF (bd_sph GT 0) THEN sph_grid[bad_sph] = !VALUES.D_NAN  ;;  kill bad points
    IF (gd_sph GT 0) THEN BEGIN
      ;;  Check dimensions
      szn_fsph       = SIZE(sph_grid,/N_DIMENSIONS)
      szd_f          = SIZE(sph_grid,/DIMENSIONS)
      test_2d        = (szn_fsph[0] EQ 2)
      IF (test_2d) THEN test_f = (szd_f[0] EQ nlon[0]) AND (szd_f[1] EQ nlat[0]) $
                   ELSE test_f = 0
      IF (test_f) THEN BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Save the data
        ;;--------------------------------------------------------------------------------
        f_grid_out[eind,*,*] = sph_grid
        sph_lon[eind,*]      = sphlon
        sph_lat[eind,*]      = sphlat
      ENDIF
    ENDIF    ;;  gridded finite test
  ENDIF      ;;  original finite test
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Define return structure
;;----------------------------------------------------------------------------------------
tags           = ['F_SPH_GRID','SPH_LON','SPH_LAT']
struc          = CREATE_STRUCT(tags,f_grid_out,sph_lon,sph_lat)
;;----------------------------------------------------------------------------------------
;;  Return structure to user
;;----------------------------------------------------------------------------------------

RETURN,struc
END


