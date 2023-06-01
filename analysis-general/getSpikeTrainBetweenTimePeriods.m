function spikeTrainPerPeriod = getSpikeTrainBetweenTimePeriods(spikeTimes, timePeriods, noiseTimePeriods)
MS_IN_1SEC = 1000;
isPeriodDuringNoise = getIfRangesIncludeValues(timePeriods,noiseTimePeriods(:,1)) | ...
    getIfRangesIncludeValues(timePeriods,noiseTimePeriods(:,2)) | ...
    getIfValuesWithinRanges(timePeriods(:,1),noiseTimePeriods);
if mean(isPeriodDuringNoise)>0.1
    warning('Excluded %d%% of trials because noisy spiking\n',mean(isPeriodDuringNoise))
end
timePeriods(isPeriodDuringNoise,:) = [];
nTimePeriods = size(timePeriods,1);
spikeTrainPerPeriod = cell(nTimePeriods,1);
for iPeriod = 1:nTimePeriods
    currentTimePeriod = timePeriods(iPeriod,:);
    currentTimePeriodMsRounded = round(currentTimePeriod*MS_IN_1SEC)./MS_IN_1SEC;
    spikeTimesCurrentPeriod = spikeTimes(spikeTimes>=currentTimePeriodMsRounded(1) & ...
        spikeTimes<currentTimePeriodMsRounded(2));
    spikeTimesCurrentPeriod = spikeTimesCurrentPeriod - currentTimePeriodMsRounded(1);
    nTimePointsCurrent = round(diff(currentTimePeriodMsRounded)*MS_IN_1SEC);
    isSpike = false(1,nTimePointsCurrent);
    isSpike(floor(spikeTimesCurrentPeriod*MS_IN_1SEC)+1) = true;
    spikeTrainPerPeriod{iPeriod} = isSpike;
end