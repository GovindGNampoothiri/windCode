;+
;NAME:		cut1d
;CALL:		cut1d,timevectorofstrings,[keywords]
;KEYWORDS:	inst: tells which instrument to use ('el','ph2',etc.), def. is 'el'
;		DEFAULT INST IS EL
;		xrange: the xrange
;		range: the zrange
;		units: the units ('df','eflux',etc.) (def. is 'df')
;		notzlog: plots on a linear z scale
;			THERE MAY BE PROBLEMS IF NOTZLOG IS SET
;		thebdata: specifies which b data to use (default is B3_gse)
;		plotenergy: plots with x as energy rather than velocity
;		vel: the velocity to use for bulk flow transform, def. is v_3d_ph
;		IF VEL KEYWORD IS NOT SET, THE DATA IS NOT TRANSFORMED
;		step: tells the program to step the data.  If it's set to 1, then
;			it will do automatic stepping.
;		nosmooth: doesn't smooth the data
;		resolution: resolution of interpolated grid
;		gettimes: returns the times used
;		picktimes: let's the user pick times to use
;		erange: sets the energy range used
;		rmbins: specifies the angle range around the anti sunward
;			direction to cut out (useful for photoelectrons)
;			If this keyword is set like /rm, it uses 30 deg.
;		var_label: puts the variable labels on for each time
;		last: automatically duplicates last plot (overrides /picktimes)
;CREATED:	Arjun Raj (2-19-98)
;EXAMPLES:
;		cut1d,['96-01-12/14:','96-01-12/15:'],bdata = 'Bexp'
;		shows 1d cuts at two times, using Bexp
;		cut1d,/picktimes,inst = 'ph',units = 'eflux'
;		user selects times, shows Pesa High data in eflux units
;		cut1d,/picktimes,erange = [25,1400]
;		user selects times, restricts energy range to cut out photoelectrons
;-





pro cut1d,thetimes,inst = inst,xrange = xrange,range = range,units = units,nozlog = nozlog,thebdata = thebdata, nogrid = nogrid,nosmooth = nosmooth,noolines = noolines,numolines = numolines,zlog = zlog,b3=b3,position = position,erange = erange,nofill = nofill,var_label = var_label,nlines = nlines,showdata = showdata,plotenergy = plotenergy,vel = vel,nosubtract = nosubtract,noerase = noerase,smooth = smooth,resolution = resolution,onecnt = onecnt,gettimes = gettimes,picktimes = picktimes,step = step,last = last,rmbins = rmbins,_EXTRA=e

if keyword_set(rmbins) then begin
	if rmbins eq 1 then rmbins = 30
endif

@tplot_com

numperrow = 3

;MODIFICATIONS TO MAKE COMMAND LINE SMALLER
if not keyword_set(nozlog) then zlog = 1
if not keyword_set(nogrid) then grid = 1
if not keyword_set(nosmooth) then smooth = 1

if not keyword_set(thebdata) then thebdata = 'B3_gsm'
if keyword_set(b3) then thebdata = 'B3_gsm'
if not keyword_set(vel) then nosubtract = 1

if keyword_set(zlog) then print,'zlog'
if keyword_set(grid) then print,'grid'
if keyword_set(cross) then print,'cross'
if keyword_set(smooth) then print,'smooth'
if keyword_set(olines) then print,'olines'
if not keyword_set(units) then units = 'df'


;END MODIFICATiONS

if !d.name eq 'PS' then loadct,39

if not keyword_set(resolution) then resolution = 51
if resolution mod 2 eq 0 then resolution = resolution + 1

oldplot = !p.multi

!p.multi = [0,2,1]

if keyword_set(last) then begin
	get_data,'cut1d',data = d
	thetimes = time_string(d.x)
endif

if keyword_set(picktimes) and not keyword_set(last) then begin
	ctime,times
	thetimes = time_string(times)
	if !d.name ne 'PS' then begin
		failed = set_tplot_window(old_window)
		if failed eq 0 then begin
			time_bars,'cut1d',/checkrange
			store_data,'cut1d',data = {x:str_to_time(thetimes)}
			time_bars,'cut1d'
		endif
		wi,old_window
	endif
endif

;help,/str,tplot_vars.settings
store_data,'cut1d',data = {x:str_to_time(thetimes),y:tplot_vars.settings.trange_cur}


if not keyword_set(vel) then vel = 'v_3d_phnrrm2'


