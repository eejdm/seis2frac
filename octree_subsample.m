function [OT,eqs]=octree_subsample(eqs,binCapacity,gridx,plot_figures,MOC,fault,style,gridShape)
%% OCTREE_SUBSAMPLE
% Script to subsample seismicity data
% Requires OcTree.m (edited by JDM)
% https://au.mathworks.com/matlabcentral/fileexchange/40732-octree-partitioning-3d-points-into-spatial-subvolumes
% To use ^ version, just remove 'Division' option from OcTree function
%
% Inputs :
%     eqs              : Matrix of seismic data, with Lon, Lat, Depth, Magnitude in columns 1:4
%     binCapacity      : Maximum number of events per bin
%     gridx            : Minimum size of bin
%     plot_figures     : Plot flag
%     MOC (optional)   : Magnitude of Completion (subsampling based on this events above this limit
%     fault (optional) : 4*3 matrix of fault corners (for plotting)
%     style            : OcTree division method ('Normal' or 'Weighted')
%     gridShape        : 'Rectangle' - default subsample or 'Cube' - subsamples as cubes
%
% Outputs
%     OT               : Octree Structure
%     eqs              : Matrix of seismic data inside the bins
%
%     Jack McGrath, University of Leeds, 2021
%     Mar 21 : JDM, Initial commit
rotatedata=1;
if exist('MOC')~=1
    MOC = -Inf;
end

if exist('fault')~=1
    fault=nan(4,3);
    rotatedata=0;
end

if rotatedata==1 % Rotate data so that grid will be fault parallel
    bearing=atand((fault(2,1)-fault(1,1))/(fault(2,2)-fault(1,2)));
    rotation_angle = -(bearing-90)*pi/180;     % [rad]
Rotation_matrix = [cos(rotation_angle)  -sin(rotation_angle); % Rotating matrix for the local reference frame
sin(rotation_angle)  cos(rotation_angle)];
eqs(:,[1:2]) = (Rotation_matrix\eqs(:,[1:2])')'; % performing the rotation of the data
fault(:,[1 2]) = (Rotation_matrix\fault(:,[1:2])')';
end




OTeqs=eqs(eqs(:,4)>=MOC,:); % Variable to search only for events above MOC

OT = OcTree(OTeqs(:,[1:3]),'binCapacity',binCapacity,'minSize',gridx,'style',style,'grdShape',gridShape); % OcTree sub-sample

% Identify the bins that contain events > MOC
[uniqueBins,~,uBix]=unique(OT.PointBins);

% Add all events to bins
OT.PointBins=OT.query(eqs(:,[1:3])); % Find bins for all data (inc. event < MOC)
OT.Points=eqs(:,[1:3]); % Add locations of all events to variable

% Remove bins that do not contain an event > MOC
OT.BinCount=length(uniqueBins);
OT.BinBoundaries=OT.BinBoundaries(uniqueBins,:);
OT.BinDepths=OT.BinDepths(:,uniqueBins);
OT.BinParents=OT.BinParents(:,uniqueBins);
[in,ix]=ismember(OT.PointBins,uniqueBins); % Indicies of all events in kept bins
OT.Points=OT.Points(in,:);
OT.PointBins=ix(find(ix));
eqs=eqs(in,:);

    %%
    figure;
    figname='OcTree Subsample rotated';
    set(gcf,'renderer','zbuffer','name',figname); title(figname);
    hold on
    boxH = OT.plot;
    cols = lines(OT.BinCount);
    doplot3 = @(p,varargin)plot3(p(:,1),p(:,2),p(:,3),varargin{:});
    for i = 1:OT.BinCount
        set(boxH(i),'Color',cols(i,:),'LineWidth', 1)
        doplot3(eqs(OT.PointBins==i,:),'.','Color',cols(i,:))
    end
    plot3(fault([1 2 4 3 1],1),fault([1 2 4 3 1],2),-fault([1 2 4 3 1],3),'LineWidth',3,'Color','k');
    xlabel('Parallel');ylabel('Perpendicular');zlabel('Depth');pbaspect([1 1 1]);
    axis image, view(3)

if rotatedata==1 % Rotate data back into unrotated form
rotation_angle = -(90-bearing)*pi/180;     % [rad]
Rotation_matrix = [cos(rotation_angle)  -sin(rotation_angle); % Rotating matrix for the local reference frame
sin(rotation_angle)  cos(rotation_angle)];
eqs(:,[1:2]) = (Rotation_matrix\eqs(:,[1:2])')'; % performing the rotation of the data
OT.Points(:,[1:2]) = (Rotation_matrix\OT.Points(:,[1:2])')';
OT.BinBoundaries(:,[1:2]) = (Rotation_matrix\OT.BinBoundaries(:,[1:2])')';
OT.BinBoundaries(:,[4:5]) = (Rotation_matrix\OT.BinBoundaries(:,[4:5])')';
fault(:,[1 2]) = (Rotation_matrix\fault(:,[1:2])')';

end


if plot_figures == 1
    %%
    figure;
    figname='OcTree Subsample unrotated';
    set(gcf,'renderer','zbuffer','name',figname); title(figname);
    hold on
    boxH = OT.plot;
    cols = lines(OT.BinCount);
    doplot3 = @(p,varargin)plot3(p(:,1),p(:,2),p(:,3),varargin{:});
    for i = 1:OT.BinCount
        set(boxH(i),'Color',cols(i,:),'LineWidth', 1)
        doplot3(eqs(OT.PointBins==i,:),'.','Color',cols(i,:))
    end
    plot3(fault([1 2 4 3 1],1),fault([1 2 4 3 1],2),-fault([1 2 4 3 1],3),'LineWidth',3,'Color','k');
    xlabel('Lon');ylabel('Lat');zlabel('Depth');pbaspect([1 1 1]);
    axis image, view(3)
    
end

end
    