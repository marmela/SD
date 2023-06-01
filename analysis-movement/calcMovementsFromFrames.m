function [movement, location, angleBetweenBodyParts, distanceBetweenBodyParts, ...
    probLikelyPerBodyPart, probLikelyTwoBodyParts, bodyParts] = calcMovementsFromFrames( ...
    xTable, yTable, likelihoodTable, timeSec, minLikelihood)

bodyParts = likelihoodTable.Properties.VariableNames;
nSamples = height(likelihoodTable);
nBodyParts = width(likelihoodTable);
assert(nSamples>0);
likelihoodArray = table2array(likelihoodTable);
isLikely = likelihoodArray>=minLikelihood;
probLikelyPerBodyPart = mean(isLikely);
xMat = table2array(xTable);
yMat = table2array(yTable);
location.x = nan(1,nBodyParts);
movement.x = nan(1,nBodyParts);
location.y = nan(1,nBodyParts);
movement.y = nan(1,nBodyParts);
angleBetweenBodyParts = nan(nBodyParts,nBodyParts);
distanceBetweenBodyParts = nan(nBodyParts,nBodyParts);
probLikelyTwoBodyParts = nan(nBodyParts,nBodyParts);
for iBodyPart = 1:nBodyParts
    location.x(iBodyPart) = mean(xMat(isLikely(:,iBodyPart),iBodyPart));
    movement.x(iBodyPart) = std(xMat(isLikely(:,iBodyPart),iBodyPart));
    location.y(iBodyPart) = mean(yMat(isLikely(:,iBodyPart),iBodyPart));
    movement.y(iBodyPart) = std(yMat(isLikely(:,iBodyPart),iBodyPart));
end
for iBodyPart = 1:nBodyParts
    for iBodyPart2 = iBodyPart+1:nBodyParts
        isLikelyBothParts = all(isLikely(:,[iBodyPart,iBodyPart2]),2);
        diffX = diff(mean(xMat(isLikelyBothParts,[iBodyPart,iBodyPart2]),1));
        diffY = diff(mean(yMat(isLikelyBothParts,[iBodyPart,iBodyPart2]),1));
        probLikelyTwoBodyParts(iBodyPart,iBodyPart2) = mean(isLikelyBothParts);
        distanceBetweenBodyParts(iBodyPart,iBodyPart2) = sqrt(diffX.^2 + diffY.^2);
        % angle is inverted since y-coordinates are starting from top-left corner, so more
        % intuitive inverted
        angleBetweenBodyParts(iBodyPart,iBodyPart2) = -angle(diffX+diffY*1i);
    end
end

1;