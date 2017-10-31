; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "../../radial_plots/radialAvg.ncl"

begin


out_type="pdf"

;config="newcyclone30x4_clubb_k10-0.3"
;k10=0.3
;cam5=False

plot_vickery=True
plot_blackadar=True
plot_log_ref=True
plot_10m=True
plot_K_ref=True

;if(cam5) then
;  config="newcyclone30x8_CAM5"
;end if

if(cam5) then
  filename = "/glade/scratch/zarzycki/cam5_work/CAM5-TC-test-VR/"+config+"/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"
  f2= "/glade/u/home/zarzycki/scratch/cam5_work/CAM5-TC-test-VR/"+config+"/camrun.cam.h3.2000-01-08-00000.nc_regrid.nc"
  kvmvar="UW_kvm"
  tkevar="TKE"
  lengthvar="UW_leng"
else
  ;filename = "/glade/scratch/zarzycki/cam5_work/clubb-TC-test-VR/"+config+"/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"
  ;f2= "/glade/u/home/zarzycki/scratch/cam5_work/clubb-TC-test-VR/"+config+"/camrun.cam.h3.2000-01-08-00000.nc_regrid.nc"
  filename = "/glade/scratch/zarzycki/QPC6.newcyclone_30_x4/run/"+config+"/QPC6.newcyclone_30_x4.cam.h1.0001-01-08-00000.nc_regrid.nc"
  f2= "/glade/scratch/zarzycki/QPC6.newcyclone_30_x4/run/"+config+"/QPC6.newcyclone_30_x4.cam.h3.0001-01-08-00000.nc_regrid.nc"
  kvmvar="KVM_CLUBB"
  tkevar="TKE_CLUBB"
  lengthvar="LSCALE_CLUBB"
end if

thefile = addfile(filename,"r")
tf2 = addfile(f2,"r")


stride = 1
topLev = 750.
botLev = 1050.
maxLat=0.
minLat=45.
timeStep=0

pi=3.14159

lat = thefile->lat({maxLat:minLat:stride})
lon = thefile->lon(::stride)
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"
fulllev = thefile->lev
print(lev)
print(fulllev)
toplevix = ind_nearest_coord (lev(0), fulllev, 0)
botlevix = ind_nearest_coord (lev((dimsizes(lev)-1)), fulllev, 0)

print(toplevix+" "+botlevix)

hyam=thefile->hyam(toplevix:botlevix)
hybm=thefile->hybm(toplevix:botlevix)
hyai=thefile->hyai(toplevix+1:botlevix+1)
hybi=thefile->hybi(toplevix+1:botlevix+1)
;P0=thefile->P0
P0=100000.
P0@units="hPa"

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

U = thefile->U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
V = thefile->V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
PS1 = thefile->PS(timeStep,{maxLat:minLat:stride},::stride)
T = thefile->T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
Q = thefile->Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
CLDLIQ = thefile->CLDLIQ(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)

KVM_CLUBB_int = tf2->$kvmvar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
if (.not.cam5) then
  KVM_CLUBB_int = KVM_CLUBB_int*k10
end if
KVM_CLUBB = hyi2hyo_Wrap(P0,hyai,hybi,PS1,KVM_CLUBB_int,hyam,hybm,1)

TKE_CLUBB_int = tf2->$tkevar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
TKE_CLUBB = hyi2hyo_Wrap(P0,hyai,hybi,PS1,TKE_CLUBB_int,hyam,hybm,1)

LSCALE_CLUBB_int = tf2->$lengthvar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
LSCALE_CLUBB = hyi2hyo_Wrap(P0,hyai,hybi,PS1,LSCALE_CLUBB_int,hyam,hybm,1)

CME = tf2->CME(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)

DTCOND = tf2->DTCOND(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)


PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)

THETA=pot_temp(PRES,T,-1,False)

CLDLIQ = CLDLIQ*1000.

; CME is kg/kg/s
CME = CME * 1000. * 86400.  ; g/kg/d

DTCOND = DTCOND * 86400. ; K/d

W = omega_to_w(OMEGA, PRES, T)         ; w (m/s)

;---FIND LOCATIONS OF PSMIN and WINDMAX
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
a_indices  = ind_resolve(minind(a1D),dsizes_a)
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))

