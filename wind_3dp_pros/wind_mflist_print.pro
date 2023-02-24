;+
;*****************************************************************************************
;
;  PROCEDURE:   wind_mflist_print.pro
;  PURPOSE  :   This routine prints the masterfile list used by the Wind/3DP
;                 initialization software to locate data files.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               get_os_slash.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               ;;  Print out 3DP level zero (lz) master file list
;               wind_mflist_print
;               ;;  Print out 3DP level zero (lz) master file list
;               inst = '3dp'
;               dtyp = 'lz'
;               wind_mflist_print,INSTR=inst[0],DTYPE=dtyp[0]
;               ;;  Print out MFI H0 master file list
;               inst = 'mfi'
;               dtyp = 'h0'
;               wind_mflist_print,INSTR=inst[0],DTYPE=dtyp[0]
;
;  KEYWORDS:    
;               DIRECTORY  :  Scalar [string] defining the directory path to the data
;                               type of interest specified by DTYPE.  The path should
;                               tell the routine where ~/wind_data_dir is located.
;                               {Default = FILE_EXPAND_PATH('wind_3dp_pros/wind_data_dir/')}
;               INSTR      :  Scalar [string] defining the instrument that measures the
;                               data type of interest specified by DTYPE.  The accepted
;                               inputs are given by:
;                                 '3dp' = 3DP [Lin et al., 1995] {** Default **}
;                                 'swe' = SWE [Ogilvie et al., 1995]
;                                 'mfi' = MFI [Lepping et al., 1995]
;                                 {Default = '3dp'}
;               DTYPE      :  Scalar [string] defining the data type of interest.  The
;                               accepted inputs are given by:
;                                 '3dp'
;                                   'elsp'  ->  EL energy spectra
;                                   'plsp'  ->  PL energy spectra
;                                   'k0'    ->  Key Parameters
;                                   'lz'    ->  Level Zero data {** Default **}
;                                 'swe'
;                                   'k0'    ->  Key Parameters {** Default **}
;                                   'h1'    ->  Nonlinear moment analysis [92 s]
;                                 'mfi'
;                                   'h0'  ->  3s resolution {** Default **}
;                                   'h2'  ->  ~11-22 samples/second
;
;   CHANGED:  1)  Added 'h1' as a data type option for the SWE instrument
;                                                                   [01/24/2014   v1.0.1]
;             2)  Updated date ranges for master list outputs
;                                                                   [08/08/2016   v1.0.2]
;
;   NOTES:      
;               0)  Unless you have changed data file locations on your machine, do
;                     NOT use the DIRECTORY keyword
;               1)  Version numbers may vary over time, so make sure after producing
;                     these lists that you take care to check the version number of
;                     each file so that it matches.
;               2)  Abbreviations used for various things:
;                     [E,P]L  =  [EESA,PESA] Low
;                             =  [Electrons,Ions] from ~few eV to [~1.1,~10] keV
;
;  REFERENCES:  
;               1)  Lin et al., (1995), "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125-153, doi:10.1007/BF00751328.
;               2)  Lepping et al., (1995), "The Wind Magnetic Field Investigation,"
;                      Space Sci. Rev. Vol. 71, pp. 207-229, doi:10.1007/BF00751330.
;               3)  Ogilvie et al., (1995), "SWE, A Comprehensive Plasma Instrument
;                      for the Wind Spacecraft," Space Sci. Rev. Vol. 71, pp. 55-77,
;                      doi:10.1007/BF00751326.
;
;   CREATED:  08/07/2013
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/08/2016   v1.0.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO wind_mflist_print,DIRECTORY=directory,INSTR=instr,DTYPE=dtype

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
slash          = get_os_slash()         ;;  '/' for Unix, '\' for Windows
mdir           = FILE_EXPAND_PATH('wind_3dp_pros'+slash[0])
;;  Check for trailing '/' or '\'
ll             = STRMID(mdir, STRLEN(mdir) - 1L,1L)
test_ll        = (ll[0] NE slash[0])
IF (test_ll) THEN mdir = mdir[0]+slash[0]
;;  Define defaults
def_dir        = mdir[0]+'wind_data_dir'+slash[0]
def_ins        = '3dp'
def_dty        = 'lz'
def_suffx      = 'data1'+slash[0]+'wind'+slash[0]
def_time       = '????-??-??/??:??:?? ????-??-??/??:??:?? '
tsuff          = '/00:00:00'
;;  Define options
opt_ins        = ['3dp','swe','mfi']
opt_dty        = ['h0','h1','h2','k0','lz','elsp','plsp']
opt_dty_3dp    = ['k0','lz','elsp','plsp']
opt_dty_swe    = ['k0','h1']
opt_dty_mfi    = ['h0','h2']
;;  Dummy error messages
incompdi_msg   = 'DTYPE must be compatible with INSTR!  Using default [see Man. page]...'
;;----------------------------------------------------------------------------------------
;;  Define system variable parameters
;;----------------------------------------------------------------------------------------
;vers           = !VERSION
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check DIRECTORY
test           = (N_ELEMENTS(directory) EQ 0) OR (SIZE(directory,/TYPE) NE 7)
IF (test) THEN BEGIN
  d_dir = def_dir[0]