if not keyword_set(position) then begin
	x_size = !d.x_size & y_size = !d.y_size
	xsize = .77
	yoffset = 0.
	d=1.
	yoffset = yoffset + .5
	xsize = xsize/2.+.13/1.5
	y_size = y_size/2.
	x_size = x_size/2.
	d = .5
	if y_size le x_size then $
		position2 = [.13*d+.05,.03+.13*d,.05+.13*d + xsize * y_size/x_size,.13*d + xsize+.03] else $
		position2 = [.13*d+.05,.03+.13*d,.05+.13*d + xsize,.13*d + xsize *x_size/y_size+.03]

	if y_size le x_size then $
		position = [.13*d+.05,.13*d+yoffset,.05+.13*d + xsize * y_size/x_size,.13*d + xsize + yoffset] else $
		position = [.13*d+.05,.13*d+yoffset,.05+.13*d + xsize,.13*d + xsize *x_size/y_size + yoffset]
endif

;if keyword_set(var_label) then begin
;	position2(1) = position2(1) + .08
;	position2(3) = position2(3) + .08
;	position(1) = position(1) + .06
;	position(3) = position(3) + .06
;endif

if not keyword_set(nsteps) then nsteps = 18
if not keyword_set(units) then units = 'eflux'
if not keyword_set(nlines) then nlines = 60
if not keyword_set(inst) then inst = 'el'

plotstr = {min:float(0),max:float(0),time:double(0), $
	vperpmin:fltarr(resolution),vperpplus:fltarr(resolution), $
	vparamin:fltarr(resolution),vparaplus:fltarr(resolution),x:dblarr(resolution)}

theplots = replicate(plotstr,n_elements(thetimes))


;**************************MAIN LOOP STARTS HERE*******************************
;******************************************************************************
for j = 0,n_elements(thetimes)-1 do begin

thedata = call_function('get_'+inst,thetimes(j))

if keyword_set(rmbins) then $
	thedata = bin_remove(thedata, an=rmbins)

theonecnt = thedata
thedata = conv_units(thedata,units)


;theonecnt = conv_units(theonecnt,'ncounts')
for i = 0,theonecnt.nenergy-1 do theonecnt.data(i,*) = 1
;theonecnt = conv_units(theonecnt,units)
;if theonecnt.units_name eq 'Counts' then theonecnt.data(*,*) = 1.

;**********************************************
bad_bins=where((thedata.dphi eq 0) or (thedata.dtheta eq 0) or $
	((thedata.data(0,*) eq 0.) and (thedata.theta(0,*) eq 0.) and $
	(thedata.phi(0,*) eq 180.)),n_bad)
good_bins=where(((thedata.dphi ne 0) and (thedata.dtheta ne 0)) and not $
	((thedata.data(0,*) eq 0.) and (thedata.theta(0,*) eq 0.) and $
	(thedata.phi(0,*) eq 180.)),n_good)

if n_bad ne 0 then print,'There are bad bins'
if thedata.valid ne 1 then print,'Not valid data'

bad120 = where(good_bins eq 120,count)
if count eq 1 and thedata.data_name eq 'Pesa High' then begin
	print, 'Fixing bad 120 bin'
	if n_bad eq 0 then bad_bins = [120] else bad_bins = [bad_bins,120]
	good_bins = good_bins(where(good_bins ne 120))
	n_bad = n_bad + 1
	n_good = n_good -1
endif

;**********************************************

;get the magnetic field into a variable

get_data,thebdata,data = mgf



;************EXPERIMENTAL INTERPOLATION FIX************
get_data,thebdata,data = bdata
index = where(bdata.x le thedata.time + 600 and bdata.x ge thedata.time - 600)
store_data,thebdata+'cut',data={x:bdata.x(index),y:bdata.y(index,*)}
;********

store_data,'time',data = {x:thedata.time+thedata.integ_t*.5}
interpolate,'time',thebdata+'cut','Bfield'
get_data,'Bfield',data = mgf
bfield = fltarr(3)
bfield[0] = mgf.y(0,0)
bfield[1] = mgf.y(0,1)
bfield[2] = mgf.y(0,2)
print,time_string(mgf.x)


;In order to find out how many particles there are at all the different locations,
;we must transform the data into cartesian coordinates.

data = {dir:fltarr(n_good,3),energy:reverse(thedata.energy(*,0)),n:fltarr(thedata.nenergy,n_good)}

x = fltarr(n_good) & y = fltarr(n_good) & z = fltarr(n_good)

