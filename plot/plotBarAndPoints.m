function currentStateXLoc = plotBarAndPoints(values, xLoc, xJitterRange, nReps, ...
    markerPixels, iExamplePerUnit,barColor,maxAbsValueToPlot)

if (~exist('iExamplePerUnit','var'))
    iExamplePerUnit = nan(length(values),1);
end
if ~exist('barColor','var') || isempty(barColor)
    barColor = [0.85,0.85,0.85];
end
if exist('maxAbsValueToPlot','var')
    values(abs(values)>maxAbsValueToPlot) = maxAbsValueToPlot*sign(values(abs(values)>maxAbsValueToPlot));
end

BAR_LINE_WIDTH = 1.5; %1.25;
MARKER_FACE_COLOR = [0.65,0.65,0.65];
MARKER_EDGE_COLOR = MARKER_FACE_COLOR;%'none'; %'k';
SEM_LINE_WIDTH = 4.5; %4.5;
SEM_COLOR = 'k';
BAR_WIDTH = 0.95;

meanVal = nanmean(values);
sem = nanstd(values)./sqrt(sum(~isnan(values)));
currentStateXLoc = xLoc+dispersePointsByAxis(values,xJitterRange,nReps,markerPixels);
bar(xLoc,meanVal,BAR_WIDTH,'FaceColor',barColor)%,'LineWidth',2);
isExampleUnit = ~isnan(iExamplePerUnit);
plot(currentStateXLoc(~isExampleUnit),values(~isExampleUnit),'o','MarkerSize',markerPixels,...
    'MarkerFaceColor', MARKER_FACE_COLOR,'MarkerEdgeColor',MARKER_EDGE_COLOR,'LineWidth',0.25)
bar(xLoc,meanVal,BAR_WIDTH,'FaceColor','none','LineWidth',BAR_LINE_WIDTH);
plot([xLoc,xLoc],[meanVal-sem,meanVal+sem],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)