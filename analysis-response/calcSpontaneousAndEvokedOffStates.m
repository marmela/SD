function offState = calcSpontaneousAndEvokedOffStates(raster, timeMs,params)

midBaselineTimeMs = timeMs(1)/2;
baseFrTimes = [-1000,-500]; %Better to separate times for calculating baseline FR and off states because those can bias each other
isTimeToCalcBaselineFr = timeMs>=baseFrTimes(1) & timeMs<baseFrTimes(2);
postOnsetLengthMs = diff(params.postOnsetTimeMs);
isDuringPostOnset = timeMs>=params.postOnsetTimeMs(1) & timeMs<params.postOnsetTimeMs(2);
isDuringEqualLengthBaseline = timeMs>=-postOnsetLengthMs & timeMs<0;
nSpikesDuringBaselinePerTrial = sum(raster(:,isDuringEqualLengthBaseline),2);
nSpikesDuringPostOnsetPerTrial = sum(raster(:,isDuringPostOnset),2);
nAverageSpikesPerPeriod = mean(mean(raster(:,isTimeToCalcBaselineFr)))*sum(isDuringPostOnset);
offState.probNoSpikes.poisson = poisspdf(0,nAverageSpikesPerPeriod);
offState.probNoSpikes.baseline = mean(nSpikesDuringBaselinePerTrial==0);
offState.probNoSpikes.postOnset = mean(nSpikesDuringPostOnsetPerTrial==0);
isDuringEntireBaselineTime = timeMs<0;
nTrials = size(raster,1);
nIsis = sum(sum(raster(:,isDuringEntireBaselineTime)))-nTrials;
allIsis = nan(nIsis,1);
isiCount = 0;

for iTrial = 1:nTrials
    currentIsis = diff(find(raster(iTrial,isDuringEntireBaselineTime)));
    nCurrentIsis = length(currentIsis);
    allIsis(isiCount+1:isiCount+nCurrentIsis) = currentIsis;
    isiCount = isiCount + nCurrentIsis;
end

allIsis(isiCount+1:end) = [];
[p,~] = gamfit(allIsis);
minIsiOffState = gaminv(params.pIsiToDefineOffState,p(1),p(2));
midPostOnsetTimeMs = mean(params.postOnsetTimeMs);
iMidPostOnsetTimeMs = find(timeMs>=midPostOnsetTimeMs,1,'first');
iMidBaselineTimeMs = find(timeMs>=midBaselineTimeMs,1,'first');
isOffStatePerTrialPostOnset = false(nTrials,1);
isOffStatePerTrialBaseline = false(nTrials,1);
probInOffState = nan(nTrials,1);
for iTrial = 1:nTrials
    currentIsis = diff(find(raster(iTrial,isDuringEntireBaselineTime)));
    lastSpikeBeforeMidPostOnset = find(raster(iTrial,1:iMidPostOnsetTimeMs),1,'last');
    firstSpikeAfterMidPostOnset = iMidPostOnsetTimeMs+find(raster(iTrial,iMidPostOnsetTimeMs+1:end),1,'first');
    isiAroundMidPostOnset = firstSpikeAfterMidPostOnset-lastSpikeBeforeMidPostOnset;
    if isiAroundMidPostOnset>=minIsiOffState
        isOffStatePerTrialPostOnset(iTrial) = true;
    end
    lastSpikeBeforeMidBaseline = find(raster(iTrial,1:iMidBaselineTimeMs),1,'last');
    firstSpikeAfterMidBaseline = iMidBaselineTimeMs+find(raster(iTrial,iMidBaselineTimeMs+1:end),1,'first');
    isiAroundMidBaseline = firstSpikeAfterMidBaseline-lastSpikeBeforeMidBaseline;
    if isiAroundMidBaseline>=minIsiOffState
        isOffStatePerTrialBaseline(iTrial) = true;
    end
    probInOffState(iTrial) = sum(currentIsis(currentIsis>minIsiOffState))./sum(currentIsis); 
    isDuringPostOnset = timeMs>=params.postOnsetTimeMs(1) & timeMs<params.postOnsetTimeMs(2);
end

MS_IN_SEC = 1000;
offState.perTrial.isOffState.probInEntireBaseline = probInOffState;
offState.perTrial.isOffState.postOnset = isOffStatePerTrialPostOnset;
offState.perTrial.isOffState.baseline = isOffStatePerTrialBaseline;
offState.perTrial.fr.postOnset = mean(raster(:,isDuringPostOnset),2)*MS_IN_SEC;
offState.perTrial.fr.equalLengthBaseline = mean(raster(:,isDuringEqualLengthBaseline),2)*MS_IN_SEC;
offState.perTrial.fr.entireBaseline = mean(raster(:,isDuringEntireBaselineTime),2)*MS_IN_SEC;


1;