function [latency,p,pPerBin] = calcDiffFromBaselineLatency(raster, timesMs, binSizeMs, ...
    baselineTimesMs,onsetTimesMs,alphaStat)
raster = full(raster);
nSamplesBin = round(binSizeMs./mean(diff(timesMs)));
edgesOnsetTimesMs = onsetTimesMs(1):binSizeMs:onsetTimesMs(2);
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

iBinSignificant = find(pPerBin<alphaStat,1,'first');
if isempty(iBinSignificant)
    latency = nan;
    p = min(pPerBin);
else
    latency = mean(edgesOnsetTimesMs(iBinSignificant:iBinSignificant+1));
    p = pPerBin(iBinSignificant);
end
1;