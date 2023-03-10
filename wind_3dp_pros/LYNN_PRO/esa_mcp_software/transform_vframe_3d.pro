;+
;*****************************************************************************************
;
;  PROCEDURE:   transform_vframe_3d.pro
;  PURPOSE  :   This routine transforms a 3DP data structure into the solar wind frame.
;                 The routine redefines the energy and angle bins of the input data
;                 structure along with their corresponding ranges (e.g. DPHI).
;
;  CALLED BY:   
;               contour_3d_1plane.pro
;               eesa_pesa_low_to_tplot.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               define_particle_charge.pro
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               pesa_high_bad_bins.pro
;               convert_ph_units.pro
;               conv_units.pro
;               dat_3dp_energy_bins.pro
;               str_element.pro
;               struct_value.pro
;               energy_angle_to_velocity.pro
;               rel_lorentz_trans_3vec.pro
;               energy_to_vel.pro
;               interp.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT        :  Scalar [structure] associated with a known THEMIS ESA or
;                               SST data structure
;                               [e.g., see get_th?_p*@b.pro, ? = a-f, * = e,s @ = e,i]
;                               or a Wind/3DP data structure
;                               [see get_?.pro, ? = el, elb, pl, ph, eh, etc.]
;                               [Note:  VSW or VELOCITY tag must be defined and finite]
;
;  EXAMPLES:    
;               ;;....................................................................
;               ;;  Define a time of interest
;               ;;....................................................................
;               to      = time_double('1998-08-09/16:00:00')
;               ;;....................................................................
;               ;;  Get a Wind 3DP PESA High data structure from level zero files
;               ;;....................................................................
;               dat     = get_ph(to)
;               ;;....................................................................
;               ;;  in the following lines, the strings correspond to TPLOT handles
;               ;;      and thus may be different for each user's preference
;               ;;....................................................................
;               add_vsw2,dat,'V_sw2'          ;;  Add solar wind velocity to struct.
;               add_magf2,dat,'wi_B3(GSE)'    ;;  Add magnetic field to struct.
;               add_scpot,dat,'sc_pot_3'      ;;  Add spacecraft potential to struct.
;               ;;....................................................................
;               ;;  Convert to solar wind frame
;               ;;....................................................................
;               transform_vframe_3d,dat,/EASY_TRAN
;
;  KEYWORDS:    
;               NO_TRANS   :  If set, routine will not transform data into SW frame
;                               [Default = FALSE]
;               EASY_TRAN  :  If set, routine only modifies the following structure
;                               tags:  ENERGY, DATA, PHI, and THETA.
;                               --> Here, there is no attempt to determine angular/energy
;                                   uncertainty changes etc.
;                               [Default = TRUE]
;               INTERP     :  If set, data is interpolated to original energy estimates
;                               after transforming into new reference frame
;                               [Default = FALSE]
;               NOKILL_PH  :  If set, program will not call pesa_high_bad_bins.pro for
;                               PESA High structures to remove "bad" data bins
;                               [Default = FALSE]
;
;   CHANGED:  1)  Added keyword:  EASY_TRAN
;                                                                  [02/09/2012   v1.1.0]
;             2)  Now removes energies < 1.3 * (SC Pot) and now calls
;                   dat_3dp_energy_bins.pro and Added keyword:  INTERP
;                                                                  [02/22/2012   v1.2.0]
;             3)  Added keyword:  NOKILL_PH and now calls dat_3dp_str_names.pro and
;                   convert_ph_units.pro
;                                                                  [02/23/2012   v1.3.0]
;             4)  Now calls test_wind_vs_themis_esa_struct.pro and no longer calls
;                   test_3dp_struc_format.pro and now uses particle charge appropriately
;                                                                  [03/29/2012   v1.4.0]
;             5)  Fixed a sign error when removing SC potential
;                                                                  [05/24/2012   v1.5.0]
;             6)  Removed the unnecessary plot command in the error handling section
;                   and now calls energy_to_vel.pro instead of velocity.pro
;                                                                  [04/23/2013   v1.6.0]
;             7)  Cleaned up a few things and now calls
;                   define_particle_charge.pro and energy_angle_to_velocity.pro and
;                   no longer calls str_element.pro
;                                                                  [10/02/2014   v1.7.0]
;             8)  Fixed a typo regarding which energy bins to remove after adjusting
;                   for spacecraft potential (really only affects electron distributions)
;                                                                  [09/28/2015   v1.7.1]
;             9)  Now routine can handle THEMIS SST data structures and
;                   updated Man. page and cleaned up a little and
;                   now calls:  struct_value.pro, str_element.pro,
;                               rel_lorentz_trans_3vec.pro
;                                                                  [11/16/2015   v1.8.0]
;            10)  Cleaned up and now calls mag__vec.pro
;                                                                  [11/16/2015   v1.8.1]
;            11)  Cleaned up and fixed bug where previously defined bad bins were not
;                   removed in input structure prior to calling
;                   energy_angle_to_velocity.pro and
;                   now default setting for EASY_TRAN = TRUE and
;                   no longer tries to add VSW tag --> avoid altering structures for
;                   backwards compatibility
;                                                                  [12/01/2015   v1.9.0]
;
;   NOTES:      
;               1)  This routine modifies the input structure, DAT, so make sure
;                     you make a copy of the original prior to calling.
;               2)  The VSW or VELOCITY structure tag in DAT must be defined and finite
;                     as a single 3-vector corresponding to the bulk flow velocity for DAT
;               3)  The Compton-Getting effect is accounted for because the routine
;                     converts the input data into units of phase space, then performs
;                     a Lorentz transformation on the resulting data by converting the
;                     f(E,??,??) to f(Vx,Vy,Vz) and subtracting the bulk flow speed.  The
;                     routine calls rel_lorentz_trans_3vec.pro to perform the
;                     relativistically accurate Lorentz transformation.
;
;  REFERENCES:  
;               1)  Carlson et al., "An instrument for rapidly measuring
;                      plasma distribution functions with high resolution,"
;                      Adv. Space Res. Vol. 2, pp. 67-70, (1983).
;               2)  Curtis et al., "On-board data analysis techniques for
;                      space plasma particle instruments," Rev. Sci. Inst. Vol. 60,
;                      pp. 372, (1989).
;               3)  Lin et al., "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125, (1995).
;               4)  Paschmann, G. and P.W. Daly "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst., (1998).
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;               7)  Auster, H.U., K.-H. Glassmeier, W. Magnes, O. Aydogar, W. Baumjohann,
;                      D. Constantinescu, D. Fischer, K.H. Fornacon, E. Georgescu,
;                      P. Harvey, O. Hillenmaier, R. Kroth, M. Ludlam, Y. Narita,
;                      R. Nakamura, K. Okrafka, F. Plaschke, I. Richter, H. Schwarzl,
;                      B. Stoll, A. Valavanoglou, and M. Wiedemann "The THEMIS Fluxgate
;                      Magnetometer," Space Sci. Rev. 141, pp. 235-264, (2008).
;               8)  Angelopoulos, V. "The THEMIS Mission," Space Sci. Rev. 141,
;                      pp. 5-34, (2008).
;               9)  Ipavich, F.M. "The Compton-Getting effect for low energy particles,"
;                      Geophys. Res. Lett. 1(4), pp. 149-152, (1974).
;
;   CREATED:  02/08/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  12/01/2015   v1.9.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO transform_vframe_3d,dat,NO_TRANS=no_trans,EASY_TRAN=easy_tran,INTERP=interpo,$
                            NOKILL_PH=nokill_ph

