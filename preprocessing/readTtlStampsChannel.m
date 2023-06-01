function [stampValues,stampIndices,stampTimesSec] = readTtlStampsChannel (data,sr)

if (isrow(data))
    data = data';
end
nBits = TtlStampConsts.N_BITS;
rampSizeMs = 0;
zeroTimeMs = TtlStampConsts.ZERO_TIME_MS;
bitSizeMs = TtlStampConsts.BIT_SIZE_MS;
onsetTtlSizeMs = TtlStampConsts.ONSET_TTL_LENGTH_MS;
entireStampTimeLengthMs = TtlStampConsts.TTL_STAMP_LENGTH_MS;
nSamplesZero = max(round(sr*zeroTimeMs/1000),1);
nSamplesRamp = round(sr*rampSizeMs/1000);
nPeriBitSamples = nSamplesZero+nSamplesRamp;
proportionOfBitIgnoredAtEachEdge = 0.2;%0.1;
nPeriBitSamples = round(nPeriBitSamples+bitSizeMs/1000*sr*proportionOfBitIgnoredAtEachEdge);
nPeriBitSamples = min(nPeriBitSamples,round(bitSizeMs/1000*sr/2)-1);
[~,clustersMeans] = kmeans(randsample(data,min(1e7,length(data))),2); %[~,clustersMeans] = kmeans(data,2);
ttlThreshold = mean(clustersMeans);
isAboveThreshold = data>ttlThreshold;
aboveThresholdIndices = find(isAboveThreshold);
interOnesInterval = [Inf;diff(aboveThresholdIndices)];
minZeroSamplesBetweenStamps = entireStampTimeLengthMs/1000*sr; %max(onsetTtlSizeMs,bitSizeMs)*2/1000*sr; %entireStampTimeLengthMs/1000*sr;
isFirstStampBitOne = interOnesInterval>minZeroSamplesBetweenStamps;
firstStampBitIndices = aboveThresholdIndices(isFirstStampBitOne);
nStamps = length(firstStampBitIndices);
stampValues = nan(nStamps,1);
stampIndices = nan(nStamps,1);
for stampInd = 1:nStamps
    currentStampFirstInd = firstStampBitIndices(stampInd);%+1;
    bitsForCurrentStamp = nan(1,nBits);
    for bitInd = 1:nBits
        currentBitFirstIndex = currentStampFirstInd + ...
            ceil((onsetTtlSizeMs+(bitInd-1)*bitSizeMs)/1000*sr) + nPeriBitSamples;
        currentBitLastIndex =currentStampFirstInd + ...
            floor((onsetTtlSizeMs+bitInd*bitSizeMs)/1000*sr) - nPeriBitSamples;
        
        currentBitFractionAboveThreshold = mean(isAboveThreshold(currentBitFirstIndex:currentBitLastIndex));
        
        if (currentBitFractionAboveThreshold>0.25 && currentBitFractionAboveThreshold<0.75)
            warning('Possible bad bit reading: %d stamp, %d bit\n', stampInd,bitInd);
        end
        
        bitsForCurrentStamp(bitInd) = currentBitFractionAboveThreshold>0.5;
    end
    stampIndices(stampInd) = currentStampFirstInd;
    stampValues(stampInd) = bi2de(bitsForCurrentStamp);
end

stampTimesSec = stampIndices/sr;
end