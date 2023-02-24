;*****************************************************************************************
;
;  FUNCTION :   get_value_se_str.pro
;  PURPOSE  :   This routine parses an input search string in the following way:
;                  {ST_STRING} RESULT[0] {SP_STRING} RESULT[1] {EN_STRING}
;
;  CALLED BY:   
;               read_html_jck_database_new.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               SEARCH_STRING  :  Scalar [string] defining the string to parse
;               ST_STRING      :  Scalar [string] defining the start part of
;                                   SEARCH_STRING to find to demarcate the beginning
;                                   of the first element in the output result
;               EN_STRING      :  Scalar [string] defining the end part of
;                                   SEARCH_STRING to find to demarcate the ending of
;                                   the second element in the output result
;               SP_STRING      :  Scalar [string] defining a separator between the
;                                   first and second element in the output result
;
;  EXAMPLES:    
;               get_value_se_str,ss,st,en,sp
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  Finished writing the routine
;                                                                   [02/18/2015   v1.0.0]
;
;   NOTES:      
;               1)  If there is only one effect result between the start and end
;                     strings, then the value of SP_STRING does not matter
;
;  REFERENCES:  
;               NA
;
;   CREATED:  02/17/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/18/2015   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION get_value_se_str,search_string,st_string,en_string,sp_string

;;----------------------------------------------------------------------------------------
;;  Define dummy and constant variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
val            = ''
unc            = ''
ret            = [val[0],unc[0]]
;;  Define allowed number types
isnum          = [1,2,3,4,5,6,12,13,14,15]
;;  Dummy error messages
noinpt_msg     = 'User must supply a scalar search, start, end, and separator string...'
badfor_msg     = 'Inputs must all be scalar strings...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 4) THEN BEGIN
  MESSAGE,noinpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN,ret
ENDIF
test           = (SIZE(search_string,/TYPE) NE 7) OR (SIZE(st_string,/TYPE) NE 7) OR $
                 (SIZE(en_string,/TYPE) NE 7) OR (SIZE(sp_string,/TYPE) NE 7)
IF (test[0]) THEN BEGIN
  MESSAGE,badfor_msg,/INFORMATIONAL,/CONTINUE
  RETURN,ret
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define parameters
;;----------------------------------------------------------------------------------------
ss             = search_string[0]
st             = st_string[0]
en             = en_string[0]
sp             = sp_string[0]
;;  Define lengths
l_ss           = STRLEN(ss[0])
l_st           = STRLEN(st[0])
l_en           = STRLEN(en[0])
l_sp           = STRLEN(sp[0])
;;  Define positions within search string
posi_st        = STRPOS(ss[0],st[0])
posi_en        = STRPOS(ss[0],en[0])
posi_sp        = STRPOS(ss[0],sp[0])
;;  Define logic variables testing position checking
log_ss         = (ss[0] NE '')
log_st         = (posi_st[0] GE 0) AND (st[0] NE '')
log_en         = (posi_en[0] GE 0) AND (en[0] NE '')
log_sp         = (posi_sp[0] GE 0) AND (sp[0] NE '')
;;----------------------------------------------------------------------------------------
;;  Get parts of strings
;;----------------------------------------------------------------------------------------
;;  Need at least
;;    1)  the search string
;;    2)  start string
;;    3)  end string
test           = log_ss[0] AND log_st[0] AND log_en[0]
IF (test[0]) THEN BEGIN
  ;;  Define start and end positions in search string
  st_posi = posi_st[0] + l_st[0]
  en_posi = posi_en[0]; + l_en[0]
  IF (log_sp[0]) THEN BEGIN
    ;;  Separator string provide --> can get uncertainty
    sp_pos_st = posi_sp[0]                 ;;  start position before separator
    sp_pos_en = posi_sp[0] + l_sp[0]       ;;  start position after separator
    l_val     = sp_pos_st[0] - st_posi[0]  ;;  length of value string
    l_unc     = en_posi[0] - sp_pos_en[0]  ;;  length of uncertainty string
    vs        = STRMID(ss[0],st_posi[0],l_val[0])
    us        = STRMID(ss[0],sp_pos_en[0],l_unc[0])
    val       = vs[0]
    unc       = us[0]
  ENDIF ELSE BEGIN
    ;;  No valid separator string --> just provide value
    l_val     = en_posi[0] - st_posi[0]  ;;  length of value string
    vs        = STRMID(ss[0],st_posi[0],l_val[0])
    val       = vs[0]
  ENDELSE
ENDIF
;;  Define output
ret            = [val[0],unc[0]]
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ret
END


;+
;*****************************************************************************************
;
;  FUNCTION :   read_html_jck_database_new.pro
;  PURPOSE  :   Copy and paste the source code to the webpages of the data base created
;                 by Justin C. Kasper at http://www.cfa.harvard.edu/shocks/wi_data/ and
;                 keep them as ASCII files labeled as:
;                     source_MM-DD-YYYY_SSSSS.5_FF.html
;                     {where:  SSSSS = seconds of day, MM = month, DD = day, YYYY = year}
;                 The program iteratively reads in the ASCII files and retrieves the 
;                 relevant information from them.  The returned data is a structure
;                 containing all the relevant data quantities from the method used by
;                 J.C. Kasper and M.L. Stevens.
;
;  CALLED BY:   
;               write_shocks_jck_database_new.pro
;
;  INCLUDES:
;               get_value_se_str.pro
;
;  CALLS:
;               get_os_slash.pro
;               get_value_se_str.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;               2)  HTML files created by using
;                       create_html_from_cfa_winddb_urls.pro
;                     in the directory:
;                       ~/wind_3dp_pros/wind_data_dir/JCK_Data-Base/JCK_html_files/
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               test = read_html_jck_database_new()
;
;  KEYWORDS:    
;               DIRECT   :  Scalar [string] defining the directory location
;                             of the HTML ASCII files one is interested in
;                [Default = '~/wind_3dp_pros/wind_data_dir/JCK_Data-Base/JCK_html_files/']
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [02/16/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [02/17/2015   v1.0.0]
;             3)  Continued to write routine
;                                                                   [02/18/2015   v1.0.0]
;             4)  Continued to write routine
;                                                                   [02/18/2015   v1.0.0]
;             5)  Finished writing the routine and moved to
;                   ~/wind_3dp_pros/LYNN_PRO/JCKs_database_routines
;                                                                   [02/18/2015   v1.0.0]
;
;   NOTES:      
;               1)  Definitions
;                     SCF   :  Spacecraft frame of reference
;                     SHF   :  Shock rest frame of reference
;                     n     :  Shock normal unit vector [GSE basis]
;                     Vsh   :  Shock velocity in SCF [km/s]
;                     Vshn  :  Shock normal speed in SCF [km/s]
;                                [ = |Vsh . n| ]
;                     Ushn  :  Shock normal speed in SHF [km/s]
;                                [ = (Vsw . n) - (Vsh . n) ]
;                     Vs    :  Phase speed of MHD slow mode [km/s]
;                     Vi    :  Phase speed of MHD intermediate mode [km/s]
;                     Vf    :  Phase speed of MHD fast mode [km/s]
;                     Q_j   :  Avg. of quantity Q in region j, where
;                                j = 1 (upstream), 2 (downstream)
;                     
;               2)  Methods Used by J.C. Kasper:
;                     MC    :  Magnetic Coplanarity    (Viñas and Scudder, [1986])
;                     VC    :  Velocity Coplanarity    (Viñas and Scudder, [1986])
;                     MX1   :  Mixed Mode Normal 1     (Russell et. al., [1983])
;                     MX2   :  Mixed Mode Normal 2     (Russell et. al., [1983])
;                     MX3   :  Mixed Mode Normal 3     (Russell et. al., [1983])
;                     RH08  :  Rankine-Hugoniot 8 Eqs  (Viñas and Scudder, [1986])
;                     RH09  :  Rankine-Hugoniot 8 Eqs  (Viñas and Scudder, [1986])
;                     RH10  :  Rankine-Hugoniot 10 Eqs (Viñas and Scudder, [1986])
;               3)  Definition of Parameters on website
;                     Nj                  :  j-th component of n [GSE basis]
;                     Theta               :  Spherical poloidal angle of n [GSE basis]
;                     Phi                 :  Spherical azimuthal angle of n [GSE basis]
;                     Shock Speed         :  Vshn [km/s]
;                     Compression Ratio   :  N_2/N_1, where N_j = <N> in region j
;                     Shock Normal Angle  :  Angle between n and upstream <B> [degrees]
;                     dV                  :  Ushn [km/s]
;                     Slow                :  Vs [km/s]
;                     Intermediate        :  Vi [km/s]
;                     Fast                :  Vf [km/s]
;                     Slow Mach           :  Ms = |Ushn,j|/<Vs,j>
;                     Fast Mach           :  Mf = |Ushn,j|/<Vf,j>
;
;    Algorithm for finding relevant information
;  ==============================================
;      Let the following definitions hold:
;        SEARCH_STRING  :  string used by STRPOS as test
;        STNO_STRING    :  normal starting string = '<td>'
;        ENNO_STRING    :  normal ending   string = '</td>'
;        STSP_STRING    :  special starting string = '<td style="vertical-align: top;">'
;        ENSP_STRING    :  special ending   string = '<br>'
;
;      0)  find line of file with SEARCH_STRING for date
;          --> Define date by reading entire line after SEARCH_STRING and using STRSPLIT
;      1)  find line of file with SEARCH_STRING for section/table heading
;          a)  "General Information" table
;              i.  For all SEARCH_STRING's EXCEPT 'Method selected'
;                    --> start/end strings = STNO_STRING/ENNO_STRING
;                    --> 1st line          = value
;             ii.  For 'Method selected'
;                    --> start/end strings = STSP_STRING/ENSP_STRING
;                    --> 1st line          = blank
;                    --> 2nd line          = value
;            iii.  Only arrival time has associated uncertainties
;          b)  "Asymptotic plasma parameters" table
;              i.  For V[x,y,z], W[i,e], Ni, and B[x,y,z]
;                    --> start/end strings = STNO_STRING/ENNO_STRING
;                    --> 1st line          = upstream
;                    --> 2nd line          = downstream
;             ii.  For Plasma Beta, Sound Speed, and Alfven Speed
;                    --> start/end strings = STSP_STRING/ENSP_STRING
;                    --> 1st line          = blank
;                    --> 2nd line          = upstream
;                    --> 3rd line          = blank
;                    --> 4th line          = downstream
;            iii.  All have associated uncertainties
;          c)  "Best values of shock front normal for each method" table
;              i.  For all SEARCH_STRING's
;                    --> start/end strings = STNO_STRING/ENNO_STRING
;                    --> 1st line          = Nx value
;                    --> 2nd line          = Ny value
;                    --> 3rd line          = Nz value
;                    --> 4th line          = Theta value
;                    --> 5th line          = Phi value
;             ii.  Only Average, Median, and Deviation SEARCH_STRING's have no uncertainties
;          d)  "Key shock parameters" table
;              i.  For all SEARCH_STRING's
;                    --> start/end strings = STNO_STRING/ENNO_STRING
;                    --> 1st line          = ThetaBn value
;                    --> 2nd line          = Shock Speed value
;                    --> 3rd line          = Compression value
;             ii.  Only Average, Median, and Deviation SEARCH_STRING's have no uncertainties
;          e)  "Upstream wave speeds and mach numbers" table
;              i.  For all SEARCH_STRING's
;                    --> start/end strings = STNO_STRING/ENNO_STRING
;                    --> 1st line          = dV value
;                    --> 2nd line          = Slow value
;                    --> 3rd line          = Intermediate value
;                    --> 4th line          = Fast value
;                    --> 5th line          = Slow Mach value
;                    --> 6th line          = Fast Mach value
;             ii.  Only Average, Median, and Deviation SEARCH_STRING's have no uncertainties
;          f)  "Downstream wave speeds and mach numbers" table
;              i.  Same as upstream table
;             ii.  Only Average, Median, and Deviation SEARCH_STRING's have no uncertainties
;
;  REFERENCES:  
;               1)  Viñas, A.F. and J.D. Scudder (1986), "Fast and Optimal Solution to
;                      the 'Rankine-Hugoniot Problem'," J. Geophys. Res. 91, pp. 39-58.
;               2)  A. Szabo (1994), "An improved solution to the 'Rankine-Hugoniot'
;                      problem," J. Geophys. Res. 99, pp. 14,737-14,746.
;               3)  Koval, A. and A. Szabo (2008), "Modified 'Rankine-Hugoniot' shock
;                      fitting technique:  Simultaneous solution for shock normal and
;                      speed," J. Geophys. Res. 113, pp. A10110.
;               4)  Russell, C.T., J.T. Gosling, R.D. Zwickl, and E.J. Smith (1983),
;                      "Multiple spacecraft observations of interplanetary shocks:  ISEE
;                      Three-Dimensional Plasma Measurements," J. Geophys. Res. 88,
;                      pp. 9941-9947.
;
;   CREATED:  02/16/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/18/2015   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION read_html_jck_database_new,DIRECT=direct

