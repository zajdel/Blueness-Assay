function [ centersStrong96_new, radiiStrong96_new ] = circle_adjust_multiple(centersStrong96, radiiStrong96)
%this function will take user input to adjust all circles' X and Y
%coordinates as well as change the radii

centersStrong96_new = centersStrong96;
radiiStrong96_new = radiiStrong96;
done = false;
while ~done
    answer = inputdlg({'Enter desired shift(in pixels) along the X-axis: ','Enter desired shift(in pixels) along the Y-axis:','Input desired increase or decrease (in pixels) of radii: '},'Multiple Cicle Adjustment',1);
    if isempty(answer)
        break;
    else
        xmove= str2num(answer{1});
        ymove= str2num(answer{2});
        radadjust = str2num(answer{3});
    end
    if ~isempty(xmove)&& ~strcmp(xmove,'0')
        shift=[ones(size(centersStrong96,1),1) zeros(size(centersStrong96,1),1)]*xmove;
        centersStrong96_new = centersStrong96_new+shift;
    end
    if ~isempty(ymove)&& ~strcmp(ymove,'0')
        shift=[zeros(size(centersStrong96,1),1) ones(size(centersStrong96,1),1) ]*ymove;
        centersStrong96_new = centersStrong96_new+shift;
    end
    if ~isempty(radadjust) && ~strcmp(radadjust,'0')
        shift=ones(size(radiiStrong96,1),1)*radadjust;
        radiiStrong96_new =radiiStrong96_new+shift;
    end 
    %redraw circles
    h=findobj('type','line');
    for n= 1:size(h,1)
        delete(h(n))
    end 
    a = viscircles(centersStrong96_new, radiiStrong96_new , 'EdgeColor','m');    
    choice = questdlg('Readjust desired?','Readjustment','Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
        case 'No'
            done = true;
    end
end

%redraw circles
h=findobj('type','line');
for n= 1:size(h,1)
    delete(h(n))
end
viscircles(centersStrong96_new, radiiStrong96_new,'EdgeColor','b');

end

