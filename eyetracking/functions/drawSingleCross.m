function drawSingleCross(pos, oriT, scr, color, w, lineWidth)
%
% draw a oriented T on the offscreen canvas
% flankers are verticaly aligned
% all measures in pixels
%
% - pos: [x, y] (integer)
% - w: (scalar, integer) length (=height) of each T element
% - oriT: (scalar, integer) 1 to 4, corresponding to 90deg, 0deg, 270deg, 180deg
%
% Matteo Lisi, 2020

if nargin < 4; w = 12; end
if nargin < 5; lineWidth = 1; end

pos = repmat(pos(:),1,4);

% coordinates of upward (90deg) T, centered on [0, 0]
xy0 = [-w/2, w/2, 0, 0 ; -0, 0, -w/2, w/2];

% target coordinates
xyT = pos + rotationMatrix(oriT) * xy0; 


% draw everything
Screen('DrawLines', scr, xyT, lineWidth, color);
end

function m = rotationMatrix(i)
switch i
    case 1 % 90 deg (identity matrix, rotation not needed)
        m = [1,0;0,1];
    case 2 % 0 deg; rotation of -90 (in screen coordinates y = -y)
        m = [0,-1;1,0];
    case 3 % 270 deg; rotation of +180deg
        m = [-1,0;0,-1];
    otherwise % 180 deg, roation of +90deg
        m = [0,1;-1,0];
end
end 