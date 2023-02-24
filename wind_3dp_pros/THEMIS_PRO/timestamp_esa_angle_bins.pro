;+
;*****************************************************************************************
;
;  FUNCTION :   timestamp_esa_angle_bins.pro
;  PURPOSE  :   This routine determines the Unix timestamps associated with each angle
;                 bin in a THEMIS ESA IDL data structure.  These timestamps can be used
;                 with the FGM data in 'fgh' mode to calculate pitch-angle distributions
;                 at a higher cadence than the current ~3 second resolution.
;
;  CALLED BY:   
;               rotate_esa_htr_structure.pro
;
;  CALLS:
;               test_themis_esa_struc_format.pro
;               get_data.pro
;               interp.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT      :  Scalar structure associated with a known THEMIS ESA Burst
;                             data structure
;                             [see get_th?_pe%b.pro, ? = a-f, % = i,e]
;               SPPERI   :  Scalar defining the spin rate [deg/s] of the associated
;                             THEMIS spacecraft
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  Changed calling sequence so that the spin rate is input as a
;                   scalar quantity, not a TPLOT handle            [08/08/2012   v1.1.0]
;
;   NOTES:      
;               1)  The routine assumes that the input structure angles are still
;                     in DSL coordinates
;               2)  Currently the routine uses a linearly interpolated spin period
;                     derived from the state data quantities from TDAS
;                       =>  You may wish to use only the average or median value in
;                             case an orbital maneuver was performed near a distribution
;                             of interest.
;               3)  See also:  contour_3d_htr_1plane.pro, rotate_3dp_htr_structure.pro,
;                     timestamp_3dp_angle_bins.pro, rotate_esa_htr_structure.pro
;
;   CREATED:  08/07/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/08/2012   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION timestamp_esa_angle_bins,data,spperi

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
notstr_mssg    = 'Must be an IDL structure...'
nottpn_msg     = ' is not a valid TPLOT handle...'
;;----------------------------------------------------------------------------------------
;; => Check input structure format
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 2) THEN RETURN,0b
str       = data[0]   ;; => in case it is an array of structures of the same format
IF (SIZE(str,/TYPE) NE 8L) THEN BEGIN
  MESSAGE,notstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
test      = test_themis_esa_struc_format(str,/NOM) NE 1
IF (test) THEN RETURN,0b

dat       = data[0]
;;----------------------------------------------------------------------------------------
;; => Check input spin rate [deg s^(-1)]
;;----------------------------------------------------------------------------------------
sprated   = spperi[0]
;;----------------------------------------------------------------------------------------
;; => Define ESA structure parameters
;;----------------------------------------------------------------------------------------
n_e       = dat.NENERGY       ;; => # of energy bins
n_a       = dat.NBINS         ;; => # of angle bins

phi       = dat.PHI           ;; [E,A]-Element Array of azimuthal angles [deg, DSL]

t0        = dat.TIME[0]       ;; => Unix time at start of ESA sample period
t1        = dat.END_TIME[0]   ;; => Unix time at end of ESA sample period
del_t     = t1[0] - t0[0]     ;; => Total time of data sample
;; => Accumulation time [s] of each angle bin
tacc      = dat[0].INTEG_T[0]*dat[0].DT_ARR
;;----------------------------------------------------------------------------------------
;; => Shift azimuthal angles to 0 ≤ ø ≤ 360
;;----------------------------------------------------------------------------------------
phi_00    = phi[0,0]          ;; => 1st DSL azimuthal angle sampled
;; => Shift the rest of the angles so that phi_00 = 0d0
sh_phi    = phi - phi_00[0]
;; => Adjust negative values so they are > 360
shphi36   = sh_phi + 36d1
;;  subtract smallest angle
shphi36  -= MIN(shphi36,/NAN)
;;----------------------------------------------------------------------------------------
;; => Calculate timestamps for each [theta,phi]-angle bin
;;----------------------------------------------------------------------------------------
;; => Define time diff. [s] from middle of first data point
d_t_phi   = shphi36/sprated[0]
;; => These times are actually 1/2 an accumulation time from the true start time of each bin
d_t_trp   = d_t_phi + tacc/2d0
;; => Define the associated timestamps for each angle bin
ti_angs   = t0[0] + d_t_trp
;;----------------------------------------------------------------------------------------
;; => Return timestamps to user
;;----------------------------------------------------------------------------------------

RETURN,ti_angs
END


