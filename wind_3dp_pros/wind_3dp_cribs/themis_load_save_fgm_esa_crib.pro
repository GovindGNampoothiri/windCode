;+
;*****************************************************************************************
;
;  CRIBSHEET:   themis_load_save_fgm_esa_crib.pro
;  PURPOSE  :   This is a crib sheet (i.e., copy+paste each line by hand) meant to
;                 illustrate how to use the load and save batch file
;                 load_save_themis_fgm_esa_batch.pro
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               get_os_slash.pro
;               @comp_lynn_pros.pro
;               thm_init.pro
;               @load_save_themis_fgm_esa_batch.pro
;               tlimit.pro
;               ps_quick_file.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries and UMN Modified Wind/3DP IDL Libraries
;               2)  MUST run comp_lynn_pros.pro prior to calling this routine
;
;  INPUT:
;               NA
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
;               1)  Summary plot notes on THEMIS SSL Berkeley website
;                     Status Bar Legend
;                     =============================
;                       yellow       :  slow survey
;                       red          :  fast survey
;                       black below  :  particle burst
;                       black above  :  wave burst
;
;  REFERENCES:  
;               1)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               2)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;               3)  Auster, H.U., K.-H. Glassmeier, W. Magnes, O. Aydogar, W. Baumjohann,
;                      D. Constantinescu, D. Fischer, K.H. Fornacon, E. Georgescu,
;                      P. Harvey, O. Hillenmaier, R. Kroth, M. Ludlam, Y. Narita,
;                      R. Nakamura, K. Okrafka, F. Plaschke, I. Richter, H. Schwarzl,
;                      B. Stoll, A. Valavanoglou, and M. Wiedemann "The THEMIS Fluxgate
;                      Magnetometer," Space Sci. Rev. 141, pp. 235-264, (2008).
;               6)  Angelopoulos, V. "The THEMIS Mission," Space Sci. Rev. 141,
;                      pp. 5-34, (2008).
;
;   CREATED:  12/05/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  12/05/2014   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
me             = 9.1093829100d-31     ;;  Electron mass [kg]
mp             = 1.6726217770d-27     ;;  Proton mass [kg]
ma             = 6.6446567500d-27     ;;  Alpha-Particle mass [kg]
c              = 2.9979245800d+08     ;;  Speed of light in vacuum [m/s]
epo            = 8.8541878170d-12     ;;  Permittivity of free space [F/m]
muo            = !DPI*4.00000d-07     ;;  Permeability of free space [N/A^2 or H/m]
qq             = 1.6021765650d-19     ;;  Fundamental charge [C]
kB             = 1.3806488000d-23     ;;  Boltzmann Constant [J/K]
hh             = 6.6260695700d-34     ;;  Planck Constant [J s]
GG             = 6.6738400000d-11     ;;  Newtonian Constant [m^(3) kg^(-1) s^(-1)]

f_1eV          = qq[0]/hh[0]          ;;  Freq. associated with 1 eV of energy [Hz]
J_1eV          = hh[0]*f_1eV[0]       ;;  Energy associated with 1 eV of energy [J]
;;  Temp. associated with 1 eV of energy [K]
K_eV           = qq[0]/kB[0]          ;; ~ 11,604.519 K
R_E            = 6.37814d3            ;;  Earth's Equatorial Radius [km]
slash          = get_os_slash()       ;;  '/' for Unix, '\' for Windows

;;  Put the initialization routine (comp_lynn_pros.pro) in the ~/TDAS/tdas_?_??/idl/
;;      directory and change the file paths so they work for your personal machine
;;      *****************************************************************************
;;      **  If your paths are not set correctly, you may need to specify the path  **
;;      **  to comp_lynn_pros.pro in addition to the batch name.  For instance,    **
;;      **  on my machine this is done by:                                         **
;;      **  @$HOME/TDAS/tdas_8_00/idl/comp_lynn_pros.pro                           **
;;      *****************************************************************************
@comp_lynn_pros.pro
;;  Initialize THEMIS software (if not already done)
thm_init
;;----------------------------------------------------------------------------------------
;;  Define:  Date and Probe
;;
;;    **  You NEED to define these EXACT variables for the batch routine to run  **
;;----------------------------------------------------------------------------------------
;;  Probe A

;;  Probe B
probe          = 'b'
tdate          = '2008-07-26'
date           = '072608'

;;  Probe C

;;  Probe D

;;  Probe E

;;----------------------------------------------------------------------------------------
;;  Load all relevant data
;;  *****************************************************************************
;;  **  If your paths are not set correctly, you may need to specify the path  **
;;  **  to the file in addition to the batch name.  For instance, on my        **
;;  **  machine this is done by:                                               **
;;  **  @$HOME/wind_3dp_pros/wind_3dp_cribs/load_save_themis_fgm_esa_batch.pro **
;;  *****************************************************************************
;;----------------------------------------------------------------------------------------
@load_save_themis_fgm_esa_batch.pro

;;----------------------------------------------------------------------------------------
;;  Manually zoom to time range including currently shown FGM data
;;    --> Then plot results using quick output wrapper, ps_quick_file.pro
;;----------------------------------------------------------------------------------------
tlimit

;;  Define |Bo| TPLOT handles for fgs, fgl, and fgh
coord_mag      = 'mag'
fgm_modes      = 'fg'+['s','l','h']
tpn_names      = scpref[0]+fgm_modes+'_'+coord_mag[0]
scname         = STRUPCASE(STRMID(scpref[0],0,3))
;;  Define structures for ps_quick_file.pro
tags           = 'T'+STRTRIM(STRING(LINDGEN(5),FORMAT='(I2.2)'),2)
fgs_str        = CREATE_STRUCT(tags,fgm_modes[0],'B','DC',coord_mag[0],'L2')
fgl_str        = CREATE_STRUCT(tags,fgm_modes[1],'B','DC',coord_mag[0],'L2')
fgh_str        = CREATE_STRUCT(tags,fgm_modes[2],'B','DC',coord_mag[0],'L2')
fstr           = [fgs_str,fgl_str,fgh_str]
ps_quick_file,SPACECRAFT=scname[0],FIELDS=fstr




