 close all;
clear all;
clc;

%% blueness_assay v1.1
%
% Andrew Prior, 2016-12-15
%
%Tom Zajdel
% 2016-02-26
% Adapted from Caroline Ajo-Frankln's D67.m and PelletSizeColor2.m code
%

%this program is designed to operate with the ardunio/scanner setup and the
%blueness main python program in 5204.Designed for 96 well, round bottom white
%plates (sigma aldrich by GSS, part number CLS3789-100EA).

% This program takes four images from scanner and stitches them into one
%image, selecting the appropriate part of the plate from each image to produce 
%the best stitched image. It corrects for any misalignment of scanner/plate 
%and should be robust against user error. Normally takes ~70 seconds to run.
%the stitched image is used to analyze the blue, red or both channel(s) in 
%the wells of the plate and produce colormap(s), color vs column number
%

%if the user saves the data, a folder is created in the same directory as 
%selected images.The file name format is ['Stitched' position timestamp].
%This folder contains the csv file, the stitched image, the colormap and
%the plot generated from the program. Subsequent saves will not overwrite 
%files.

%
% v1.1, 2016-02-26:
% Earlier versions calculated image intensity, not density.
% Density is now computed using an uncalibrated conversion formula:
%       D = log10(255 / I)
%
%% Image Stitching
%this section will take the 4 images produced by scanner and stitch them
%into one image with the appropriate rows of wells taken from each image.
%this code expects 4 images to be selected.


[FileName,PathName] = uigetfile({'*.*';'*.jpg'},'Select the four image files','MultiSelect','on');

FileName=sort(FileName);
image=cell(1,4);


choice = questdlg({'Which plate position?'},'Plates ','1','2','1');
% position one is near the base of the printer, position 2 is closer to
% the user. can only do one position at a time.
switch choice
    case '1'
        position=1;
    case '2'
        position=2;
end


%read in the four images selected. The order of the images should be
%1,2,3,4 for stitching to be accurate.
for n=1:4
    image{n}=imread([PathName FileName{n}]);
end

%decide if you want program to display steps. vis=true to make steps
%visible, vis=false to hide steps. Will pause at steps and wait for 
%user button press
vis=true;
vis=false;

%initialize for vis-related operation
flag=0;

%slice will take the raw image, identify the plate in the given
%position,correct for any rotation, and then return the appropriate
%section of the image to be stitched.

H = waitbar(0,'Stitching Image...');
section=cell(1,4);
for n=1:4
    [section{n}]=slice(image{n},position,n,vis);
    waitbar((n/4),H,'Stitching Image...');
end

close(H);
close all;
%combine crops images, stitched together and show.
stitch=[ section{4};section{3};section{2};section{1}];
pic(4)= figure('name','Stitched Image');
imshow(stitch);
%get path and name of file
[pathstr,~,ext] = fileparts([PathName FileName{4}]);
name=['Position' num2str(position)];

if vis==true
    k=waitforbuttonpress;
end


%% Separate Channels
%this section was done to determine in any adjustment is needed for any
%individual channel.
rgb = stich;
%blue channel
imblue =rgb(:,:,3);
%red channel
imred =rgb(:,:,1);
%green chaneel
imgreen =rgb(:,:,2);

gray = rgb2gray(rgb);
%% Automatic Circle Find
%Allow user to repeatedly adjust radius search parameters to idenfity circles. if none
%are detected, it will prompt user to change parameters until circles are
%found

%not sure why but it tends to find circles better things way
if position==1
    Rmin=73;
    Rmax=85;
elseif position==2
    Rmin=68;
    Rmax=80;
end

%find circles
[centers, radii, metric] = imfindcircles(rgb,[Rmin Rmax],'Sensitivity',0.98,'EdgeThreshold',0.1);

if vis==true
    c=viscircles(centers, radii,'EdgeColor','r');
    k= waitforbuttonpress;
end
    
% auto adjust to attempt to narrow number of circles as close to 96 as possible.
if size(centers,1)~=0
    [centers, radii] = auto_adjust(centers,radii,rgb,Rmin,Rmax);
end

if vis==true
    c=viscircles(centers, radii,'EdgeColor',[0 0 0]);
    k= waitforbuttonpress;
    %erase circles
    h=findobj('type','line');
    for n= 1:size(h,1)
        delete(h(n))
    end
    c=viscircles(centers, radii,'EdgeColor',[0 0 0]);
end

