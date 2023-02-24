;+
;*****************************************************************************************
;
;  FUNCTION :   vec_trans.pro
;  PURPOSE  :   Returns the transverse component of an input vector, V, with respect to
;                 a normal vector, n, given by:  v_t = (n x V) x n
;
;  CALLED BY:   
;               rh_eq_gen.pro
;
;  CALLS:
;               my_crossp_2.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               V  :  [N,3]-Element vector to find the transverse component of...
;               N  :  [M,3]-Element unit normal vector
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  Removed renormalization of n                   [09/09/2011   v1.0.1]
;             2)  Changed input                                  [09/10/2011   v1.1.0]
;
;   NOTES:      
;               
;
;  REFERENCES:  
;               1)  Jackson, John David (1999), "Classical Electrodynamics,"
;                      Third Edition, John Wiley & Sons, Inc., New York, NY.,
;                      ISBN 0-471-30932-X
;
;   CREATED:  06/21/2011
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  09/10/2011   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION vec_trans,v,n

;-----------------------------------------------------------------------------------------
; => Define dummy variables
;-----------------------------------------------------------------------------------------
f     = !VALUES.F_NAN
d     = !VALUES.D_NAN
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 2) THEN RETURN,REPLICATE(d,3)

;-----------------------------------------------------------------------------------------
; => Define transverse component
;-----------------------------------------------------------------------------------------
v1    = v                    ; => [N,3]-Element array
n1    = n                    ; => [M,3]-Element array
mm    = N_ELEMENTS(n1[*,0])
nv    = N_ELEMENTS(v1[*,0])
test  = (mm NE nv)
IF (test) THEN BEGIN
  dm    = REPLICATE(1d0,mm)
  dv    = REPLICATE(1d0,nv)
  v1x   = v1[*,0] # dm               ; => [N,M]-Element array
  v1y   = v1[*,1] # dm               ; => [N,M]-Element array
  v1z   = v1[*,2] # dm               ; => [N,M]-Element array
  v1mn  = [[[v1x]],[[v1y]],[[v1z]]]  ; => [N,M,3]-Element array
  n1x   = dv # n1[*,0]               ; => [N,M]-Element array
  n1y   = dv # n1[*,1]               ; => [N,M]-Element array
  n1z   = dv # n1[*,2]               ; => [N,M]-Element array
  n1mn  = [[[n1x]],[[n1y]],[[n1z]]]  ; => [N,M,3]-Element array
  vt    = REPLICATE(d,nv,mm,3L)      ; => [N,M,3]-Element array
  IF (mm GT nv) THEN BEGIN
    ; => loop through nv
    FOR j=0L, nv - 1L DO BEGIN
      nn0       = REFORM(n1mn[j,*,*])      ; => [M,3]-Element array
      vv0       = REFORM(v1mn[j,*,*])      ; => [M,3]-Element array
      ; => v_tt = (n x V)
      nxv       = my_crossp_2(nn0,vv0,/NOM)
      ; =>  v_t = (n x V) x n        [page 357 Eq. 8.22 of Jackson E&M 3rd Edition]
      vt[j,*,*] = my_crossp_2(nxv,nn0,/NOM)
    ENDFOR
  ENDIF ELSE BEGIN
    ; => loop through mm
    FOR j=0L, mm - 1L DO BEGIN
      nn0       = REFORM(n1mn[*,j,*])      ; => [N,3]-Element array
      vv0       = REFORM(v1mn[*,j,*])      ; => [N,3]-Element array
      ; => v_tt = (n x V)
      nxv       = my_crossp_2(nn0,vv0,/NOM)
      ; =>  v_t = (n x V) x n        [page 357 Eq. 8.22 of Jackson E&M 3rd Edition]
      vt[*,j,*] = my_crossp_2(nxv,nn0,/NOM)
    ENDFOR
  ENDELSE
ENDIF ELSE BEGIN
  ; => M = N
  ; => v_tt = (n x V)
  nxv   = my_crossp_2(n1,v1,/NOM)
  ; =>  v_t = (n x V) x n        [page 357 Eq. 8.22 of Jackson E&M 3rd Edition]
  vt    = my_crossp_2(nxv,n1,/NOM)
ENDELSE
;-----------------------------------------------------------------------------------------
; => Return transverse vector
;-----------------------------------------------------------------------------------------

RETURN,vt
END
