##  This is a test
clearconsole()
## Before using
# import Pkg; Pkg.add("Plots")
#using Pkg; Pkg.add("Interpolations")
#Pkg.add("VectorizedRoutines")
# ] DelimitedFiles

## USIN AND & INCLUDE
using DelimitedFiles, Interpolations, Plots, VectorizedRoutines

## FUNTIONS
include("GetTime.jl")
include("RayBender.jl")
include("INITIAL_RAYS.jl")

## LOAD DATA SECTION
#Load AK135 Data
AK135   = readdlm("jAK135.txt", Float64); # I didn't found this file

#read input data
TTDATA0 = readdlm("TestData.txt", Float64);

println("Data Have Been Read!")
## Transform real coordinates to Model Coordinates!

const LONG_0        = minimum([TTDATA0[:,1]; TTDATA0[:,4]]);
const LAT_0         = minimum([TTDATA0[:,2]; TTDATA0[:,5]]);
#Larger window than data
const LONG_min      = floor(minimum([TTDATA0[:,1]; TTDATA0[:,4]]))-1;
const LAT_min       = ceil(minimum([TTDATA0[:,2]; TTDATA0[:,5]]))-1;
const LONG_max      = floor(maximum([TTDATA0[:,1]; TTDATA0[:,4]]))+1;
const LAT_max       = ceil(maximum([TTDATA0[:,2]; TTDATA0[:,5]]))+1;
#Depth Min and Max
const DEPTH_min     = floor(minimum(TTDATA0[:,3]));
const DEPTH_max     = ceil(maximum(TTDATA0[:,6]));
# Distances in the Model
const LONG_Distance = round((LONG_max-LONG_min)*111.3195;sigdigits=2);
const LAT_Distance  = round((LAT_max-LAT_min)*111.3195;sigdigits=2);
# New coordinate system Base
const baselo        = LONG_0-LONG_min; #%shift between (0,0) and data
const basela        = LAT_0-LAT_min; #shift between (0,0) and data

#data in the XY cartesian coordinate system
TTDATA = [ ((TTDATA0[:,1].-LONG_0).*112).+baselo ((TTDATA0[:,2].-LAT_0).*112).+basela TTDATA0[:,3].-0.001 ((TTDATA0[:,4].+(pi/1000).-LONG_0).*112).+baselo ((TTDATA0[:,5].+(pi/1000).-LAT_0).*112).+basela TTDATA0[:,6].+0.001 TTDATA0[:,7] ];

println("Data In Model Coordinates")

## THE MODEL!
# You can use const (minor improvements)
const xmin = 0.0; # min longitud in km
const xmax = LONG_Distance; # max longitud in km
const ymin = 0.0; # min latitude in km
const ymax = LAT_Distance; # max latitude in km
const zmin = DEPTH_min; #min depth in the model (we should include topography)
const zmax = 300.0; #max depth in the model;

# Define spacing in km
const dx = 100.0; #horizontal x cell size
const dy = 100.0; #horizontal y cell size
const dz = 1.0;  #vertical z cell size

# Parameters for ray tracing
const dray   = 0.05; # Porcentage to change ray
const dr     = 12; #Nodes in ray. THis inclures the source and receiver
const movedz = dz*dray;

## Inicialize ray tracing parameters!
ALL_T    = zeros(Float64, size(TTDATA,1));
ALL_RAYS = zeros(Float64, dr, 3, size(TTDATA,1));
# ALL_RAYS = INITIAL_RAYS(TTDATA, ALL_RAYS);
INITIAL_RAYS!(TTDATA, ALL_RAYS);

## Create model Vectors
# vx=collect(xmin:dx:xmax) ; # Vector of X coordinates
# vy=collect(ymin:dy:ymax); # Vector of Y coordinates
# vz=collect(zmin:dz:zmax); # Vector of Z coordinates

vx = xmin:dx:xmax; # Vector of X coordinates
vy = ymin:dy:ymax; # Vector of Y coordinates
vz = zmin:dz:zmax; # Vector of Z coordinates

println("BOX and RAY paramters SET!")

## INITIAL ModelV

iVp = LinearInterpolation(AK135[:,1],  AK135[:,2]);
# To Make the Model Constant Velocity
## Generate Slowness Cube
#Initialize Slowness Model
ModelSp = zeros(Float64, size(vx,1),size(vy,1),size(vz,1));
#Fill Slowness Model with AK135 Values
for k=1:size(vz,1)
    for j=1:size(vy,1)
        for i=1:size(vx,1)
            ModelSp[i,j,k]=1/iVp(vz[k]); # Matrix Space of P wave Slowness value
        end
    end
