;+
;*****************************************************************************************
;
;  FUNCTION :   merge_themis_esa_structs.pro
;  PURPOSE  :   This routine takes the pointer outputs from themis_load_fgm_esa_inst.pro
;                 and creates arrays of structures instead.  This routine was created to
;                 maintain continuity with previous methods of saving ESA data.
;
;  CALLED BY:   
;               load_save_themis_fgm_esa_batch.pro
;
;  CALLS:
;               dat_themis_esa_str_names.pro
;               themis_eesa_dummy_struc.pro
;               themis_iesa_dummy_struc.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries and UMN Modified Wind/3DP IDL Libraries
;               2)  MUST run comp_lynn_pros.pro prior to calling this routine
;
;  INPUT:
;               POINTER  :  Scalar [structure] containing either or both the following
;                             tags:  FULL and/or BURST.  Each tag must be an array of
;                             pointers.  Within each pointer are arrays of structures,
;                             where the structures are those associated with the THEMIS
;                             ESA instruments [see get_th?_peib.pro, ? = a-f].  The
;                             POINTER variable can be the output returned by either
;                             of the following keywords EESA_DF_OUT or IESA_DF_OUT from
;                             the routine themis_load_fgm_esa_inst.pro
;
;  EXAMPLES:    
;               mergedstr = merge_themis_esa_structs(pointer)
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [12/09/2014   v1.0.0]
;             2)  Fixed an issue resulting from the increase in elements which caused
;                   a difference in size of [E,A]-element arrays and the values
;                   associated with the NBINS and NENERGY structure tags
;                                                                   [12/11/2014   v1.0.1]
;
;   NOTES:      
;               1)  The routine finds the largest sized arrays of FULL or BURST data
;                     structures and then creates dummy copies.  The copies are then
;                     filled, where each tag will contain finite values for the first
;                     N-finite values in the original structure.  For instance, some
;                     IESA FULL structures have [15]-energy bins and [88]-solid-angle
;                     bins while others are [32,88]-elements.  So assume [32,88]
;                     is the largest sized array, then the structures with only 15
;                     energy bins will fill elements from 0--14.  Elements 15--31 will
;                     remain defined as NaNs.
;               2)  IDL ??? v8.4 allows for a looser definition of structures so that this
;                     routine may be obsolete for users with later versions of IDL.
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
;   CREATED:  12/08/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  12/11/2014   v1.0.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION merge_themis_esa_structs,pointer

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
dumb           = 0
;;  Define default values for Probe, Instrument Mode, Units, and Units Procedure
probe          = 'a'
inst_mode      = 'peeb'
units          = 'counts'
units_pro      = 'thm_convert_esa_units'
;;  Define default values for the number of energy and angle bins
N_E            = 32
N_A            = 88
;;  Define logic variables that inform routine whether POINTER contains EESA or IESA structures
eesa           = 0b
iesa           = 0b
;;  Define strings that define which dummy structure routine to call
dummy_str_func = ['themis_eesa_dummy_struc','themis_iesa_dummy_struc']
;;  Dummy error messages
noinpt_msg     = 'User must supply POINTER variable containing arrays of structures as heap variables...'
nofind_msg     = 'Incorrect input format...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() NE 1)
IF (test) THEN BEGIN
  MESSAGE,noinpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF ELSE BEGIN
  test           = (SIZE(pointer,/TYPE) NE 8)
  IF (test) THEN BEGIN
    MESSAGE,nofind_msg,/INFORMATIONAL,/CONTINUE
    RETURN,0b
  ENDIF
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Check input format
;;----------------------------------------------------------------------------------------
npt            = N_TAGS(pointer)
ptags          = STRLOWCASE(TAG_NAMES(pointer))
checks         = ['full','burst']
checkp         = BYTARR(2,npt)
FOR j=0L, 1L DO checkp[j,*] = (checks[j] EQ ptags)
test__full     = (TOTAL(checkp[0,*]) EQ 1)
test_burst     = (TOTAL(checkp[1,*]) EQ 1)
IF (test__full) THEN nef = N_ELEMENTS(pointer.FULL)  ELSE nef = 0L
IF (test_burst) THEN neb = N_ELEMENTS(pointer.BURST) ELSE neb = 0L
;;----------------------------------------------------------------------------------------
;;  Determine the largest size for [E,A]-Element array and then
;;  create a dummy array for that structure type to fill
;;    E  :  # of energy bins
;;    A  :  # of angle bins
;;----------------------------------------------------------------------------------------
nf_s           = 0L                                 ;;  Total # of Full VDFs
nb_s           = 0L                                 ;;  Total # of Burst VDFs
test           = (nef[0] GT 0)
IF (test) THEN BEGIN
  test = (SIZE(pointer.FULL,/TYPE) NE 10)
  IF (test) THEN GOTO,JUMP_SKIPF
  ;;--------------------------------------------------------------------------------------
  ;;  FULL VDFs were found
  ;;--------------------------------------------------------------------------------------
  nf_sa = LONARR(nef[0])
  FOR j=0L, nef[0] - 1L DO BEGIN
    temp  = *(pointer.FULL)[j]
    ;;  Make sure these are THEMIS structures
    strns = dat_themis_esa_str_names(temp[0],/NOM)
    test  = (SIZE(strns,/TYPE) NE 8)
    IF (test) THEN CONTINUE                         ;;  If true --> not THEMIS structures
    test  = STRMATCH(strns[0].SN[0],'pe*f',/FOLD_CASE) NE 1
    IF (test) THEN CONTINUE                         ;;  If true --> not currently allowing SST structures
    nf_sa[j] = N_ELEMENTS(temp)                     ;;  Keep track to use later
    IF (j[0] EQ 0) THEN BEGIN
      nf_s      = N_ELEMENTS(temp)                  ;;  Total # of Full VDFs in j-th pointer
      n_ef      = MAX(temp.NENERGY,/NAN)            ;;  # of energy bins
      n_af      = MAX(temp.NBINS,/NAN)              ;;  # of angle bins
      probe     = temp[0].SPACECRAFT[0]             ;;  e.g., 'a' for Probe A
      inst_mode = strns[0].SN[0]                    ;;  e.g., 'peef' for EESA 3D Full
      units     = temp[0].UNITS_NAME[0]             ;;  e.g., 'counts' for # of integer counts
      units_pro = temp[0].UNITS_PROCEDURE[0]        ;;  e.g., 'thm_convert_esa_units'
      ;;  Determine if EESA or IESA
      temp_str  = STRLOWCASE(STRMID(strns[0].LC[0],0L,1L))
      test      = (temp_str[0] EQ 'e')
      IF (test) THEN eesa = 1b ELSE iesa = 1b
    ENDIF ELSE BEGIN
      nf_s     += N_ELEMENTS(temp)                  ;;  Cumulative total # of Full VDFs
      n_ef      = n_ef[0] > MAX(temp.NENERGY,/NAN)  ;;  # of energy bins
      n_af      = n_af[0] > MAX(temp.NBINS,/NAN)    ;;  # of angle bins
    ENDELSE
  ENDFOR
  IF (eesa EQ 0 AND iesa EQ 0) THEN STOP   ;;  something is wrong --> debug
  ;;--------------------------------------------------------------------------------------
  ;;  Create dummy array of FULL VDFs
  ;;--------------------------------------------------------------------------------------
  good      = WHERE([eesa,iesa],gd)
  func      = dummy_str_func[good[0]]
  ;;  Define string to be used by EXECUTE.PRO
  exstr     = 'dumb = '+func[0]+'(PROBE=probe,INST_MODE=inst_mode,UNITS=units,'
  exstr     = exstr[0]+'UNIT_PROC=units_pro,NENER=n_ef,NANGL=n_af)'
  result    = EXECUTE(exstr[0])
  test      = (result EQ 0) OR (SIZE(dumb,/TYPE) NE 8)
  IF (test) THEN STOP   ;;  something is wrong --> debug
  ;;  Create array of copies of DUMB
  IF (nf_s[0] EQ 0) THEN STOP   ;;  something is wrong --> debug
  dat__full = REPLICATE(dumb[0],nf_s[0])
  nt0       = N_TAGS(dumb[0])   ;;  # of tags in each structure
  tagnms0   = STRLOWCASE(TAG_NAMES(dumb[0]))
  ;;--------------------------------------------------------------------------------------
  ;;  Fill dummy array of FULL VDFs
  ;;--------------------------------------------------------------------------------------
  cc        = 0L                                    ;;  Use for indexing dat__full
  FOR j=0L, nef[0] - 1L DO BEGIN
    test  = (nf_sa[j] EQ 0)
    IF (test) THEN CONTINUE                         ;;  If true --> not valid array of structures
    temp  = *(pointer.FULL)[j]
    ;;  Fill each structure tag
    FOR i=0L, nt0[0] - 1L DO BEGIN
      ;;  Vectorize instead of using FOR loop
      szni  = SIZE(temp[0].(i),/N_DIMENSIONS)
      szdi  = SIZE(temp[0].(i),/DIMENSIONS)
      ginds = LINDGEN(nf_sa[j]) + cc[0]
      test  = (tagnms0[i] EQ 'nbins') OR (tagnms0[i] EQ 'nenergy')
      IF (test) THEN BEGIN
        ;;  Make sure NBINS and NENERGY structure tags are set correctly
        dat__full[ginds].(i) = (dumb[0].(i))[0]
      ENDIF ELSE BEGIN
        IF (szni[0] EQ 2) THEN BEGIN
          ;;  2D array
          gind0 = LINDGEN(szdi[0])
          gind1 = LINDGEN(szdi[1])
          tempk = dat__full[ginds].(i)
          tempk[gind0,gind1,*] = temp.(i)
          dat__full[ginds].(i) = tempk
        ENDIF ELSE BEGIN
          ;;  1D array or scalar
          dat__full[ginds].(i) = temp.(i)
        ENDELSE
      ENDELSE
    ENDFOR
    ;;  Increment dat__full index
    cc += nf_sa[j]
  ENDFOR
