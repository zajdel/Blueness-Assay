function [ new_circles, new_radii ] = manual_identification(centers,radii)
%This function will allow user to both add and remove circles manually.
%to add, they will click two points, one for defining
%center of circle and the other for defining the the radius.
%to remove, they simply need to click inside the circle.

%reset current character so return key can be used to exit loop again.
set(gcf,'CurrentCharacter','f');

%initialize 
new_circles=centers;
new_radii=radii;

g=viscircles(centers,radii,'EdgeColor','r');

waitfor(msgbox('To remove an identified circle, click anywhere inside the cirlce to be removed. When done, press "return".'));
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
        end;
    end;
end

%remove selected circles from list
idx=find(new_circles(:,1)==-1);
new_radii(idx)=[];
new_circles(new_circles(:,1)==-1,:)=[];

%redraw circles
h=findobj('type','line');
for n= 1:size(h,1)
    delete(h(n))
end

a = viscircles(new_circles, new_radii, 'EdgeColor','r');

%reset current character so e key can be used to exit loop again.
set(gcf,'CurrentCharacter','f');

%add new circles
waitfor(msgbox('To identify additional circles, click once to identify the center of the desired circle and then click again to define the radius of the circle. When done, press "return".'));
while 1
    [x,y] = ginput(2);
    clicks= [x y];
    if size(clicks,1)~=2
        break;
    end
    new_radius=sqrt((clicks(1)-clicks(2))^2+(clicks(3)-clicks(4))^2);
    a = viscircles(clicks(1,:),new_radius,'EdgeColor','g');
    new_circles= [new_circles ; clicks(1,:)];
    new_radii = [new_radii ; new_radius];
end

%redraw circles
h=findobj('type','line');
for n= 1:size(h,1)
    delete(h(n))
end

a = viscircles(new_circles, new_radii, 'EdgeColor','b');

end

