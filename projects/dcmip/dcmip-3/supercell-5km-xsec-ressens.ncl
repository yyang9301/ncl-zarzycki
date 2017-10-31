;***********************************************
; plot_supercell_5km_xsec.ncl
;
; Version 1.0
;***********************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

;****************************************************************************
; DO NOT EDIT ABOVE THIS LINE
;****************************************************************************
; Read in data and store as follows:
;
;   Output:
;     w_5km(time, lon, lat)
;     2D vertical velocity field at 5km altitude (units m/s)
;
;   Output:
;     qr_5km(time, lon, lat)
;     2D rain water mixing ratio at 5km altitude (units g/kg)
;
;   Dimensions:
;     time:  4 elements at 30, 60, 90 and 120 minutes
;     lon:   arbitrary
;     lat:   arbitrary
;----------------------------------------------------------------------------

;model="ACME"
resols=(/"r400","r200","r100","r50"/)
out_type="pdf"

;------------------------------------------------
; Workspace
;------------------------------------------------
  wks = gsn_open_wks(out_type,"pdfs/5km.ressens."+model)   

  gsn_merge_colormaps(wks,"temp_diff_18lev","sunshine_9lev")

;------------------------------------------------
; Plot resources [options]
;------------------------------------------------
  plot = new(2,graphic)
  wplot = new(3,graphic)
  qrplot = new(3,graphic)

do ii = 0,dimsizes(resols)-1
resol=resols(ii)

if (model .eq. "CSU_LZ" .or. model .eq. "CSU_CP") then
  if (resol .eq. "r50") then
    resol = "r050"
  end if
end if

if (model .eq. "TEMPEST") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/tempest/publish/tempest.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/tempest/publish/tempest.163."+resol+".L40.interp_latlon.nonhydro.Qr.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->W((/6,12,18,24/),{5000.},:,:)
  qr_5km = qr_data->Qr((/6,12,18,24/),{5000.},:,:)
end if

if (model .eq. "FVM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon.QR.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  ; CMZ -- still need to interpolate since 5000 falls between two levels in output
  lev=w_data->lev(:)
  print(lev)   ;5000 is the 10th index
  w_5km = w_data->W((/6,12,18,24/),10,:,:)
  qr_5km = qr_data->QR((/6,12,18,24/),10,:,:)
end if

if (model .eq. "MPAS") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  lev=w_data->Z(:,0,0)
  print(lev)   ;5000 is the 10th index
  w_5km = w_data->W((/6,12,18,24/),10,:,:)
  qr_5km = qr_data->QR((/6,12,18,24/),10,:,:)
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)
end if

