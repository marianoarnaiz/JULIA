function RayBender(ray0,dr,zmax,F_Sp,movedz)
    T0=GetTime(ray0, F_Sp);
NCC=0;
while NCC<dr-2
    NCC=0;
    for p=2:dr-1

        #Bend a point of the ray up and down
        #Also get the travel time of each test

        rtest=ray0[p,3];
        ray0[p, 3] = rtest + movedz;
        #rayz1[rayz1.>zmax] .= zmax;
        T1=GetTime(ray0,F_Sp);
        ray0[p, 3] = rtest - movedz;
        T2=GetTime(ray0,F_Sp);

        if T1<T0 && T1<T2 # If RAY 1 is the solution
            ray0[p, 3] = rtest + movedz;
            T0=T1;
            #println("T1")

        elseif T2<T0 && T2<T1 # If RAY 2 is the solution
            ray0[p, 3] = rtest - movedz;
            T0=T2;
            #println("T2")

        else
            NCC=NCC+1; # Keep Count of NO CHANGES
        end

    end
end
return T0,ray0

end