%this section prevents overlapping circles when using imfindcircles. It
%will choose the stronger circle when it detects an overlap and discard
%the weaker one.
[centers,radii] = overlap_strength(centers, radii,Rmin);
if vis==true
    c=viscircles(centers, radii,'EdgeColor','r');
    k= waitforbuttonpress;
    %erase circles
    h=findobj('type','line');
    for n= 1:size(h,1)
        delete(h(n))
    end
    c=viscircles(centers, radii,'EdgeColor',[0 0 0]);
end

%this used to retain top 96 circles (may have to tune depending on imaging setup)
%"strongest" circles used for analysis and the rest are discarded.
well_num=96;
centersStrong96 = centers(1:well_num,:);
radiiStrong96 = radii(1:well_num);

c=viscircles(centersStrong96, radiiStrong96,'EdgeColor',[0 0 0]);
if vis==true
    k= waitforbuttonpress;
end

%% Circle Adjustment
%This code allows for manual adjustment of circles by shifting the centers and increasing or decreasing the radii.
%The new position is shown in magenta.

%multiple circle adjustment
choice = questdlg('Circle adjustment desired?','Multiple Circle Adjustment','Yes','No','No');
% Handle response
switch choice
    case 'Yes'
        delete(c);
        [centersStrong96, radiiStrong96] = circle_adjust_multiple(centersStrong96, radiiStrong96);
    case 'No'
    case ''
        return;
end
%% Select Assay Type

%parameters
pCols=12;
pRows=8;

%select assay type to determine which color the program is looking for
choice = questdlg({'Red Assay or Blue Assay?'},'Assay type ','Red','Blue','Both','Blue');
switch choice
    case 'Red'
        red_assay=true;
        both=false;
    case 'Blue'
        red_assay=false;
        both=false;
    case 'Both'
        red_assay=false;
        both=true;
end

%% Color Density Calculation
%Convert the regions to wells within the image
%---------------------------------------------------------------
%Move centroids to the nearest pixels
n=(length(centersStrong96)); %n should be 96
centerx=centersStrong96(:,1);
centery=centersStrong96(:,2);

%Find the origin
originx = min(centerx);
originy = min(centery);

%Calculate the delta x & delta y
deltax = (max(centerx)-originx)./(pCols-1);
deltay = (max(centery)-originx)./(pRows-1);

%Convert x & y positions into rows & column indices
column = round(((centerx-originx)./deltax) +1);
row = round(((centery-originy)./deltay)+1);

% gather the circles and average pixels over entire circle
pellet_blue = zeros(n,1);
pellet_red = zeros(n,1);
pellet_gray  = zeros(n,1);
pellet_green = zeros(n,1);
[rr, cc] = meshgrid(1:size(rgb,2), 1:size(rgb,1));
if vis==true
    flag=1;
    h=figure;
    hold on;
end
for k=1:n
    cmask = sqrt((rr-centerx(k)).^2+(cc-centery(k)).^2)<=radiiStrong96(k);
    pellet_gray(k)= mean(gray(cmask));
    pellet_blue(k)=mean(imblue(cmask));
    pellet_red(k)=mean(imred(cmask));
    %pellet_gray(k)=1;
    pellet_green(k)=1;
    if vis==true && flag<30
        imshow(cmask);
        pause(.1);
        flag=flag+1;
    end
end
if vis==true
    close(h);
end
% save file with pellet summaries
pellet_areas = pi*radiiStrong96.^2;
pellet_centers=[centerx, centery];
pellet_intensity = pellet_gray;
pellet_summary = [row, column, pellet_areas, ...
    pellet_intensity,pellet_blue, pellet_gray, pellet_red, pellet_green];

empty=[];
%If there are empty wells, put in place holders
if length(empty)>=1,
    [rEmpty,~] = size(empty);
    holders = zeros(rEmpty,6);
    holders(1:rEmpty,1) = empty(:,1);
    holders(1:rEmpty,2) = empty(:,2);
    holders(:,3)=0.95.*min(pellet_areas);
    holders(:,5)=0.95.*min(pellet_red);
    holders(:,6)=0.95.*min(pellet_red2green);
    pellet_summary2=[pellet_summary;holders];
elseif isempty(empty),
    pellet_summary2=pellet_summary;
end;

%Add place holders into pellet summary, then sort by rows
summaryP = sortrows(pellet_summary2);

%Reshape the pellet data into rows & columns
sizeP = transpose(reshape(summaryP(:,3),pCols,pRows));
blueP = transpose(reshape(summaryP(:,5),pCols,pRows));
redP  = transpose(reshape(summaryP(:,7),pCols,pRows));

blueDensity = log10(255./blueP); %convert to uncalibrated O
redDensity = log10(255./redP);
%% Colormaps
%colormap of results

if red_assay==false || both==true
    pic(1) = figure('name','Blue Density Colormap');
    blueimage = imagesc(blueDensity*-1);
    colormap(bone)
    title ('Blue Density');
