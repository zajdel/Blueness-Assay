function [ circles, radius1, a ] = red_circle_find(radius)
%function to find circles in a red assay, using four given corner pellet
%and radius size

n=1;
clicks= zeros(3,2);
while n~=4
    [x,y] = ginput(1);
    clicks(n,:)= [x y];
    a = viscircles([x y],2,'EdgeColor','r');
    n=n+1;
end
%delete dots for choosen centers
h=findobj('type','line');
for n= 1:size(h,1)
    delete(h(n))
end
x=clicks(:,1);
y=clicks(:,2);
circles=zeros(96,2);
radius1 =radius*ones(96,1);
p=1;
slope_hor = (y(2)-y(1))/(x(2)-x(1));
slope_ver = (x(3)-x(2))/(y(3)-y(2));
if (x(2)-x(1)) >= (y(3)-y(2))
    x_coor=linspace(x(1),x(2),12);
    y_coor=linspace(y(2),y(3),8);
    for n=1:12
        for m=1:8
            correction_y=slope_hor*(x_coor(2)-x_coor(1))*(12-n);
            correction_x=slope_ver*(y_coor(2)-y_coor(1))*(m);
            circles(p,:)=[x_coor(n)+correction_x y_coor(m)-correction_y];
            p=p+1;
        end
    end
end

a = viscircles(circles,radius1,'EdgeColor','g');
end

