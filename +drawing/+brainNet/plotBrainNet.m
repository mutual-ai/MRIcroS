function plotBrainNet(v, nodes, edges, colorMap)
%function plotBrainNet(v, nodes, edges)
%inputs:   
%   nodes
%   edges: set to [] if none should be plotted
%   colorMapFn (optional): map for the node color function, default is jet
%http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pone.0068910

if nargin < 3, colorMap = 'jet'; end;

xCs = nodes(:,1); %X coordinate
yCs = nodes(:,2); %Y coordinade
zCs = nodes(:,3); %Z coordinate
rads = nodes(:,5); %Radius
cols = nodes(:,4); %color

numNodes = size(nodes, 1);
nodeColors = utils.magnitudesToColors(cols./max(cols), colorMap);
%plot nodes
v = guidata(v.hMainFigure);%load data
layer = utils.fieldIndex(v, 'surface');
v.surface(layer).colorMap = utils.colorTables(1);
v.surface(layer).colorMin = 0;
[xSph, ySph, zSph] = sphere(12); 
FV = surf2patch(xSph, ySph, zSph,'triangles'); %use triangles to save to PLY

half = size(FV.faces,1);
%FV.faces(1:half, :) = fliplr(FV.faces(1:half,:))
FV.faces(half+1:end, :) = fliplr(FV.faces(half+1:end,:));
%FV.faces(:, :) = fliplr(FV.faces(:,:));


nFaces = size(FV.vertices,1);
vtxs = [];%zeros(nFaces*numNodes, 3);
facs = [];%zeros(size(FV.faces,1), 3);
clrs = [];
for i = 1:numNodes
  fac = FV.faces + ((i-1) * nFaces);
  vtx = FV.vertices;
  vtx(:,1) = vtx(:,1).*rads(i) + xCs(i);
  vtx(:,2) = vtx(:,2).*rads(i) + yCs(i);
  vtx(:,3) = vtx(:,3).*rads(i) + zCs(i);
  clr = repmat(nodeColors(i,:),[nFaces,1]);
  vtxs = [vtxs; vtx]; %#ok<AGROW>
  facs = [facs; fac]; %#ok<AGROW>
  clrs = [clrs; clr]; %#ok<AGROW>
end 
v.surface(layer).faces = facs;%FV.faces;
v.surface(layer).vertices = vtxs;%FV.vertices;
v.surface(layer).vertexColors = clrs;
v.vprefs.colors(layer,4) = 1.0;

if isempty(edges);
    guidata(v.hMainFigure, v); %save data
    drawing.redrawSurface(v);     
    return;
end;
    
if(numel(edges) > length(nodes)^2)
    error('num edges (%d) must be less than the square of num nodes (%d)',...
        numel(edges), length(nodes));
end

edgesBinary = edges ~= 0 & ~tril(edges);
%several times faster than double for loop
xStarts = bsxfun(@times, edgesBinary, xCs);
xStops = bsxfun(@times, edgesBinary, xCs');
yStarts = bsxfun(@times, edgesBinary, yCs);
yStops = bsxfun(@times, edgesBinary, yCs');
zStarts = bsxfun(@times, edgesBinary, zCs);
zStops = bsxfun(@times, edgesBinary, zCs');
edgeIdxs = find(edgesBinary);
numEdges = sum(edgesBinary(:));

usedEdges = edges(edgeIdxs);

edgeRange =max(usedEdges(:)) -  min(usedEdges(:)); %'range' does not exist in Matlab 2012
if edgeRange > 0
    normalizedEdges = (edges(:) - min(usedEdges(:)))./edgeRange;
else
    normalizedEdges = edges(:)/max(usedEdges(:));
end
%normalizedEdges = (edges(:) - min(edges(:)))./range(edges(:));
kThick = 2;
edgeColors = utils.magnitudesToColors(normalizedEdges, colorMap);

%add new faces, vertices and vertex colors...
vtxs = [];%faster if preallocated: zeros(nFaces*numNodes, 3);
facs = [];%faster if preallocated: zeros(size(FV.faces,1), 3);
clrs = [];%faster if preallocated: 
nTri = max(v.surface(layer).faces(:));
for i = 1:numEdges
    edgeIdx = edgeIdxs(i);
    startXYZ = [xStarts(edgeIdx), yStarts(edgeIdx), zStarts(edgeIdx)];
    endXYZ = [xStops(edgeIdx), yStops(edgeIdx), zStops(edgeIdx)];
    %edgeW = edges(edgeIdx);
    edgeW = normalizedEdges(edgeIdx) * kThick;
    FV = cylinderSubX(startXYZ, endXYZ, edgeW);
    newTri = max(FV.faces(:));
    FV.faces = FV.faces + nTri;
    nTri = nTri + newTri;
    vtxs = [vtxs; FV.vertices]; %#ok<AGROW>
    facs = [facs; FV.faces]; %#ok<AGROW>
    clr = repmat(edgeColors(edgeIdx,:),[newTri,1]);
    clrs = [clrs; clr]; %#ok<AGROW>
end
v.surface(layer).faces = [v.surface(layer).faces; facs];
v.surface(layer).vertices = [v.surface(layer).vertices; vtxs];%FV.vertices;
v.surface(layer).vertexColors = [v.surface(layer).vertexColors; clrs];
%save...
guidata(v.hMainFigure, v); %save data
drawing.redrawSurface(v);  
%end plotBrainNet()

function FV = cylinderSubX(startXYZ, endXYZ, radius)
%Generate cylinder between two points with specified radius
% startXYZ : coordinate of starting point
% endXYZ : coordinate of ending point
% radius : how thick is the tube?
%Example 
% cylinderSub([0 0 0],[10 1 0],0.1)
%Update Chris Rorden Oct 2015: only applies matrix once instead of four times 
%
len =norm(startXYZ-endXYZ); %length
[CZ,CY,CX] = cylinder; %create unit cylinder from 0,0,0 to 0,0,1
%scale, note length is X axis
CZ = CZ * radius;
CY = CY * radius;
CX = CX *len;
[row, col] = size(CX);    
%rotate
newEll = rotatePointsSub(endXYZ - startXYZ, [CX(:), CY(:), CZ(:)]);
%translate 
stemX = reshape(newEll(:,1), row, col)+ startXYZ(1);
stemY = reshape(newEll(:,2), row, col)+ startXYZ(2);
stemZ = reshape(newEll(:,3), row, col)+ startXYZ(3);
FV = surf2patch(stemX,stemY,stemZ,'triangles'); 
%patch(FV)
%end cylinderSub()

function rotatedData = rotatePointsSub(alignmentVector, originalData)
%http://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d
B = alignmentVector'/norm(alignmentVector);
A=[-1 0 0]'; 
GG = [ dot(A,B) -norm(cross(A,B)) 0;
              norm(cross(A,B)) dot(A,B)  0;
              0              0           1];
FFi = [ A (B-dot(A,B)*A)/norm(B-dot(A,B)*A) cross(B,A) ];
UU = FFi*GG/FFi;%UU = FFi*GG*inv(FFi);
UU = -UU;
rotatedData = originalData*UU';
%end rotatePointsSub()
