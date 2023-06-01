function plotBackground( X, Y, BOTTOM_DEV,UP_DEV, c, alphaValue)
% Plot Backround around graph Y=f(X) in size of (vector) DEV and color c.
% If Y is a single value (length=1) the backround will not follow the
% graph. For example put Y = 0 to make the backround mark the specific area
% on the graph.
% Default color is blue ('b').

if (~exist('alphaValue','var'))
    alphaValue = 0.25;
end

if nargin < 4
   c = 'b'; 
end

if size(Y,1)>size(Y,2)
    Y = Y';
end

if size(X,1)>size(X,2)
    X = X';
end

if size(UP_DEV,1)>size(UP_DEV,2)
    UP_DEV = UP_DEV';
end

if size(BOTTOM_DEV,1)>size(BOTTOM_DEV,2)
    BOTTOM_DEV = BOTTOM_DEV';
end

if length(Y) == 1
    Y = ones(size(X))*Y;
end

ebars=patch([X,fliplr(X)],[Y-BOTTOM_DEV,fliplr(Y+UP_DEV)],c);
set(ebars,'EdgeColor','none');

global isForIllustrator
if (isempty(isForIllustrator) || ~isForIllustrator)
    alpha(alphaValue);
else
    alpha(alphaValue);
end


end