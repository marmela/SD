function calculateAndSaveFraPerState(allSessions)

MS_IN_SEC = 1000;
spikesFileNameFormat = 'times_Raw_%03g.mat';
isDrcTuning = true;
nFirstChordsToIgnore = 5;
spikingTemporalWindowPerChordMs = [5,30]; 
nSessions = length(allSessions);
statePerStimAnalysisDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'State\StatePerStim'];
iFreqsToIgnore = 59:60; %frequencies to ignore due to anamoly - too many units responded to the two highest frequencies.

for iSess = 1:nSessions 
    sessInfo = allSessions{iSess};
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    fileName = sprintf('DRC-Tuning-%s-%d',sessInfo.animal,sessInfo.animalSession);
    filePath = [statePerStimAnalysisDir filesep fileName];
    stateData = load(filePath);
    [iQw,iNrem, iRem] = getRecoveryPeriodEpochs(stateData.statePerStim,...
        stateData.sleepStateToScoreValue);
    nStims = length(iQw);
    nSdPressurePeriods = 3;
    nTimePeriods = 1;
    iSdPerStimAndSdPressure = getSdPeriodEpochs(...
        stateData.statePerStim,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods);
    nSdPressurePeriods = 1;
    nTimePeriods = 3;
    iSdPerStimAndMomentArousal = squeeze(getSdPeriodEpochs(...
        stateData.statePerStim,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods));
    % if there is only 1 stim the squeeze messes up the dimensions
    if iscolumn(iSdPerStimAndMomentArousal)
        iSdPerStimAndMomentArousal = iSdPerStimAndMomentArousal';
    end
    spikesDir =  getSpikesSortingDirPath(sessInfo.animal,sessInfo.animalSession);
    [drcs,drcStartTimesSec]  = loadDrcParadigmData(sessInfo,isDrcTuning);
    %% load DRC chord times per state
    [timesSecPerChord,soundLevelIndPerFreqAndChord,freqs,soundLevelsDb] = ...
        getChordTimesFromDrcPartsPerState(drcs, nFirstChordsToIgnore, stateData.statePerStim.onsetSec,...
        stateData.statePerStim.stamp-ParadigmConsts.DRC_TUNING_BASE_ID, stateData.statePerStim.partIndexInDrc,...
        iQw{1}, iNrem{1}, iRem{1}, iSdPerStimAndSdPressure,iSdPerStimAndMomentArousal,iFreqsToIgnore);
    %%
    MAX_PROBABLE_N_CLUS = 10;
    fraPerState = cell(max(channels),MAX_PROBABLE_N_CLUS);
    fraStats = cell(max(channels),MAX_PROBABLE_N_CLUS);
    for ch = channels
        spikePath = [spikesDir filesep sprintf(spikesFileNameFormat,ch)];
        if ~exist(spikePath,'file')
            continue;
        end
        spikeTimesData = load(spikePath);
        
        nClus = max(spikeTimesData.cluster_class(:,1));
        for iClus = 1:nClus
            clusSpikeTimesSec = spikeTimesData.cluster_class(...
                spikeTimesData.cluster_class(:,1)==iClus,2)./MS_IN_SEC;
            [fraPerState{ch,iClus},fraStats{ch,iClus}] = getFraFromChordsPerState (timesSecPerChord, ...
                soundLevelIndPerFreqAndChord,clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
        end
        
        fprintf('Finished %s-Session #%d Channel #%d\n',sessInfo.animal,sessInfo.animalSession,ch);
    end
    % delete empty clusters columns 
    fraPerState(:,find(all(cellfun(@isempty,fraPerState)),1,'first'):end) = [];
    fraStats(:,find(all(cellfun(@isempty,fraStats)),1,'first'):end) = [];
    [sessFilePath,~,~] = getFraPerStateAnalysisFilePath(sessInfo);
    save(sessFilePath,'fraPerState','fraStats','freqs','soundLevelsDb');
end

function [timesSecPerChord,soundLevelIndPerFreqAndChord,freqs,soundLevelsDb] = ...
    getChordTimesFromDrcPartsPerState(drcs, nFirstChordsToIgnore, onsetSecPerTrial,...
    drcIdPerTrial, partIndexInDrcPerTrial, iQw, iNrem, iRem, ...
    iSdForSdPressure,iSdForArousal,iFreqsToIgnore)

if ~exist('iFreqsToIgnore','var')
    iFreqsToIgnore = [];
end

assert(size(iSdForSdPressure,1)==1);
assert(size(iSdForArousal,1)==1);

iAllTrials = [iQw; iNrem; iRem];
for iSdPressure = 1:length(iSdForSdPressure)
    iAllTrials = [iAllTrials; iSdForSdPressure{iSdPressure}];
end
iAllTrials = unique(iAllTrials);

[timesSecPerChord.qw,soundLevelIndPerFreqAndChord.qw,freqs,soundLevelsDb] = ...
    getChordTimesFromDrcParts(drcs, nFirstChordsToIgnore, onsetSecPerTrial(iQw), ...
    drcIdPerTrial(iQw), partIndexInDrcPerTrial(iQw),iFreqsToIgnore);

[timesSecPerChord.nrem,soundLevelIndPerFreqAndChord.nrem,~,~] = ...
    getChordTimesFromDrcParts(drcs, nFirstChordsToIgnore, onsetSecPerTrial(iNrem), ...
    drcIdPerTrial(iNrem), partIndexInDrcPerTrial(iNrem),iFreqsToIgnore);

[timesSecPerChord.rem,soundLevelIndPerFreqAndChord.rem,~,~] = ...
    getChordTimesFromDrcParts(drcs, nFirstChordsToIgnore, onsetSecPerTrial(iRem), ...
    drcIdPerTrial(iRem), partIndexInDrcPerTrial(iRem),iFreqsToIgnore);

for iSdPressure = 1:length(iSdForSdPressure)
    [timesSecPerChord.sdPressure{iSdPressure},soundLevelIndPerFreqAndChord.sdPressure{iSdPressure},~,~] = ...
        getChordTimesFromDrcParts(drcs, nFirstChordsToIgnore, onsetSecPerTrial(iSdForSdPressure{iSdPressure}), ...
        drcIdPerTrial(iSdForSdPressure{iSdPressure}), partIndexInDrcPerTrial(iSdForSdPressure{iSdPressure}),iFreqsToIgnore);
end

for iArousal = 1:length(iSdForArousal)
    [timesSecPerChord.arousal{iArousal},soundLevelIndPerFreqAndChord.arousal{iArousal},~,~] = ...
        getChordTimesFromDrcParts(drcs, nFirstChordsToIgnore, ...
        onsetSecPerTrial(iSdForArousal{iArousal}), ...
        drcIdPerTrial(iSdForArousal{iArousal}), ...
        partIndexInDrcPerTrial(iSdForArousal{iArousal}),iFreqsToIgnore);
end

[timesSecPerChord.all,soundLevelIndPerFreqAndChord.all,~,~] = ...
    getChordTimesFromDrcParts(drcs, nFirstChordsToIgnore, onsetSecPerTrial(iAllTrials), ...
    drcIdPerTrial(iAllTrials), partIndexInDrcPerTrial(iAllTrials),iFreqsToIgnore);

function [fraPerState,fraStats] = getFraFromChordsPerState (timesSecPerChord, ...
    soundLevelIndPerFreqAndChord,clusSpikeTimesSec,spikingTemporalWindowPerChordMs)

1;
isDoStats = true;
[fraPerState.qw,fraStats.qw] = getFraFromChords (timesSecPerChord.qw, soundLevelIndPerFreqAndChord.qw, ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs,isDoStats);
[fraPerState.nrem,fraStats.nrem] = getFraFromChords (timesSecPerChord.nrem, soundLevelIndPerFreqAndChord.nrem, ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs,isDoStats);
[fraPerState.rem,fraStats.rem] = getFraFromChords (timesSecPerChord.rem, soundLevelIndPerFreqAndChord.rem, ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs,isDoStats);

for iSdPressure = 1:length(timesSecPerChord.sdPressure)
    [fraPerState.sdPressure{iSdPressure},fraStats.sdPressure{iSdPressure}] = ...
        getFraFromChords (timesSecPerChord.sdPressure{iSdPressure},...
        soundLevelIndPerFreqAndChord.sdPressure{iSdPressure}, clusSpikeTimesSec, ...
        spikingTemporalWindowPerChordMs,isDoStats);
end

for iArousal = 1:length(timesSecPerChord.arousal)
    [fraPerState.arousal{iArousal},fraStats.arousal{iArousal}]  = getFraFromChords (...
        timesSecPerChord.arousal{iArousal}, soundLevelIndPerFreqAndChord.arousal{iArousal}, ...
        clusSpikeTimesSec, spikingTemporalWindowPerChordMs, isDoStats);
end

[fraPerState.all, fraStats.all] = getFraFromChords(timesSecPerChord.all, ...
    soundLevelIndPerFreqAndChord.all, clusSpikeTimesSec,spikingTemporalWindowPerChordMs,isDoStats);




%%
isFirstHalf = timesSecPerChord.qw<median(timesSecPerChord.qw);
fraPerState.qwPerHalf{1} = getFraFromChords (...
    timesSecPerChord.qw(isFirstHalf),soundLevelIndPerFreqAndChord.qw(:,isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
fraPerState.qwPerHalf{2} = getFraFromChords (...
    timesSecPerChord.qw(~isFirstHalf),soundLevelIndPerFreqAndChord.qw(:,~isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);

isFirstHalf = timesSecPerChord.nrem<median(timesSecPerChord.nrem);
fraPerState.nremPerHalf{1} = getFraFromChords (...
    timesSecPerChord.nrem(isFirstHalf),soundLevelIndPerFreqAndChord.nrem(:,isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
fraPerState.nremPerHalf{2} = getFraFromChords (...
    timesSecPerChord.nrem(~isFirstHalf),soundLevelIndPerFreqAndChord.nrem(:,~isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);


isFirstHalf = timesSecPerChord.rem<median(timesSecPerChord.rem);
fraPerState.remPerHalf{1} = getFraFromChords (...
    timesSecPerChord.rem(isFirstHalf),soundLevelIndPerFreqAndChord.rem(:,isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
fraPerState.remPerHalf{2} = getFraFromChords (...
    timesSecPerChord.rem(~isFirstHalf),soundLevelIndPerFreqAndChord.rem(:,~isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);


for iSdPressure = 1:length(timesSecPerChord.sdPressure)
    isFirstHalf = timesSecPerChord.sdPressure{iSdPressure}<...
        median(timesSecPerChord.sdPressure{iSdPressure});
    fraPerState.sdPressurePerHalf{iSdPressure}{1} = getFraFromChords (...
        timesSecPerChord.sdPressure{iSdPressure}(isFirstHalf),...
        soundLevelIndPerFreqAndChord.sdPressure{iSdPressure}(:,isFirstHalf), ...
        clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
    fraPerState.sdPressurePerHalf{iSdPressure}{2} = getFraFromChords (...
        timesSecPerChord.sdPressure{iSdPressure}(~isFirstHalf),...
        soundLevelIndPerFreqAndChord.sdPressure{iSdPressure}(:,~isFirstHalf), ...
        clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
end

for iArousal = 1:length(timesSecPerChord.arousal)
    isFirstHalf = timesSecPerChord.arousal{iArousal}<...
        median(timesSecPerChord.arousal{iArousal});
    fraPerState.arousalPerHalf{iArousal}{1} = getFraFromChords (...
        timesSecPerChord.arousal{iArousal}(isFirstHalf),...
        soundLevelIndPerFreqAndChord.arousal{iArousal}(:,isFirstHalf), ...
        clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
    fraPerState.arousalPerHalf{iArousal}{2} = getFraFromChords (...
        timesSecPerChord.arousal{iArousal}(~isFirstHalf),...
        soundLevelIndPerFreqAndChord.arousal{iArousal}(:,~isFirstHalf), ...
        clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
end

isFirstHalf = timesSecPerChord.all<median(timesSecPerChord.all);
fraPerState.allPerHalf{1} = getFraFromChords (...
    timesSecPerChord.all(isFirstHalf),soundLevelIndPerFreqAndChord.all(:,isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);
fraPerState.allPerHalf{2} = getFraFromChords (...
    timesSecPerChord.all(~isFirstHalf),soundLevelIndPerFreqAndChord.all(:,~isFirstHalf), ...
    clusSpikeTimesSec,spikingTemporalWindowPerChordMs);