;;----------------------------------------------------------------------------------------
;;  Define dummy and constant variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
dumb_sep       = 'aaaaaaaaaaaaaaaaaaa'
s256           = STRARR(256)
slash          = get_os_slash()         ;;  '/' for Unix, '\' for Windows
;;  Define allowed number types
isnum          = [1,2,3,4,5,6,12,13,14,15]
vec_str        = ['x','y','z']
;;  Dummy error messages
nooutput_msg   = 'No URLs were found to be valid --> No output files created!'
;;----------------------------------------------------------------------------------------
;;  Define default search paths and file names
;;----------------------------------------------------------------------------------------
;;  Define location of locally saved HTML files
def_path       = '.'+slash[0]+'wind_3dp_pros'+slash[0]+'wind_data_dir'+slash[0]
def_path       = def_path[0]+'JCK_Data-Base'+slash[0]+'JCK_html_files'+slash[0]
def_files      = 'source_*.html'
;;----------------------------------------------------------------------------------------
;;  Setup file paths to HTML files
;;----------------------------------------------------------------------------------------
DEFSYSV,'!wind3dp_umn',EXISTS=exists
test           = ~KEYWORD_SET(exists) AND (SIZE(direct,/TYPE) NE 7)
IF (test[0]) THEN BEGIN
  mdir  = FILE_EXPAND_PATH(def_path[0])
ENDIF ELSE BEGIN
  test  = (SIZE(direct,/TYPE) NE 7)
  IF (test[0]) THEN BEGIN
    ;;  !wind3dp_umn system variable has been created
    mdir  = !wind3dp_umn.ASCII_FILE_DIR
    IF (mdir[0] EQ '') THEN BEGIN
      mdir = FILE_EXPAND_PATH(def_path[0])
    ENDIF ELSE BEGIN
      mdir = mdir[0]+'JCK_html_files'+slash[0]
    ENDELSE
  ENDIF ELSE BEGIN
    ;;  DIRECT keyword was set
    ;;    --> check it
    test = FILE_TEST(direct[0],/DIRECTORY)
    IF (test[0]) THEN BEGIN
      ;;  DIRECT is a directory
      mdir  = EXPAND_PATH(direct[0])
    ENDIF ELSE BEGIN
      ;;  DIRECT is NOT a directory
      ;;    --> use default
      mdir  = FILE_EXPAND_PATH(def_path[0])
    ENDELSE
  ENDELSE
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define search strings preceeding relevant information
;;----------------------------------------------------------------------------------------
;;  Define shock analysis method strings [for General, Asymptotic, and Best Values tables]
all_meth0_strs = ['MC','VC','MX1','MX2','MX3','RH08','RH09','RH10']
;;  Define shock analysis method strings [for Upstream and Downstream tables]
all_meth1_strs = ['MC','VC','MX1','MX2','MX3','RH8','RH9','RH10']
nm             = N_ELEMENTS(all_meth1_strs)                 ;;  # of different methods used
;;  Define start/end and separator strings
td_str_before  = '<td>'                                     ;;  HTML code to start table element
td_str__after  = '</td>'                                    ;;  HTML code to end   table element
td_str_balens  = STRLEN([td_str_before[0],td_str__after[0]])
uncer_test_s   = '&plusmn;'                                 ;;  Test string for uncertainties { = HTML code for ± ASCII char }

