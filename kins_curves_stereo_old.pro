; OLD CODE!!! see newer kins_curves_secchi.pro


; Last Edited: 25-06-08

pro kins_curves_stereo, fit_vel=fit_vel

readcol, 'kins.txt', smj, smn, tilt, aw, hc, h, instr, date, time, h_err, delta_t, $
	tilt_err, mag_err, tile_err_deg, max_h_front, r_sun, f='F,F,F,F,F,F,A,A,A,F,F,F,F,F,F,F'
t = anytim(date+' '+time)
utbasedata = t[0]
t = anytim(t) - anytim(t[0])

; Hardcoding in the minimum error based upon Scale 5 (8-3) which has filter size 2^3=8pixels.
for k=0,n_elements(h_err)-1 do begin
	case instr[k] of
       'COR1': if h_err[k] lt 60 then h_err[k]=60
       'COR2': if h_err[k] lt 235.2 then h_err[k]=235.2
       endcase
endfor

; Because of occulter interference on the ellipse fit at low C2, check the error isn't larger than PIX_ERRS
;for k=0,n_elements(mag_err)-1 do begin
;	if (h_err[k] gt mag_err[k]) then h_err[k]=mag_err[k]
	;h_err[k]=mag_err[k]
;endfor

for i=0,4 do h[i] = max_h_front[i]
for i=12,15 do h[i] = max_h_front[i]

r_sun =  r_sun[0];arcsec
RSun = 6.96e8 ;metres
km_arc = RSun / (1000*r_sun) ; km per arcsec
h_km = h*km_arc
h_rsun = h_km*1000 / RSun
h_rsun_err = (h_err*km_arc / RSun)*1000
v = deriv(t, h)
a = deriv(t, v)
;using derivsig instead of this formula
;v_err = fltarr(n_elements(t))
;a_err = v_err
;for i=0,n_elements(t)-1 do begin
;	v_err[i] = v[i] * ( h_err[i]/h[i] + delta_t[i]/t[i] )
;	a_err[i] = a[i] * ( v_err[i]/v[i] + delta_t[i]/t[i] )
;endfor
v_err = derivsig(t,h,delta_t,h_err)
a_err = derivsig(t,v,delta_t,v_err)

if keyword_set(fit_vel) then begin
	yf = 'p[0]*x + p[1]'
	f = mpfitexpr(yf, t, v, v_err, [h[0],v[0],a[0]], perror=perror)
	h_model = (f[0]/2.)*t^2 + f[1]*t + f[2]+1.1*h[0]
	v_model = f[0]*t + f[1]
	a_model = f[0]
endif else begin
	yf = 'p[0]*x^2. + p[1]*x + p[2]'
	f = mpfitexpr(yf, t, h, h_err, [h[0],v[0],a[0]], perror=perror)
	h_model = f[0]*t^2 + f[1]*t + f[2]
	v_model = f[0]*t + f[1]
	a_model = f[0]
endelse
print, 'h[0] ', h[0]
	
;!p.multi=[0,1,2]
;plot, h_rsun, v*km_arc, psym=-2, linestyle=1, tit='Ellipse', xtit='Height (R_sun)', ytit='Velocity (km/sec)'
;oploterror, h_rsun, v*km_arc, fltarr(n_elements(h_rsun)), v_err*km_arc, psym=3
;plot, h_rsun, a*km_arc*1000, psym=-2, linestyle=1, xtit='Height (R_sun)', ytit='Acceleration (km/sec^2)'
;oploterror, h_rsun, a*km_arc*1000, fltarr(n_elements(h_rsun)), a_err*km_arc*1000, psym=3
;line0 = replicate(0, n_elements(t))
;outplot, t, line0, utbasedata, psym=-3, linestyle=2
;pause


;*********** Read in CDAW to compare / overplot.

readcol, 'kins_cdaw.txt', h_cdaw, date_cdaw, time_cdaw, angle_cdaw, f='F,A,A,F'

t_cdaw = anytim(date_cdaw+' '+time_cdaw)
t_cdaw = anytim(t_cdaw) - utbasedata

;v_cdaw = deriv(t_cdaw, h_cdaw*r_sun)
;a_cdaw = deriv(t_cdaw, v_cdaw)

;***********



!p.multi=[0,1,3]

xrs = 6200
xls = 3300

utplot, t, h_rsun, utbasedata, psym=3, linestyle=1, ytit='!6Height (R!D!9n!N!X)', $
	xr=[t[0]-xls,t[*]+xrs], yr=[1,16], /xs, /ys, /notit, /nolabel, $
	xtickname = [' ',' ',' ',' ',' ',' ',' '], $
	pos=[0.15,0.68,0.95,0.98];, ytickname=['0','5','10','15','20','25','30']
outplot, t, h_model/r_sun, utbasedata, psym=-3, linestyle=0
oploterror, t, h_rsun, delta_t, h_rsun_err, psym=3

;outplot, t_cdaw, h_cdaw, utbasedata, psym=-4, linestyle=2

;legend, ['CDAW', 'Multiscale', 'Model'], psym=[4,1,-3], charsize=1
legend, ['Multiscale', 'Model'], psym=[1,-3], charsize=1


utplot, t, v*km_arc, utbasedata, psym=3, linestyle=1, ytit='!6Velocity (km s!U-1!N)', $
	/notit, /nolabel, xtickname = [' ',' ',' ',' ',' ',' ',' '], xr=[t[0]-xls,t[*]+xrs], /xs, $
	yr=[-70,480], /ys, pos=[0.15,0.38,0.95,0.68];, ytickname=['-500','0','500','1000',' '] 
outplot, t, v_model*km_arc, utbasedata, psym=-3, linestyle=0
oploterror, t, v*km_arc, delta_t, v_err*km_arc, psym=3

;outplot, t_cdaw, v_cdaw*km_arc, utbasedata, psym=-4, line=2

utplot, t, a*km_arc*1000, utbasedata, psym=3, linestyle=1, /notit, ytit='!6Acceleration (m s!U-1!N s!U-1!N)', $
	xr=[t[0]-xls,t[*]+xrs], /xs, /ys, yr=[-260,230], pos=[0.15,0.08,0.95,0.38];, ytickname=['-600','-400','-200','0','200','400',' ']
a_model_array = replicate(a_model*km_arc*1000, n_elements(t))
outplot, t, a_model_array, utbasedata, psym=-3, linestyle=0
oploterror, t, a*km_arc*1000, delta_t, a_err*km_arc*1000, psym=3

;outplot, t_cdaw, a_cdaw*km_arc*1000, utbasedata, psym=-4, line=2

print, 'accel (model): ', a_model*km_arc*1000
print, 'perror: ', perror
print, perror[0]*km_arc*1000
print, perror[1]*km_arc
print, perror[2]/r_sun
print, 'h_model: ', h_model/r_sun
print, 'v_model: ', v_model*km_arc
print, 'a_model: ', a_model[0]*km_arc*1000

;outplot, t, line0, utbasedata, psym=-3, linestyle=2

end