if (model .eq. "GEM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.w.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.qr.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")

  ; CMZ -- need to interp to Z surfaces
  w_pres = w_data->W((/6,12,18,24/),:,:,:)
  qr_pres = qr_data->Qr((/6,12,18,24/),:,:,:)

  q_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.q.nc"
  t_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.t.nc"
  ps_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.ps.nc" 
  ps_data = addfile(ps_data_file,"r")
  q_data = addfile(q_data_file,"r")
  t_data = addfile(t_data_file,"r")
  ps1 = ps_data->PS((/6,12,18,24/),:,:)
  t_pres = t_data->T((/6,12,18,24/),:,:,:)
  q_pres = q_data->Q((/6,12,18,24/),:,:,:)
  lat=w_data->lat
  lon=w_data->lon
  hyai=w_data->hyai
  hybi=w_data->hybi
  hyam=w_data->hyam
  hybm=w_data->hybm
  P0=w_data->P0
  ps_P0 = ps1
  ps_P0 = 100000.
  ilev = exp(hyai + hybi*log(100000./P0))
  print(ilev)

  TV=t_pres*(1.+0.61*(q_pres))
  PHIS=ps1
  PHIS=0.0

  pres_m=w_pres
  pres_m=0.0
  Z_m=w_pres
  Z_m=0.0
  printVarSummary(pres_m)

  do tt=0,3
    do kk = 0,dimsizes(lat)-1
      do jj = 0,dimsizes(lon)-1
        pres_m(tt,:,kk,jj)=tofloat(exp(hyai + hybi*log(ps1(tt,kk,jj)/P0)))
        Z_m(tt,:,kk,jj)=hydro(pres_m(tt,::-1,kk,jj),TV(tt,::-1,kk,jj),0.0)
      end do
    end do
  end do

  print(Z_m(0,:,0,0)+" "+pres_m(0,:,0,0))

  Z_m@units="m"
  Zlev = (/5000./)
  Zlev@units = "m"
  Zlev!0     = "Zlev"
  Zlev&Zlev = Zlev
  ;print(Z(0,:,0,0))

  interp_type=1
  w_5km_int  = int2p_n_Wrap(Z_m,w_pres(:,::-1,:,:),Zlev,interp_type,1)
  qr_5km_int = int2p_n_Wrap(Z_m,qr_pres(:,::-1,:,:),Zlev,interp_type,1)
  printVarSummary(w_5km_int)


  ;w_5km  =  w_pres(:,{500.0},:,:)
  ;qr_5km = qr_pres(:,{500.0},:,:)
  w_5km  =  w_5km_int(:,{5000.0},:,:)
  qr_5km = qr_5km_int(:,{5000.0},:,:)

  delete(w_5km_int)
  delete(qr_5km_int)
  delete(Zlev)
  delete(Z_m)
  delete(w_pres)
  delete(w_data)
  delete(qr_data)
  delete(qr_pres)
  delete([/lat,lon,ps1,t_pres,q_pres,hyai,hybi,hyam,hybm,P0,ps_P0,ilev,TV,PHIS,pres_m/])
end if

if (model .eq. "FV3") then
  if (resol .eq. "r400") then
    resolkm="4km"
  else if (resol .eq. "r200") then
    resolkm="2km"
  else if (resol .eq. "r100") then
    resolkm="1km"
  else if (resol .eq. "r50") then
    resolkm="0.5km"
  else
    print("incorrect resol value")
    exit
  end if
  end if
  end if
  end if
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/publish/release_v1.2_DCMIP/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+".w5km.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/publish/release_v1.2_DCMIP/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+".rain5km.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->w5km((/5,11,17,23/),:,:)
  qr_5km = qr_data->rain5km((/5,11,17,23/),:,:)
end if

if (model .eq. "ACME") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro.Qr.nc"
  z_data_file =  "/glade/p/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro.Geopotential.nc"

  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?

  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  z_data = addfile(z_data_file,"r")

  w = w_data->W((/6,12,18,24/),::-1,:,:)
  qr = qr_data->Q3((/6,12,18,24/),::-1,:,:)
  z = z_data->geo((/6,12,18,24/),::-1,:,:)/9.80616

  w_interp = linint1_n_Wrap(z,w, False,5000.0,0,1)
  w_5km    = w_interp(:,0,:,:)

  qr_interp= linint1_n_Wrap(z,qr,False,5000.0,0,1)
  qr_5km   = qr_interp(:,0,:,:)
end if

if (model .eq. "CSU_CP") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_CP/csu.163."+resol+".L40.interp_latlon.nonhydro.CP_default.W5.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_CP/csu.163."+resol+".L40.interp_latlon.nonhydro.CP_default.QR5.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->W5((/6,12,18,24/),:,:)
  qr_5km = qr_data->QR5((/6,12,18,24/),:,:)
end if

if (model .eq. "CSU_LZ") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_LZ/csu.163."+resol+".L40.interp_latlon.nonhydro.LZ_default.W5.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_LZ/csu.163."+resol+".L40.interp_latlon.nonhydro.LZ_default.QR5.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->W5((/6,12,18,24/),:,:)
  qr_5km = qr_data->QR5((/6,12,18,24/),:,:)
end if

