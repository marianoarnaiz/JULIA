function INITIAL_RAYS(TTDATA, ALL_RAYS)
for i=1:size(TTDATA,1)
    RECEIVER = [TTDATA[i,1], TTDATA[i,2],TTDATA[i,3]]; #Source Position
    SOURCE = [TTDATA[i,4],TTDATA[i,5],TTDATA[i,6]]; #Receiver Position
    #Initial RAY
    ALL_RAYS[:,:,i]=[collect(range(SOURCE[1],RECEIVER[1],length=dr))  collect(range(SOURCE[2],RECEIVER[2],length=dr)) collect(range(SOURCE[3],RECEIVER[3],length=dr))];
end
return ALL_RAYS
end

function INITIAL_RAYS!(TTDATA::Array{Float64, 2}, ALL_RAYS::Array{Float64,3})
    for i in 1:size(TTDATA,1)
        RECEIVER = [TTDATA[i,1], TTDATA[i,2], TTDATA[i,3]]; #Source Position
        SOURCE   = [TTDATA[i,4], TTDATA[i,5], TTDATA[i,6]]; #Receiver Position
        #Initial RAY
        ALL_RAYS[:,:,i] = [collect(range(SOURCE[1],RECEIVER[1],length=dr))  collect(range(SOURCE[2],RECEIVER[2],length=dr)) collect(range(SOURCE[3],RECEIVER[3],length=dr))];
    end
end
