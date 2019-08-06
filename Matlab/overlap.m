function [new_circles, new_radii, overlap_remain] = overlap(centers,radii, Rmin)
%This segment identifies all overlapping circles and allows user to pick
%which overlapping circles to discard.

overlap_remain=true;
new_circles=centers;
new_radii=radii;

%reset current character so return key can be used to exit loop again.
set(gcf,'CurrentCharacter','f');

c=viscircles(centers,radii,'EdgeColor','r');

%compare all circles to identify overlaps, shown in green.
duplicate_centers=[];
duplicate_radii=[];
for m = 1:size(centers,1)
    select = new_circles(m,:);
    for n = 1:size(new_circles,1)
        compare = new_circles(n,:);
        d = sqrt((select(1)-compare(1))^2+(select(2)-compare(2))^2);
        compare_radius = radii(n);
        select_radius = radii(m);
        if d == 0
            continue;
        elseif d < (compare_radius+select_radius) || d<Rmin
            duplicate_centers = [duplicate_centers; new_circles(m,:)];
            duplicate_radii= [duplicate_radii ; new_radii(m)];
        end
    end
end

a= viscircles(duplicate_centers,duplicate_radii,'EdgeColor','m');

if isempty(duplicate_centers)
    delete(c);
    return;
end

waitfor(msgbox( [ num2str(size(duplicate_centers,1)) ' overlapping circles have been detected(magenta). User input is required to resolve overlaps. Select circles to discard by cliking inside them. When finished selecting, press return.']));

% select circles to discard by using mouse clicks. Coordinates from the
% mouse clicks are used to see if they lie within a circle by using
% distance from center and comparing to circle radius

selected_remove_centers=[];
selected_remove_radii=[];
while get(gcf,'CurrentCharacter')~=13
    [x,y] = ginput(1);
    clicks= [x y];
    key = get(gcf,'CurrentCharacter');
    if (key == 13)
        break;
    end
    for n = 1:size(new_circles,1)
        select = new_circles(n,:);
        compare_radius = radii(n);
        d = sqrt((select(1)-clicks(1))^2+(select(2)-clicks(2))^2);
        if d < compare_radius
            b = viscircles(new_circles(n,:),compare_radius,'EdgeColor','g');
            A=ismember(new_circles,new_circles(n,:));
            new_circles(find(A,1),:)=[-1 -1];
            B=ismember(radii,compare_radius);
            new_radii(find(B))=[-1];
        end;
    end;
end

%remove selected circlces from list
new_radii(new_radii==-1)=[];
new_circles(new_circles(:,1)==-1,:)=[];

%redraw circles
h=findobj('type','line');
for n= 1:size(h,1)
    delete(h(n))
end

a = viscircles(new_circles, new_radii, 'EdgeColor','r');

%ocompare all circles again to identify if overlaps remain.
duplicate_centers=[];
duplicate_radii=[];
for m = 1:size(new_circles,1)
    select = new_circles(m,:);
    for n = 1:size(new_circles,1)
        compare = new_circles(n,:);
        d = sqrt((select(1)-compare(1))^2+(select(2)-compare(2))^2);
        compare_radius = radii(n);
        select_radius = radii(m);
        if d == 0
            continue;
        elseif d < (compare_radius+select_radius) || d<Rmin
            duplicate_centers = [duplicate_centers; new_circles(m,:)];
            duplicate_radii= [duplicate_radii ; new_radii(m)];
        end
    end
end

%this will trigger this function to repeat since overlaps are still present
if size(duplicate_centers,1)>0
    overlap_remain=false;
end

%redraw all updated circles
h=findobj('type','line');
for n= 1:size(h,1)
    delete(h(n))
end
viscircles(new_circles,new_radii,'EdgeColor','b');

end

