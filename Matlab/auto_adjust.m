function [centers1,radii1] = auto_adjust(centers,radii,rgb,Rmin,Rmax)
%This function will take the circles generated by the catch-all
%imfindcircle and attempt to narrow the identified circles down by
%iteratively decreasing tolerance of imfindcircles. After 50 attempts, it
%will return the centers and radii of the new circles.
% This is computationally costly but this allows for variation in images  
%and ensures good results from plate to plate

centers1=centers;
radii1=radii;

if size(centers1,1)==96
    return;
end

count=1;
n=0.97;
m=.1;
while size(centers1,1)>105
    count=count+1;
    if n==0
        return
    end
    n=n-.01;
    m=m+.01;
    [centers1, radii1, ~] = imfindcircles(rgb,[Rmin Rmax],'Sensitivity',n,'EdgeThreshold',m,'ObjectPolarity','dark');
    if count==50
        return
    end
end

count=1;
while size(centers1,1)<85
    count=count+1;
    if n==1
        return
    end
    n=n+.01;
    m=m-.01;
    [centers1, radii1, ~] = imfindcircles(rgb,[Rmin Rmax],'Sensitivity',n,'EdgeThreshold',m,'ObjectPolarity','dark');
    if count==50
        return
    end
end

end
