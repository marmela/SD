function [latency,p,pPerTimePoint,timesMs] = calcPeakLatency(raster, timesMs, gaussWinSizeMs, ...
    baselineTimesMs,onsetTimesMs,alphaStat)
sampleMs = mean(diff(timesMs));
sigma = gaussWinSizeMs./sampleMs;
nPoints = round(sigma*6); %3 Std Deviations.
win = getGaussWin(sigma,nPoints)';
rasterSmoothed = conv2(full(raster),win,'same');
MIN_PEAK_FR_TO_BASELINE_RATIO = 2;

isValidTimePoint = true(1,length(timesMs));
isValidTimePoint(1:ceil(nPoints/2)) = false;
isValidTimePoint(end-ceil(nPoints/2)+1:end) = false;

timesMs(~isValidTimePoint) = [];
raster(:,~isValidTimePoint) = [];
rasterSmoothed(:,~isValidTimePoint) = [];

iLastBaseline = find(timesMs>=baselineTimesMs(1) & timesMs<baselineTimesMs(2),1,'last')-nPoints;

iOnsetTimePoints = find(timesMs>=onsetTimesMs(1) & timesMs<onsetTimesMs(2));

baselineSpikeProb = rasterSmoothed(:,iLastBaseline);

nValidTimePoints = length(iOnsetTimePoints);
pPerBin = nan(1,nValidTimePoints);
for iTimePoint = 1:nValidTimePoints
    pPerTimePoint(iTimePoint) = ranksum(baselineSpikeProb,rasterSmoothed(:,iOnsetTimePoints(iTimePoint)));
end

psthSmoothed = mean(rasterSmoothed,1);
iSigWithinOnset = find(pPerTimePoint<alphaStat);
iSignificantTimePoint = iOnsetTimePoints(iSigWithinOnset);
meanBaselineSpikeProb = mean(baselineSpikeProb);
[maxSpikeProb, iMaxOfSignificant] = max(psthSmoothed(iSignificantTimePoint));
if maxSpikeProb>meanBaselineSpikeProb*MIN_PEAK_FR_TO_BASELINE_RATIO
    iPeakLatency = iSignificantTimePoint(iMaxOfSignificant);
    latency = timesMs(iPeakLatency);
    p = pPerTimePoint(iSigWithinOnset(iMaxOfSignificant));
else
    latency = nan;
    p = nan;
end
1;