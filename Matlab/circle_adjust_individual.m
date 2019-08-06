function [ centersStrong96_new, radiiStrong96_new ] = circle_adjust_individual(centersStrong96,radiiStrong96)
%This identifies an individual circle as allows for manipulation in terms of
%coordinates and radius. able to repeat for multiple individual circles
%%
centersStrong96_new = centersStrong96;
radiiStrong96_new = radiiStrong96;
c = viscircles(centersStrong96, radiiStrong96,'EdgeColor','b');
pCols=12;
pRows=8;
a= viscircles([0 0],0);
%assign numbers to each circle to allow for percise manipulation

%Move centroids to the nearest pixels
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

%cell array of all wells, in order by row/column. create map for easy
%access
n=1;
m=1;
A=cell(8,12);
while n<=8
    row_n = find(row==n);
    while m<=12
        for idx =1: numel(row_n)
            if column(row_n(idx))== m
                A{n,m}={centersStrong96(row_n(idx),:),radiiStrong96(row_n(idx))};
                m=m+1;
            end
        end
    end
    m=1;
    n=n+1;
end
%%

done = false;
while ~done
    answer = inputdlg({'row #:','column #:'},'Choose circle for modification',1,{'',''});
    if isempty(answer) || numel(answer)<2
        break;
    else
        circle_location = A{str2num(answer{1}),str2num(answer{2})}{1};
        circle_radius = A{str2num(answer{1}),str2num(answer{2})}{2};
        a = viscircles(circle_location,circle_radius,'EdgeColor','m');
        [~, index] = ismember(circle_location, centersStrong96, 'rows');
    end
    
    %% carryout adjustment of individual circle
    complete = false;
    while ~complete
        answer = inputdlg({'Enter desired shift(in pixels) along the X-axis: '},'X-axis shift',1);
        if isempty(answer)
            break;
        else
            move= str2num(answer{1});
        end
        if ~isempty(move)&& ~strcmp(move,'0')
            shift=[1,0]*move;
            centersStrong96_new(index,:) = centersStrong96_new(index,:)+shift;
            delete(a)
            a=viscircles(centersStrong96_new(index,:), radiiStrong96_new(index),'EdgeColor','m');
        end
        choice = questdlg('Readjust desired?','X-axis Readjustment','Yes','No','No');
        % Handle response
        switch choice
            case 'Yes'
            case 'No'
                complete=true;
        end
    end
    %Y-axis shift
    complete = false;
    while ~complete
        answer = inputdlg({'Input desired shift(in pixels) along the Y-axis: '},'Y-axis shift',1);
        if isempty(answer)
            break;
        else
            move2= str2num(answer{1});
        end
        if ~isempty(move)&& ~strcmp(move,'0')
            shift=[0,1]*move2;
            centersStrong96_new(index,:) = centersStrong96_new(index,:)+shift;
            delete(a)
            a=viscircles(centersStrong96_new(index,:), radiiStrong96_new(index),'EdgeColor','m');
        end
        choice = questdlg('Readjust desired?','Y-axis Readjustment','Yes','No','No');
        % Handle response
        switch choice
            case 'Yes'
            case 'No'
                complete= true;
        end
    end
    %radii length
    complete = false;
    while ~complete
        answer = inputdlg({'Input desired increase or decrease (in pixels) of radii: '},'Radius adjustment',1);
        if isempty(answer)
            break;
        else
            adjust = str2num(answer{1});
        end
        
        if ~isempty(adjust) && ~strcmp(adjust,'0')
            radiiStrong96_new(index,:) = radiiStrong96_new(index,:)+adjust;
            delete(a)
            a=viscircles(centersStrong96_new(index,:), radiiStrong96_new(index),'EdgeColor','m');
        end
        choice = questdlg('Readjust desired?','Radius Readjustment','Yes','No','No');
        % Handle response
        switch choice
            case 'Yes'
            case 'No'
                complete= true;
        end
    end
    
    delete(c);
    c=viscircles(centersStrong96_new, radiiStrong96_new,'EdgeColor','b');
    %%
    
    choice = questdlg('Adjust another circle?','Individual Cirlce Adjustment','Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
        case 'No'
            done = true;
    end
end

delete(a);
delete(c);
viscircles(centersStrong96_new, radiiStrong96_new,'EdgeColor','b');

end