;;  Let IDL know that the following are functions
FORWARD_FUNCTION define_particle_charge, test_wind_vs_themis_esa_struct,           $
                 dat_3dp_str_names, conv_units, dat_3dp_energy_bins, struct_value, $
                 energy_angle_to_velocity, rel_lorentz_trans_3vec, mag__vec,       $
                 energy_to_vel, interp
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
def_uconv_r_th = ['thm_convert_esa_units_lbwiii','thm_convert_sst_units_lbwiii']
;;  Dummy error messages
notstr_msg     = 'Must be an IDL structure...'
notvdf_msg     = 'Must be an ion velocity distribution IDL structure...'
badthm_msg     = 'If THEMIS ESA structures used, then they must be modified using modify_themis_esa_struc.pro'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 1 OR (N_ELEMENTS(dat) EQ 0)) THEN RETURN
;;  Check DAT structure format
str            = dat[0]   ;;  in case it is an array of structures of the same format
IF (SIZE(str,/TYPE) NE 8L) THEN BEGIN
  MESSAGE,notstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
data           = dat[0]
;;  Define sign of particle charge and energy shift
charge         = define_particle_charge(data,E_SHIFT=e_shift)
IF (charge[0] EQ 0) THEN BEGIN
  MESSAGE,notvdf_msg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check NO_TRANS