; calculate radial stuff
vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon,0,0)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

; get Z from hybrid levels
TV=T*(1.+0.61*Q) 
PHIS=PS1
PHIS=0.0
Z = cz2ccm(PS1,PHIS,TV,P0,hyam(::-1),hybm(::-1),hyai(::-1),hybi(::-1))
Z@units="m"

; generate Zlev
Zlev = fspan(10.,3000.,250)
;Zlev = (/50.,100.,150.,200.,250.,300.,350.500.,750.,1000.,2000.,3000.,4000.,5000.,10000./)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

printVarSummary(W)
printVarSummary(KVM_CLUBB)

print(Z)

interp_type=1
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
W_Z        = int2p_n_Wrap(Z,W,Zlev,interp_type,0)
KVM_Z      = int2p_n_Wrap(Z,KVM_CLUBB,Zlev,interp_type,0)  
TKE_Z      = int2p_n_Wrap(Z,TKE_CLUBB,Zlev,interp_type,0)  
LSCALE_Z      = int2p_n_Wrap(Z,LSCALE_CLUBB,Zlev,interp_type,0)  
THETA_Z      = int2p_n_Wrap(Z,THETA,Zlev,interp_type,0)  
T_Z      = int2p_n_Wrap(Z,T,Zlev,interp_type,0)  
Q_Z      = int2p_n_Wrap(Z,Q,Zlev,interp_type,0)  
CLDLIQ_Z      = int2p_n_Wrap(Z,CLDLIQ,Zlev,interp_type,0)  
CME_Z      = int2p_n_Wrap(Z,CME,Zlev,interp_type,0)  
DTCOND_Z      = int2p_n_Wrap(Z,DTCOND,Zlev,interp_type,0)  