sphere_to_cart,1,thedata.theta(0,good_bins),thedata.phi(0,good_bins),x,y,z
data.dir(*,0) = x & data.dir(*,1) = y & data.dir(*,2) = z

if units eq 'counts' then $
	for i = 0,thedata.nenergy - 1 do $
		data.n(i,*) = thedata.data(thedata.nenergy-1-i,good_bins)/thedata.geom $
 else $
	for i = 0,thedata.nenergy - 1 do $
		data.n(i,*) = thedata.data(thedata.nenergy-1-i,good_bins)

;now the variable data contains both a tag with the directions associated with all the bins
;as well as all the counts.

if not keyword_set(erange) then begin
	erange = [data.energy(0,0),data.energy(thedata.nenergy-1,0)]
	eindex = indgen(thedata.nenergy)
endif else begin
	eindex = where(data.energy ge erange(0) and data.energy le erange(1))
	erange = [data.energy(eindex(0)),data.energy(eindex(n_elements(eindex)-1))]
endelse

;angles = angl(data.dir,bfield)

energy = data.energy(eindex)
n = data.n(eindex,*)

newdata = {dir:fltarr(n_elements(n),3),n:fltarr(n_elements(n))}

if strpos(thedata.data_name, 'Eesa') ne -1 then mass = 9.1e-31 $
	else mass = 1.67e-27

for i = 0,n_elements(energy)-1 do begin
	if not keyword_set(plotenergy) then $
		newdata.dir(i*n_elements(data.dir)/3:(i*n_elements(data.dir)/3+n_elements(data.dir)/3-1),*) = data.dir*sqrt(2*1.6e-19*energy(i)/mass) $
	else $
		newdata.dir(i*n_elements(data.dir)/3:(i*n_elements(data.dir)/3+n_elements(data.dir)/3-1),*) = data.dir*energy(i)

	newdata.n(i*n_elements(data.dir)/3:(i*n_elements(data.dir)/3+n_elements(data.dir)/3-1)) = reform(n(i,*))
endfor


if keyword_set(vel) then begin
	interpolate,'time',vel,'value'
	get_data,'value',data = thevalue
	thevel = 1000.* reform(thevalue.y)
	if keyword_set(plotenergy) then factor = sqrt(total(thevel(*)^2))*mass/2./1.6e-19 else factor = 1.
	if not keyword_set(nosubtract) then begin
		newdata.dir(*,0) = newdata.dir(*,0) - thevel(0)*factor
		newdata.dir(*,1) = newdata.dir(*,1) - thevel(1)*factor
		newdata.dir(*,2) = newdata.dir(*,2) - thevel(2)*factor
	endif else begin
		newdata.dir(*,0) = newdata.dir(*,0)
		newdata.dir(*,1) = newdata.dir(*,1)
		newdata.dir(*,2) = newdata.dir(*,2)
	endelse
endif




;**************NOW CONVERT TO THE DATA SET REQUIRED*****************
rot = cal_rot(bfield,thevel)

newdata.dir = newdata.dir#rot
if keyword_set(plotenergy) then factor=1. else factor = 1000.
vperp = (newdata.dir(*,1)^2 + newdata.dir(*,2)^2)^.5*newdata.dir(*,1)/abs(newdata.dir(*,1))/factor
vpara = newdata.dir(*,0)/factor
zdata = newdata.n

;******************NOW TO PLOT THE DATA********************

if not keyword_set(xrange) then begin
	themax = max(abs([vperp,vpara]))
	xrange = [-1*themax,themax]
endif else themax = max(abs(xrange))


if not keyword_set(range) then begin
	if not keyword_set(xrange) then begin	
		maximum = max(zdata)
		minimum = min(zdata(where(zdata ne 0)))
	endif else begin
		maximum = max(zdata(where(abs(vperp) le themax and abs(vpara) le themax)))
		minimum = min(zdata(where(zdata ne 0 and abs(vperp) le themax and abs(vpara) le themax)))
	endelse
endif else begin
	maximum = range(1)
	minimum = range(0)
endelse

x= findgen(resolution)/(resolution-1)*(xrange(1)-xrange(0)) + xrange(0)
spacing = (xrange(1)-xrange(0))/(resolution-1)
triangulate,vpara,vperp,tr,b
thesurf = trigrid(vpara,vperp,zdata,tr,[spacing,spacing], [xrange(0),xrange(0),xrange(1),xrange(1)],xgrid = xg,ygrid = yg )
if keyword_set(smooth) then thesurf = smooth(thesurf,3)
if n_elements(xg) mod 2 ne 1 then print,'problem with data: do not trust line plots'


