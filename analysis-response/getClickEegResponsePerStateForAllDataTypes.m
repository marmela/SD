function response = getClickEegResponsePerStateForAllDataTypes(epochsData, iTrials, iStim, ...
    clickRateHz, params)
if isempty(iTrials)
    response = [];
    return;
end
MS_IN_SEC = 1000;
nEegs = length(epochsData.eeg);
freqs = params.eegPowerFreqs;
nFreqs = length(freqs);
for iEeg = 1:nEegs
    eegTrials = epochsData.eeg(iEeg).epochsPerStim{iStim}(iTrials,:);
    eegTimesMs = epochsData.eeg(1).times * MS_IN_SEC;
    baselineEeg = eegTrials(:,eegTimesMs>=params.baselineTimeMsEegPower(1) & ...
        eegTimesMs<params.baselineTimeMsEegPower(2));
    response(iEeg) = getContinuousDataClickResponse(eegTrials,eegTimesMs,clickRateHz,params); 
    
    nTimepoints = size(baselineEeg,2); 
    nTrials = size(baselineEeg,1); 
    powerPerTrialAndFreq = nan(nTrials, nFreqs);
    for iTrial = 1:nTrials
        powerPerTrialAndFreq(iTrial,:) = pwelch(baselineEeg(iTrial,:), ...
            nTimepoints,0,freqs,epochsData.eeg(1).sr);
    end
    response(iEeg).baseline.power.meanPerFreq = mean(powerPerTrialAndFreq);
    response(iEeg).baseline.power.medianPerFreq = median(powerPerTrialAndFreq);
    response(iEeg).baseline.power.dbPerFreq = mean(10*log10(powerPerTrialAndFreq));
    response(iEeg).baseline.power.freqs = freqs;
end