IF KEYWORD_SET(no_trans) THEN no_trans = 1b ELSE no_trans = 0b
;;  Check EASY_TRAN
test           = ~KEYWORD_SET(easy_tran) AND (N_ELEMENTS(easy_tran) GT 0)
IF (test[0]) THEN easy_tran = 0b ELSE easy_tran = 1b
;;  Check INTERP
IF KEYWORD_SET(interpo) THEN interpo = 1b ELSE interpo = 0b
;;  Check NOKILL_PH
IF KEYWORD_SET(nokill_ph) THEN nokill_ph = 1b ELSE nokill_ph = 0b
;;----------------------------------------------------------------------------------------
;;  Determine the spacecraft from which DAT originated
;;----------------------------------------------------------------------------------------
test0          = test_wind_vs_themis_esa_struct(dat,/NOM)
IF (test0.(0)) THEN BEGIN
  ;;-------------------------------------------
  ;; Wind
  ;;-------------------------------------------
  ;;  Check which instrument is being used
  strns   = dat_3dp_str_names(data[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    ;;  Return with nothing changed
    RETURN
  ENDIF
  shnme   = STRLOWCASE(STRMID(strns.SN[0],0L,2L))
  CASE shnme[0] OF
    'ph' : BEGIN
      ;;  Remove data glitch if necessary in PH data
      IF NOT KEYWORD_SET(nokill_ph) THEN BEGIN
        pesa_high_bad_bins,data
      ENDIF
      convert_ph_units,data,'df'
    END
    ELSE : BEGIN
      data   = conv_units(data,'df')
    END
  ENDCASE
  ;;  Make sure not SST
  IF (STRMID(shnme[0],0L,1L) EQ 's') THEN yes_e_remove = 0 ELSE yes_e_remove = 1
ENDIF ELSE BEGIN
  yes_e_remove = 0  ;;  Do not kill data with large energy bins [later in routine]
  ;;-------------------------------------------
  ;; THEMIS
  ;;-------------------------------------------
  ;;  make sure the structure has been modified
  temp_proc = STRLOWCASE(str[0].UNITS_PROCEDURE)
  test_un   = (temp_proc[0] NE def_uconv_r_th[0]) AND (temp_proc[0] NE def_uconv_r_th[1])
  IF (test_un) THEN BEGIN
    MESSAGE,badthm_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN
  ENDIF
  ;;  structure modified appropriately so convert units
  data   = conv_units(data,'df')
ENDELSE
;;  Define default energy bin values
myens          = dat_3dp_energy_bins(data)
evalues        = myens.ALL_ENERGIES
;;----------------------------------------------------------------------------------------
;;  Check for finite vector in VSW or VELOCITY IDL structure tags
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(no_trans) THEN BEGIN
  str_element,data,'VSW',v_vsw0
  v_vsws         = [0,0,0]
  IF (SIZE(v_vsw0,/TYPE) NE 0) THEN v_vsws *= v_vsw0[0]  ;;  convert type
;;  LBW  12/01/2015   v1.8.2
;  str_element,data,'VSW',v_vsws,/ADD_REPLACE
ENDIF ELSE BEGIN
  ;;  User wants to perform a Lorentz transformation
  v_vsws         = struct_value(data[0],'VSW')
  test_v         = (TOTAL(FINITE(v_vsws)) NE 3)
  IF (test_v[0]) THEN BEGIN
    v_vsws         = struct_value(data[0],'VELOCITY')
    test_v         = (TOTAL(FINITE(v_vsws)) NE 3)
  ENDIF
  IF (test_v[0]) THEN BEGIN
    ;;  Neither VSW or VELOCITY were set --> No transformation
    test_v     = (N_ELEMENTS(v_vsws) NE 3)
    IF (test_v[0]) THEN v_vsws = [0.,0.,0.] ELSE v_vsws = MAKE_ARRAY(3,TYPE=SIZE(v_vsws,/TYPE),VALUE=0)
;;  LBW  12/01/2015   v1.8.2
;    str_element,data,'VSW',v_vsws,/ADD_REPLACE
    ;;  Set NO_TRANS keyword = TRUE
    no_trans   = 1b
  ENDIF
ENDELSE

scpot          = data.SC_POT[0]*charge[0]  ;;  ?? < 0 (electrons), ?? > 0 (ions)
IF (FINITE(scpot[0]) EQ 0) THEN BEGIN
  scpot          = 0.
  data[0].SC_POT = scpot[0]
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define DAT structure parameters
;;----------------------------------------------------------------------------------------
n_e            = data.NENERGY            ;;  # of energy bins
n_a            = data.NBINS              ;;  # of angle bins
ind_2d         = INDGEN(n_e,n_a)         ;;  original indices of angle bins
def_ener       = evalues # REPLICATE(1e0,n_a)
;;  Check for energy shift in data structure
energy         = data.ENERGY + e_shift   ;;  Energy bin values [eV]
old_energy     = energy
denergy        = data.DENERGY            ;;  Uncertainty in ENERGY [eV]
;;   Shift energies by SC-Potential
;;    -> Electrons gain energy => +(-e) ?? = -e ??
;;    -> Ions lose energy      => +(+q) ?? = +Z e ??
energy        += scpot[0]
df_dat         = data.DATA               ;;  Data values [data.UNITS_NAME]
;;  Define types to avoid "Conflicting data structures" error
szt_dtpe       = [SIZE(data.DATA,/TYPE),SIZE(data.THETA,/TYPE),SIZE(data.PHI,/TYPE),$
                  SIZE(data.ENERGY,/TYPE)]
;;----------------------------------------------------------------------------------------
;;  Reform 2D arrays into 1D
;;----------------------------------------------------------------------------------------
;;  Data [K]-element arrays
dat_1d         = REFORM(df_dat,n_e*n_a)
;ind_1d         = REFORM(ind_2d,n_e*n_a)
;;  Energies
ener_1d        = REFORM(energy,n_e*n_a) > 0     ;;  Do not convert negative energies
dener_1d       = REFORM(denergy,n_e*n_a)
;def_en_1d      = REFORM(def_ener,n_e*n_a)
;;  Remove bins below ~1.3 ??_sc
old_ener_1d    = REFORM(old_energy,n_e*n_a)
;bad            = WHERE(old_ener_1d LT ABS(scpot[0])*1.3,nbad,COMPLEMENT=good,NCOMPLEMENT=gd)
test_old       = (old_ener_1d LT ABS(scpot[0])*1.3)
bad            = WHERE(test_old,nbad,COMPLEMENT=good,NCOMPLEMENT=gd)
IF (nbad GT 0) THEN BEGIN
  ;;  Remove low energy values
  dat_1d[bad]  = f
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check for "bad" values
;;
;;    ** specifically looking for energy bin values in PESA High distributions that were
;;      produced using the 32-bit Darwin shared object libraries
;;----------------------------------------------------------------------------------------
bad_en         = WHERE(dener_1d GE 1e8,bden)
test_en        = (bden GT 0L) AND yes_e_remove[0]
IF (test_en[0]) THEN BEGIN
  ;;  Energies
  ener_1d[bad_en]  = f
  dener_1d[bad_en] = f
  ;;  Data
  dat_1d[bad_en]   = f
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check to see if user only wants an easy transformation
;;----------------------------------------------------------------------------------------
vsw_3dp_pts    = REPLICATE(1e0,n_e*n_a) # v_vsws  ;;  [K,3]-Element array
mass           = data[0].MASS[0]                  ;;  particle mass [eV km^(-2) s^(2)]
IF KEYWORD_SET(easy_tran) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Define velocities [km/s] from energies [eV] and angles [degrees]
  ;;--------------------------------------------------------------------------------------
  mvel_3d       = energy_angle_to_velocity(data)
  mvel_1d       = REFORM(mvel_3d,n_e*n_a,3)       ;;  [K,3]-Element array
  ;;  Calculate (relativistically correct) Lorentz transformation
  swvel         = rel_lorentz_trans_3vec(mvel_1d,v_vsws)
  IF (N_ELEMENTS(swvel) EQ 1) THEN RETURN
  ;;--------------------------------------------------------------------------------------
  ;;  Remove bad bins, if necessary
  ;;--------------------------------------------------------------------------------------
  IF (test_en[0]) THEN BEGIN
    swvel[bad_en,*] = f
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Define new velocity magnitudes [km/s] and convert speeds back to energies [eV]
  ;;--------------------------------------------------------------------------------------
  swvmag        = mag__vec(swvel,/NAN)
  n_ener        = energy_to_vel(swvmag,mass[0],/INVERSE)
  ;;--------------------------------------------------------------------------------------
  ;;  Define new poloidal angles [deg]  { -90 < theta < +90 }
  ;;    and azimuthal angles [deg]  { -180 < phi < +180 }
  ;;--------------------------------------------------------------------------------------
  n_the         = ASIN(swvel[*,2]/swvmag)*18e1/!PI
  n_phi         = ATAN(swvel[*,1],swvel[*,0])*18e1/!PI
  ;;  Shift azimuthal angles to {   0 < phi < +360 }
  n_phi         = (n_phi + 36e1) MOD 36e1
  ;;--------------------------------------------------------------------------------------
  ;;  Refrom arrays back to 2D
  ;;--------------------------------------------------------------------------------------
  IF (szt_dtpe[0] EQ 4) THEN data_2d = FLOAT(REFORM(dat_1d,n_e,n_a)) ELSE data_2d = DOUBLE(REFORM(dat_1d,n_e,n_a))
  IF (szt_dtpe[1] EQ 4) THEN the_2d  = FLOAT(REFORM( n_the,n_e,n_a)) ELSE the_2d  = DOUBLE(REFORM( n_the,n_e,n_a))
  IF (szt_dtpe[2] EQ 4) THEN phi_2d  = FLOAT(REFORM( n_phi,n_e,n_a)) ELSE phi_2d  = DOUBLE(REFORM( n_phi,n_e,n_a))
  IF (szt_dtpe[3] EQ 4) THEN ener_2d = FLOAT(REFORM(n_ener,n_e,n_a)) ELSE ener_2d = DOUBLE(REFORM(n_ener,n_e,n_a))
  ;;--------------------------------------------------------------------------------------
  ;;  If desired, interpolate back to original energies
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(interpo) THEN BEGIN
    ;;  Interpolate [linearly] data back to original measured energy values
    FOR i=0L, n_a - 1L DO BEGIN
      df_temp  = data_2d[*,i]
      th_temp  = the_2d[*,i]
      ph_temp  = phi_2d[*,i]
      nrg      = ener_2d[*,i]
      def_en   = def_ener[*,i]
      ;;  Check for bad values
      bad      = WHERE(FINITE(df_temp) EQ 0,wc)
      IF (wc GT 0) THEN df_temp[bad] = 0e0
      ind      = WHERE(df_temp GT 0,count)
      IF (count GT 0) THEN BEGIN
        ;;  good values available, so interpolate
        df_temp = EXP(interp(ALOG(df_temp[ind]),nrg[ind],def_en))
        th_temp = interp(th_temp[ind],nrg[ind],def_en)
        ph_temp = interp(ph_temp[ind],nrg[ind],def_en)
      ENDIF
      ;;  Remove data at energies below measured energy values
      good_en  = WHERE(FINITE(nrg) AND nrg GT 0,gden)
      IF (gden GT 0) THEN BEGIN
        bad  = WHERE(def_en LT MIN(nrg[good_en],/NAN),bd)
        IF (bd GT 0) THEN df_temp[bad] = f
      ENDIF
      ;;  Redefine parameters
      data_2d[*,i]  = df_temp
      the_2d[*,i]   = th_temp
      phi_2d[*,i]   = ph_temp
    ENDFOR
    ;;  Redefine energy bin values
    ener_2d  = def_ener
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Redefine structure tag values
  ;;--------------------------------------------------------------------------------------
  dat           = data
  dat.DATA      = data_2d
  dat.ENERGY    = ener_2d
  dat.THETA     = the_2d
  dat.PHI       = phi_2d
  ;;  Return to user
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;    ***  Still Testing  ***
;;  Perform more accurate transformation
;;    ***  Still Testing  ***
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
phi            = data.PHI                ;;  Azimuthal angle (from sun direction) [deg]
dphi           = data.DPHI               ;;  Uncertainty in phi [deg]
the            = data.THETA              ;;  Poloidal angle (from ecliptic plane) [deg]
dthe           = data.DTHETA             ;;  Uncertainty in theta [deg]
;;  Angles
phi_1d         = REFORM(phi,n_e*n_a)
dphi_1d        = REFORM(dphi,n_e*n_a)
the_1d         = REFORM(the,n_e*n_a)
dthe_1d        = REFORM(dthe,n_e*n_a)
IF (test_en[0]) THEN BEGIN
  ;;  Angles
  phi_1d[bad_en]   = f
  dphi_1d[bad_en]  = f
  the_1d[bad_en]   = f
  dthe_1d[bad_en]  = f
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define high/low ranges of values
;;----------------------------------------------------------------------------------------
ener_l_1d  = ener_1d - dener_1d/2e0
ener_h_1d  = ener_1d + dener_1d/2e0
phi_l_1d   = phi_1d - dphi_1d/2e0
phi_h_1d   = phi_1d + dphi_1d/2e0
the_l_1d   = the_1d - dthe_1d/2e0
the_h_1d   = the_1d + dthe_1d/2e0
;;----------------------------------------------------------------------------------------
;;  Remove data associated with negative energies
;;----------------------------------------------------------------------------------------
low_en_l   = WHERE(ener_l_1d LE 0.,lwel)
low_en_h   = WHERE(ener_h_1d LE 0.,lweh)
gel_str    = {LOW:low_en_l,HIGH:low_en_h}
nlw_str    = {LOW:lwel,HIGH:lweh}
FOR j=0L, 1L DO BEGIN
  low_en  = gel_str.(j)
  lwe     = nlw_str.(j)
  IF (lwe GT 0L) THEN BEGIN
    ;;  kill "bad" data
    dat_1d[low_en]    = f
    ;;  kill "bad" energies
    ener_l_1d[low_en] = f
    ener_h_1d[low_en] = f
    ;;  kill "bad" angles
    phi_l_1d[low_en]  = f
    phi_h_1d[low_en]  = f
    the_l_1d[low_en]  = f
    the_h_1d[low_en]  = f
  ENDIF
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Convert energies/angles to cartesian velocity equivalents
;;----------------------------------------------------------------------------------------
;;  Magnitude of velocities from energy (km/s)
vmag_l          = energy_to_vel(ener_l_1d,mass[0])
vmag_h          = energy_to_vel(ener_h_1d,mass[0])
;;  Define sine and cosine of low angles
coth_l          = COS(the_l_1d*!DPI/18d1)
sith_l          = SIN(the_l_1d*!DPI/18d1)
coph_l          = COS(phi_l_1d*!DPI/18d1)
siph_l          = SIN(phi_l_1d*!DPI/18d1)
;;  Define sine and cosine of high angles
coth_h          = COS(the_h_1d*!DPI/18d1)
sith_h          = SIN(the_h_1d*!DPI/18d1)
coph_h          = COS(phi_h_1d*!DPI/18d1)
siph_h          = SIN(phi_h_1d*!DPI/18d1)
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;  permutations of these points creates a "cube" in cartesian space
;;      {i.e. volume element in spherical coordinates}
;;
;;     subscripts 'abc' definitions:
;;         a  :  0(1) = Low(High) Energy Value
;;         b  :  0(1) = Low(High) Azimuthal Angle Value
;;         c  :  0(1) = Low(High) Poloidal Angle Value
;;
;;
;;            '011'-------------'111'           'B'---------------'F'
;;             /I                /|             /I                /|
;;            / I               / |            / I               / |
;;           /  I              /  |           /  I              /  |
;;          /   I             /   |          /   I             /   |
;;         /    I            /    |         /    I            /    |
;;      '001'-------------'101'   |       'A'---------------'E'    |
;;        |     I           |     |        |     I           |     |
;;        |   '010'---------|---'110'      |    'D'----------|----'G'
;;        |    /            |    /         |    /            |    /
;;        |   /             |   /          |   /             |   /
;;        |  /              |  /           |  /              |  /
;;        | /               | /            | /               | /
;;        |/                |/             |/                |/
;;      '000'-------------'100'           'C'---------------'H'
;;
;;  
;;      theta      phi
;;        |        /
;;        |      /
;;        |    /
;;        |  /
;;        |/
;;        ----------> r
;;
;;     position definitions:
;;         C  :  000         H  :  100
;;         A  :  001         E  :  101
;;         B  :  011         F  :  111
;;         D  :  010         G  :  110
;;
;;     range definitions:
;;        dr  :  <EFGH>_r   - <ABCD>_r
;;      dphi  :  <BDFG>_phi - <ACEH>_phi
;;      dthe  :  <ABEF>_the - <CDGH>_the
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;  Define directions
mvel_000        = DBLARR(n_e*n_a,3L)
mvel_001        = DBLARR(n_e*n_a,3L)
mvel_010        = DBLARR(n_e*n_a,3L)
mvel_011        = DBLARR(n_e*n_a,3L)
mvel_100        = DBLARR(n_e*n_a,3L)
mvel_101        = DBLARR(n_e*n_a,3L)
mvel_110        = DBLARR(n_e*n_a,3L)
mvel_111        = DBLARR(n_e*n_a,3L)
;;----------------------------------------
;;  Low Energy Points
;;----------------------------------------
;;  000 vector directions
mvel_000[*,0]   = vmag_l*coth_l*coph_l   ;;  Define X-Velocity per energy per data bin
mvel_000[*,1]   = vmag_l*coth_l*siph_l   ;;  Define Y-Velocity per energy per data bin
mvel_000[*,2]   = vmag_l*sith_l          ;;  Define Z-Velocity per energy per data bin
;;  001 vector directions
mvel_001[*,0]   = vmag_l*coth_h*coph_l   ;;  X-Velocity
mvel_001[*,1]   = vmag_l*coth_h*siph_l   ;;  Y-Velocity
mvel_001[*,2]   = vmag_l*sith_h          ;;  Z-Velocity
;;  010 vector directions
mvel_010[*,0]   = vmag_l*coth_l*coph_h   ;;  X-Velocity
mvel_010[*,1]   = vmag_l*coth_l*siph_h   ;;  Y-Velocity
mvel_010[*,2]   = vmag_l*sith_l          ;;  Z-Velocity
;;  011 vector directions
mvel_011[*,0]   = vmag_l*coth_h*coph_h   ;;  X-Velocity
mvel_011[*,1]   = vmag_l*coth_h*siph_h   ;;  Y-Velocity
mvel_011[*,2]   = vmag_l*sith_h          ;;  Z-Velocity
;;----------------------------------------
;;  High Energy Points
;;----------------------------------------
;;  100 vector directions
mvel_100[*,0]   = vmag_h*coth_l*coph_l   ;;  X-Velocity
mvel_100[*,1]   = vmag_h*coth_l*siph_l   ;;  Y-Velocity
mvel_100[*,2]   = vmag_h*sith_l          ;;  Z-Velocity
;;  101 vector directions
mvel_101[*,0]   = vmag_h*coth_h*coph_l   ;;  X-Velocity
mvel_101[*,1]   = vmag_h*coth_h*siph_l   ;;  Y-Velocity
mvel_101[*,2]   = vmag_h*sith_h          ;;  Z-Velocity
;;  110 vector directions
mvel_110[*,0]   = vmag_h*coth_l*coph_h   ;;  X-Velocity
mvel_110[*,1]   = vmag_h*coth_l*siph_h   ;;  Y-Velocity
mvel_110[*,2]   = vmag_h*sith_l          ;;  Z-Velocity
;;  111 vector directions
mvel_111[*,0]   = vmag_h*coth_h*coph_h   ;;  X-Velocity
mvel_111[*,1]   = vmag_h*coth_h*siph_h   ;;  Y-Velocity
mvel_111[*,2]   = vmag_h*sith_h          ;;  Z-Velocity
;;----------------------------------------------------------------------------------------
;;  Subtract solar wind velocity
;;----------------------------------------------------------------------------------------
swfv_000        = mvel_000 - vsw_3dp_pts
swfv_001        = mvel_001 - vsw_3dp_pts
swfv_010        = mvel_010 - vsw_3dp_pts
swfv_011        = mvel_011 - vsw_3dp_pts
swfv_100        = mvel_100 - vsw_3dp_pts
swfv_101        = mvel_101 - vsw_3dp_pts
swfv_110        = mvel_110 - vsw_3dp_pts
swfv_111        = mvel_111 - vsw_3dp_pts
;;  Define Avg. velocity vectors [km/s]
low             = (swfv_000 + swfv_001 + swfv_010 + swfv_011)/4d0
high            = (swfv_100 + swfv_101 + swfv_110 + swfv_111)/4d0
swfv_avg        = (low + high)/2d0
;;  Define Avg. velocity magnitudes [km/s]
swmg_avg        = SQRT(TOTAL(swfv_avg^2,2,/NAN))
;;  Define Avg. poloidal angles [deg]  { -90 < theta < +90 }
the_avg         = ASIN(swfv_avg[*,2]/swmg_avg)*18e1/!PI
;;  Define Avg. azimuthal angles [deg]  {   0 < phi < +360 }
phi_avg         = ATAN(swfv_avg[*,1],swfv_avg[*,0])*18e1/!PI
phi_avg         = (phi_avg + 36e1) MOD 36e1
;;  Define new velocity magnitudes [km/s]
swmg_000        = SQRT(TOTAL(swfv_000^2,2,/NAN))
swmg_001        = SQRT(TOTAL(swfv_001^2,2,/NAN))
swmg_010        = SQRT(TOTAL(swfv_010^2,2,/NAN))
swmg_011        = SQRT(TOTAL(swfv_011^2,2,/NAN))
swmg_100        = SQRT(TOTAL(swfv_100^2,2,/NAN))
swmg_101        = SQRT(TOTAL(swfv_101^2,2,/NAN))
swmg_110        = SQRT(TOTAL(swfv_110^2,2,/NAN))
swmg_111        = SQRT(TOTAL(swfv_111^2,2,/NAN))
;;  Define new poloidal angles [deg]  { -90 < theta < +90 }
the_000         = ASIN(swfv_000[*,2]/swmg_000)*18e1/!PI
the_001         = ASIN(swfv_001[*,2]/swmg_001)*18e1/!PI
the_010         = ASIN(swfv_010[*,2]/swmg_010)*18e1/!PI
the_011         = ASIN(swfv_011[*,2]/swmg_011)*18e1/!PI
the_100         = ASIN(swfv_100[*,2]/swmg_100)*18e1/!PI
the_101         = ASIN(swfv_101[*,2]/swmg_101)*18e1/!PI
the_110         = ASIN(swfv_110[*,2]/swmg_110)*18e1/!PI
the_111         = ASIN(swfv_111[*,2]/swmg_111)*18e1/!PI
;;  Define new azimuthal angles [deg]  { -180 < phi < +180 }
phi_000         = ATAN(swfv_000[*,1],swfv_000[*,0])*18e1/!PI
phi_001         = ATAN(swfv_001[*,1],swfv_001[*,0])*18e1/!PI
phi_010         = ATAN(swfv_010[*,1],swfv_010[*,0])*18e1/!PI
phi_011         = ATAN(swfv_011[*,1],swfv_011[*,0])*18e1/!PI
phi_100         = ATAN(swfv_100[*,1],swfv_100[*,0])*18e1/!PI
phi_101         = ATAN(swfv_101[*,1],swfv_101[*,0])*18e1/!PI
phi_110         = ATAN(swfv_110[*,1],swfv_110[*,0])*18e1/!PI
phi_111         = ATAN(swfv_111[*,1],swfv_111[*,0])*18e1/!PI
;;  Shift azimuthal angles to {   0 < phi < +360 }
phi_000         = (phi_000 + 36e1) MOD 36e1
phi_001         = (phi_001 + 36e1) MOD 36e1
phi_010         = (phi_010 + 36e1) MOD 36e1
phi_011         = (phi_011 + 36e1) MOD 36e1
phi_100         = (phi_100 + 36e1) MOD 36e1
phi_101         = (phi_101 + 36e1) MOD 36e1
phi_110         = (phi_110 + 36e1) MOD 36e1
phi_111         = (phi_111 + 36e1) MOD 36e1
;;----------------------------------------------------------------------------------------
;;  Find range of values for each
;;----------------------------------------------------------------------------------------
swmg_ran        = DBLARR(n_e*n_a)
the_ran         = DBLARR(n_e*n_a)
phi_ran         = DBLARR(n_e*n_a)
;;--------------------------------------------------------
;;  Velocity ranges [km/s]
;;--------------------------------------------------------
avg_EFGH        = (swmg_100 + swmg_101 + swmg_110 + swmg_111)/4e0
avg_ABCD        = (swmg_000 + swmg_001 + swmg_010 + swmg_011)/4e0
swmg_ran        = avg_EFGH - avg_ABCD
;;  Check for "bad" values
bad             = WHERE(swmg_ran LT 0.,bd)
IF (bden GT 0L) THEN BEGIN
  swmg_ran[bad]   = f
  ;; kill data and averages as well
  dat_1d[bad]     = f
  swfv_avg[bad,*] = f
  swmg_avg[bad]   = f
  the_avg[bad]    = f
  phi_avg[bad]    = f
ENDIF
;;--------------------------------------------------------
;;  Poloidal angle ranges [km/s]
;;--------------------------------------------------------
avg_ABEF        = (the_001 + the_011 + the_101 + the_111)/4e0
avg_CDGH        = (the_000 + the_010 + the_100 + the_110)/4e0
the_ran         = avg_ABEF - avg_CDGH
;;  Check for "bad" values
bad             = WHERE(the_ran LT 0.,bd)
IF (bden GT 0L) THEN BEGIN
  the_ran[bad]    = f
  swmg_ran[bad]   = f
  ;; kill data and averages as well
  dat_1d[bad]     = f
  swfv_avg[bad,*] = f
  swmg_avg[bad]   = f
  the_avg[bad]    = f
  phi_avg[bad]    = f
ENDIF
;;--------------------------------------------------------
;;  Azimuthal angle ranges [km/s]
;;--------------------------------------------------------
avg_BDFG        = (phi_011 + phi_010 + phi_111 + phi_110)/4e0
avg_ACEH        = (phi_001 + phi_000 + phi_101 + phi_100)/4e0
phi_ran         = avg_BDFG - avg_ACEH
;;  Check for "bad" values
bad             = WHERE(phi_ran LT 0.,bd)
IF (bden GT 0L) THEN BEGIN
  phi_ran[bad]    = f
  the_ran[bad]    = f
  swmg_ran[bad]   = f
  ;; kill data and averages as well
  dat_1d[bad]     = f
  swfv_avg[bad,*] = f
  swmg_avg[bad]   = f
  the_avg[bad]    = f
  phi_avg[bad]    = f
ENDIF
;;----------------------------------------------------------------------------------------
;;  Convert speeds to energies [eV]
;;----------------------------------------------------------------------------------------
ener_avg        = energy_to_vel(swmg_avg,mass[0],/INVERSE)
ener_ran        = energy_to_vel(swmg_ran,mass[0],/INVERSE)
;;----------------------------------------------------------------------------------------
;;  Refrom arrays back to 2D
;;----------------------------------------------------------------------------------------
;;  Define 2D Data
IF (szt_dtpe[0] EQ 4) THEN data_2d = FLOAT(REFORM(dat_1d,n_e,n_a)) ELSE data_2d = DOUBLE(REFORM(dat_1d,n_e,n_a))
;;  Define 2D Poloidal Angles
IF (szt_dtpe[1] EQ 4) THEN BEGIN
  the_2d  = FLOAT(REFORM(the_avg,n_e,n_a))
  dthe_2d = FLOAT(REFORM(the_ran,n_e,n_a))
ENDIF ELSE BEGIN
  the_2d  = DOUBLE(REFORM(the_avg,n_e,n_a))
  dthe_2d = DOUBLE(REFORM(the_ran,n_e,n_a))
ENDELSE
;;  Define 2D Azimuthal Angles
IF (szt_dtpe[2] EQ 4) THEN BEGIN
  phi_2d  = FLOAT(REFORM(phi_avg,n_e,n_a))
  dphi_2d = FLOAT(REFORM(phi_ran,n_e,n_a))
ENDIF ELSE BEGIN
  phi_2d  = DOUBLE(REFORM(phi_avg,n_e,n_a))
  dphi_2d = DOUBLE(REFORM(phi_ran,n_e,n_a))
ENDELSE
;;  Define 2D Energies
IF (szt_dtpe[3] EQ 4) THEN BEGIN
  ener_2d  = FLOAT(REFORM(ener_avg,n_e,n_a))
  dener_2d = FLOAT(REFORM(ener_ran,n_e,n_a))
ENDIF ELSE BEGIN
  ener_2d  = DOUBLE(REFORM(ener_avg,n_e,n_a))
  dener_2d = DOUBLE(REFORM(ener_ran,n_e,n_a))
ENDELSE
;the_2d          = REFORM(the_avg,n_e,n_a)
;dthe_2d         = REFORM(the_ran,n_e,n_a)
;phi_2d          = REFORM(phi_avg,n_e,n_a)
;dphi_2d         = REFORM(phi_ran,n_e,n_a)
;ener_2d         = REFORM(ener_avg,n_e,n_a)
;dener_2d        = REFORM(ener_ran,n_e,n_a)
;data_2d         = REFORM(dat_1d,n_e,n_a)
;ind_1d_to_2d    = REFORM(ind_1d,n_e,n_a)
;;----------------------------------------------------------------------------------------
;;  Redefine structure tag values
;;----------------------------------------------------------------------------------------
dat             = data
dat.DATA        = data_2d
dat.ENERGY      = ener_2d
dat.DENERGY     = dener_2d

dat.THETA       = the_2d
dat.DTHETA      = dthe_2d
dat.PHI         = phi_2d
dat.DPHI        = dphi_2d
;;----------------------------------------------------------------------------------------
;;  Return modified structure to user
;;----------------------------------------------------------------------------------------

RETURN
END




;;----------------------------------------------------------------------------------------
; => Find mean values for each
;;----------------------------------------------------------------------------------------
;swmg_avg        = DBLARR(n_e*n_a)
;the_avg         = DBLARR(n_e*n_a)
;phi_avg         = DBLARR(n_e*n_a)
; => Define Avg. velocity magnitudes [km/s]
;low             = (swmg_000 + swmg_001 + swmg_010 + swmg_011)/4d0
;high            = (swmg_100 + swmg_101 + swmg_110 + swmg_111)/4d0
;swmg_avg        = (low + high)/2d0
; => Define Avg. poloidal angles [deg]  { -90 < theta < +90 }
;low             = (the_000 + the_001 + the_010 + the_011)/4d0
;high            = (the_100 + the_101 + the_110 + the_111)/4d0
;the_avg         = (low + high)/2d0
; => Define Avg. azimuthal angles [deg]  {   0 < phi < +360 }
;low             = (phi_000 + phi_001 + phi_010 + phi_011)/4d0
;high            = (phi_100 + phi_101 + phi_110 + phi_111)/4d0
;phi_avg         = (low + high)/2d0

;;----------------------------------------------------------------------------------------
;d_100_000       = ABS(swmg_100 - swmg_000)
;d_100_001       = ABS(swmg_100 - swmg_001)
;d_100_010       = ABS(swmg_100 - swmg_010)
;d_100_011       = ABS(swmg_100 - swmg_011)
;d_100           = d_100_000 > d_100_001
;d_100           = d_100     > (d_100_010 > d_100_011)
;d_101_000       = ABS(swmg_101 - swmg_000)
;d_101_001       = ABS(swmg_101 - swmg_001)
;d_101_010       = ABS(swmg_101 - swmg_010)
;d_101_011       = ABS(swmg_101 - swmg_011)
;d_101           = d_101_000 > d_101_001
;d_101           = d_101     > (d_101_010 > d_101_011)
;d_110_000       = ABS(swmg_110 - swmg_000)
;d_110_001       = ABS(swmg_110 - swmg_001)
;d_110_010       = ABS(swmg_110 - swmg_010)
;d_110_011       = ABS(swmg_110 - swmg_011)
;d_110           = d_110_000 > d_110_001
;d_110           = d_110     > (d_110_010 > d_110_011)
;d_111_000       = ABS(swmg_111 - swmg_000)
;d_111_001       = ABS(swmg_111 - swmg_001)
;d_111_010       = ABS(swmg_111 - swmg_010)
;d_111_011       = ABS(swmg_111 - swmg_011)
;d_111           = d_111_000 > d_111_001
;d_111           = d_111     > (d_111_010 > d_111_011)
; => define the maximum range of values
;d_ran           = (d_110 > d_111) > (d_100 > d_101)
;swmg_ran        = d_ran

;;----------------------------------------------------------------------------------------
;d_100_000       = ABS(the_100 - the_000)
;d_100_001       = ABS(the_100 - the_001)
;d_100_010       = ABS(the_100 - the_010)
;d_100_011       = ABS(the_100 - the_011)
;d_100           = d_100_000 > d_100_001
;d_100           = d_100     > (d_100_010 > d_100_011)
;d_101_000       = ABS(the_101 - the_000)
;d_101_001       = ABS(the_101 - the_001)
;d_101_010       = ABS(the_101 - the_010)
;d_101_011       = ABS(the_101 - the_011)
;d_101           = d_101_000 > d_101_001
;d_101           = d_101     > (d_101_010 > d_101_011)
;d_110_000       = ABS(the_110 - the_000)
;d_110_001       = ABS(the_110 - the_001)
;d_110_010       = ABS(the_110 - the_010)
;d_110_011       = ABS(the_110 - the_011)
;d_110           = d_110_000 > d_110_001
;d_110           = d_110     > (d_110_010 > d_110_011)
;d_111_000       = ABS(the_111 - the_000)
;d_111_001       = ABS(the_111 - the_001)
;d_111_010       = ABS(the_111 - the_010)
;d_111_011       = ABS(the_111 - the_011)
;d_111           = d_111_000 > d_111_001
;d_111           = d_111     > (d_111_010 > d_111_011)
; => define the maximum range of values
;d_ran           = (d_110 > d_111) > (d_100 > d_101)
;the_ran         = d_ran

;;----------------------------------------------------------------------------------------
;d_100_000       = ABS(phi_100 - phi_000)
;d_100_001       = ABS(phi_100 - phi_001)
;d_100_010       = ABS(phi_100 - phi_010)
;d_100_011       = ABS(phi_100 - phi_011)
;d_100           = d_100_000 > d_100_001
;d_100           = d_100     > (d_100_010 > d_100_011)
;d_101_000       = ABS(phi_101 - phi_000)
;d_101_001       = ABS(phi_101 - phi_001)
;d_101_010       = ABS(phi_101 - phi_010)
;d_101_011       = ABS(phi_101 - phi_011)
;d_101           = d_101_000 > d_101_001
;d_101           = d_101     > (d_101_010 > d_101_011)
;d_110_000       = ABS(phi_110 - phi_000)
;d_110_001       = ABS(phi_110 - phi_001)
;d_110_010       = ABS(phi_110 - phi_010)
;d_110_011       = ABS(phi_110 - phi_011)
;d_110           = d_110_000 > d_110_001
;d_110           = d_110     > (d_110_010 > d_110_011)
;d_111_000       = ABS(phi_111 - phi_000)
;d_111_001       = ABS(phi_111 - phi_001)
;d_111_010       = ABS(phi_111 - phi_010)
;d_111_011       = ABS(phi_111 - phi_011)
;d_111           = d_111_000 > d_111_001
;d_111           = d_111     > (d_111_010 > d_111_011)
; => define the maximum range of values
;d_ran           = (d_110 > d_111) > (d_100 > d_101)
;phi_ran         = d_ran
