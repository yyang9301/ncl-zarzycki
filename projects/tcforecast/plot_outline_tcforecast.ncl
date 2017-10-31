function plot_outline_fcn(wks,plot,linecolor,linethick)

;========================================================
; This function plots an outline of the AMIP refinement pattern over
; a map
;
; Inputs
; wks - workstation
; plot - plot
; linecolor - color of line (string)
; linethick - thickness of line (float)
;========================================================

;local nlat,mlon,re,pi,rad,rr,ASPHERE,dxeq,dx,dy,carea
begin

;fileinside="atl_30_x8_border_inside.txt"
;fileoutside="atl_30_x8_border_outside.txt"

;data_in = asciiread(fileinside,(/33,2/),"float")
;data_out = asciiread(fileoutside,(/25,2/),"float")

;lat_in = data_in(:,0)
;lon_in = data_in(:,1)
;lat_out = data_out(:,0)
;lon_out = data_out(:,1)

lat_in = (/ \
31.698, \
32.72, \
33.778, \
34.803, \
35.755, \
36.697, \
37.358, \
38.522, \
39.889, \
40.393, \
42.014, \
44.167, \
45.964, \
48.126, \
49.659, \
50.542, \
51.752, \
51.79, \
51.235, \
49.48, \
48.168, \
47.364, \
46.629, \
45.082, \
44.311, \
41.899, \
40.514, \
39.193, \
38.685, \
38.43, \
38.43, \
37.696, \
36.809, \
35.738, \
33.742, \
31.008, \
28.037, \
25.007, \
20.914, \
18.004, \
14.743, \
11.597, \
8.775, \
7.232, \
5.467, \
5.195, \
6.077, \
5.971, \
5.721, \
5.606, \
5.606, \
5.606, \
5.527, \
5.458, \
5.574, \
5.68, \
5.786, \
5.786, \
5.786, \
5.786, \
5.791, \
5.68, \
7.103, \
7.085, \
7.085, \
7.269, \
7.934, \
8.632, \
9.385, \
10.448, \
11.039, \
13.51, \
16.887, \
19.603, \
23.446, \
25.553, \
27.378, \
29.568, \
31.698 \
/)

lon_in = (/ \
-130.466, \
-127.682, \
-124.383, \
-121.155, \
-117.237, \
-113.088, \
-109.323, \
-104.859, \
-100.567, \
-96.503, \
-93.727, \
-91.493, \
-89.143, \
-87.492, \
-85.946, \
-83.087, \
-80.183, \
-77.477, \
-74.742, \
-71.768, \
-70.163, \
-68.04, \
-65.523, \
-63.021, \
-60.426, \
-56.938, \
-53.571, \
-50.286, \
-46.725, \
-43.219, \
-40.101, \
-37.423, \
-34.301, \
-30.707, \
-26.475, \
-21.457, \
-19.066, \
-17.812, \
-17.738, \
-17.627, \
-17.627, \
-17.517, \
-18.904, \
-21.883, \
-26.078, \
-29.556, \
-34.968, \
-38.409, \
-41.651, \
-46.374, \
-50.023, \
-53.955, \
-58.808, \
-64.376, \
-69.505, \
-74.468, \
-79.565, \
-83.802, \
-87.978, \
-91.545, \
-96.424, \
-100.18, \
-103.326, \
-106.281, \
-109.695, \
-113.978, \
-118.279, \
-122.465, \
-126.212, \
-129.833, \
-132.96, \
-135.559, \
-136.923, \
-138.103, \
-138.547, \
-137.45, \
-135.364, \
-133.181, \
-130.466 \
/)

lat_out = (/ \
38.067, \
41.66, \
46.681, \
51.295, \
56.949, \
57.905, \
58.164, \
57.901, \
56.607, \
53.956, \
47.794, \
45.281, \
43.125, \
39.042, \
34.607, \
26.972, \
18.51, \
11.946, \
6.278, \
0.043, \
-0.812, \
-0.886, \
-0.775, \
-0.881, \
-0.881, \
-0.992, \
-1.066, \
-1.066, \
-1.066, \
-1.107, \
1.516, \
1.516, \
1.516, \
1.516, \
1.516, \
3.438, \
4.796, \
7.271, \
10.08, \
13.553, \
19.304, \
25.545, \
29.84, \
34.173, \
38.067 \
/)

lon_out = (/ \
-140.982, \
-132.189, \
-123.388, \
-113.962, \
-102.875, \
-94.745, \
-87.321, \
-78.996, \
-69.56, \
-59.981, \
-47.184, \
-34.497, \
-22.416, \
-13.794, \
-7.148, \
0.418, \
1.417, \
1.491, \
1.195, \
-5.604, \
-10.738, \
-18.036, \
-26.394, \
-36.195, \
-45.542, \
-54.302, \
-66.322, \
-76.007, \
-83.329, \
-90.751, \
-99.355, \
-104.229, \
-108.729, \
-113.017, \
-116.662, \
-127.424, \
-131.888, \
-137.651, \
-143.784, \
-148.474, \
-151.138, \
-151.582, \
-151.036, \
-146.701, \
-140.982 \
/)

resp                  = True                      ; polyline mods desired
resp@gsLineColor      = linecolor                    ; color of lines
resp@gsLineThicknessF = linethick
resp@mpGreatCircleLinesOn=True

dum = new(500,"graphic")
count = 0

do hh = 0,dimsizes(lat_in) - 2		; Draw inner nest
  dum(hh) = gsn_add_polyline(wks,plot,lon_in(hh:hh+1),lat_in(hh:hh+1),resp)
  count = hh
end do

do hh = 0,dimsizes(lat_out) - 2		; Draw outer nest
  dum(hh+count+1) = gsn_add_polyline(wks,plot,lon_out(hh:hh+1),lat_out(hh:hh+1),resp)
end do

dname = unique_string("dum")            ; This setting is important! If
                                        ; you don't do this, gsn_add_polygon
                                        ; will fail.
plot@$dname$ = dum                      ; That way you assign a unique name
                                        ; to each "dum" attribute, thus saving
                                        ; each attribute and allowing each 
                                        ; line to be drawn on each plot.

return(plot)

end



 