end

if red_assay==true || both==true
    pic(2) = figure('name', 'Red Density Colormap');
    redimage = imagesc(redDensity);
    colormap(bone)
    title ('Red Density');
end

if vis==true
    k= waitforbuttonpress;
end

%% Color Density Over Rows
%figure(s) to show graph of blue density or red density over each row
IPTG = [1 2 3 4 5 6 7 8 9 10 11 12];
alphabet = ['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'];
if red_assay==false || both==true
    
    %set title and position
    plots(1) = figure('Name',['Blue vs IPTG_ ' name],'NumberTitle','off');
    title(['Blue vs IPTG_ ' name]);
    set(plots(1), 'Position', [100, 100, 1150, 895]);
    
    %create subplot for each row
    for n=1:8
        d = subplot(4,2,n);
        hold on;
        title(['Row ' +alphabet(n)]);
        h = plot(IPTG,blueDensity(n,:),'Color','b');
        ylabel('Blue Value');
        
%         %use when over want bluenss over subsection of rows
%         if n==1
%             title(['Row ' +alphabet(n)]);
%             h = plot(IPTG,blueDensity(n,:),'Color','b');
%         elseif n~=1 && n~=8
%             title(['Row ' +alphabet(n)]);
%             h = plot(IPTG(1:6),blueDensity(n,1:6),'Color','b');
%         elseif n==8
%             title(['WO3']);
%             h = plot(IPTG(7:12),blueDensity(2,7:12),'Color','b');
%         end
        
    end
end

% % %     %section for diffuse reflectance plates or overlaying repeats
% % figure;
% % for n=1:8
% %     %d = subplot(4,2,n);
% %     hold on;
% %     title(['All']);
% %     if n==1 || n==8
% %         continue;
% %         %h = plot(IPTG,blueDensity(n,:),'Color','b');
% %     end
% %     h = plot(IPTG(1:6),blueDensity(n,1:6),'Color','b');
% % end

if red_assay==true || both==true
    
    %set title and position
    plots(2) = figure('Name',['Red vs IPTG_ ' name],'NumberTitle','off');
    title(['Red vs IPTG_ ' name]);
    set(plots(2), 'Position', [100, 100, 1150, 895]);
    
    %create subplot for each row
    for n=1:8
        d = subplot(4,2,n);
        hold on;
        title(['Row ' +alphabet(n)]);
        h = plot(IPTG,redDensity(n,:),'Color','r');
        xlim([1 12]);
        ylabel('Red Value');
    end
end
%% Save Data
%This section will ask user if they want to save image and data. Creates
%new, time-stamped folder in same directory as selected image.

choice = questdlg('Save results?','Save Data','Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'
        %create new folder for results in the same location as selected images
        %folder are created with the year-month-day-hour-minute-secon format
        %to insure no results are ever overwritten with additional runs of
        %the programs. all saved files will be in this folder
        format shortg
        time=clock;
        f=num2str(fix(time));
        f= datestr(now);
        f = strrep(f,'    ','');
        f = strrep(f,'-','');
        f = strrep(f,':','');
        oldFolder =cd(PathName);
        name=['Results_' f];
        mkdir(name);
        s= PathName;
        s= [s name];
        cd(oldFolder);
        
        %blue data
        if red_assay==false || both==true
            filename = ['Blue Density of ' name '.csv'];
            imagename = ['Blue Density colormap of ' name '.fig'];
            %Colormap
            savefig(pic(1),fullfile(s,imagename));
            %BlueDensity csv file
            csvwrite(fullfile(s,filename) ,blueDensity);
            %plots
            imagename =['Blue vs IPTG, ' name  '.fig'];
            savefig(plots(1),fullfile(s,imagename));
        end
        
        %red data
        if red_assay==true || both==true
            filename = ['Red Density of ' name  '.csv'];
            imagename = ['Red Density colormap of ' name  '.fig'];
            %Colormap
            savefig(pic(2),fullfile(s,imagename));
            %RedDensity csv file
            csvwrite(fullfile(s,filename) ,redDensity);
            %plots
            imagename =['Red vs IPTG, ' name  '.fig'];
            savefig(plots(2),fullfile(s,imagename));
        end
        
        %image with circles
        imagename =[ name '_circles.fig'];
        savefig(pic(4),fullfile(s,imagename));
        
        %if stiched image created, saves it seperately
        
            pic(5)= figure('name','Stiched Image');
            imshow(stich);
            imagename = [name '.fig'];
            savefig(pic(5), fullfile(s,imagename));
            close(pic(5));

    case 'No'
    case ''
        return;
end