function [ section ] = slice(image,position,img_num,vis)
%This section will take the raw image from the scanner, crop it to focus on
%the selected plate, auto-rotate it to get rid of slight angles, and then
%return the appropriate section of the adjusted image to be later stitched.
%   image is the image from the scanner
%   position is the position on the scanner, user picks 1 or 2
%   img_num is the number of the image taken from the scanner (1-4)
%   vis determines if user wants to see steps

%% Image Cropping and Circle Find
%%identifty plate and get coordinates for rotation adjustment.

if vis==true
    figure;
    imshow(image);
    k = waitforbuttonpress;
end

if position==1
    ymin=0;
    width=2200;
    height=3600;
elseif position==2
    ymin=3600;
    width=2200;
    height=3600;
end

move=370;
if img_num == 1
    xmin=2150;
elseif img_num == 2
    xmin=2150-move;
elseif img_num == 3
    xmin=2150-2*move;
elseif img_num == 4
    xmin=2150-3*move;
end

crop_img=imcrop(image,[xmin ymin width height]);
I=imrotate(crop_img,90);

if vis==true
    figure;
    imshow(I);
    k = waitforbuttonpress;
end

%pass in image to get_circles to find circles in plate.
%summaryP is a matrix that is [row# column# xcoordinat ycoordinate] for
%each circle. C is a matrix for the coordinates of the corners of the plate
%in the format [topleft topright bottomright bottomleft].
[C]=get_circles(I,position,vis);

%% Fix Rotation
%adjsut the picutre for any slight rotation so insure good alignment of
%rows between stiched images
if vis==true
    % Plot the corners
    imshow(I); hold all
    plot(C([1:4 1],1),C([1:4 1],2),'r','linewidth',3);
    k = waitforbuttonpress;
end

%Find the locations of the new  corners
L = mean(C([1 4],1));
R = mean(C([2 3],1));
U = mean(C([1 2],2));
D = mean(C([3 4],2));
C2 = [L U; R U; R D; L D];

%Do the image transform
T = cp2tform(C ,C2,'projective');
IT = imtransform(I,T);


%% Slice

%pick the appropriate section of the image to be stitched and crop it.
[C]=get_circles(IT,position,vis);

if vis==true
    plot(C([1:4 1],1),C([1:4 1],2),'b','linewidth',3);
    k = waitforbuttonpress;
end

if vis==true
    imshow(IT)
    k = waitforbuttonpress;
end
%pixel length to add edge an two rows
edge_row=535;
%width of plate in pixels
width=2948;
%staring x coordinate used to crop
xmin=C(4,1);
%pixel lengthper two rows
row=420;

if img_num==1
    % rowGH=
    section=imcrop(IT,[xmin C(4,2)-edge_row width edge_row]);
elseif img_num==2
    %rowEF
    section=imcrop(IT,[xmin (C(4,2)-(edge_row+row)) width row]);
elseif img_num==3
    %rowCD
    section=imcrop(IT,[xmin C(4,2)-(edge_row+(2*row)) width row]);
elseif img_num==4
    %rowAB
    section=imcrop(IT,[xmin C(1,2) width edge_row]);
end

if vis==true
    figure
    imshow(section);
    k = waitforbuttonpress;
end