if (model .eq. "NICAM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro.Qr.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")

  w_full=w_data->W((/6,12,18,24/),:,:,:)
  qr_full=qr_data->Qr((/6,12,18,24/),:,:,:)

  ; Direct indexing (preinterpolation for AGU, etc.)
  ;w_5km = w_data->W((/6,12,18,24/),{5000.},:,:)
  ;qr_5km = qr_data->Qr((/6,12,18,24/),{5000.},:,:)

  ; Straight linear interpolation to test int2p_n_Wrap use with Z/linear
  ;w_5km_meta = w_data->W((/6,12,18,24/),{5000.},:,:)
  ;qr_5km_meta = qr_data->Qr((/6,12,18,24/),{5000.},:,:)
  ;lev (9)	4750
  ;lev (10)	5250
  ;w_5km=(w_full(:,9,:,:)+w_full(:,10,:,:)) / 2.
  ;qr_5km=(qr_full(:,9,:,:)+qr_full(:,10,:,:)) / 2.
  ;copy_VarMeta(w_5km_meta,w_5km)
  ;copy_VarMeta(qr_5km_meta,qr_5km)

  ; Vertically interpolate levels to 5km
  Z_m = w_full&lev
  Z_m@units="m"
  print(Z_m)
  Zlev = (/5000./)
  Zlev@units = "m"
  Zlev!0     = "Zlev"
  Zlev&Zlev = Zlev
  interp_type=1
  w_5km_int  = int2p_n_Wrap(Z_m,w_full,Zlev,interp_type,1)
  qr_5km_int = int2p_n_Wrap(Z_m,qr_full,Zlev,interp_type,1)
  w_5km=w_5km_int(:,{5000.},:,:)
  qr_5km=qr_5km_int(:,{5000.},:,:)
  
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)

  delete(w_full)
  delete(qr_full)
  delete(Z_m)
  delete(Zlev)
  delete(w_5km_int)
  delete(qr_5km_int)
end if

if (model .eq. "ICON") then
  if (resol .eq. "r400") then
    timestep="300"
  else if (resol .eq. "r200") then
    timestep="300"
  else if (resol .eq. "r100") then
    timestep="240"
  else if (resol .eq. "r50") then
    timestep="120"
  else
    print("incorrect resol value")
    exit
  end if
  end if
  end if
  end if
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.Qr.nc"
  correctLon=False
  conv_qr_units=False ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w = w_data->W((/6,12,18,24/),:,:,:)
  qr = qr_data->Qr((/6,12,18,24/),:,:,:)
  z_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.Z.nc"
  z_data = addfile(z_data_file,"r")
  zmid = z_data->Z(:,0,0)
  zint = new(dimsizes(zmid)+1,"float")
  zint(1:dimsizes(zmid))=zmid-250.
  zint(0) = 30000.0
  w&ilev=zint
  w_5km = w(:,{5000.0},:,:)
  qr_5km = w(:,{5000.0},:,:)
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)
end if

if (model .eq. "DYNAMICO") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.Qr.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w = w_data->W((/5,11,17,23/),:,:,:)
  qr = qr_data->Qr((/5,11,17,23/),:,:,:)

  ; get pressure levels
  ps_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.PS.nc"
  ps_data=addfile(ps_data_file,"r")
  ps = ps_data->PS((/5,11,17,23/),:,:)
  hyai_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hyai.nc"
  hybi_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hybi.nc"
  hyam_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hyam.nc"
  hybm_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hybm.nc"
  hyai_data=addfile(hyai_data_file,"r")
  hybi_data=addfile(hybi_data_file,"r")
  hyam_data=addfile(hyam_data_file,"r")
  hybm_data=addfile(hybm_data_file,"r")
  hyai = hyai_data->hyai
  hybi = hybi_data->hybi
  hyam = hyam_data->hyam
  hybm = hybm_data->hybm
;p $ _{(i,j,k) }$= A$ _{k}$P$ _{0}$+ B$ _{k}$P$ _{s}$(i,j)

