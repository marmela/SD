function [resultPerUnit] = analyzeBaselineSpikes(epochsData,iTrialsOfState,epochsDataAll)

if isempty(iTrialsOfState)
    resultPerUnit = [];
    return;
end
MS_IN_1SEC = 1000;
binLengthMs = 50;

timesMs = -epochsData.preStimStartTimeInSec*MS_IN_1SEC+epochsData.spikes.binSizeMs/2:...
    epochsData.spikes.binSizeMs:epochsData.postStimStartTimeInSec*MS_IN_1SEC;
isBaselineTime = timesMs<0;
nStims = size(epochsData.spikes.rasterPerStimAndClus,1);
nUnits = size(epochsData.spikes.rasterPerStimAndClus,2);
assert(mean(diff(timesMs))==1)
sizeMs = sum(isBaselineTime);
nBins = floor(sizeMs./binLengthMs);
isCalcPopCoupling = exist('epochsDataAll','var');

for iUnit = nUnits:-1:1
    rasterUnit = [];
    for iStim = 1:nStims
        rasterUnit = [rasterUnit; epochsData.spikes.rasterPerStimAndClus{iStim,iUnit}(...
            iTrialsOfState{iStim}, isBaselineTime)];
    end
    resultPerUnit{iUnit} = analyzeBaselineSpikesCvFano(full(rasterUnit));    
    
    if ~isCalcPopCoupling
        continue;
    end
    rasterPop = [];
    nTrials = size(rasterUnit,1);
    rasterUnitBin = nan(nTrials,nBins);
    rasterPopButUnitBin = nan(nTrials,nBins);
    
    for iStim = 1:nStims
        rasterPop = [rasterPop; epochsDataAll.spikes.rasterPerStimAndClus{iStim,1}(...
            iTrialsOfState{iStim}, isBaselineTime)];
    end
        rasterPopButUnit = rasterPop-rasterUnit;  
    
    for iBin = 1:nBins
        rasterUnitBin(:,iBin) = sum(rasterUnit(:,(iBin-1)*binLengthMs+(1:binLengthMs)),2);
        rasterPopButUnitBin(:,iBin) = sum(rasterPopButUnit(:,(iBin-1)*binLengthMs+(1:binLengthMs)),2);
    end
    corrPerTrial = nan(nTrials,1);
    for iTrial = 1:nTrials
        corrPerTrial(iTrial) = corr(rasterUnitBin(iTrial,:)',rasterPopButUnitBin(iTrial,:)');
    end
    resultPerUnit{iUnit}.populationCoupling = nanmean(corrPerTrial);
end