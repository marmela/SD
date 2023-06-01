function iSdPerSdPressure = getSdPeriodEpochsISI(statePerIsi,sleepStateToScoreValue,...
    iSdPerSdPressureStim,stimOnsetSec)
nSdPeriods = length(iSdPerSdPressureStim);
maxTimeSecPerPeriod = nan(nSdPeriods,1);
minTimeSecPerPeriod = nan(nSdPeriods,1);
for iSdPeriod = 1:nSdPeriods
    currentStimTime = stimOnsetSec(iSdPerSdPressureStim{iSdPeriod});
    maxTimeSecPerPeriod(iSdPeriod) = max(currentStimTime);
    minTimeSecPerPeriod(iSdPeriod) = min(currentStimTime);
end
assert(all(maxTimeSecPerPeriod(1:end-1)<minTimeSecPerPeriod(2:end))); %make sure that divided according to consecutive sd pressure periods
for iEdgeBetweenPeriods = 1:nSdPeriods-1
    edgeBetweenPeriodsSec(iEdgeBetweenPeriods) = (maxTimeSecPerPeriod(iEdgeBetweenPeriods)+...
        minTimeSecPerPeriod(iEdgeBetweenPeriods+1))/2;
end
edgeBetweenPeriodsSec = [minTimeSecPerPeriod(1), edgeBetweenPeriodsSec, maxTimeSecPerPeriod(end)];
isQwSd = cell2mat(extractfield(statePerIsi,'isDuringSd')) & ...
    extractfield(statePerIsi,'scoring')==sleepStateToScoreValue('Q-Wake');
onsetSec = extractfield(statePerIsi,'onsetSec');
for iSdPeriod = 1:nSdPeriods
        iSdPerSdPressure{iSdPeriod} = find(onsetSec>=edgeBetweenPeriodsSec(iSdPeriod) & ...
            onsetSec<edgeBetweenPeriodsSec(iSdPeriod+1) & isQwSd);
end