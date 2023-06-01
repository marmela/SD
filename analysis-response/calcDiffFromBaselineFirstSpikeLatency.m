function [latency,p,pPerBin] = calcDiffFromBaselineFirstSpikeLatency(raster, timesMs, binSizeMs, ...
    baselineTimesMs,onsetTimesMs,alphaStat, minConescutiveSignficantBins)
raster = full(raster);
nSamplesBin = round(binSizeMs./mean(diff(timesMs)));
edgesOnsetTimesMs = onsetTimesMs(1):binSizeMs:onsetTimesMs(2)+binSizeMs*(minConescutiveSignficantBins-1);
assert(diff(baselineTimesMs)>=binSizeMs)
isLastBaselineBin = timesMs>=baselineTimesMs(2)-binSizeMs & timesMs<baselineTimesMs(2);
nSpikesPerTrialBaseline = sum(raster(:,isLastBaselineBin),2);
assert(sum(isLastBaselineBin)==nSamplesBin)
nBinsOnset = length(edgesOnsetTimesMs)-1;

pPerBin = nan(nBinsOnset,1);
for iBin = 1:nBinsOnset
    isDuringCurrentBin = timesMs>=edgesOnsetTimesMs(iBin) & timesMs<edgesOnsetTimesMs(iBin+1);
    assert(sum(isDuringCurrentBin)==nSamplesBin);
    nSpikesPerTrialOnsetCurrent = sum(raster(:,isDuringCurrentBin),2);
    pPerBin(iBin) = ranksum(nSpikesPerTrialBaseline,nSpikesPerTrialOnsetCurrent);
end

isSigConsecutiveBin = true(nBinsOnset-minConescutiveSignficantBins+1,1);
for iConsecutiveBin = 1:minConescutiveSignficantBins
    isSigConsecutiveBin = isSigConsecutiveBin & pPerBin(...
        iConsecutiveBin:nBinsOnset-minConescutiveSignficantBins+iConsecutiveBin)<alphaStat;
end
iBinSignificant = find(isSigConsecutiveBin,1,'first');
if isempty(iBinSignificant)
    latency = nan;
    p = nan;
else
    latency = mean(edgesOnsetTimesMs(iBinSignificant:iBinSignificant+1));
    p = pPerBin(iBinSignificant);
end
1;