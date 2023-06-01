function x = dispersePoints(y,yScaleFactor,xJitterRange,minDistanceInXUnits,nReps)

xHalfRange = xJitterRange./2;
y = makeColumn(y);
y = y./yScaleFactor;
nPoints = numel(y);
x = rand(nPoints,1)*2*xHalfRange-xHalfRange;
distMat = zeros(nPoints,nPoints);

for i1=1:nPoints
    for i2=i1+1:nPoints
        distMat(i1,i2) = sqrt((x(i2)-x(i1))^2+(y(i2)-y(i1))^2);
        distMat(i2,i1) = distMat(i1,i2);
    end
end

%%
for iRep = 1:nReps
    for i=1:nPoints
        if rand(1,1)<0.5
            newXValue = rand(1,1)*2*xHalfRange-xHalfRange;
        else
            newXValue = x(i)*0.095;
        end
        iNonCurrent = [1:i-1,i+1:nPoints];
        distVec = distMat(i,iNonCurrent);
        distVecNew = sqrt((x(iNonCurrent)-newXValue).^2+(y(iNonCurrent)-y(i)).^2);
        isSmallerThanMinDist =  distVec<minDistanceInXUnits;
        isSmallerThanMinDistNew = distVecNew<minDistanceInXUnits;
        if any(isSmallerThanMinDist)
            if sum(isSmallerThanMinDist)>sum(isSmallerThanMinDistNew)
                distMat(i,iNonCurrent) = distVecNew;
                distMat(iNonCurrent,i) = distVecNew;
                x(i) = newXValue;
            elseif sum(isSmallerThanMinDist)==sum(isSmallerThanMinDistNew)
                if mean(distVec(isSmallerThanMinDist))< mean(distVecNew(isSmallerThanMinDistNew))
                    distMat(i,iNonCurrent) = distVecNew;
                    distMat(iNonCurrent,i) = distVecNew;
                    x(i) = newXValue;
                end
            end
        elseif ~any(isSmallerThanMinDistNew)
            if nanmean(distVec)>nanmean(distVecNew) %make points closer
                distMat(i,iNonCurrent) = distVecNew;
                distMat(iNonCurrent,i) = distVecNew;
                x(i) = newXValue;
            elseif rand(1,1)<exp(-20*iRep./nReps)*0.1
                distMat(i,iNonCurrent) = distVecNew;
                distMat(iNonCurrent,i) = distVecNew;
                x(i) = newXValue;
            end
        end
    end
end

x = x-mean(x);
if any(x<-xHalfRange)
    x = x - xHalfRange - min(x);
elseif any(x>xHalfRange)
    x = x + xHalfRange - max(x);
end