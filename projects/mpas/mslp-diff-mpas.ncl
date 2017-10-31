load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************
  ;filename = "/glade/scratch/mpasrt/wp/2017080200/diag.2017-08-07_00.00.00.nc"
  ;f     = addfile(filename,"r")

  initdate="2017080100"

  ;filename = systemfunc ("ls /glade/scratch/mpasrt/wp/"+initdate+"/diag.*.nc") ; file paths
  filename = systemfunc ("ls /glade/scratch/mpasrt/wp/"+initdate+"/test/diag.*.nc") ; file paths

  f    = addfiles (filename, "r")   
  ListSetType (f, "cat")
  var    = f[:]->mslp 
  var2   = f[:]->u10
  var3   = f[:]->v10
  var2 = sqrt(var2^2 + var3^2)

  time = tostring(f[:]->xtime)
  print(time)

  dims = dimsizes(var)
  ntimes = dims(0)
  ncol = dims(1)

  gridname = "/glade/p/work/mpasrt/tc2017/static_wp.nc"
  g = addfile(gridname,"r")

  lat1d = ndtooned(g->latCell)          ; Pull off lat/lon variable and
  lon1d = ndtooned(g->lonCell)          ; convert both to 1D.
  ;var  = ndtooned(f->skintemp(0,:))      ; Read some data; convert to 1D.

  landmask = tofloat(g->landmask)
;print(landmask)
  printVarSummary(landmask)

  ;print(lat1d)
  pi=3.14159
  r2d=180/pi

  lat1d=lat1d*r2d
  lon1d=lon1d*r2d

  maxLat=45.
  minLat=20.
  maxLon=150.
  minLon=120.

  var@_FillValue=-99999.9
  var2@_FillValue=-99999.9
  do ii = 0,ntimes-1
    var(ii,:) = where(lat1d .lt. maxLat .and. lat1d .gt. minLat,var(ii,:),var@_FillValue)
    var(ii,:) = where(lon1d .lt. maxLon .and. lon1d .gt. minLon,var(ii,:),var@_FillValue)
    var2(ii,:) = where(lat1d .lt. maxLat .and. lat1d .gt. minLat,var2(ii,:),var2@_FillValue)
    var2(ii,:) = where(lon1d .lt. maxLon .and. lon1d .gt. minLon,var2(ii,:),var2@_FillValue)
    print(min(var(ii,:))+"    "+max(var2(ii,:))+"    "+str_right_strip(time(ii)))
  end do

  exit

;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("pdf","SSTA-mpas-wp-"+initdate)               ; open workstation
  gsn_define_colormap(wks,"hotcolr_19lev")   ; choose colormap

  res                     = True         ; plot modifications desired

  res@gsnFrame = False
  res@gsnDraw = False


;  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@gsnSpreadColors     = True         ; Use full colormap, but start

  res@sfXArray            = lon1d        ; Required to tell NCL where to
  res@sfYArray            = lat1d        ; overlay data on globe.

  res@cnFillOn            = True         ; Turn on contour fill
;  res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

res@mpMaxLatF = 45.
res@mpMinLatF = 15.
res@mpMaxLonF = 175.
res@mpMinLonF = 120.

      ;res@cnLevelSelectionMode = "ManualLevels"
      ;res@cnLevelSpacingF      =  0.5
      ;res@cnMinLevelValF       =  25.0
      ;res@cnMaxLevelValF       =  32.0

      res@cnLevelSelectionMode = "ManualLevels"
      res@cnLevelSpacingF      =  0.25
      res@cnMinLevelValF       =  -2.0
      res@cnMaxLevelValF       =  2.0

  do jj = 0,ntimes-1,4
  print(jj+"")

  res@tiMainString = "SSTA at "+str_right_strip(time(jj))
  map = gsn_csm_contour_map_ce(wks,vardiff(jj,:),res)

  draw(map)
  frame(wks)

  end do

end