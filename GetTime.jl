# It is a good practice specialize your function
function GetTime(ray0::Array{Float64, 2}, F_Sp)
    time=0;
    #Loop to evaluate slowness
    for ri=2:size(ray0,1)
        Snode1=F_Sp(ray0[ri-1,1],ray0[ri-1,2],ray0[ri-1,3]);
        Snode2=F_Sp(ray0[ri,1],ray0[ri,2],ray0[ri,3]);
        B = (Snode1 + Snode2)*0.5;
        C = sqrt((ray0[ri,1] - ray0[ri-1,1])^2 +
                 (ray0[ri,2] - ray0[ri-1,2])^2 +
                 (ray0[ri,3] - ray0[ri-1,3])^2);
        time += B * C;
    end

    return time
end