ENDIF ELSE BEGIN
  tdir  = FILE_EXPAND_PATH(directory[0])
  test  = FILE_TEST(tdir,/DIRECTORY) EQ 0
  IF (test) THEN d_dir = def_dir[0] ELSE d_dir = directory[0]
ENDELSE
;;  Check INSTR
test           = (N_ELEMENTS(instr) EQ 0) OR (SIZE(instr,/TYPE) NE 7)
IF (test) THEN BEGIN
  d_ins = def_ins[0]
ENDIF ELSE BEGIN
  test  = TOTAL(instr[0] EQ opt_ins) EQ 0
  IF (test) THEN d_ins = def_ins[0] ELSE d_ins = instr[0]
ENDELSE
;;  Check DTYPE
test           = (N_ELEMENTS(dtype) EQ 0) OR (SIZE(dtype,/TYPE) NE 7)
IF (test) THEN BEGIN
  d_dty = def_dty[0]
ENDIF ELSE BEGIN
  test  = TOTAL(dtype[0] EQ opt_dty) EQ 0
  IF (test) THEN d_dty = def_dty[0] ELSE d_dty = dtype[0]
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Make sure instrument and data types are compatible
;;----------------------------------------------------------------------------------------
CASE d_ins[0] OF
  '3dp' : BEGIN
    test  = TOTAL(d_dty[0] EQ opt_dty_3dp) EQ 0
    IF (test) THEN BEGIN
      MESSAGE,incompdi_msg[0],/INFORMATIONAL,/CONTINUE
      d_dty = 'lz'
    ENDIF
    ;;  Add on 3DP locations to directory path
    d_dir = d_dir[0]+def_suffx[0]+'3dp'+slash[0]+d_dty[0]+slash[0]
    ;;  Define file prefixes and suffixes
    CASE d_dty[0] OF
      'k0' : BEGIN
        fpref = 'wi_k0_3dp_'
        fsuff = '_v??.cdf'
      END
      'lz' : BEGIN
        fpref = 'wi_lz_3dp_'
        fsuff = '_v??.dat'
      END
      'elsp' : BEGIN
        fpref = 'wi_elsp_3dp_'
        fsuff = '_v??.cdf'
      END
      'plsp' : BEGIN
        fpref = 'wi_plsp_3dp_'
        fsuff = '_v??.cdf'
      END
    ENDCASE
  END
  'swe' : BEGIN
    test  = TOTAL(d_dty[0] EQ opt_dty_swe) EQ 0
    IF (test) THEN BEGIN
      MESSAGE,incompdi_msg[0],/INFORMATIONAL,/CONTINUE
      d_dty = 'k0'
    ENDIF
    ;;  Add on SWE locations to directory path
    d_dir = d_dir[0]+def_suffx[0]+'swe'+slash[0]+d_dty[0]+slash[0]
    ;;  Define file prefixes and suffixes
    CASE d_dty[0] OF
      'k0' : BEGIN
        fpref = 'wi_k0_swe_'
        fsuff = '_v??.cdf'
      END
      'h1' : BEGIN
        fpref = 'wi_h1_swe_'
        fsuff = '_v??.cdf'
      END
    ENDCASE
  END
  'mfi' : BEGIN
    test  = TOTAL(d_dty[0] EQ opt_dty_mfi) EQ 0
    IF (test) THEN BEGIN
      MESSAGE,incompdi_msg[0],/INFORMATIONAL,/CONTINUE
      d_dty = 'h0'
    ENDIF
    ;;  Add on MFI locations to directory path and define file prefixes and suffixes
    fsuff = '_v??.cdf'
    CASE d_dty[0] OF
      'h0' : BEGIN
        d_dir = d_dir[0]+'MFI_CDF'+slash[0]
        fpref = 'wi_h0_mfi_'
      END
      'h2' : BEGIN
        d_dir = d_dir[0]+'HTR_MFI_CDF'+slash[0]
        fpref = 'wi_h2_mfi_'
      END
    ENDCASE
  END
