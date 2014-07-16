% --- Save screenshot as bitmap image
function saveBitmap(v,varargin)
% inputs: filename
%MATcro('saveBitmap',{'myPicture.png'});
if (length(varargin) < 1), return; end;
filename = char(varargin{1});
%saveas(v.hAxes, filename,'png'); %<- save as 150dpi
print (v.hMainFigure, '-r600', '-dpng', filename); %<- save as 600dpi , '-noui'
%end saveBitmap()
