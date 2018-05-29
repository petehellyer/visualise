function [FigureHandle,nodehandles,edgehandles] = ball_and_stick(ConnMat, ColorMat, Coordinates, Threshold, Overlay)
%BALL_AND_STICK visualises a connectivity matrix as a 3D ball and stick (in
%fancy pants 3D)
%diagram.
%
% TODO: Usage

%Sanity checking and defaults:
Coordinatescale = 0.2;
CC_cross=[-32 32];
Node_Size=20;
FigureHandle = 1;
Num_Segs=10;
Edge_width=5;
nodecolor='white';

CC_cross = CC_cross*Coordinatescale;
[d, e] = size(ConnMat);
if d ~= e
    error('Thickness matrix must be square.');
end

[points, f] = size(Coordinates);
if f ~= 3
    error('xyz matrix must be of width 3');
end

if points ~= d
    error('Width of Thickness must equal height of xyz.');
end
if nargin < 4
    Threshold = 100;
end
if nargin < 5
    dooverlay=false;
end
if nargin >= 5
    if exist('overlay')
        dooverlay = true;
    end
end

% Scale the coordinate system
Coordinates = Coordinates*Coordinatescale;
%Threshold the Connectivity matrix to keep Threshold% of the top edges.
[Sorted,Index]=sort(abs(ConnMat(:)),'descend');
cutoff = ceil((numel(find(Sorted>0))./100)*Threshold);
ConnMat(Index(cutoff:end)) = 0;
%Threshold ColorMat to match ConnMat
ColorMat = ColorMat.*(abs(ConnMat)>0);
FigureHandle = figure(FigureHandle);
%set the Figure renderer to something sensible.
set(FigureHandle,'Renderer','zbuffer');
%set background to black
set(FigureHandle,'Color',[.2 .2 .2]);

%plot out the graph nodes (as white spheres)
for i = 1:size(Coordinates,1)
    [X,Y,Z] = sphere(Num_Segs);
    X=X*Node_Size;
    Y=Y*Node_Size;
    Z=Z*Node_Size;
    nodehandles(i) = surf(X+Coordinates(i,1),Y+Coordinates(i,2),Z+Coordinates(i,3),'EdgeColor','none','FaceColor',nodecolor,'FaceLighting','gouraud');
    hold on
end

%now plot out the edges, in color
%create a rather large colourmap
cmap = hot(1000);
%loop through all of the edges of the network.
for i = 1:d
    for j = i:d
        %plot the connection if it is nonzero.
        if abs(mean([ConnMat(i,j) ConnMat(j,i)])) ~= 0
            %create some vectors for the start and end of each node.
            r1=[Coordinates(i,1) Coordinates(i,2) Coordinates(i,3)];
            r2=[Coordinates(j,1) Coordinates(j,2) Coordinates(j,3)];
            %work out the plot color.
            colour_tmp = mean([ColorMat(i,j) ColorMat(j,i)]);
            tmp = ceil((colour_tmp-min(ColorMat(ColorMat>0)))/diff([min(ColorMat(ColorMat>0)) max(ColorMat(ColorMat>0))])*1000);
            colour_tmp = cmap(max([1 tmp]),:);
            %work out if our line crosses the midline (of MNI)
            mid_cross = false;
            if r1(1) < 0 && r2(1) > 0
                mid_cross = false;
            end
            if r1(1) > 0 && r2(1) < 0
                mid_cross = false;
            end
            %if lines cross the midline, make them pass though CC_cross
            if mid_cross
                CC_diff = diff(CC_cross);
                %work out the bounds of all nodes in plot
                miny=min(Coordinates(:,2));
                maxy=max(Coordinates(:,2));
                IM_diff = diff([miny maxy]);
                %work out how many percent along the image the start node is
                perseed=(r1(2)+abs(miny))./IM_diff;
                diffy=(CC_diff*perseed)+CC_cross(1);
                xpoint = [0 diffy 14];
                values = [r1' xpoint' r2'];
                %interpolate the line and calulate a surface
                values = interparc(0:0.1:1,values(1,:),values(2,:),values(3,:));
                [X,Y,Z]=tubeplot(values',Edge_width,Num_Segs);
            else
                %else it's a dead easy two point line.
                [X,Y,Z]=tubeplot([r1' r2'],Edge_width,Num_Segs);
            end
            edgehandles(i,j) = surf(X,Y,Z,'EdgeColor','none','FaceColor',colour_tmp,'FaceLighting','gouraud');
            hold on
            
        end
    end
end

%now do a slice overlay if requested (note this is optimised for MNI152)
if dooverlay
    niftiimage=load_nifti(overlay);
    y=(-72:109)*Coordinatescale;
    x=(-126:91)*Coordinatescale;
    [x,y] = meshgrid(x,y);
    z = ones(size(x));
    slice = squeeze(niftiimage.vol(80,:,:))';
    slicemask = slice;
    slicemask(slicemask>0) = 1;
    RGB = label2rgb(slice,@gray);
    %TODO SET ALPHADATA such that BLACK IS TRANSPARENT
    surf(z, x, y,RGB,'FaceColor','texturemap','EdgeColor','none','FaceLighting','none','FaceAlpha',0.5,'AlphaData',slicemask)
    
end
%finally set a few axis settings.
axis off equal tight vis3d
camproj('perspective')
light
hold off
end