n_elem = n_elements(thesurf(*,0))
theplots(j).time = thedata.time
theplots(j).x = xg
theplots(j).min = minimum
theplots(j).max = maximum
theplots(j).vparaplus = [reverse(thesurf(n_elem/2:*,n_elem/2)),thesurf(n_elem/2+1:*,n_elem/2)]
theplots(j).vparamin = [thesurf(0:n_elem/2,n_elem/2),reverse(thesurf(0:n_elem/2-1,n_elem/2))]
theplots(j).vperpplus = [reverse(reform(thesurf(n_elem/2,n_elem/2+1:*))),reform(thesurf(n_elem/2,n_elem/2:*))]
theplots(j).vperpmin = [reform(thesurf(n_elem/2,0:n_elem/2)),reverse(reform(thesurf(n_elem/2,0:n_elem/2-1)))]

endfor ;*************************************MAIN LOOP ENDS HERE************************************


if keyword_set(step) then begin
	if step ne 1 then factor = step else begin
		if not keyword_set(zlog) then step = (theplots(0).max-theplots(0).min)/n_elements(thetimes) else $
			factor = .1
	endelse
 
	for j = 0,n_elements(thetimes)-1 do begin
		if keyword_set(zlog) then begin
			theplots(j).min = theplots(j).min*(factor^j)
			theplots(j).max = theplots(j).max*(factor^j)
			theplots(j).vparaplus = theplots(j).vparaplus*(factor^j)
			theplots(j).vparamin = theplots(j).vparamin*(factor^j)
			theplots(j).vperpplus = theplots(j).vperpplus*(factor^j)
			theplots(j).vperpmin = theplots(j).vperpmin*(factor^j)
		endif else begin
			theplots(j).min = theplots(j).min-step
			theplots(j).max = theplots(j).max-step
			theplots(j).vparaplus = theplots(j).vparaplus-step
			theplots(j).vparamin = theplots(j).vparamin-step
			theplots(j).vperpplus = theplots(j).vperpplus-step
			theplots(j).vperpmin = theplots(j).vperpmin-step
		endelse
	endfor
endif

themin = min(theplots(*).min)
themax = max(theplots(*).max)

thetitle = thedata.units_name
if keyword_set(zlog) then thetitle = thetitle + ' (log)'

if keyword_set(plotenergy) then begin
	xtitle = 'Energy (eV)'
	vore = 'E'
endif else begin
	xtitle = 'Velocity (km/sec)'
	vore = 'V'
endelse

ncolors = n_elements(thetimes)*2.
thecolors = round((indgen(ncolors)+1)*(!d.table_size-9)/ncolors)+7


plot,[0,0],[0,0],/nodata,xstyle = 1,ystyle = 1,xrange = xrange,yrange = [themin,themax],ylog = zlog,$
		title = vore + ' perp (plus and minus)',xtitle = thedata.data_name + ': ' + xtitle, $
		ytitle = thetitle,position = position2;,color = thecolors(0)

;put a dotted line
oplot,[0,0],[themin,themax],linestyle = 1
;put erange and onecnt lines
if not keyword_set(plotenergy) then begin
	oplot,[sqrt(2.*1.6e-19*erange(0)/mass)/1000.,sqrt(2.*1.6e-19*erange(0)/mass)/1000.],[themin,themax],linestyle = 5
	oplot,-[sqrt(2.*1.6e-19*erange(0)/mass)/1000.,sqrt(2.*1.6e-19*erange(0)/mass)/1000.],[themin,themax],linestyle = 5
	oplot,[sqrt(2.*1.6e-19*erange(1)/mass)/1000.,sqrt(2.*1.6e-19*erange(1)/mass)/1000.],[themin,themax],linestyle = 5
	oplot,-[sqrt(2.*1.6e-19*erange(1)/mass)/1000.,sqrt(2.*1.6e-19*erange(1)/mass)/1000.],[themin,themax],linestyle = 5
	if keyword_set(onecnt) then begin
		they = [theonecnt.data(*,0),reverse(theonecnt.data(*,0))]
		thex = [sqrt(2.*1.6e-19*theonecnt.energy(*,0)/mass)/1000.,reverse(-sqrt(2.*1.6e-19*theonecnt.energy(*,0)/mass)/1000.)]
		oplot,thex,they,color = 6,linestyle = 3
		if keyword_set(step) then begin
			if keyword_set(zlog) then for j =1,n_elements(thetimes)-1 do oplot,thex,they*factor^j,color = 6,linestyle = 3 else $
				for j = 1,n_elements(thetimes) - 1 do oplot,thex,they-step*j,color = 6,linestyle=3
		endif
	endif