end

#Create a Velocity Function
knots = ([x for x = xmin:dx:xmax], [y for y = ymin:dy:ymax], [z for z = zmin:dz:zmax]);
F_Sp = interpolate(knots, ModelSp, Gridded(Linear()));

function ALL_X!(ALL_R::Array{Float64,3}, ALL_T::Array{Float64, 1},
    dr::Int64, F_Sp, movedz::Float64, imax::Int64)
    for i in 1:4:imax
        # println("Tracing ray for Source/Event pair: $i")
        RayBender!(ALL_T[i+0], ALL_R[:,:,i+0], dr, F_Sp, movedz);
        RayBender!(ALL_T[i+1], ALL_R[:,:,i+1], dr, F_Sp, movedz);
        RayBender!(ALL_T[i+2], ALL_R[:,:,i+2], dr, F_Sp, movedz);
        RayBender!(ALL_T[i+3], ALL_R[:,:,i+3], dr, F_Sp, movedz);
    end
end

## Perform Ray tracing
# In my test break the loop speed up 2x
# @time for i=1:4:size(TTDATA,1);
#     # Trace ray by Pseudo-Bending Algorithm
#     println("Tracing ray for Source/Event pair: $i")
#     ALL_T[i],   ALL_RAYS[:,:,i]   = RayBender(ALL_RAYS[:,:,i],   dr, zmax, F_Sp, movedz);
#     ALL_T[i+1], ALL_RAYS[:,:,i+1] = RayBender(ALL_RAYS[:,:,i+1], dr, zmax, F_Sp, movedz);
#     ALL_T[i+2], ALL_RAYS[:,:,i+2] = RayBender(ALL_RAYS[:,:,i+2], dr, zmax, F_Sp, movedz);
#     ALL_T[i+3], ALL_RAYS[:,:,i+3] = RayBender(ALL_RAYS[:,:,i+3], dr, zmax, F_Sp, movedz);
# end

# Warm up
# @time ALL_X!(zeros(size(ALL_RAYS)), zeros(size(ALL_T)), dr, zmax, F_Sp, movedz, size(TTDATA, 1))

@time ALL_X!(ALL_RAYS, ALL_T, dr, F_Sp, movedz, size(TTDATA, 1))

## FIGURES! LET'S MAKE THEM PRETTY!

#Figure 1. Velocity model and Stations and Events
p1=plot(AK135[:,2:3],AK135[:,1], yflip = true,color = [:blue :red],label=["Vp" "Vs"])
Plots.scatter!(iVp(AK135[:,1]),AK135[:,1],markershape = :circle, color = [:black],label="Int Vp")
plot!(title="AK135 Initial Model")
plot!(xlabel = "Velocity (km/s)")
plot!(ylabel = "Depth (km)")

p2=Plots.scatter(TTDATA[:,1],TTDATA[:,2],markershape = :dtriangle, color = [:orange],label="Stations")
p3=Plots.scatter(TTDATA[:,4],TTDATA[:,5],markershape = :circle, color = [:red],label="Events")
#Plots.scatter!(ALL_RAYS[:,1,:],ALL_RAYS[:,2,:],markershape = :circle, color = [:blue],label="")

#plot!(ALL_RAYS[:,1,1],ALL_RAYS[:,2,1],  color = [:blue],label="Rays")
#plot!(ALL_RAYS[:,1,100],ALL_RAYS[:,2,100],  color = [:blue], label="")

p4=histogram(ALL_T-TTDATA[:,7],color=:blue, fillalpha=.3,label="Residuals",xlabel = "Residual Time (s)",ylabel = "Frecuency (Counts)")

plot(p2,p3,p1,p4)
savefig("Figure1.pdf")

# Figure 2
scatter(TTDATA[:,1],TTDATA[:,2],TTDATA[:,3], markershape = :dtriangle, color = [:orange],xlim=(xmin,xmax),ylim=(ymin,ymax),zlim=(zmin,zmax),label="Stations")
for ii=1:size(ALL_T,1)-1
    plot!(ALL_RAYS[:,1,ii],ALL_RAYS[:,2,ii],ALL_RAYS[:,3,ii], color = [:blue],label="")
end
plot!(ALL_RAYS[:,1,size(ALL_T,1)],ALL_RAYS[:,2,size(ALL_T,1)],ALL_RAYS[:,3,size(ALL_T,1)], color = [:blue],label="Rays")
scatter!(TTDATA[:,4],TTDATA[:,5],TTDATA[:,6] , markershape = :circle, color = [:red], label="Events")
savefig("Rays.pdf")
