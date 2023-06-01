function x = dispersePointsByAxis(y,xJitterRange,nReps,markerPixels,axisToUse)

if (~exist('axisToUse','var'))
    axisToUse = gca;
end
pixPos = getpixelposition(axisToUse);
% [distance from left, distance from bottom, width, height]
widthPixels = pixPos(3);
heightPixels = pixPos(4);
widthUnits = diff(xlim(axisToUse));
heightUnits = diff(ylim(axisToUse));
widthPixelsPerUnit = widthPixels./widthUnits;
heightPixelsPerUnit = heightPixels./heightUnits;
yScaleFactor = widthPixelsPerUnit./heightPixelsPerUnit;
minDistXPixels = markerPixels.*1.55; %./0.7;
minDistanceInXUnits = minDistXPixels./widthPixelsPerUnit;
x = dispersePoints(y,yScaleFactor,xJitterRange,minDistanceInXUnits,nReps);