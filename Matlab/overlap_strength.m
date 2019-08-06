function [ centers,radii] = overlap_strength(centers,radii,Rmin)
%this section prevents overlapping circles when using imfindcircles. It
%will choose the stronger circle when it detects an overlap and discard
%the weaker one.
%the code iterates through circles, comparing a circle against all weaker
%circles. if the distance of the circle centers is less than the radii
%of the circles, they overlap and the weaker circle will be marked for
%removal by changing its values to -1

marked_circles=centers;
marked_radii=radii;
for m = 1:size(centers,1)
    %circle to be compared agasint weaker circlers
    circleA=centers(m,:);
    for n = m+1:size(centers,1)
        %weaker circle
        circleB=centers(n,:);
        %calculare distance
        d= sqrt((circleA(1)-circleB(1))^2+(circleA(2)-circleB(2))^2);
        if d < (radii(m)+radii(n)) || d<Rmin
            %mark for deletion
            marked_circles(n,:)=[-1 -1];
            marked_radii(n)= -1;
        end
    end
end
%discard marked circles
radii(marked_radii==-1)=[];
centers(marked_circles(:,1)==-1,:)=[];
end

