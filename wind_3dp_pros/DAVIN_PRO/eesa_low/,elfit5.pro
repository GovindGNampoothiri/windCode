function far_theta,theta,e_pot,alpha
rad = !dpi/180.d

st2 = sin(theta*rad)
sg = (st2 gt 0) * 2 -1
st2 = st2^2
e = sqrt(1+4.d*e_pot*(e_pot-1)*st2)
th0 = acos(-1/e) - acos( (2*e_pot*st2-1)/e )
return,th0/rad*sg
end



; .r elfit5

function elfit5, x,  $
    set=set, $
    type = type, $
    parameters=p 

k_an = 6.42


if not keyword_set(p) then begin
   ldf = [-9.23,-9.53,-10.07,-10.52,-11.30,-13.,-14.]
   photo = {ldf:ldf,nrg:fltarr(7) }
   core = {n:10.d,  t:10.d, tdif:0.d,  v:0.d}
   halo = {n:.1d,  vth:5000.d, k:4.3d,  v:0.d}
   p13 = {ph:photo,core:core,  halo:halo,  $
    e_shift:0.d, v_shift:0.31d, sc_pot:5.d, vsw:[500.d,0.d,0.d], $
    magf:[0.,0.,1.], $
    ntot:10.d,  $
    dflag:0, $
    deadtime:0.6d-6,expand:8  }
   p=p13
endif

if p.dflag then p.core.n = p.ntot-p.halo.n else p.ntot=p.core.n+p.halo.n

if data_type(x) ne 8 then begin
;   Set limits:
  p.sc_pot   =  .1    > p.sc_pot    < 40
  p.ntot     = .05    > p.ntot    < 200
  p.core.n   = .05    > p.core.n    < 200
  p.core.t   = 0.3    > p.core.t    < 50
  p.core.tdif= -.6    > p.core.tdif < .6
  p.core.v   = -500   > p.core.v    < 500
  p.halo.n   = 0.00    > p.halo.n    < 5
  p.halo.vth = 2000   > abs(p.halo.vth)  < 6000
  p.halo.v   = -5000  > p.halo.v    < 5000
  p.halo.k   = 3      > p.halo.k    < 5
  p.vsw  = [-900.,-200.,-200.] > p.vsw < [200.,200.,200.]
  return,0
endif

energy = x.energy + p.E_shift    ;  True energy, accounting for HV offset
theta = x.theta
phi = x.phi

p.ph.nrg = (reverse(k_an*average(x.volts,1)))[0:6]

if keyword_set(p.expand) then expand=8
str_element,x,'volts',volts
if not keyword_set(volts) then expand=0


if keyword_set(expand) then begin
  nrg2 = (x.volts + p.v_shift) * k_an
