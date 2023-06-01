function response = getClickResponsePerStateForAllDataTypes(epochsData, iTrials, iStim, ...
    clickRateHz, params)

if isempty(iTrials)
    response.lfp = [];
    response.mua = [];
    response.spikesPerClus = {};
    response.spikes = [];
    return;
end
MS_IN_SEC = 1000;
lfpTrials = epochsData.lfp.epochsPerStim{iStim}(iTrials,:);
muaTrials = epochsData.mua.epochsPerStim{iStim}(iTrials,:);
lfpTimesMs = (-epochsData.preStimStartTimeInSec*MS_IN_SEC:MS_IN_SEC/epochsData.lfp.sr:...
    epochsData.postStimStartTimeInSec*MS_IN_SEC);
muaTimesMs = (-epochsData.preStimStartTimeInSec*MS_IN_SEC:MS_IN_SEC/epochsData.mua.sr:...
    epochsData.postStimStartTimeInSec*MS_IN_SEC);
spikeTimeMs = (-epochsData.preStimStartTimeInSec*MS_IN_SEC+epochsData.spikes.binSizeMs/2:...
    epochsData.spikes.binSizeMs:epochsData.postStimStartTimeInSec*MS_IN_SEC);
response.lfp = getContinuousDataClickResponse(lfpTrials,lfpTimesMs,clickRateHz,params);
response.mua = getContinuousDataClickResponse(muaTrials,muaTimesMs,clickRateHz,params);
if isfield(params,'timef')
    if strcmp(params.timef.data,'lfp')
        %% EEGLAB functions - lfp analysis wasn't used in the manuscript
        [response.lfp.timef.low.ersp,response.lfp.timef.low.itc,response.lfp.timef.low.powbase,...
            response.lfp.timef.low.times,response.lfp.timef.low.freqs,~,~] = newtimef(lfpTrials', ...
            length(lfpTimesMs), [lfpTimesMs(1) lfpTimesMs(end)], epochsData.lfp.sr, params.timef.lowBand.cycles,...
            'winsize',params.timef.lowBand.winsize,'maxfreq',params.timef.lowBand.freqs(2),...
            'trialbase',params.timef.trialbase,'freqs',params.timef.lowBand.freqs,...
            'plotersp','off','plotitc','off','verbose','off');
        [response.lfp.timef.high.ersp,response.lfp.timef.high.itc,response.lfp.timef.high.powbase,...
            response.lfp.timef.high.times,response.lfp.timef.high.freqs,~,~] = newtimef(lfpTrials', ...
            length(lfpTimesMs), [lfpTimesMs(1) lfpTimesMs(end)], epochsData.lfp.sr, params.timef.highBand.cycles,...
            'winsize',params.timef.highBand.winsize,'maxfreq',params.timef.highBand.freqs(2),...
            'trialbase',params.timef.trialbase,'freqs',params.timef.highBand.freqs,...
            'plotersp','off','plotitc','off','verbose','off');
    end
end

if ~isfield(epochsData.spikes,'rasterPerStimAndClus')
    return;
end
nClus = size(epochsData.spikes.rasterPerStimAndClus,2);
isBaselineTime = spikeTimeMs>=params.baselineTimeMs(1) & spikeTimeMs<params.baselineTimeMs(2);
for iClus = 1:nClus
    spikesCurrentClus = full(epochsData.spikes.rasterPerStimAndClus{iStim,iClus}(iTrials,:));
    offStateResponse = calcSpontaneousAndEvokedOffStates(spikesCurrentClus, spikeTimeMs,params);
    spikesCurrentClusFr = spikesCurrentClus * MS_IN_SEC ./ epochsData.spikes.binSizeMs;
    response.spikesPerClus{iClus} = getContinuousDataClickResponse(spikesCurrentClusFr,...
        spikeTimeMs,clickRateHz,params);
    response.spikesPerClus{iClus}.offState = offStateResponse;
end

iClus = 1;
allClustersSpikesTrials = full(epochsData.spikes.rasterPerStimAndClus{iStim,iClus}(iTrials,:));
for iClus = 2:nClus
    allClustersSpikesTrials = allClustersSpikesTrials + ...
        full(epochsData.spikes.rasterPerStimAndClus{iStim,iClus}(iTrials,:));
end
offStateResponse = calcSpontaneousAndEvokedOffStatesEntireChannel(allClustersSpikesTrials, spikeTimeMs,params);
allClustersSpikesTrialsFr = allClustersSpikesTrials * MS_IN_SEC ./ epochsData.spikes.binSizeMs;
response.spikes = getContinuousDataClickResponse(allClustersSpikesTrialsFr,spikeTimeMs,clickRateHz,params);
response.spikes.offState = offStateResponse;

1;