td_str_stspcl  = '<td style="vertical-align: top;">'        ;;  Special start string for some table elements
td_str_enspcl  = '<br>'                                     ;;  Corresponding ending string
;;  Define statistics strings [After all tables except General]
all_stats_strs = ['Average','Median','Deviation']
all_stat_se_s  = td_str_before[0]+all_stats_strs+td_str__after[0]
;;  Define section/table heading strings
geni_tab_t_s   = '<a name="Information"></a>'               ;;  Leading string for the "General Information" table
asym_tab_t_s   = '<a name="Asymptotic">'                    ;;  Leading string for the "Asymptotic plasma parameters" table
norm_tab_t_s   = '<a name="Normals">'                       ;;  Leading string for the "Best values of shock front normal for each method" table
keyp_tab_t_s   = '<a name="Parameters">'                    ;;  Leading string for the "Key shock parameters" table
upsw_tab_t_s   = '<a name="Waves"></a><big>Upstream'        ;;  Leading string for the "Upstream wave speeds and mach numbers" table
dnsw_tab_t_s   = '<a name="Waves"></a><big>Downstream'      ;;  Leading string for the "Downstream wave speeds and mach numbers" table
;;  Define search strings for Date of Event
odate_test_s   = 'Observation time:'                        ;;  Find observation date [16 chars search string, 1 line]
;;  Define search strings for "General Information" table
fdoy__test_s   = 'Fractional day of year'                   ;;  Find Frac. DOY [22 chars search string, +1 line, 1 #]
atime_test_s   = 'Arrival time of shock [seconds of day]'   ;;  Find shock arrival time SOD [38 chars search string, +1 line, 2 #'s, &plusmn; separator]
shtyp_test_s   = 'Shock type'                               ;;  Find shock designation [10 chars search string, +1 line, 1 string, 2 char long]
eleda_test_s   = 'Electron data availability'               ;;  Find logic test for electron data [26 chars search string, +1 line, 1 #]
scxgsetest_s   = 'X GSE location of spacecraft [Re]'        ;;  Find X-GSE SC position [Re] [33 chars search string, +1 line, 1 #]
scygsetest_s   = 'Y GSE location of spacecraft [Re]'        ;;  Find Y-GSE SC position [Re] [33 chars search string, +1 line, 1 #]
sczgsetest_s   = 'Z GSE location of spacecraft [Re]'        ;;  Find Z-GSE SC position [Re] [33 chars search string, +1 line, 1 #]
nuppt_test_s   = 'Upstream plasma points'                   ;;  Find # of upstream plasma points used [22 chars search string, +1 line, 1 #]
nufpt_test_s   = 'Upstream field points'                    ;;  Find # of upstream field points used [21 chars search string, +1 line, 1 #]
ndppt_test_s   = 'Downstream plasma points'                 ;;  Find # of downstream plasma points used [22 chars search string, +1 line, 1 #]
ndfpt_test_s   = 'Downstream field points'                  ;;  Find # of downstream field points used [21 chars search string, +1 line, 1 #]
meths_test_s   = 'Method selected'                          ;;  Find method used [e.g., RHO8]
all_gen_strs   = [fdoy__test_s[0],atime_test_s[0],shtyp_test_s[0],eleda_test_s[0],$
                  scxgsetest_s[0],scygsetest_s[0],sczgsetest_s[0],nuppt_test_s[0],$
                  nufpt_test_s[0],ndppt_test_s[0],ndfpt_test_s[0],meths_test_s[0] ]
last_gen_tab   = 0b                                         ;;  Logic to indicate that last value of table has been found --> move on
;;  Define search strings for "Asymptotic plasma parameters" table
v_xyz_test_s   = 'V'+vec_str+' GSE [km/s]'                  ;;  Search string for V[x,y,z], bulk flow velocity vectors
vthie_test_s   = 'W'+['i','e']+' [km/s]'                    ;;  Search string for W[i,e], Avg. thermal speeds
idens_test_s   = 'Ni [n/cc]'                                ;;  Search string for Ni, Avg. ion number density
b_xyz_test_s   = 'B'+vec_str+' GSE [nT]'                    ;;  Search string for B[x,y,z], Avg. magnetic field vectors
pbeta_test_s   = 'Plasma Beta'                              ;;  Search string for ß, Avg. total plasma beta
IACs__test_s   = 'Sound Speed [km/s]'                       ;;  Search string for Cs, Avg. ion-acoustic sound speed
Valfv_test_s   = 'Alfven Speed [km/s]'                      ;;  Search string for V_A, Avg. Alfven speed
all_asy_strs   = [v_xyz_test_s,vthie_test_s,idens_test_s[0],b_xyz_test_s,$
                  pbeta_test_s[0],IACs__test_s[0],Valfv_test_s[0]]
last_asy_tab   = 0b                                         ;;  Logic to indicate that last value of table has been found --> move on
;;  Define search strings for "Best values of shock front normal for each method" table
a_bvs_test_s   = td_str_before[0]+all_meth0_strs+td_str__after[0]
all_bvs_strs   = [a_bvs_test_s,all_stat_se_s]
last_bvn_tab   = 0b                                         ;;  Logic to indicate that last value of table has been found --> move on
;;  Define search strings for "Key shock parameters" table
a_key_test_s   = td_str_before[0]+all_meth0_strs+td_str__after[0]
all_key_strs   = [a_key_test_s,all_stat_se_s]
last_key_tab   = 0b                                         ;;  Logic to indicate that last value of table has been found --> move on
;;  Define search strings for "Upstream wave speeds and mach numbers" table
a_ups_test_s   = td_str_before[0]+all_meth1_strs+td_str__after[0]
all_ups_strs   = [a_ups_test_s,all_stat_se_s]
last_ups_tab   = 0b                                         ;;  Logic to indicate that last value of table has been found --> move on
;;  Define search strings for "Downstream wave speeds and mach numbers" table
a_dns_test_s   = td_str_before[0]+all_meth1_strs+td_str__after[0]
all_dns_strs   = [a_dns_test_s,all_stat_se_s]
last_dns_tab   = 0b                                         ;;  Logic to indicate that last value of table has been found --> move on
;;----------------------------------------------------------------------------------------
;;  Check for files
;;----------------------------------------------------------------------------------------
files          = FILE_SEARCH(mdir[0],def_files[0])
good           = WHERE(files NE '',gd)
IF (gd[0] LT 2) THEN BEGIN
  MESSAGE,'0: '+nooutput_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
gfiles         = files[good]
nf             = N_ELEMENTS(gfiles)
IF (nf[0] LT 2) THEN BEGIN
  MESSAGE,'0: '+nooutput_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define variables to be filled from tables in each HTML files
;;----------------------------------------------------------------------------------------
a__odate       = REPLICATE('',nf)          ;;  Dates of events ['MM/DD/YYYY']
;;  Define variables for "General Information" table
a__frdoy       = REPLICATE(f,nf)           ;;  Fractional day of year of shock arrival time
a__arrvt       = REPLICATE(f,nf)           ;;  Time of shock arrival (seconds of day)
a_darrvt       = REPLICATE(f,nf)           ;;  Uncertainty of Time of shock arrival (seconds of day)
a__stype       = REPLICATE('',nf)          ;;  Type of shock (e.g., FF = fast forward, FR = fast reverse, etc.)
a__edatl       = REPLICATE(0b,nf)          ;;  Logic test for availability of electron data
a__scgse       = REPLICATE(f,nf,3)         ;;  Wind GSE Positions (Re) at time of shock arrival
a__nuppt       = REPLICATE(0L,nf)          ;;  # of upstream plasma points used
a__nupft       = REPLICATE(0L,nf)          ;;  # of upstream field points used
a__ndnpt       = REPLICATE(0L,nf)          ;;  # of downstream plasma points used
a__ndnft       = REPLICATE(0L,nf)          ;;  # of downstream field points used
a__mthus       = REPLICATE('',nf)          ;;  Type of analysis method used (e.g., RH08)
;;  Define variables for "Asymptotic plasma parameters" table
;;    Notes:
;;          1)  Not sure how Wi or We are calculated, but as far as numbers go...
;;                --> Cs^2 ~ (5/3)*Wi^2
;;          2)  We is effectively meaningless if logic test = FALSE
;;          3)  Plasma Beta is the total plasma beta
;;                --> ß = Cs^2/V_A^2*(3/5)
a__vigse       = REPLICATE(f,nf,3,2)       ;;  Avg. bulk flow velocity [Event,GSE,{up,down}] [km/s]
a___vthi       = REPLICATE(f,nf,2)         ;;  Avg. ion thermal speed [Event,{up,down}] [km/s]
a___vthe       = REPLICATE(f,nf,2)         ;;  Avg. electron thermal speed [Event,{up,down}] [km/s]
a___iden       = REPLICATE(f,nf,2)         ;;  Avg. ion number [Event,{up,down}] [cm^(-3)]
a___bgse       = REPLICATE(f,nf,3,2)       ;;  Avg. magnetic field [Event,GSE,{up,down}] [nT]
a___beta       = REPLICATE(f,nf,2)         ;;  Avg. total plasma beta [Event,{up,down}] [unitless]
a_____Cs       = REPLICATE(f,nf,2)         ;;  Avg. ion-acoustic sound speed [Event,{up,down}] [km/s]
a_____VA       = REPLICATE(f,nf,2)         ;;  Avg. Alfvén speed [Event,{up,down}] [km/s]
a_dvigse       = REPLICATE(f,nf,3,2)       ;;  Uncertainty of Avg. bulk flow velocity [Event,GSE,{up,down}] [km/s]
a__dvthi       = REPLICATE(f,nf,2)         ;;  Uncertainty of Avg. ion thermal speed [Event,{up,down}] [km/s]
a__dvthe       = REPLICATE(f,nf,2)         ;;  Uncertainty of Avg. electron thermal speed [Event,{up,down}] [km/s]
a__diden       = REPLICATE(f,nf,2)         ;;  Uncertainty of Avg. ion number [Event,{up,down}] [cm^(-3)]
a__dbgse       = REPLICATE(f,nf,3,2)       ;;  Uncertainty of Avg. magnetic field [Event,GSE,{up,down}] [nT]
a__dbeta       = REPLICATE(f,nf,2)         ;;  Uncertainty of Avg. total plasma beta [Event,{up,down}] [unitless]
a____dCs       = REPLICATE(f,nf,2)         ;;  Uncertainty of Avg. ion-acoustic sound speed [Event,{up,down}] [km/s]
a____dVA       = REPLICATE(f,nf,2)         ;;  Uncertainty of Avg. Alfvén speed [Event,{up,down}] [km/s]
;;  Define variables for "Best values of shock front normal for each method" table
a____nsh       = REPLICATE(f,nf,3,nm)      ;;  Shock normal unit vector [Event,GSE,Method]
a___nthe       = REPLICATE(f,nf,nm)        ;;  Spherical poloidal angle of n [Event,Method] [degrees]
a___nphi       = REPLICATE(f,nf,nm)        ;;  Spherical azimuthal angle of n [Event,Method] [degrees]
a___dnsh       = REPLICATE(f,nf,3,nm)      ;;  Uncertainty of Shock normal unit vector [Event,GSE,Method]
a__dnthe       = REPLICATE(f,nf,nm)        ;;  Uncertainty of Spherical poloidal angle of n [Event,Method] [degrees]
a__dnphi       = REPLICATE(f,nf,nm)        ;;  Uncertainty of Spherical azimuthal angle of n [Event,Method] [degrees]
;;  Define variables for "Key shock parameters" table
a__thebn       = REPLICATE(f,nf,nm)        ;;  Avg. upstream shock normal angle [Event,Method] [degrees]
a___vshn       = REPLICATE(f,nf,nm)        ;;  Avg. upstream shock normal speed [Event,Method] [km/s, SCF]
a___n2n1       = REPLICATE(f,nf,nm)        ;;  Avg. shock density compression ratio [Event,Method]
a_dthebn       = REPLICATE(f,nf,nm)        ;;  Uncertainty of Avg. upstream shock normal angle [Event,Method] [degrees]
a__dvshn       = REPLICATE(f,nf,nm)        ;;  Uncertainty of Avg. upstream shock normal speed [Event,Method] [km/s, SCF]
a__dn2n1       = REPLICATE(f,nf,nm)        ;;  Uncertainty of Avg. shock density compression ratio [Event,Method]
;;  Define variables for "Upstream wave speeds and mach numbers" table (and Downstream too)
a___ushn       = REPLICATE(f,nf,nm,2)      ;;  Avg. shock normal speed [Event,Method,{up,down}] [km/s, SHF]
a_____Vs       = REPLICATE(f,nf,nm,2)      ;;  Avg. MHD slow mode speed [Event,Method,{up,down}] [km/s]
a_____Vi       = REPLICATE(f,nf,nm,2)      ;;  Avg. MHD intermediate mode speed [Event,Method,{up,down}] [km/s]
a_____Vf       = REPLICATE(f,nf,nm,2)      ;;  Avg. MHD fast mode speed [Event,Method,{up,down}] [km/s]
a_____Ms       = REPLICATE(f,nf,nm,2)      ;;  Avg. MHD slow mode Mach number [Event,Method,{up,down}]
a_____Mf       = REPLICATE(f,nf,nm,2)      ;;  Avg. MHD fast mode Mach number [Event,Method,{up,down}]
a__dushn       = REPLICATE(f,nf,nm,2)      ;;  Uncertainty of Avg. shock normal speed [Event,Method,{up,down}] [km/s, SHF]
a____dVs       = REPLICATE(f,nf,nm,2)      ;;  Uncertainty of Avg. MHD slow mode speed [Event,Method,{up,down}] [km/s]
a____dVi       = REPLICATE(f,nf,nm,2)      ;;  Uncertainty of Avg. MHD intermediate mode speed [Event,Method,{up,down}] [km/s]
a____dVf       = REPLICATE(f,nf,nm,2)      ;;  Uncertainty of Avg. MHD fast mode speed [Event,Method,{up,down}] [km/s]
a____dMs       = REPLICATE(f,nf,nm,2)      ;;  Uncertainty of Avg. MHD slow mode Mach number [Event,Method,{up,down}]
a____dMf       = REPLICATE(f,nf,nm,2)      ;;  Uncertainty of Avg. MHD fast mode Mach number [Event,Method,{up,down}]
;;----------------------------------------------------------------------------------------
;;  Define statistics of variables from tables in each HTML files
;;----------------------------------------------------------------------------------------
;;  Define variables for "Best values of shock front normal for each method" table
avg__nsh       = REPLICATE(f,nf,3)         ;;  Mean of methods of Shock normal unit vector [Event,GSE]
avg_nthe       = REPLICATE(f,nf)           ;;  Mean of methods of Spherical poloidal angle of n [Event] [degrees]
avg_nphi       = REPLICATE(f,nf)           ;;  Mean of methods of Spherical azimuthal angle of n [Event] [degrees]
med__nsh       = REPLICATE(f,nf,3)         ;;  Median of methods of Shock normal unit vector [Event,GSE]
med_nthe       = REPLICATE(f,nf)           ;;  Median of methods of Spherical poloidal angle of n [Event] [degrees]
med_nphi       = REPLICATE(f,nf)           ;;  Median of methods of Spherical azimuthal angle of n [Event] [degrees]
std__nsh       = REPLICATE(f,nf,3)         ;;  Std. Dev. of methods of Shock normal unit vector [Event,GSE]
std_nthe       = REPLICATE(f,nf)           ;;  Std. Dev. of methods of Spherical poloidal angle of n [Event] [degrees]
std_nphi       = REPLICATE(f,nf)           ;;  Std. Dev. of methods of Spherical azimuthal angle of n [Event] [degrees]
;;  Define variables for "Key shock parameters" table
avgthebn       = REPLICATE(f,nf)           ;;  Mean of methods of Avg. upstream shock normal angle [Event] [degrees]
avg_vshn       = REPLICATE(f,nf)           ;;  Mean of methods of Avg. upstream shock normal speed [Event] [km/s, SCF]
avg_n2n1       = REPLICATE(f,nf)           ;;  Mean of methods of Avg. shock density compression ratio [Event]
medthebn       = REPLICATE(f,nf)           ;;  Median of methods of Avg. upstream shock normal angle [Event] [degrees]
med_vshn       = REPLICATE(f,nf)           ;;  Median of methods of Avg. upstream shock normal speed [Event] [km/s, SCF]
med_n2n1       = REPLICATE(f,nf)           ;;  Median of methods of Avg. shock density compression ratio [Event]
stdthebn       = REPLICATE(f,nf)           ;;  Std. Dev. of methods of Avg. upstream shock normal angle [Event] [degrees]
std_vshn       = REPLICATE(f,nf)           ;;  Std. Dev. of methods of Avg. upstream shock normal speed [Event] [km/s, SCF]
std_n2n1       = REPLICATE(f,nf)           ;;  Std. Dev. of methods of Avg. shock density compression ratio [Event]
;;  Define variables for "Upstream wave speeds and mach numbers" table (and Downstream too)
avg_ushn       = REPLICATE(f,nf,2)         ;;  Mean of methods of Avg. shock normal speed [Event,{up,down}] [km/s, SHF]
avg___Vs       = REPLICATE(f,nf,2)         ;;  Mean of methods of Avg. MHD slow mode speed [Event,{up,down}] [km/s]
avg___Vi       = REPLICATE(f,nf,2)         ;;  Mean of methods of Avg. MHD intermediate mode speed [Event,{up,down}] [km/s]
avg___Vf       = REPLICATE(f,nf,2)         ;;  Mean of methods of Avg. MHD fast mode speed [Event,{up,down}] [km/s]
avg___Ms       = REPLICATE(f,nf,2)         ;;  Mean of methods of Avg. MHD slow mode Mach number [Event,{up,down}]
avg___Mf       = REPLICATE(f,nf,2)         ;;  Mean of methods of Avg. MHD fast mode Mach number [Event,{up,down}]
med_ushn       = REPLICATE(f,nf,2)         ;;  Median of methods of Avg. shock normal speed [Event,{up,down}] [km/s, SHF]
med___Vs       = REPLICATE(f,nf,2)         ;;  Median of methods of Avg. MHD slow mode speed [Event,{up,down}] [km/s]
med___Vi       = REPLICATE(f,nf,2)         ;;  Median of methods of Avg. MHD intermediate mode speed [Event,{up,down}] [km/s]
med___Vf       = REPLICATE(f,nf,2)         ;;  Median of methods of Avg. MHD fast mode speed [Event,{up,down}] [km/s]
med___Ms       = REPLICATE(f,nf,2)         ;;  Median of methods of Avg. MHD slow mode Mach number [Event,{up,down}]
med___Mf       = REPLICATE(f,nf,2)         ;;  Median of methods of Avg. MHD fast mode Mach number [Event,{up,down}]
std_ushn       = REPLICATE(f,nf,2)         ;;  Std. Dev. of methods of Avg. shock normal speed [Event,{up,down}] [km/s, SHF]
std___Vs       = REPLICATE(f,nf,2)         ;;  Std. Dev. of methods of Avg. MHD slow mode speed [Event,{up,down}] [km/s]
std___Vi       = REPLICATE(f,nf,2)         ;;  Std. Dev. of methods of Avg. MHD intermediate mode speed [Event,{up,down}] [km/s]
std___Vf       = REPLICATE(f,nf,2)         ;;  Std. Dev. of methods of Avg. MHD fast mode speed [Event,{up,down}] [km/s]
std___Ms       = REPLICATE(f,nf,2)         ;;  Std. Dev. of methods of Avg. MHD slow mode Mach number [Event,{up,down}]
std___Mf       = REPLICATE(f,nf,2)         ;;  Std. Dev. of methods of Avg. MHD fast mode Mach number [Event,{up,down}]
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Read in data
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
FOR f_j=0L, nf[0] - 1L DO BEGIN
  t_file  = gfiles[f_j]
  nfls    = FILE_LINES(t_file[0])
  ;;--------------------------------------------------------------------------------------
  ;;  Open file and logical unit number
  ;;--------------------------------------------------------------------------------------
  OPENR,gunit,t_file[0],/GET_LUN
  ;;--------------------------------------------------------------------------------------
  ;;  Reset/Initialize logic variables
  ;;--------------------------------------------------------------------------------------
  last_gen_tab   = 0b
  last_asy_tab   = 0b
  last_bvn_tab   = 0b
  last_key_tab   = 0b
  last_ups_tab   = 0b
  last_dns_tab   = 0b
  ;;  Test variables
  test_odate_s   = 0b
  test_geni__s   = 0b
  test_asym__s   = 0b
  test_norm__s   = 0b
  test_keyp__s   = 0b
  test_upsw__s   = 0b
  test_dnsw__s   = 0b
  ;;  Initialize variables
  sline          = ''               ;;  dummy string used for reading each line of file
  l_j            = 0L
  test_while     = 1b
  sp_string      = uncer_test_s[0]  ;;  '&plusmn;'
  WHILE (test_while) DO BEGIN
    ;;  Check if we need to continue
    IF (last_dns_tab) THEN BREAK  ;;  Nope --> exit loop
    ;;  Yep --> keep reading
    READF,gunit,sline
    ;;------------------------------------------------------------------------------------
    ;;  Test to find current location
    ;;------------------------------------------------------------------------------------
    test_odate_s   = STRPOS(sline[0],odate_test_s[0]) GE 0
    test_geni__s   = STRPOS(sline[0],geni_tab_t_s[0]) GE 0
    test_asym__s   = STRPOS(sline[0],asym_tab_t_s[0]) GE 0
    test_norm__s   = STRPOS(sline[0],norm_tab_t_s[0]) GE 0
    test_keyp__s   = STRPOS(sline[0],keyp_tab_t_s[0]) GE 0
    test_upsw__s   = STRPOS(sline[0],upsw_tab_t_s[0]) GE 0
    test_dnsw__s   = STRPOS(sline[0],dnsw_tab_t_s[0]) GE 0
    test_table     = 0b
    CASE 1 OF
      test_odate_s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get event date
        ;;--------------------------------------------------------------------------------
        slen  = STRLEN(odate_test_s[0])
        t_str = STRTRIM(STRMID(sline[0],slen[0]),2L)
        t_str = STRSPLIT(t_str,' ',/EXTRACT,/REGEX,/FOLD_CASE)
        a__odate[f_j] = t_str[0]      ;;  e.g., '01/21/2012'
      END
      test_geni__s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get data from "General Information" table
        ;;--------------------------------------------------------------------------------
        s_s0         = all_gen_strs
        n_s0         = N_ELEMENTS(s_s0)
        FOR s_j=0L, n_s0[0] - 1L DO BEGIN
          ;;  Read until we hit one of the search strings
          s_slast    = ''
          s_slast    = s_s0[s_j]
          REPEAT BEGIN
            ;;  Need to increment line counter
            l_j += 1L
            READF,gunit,sline
            test_table = STRPOS(sline[0],s_slast[0]) GE 0
          ENDREP UNTIL (test_table)
          ;;  Found search string
          ;;    --> Define start/end strings
          st_string = td_str_before[0]
          en_string = td_str__after[0]
          ;;  Only arrival time has uncertainty for this table
          ;;    --> change separator string accordingly
          IF (s_slast[0] EQ atime_test_s[0]) THEN sp_ss = sp_string[0] ELSE sp_ss = ''
          ;;  read next line --> get data result
          l_j += 1L
          READF,gunit,sline
          IF (s_j EQ n_s0[0] - 1L) THEN BEGIN
            ;;  Need to read an extra line for the Method
            l_j += 1L
            READF,gunit,sline
            ;;  Need to redefine start/end strings
            st_string = td_str_stspcl[0]
            en_string = td_str_enspcl[0]
          ENDIF
          IF (s_j EQ 9L) THEN en_string = td_str_enspcl[0]   ;;  Unusual ending string for this one parameter
          ;;  Separate the useful information from the rest of the string
          valunc = get_value_se_str(sline[0],st_string[0],en_string[0],sp_ss[0])
          CASE s_j[0] OF
            0L  : a__frdoy[f_j]   = valunc[0]              ;;  Fractional day of year of shock arrival time
            1L  : BEGIN                                    ;;  Arrival time [sec. of day]
              a__arrvt[f_j] = FLOAT(valunc[0])
              a_darrvt[f_j] = FLOAT(valunc[1])
            END
            2L  : a__stype[f_j]   = valunc[0]              ;;  Type of shock [e.g., 'FF']
            3L  : a__edatl[f_j]   = BYTE(LONG(valunc[0]))  ;;  1 = Electron data available, else = not
            4L  : a__scgse[f_j,0] = FLOAT(valunc[0])       ;;  X-GSE SC Position [Re]
            5L  : a__scgse[f_j,1] = FLOAT(valunc[0])       ;;  Y-GSE SC Position [Re]
            6L  : a__scgse[f_j,2] = FLOAT(valunc[0])       ;;  Z-GSE SC Position [Re]
            7L  : a__nuppt[f_j]   = LONG(valunc[0])        ;;  # of upstream plasma points used
            8L  : a__nupft[f_j]   = LONG(valunc[0])        ;;  # of upstream field points used
            9L  : a__ndnpt[f_j]   = LONG(valunc[0])        ;;  # of downstream plasma points used
            10L : a__ndnft[f_j]   = LONG(valunc[0])        ;;  # of downstream field points used
            11L : a__mthus[f_j]   = valunc[0]              ;;  Method used [e.g., 'RH08']
          ENDCASE
        ENDFOR
        ;;  End and set logic for later
        last_gen_tab = 1b
      END
      test_asym__s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get data from "Asymptotic plasma parameters" table
        ;;--------------------------------------------------------------------------------
        s_s0         = all_asy_strs
        n_s0         = N_ELEMENTS(s_s0)
        FOR s_j=0L, n_s0[0] - 1L DO BEGIN
          ;;  Read until we hit one of the search strings
          s_slast = ''
          REPEAT BEGIN
            ;;  Need to increment line counter
            l_j += 1L
            READF,gunit,sline
            s_slast    = s_s0[s_j]
            test_table = STRPOS(sline[0],s_slast[0]) GE 0
          ENDREP UNTIL (test_table)
          ;;  Found search string
          ;;    --> Define start/end strings
          st_string = td_str_before[0]
          en_string = td_str__after[0]
          sp_ss     = sp_string[0]         ;;  All have uncertainties
          ;;------------------------------------------------------------------------------
          ;;  Check for search strings that have special formatting
          ;;------------------------------------------------------------------------------
          test_2       = (s_slast[0] EQ pbeta_test_s[0]) OR $
                         (s_slast[0] EQ IACs__test_s[0]) OR $
                         (s_slast[0] EQ Valfv_test_s[0])
          FOR updn=0L, 1L DO BEGIN
            ;;  read next line --> get upstream/downstream data result
            l_j += 1L
            READF,gunit,sline
            IF (test_2[0]) THEN BEGIN
              ;;  Need to read an extra line for these strings
              l_j += 1L
              READF,gunit,sline
              ;;  Need to redefine start/end strings
              st_string = td_str_stspcl[0]
              en_string = td_str_enspcl[0]
            ENDIF
            ;;----------------------------------------------------------------------------
            ;;  Separate the useful information from the rest of the string
            ;;----------------------------------------------------------------------------
            valunc  = get_value_se_str(sline[0],st_string[0],en_string[0],sp_ss[0])
            test_sj = (s_j[0] LE 2L)
            IF (test_sj[0]) THEN BEGIN
              ;;  Avg. bulk flow velocity [km/s]
              soff                 = s_j[0] - 0L
              a__vigse[f_j,soff[0],updn[0]] = FLOAT(valunc[0])
              a_dvigse[f_j,soff[0],updn[0]] = FLOAT(valunc[1])
            ENDIF
            test_sj = (s_j[0] LE 8L) AND (s_j[0] GE 6L)
            IF (test_sj[0]) THEN BEGIN
              ;;  Avg. magnetic field [nT]
              soff                 = s_j[0] - 6L
              a___bgse[f_j,soff[0],updn[0]] = FLOAT(valunc[0])
              a__dbgse[f_j,soff[0],updn[0]] = FLOAT(valunc[1])
            ENDIF
            ;;----------------------------------------------------------------------------
            ;;  ELSE --> check each
            ;;----------------------------------------------------------------------------
            CASE s_j[0] OF
              3L  : BEGIN                              ;;  Avg. ion thermal speed [km/s]
                a___vthi[f_j,updn[0]] = FLOAT(valunc[0])
                a__dvthi[f_j,updn[0]] = FLOAT(valunc[1])
              END
              4L  : BEGIN                              ;;  Avg. electron thermal speed [km/s]
                a___vthe[f_j,updn[0]] = FLOAT(valunc[0])
                a__dvthe[f_j,updn[0]] = FLOAT(valunc[1])
              END
              5L  : BEGIN                              ;;  Avg. ion number [cm^(-3)]
                a___iden[f_j,updn[0]] = FLOAT(valunc[0])
                a__diden[f_j,updn[0]] = FLOAT(valunc[1])
              END
              9L  : BEGIN                              ;;  Avg. total plasma beta [unitless]
                a___beta[f_j,updn[0]] = FLOAT(valunc[0])
                a__dbeta[f_j,updn[0]] = FLOAT(valunc[1])
              END
              10L : BEGIN                              ;;  Avg. ion-acoustic sound speed [km/s]
                a_____Cs[f_j,updn[0]] = FLOAT(valunc[0])
                a____dCs[f_j,updn[0]] = FLOAT(valunc[1])
              END
              11L : BEGIN                              ;;  Avg. Alfvén speed [km/s]
                a_____VA[f_j,updn[0]] = FLOAT(valunc[0])
                a____dVA[f_j,updn[0]] = FLOAT(valunc[1])
              END
              ELSE :                                   ;;  Do nothing
            ENDCASE
          ENDFOR
        ENDFOR
        ;;  End and set logic for later
        last_asy_tab = 1b
      END
      test_norm__s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get data from "Best values of shock front normal for each method" table
        ;;--------------------------------------------------------------------------------
        s_s0         = all_bvs_strs
        n_s0         = N_ELEMENTS(s_s0)
        FOR s_j=0L, n_s0[0] - 1L DO BEGIN
          ;;  Read until we hit one of the search strings
          s_slast = ''
          s_slast = s_s0[s_j]
          REPEAT BEGIN
            ;;  Need to increment line counter
            l_j += 1L
            READF,gunit,sline
            test_table = STRPOS(sline[0],s_slast[0]) GE 0
          ENDREP UNTIL (test_table)
          ;;  Found search string
          ;;    --> Define start/end strings
          st_string = td_str_before[0]
          en_string = td_str__after[0]
          ;;------------------------------------------------------------------------------
          ;;  Check for search strings that have special formatting
          ;;------------------------------------------------------------------------------
          test_2       = (s_slast[0] EQ all_stat_se_s[0]) OR $
                         (s_slast[0] EQ all_stat_se_s[1]) OR $
                         (s_slast[0] EQ all_stat_se_s[2])
          IF (test_2[0]) THEN sp_ss = '' ELSE sp_ss = sp_string[0]
          ;;  Loop over parameters for each method
          FOR ipar=0L, 4L DO BEGIN
            ;;----------------------------------------------------------------------------
            ;;  each line = new parameter [ipar] for each method [s_j]
            ;;----------------------------------------------------------------------------
            l_j += 1L
            READF,gunit,sline
            ;;----------------------------------------------------------------------------
            ;;  Separate the useful information from the rest of the string
            ;;----------------------------------------------------------------------------
            valunc  = get_value_se_str(sline[0],st_string[0],en_string[0],sp_ss[0])
            test_sj = (s_j[0] LT 8L)
            IF (test_sj[0]) THEN BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Parameters, not statistics yet
              ;;--------------------------------------------------------------------------
              test_ud  = (ipar[0] LE 2L)
              meth_off = s_j[0]             ;;  Method index
              IF (test_ud[0]) THEN BEGIN
                ;;  Shock normal unit vector [GSE basis]
                a____nsh[f_j,ipar[0],meth_off[0]] = FLOAT(valunc[0])
                a___dnsh[f_j,ipar[0],meth_off[0]] = FLOAT(valunc[1])
              ENDIF
              ;;  ELSE --> check each
              CASE ipar[0] OF
                3L  : BEGIN                              ;;  Spherical poloidal angle of n [degrees]
                  a___nthe[f_j,meth_off[0]] = FLOAT(valunc[0])
                  a__dnthe[f_j,meth_off[0]] = FLOAT(valunc[1])
                END
                4L  : BEGIN                              ;;  azimuthal poloidal angle of n [degrees]
                  a___nphi[f_j,meth_off[0]] = FLOAT(valunc[0])
                  a__dnphi[f_j,meth_off[0]] = FLOAT(valunc[1])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDIF ELSE BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Now define statistics yet
              ;;--------------------------------------------------------------------------
              CASE s_j[0] OF
                8L  : BEGIN                              ;;  Averages
                  IF (ipar[0] LE 2L) THEN avg__nsh[f_j,ipar[0]] = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN avg_nthe[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN avg_nphi[f_j]         = FLOAT(valunc[0])
                END
                9L  : BEGIN                              ;;  Medians
                  IF (ipar[0] LE 2L) THEN med__nsh[f_j,ipar[0]] = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN med_nthe[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN med_nphi[f_j]         = FLOAT(valunc[0])
                END
                10L : BEGIN                              ;;  Standard Deviations
                  IF (ipar[0] LE 2L) THEN std__nsh[f_j,ipar[0]] = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN std_nthe[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN std_nphi[f_j]         = FLOAT(valunc[0])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDELSE
          ENDFOR
        ENDFOR
        ;;  End and set logic for later
        last_bvn_tab = 1b
      END
      test_keyp__s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get data from "Key shock parameters" table
        ;;--------------------------------------------------------------------------------
        s_s0         = all_key_strs
        n_s0         = N_ELEMENTS(s_s0)
        FOR s_j=0L, n_s0[0] - 1L DO BEGIN
          ;;  Read until we hit one of the search strings
          s_slast = ''
          s_slast = s_s0[s_j]
          REPEAT BEGIN
            ;;  Need to increment line counter
            l_j += 1L
            READF,gunit,sline
            test_table = STRPOS(sline[0],s_slast[0]) GE 0
          ENDREP UNTIL (test_table)
          ;;  Found search string
          ;;    --> Define start/end strings
          st_string = td_str_before[0]
          en_string = td_str__after[0]
          ;;------------------------------------------------------------------------------
          ;;  Check for search strings that have special formatting
          ;;------------------------------------------------------------------------------
          test_2       = (s_slast[0] EQ all_stat_se_s[0]) OR $
                         (s_slast[0] EQ all_stat_se_s[1]) OR $
                         (s_slast[0] EQ all_stat_se_s[2])
          IF (test_2[0]) THEN sp_ss = '' ELSE sp_ss = sp_string[0]
          ;;  Loop over parameters for each method
          FOR ipar=0L, 2L DO BEGIN
            ;;----------------------------------------------------------------------------
            ;;  each line = new parameter [ipar] for each method [s_j]
            ;;----------------------------------------------------------------------------
            l_j += 1L
            READF,gunit,sline
            ;;----------------------------------------------------------------------------
            ;;  Separate the useful information from the rest of the string
            ;;----------------------------------------------------------------------------
            valunc  = get_value_se_str(sline[0],st_string[0],en_string[0],sp_ss[0])
            test_sj = (s_j[0] LT 8L)
            IF (test_sj[0]) THEN BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Parameters, not statistics yet
              ;;--------------------------------------------------------------------------
              meth_off = s_j[0]             ;;  Method index
              ;;  ELSE --> check each
              CASE ipar[0] OF
                0L  : BEGIN                              ;;  Avg. upstream shock normal angle [degrees]
                  a__thebn[f_j,meth_off[0]] = FLOAT(valunc[0])
                  a_dthebn[f_j,meth_off[0]] = FLOAT(valunc[1])
                END
                1L  : BEGIN                              ;;  Avg. upstream shock normal speed [km/s, SCF]
                  a___vshn[f_j,meth_off[0]] = FLOAT(valunc[0])
                  a__dvshn[f_j,meth_off[0]] = FLOAT(valunc[1])
                END
                2L  : BEGIN                              ;;  Avg. shock density compression ratio
                  a___n2n1[f_j,meth_off[0]] = FLOAT(valunc[0])
                  a__dn2n1[f_j,meth_off[0]] = FLOAT(valunc[1])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDIF ELSE BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Now define statistics yet
              ;;--------------------------------------------------------------------------
              CASE s_j[0] OF
                8L  : BEGIN                              ;;  Averages
                  IF (ipar[0] LE 0L) THEN avgthebn[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN avg_vshn[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN avg_n2n1[f_j]         = FLOAT(valunc[0])
                END
                9L  : BEGIN                              ;;  Medians
                  IF (ipar[0] LE 0L) THEN medthebn[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN med_vshn[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN med_n2n1[f_j]         = FLOAT(valunc[0])
                END
                10L : BEGIN                              ;;  Standard Deviations
                  IF (ipar[0] LE 0L) THEN stdthebn[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN std_vshn[f_j]         = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN std_n2n1[f_j]         = FLOAT(valunc[0])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDELSE
          ENDFOR
        ENDFOR
        ;;  End and set logic for later
        last_key_tab = 1b
      END
      test_upsw__s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get data from "Upstream wave speeds and mach numbers" table
        ;;--------------------------------------------------------------------------------
        s_s0         = all_ups_strs
        n_s0         = N_ELEMENTS(s_s0)
        FOR s_j=0L, n_s0[0] - 1L DO BEGIN
          ;;  Read until we hit one of the search strings
          s_slast = ''
          s_slast = s_s0[s_j]
          REPEAT BEGIN
            ;;  Need to increment line counter
            l_j += 1L
            READF,gunit,sline
            test_table = STRPOS(sline[0],s_slast[0]) GE 0
          ENDREP UNTIL (test_table)
          ;;  Found search string
          ;;    --> Define start/end strings
          st_string = td_str_before[0]
          en_string = td_str__after[0]
          ;;------------------------------------------------------------------------------
          ;;  Check for search strings that have special formatting
          ;;------------------------------------------------------------------------------
          test_2       = (s_slast[0] EQ all_stat_se_s[0]) OR $
                         (s_slast[0] EQ all_stat_se_s[1]) OR $
                         (s_slast[0] EQ all_stat_se_s[2])
          IF (test_2[0]) THEN sp_ss = '' ELSE sp_ss = sp_string[0]
          ;;  Loop over parameters for each method
          FOR ipar=0L, 5L DO BEGIN
            ;;----------------------------------------------------------------------------
            ;;  each line = new parameter [ipar] for each method [s_j]
            ;;----------------------------------------------------------------------------
            l_j += 1L
            READF,gunit,sline
            ;;----------------------------------------------------------------------------
            ;;  Separate the useful information from the rest of the string
            ;;----------------------------------------------------------------------------
            valunc  = get_value_se_str(sline[0],st_string[0],en_string[0],sp_ss[0])
            test_sj = (s_j[0] LT 8L)
            IF (test_sj[0]) THEN BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Parameters, not statistics yet
              ;;--------------------------------------------------------------------------
              meth_off = s_j[0]             ;;  Method index
              ;;  ELSE --> check each
              ;;  Zero index is for Upstream region
              CASE ipar[0] OF
                0L  : BEGIN                              ;;  Avg. shock normal speed [km/s, SHF]
                  a___ushn[f_j,meth_off[0],0] = FLOAT(valunc[0])
                  a__dushn[f_j,meth_off[0],0] = FLOAT(valunc[1])
                END
                1L  : BEGIN                              ;;  Avg. MHD slow mode speed [km/s]
                  a_____Vs[f_j,meth_off[0],0] = FLOAT(valunc[0])
                  a____dVs[f_j,meth_off[0],0] = FLOAT(valunc[1])
                END
                2L  : BEGIN                              ;;  Avg. MHD intermediate mode speed [km/s]
                  a_____Vi[f_j,meth_off[0],0] = FLOAT(valunc[0])
                  a____dVi[f_j,meth_off[0],0] = FLOAT(valunc[1])
                END
                3L  : BEGIN                              ;;  Avg. MHD fast mode speed [km/s]
                  a_____Vf[f_j,meth_off[0],0] = FLOAT(valunc[0])
                  a____dVf[f_j,meth_off[0],0] = FLOAT(valunc[1])
                END
                4L  : BEGIN                              ;;  Avg. MHD slow mode Mach number
                  a_____Ms[f_j,meth_off[0],0] = FLOAT(valunc[0])
                  a____dMs[f_j,meth_off[0],0] = FLOAT(valunc[1])
                END
                5L  : BEGIN                              ;;  Avg. MHD fast mode Mach number
                  a_____Mf[f_j,meth_off[0],0] = FLOAT(valunc[0])
                  a____dMf[f_j,meth_off[0],0] = FLOAT(valunc[1])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDIF ELSE BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Now define statistics yet
              ;;--------------------------------------------------------------------------
              ;;  Zero index is for Upstream region
              CASE s_j[0] OF
                8L  : BEGIN                              ;;  Averages
                  IF (ipar[0] EQ 0L) THEN avg_ushn[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN avg___Vs[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN avg___Vi[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN avg___Vf[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN avg___Ms[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 5L) THEN avg___Mf[f_j,0]       = FLOAT(valunc[0])
                END
                9L  : BEGIN                              ;;  Medians
                  IF (ipar[0] EQ 0L) THEN med_ushn[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN med___Vs[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN med___Vi[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN med___Vf[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN med___Ms[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 5L) THEN med___Mf[f_j,0]       = FLOAT(valunc[0])
                END
                10L : BEGIN                              ;;  Standard Deviations
                  IF (ipar[0] EQ 0L) THEN std_ushn[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN std___Vs[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN std___Vi[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN std___Vf[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN std___Ms[f_j,0]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 5L) THEN std___Mf[f_j,0]       = FLOAT(valunc[0])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDELSE
          ENDFOR
        ENDFOR
        ;;  End and set logic for later
        last_ups_tab = 1b
      END
      test_dnsw__s[0]  :  BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Get data from "Downstream wave speeds and mach numbers" table
        ;;--------------------------------------------------------------------------------
        s_s0         = all_dns_strs
        n_s0         = N_ELEMENTS(s_s0)
        FOR s_j=0L, n_s0[0] - 1L DO BEGIN
          ;;  Read until we hit one of the search strings
          s_slast = ''
          s_slast = s_s0[s_j]
          REPEAT BEGIN
            ;;  Need to increment line counter
            l_j += 1L
            READF,gunit,sline
            test_table = STRPOS(sline[0],s_slast[0]) GE 0
          ENDREP UNTIL (test_table)
          ;;  Found search string
          ;;    --> Define start/end strings
          st_string = td_str_before[0]
          en_string = td_str__after[0]
          ;;------------------------------------------------------------------------------
          ;;  Check for search strings that have special formatting
          ;;------------------------------------------------------------------------------
          test_2       = (s_slast[0] EQ all_stat_se_s[0]) OR $
                         (s_slast[0] EQ all_stat_se_s[1]) OR $
                         (s_slast[0] EQ all_stat_se_s[2])
          IF (test_2[0]) THEN sp_ss = '' ELSE sp_ss = sp_string[0]
          ;;  Loop over parameters for each method
          FOR ipar=0L, 5L DO BEGIN
            ;;----------------------------------------------------------------------------
            ;;  each line = new parameter [ipar] for each method [s_j]
            ;;----------------------------------------------------------------------------
            l_j += 1L
            READF,gunit,sline
            ;;----------------------------------------------------------------------------
            ;;  Separate the useful information from the rest of the string
            ;;----------------------------------------------------------------------------
            valunc  = get_value_se_str(sline[0],st_string[0],en_string[0],sp_ss[0])
            test_sj = (s_j[0] LT 8L)
            IF (test_sj[0]) THEN BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Parameters, not statistics yet
              ;;--------------------------------------------------------------------------
              meth_off = s_j[0]             ;;  Method index
              ;;  ELSE --> check each
              ;;  One index is for Downstream region
              CASE ipar[0] OF
                0L  : BEGIN                              ;;  Avg. shock normal speed [km/s, SHF]
                  a___ushn[f_j,meth_off[0],1] = FLOAT(valunc[0])
                  a__dushn[f_j,meth_off[0],1] = FLOAT(valunc[1])
                END
                1L  : BEGIN                              ;;  Avg. MHD slow mode speed [km/s]
                  a_____Vs[f_j,meth_off[0],1] = FLOAT(valunc[0])
                  a____dVs[f_j,meth_off[0],1] = FLOAT(valunc[1])
                END
                2L  : BEGIN                              ;;  Avg. MHD intermediate mode speed [km/s]
                  a_____Vi[f_j,meth_off[0],1] = FLOAT(valunc[0])
                  a____dVi[f_j,meth_off[0],1] = FLOAT(valunc[1])
                END
                3L  : BEGIN                              ;;  Avg. MHD fast mode speed [km/s]
                  a_____Vf[f_j,meth_off[0],1] = FLOAT(valunc[0])
                  a____dVf[f_j,meth_off[0],1] = FLOAT(valunc[1])
                END
                4L  : BEGIN                              ;;  Avg. MHD slow mode Mach number
                  a_____Ms[f_j,meth_off[0],1] = FLOAT(valunc[0])
                  a____dMs[f_j,meth_off[0],1] = FLOAT(valunc[1])
                END
                5L  : BEGIN                              ;;  Avg. MHD fast mode Mach number
                  a_____Mf[f_j,meth_off[0],1] = FLOAT(valunc[0])
                  a____dMf[f_j,meth_off[0],1] = FLOAT(valunc[1])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDIF ELSE BEGIN
              ;;--------------------------------------------------------------------------
              ;;  Now define statistics yet
              ;;--------------------------------------------------------------------------
              ;;  One index is for Downstream region
              CASE s_j[0] OF
                8L  : BEGIN                              ;;  Averages
                  IF (ipar[0] EQ 0L) THEN avg_ushn[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN avg___Vs[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN avg___Vi[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN avg___Vf[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN avg___Ms[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 5L) THEN avg___Mf[f_j,1]       = FLOAT(valunc[0])
                END
                9L  : BEGIN                              ;;  Medians
                  IF (ipar[0] EQ 0L) THEN med_ushn[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN med___Vs[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN med___Vi[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN med___Vf[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN med___Ms[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 5L) THEN med___Mf[f_j,1]       = FLOAT(valunc[0])
                END
                10L : BEGIN                              ;;  Standard Deviations
                  IF (ipar[0] EQ 0L) THEN std_ushn[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 1L) THEN std___Vs[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 2L) THEN std___Vi[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 3L) THEN std___Vf[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 4L) THEN std___Ms[f_j,1]       = FLOAT(valunc[0])
                  IF (ipar[0] EQ 5L) THEN std___Mf[f_j,1]       = FLOAT(valunc[0])
                END
                ELSE :                                   ;;  Do nothing
              ENDCASE
            ENDELSE
          ENDFOR
        ENDFOR
        ;;  End and set logic for later
        last_dns_tab = 1b
      END
      ELSE             :  ;;  Do nothing otherwise
    ENDCASE
    ;;------------------------------------------------------------------------------------
    ;;  Test indices
    ;;------------------------------------------------------------------------------------
    test_last_atab = last_gen_tab AND last_asy_tab AND last_bvn_tab AND last_key_tab AND $
                     last_ups_tab AND last_dns_tab
    test_while     = (l_j[0] LT (nfls[0] - 1L)) AND (test_last_atab EQ 0)
    l_j           += (1L*test_while[0])    ;;  Increment index
  ENDWHILE
  ;;--------------------------------------------------------------------------------------
  ;;  Close file and logical unit number
  ;;--------------------------------------------------------------------------------------
  FREE_LUN,gunit
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Define approximate Unix time of shock arrival
;;----------------------------------------------------------------------------------------
;;  Define string time zero
str_t_zero     = '00:00:00.000'
;;  Convert format of dates to 'YYYY-MM-DD'
a__tdate       = STRMID(a__odate,6L,4L)+'-'+STRMID(a__odate,0L,2L)+'-'+STRMID(a__odate,3L,2L)
;;  Define formal time at start of date  [e.g., 'YYYY-MM-DD/hh:mm:ss.xxx']
a__ymdst       = a__tdate+'/'+str_t_zero[0]
;;  Define Unix times at start of date
a__unixs       = time_double(a__ymdst)
;;  Define approximate Unix times at shock arrival
a__unixo       = a__unixs + a__arrvt
;;----------------------------------------------------------------------------------------
;;  Sort by Unix time of shock arrival
;;----------------------------------------------------------------------------------------
sp             = SORT(a__unixo)
a__tdate       = TEMPORARY(a__tdate[sp])
a__unixo       = TEMPORARY(a__unixo[sp])
a__odate       = TEMPORARY(a__odate[sp])
a__frdoy       = TEMPORARY(a__frdoy[sp])
a__arrvt       = TEMPORARY(a__arrvt[sp])
a_darrvt       = TEMPORARY(a_darrvt[sp])
a__stype       = TEMPORARY(a__stype[sp])
a__edatl       = TEMPORARY(a__edatl[sp])
a__scgse       = TEMPORARY(a__scgse[sp,*])
a__nuppt       = TEMPORARY(a__nuppt[sp])
a__nupft       = TEMPORARY(a__nupft[sp])
a__ndnpt       = TEMPORARY(a__ndnpt[sp])
a__ndnft       = TEMPORARY(a__ndnft[sp])
a__mthus       = TEMPORARY(a__mthus[sp])
a__vigse       = TEMPORARY(a__vigse[sp,*,*])
a___vthi       = TEMPORARY(a___vthi[sp,*])
a___vthe       = TEMPORARY(a___vthe[sp,*])
a___iden       = TEMPORARY(a___iden[sp,*])
a___bgse       = TEMPORARY(a___bgse[sp,*,*])
a___beta       = TEMPORARY(a___beta[sp,*])
a_____Cs       = TEMPORARY(a_____Cs[sp,*])
a_____VA       = TEMPORARY(a_____VA[sp,*])
a_dvigse       = TEMPORARY(a_dvigse[sp,*,*])
a__dvthi       = TEMPORARY(a__dvthi[sp,*])
a__dvthe       = TEMPORARY(a__dvthe[sp,*])
a__diden       = TEMPORARY(a__diden[sp,*])
a__dbgse       = TEMPORARY(a__dbgse[sp,*,*])
a__dbeta       = TEMPORARY(a__dbeta[sp,*])
a____dCs       = TEMPORARY(a____dCs[sp,*])
a____dVA       = TEMPORARY(a____dVA[sp,*])
a____nsh       = TEMPORARY(a____nsh[sp,*,*])
a___nthe       = TEMPORARY(a___nthe[sp,*])
a___nphi       = TEMPORARY(a___nphi[sp,*])
a___dnsh       = TEMPORARY(a___dnsh[sp,*,*])
a__dnthe       = TEMPORARY(a__dnthe[sp,*])
a__dnphi       = TEMPORARY(a__dnphi[sp,*])
a__thebn       = TEMPORARY(a__thebn[sp,*])
a___vshn       = TEMPORARY(a___vshn[sp,*])
a___n2n1       = TEMPORARY(a___n2n1[sp,*])
a_dthebn       = TEMPORARY(a_dthebn[sp,*])
a__dvshn       = TEMPORARY(a__dvshn[sp,*])
a__dn2n1       = TEMPORARY(a__dn2n1[sp,*])
a___ushn       = TEMPORARY(a___ushn[sp,*,*])
a_____Vs       = TEMPORARY(a_____Vs[sp,*,*])
a_____Vi       = TEMPORARY(a_____Vi[sp,*,*])
a_____Vf       = TEMPORARY(a_____Vf[sp,*,*])
a_____Ms       = TEMPORARY(a_____Ms[sp,*,*])
a_____Mf       = TEMPORARY(a_____Mf[sp,*,*])
a__dushn       = TEMPORARY(a__dushn[sp,*,*])
a____dVs       = TEMPORARY(a____dVs[sp,*,*])
a____dVi       = TEMPORARY(a____dVi[sp,*,*])
a____dVf       = TEMPORARY(a____dVf[sp,*,*])
a____dMs       = TEMPORARY(a____dMs[sp,*,*])
a____dMf       = TEMPORARY(a____dMf[sp,*,*])
avg__nsh       = TEMPORARY(avg__nsh[sp,*])
avg_nthe       = TEMPORARY(avg_nthe[sp])
avg_nphi       = TEMPORARY(avg_nphi[sp])
med__nsh       = TEMPORARY(med__nsh[sp,*])
med_nthe       = TEMPORARY(med_nthe[sp])
med_nphi       = TEMPORARY(med_nphi[sp])
std__nsh       = TEMPORARY(std__nsh[sp,*])
std_nthe       = TEMPORARY(std_nthe[sp])
std_nphi       = TEMPORARY(std_nphi[sp])
avgthebn       = TEMPORARY(avgthebn[sp])
avg_vshn       = TEMPORARY(avg_vshn[sp])
avg_n2n1       = TEMPORARY(avg_n2n1[sp])
medthebn       = TEMPORARY(medthebn[sp])
med_vshn       = TEMPORARY(med_vshn[sp])
med_n2n1       = TEMPORARY(med_n2n1[sp])
stdthebn       = TEMPORARY(stdthebn[sp])
std_vshn       = TEMPORARY(std_vshn[sp])
std_n2n1       = TEMPORARY(std_n2n1[sp])
avg_ushn       = TEMPORARY(avg_ushn[sp,*])
avg___Vs       = TEMPORARY(avg___Vs[sp,*])
avg___Vi       = TEMPORARY(avg___Vi[sp,*])
avg___Vf       = TEMPORARY(avg___Vf[sp,*])
avg___Ms       = TEMPORARY(avg___Ms[sp,*])
avg___Mf       = TEMPORARY(avg___Mf[sp,*])
med_ushn       = TEMPORARY(med_ushn[sp,*])
med___Vs       = TEMPORARY(med___Vs[sp,*])
med___Vi       = TEMPORARY(med___Vi[sp,*])
med___Vf       = TEMPORARY(med___Vf[sp,*])
med___Ms       = TEMPORARY(med___Ms[sp,*])
med___Mf       = TEMPORARY(med___Mf[sp,*])
std_ushn       = TEMPORARY(std_ushn[sp,*])
std___Vs       = TEMPORARY(std___Vs[sp,*])
std___Vi       = TEMPORARY(std___Vi[sp,*])
std___Vf       = TEMPORARY(std___Vf[sp,*])
std___Ms       = TEMPORARY(std___Ms[sp,*])
std___Mf       = TEMPORARY(std___Mf[sp,*])
;;----------------------------------------------------------------------------------------
;;  Define output structures
;;    1)  If parameter has an uncertainty, then it will be a structure with the tags:
;;          Y   :  Array of values
;;          DY  :  Array of uncertainties
;;    2)  If table has associated statistics, then they will be found in an additional
;;          structure defined by the tag, STATS, that contains the same tags as the
;;          outer structure but each tag is now a structure with the tags:
;;          AVG  :  Array of averages (over methods) of TAG[i] values
;;          MED  :  Array of medians (over methods) of TAG[i] values
;;          STD  :  Array of Std. Dev.'s (over methods) of TAG[i] values
;;----------------------------------------------------------------------------------------
;;  Define structure for "General Information" table
tags           = ['TDATES','FRAC_DOY','ARRT_SOD','ARRT_UNIX','SH_TYPE','E_DATA_YN',$
                  'SCPOS_GSE','N_UP_P_PTS','N_UP_F_PTS','N_DN_P_PTS','N_DN_F_PTS', $
                  'RH_METHOD']
gen_info_str   = CREATE_STRUCT(tags,a__tdate,a__frdoy,{Y:a__arrvt,DY:a_darrvt},    $
                               {Y:a__unixo,DY:a_darrvt},a__stype,a__edatl,a__scgse,$
                               a__nuppt,a__nupft,a__ndnpt,a__ndnft,a__mthus)
;;  Define structure for "Asymptotic plasma parameters" table
tags           = ['VBULK_GSE','VTH_ION','VTH_ELE','DENS_ION','MAGF_GSE','PLASMA_BETA',$
                  'SOUND_SPEED','ALFVEN_SPEED']
asy_info_str   = CREATE_STRUCT(tags,{Y:a__vigse,DY:a_dvigse},{Y:a___vthi,DY:a__dvthi},$
                               {Y:a___vthe,DY:a__dvthe},{Y:a___iden,DY:a__diden},     $
                               {Y:a___bgse,DY:a__dbgse},{Y:a___beta,DY:a__dbeta},     $
                               {Y:a_____Cs,DY:a____dCs},{Y:a_____VA,DY:a____dVA})
;;  Define structure for "Best values of shock front normal for each method" table
tag0           = ['SH_N_GSE','SH_N_THE','SH_N_PHI']
tags           = [tag0,'STATS']
stat_str       = CREATE_STRUCT(tag0,{AVG:avg__nsh,MED:med__nsh,STD:std__nsh},$
                                    {AVG:avg_nthe,MED:med_nthe,STD:std_nthe},$
                                    {AVG:avg_nphi,MED:med_nphi,STD:std_nphi})
bvn_info_str   = CREATE_STRUCT(tags,{Y:a____nsh,DY:a___dnsh},{Y:a___nthe,DY:a__dnthe},$
                                    {Y:a___nphi,DY:a__dnphi},stat_str)
;;  Define structure for "Key shock parameters" table
tag0           = ['THETA_BN','VSHN_UP','NIDN_NIUP']
tags           = [tag0,'STATS']
stat_str       = CREATE_STRUCT(tag0,{AVG:avgthebn,MED:medthebn,STD:stdthebn},$
                                    {AVG:avg_vshn,MED:med_vshn,STD:std_vshn},$
                                    {AVG:avg_n2n1,MED:med_n2n1,STD:std_n2n1})
key_info_str   = CREATE_STRUCT(tags,{Y:a__thebn,DY:a_dthebn},{Y:a___vshn,DY:a__dvshn},$
                                    {Y:a___n2n1,DY:a__dn2n1},stat_str)
;;  Define structure for "Upstream wave speeds and mach numbers" table
tag0           = ['USHN','V_SLOW','V_INTM','V_FAST','M_SLOW','M_FAST']
tags           = [tag0,'STATS']
stat_str       = CREATE_STRUCT(tag0,{AVG:avg_ushn[*,0],MED:med_ushn[*,0],STD:std_ushn[*,0]},$
                                    {AVG:avg___Vs[*,0],MED:med___Vs[*,0],STD:std___Vs[*,0]},$
                                    {AVG:avg___Vi[*,0],MED:med___Vi[*,0],STD:std___Vi[*,0]},$
                                    {AVG:avg___Vf[*,0],MED:med___Vf[*,0],STD:std___Vf[*,0]},$
                                    {AVG:avg___Ms[*,0],MED:med___Ms[*,0],STD:std___Ms[*,0]},$
                                    {AVG:avg___Mf[*,0],MED:med___Mf[*,0],STD:std___Mf[*,0]})
ups_info_str   = CREATE_STRUCT(tags,{Y:a___ushn[*,*,0],DY:a__dushn[*,*,0]},$
                                    {Y:a_____Vs[*,*,0],DY:a____dVs[*,*,0]},$
                                    {Y:a_____Vi[*,*,0],DY:a____dVi[*,*,0]},$
                                    {Y:a_____Vf[*,*,0],DY:a____dVf[*,*,0]},$
                                    {Y:a_____Ms[*,*,0],DY:a____dMs[*,*,0]},$
                                    {Y:a_____Mf[*,*,0],DY:a____dMf[*,*,0]},stat_str)

;;  Define structure for "Downstream wave speeds and mach numbers" table
tag0           = ['USHN','V_SLOW','V_INTM','V_FAST','M_SLOW','M_FAST']
tags           = [tag0,'STATS']
stat_str       = CREATE_STRUCT(tag0,{AVG:avg_ushn[*,1],MED:med_ushn[*,1],STD:std_ushn[*,1]},$
                                    {AVG:avg___Vs[*,1],MED:med___Vs[*,1],STD:std___Vs[*,1]},$
                                    {AVG:avg___Vi[*,1],MED:med___Vi[*,1],STD:std___Vi[*,1]},$
                                    {AVG:avg___Vf[*,1],MED:med___Vf[*,1],STD:std___Vf[*,1]},$
                                    {AVG:avg___Ms[*,1],MED:med___Ms[*,1],STD:std___Ms[*,1]},$
                                    {AVG:avg___Mf[*,1],MED:med___Mf[*,1],STD:std___Mf[*,1]})
dns_info_str   = CREATE_STRUCT(tags,{Y:a___ushn[*,*,1],DY:a__dushn[*,*,1]},$
                                    {Y:a_____Vs[*,*,1],DY:a____dVs[*,*,1]},$
                                    {Y:a_____Vi[*,*,1],DY:a____dVi[*,*,1]},$
                                    {Y:a_____Vf[*,*,1],DY:a____dVf[*,*,1]},$
                                    {Y:a_____Ms[*,*,1],DY:a____dMs[*,*,1]},$
                                    {Y:a_____Mf[*,*,1],DY:a____dMf[*,*,1]},stat_str)
;;----------------------------------------------------------------------------------------
;;  Define return structure
;;----------------------------------------------------------------------------------------
tags           = ['GEN_INFO','ASY_INFO','BVN_INFO','KEY_INFO','UPS_INFO','DNS_INFO']
struct         = CREATE_STRUCT(tags,gen_info_str,asy_info_str,bvn_info_str,key_info_str,$
                                    ups_info_str,dns_info_str)
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struct
END

