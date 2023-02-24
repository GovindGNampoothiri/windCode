;+
;*****************************************************************************************
;
;  FUNCTION :   lbw_digamma.pro
;  PURPOSE  :   Returns digamma function (i.e., derivative of Gamma function divided
;                 by Gamma function) of argument z.  This routine is used when one
;                 calculates the derivative of a kappa velocity distribution function
;                 analytically.
;
;                 The asymptotic series (about z_o = infinity) is defined as:
;
;                                        z
;                   psi(x) = -¥ + ∑ -----------
;                                    n (n + z)
;
;                 where z = (x - 1), ¥ = Euler-Mascheroni constant, and ∑ is a sum
;                 from n = 1 to +infinity.  To achieve 7 digits of accuracy for x = 5,
;                 we need N ~ 30000000 terms.
;
;                 If we expand psi(z) in a series about +infinity, we find:
;
;                                 1      1        1           1           1
;                   psi(z) = -Ln --- - ----- - -------- + --------- - --------- +
;                                 z     2 z     12 z^2     120 z^4     252 z^6
;
;                                    1           1            691            1
;                                --------- - ---------- + ------------ - --------- +
;                                 240 z^8     132 z^10     32760 z^12     12 z^14
;
;                                    3617         43,867         174,611      77,683
;                                ----------- - ------------ + ----------- - ---------- +
;                                 8160 z^16     14364 z^18     6600 z^20     276 z^22
;
;                                 236,364,091      657931      [  1   ]
;                                ------------- - ---------- + O[------]
;                                 65,520 z^24     12  z^26     [ z^27 ]
;
;                 unfortunately, the number of terms that results in a minimum
;                 difference from the "true" value is neither constant nor an
;                 increasing number with increasing z.  Therefore, we will use the
;                 summation above.
;
;  CALLED BY:   
;               temp_bimaxwellian_plus_bikappa_1d.pro
;
;  CALLS:
;               is_a_number.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               Z  :  Scalar [float/double] defining the argument of the digamma function
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               N  :  Scalar [long] defining the number of terms to use in the summation
;                       [Default = 30000000]
;
;   CHANGED:  1)  Finished writing routine
;                                                                   [04/23/2015   v1.0.0]
;             2)  Changed long integers to unsigned long integers in case
;                   user sends in a number that exceeds the limit of a long integer
;                                                                   [04/24/2015   v1.0.1]
;             3)  Moved to ~/wind_3dp_pros/LYNN_PRO/general_math/ and updated routine
;                                                                   [08/12/2015   v1.1.0]
;
;   NOTES:      
;               1)  The Euler-Mascheroni constant to 50 decimal places is:
;                     0.57721566490153286060651209008240243104215933593992
;               2)  The larger the value of N, the more accurate the result
;                     --> the Default value only gives accurate results to
;                           ~7 decimal places
;               3)  Unfortunately, this routine is slow as it creates an array of values
;                     that can be several billion elements long, depending on the
;                     precision desired by the user
;
;  REFERENCES:  
;               Equation (15) at:
;                 http://mathworld.wolfram.com/DigammaFunction.html
;
;   CREATED:  04/01/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/12/2015   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION lbw_digamma,z,N=n

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
em_gam         = 0.57721566490153286060651209008240243104215933593992d0
def_n          = 30000000UL
min_prec       = 1d-12
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() NE 1) OR (is_a_number(z,/NOMSSG) EQ 0) OR $
                 (N_ELEMENTS(z) LT 1)
IF (test) THEN BEGIN
  ;;  (Incorrect # of inputs) OR (Input was not numeric)
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check N
test           = (N_ELEMENTS(n) LT 1) OR (is_a_number(n) EQ 0)
IF (test) THEN nn = def_n[0] ELSE nn = ULONG(n[0] > def_n[0])
;;  Make sure N is large enough so that the deviation from Euler-Mascheroni constant
;;    is less than ~10^(-12)
zz             = z[0] - 1d0
min_n          = (-zz[0] + SQRT(zz[0]^2 + 4d0*(zz[0]/min_prec[0])))/2d0
nn             = nn[0] > ULONG(ABS(min_n[0]))
;;----------------------------------------------------------------------------------------
;;  Calculate deviation from Euler-Mascheroni constant
;;----------------------------------------------------------------------------------------
listn          = TEMPORARY(ULINDGEN(nn[0]) + 1L)
d_psi_tot      = TOTAL(zz[0]/(listn*(listn + zz[0])),/NAN)
;;----------------------------------------------------------------------------------------
;;  Calculate the value of the digamma function
;;----------------------------------------------------------------------------------------
psi_final      = -em_gam[0] + d_psi_tot[0]
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,psi_final[0]
END