p.ph.nrg = (reverse(average(nrg2,1)))[0:6]

  nn = x.nenergy
  nb = x.nbins
  i = replicate(1.,expand)
  nn2 = nn*expand

  energy = nrg2[*] # replicate(1.,nb)
  phi = reform(i # phi[*],nn2,nb)
  theta = reform(i # theta[*],nn2,nb)
endif


mass = x.mass
units = x.units_name
nrg_inf  = (energy-p.sc_pot) 
vel = sqrt(2*(energy-p.sc_pot)/mass)  ;Particle velocity far from potential
;theta = far_theta(theta,energy/p.sc_pot)
sphere_to_cart,vel,theta,phi,vx,vy,vz
magf =x.magf
bdir = magf/sqrt(total(magf^2))
bx = bdir(0)
by = bdir(1)
bz = bdir(2)

vsw  = x.vsw   ; mod
vsw  = p.vsw
f = 0

wght = 0. > (p.sc_pot - energy) < 1.
iwght = 1. - wght

photo = p.ph
if keyword_set(0) then begin
   fphoto =  (mass/2/!dpi/photo.t)^1.5 * 1e10 * photo.n * exp(- energy/photo.t)
   f = f+ wght * fphoto
endif

if keyword_set(photo.ldf[0]) then begin
   ldf2 = spl_init(photo.nrg,photo.ldf,/double)
   fphoto =  10^( spl_interp(photo.nrg,photo.ldf,ldf2,energy) ) * 1e10
   f = f+ wght * fphoto
endif

if p.core.n ne 0 then begin
  vcore = vsw + bdir * p.core.v
  vsx = vx - vcore[0] 
  vsy = vy - vcore[1]
  vsz = vz - vcore[2]
  vtot2 = vsx*vsx + vsy*vsy + vsz*vsz
  cos2a = (vsx*bx + vsy*by + vsz*bz)^2/vtot2

  e = exp( -0.5*mass*vtot2 / p.core.t * (1.d + cos2a*p.core.tdif) )
  k = (mass/2/!dpi)^1.5 * 1e10

  fcore = (k * p.core.n * sqrt((1+p.core.tdif)/p.core.t^3) ) * e
  w = where(energy le (p.sc_pot > 0.),c)
  if c ne 0 then fcore[w]=0.
  f= f+ iwght * fcore
endif

if p.halo.n ne 0 then begin
  vhalo = vsw + bdir *p.halo.v
  vsx = vx - vhalo(0)
  vsy = vy - vhalo(1)
  vsz = vz - vhalo(2)
  vtot2 = vsx*vsx + vsy*vsy + vsz*vsz
  cos2a = (vsx*bx + vsy*by + vsz*bz)^2/vtot2
;  if tag_names(/str,p.halo) eq 'DIST2' then begin
     vh2 = (p.halo.k-1.5)*p.halo.vth^2
     kc = (!dpi*vh2)^(-1.5) *  gamma(p.halo.k+1)/gamma(p.halo.k-.5) *1e10
     fhalo = p.halo.n*kc*(1+(vtot2/vh2))^(-p.halo.k-1) 
;  endif else begin
;     e = exp( -0.5*mass*vtot2 / p.halo.t * (1.d + cos2a*p.halo.tdif) )
;     k = (mass/2/!dpi)^1.5 * 1e10
;     fhalo = (k * p.halo.n * sqrt((1+p.halo.tdif)/p.halo.t^3) ) * e
;  endelse
  w = where(energy le (p.sc_pot > 0.),c)
  if c ne 0 then fhalo[w]=0
  f = f+ iwght*fhalo

endif

a = 2./mass^2/1e5

eflux = f* energy^2 * a

if keyword_set(expand) then begin
  eflux = average(reform(eflux,expand,nn,nb),1)
  energy = average(reform(energy,expand,nn,nb),1)
  theta = average(reform(theta,expand,nn,nb),1)
  phi = average(reform(phi,expand,nn,nb),1)
endif



case strlowcase(units) of
'df'     :  data = eflux/energy^2/a
'flux'   :  data = eflux/energy
'eflux'  :  data = eflux
else     : begin
    crate =  x.geomfactor *x.gf * eflux
    anode = byte((90 - x.theta)/22.5)
    deadtime = (p.deadtime/[1.,1.,2.,4.,4.,2.,1.,1.])(anode)
    rate = crate/(1+ deadtime *crate)
    bkgrate = 0
    str_element,p,'bkgrate',bkgrate
    rate = rate + bkgrate
    case strlowcase(units) of
       'crate'  :  data = crate
       'rate'   :  data = rate
       'counts' :  data = rate * x.dt
    endcase
    end
endcase



if keyword_set(set) then begin
  x.data = data
  x.e_shift = p.e_shift
  str_element,/add,x,'sc_pot',p.sc_pot    ;  x.sc_pot = p.sc_pot
  x.vsw = p.vsw
  x.magf = p.magf
  str_element,/add,x,'deadtime', deadtime
endif

str_element,x,'bins',value = bins
if n_elements(bins) gt 0 then begin
   ind = where(bins)
   data = data(ind)
endif else data = reform(data,n_elements(data),/overwrite)
if keyword_set(set) and keyword_set(bins) then begin
   w = where(bins eq 0,c)
   if (c ne 0)  and (set eq 2) then x.data(w) = !values.f_nan
endif

return,data
end