ENDIF ELSE BEGIN
  ;;  FULL VDFs were not found
  dat__full = 0b
ENDELSE
;;========================================================================================
JUMP_SKIPF:
;;========================================================================================
;;----------------------------------------------------------------------------------------
;;  Fill Burst Structures (if provided)
;;----------------------------------------------------------------------------------------
eesa           = 0b
iesa           = 0b
test           = (neb[0] GT 0)
IF (test) THEN BEGIN
  test = (SIZE(pointer.BURST,/TYPE) NE 10)
  IF (test) THEN GOTO,JUMP_SKIPB
  ;;--------------------------------------------------------------------------------------
  ;;  BURST VDFs were found
  ;;--------------------------------------------------------------------------------------
  nb_sa = LONARR(neb[0])
  FOR j=0L, neb[0] - 1L DO BEGIN
    temp  = *(pointer.BURST)[j]
    ;;  Make sure these are THEMIS structures
    strns = dat_themis_esa_str_names(temp[0],/NOM)
    test  = (SIZE(strns,/TYPE) NE 8)
    IF (test) THEN CONTINUE                         ;;  If true --> not THEMIS structures
    test  = STRMATCH(strns[0].SN[0],'pe*b',/FOLD_CASE) NE 1
    IF (test) THEN CONTINUE                         ;;  If true --> not currently allowing SST structures
    nb_sa[j] = N_ELEMENTS(temp)                     ;;  Keep track to use later
    IF (j[0] EQ 0) THEN BEGIN
      nb_s      = N_ELEMENTS(temp)                  ;;  Total # of Burst VDFs in j-th pointer
      n_eb      = MAX(temp.NENERGY,/NAN)            ;;  # of energy bins
      n_ab      = MAX(temp.NBINS,/NAN)              ;;  # of angle bins
      probe     = temp[0].SPACECRAFT[0]             ;;  e.g., 'a' for Probe A
      inst_mode = strns[0].SN[0]                    ;;  e.g., 'peeb' for EESA 3D Burst
      units     = temp[0].UNITS_NAME[0]             ;;  e.g., 'counts' for # of integer counts
      units_pro = temp[0].UNITS_PROCEDURE[0]        ;;  e.g., 'thm_convert_esa_units'
      ;;  Determine if EESA or IESA
      temp_str  = STRLOWCASE(STRMID(strns[0].LC[0],0L,1L))
      test      = (temp_str[0] EQ 'e')
      IF (test) THEN eesa = 1b ELSE iesa = 1b
    ENDIF ELSE BEGIN
      nb_s     += N_ELEMENTS(temp)                  ;;  Cumulative total # of Burst VDFs
      n_eb      = n_eb[0] > MAX(temp.NENERGY,/NAN)  ;;  # of energy bins
      n_ab      = n_ab[0] > MAX(temp.NBINS,/NAN)    ;;  # of angle bins
    ENDELSE
  ENDFOR
  IF (eesa EQ 0 AND iesa EQ 0) THEN STOP   ;;  something is wrong --> debug
  ;;--------------------------------------------------------------------------------------
  ;;  Create dummy array of BURST VDFs
  ;;--------------------------------------------------------------------------------------
  good      = WHERE([eesa,iesa],gd)
  func      = dummy_str_func[good[0]]
  ;;  Define string to be used by EXECUTE.PRO
  exstr     = 'dumb = '+func[0]+'(PROBE=probe,INST_MODE=inst_mode,UNITS=units,'
  exstr     = exstr[0]+'UNIT_PROC=units_pro,NENER=n_eb,NANGL=n_ab)'
  result    = EXECUTE(exstr[0])
  test      = (result EQ 0) OR (SIZE(dumb,/TYPE) NE 8)
  IF (test) THEN STOP   ;;  something is wrong --> debug
  ;;  Create array of copies of DUMB
  IF (nb_s[0] EQ 0) THEN STOP   ;;  something is wrong --> debug
  dat_burst = REPLICATE(dumb[0],nb_s[0])
  nt0       = N_TAGS(dumb[0])   ;;  # of tags in each structure
  tagnms0   = STRLOWCASE(TAG_NAMES(dumb[0]))
  ;;--------------------------------------------------------------------------------------
  ;;  Fill dummy array of BURST VDFs
  ;;--------------------------------------------------------------------------------------
  cc        = 0L                                    ;;  Use for indexing dat_burst
  FOR j=0L, neb[0] - 1L DO BEGIN
    test  = (nb_sa[j] EQ 0)
    IF (test) THEN CONTINUE                         ;;  If true --> not valid array of structures
    temp  = *(pointer.BURST)[j]
    ;;  Fill each structure tag
    FOR i=0L, nt0[0] - 1L DO BEGIN
      ;;  Vectorize instead of using FOR loop
      szni  = SIZE(temp[0].(i),/N_DIMENSIONS)
      szdi  = SIZE(temp[0].(i),/DIMENSIONS)
      ginds = LINDGEN(nb_sa[j]) + cc[0]
      test  = (tagnms0[i] EQ 'nbins') OR (tagnms0[i] EQ 'nenergy')
      IF (test) THEN BEGIN
        ;;  Make sure NBINS and NENERGY structure tags are set correctly
        dat__full[ginds].(i) = (dumb[0].(i))[0]
      ENDIF ELSE BEGIN
        IF (szni[0] EQ 2) THEN BEGIN
          ;;  2D array
          gind0 = LINDGEN(szdi[0])
          gind1 = LINDGEN(szdi[1])
          tempk = dat_burst[ginds].(i)
          tempk[gind0,gind1,*] = temp.(i)
          dat_burst[ginds].(i) = tempk
        ENDIF ELSE BEGIN
          ;;  1D array or scalar
          dat_burst[ginds].(i) = temp.(i)
        ENDELSE
      ENDELSE
    ENDFOR
    ;;  Increment dat_burst index
    cc += nb_sa[j]
  ENDFOR
ENDIF ELSE BEGIN
  ;;  BURST VDFs were not found
  dat_burst = 0b
ENDELSE
;;========================================================================================
JUMP_SKIPB:
;;========================================================================================
;;----------------------------------------------------------------------------------------
;;  Define return structure
;;----------------------------------------------------------------------------------------
;;  Check to see if structures were defined
IF (SIZE(dat__full,/TYPE) NE 8) THEN dat__full = 0b
IF (SIZE(dat_burst,/TYPE) NE 8) THEN dat_burst = 0b
struc          = {FULL:dat__full,BURST:dat_burst}
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struc
END