endif else begin
	oplot,[erange(0),erange(0)],[themin,themax],linestyle = 5
	oplot,-[erange(0),erange(0)],[themin,themax],linestyle = 5
	oplot,[erange(1),erange(1)],[themin,themax],linestyle = 5
	oplot,-[erange(1),erange(1)],[themin,themax],linestyle = 5
	if keyword_set(onecnt) then begin
		oplot,theonecnt.energy(*,0),theonecnt.data(*,0),color = 6,linestyle = 3
		oplot,-theonecnt.energy(*,0),theonecnt.data(*,0),color = 6,linestyle = 3
	endif
endelse

;oplot,theplots(0).x,theplots(0).vperpplus,color = thecolors(0)
;oplot,theplots(0).x,theplots(0).vperpmin,color = thecolors(0+ncolors/2-1)

for j=0,n_elements(thetimes)-1 do begin
	oplot,theplots(j).x,theplots(j).vperpplus,color = thecolors(j)
	oplot,theplots(j).x,theplots(j).vperpmin,color = thecolors(j+ncolors/2)
endfor


plot,[0,0],[0,0],/nodata,xstyle = 1,ystyle = 1,xrange = xrange,yrange = [themin,themax],ylog = zlog,$
		title = vore + ' para (plus and minus)',xtitle = thedata.data_name + ': ' + xtitle, $
		ytitle = thetitle,position = position

;put a dotted line
oplot,[0,0],[themin,themax],linestyle = 1
;put erange and onecnt lines
if not keyword_set(plotenergy) then begin
	oplot,[sqrt(2.*1.6e-19*erange(0)/mass)/1000.,sqrt(2.*1.6e-19*erange(0)/mass)/1000.],[themin,themax],linestyle = 5
	oplot,-[sqrt(2.*1.6e-19*erange(0)/mass)/1000.,sqrt(2.*1.6e-19*erange(0)/mass)/1000.],[themin,themax],linestyle = 5
	oplot,[sqrt(2.*1.6e-19*erange(1)/mass)/1000.,sqrt(2.*1.6e-19*erange(1)/mass)/1000.],[themin,themax],linestyle = 5
	oplot,-[sqrt(2.*1.6e-19*erange(1)/mass)/1000.,sqrt(2.*1.6e-19*erange(1)/mass)/1000.],[themin,themax],linestyle = 5
	if keyword_set(onecnt) then begin
		they = [theonecnt.data(*,0),reverse(theonecnt.data(*,0))]
		thex = [sqrt(2.*1.6e-19*theonecnt.energy(*,0)/mass)/1000.,reverse(-sqrt(2.*1.6e-19*theonecnt.energy(*,0)/mass)/1000.)]
		oplot,thex,they,color = 6,linestyle = 3
		if keyword_set(step) then begin
			if keyword_set(zlog) then for j =1,n_elements(thetimes)-1 do oplot,thex,they*factor^j,color = 6,linestyle = 3 else $
				for j = 1,n_elements(thetimes) - 1 do oplot,thex,they-step*j,color = 6,linestyle=3
		endif
	endif
endif else begin
	oplot,[erange(0),erange(0)],[themin,themax],linestyle = 5
	oplot,-[erange(0),erange(0)],[themin,themax],linestyle = 5
	oplot,[erange(1),erange(1)],[themin,themax],linestyle = 5
	oplot,-[erange(1),erange(1)],[themin,themax],linestyle = 5
	if keyword_set(onecnt) then begin
		oplot,theonecnt.energy(*,0),theonecnt.data(*,0),color = 6,linestyle = 3
		oplot,-theonecnt.energy(*,0),theonecnt.data(*,0),color = 6,linestyle = 3
	endif
endelse


;oplot,theplots(0).x,theplots(0).vparamin,color = thecolors(0+ncolors/2-1)

for j=0,n_elements(thetimes)-1 do begin
	oplot,theplots(j).x,theplots(j).vparaplus,color = thecolors(j)
	oplot,theplots(j).x,theplots(j).vparamin,color = thecolors(j+ncolors/2)