ENDCASE
;;----------------------------------------------------------------------------------------
;;  Define file parameters
;;----------------------------------------------------------------------------------------
;;  Define a dummy string to determine length in # of characters
dumb           = d_dir[0]+'????'+slash[0]+fpref[0]+'????????'+fsuff[0]
dlen           = STRLEN(dumb[0])
slen           = STRING(FORMAT='(I3.3)',dlen[0])
;;  Define output file name
fname          = fpref[0]+'files'      ;;  e.g., 'wi_lz_3dp_files'
;;  Define print format
mform          = '(a'+slen[0]+')'
;;----------------------------------------------------------------------------------------
;;  Define date parameters
;;----------------------------------------------------------------------------------------
nyr            = 40L                   ;;  # of years to print
;nyr            = 20L                   ;;  # of years to print
ndy            = 31L                   ;;  # of days to print
nmn            = 12L                   ;;  # of months to print
days           = LINDGEN(ndy) + 1L     ;;  day of month
months         = LINDGEN(nmn) + 1L     ;;  month of year
years          = LINDGEN(nyr) + 1994L  ;;  year
dstr           = STRING(FORMAT='(I2.2)',days)
mstr           = STRING(FORMAT='(I2.2)',months)
ystr           = STRING(FORMAT='(I4.4)',years)
d_string       = STRARR(nyr,nmn,ndy + 1L)  ;;  e.g. '1994-01-01/00:00:00'
dfstring       = STRARR(nyr,nmn,ndy + 1L)  ;;  e.g. '19940101'
FOR yy=0L, nyr - 1L DO BEGIN      ;;  Years
  FOR mm=0L, nmn - 1L DO BEGIN    ;;  Months
    FOR dd=0L, ndy - 1L DO BEGIN  ;;  Days
      d_string[yy,mm,dd] = ystr[yy]+'-'+mstr[mm]+'-'+dstr[dd]+tsuff[0]
      dfstring[yy,mm,dd] = ystr[yy]+mstr[mm]+dstr[dd]
    ENDFOR
  ENDFOR
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Print file
;;----------------------------------------------------------------------------------------
gfile          = mdir[0]+fname[0]

;;  Open file
OPENW,gunit,gfile[0],/GET_LUN
  FOR yy=0L, nyr - 1L DO BEGIN      ;;  Years
    FOR mm=0L, nmn - 1L DO BEGIN    ;;  Months
      FOR dd=0L, ndy - 1L DO BEGIN  ;;  Days
        ;;  Define start date indices
        yy0 = yy[0]
        mm0 = mm[0]
        dd0 = dd[0]
        IF (dd LE 29L) THEN BEGIN
          ;;  day ≤ 30
          yy1 = yy[0]
          mm1 = mm[0]
          dd1 = dd[0] + 1L
        ENDIF ELSE BEGIN
          ;;  day = 31
          IF (mm LE 10L) THEN BEGIN
            ;;  month ≤ 11
            yy1 = yy[0]
            mm1 = mm[0] + 1L
            dd1 = dd[0]
          ENDIF ELSE BEGIN
            ;;  month = December
            ;;    => rollover to January 1st
            yy1 = yy[0] + 1L
            mm1 = 0L
            dd1 = 0L
          ENDELSE
        ENDELSE
        ;;  Define substrings
        df_str_0        = dfstring[yy,mm,dd]
        d_str_0         = d_string[yy0,mm0,dd0]
        IF (yy1 EQ nyr) THEN BEGIN
          t_yr    = STRING(FORMAT='(I4.4)',years[yy]+1L)
          d_str_1 = t_yr[0]+'-'+mstr[mm1]+'-'+dstr[dd1]+tsuff[0]
        ENDIF ELSE BEGIN
          d_str_1 = d_string[yy1,mm1,dd1]
        ENDELSE
        out_pref        = d_str_0[0]+' '+d_str_1[0]+' '+d_dir[0]
        ;;  Define output string
        CASE d_ins[0] OF
          'mfi' : p_string = out_pref[0]+fpref[0]+df_str_0[0]+fsuff[0]
          ELSE  : p_string = out_pref[0]+ystr[yy]+slash[0]+fpref[0]+df_str_0[0]+fsuff[0]
        ENDCASE
        ;;  Print to file
        PRINTF,gunit,p_string[0]
;        PRINTF,gunit,p_string,FORMAT=mform
      ENDFOR
    ENDFOR
  ENDFOR
;;  Close file
FREE_LUN,gunit
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END












