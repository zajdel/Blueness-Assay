function [C] = get_circles(I,position,vis)
%This function will find 96 strongest circles in the given image using the
%radius parameters the given position. It will then return a list of
%the circle coordinates [x y] and C, which is the coordinates for the four
%coordinates of the plate corners [top_left top_right bottom_right bottom_left
%

if position==1
    Rmin=73;
    Rmax=85;
elseif position==2
    Rmin=68;
    Rmax=80;
end

%identifty circles for wells, 'Sensitivity',0.98,'EdgeThreshold',0.1,
[centers, radii, ~] = imfindcircles(I,[Rmin Rmax],'Sensitivity',0.98,'EdgeThreshold',0.1,'ObjectPolarity','dark');
[centers, radii] = auto_adjust(centers,radii,I,Rmin,Rmax);
[centers,radii] = overlap_strength(centers, radii,Rmin);

%select top 96 wells
well_num=96;
centersStrong96 = centers(1:well_num,:);
radiiStrong96 = radii(1:well_num);

if vis==true
c=viscircles(centersStrong96, radiiStrong96,'EdgeColor','b');
end

%calculate corner coordinates based on circle coordinates
x=centersStrong96(:,1);
y=centersStrong96(:,2);
C=zeros(4,2);
%top left corner coordinates
[~,loc] = min(y+x);
temp = [x(loc),y(loc)];
C(1,:)=temp-[290 215];

%top right corner coordinates
[~,loc] = min(y-x);
temp = [x(loc),y(loc)];
C(2,:)=temp-[-290 215];

%bottom right corner coordinates
[~,loc] = max(y+x);
temp = [x(loc),y(loc)];
C(3,:) =temp-[-290 -215];

%bottom left corner coordinates
[~,loc] = max(y-x);
temp = [x(loc),y(loc)];
C(4,:)=temp-[290 -215];

end

