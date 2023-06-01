function BP = bandpassHeavyData(timecourse, SamplingRate, low_cut, high_cut, filterOrder,isDataTypesSingle)
if (nargin<5)
    filterOrder = 2;
end
nPointsSignal = length(timecourse);
nPointsInSegment = max(SamplingRate*low_cut*2,5e7);
nPointsOverlap = round(nPointsInSegment/4);
nPointsToNotIncludeFromStartOfSegment = round(nPointsOverlap/2);
if (isDataTypesSingle)
    BP = nan(1,length(timecourse),'single');
else
    BP = nan(1,length(timecourse),'double');
end
segmentStartSampleInd = 1;
segmentEndSampleInd = min(nPointsInSegment,nPointsSignal);
if (isDataTypesSingle)
    BP(segmentStartSampleInd:segmentEndSampleInd) = (bandpass(...
        double(timecourse(segmentStartSampleInd:segmentEndSampleInd)),SamplingRate, ...
        low_cut, high_cut, filterOrder));
else
    BP(segmentStartSampleInd:segmentEndSampleInd) = (bandpass(...
        timecourse(segmentStartSampleInd:segmentEndSampleInd),SamplingRate, ...
        low_cut, high_cut, filterOrder));
end

while segmentEndSampleInd<nPointsSignal
    segmentStartSampleInd = segmentEndSampleInd-nPointsOverlap+1;
    segmentEndSampleInd = min(segmentStartSampleInd+nPointsInSegment-1,nPointsSignal);
    if (isDataTypesSingle)
        tempBandpass = (bandpass(...
            double(timecourse(segmentStartSampleInd:segmentEndSampleInd)),SamplingRate, ...
            low_cut, high_cut, filterOrder));
    else
        tempBandpass = (bandpass(...
            timecourse(segmentStartSampleInd:segmentEndSampleInd),SamplingRate, ...
            low_cut, high_cut, filterOrder));
    end
    
    BP(segmentStartSampleInd+nPointsToNotIncludeFromStartOfSegment:...
        segmentEndSampleInd) = tempBandpass(nPointsToNotIncludeFromStartOfSegment+1:end);
    clear tempBandpass
end