;p(i,j,k)=hya(k)*P0+hyb(k)*PS(i,j) where P0=1000hPa
  exit
end if


;****************************************************************************
; DO NOT EDIT BELOW THIS LINE
;****************************************************************************

if (conv_qr_units) then
  qr_5km = qr_5km*1000.
end if



if (correctLon) then
  loncorr=180.0
else
  loncorr=0.0
end if

; Resources:
  res                     = True

  res@gsnDraw             = False
  res@gsnFrame            = False

  res@vpKeepAspect        = True
  res@vpWidthF            = 0.3
  res@vpHeightF           = 0.6
  res@gsnSpreadColors     = True
;  res@gsnMaximize         = True
  res@gsnPaperOrientation = "landscape"

  res@cnFillOn          = True
  res@cnLinesOn         = True
  res@cnLineLabelsOn    = False
  res@lbLabelAutoStride = True
  res@cnInfoLabelOn     = False
  res@tmXBLabelsOn      = True
  res@tmXBOn            = True

  res@tmXTLabelsOn      = False
  res@tmXTOn            = False

  res@gsnSpreadColors = True

  res@lbOrientation = "vertical"
  res@gsnLeftString=""
  res@gsnRightString=""

  res@trYMinF = -45.0
  res@trYMaxF =  45.0

  res@gsnContourZeroLineThicknessF = 0.0
  res@gsnContourNegLineDashPattern = 1

;  res@lbLabelBarOn = False
  res@tmYLLabelsOn = True

  resw = res
  resw@gsnSpreadColorStart = 8
  resw@gsnSpreadColorEnd = 19
  resw@cnLevelSelectionMode = "ManualLevels"
  resw@cnLevelSpacingF = 2.0
  resw@cnMinLevelValF = -8.0
  resw@cnMaxLevelValF = 24.0

  resqr = res
  resqr@gsnSpreadColorStart = 21
  resqr@gsnSpreadColorEnd = 30
  resqr@cnLevelSelectionMode = "ManualLevels"
  resqr@cnLevelSpacingF = 1.0
  resqr@cnMinLevelValF = 1.0
  resqr@cnMaxLevelValF = 12.0

;------------------------------------------------
; Vertical velocity plots
;------------------------------------------------

  resw@trXMinF = -20.0+loncorr
  resw@trXMaxF =  30.0+loncorr

  printVarSummary(w_5km)

  plot_index=3

  if (ii .eq. 0)
    plot(0) = gsn_csm_contour(wks, w_5km(plot_index,:,:), resw)
  else
    wplot(ii-1) = gsn_csm_contour(wks, w_5km(plot_index,:,:), resw)
  end if

  if(ii .eq. 3) then
    mergedw = gsn_attach_plots(plot(0), (/wplot(0),wplot(1),wplot(2)/), False, False)
  end if
;------------------------------------------------
; Rain water plots
;------------------------------------------------

  resqr@trXMinF = -20.0+loncorr
  resqr@trXMaxF =  30.0+loncorr
  if (ii .eq. 0)
    plot(1) = gsn_csm_contour(wks, qr_5km(plot_index,:,:), resqr)
  else
    qrplot(ii-1) = gsn_csm_contour(wks, qr_5km(plot_index,:,:), resqr)
  end if

  if(ii .eq. 3) then
    mergedqr = gsn_attach_plots(plot(1), (/qrplot(0),qrplot(1),qrplot(2)/), False, False)
  end if

  delete(qr_5km)
  delete(w_5km)

end do

;------------------------------------------------
; Panel plot
;------------------------------------------------

  pres = True
  pres@gsnPanelBottom = 0.2
  pres@gsnPanelTop = 0.8
  ;pres@gsnPanelYWhiteSpacePercent = 5
  ;pres@gsnPanelXWhiteSpacePercent = 5
  pres@txString           = model+", +7200s, r400 -> r50"     ; use this for NCL V6.3.0 and earlier
  gsn_panel(wks, plot, (/2,1/), pres)

end