; do radial integrals
rad_v_theta  = radialAvg3D(v_theta_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad    = radialAvg3D(v_rad_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad = -rad_v_rad  ; NEGATIVE FOR CONVENTION
rad_W        = radialAvg3D(W_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_KVM      = radialAvg3D(KVM_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_TKE      = radialAvg3D(TKE_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_LSCALE      = radialAvg3D(LSCALE_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_THETA      = radialAvg3D(THETA_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_T      = radialAvg3D(T_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_Q      = radialAvg3D(Q_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_CLDLIQ      = radialAvg3D(CLDLIQ_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_CME      = radialAvg3D(CME_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_DTCOND      = radialAvg3D(DTCOND_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)

rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
nrad_rad=rad_dims(1)

; Calculate derived rad quantities

L_v = 2264.76*1000.    ; J/kg
c_p = 1005.7 ; J/kg/K
g = 9.81
; q is kg/kg, 
rad_MSE = rad_T
rad_MSE = c_p * rad_T + g * conform(rad_MSE,Zlev,0) + L_v * rad_Q
print(max(rad_MSE))
print(min(rad_MSE))

; find RMW
rad_sfc_v_theta=rad_v_theta({70.},:)
inds = maxind(rad_sfc_v_theta)
rad_max = rad_sfc_v_theta&radius(inds)   ; insert the longitude index into the lon coordinate variable
print("Maximum value located at, "+rad_max)
rad_max_2x = rad_max*2

rad_v_theta_vert=new((/2,nlev_rad/),"float")
rad_v_theta_vert!1 = "lev"
rad_v_theta_vert&lev = rad_v_theta&lev

rad_v_rad_vert = rad_v_theta_vert
rad_W_vert     = rad_v_theta_vert
rad_KVM_vert   = rad_v_theta_vert
rad_TKE_vert   = rad_v_theta_vert
rad_LSCALE_vert   = rad_v_theta_vert
rad_THETA_vert   = rad_v_theta_vert
rad_T_vert   = rad_v_theta_vert
rad_Q_vert   = rad_v_theta_vert
rad_CLDLIQ_vert   = rad_v_theta_vert
rad_MSE_vert   = rad_v_theta_vert
rad_CME_vert   = rad_v_theta_vert
rad_DTCOND_vert   = rad_v_theta_vert


rad_v_theta_vert(0,:) = tofloat(rad_v_theta(:,{rad_max}))
rad_v_rad_vert(0,:) = tofloat(rad_v_rad(:,{rad_max}))
rad_W_vert(0,:) = tofloat(rad_W(:,{rad_max}))
rad_KVM_vert(0,:) = tofloat(rad_KVM(:,{rad_max}))
rad_TKE_vert(0,:) = tofloat(rad_TKE(:,{rad_max}))
rad_LSCALE_vert(0,:) = tofloat(rad_LSCALE(:,{rad_max}))
rad_THETA_vert(0,:) = tofloat(rad_THETA(:,{rad_max}))
rad_T_vert(0,:) = tofloat(rad_T(:,{rad_max}))
rad_Q_vert(0,:) = tofloat(rad_Q(:,{rad_max}))
rad_CLDLIQ_vert(0,:) = tofloat(rad_CLDLIQ(:,{rad_max}))
rad_MSE_vert(0,:) = tofloat(rad_MSE(:,{rad_max}))
rad_CME_vert(0,:) = tofloat(rad_CME(:,{rad_max}))
rad_DTCOND_vert(0,:) = tofloat(rad_DTCOND(:,{rad_max}))

rad_v_theta_vert(1,:) = tofloat(rad_v_theta(:,{rad_max_2x}))
rad_v_rad_vert(1,:) = tofloat(rad_v_rad(:,{rad_max_2x}))
rad_W_vert(1,:) = tofloat(rad_W(:,{rad_max_2x}))
rad_KVM_vert(1,:) = tofloat(rad_KVM(:,{rad_max_2x}))
rad_TKE_vert(1,:) = tofloat(rad_TKE(:,{rad_max_2x}))
rad_LSCALE_vert(1,:) = tofloat(rad_LSCALE(:,{rad_max_2x}))
rad_THETA_vert(1,:) = tofloat(rad_THETA(:,{rad_max_2x}))
rad_T_vert(1,:) = tofloat(rad_T(:,{rad_max_2x}))
rad_Q_vert(1,:) = tofloat(rad_Q(:,{rad_max_2x}))
rad_CLDLIQ_vert(1,:) = tofloat(rad_CLDLIQ(:,{rad_max_2x}))
rad_MSE_vert(1,:) = tofloat(rad_MSE(:,{rad_max_2x}))
rad_CME_vert(1,:) = tofloat(rad_CME(:,{rad_max_2x}))
rad_DTCOND_vert(1,:) = tofloat(rad_DTCOND(:,{rad_max_2x}))

; find surface inflow angle
do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(0,ii))) then
    sfc_inflow_ang=atan(rad_v_rad_vert(0,ii)/rad_v_theta_vert(0,ii))*180./pi
    sfc_radial_flow=abs(rad_v_rad_vert(1,ii))
    break
  else
    print("Missing value in search for lowest model level...")
  end if
end do

do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(1,ii))) then
    if (abs(rad_v_rad_vert(1,ii)) .ge. 0.1*sfc_radial_flow) then
      print("Searing for inflow depth -- at z: "+Zlev(ii)+" "+rad_v_rad_vert(1,ii)+" compared to: "+(0.1*sfc_radial_flow))
      inflow_depth=Zlev(ii)
    else
      print("Breaking -- at z: "+Zlev(ii)+" "+rad_v_rad_vert(1,ii)+" compared to: "+(0.1*sfc_radial_flow))
      break
    end if
  else
    print("Missing value in search for inflow depth...")
  end if
end do

print("-------------------------------------------------------------------")
print("surface inflow angle: "+abs(sfc_inflow_ang))
print("inflow depth: "+inflow_depth+" "+Zlev@units)
print("-------------------------------------------------------------------")

; LOAD DATA

if (plot_vickery)
  txtdata = "txtdata/vickery2009.csv"
  dlines = asciiread(txtdata,-1,"string")
  delim = ","
  dwind  = tofloat(str_get_field(dlines,1,delim))
  dhgt   = tofloat(str_get_field(dlines,2,delim))
  data1x=dwind(0:35)
  data1y=dhgt(0:35)
  data2x=dwind(36:71)
  data2y=dhgt(36:71)
  data3x=dwind(72:117)
  data3y=dhgt(72:117)
  data4x=dwind(118:159)
  data4y=dhgt(118:159)
  data5x=dwind(160:205)
  data5y=dhgt(160:205)
  data6x=dwind(206:248)
  data6y=dhgt(206:248)
end if

if(plot_blackadar)
  vonKar=0.4  ; vonKarman
  linf = 80.0
  blackadar = (vonKar*Zlev)^(-1.0) + linf^(-1.0)
  blackadar = blackadar^(-1.0)
end if

if(plot_10m)
  factor = surfaceWindCorrFactor(70.0,-1,"log")
  U10=factor*rad_v_theta_vert(0,{70.0})
  print(U10)
  print(rad_v_theta_vert(0,{70.0}))
end if

if(plot_log_ref)
  USTAR = tf2->USTAR(timeStep,{maxLat:minLat:stride},::stride)
  rad_ustar = radialAvg2D(USTAR,lat,lon,psminlat,psminlon,500.,True)
  ustar_rmw = tofloat(rad_ustar({rad_max}))

  log_wind_profile = tofloat(rad_v_rad_vert(0,:))

  K = 0.4
  c4=0.0027
  c5=0.000142
  c6=0.0000764
  ;z_0 = 10 * exp( -K * (c4/U10 + c5 + c6*U10)^(-1) )
  ;print(z_0)
  z_0 = 0.015*ustar_rmw*ustar_rmw/9.81
  print(z_0)
  ;z_0=0.0002

  ;z_0 = 0.0002
  ;cdn = .0027/U10 + .000142 + .0000764 U10

  do ii = 0,dimsizes(log_wind_profile)-1
    log_wind_profile(ii) = ustar_rmw/K * log(Zlev(ii)/z_0)
  end do
  ;print(log_wind_profile+" "+Zlev)

  z_0=0.0002
  do ii = 0,dimsizes(log_wind_profile)-1
    log_wind_profile(ii) = rad_v_theta_vert(0,{70.0})*(1 + log(Zlev(ii)/70.0)/log(70.0/z_0) )
  end do

  k_profile = tofloat(rad_KVM_vert(0,:))
  
  print("ustar_rmw "+ustar_rmw)
  do ii = 0,dimsizes(k_profile)-1
    k_profile(ii) = K*ustar_rmw*Zlev(ii)
  end do

  print(k_profile+" "+Zlev)

end if

; PLOTTING



wks   = gsn_open_wks (out_type,"panel_"+config)
npanels=12
plot = new(npanels,"graphic")

; universal settings
res= True       
res@gsnDraw = False
res@gsnFrame = False
res@trYMinF           = 10.
res@trYMaxF           = 2800.

;res@xyMarkLineMode = "MarkLines"

res@tiMainString  = "Radial Flow"
res@tiXAxisString = "V_rad (m/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = -25.
res@trXMaxF           = 10.
plot(0) = gsn_csm_xy (wks,rad_v_rad_vert(:,:),Zlev(:),res)
zlineres = True
zlineres@gsLineColor = "gray"
zlineres@gsLineThicknessF = 1.0
dummy_vert = gsn_add_polyline(wks,plot(0),(/0,0/),(/1,100000/),zlineres)

; add inflow depth annotation
txres                       = True
txres@txFontHeightF         = 0.02
txid = gsn_create_text(wks, "inflow depth: "+inflow_depth+Zlev@units, txres)
amres = True
amres@amParallelPosF   = -0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = -0.48    ; This is the bottom edge of the plot.
amres@amJust           = "TopLeft"
annoid = gsn_add_annotation(plot(0), txid, amres)

; add inflow angle annotation
txres                       = True
txres@txFontHeightF         = 0.02
txid = gsn_create_text(wks, "sfc inflow ang: "+abs(sfc_inflow_ang)+"deg", txres)
amres = True
amres@amParallelPosF   = 0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = 0.48    ; This is the bottom edge of the plot.
amres@amJust           = "BottomRight"
annoid = gsn_add_annotation(plot(0), txid, amres)





if(0.eq.0) then
res@tiMainString  = "Azimuthal Flow"
res@tiXAxisString = "V_theta (m/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 20.
res@trXMaxF           = 80.
plot(1) = gsn_csm_xy (wks,rad_v_theta_vert(:,:),Zlev(:),res)

; add RMW annotation
txres                       = True
txres@txFontHeightF         = 0.02
txid = gsn_create_text(wks, "RMW: "+rad_max+"km", txres)
amres = True
amres@amParallelPosF   = -0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = -0.48    ; This is the bottom edge of the plot.
amres@amJust           = "TopLeft"
annoid = gsn_add_annotation(plot(1), txid, amres)



if (plot_vickery)
  resover=True
  resover=res
  resover@xyLineColor="red"
  ;plot11 = gsn_csm_xy (wks,data1x,data1y,resover)
  ;overlay(plot(1),plot11)
  ;plot21 = gsn_csm_xy (wks,data2x,data2y,resover)
  ;overlay(plot(1),plot21)
  plot31 = gsn_csm_xy (wks,data3x,data3y,resover)
  overlay(plot(1),plot31)
  plot41 = gsn_csm_xy (wks,data4x,data4y,resover)
  overlay(plot(1),plot41)
  plot51 = gsn_csm_xy (wks,data5x,data5y,resover)
  overlay(plot(1),plot51)
  plot61 = gsn_csm_xy (wks,data6x,data6y,resover)
  overlay(plot(1),plot61)
  delete(resover)
end if

if (plot_log_ref)
  resover=True
  resover=res
  resover@xyLineColor="blue"
  plot19 = gsn_csm_xy (wks,log_wind_profile,Zlev,resover) ; create plot
  overlay(plot(1),plot19)
  delete(resover)
end if

res@tiMainString  = "Vertical Flow"
res@tiXAxisString = "W (m/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 0.6
plot(2) = gsn_csm_xy (wks,rad_W_vert(:,:),Zlev(:),res)

res@tiMainString  = "Diffusivity"
res@tiXAxisString = "Km (m2/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 300.
plot(3) = gsn_csm_xy (wks,rad_KVM_vert(:,:),Zlev(:),res)

if (plot_K_ref)
  resover=True
  resover=res
  resover@xyLineColor="blue"
  plot39 = gsn_csm_xy (wks,k_profile,Zlev,resover) ; create plot
  overlay(plot(3),plot39)
  delete(resover)
end if

res@tiMainString  = "TKE"
res@tiXAxisString = "TKE (m2/s2)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 25.
plot(4) = gsn_csm_xy (wks,rad_TKE_vert(:,:),Zlev(:),res)

res@tiMainString  = "Turb. length scale"
res@tiXAxisString = "lscale (m)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 1000.
plot(5) = gsn_csm_xy (wks,rad_LSCALE_vert(:,:),Zlev(:),res)

if (plot_blackadar)
  resover=True
  resover=res
  resover@xyLineColor="red"
  plot510 = gsn_csm_xy (wks,blackadar,Zlev,resover)
  overlay(plot(5),plot510)
  delete(resover)
end if

end if
;
;res@tiMainString  = "Pot. Temp."
;res@tiXAxisString = "Theta (K)"
;res@tiYAxisString = "Height (m)"
;res@xyYStyle          = "Log"
;res@trXMinF           = 300.
;res@trXMaxF           = 320.
;plot(6) = gsn_csm_xy (wks,rad_THETA_vert(:,:),Zlev(:),res)

res@tiMainString  = "DTCOND"
res@tiXAxisString = "DTCOND (K/d)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = -180.
res@trXMaxF           = 200.
plot(6) = gsn_csm_xy (wks,rad_DTCOND_vert(:,:),Zlev(:),res)

res@tiMainString  = "T"
res@tiXAxisString = "Temp (K)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 285.
res@trXMaxF           = 305.
plot(7) = gsn_csm_xy (wks,rad_T_vert(:,:),Zlev(:),res)

pmres=True
dum7 = gsn_add_polymarker(wks, plot(7), 302.15, 15.0, pmres)

;302.15

res@tiMainString  = "Q"
res@tiXAxisString = "Q (K)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.011
res@trXMaxF           = 0.025
plot(8) = gsn_csm_xy (wks,rad_Q_vert(:,:),Zlev(:),res)

res@tiMainString  = "CLDLIQ"
res@tiXAxisString = "CLDLIQ (g/kg)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 0.004
plot(9) = gsn_csm_xy (wks,rad_CLDLIQ_vert(:,:),Zlev(:),res)


res@tiMainString  = "MSE"
res@tiXAxisString = "MSE (J/kg)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 330000.
res@trXMaxF           = 360000.
plot(10) = gsn_csm_xy (wks,rad_MSE_vert(:,:),Zlev(:),res)


res@tiMainString  = "CME"
res@tiXAxisString = "CME (g/kg/day)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = -5.
res@trXMaxF           = 65.
plot(11) = gsn_csm_xy (wks,rad_CME_vert(:,:),Zlev(:),res)

resP = True
resP@txString = config

;resP@amJust           = "TopLeft"
;resP@gsnPanelFigureStringsFontHeightF = 0.014
;resP@gsnPanelFigureStrings= (/"T12","G16","T12-G16"/)

gsn_panel(wks,plot,(/4,3/),resP)
delete(res)
delete(resP)

wks2   = gsn_open_wks (out_type,"panel2_"+config)
npanels=4
plot2 = new(npanels,"graphic")
;plot3 = new(npanels,"graphic")

res= True       
res@gsnDraw = False
res@gsnFrame = False
res@trYMinF           = 10.
res@trYMaxF           = 2000.
res@trXMinF           = 0.
res@trXMaxF           = 400.

;res@cnFillOn            = True          ; turn on color
;res@cnFillPalette       = "gui_default" ; set color map

;res@mpShapeMode = "FreeAspect"
res@vpWidthF = 0.9
res@vpHeightF = 0.3

;res@tiMainString  = "Radial Flow"
;res@tiXAxisString = "V_rad (m/s)"
;res@tiYAxisString = "Height (m)"

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnLineThicknessF = 1. 
res@cnMinLevelValF  = -100.			; set the minimum contour level
res@cnMaxLevelValF  = 100.			; set the maximum contour level
res@cnLevelSpacingF = 1.			; set the interval between contours
plot2(0) = gsn_csm_contour(wks2,rad_v_rad,res)       ; contour the variable
res@cnLineThicknessF = 3.
res@cnLevelSpacingF = 10.
plot3 = gsn_csm_contour(wks2,rad_v_rad,res)
overlay(plot2(0),plot3)
delete(plot3)

res@cnLineThicknessF = 1. 
res@cnMinLevelValF  = -100.			; set the minimum contour level
res@cnMaxLevelValF  = 100.			; set the maximum contour level
res@cnLevelSpacingF = 2.			; set the interval between contours
plot2(1) = gsn_csm_contour(wks2,rad_v_theta,res)       ; contour the variable
res@cnLineThicknessF = 3.
res@cnLevelSpacingF = 10.
plot3 = gsn_csm_contour(wks2,rad_v_theta,res)
overlay(plot2(1),plot3)
delete(plot3)

res@cnLineThicknessF = 1. 
res@cnMinLevelValF  = -2.			; set the minimum contour level
res@cnMaxLevelValF  = 2.			; set the maximum contour level
res@cnLevelSpacingF = 0.1			; set the interval between contours
plot2(2) = gsn_csm_contour(wks2,rad_W,res)       ; contour the variable
res@cnLineThicknessF = 3.
res@cnLevelSpacingF = 2.
plot3 = gsn_csm_contour(wks2,rad_W,res)
overlay(plot2(2),plot3)
delete(plot3)

res@cnLineThicknessF = 1. 
res@cnMinLevelValF  = 0.			; set the minimum contour level
res@cnMaxLevelValF  = 500.			; set the maximum contour level
res@cnLevelSpacingF = 5.			; set the interval between contours
plot2(3) = gsn_csm_contour(wks2,rad_KVM,res)       ; contour the variable
res@cnLineThicknessF = 3.
res@cnLevelSpacingF = 20.
plot3 = gsn_csm_contour(wks2,rad_KVM,res)
overlay(plot2(3),plot3)
delete(plot3)




resP = True
resP@txString = config
gsn_panel(wks2,plot2,(/4,1/),resP)


end