endfor


;*************************NOW PUT THE LABELS ON THE RIGHT SIDE OF THE PLOT*******************


;if keyword_set(var_label) then begin
;	;store_data,'some_times',data = {x:theplots(*).time}
;	;for i = 0,n_elements(var_label)-1 do interpolate,'some_times',var_label(i),var_label(i) + 'in'
;	outstring= strarr(n_elements(thetimes))

;	for j = 0,n_elements(thetimes)-1 do begin
;		store_data,'time',data = {x:theplots(j).time+thedata.integ_t*.5}
;		for i = 0,n_elements(var_label)-1 do begin
;			get_data,var_label(i),data = bdata
;			index = where(bdata.x le theplots(j).time +600 and bdata.x ge theplots(j).time-600,count)
;			if count ne 0 then begin
;				store_data,var_label(i)+'cut',data = {x:bdata.x(index),y:bdata.y(index,*)}
;				interpolate,'time',var_label(i)+'cut','value'
;				get_data,'value',data = thevalue
;				if i mod numperrow eq 0 then put_space = '!c' else put_space = ' '
;				outstring(j) = outstring(j) + put_space + var_label(i) +'= '+ strtrim(string(format = '(G11.4)',thevalue.y(0)),2)
;			endif
;		endfor
;	endfor
;endif else begin
;	outstring = strarr(n_elements(thetimes))
;	outstring(*) = ''
;endelse
	

if keyword_set(var_label) then begin
	store_data,'some_times',data = {x:theplots(*).time+thedata.integ_t*.5}
	for i = 0,n_elements(var_label)-1 do interpolate,'some_times',var_label(i),var_label(i) + 'in'
	outstring= strarr(n_elements(thetimes))



	for j = 0,n_elements(thetimes)-1 do begin
		;outstring(j) = '!c'
		for i = 0,n_elements(var_label)-1 do begin
			get_data,var_label(i) + 'in',data = thedata
			;atime = theplots(j).time + thedata.integ_t * 0.5
			index = j;  where(thedata.x eq atime) ;theplots(j).time+thedata.integ_t*.5)
			if i mod numperrow eq 0 then put_space = '!c' else put_space = ' '
			outstring(j) = outstring(j) + put_space + var_label(i) +'= '+ strtrim(string(format = '(G11.4)',thedata.y(index)),2)
		endfor
	endfor
endif else begin
	outstring = strarr(n_elements(thetimes))
	outstring(*) = ''
endelse
				

			



positions = -findgen(n_elements(thetimes)*2+1)*(position2(3)-position2(1))/(n_elements(thetimes)*2+1)+ position2(3)-.03

for j =0, n_elements(thetimes)-1 do begin
	if keyword_set(step) then begin
		if keyword_set(zlog) then add ='!c(factor of '+strtrim(string(format = '(F11.4)',factor^j),2)+')' else $
			add = '!c(step of '+strtrim(string(format = '(G11.4)',step*j),2) + ')'
	endif else add = ''
	xyouts,position2(2) + .03,positions(j*2),time_string(theplots(j).time) + ' plus'+add+outstring(j),color = thecolors(j),/norm
	xyouts,position2(2) + .03,positions(j*2+1),time_string(theplots(j).time) + ' minus'+add,color = thecolors(j + ncolors/2),/norm
endfor

if keyword_set(onecount) then xyouts,position2(2) + .03,positions(j*2),'One count',color = 6,/norm

positions = -findgen(n_elements(thetimes)*2+1)*(position(3)-position(1))/(n_elements(thetimes)*2+1)+ position(3)-.03

for j =0, n_elements(thetimes)-1 do begin
	if keyword_set(step) then begin
		if keyword_set(zlog) then add ='!c(factor of '+strtrim(string(format = '(F11.4)',factor^j),2)+')' else $
			add = '!c(step of '+strtrim(string(format = '(G11.4)',step*j),2) + ')'
	endif else add = ''
	xyouts,position(2) + .03,positions(j*2),time_string(theplots(j).time) + ' plus'+add+outstring(j),color = thecolors(j),/norm
	xyouts,position(2) + .03,positions(j*2+1),time_string(theplots(j).time) + ' minus'+add,color = thecolors(j + ncolors/2),/norm
endfor

if keyword_set(onecount) then xyouts,position(2) + .03,positions(j*2),'One count',color = 6,/norm







!p.multi = oldplot
gettimes = thetimes


end
