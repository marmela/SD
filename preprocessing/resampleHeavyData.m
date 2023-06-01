function newData = resampleHeavyData(data,originalSr,desiredSr,methodStr)
nPointsOriginalData = length(data);
nPointsOriginalDataPerSeg = 1e7;
dataLengthSec = (nPointsOriginalData-1)/originalSr;
timesSecAfterInterpolation = 0:1/desiredSr:dataLengthSec;
nPointsNewData = length(timesSecAfterInterpolation);
newData = nan(1,length(timesSecAfterInterpolation),'like',data);
for segStartIndOriginData = 1:(nPointsOriginalDataPerSeg):nPointsOriginalData
    %(nPointsOriginalDataPerSeg+2) create a two samples overlap between adjacent segments
    segEndIndOriginData = min(segStartIndOriginData+nPointsOriginalDataPerSeg+2,nPointsOriginalData);
    segOriginDataTimes = (segStartIndOriginData-1:segEndIndOriginData-1)./originalSr;
    segStartIndNewData = find(timesSecAfterInterpolation>=segOriginDataTimes(1),1,'first');
    segEndIndNewData = find(timesSecAfterInterpolation<=segOriginDataTimes(end),1,'last');
    newData(segStartIndNewData:segEndIndNewData) = ...
        interp1(segOriginDataTimes,data(segStartIndOriginData:segEndIndOriginData),...
        timesSecAfterInterpolation(segStartIndNewData:segEndIndNewData),methodStr);
end

