function res = simulateClickResponsesByClickErp(clickErp,timesMs,sustainedTimeMs)

stimLengthMs = 500;
clickRateToSimulateHz = [10,20,30,40];

EPSILON = 0.001;
clickWindowMs = [0,500];

MS_IN_SEC = 1000;

assert(mean(diff(timesMs))==1)
sigmaMs = 2.5;
nPointsMs = ceil(sigmaMs*6);
smoothWin = getGaussWin(sigmaMs,nPointsMs);

isRelevantClickTime = timesMs>=clickWindowMs(1) & timesMs<clickWindowMs(2);
isBaselineTime = timesMs<0;

baselineFrHz = mean(clickErp(isBaselineTime));
clickSmoothedErp = conv(clickErp,smoothWin,'same');
minClickFr = min(clickSmoothedErp);
clickSmoothedErp = clickSmoothedErp(isRelevantClickTime)-baselineFrHz;
nDataPointsSmoothedErp = length(clickSmoothedErp);

nClicksToSimulate = length(clickRateToSimulateHz);

simClicksTimeMs = timesMs(find(timesMs>=-100,1,'first')):1:1000;
nDataPointsSim = length(simClicksTimeMs);
simulatedClicksResponses = ones(nClicksToSimulate,nDataPointsSim)*baselineFrHz;



isSustainedTime = timesMs>=sustainedTimeMs(1)-EPSILON & timesMs<sustainedTimeMs(2)-EPSILON;
timeMsDuringSustained = timesMs(isSustainedTime);
res.lockingPerClickRate = nan(nClicksToSimulate,1);
res.timesMs = simClicksTimeMs;
for iClickRate = 1:nClicksToSimulate
    currentClickRate = clickRateToSimulateHz(iClickRate);
    clickIsiMs = MS_IN_SEC./currentClickRate;
    clickTimesMs = 0:clickIsiMs:stimLengthMs+EPSILON;
    
    nClicks = length(clickTimesMs);
    for iClick = 1:nClicks
        iClickTime = find(simClicksTimeMs>=clickTimesMs(iClick),1,'first');
        simulatedClicksResponses(iClickRate,iClickTime:iClickTime+nDataPointsSmoothedErp-1)=...
            simulatedClicksResponses(iClickRate,iClickTime:iClickTime+nDataPointsSmoothedErp-1) + ...
            clickSmoothedErp;
    end
    
    timeRelativeToClickBinMs = floor(mod(timeMsDuringSustained,clickIsiMs)+1);
    maxTimeBins = max(timeRelativeToClickBinMs);
    meanPerBin = nan(1,maxTimeBins);
    for iBin=1:maxTimeBins
        meanPerBin(iBin) = mean(simulatedClicksResponses(iClickRate,iBin==timeRelativeToClickBinMs));
    end
    res.lockingPerClickRate(iClickRate) = max(meanPerBin)-min(meanPerBin);
end

res.minClickFr = minClickFr;
res.simClicksResponses = simulatedClicksResponses;
res.clickRates = clickRateToSimulateHz;


1;