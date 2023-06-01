function calcAndSaveYokedPostOnsetFromSpontaneousActivity(allSessionsInfo)
iStimPostOnset = 1;
MS_IN_1SEC = 1000;
    onsetTimesMs = [0,30];
    timePointsToObtain = [-100,200];
spikesFileNameFormat = 'times_Raw_%03g.mat';
noiseFileNameFormat = 'Raw_%03g_noiseTimes.mat';
epochsDir = [SdLocalPcDef.TEMP_ANALYSIS_DIR filesep 'Epochs'];
statePerStimAnalysisDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'State\StatePerStim'];
saveDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Post Onset'];
makeDirIfNeeded(saveDir);
nSessions = length(allSessionsInfo);

parfor iSess = 1:nSessions
    sessInfo = allSessionsInfo{iSess};
    isiStateFile = sprintf('ISI-%s-%d',sessInfo.animal,sessInfo.animalSession);
    isiStateFilePath = [statePerStimAnalysisDir filesep isiStateFile];
    isiState = load(isiStateFilePath);
    [iQwIsi, iNremIsi, iRemIsi, iAwRecoveryIsi, iAwAllIsi] = getRecoveryPeriodEpochsISI(...
        isiState.statePerIsi,isiState.sleepStateToScoreValue);
    sessionFileName = [getSessionDirName(sessInfo), '_YokedVsRealPostOnset'];
    savePath = [saveDir filesep sessionFileName];
    spikesDir =  getSpikesSortingDirPath(sessInfo.animal,sessInfo.animalSession);
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    stateData = load([epochsDir filesep getEpochsFileName(sessInfo)]);
    [iQw, iNrem, iRem, iAwRecovery, iAwAll] = getRecoveryPeriodEpochs(stateData.statePerStimValidTrials,...
        stateData.sleepStateToScoreValue);
    iQw = iQw{iStimPostOnset};
    iNrem = iNrem{iStimPostOnset};
    iRem = iRem{iStimPostOnset};
    nSdPressurePeriods = 3;
    nTimePeriods = 1;
    iSdPerStimAndSdPressure = getSdPeriodEpochs(...
        stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods);
    iSdPerSdPressure = iSdPerStimAndSdPressure(iStimPostOnset,:);
    stimOnsetSec = stateData.statePerStimValidTrials(iStimPostOnset).onsetSec;
    iSdPerSdPressureIsi = getSdPeriodEpochsISI(isiState.statePerIsi,...
        isiState.sleepStateToScoreValue, iSdPerSdPressure,stimOnsetSec);
    isiOnsetSec = extractfield(isiState.statePerIsi,'onsetSec');
    isiOffsetSec = extractfield(isiState.statePerIsi,'offsetSec');
    isiTimePeriods = [makeColumn(isiOnsetSec),makeColumn(isiOffsetSec)];
    yokedSponPostOnset ={};
    for ch = channels
        filePath = [epochsDir filesep getEpochsFileName(sessInfo,ch) '.mat'];
        if ~exist(filePath,'file'); continue;  end
        epochsData = load(filePath);
        if ~isfield(epochsData.spikes,'rasterPerStimAndClus'); continue; end
        spikePath = [spikesDir filesep sprintf(spikesFileNameFormat,ch)];
        if ~exist(spikePath,'file'); continue; end
        
        spikeTimesData = load(spikePath);
        noisePath = [spikesDir filesep sprintf(noiseFileNameFormat,ch)];
        noiseTimesData = load(noisePath);
        rasterPerClus = epochsData.spikes.rasterPerStimAndClus(iStimPostOnset,:);
        timesMs = -epochsData.preStimStartTimeInSec*MS_IN_1SEC+epochsData.spikes.binSizeMs./2:...
            epochsData.spikes.binSizeMs:epochsData.postStimStartTimeInSec*MS_IN_1SEC;
        nClus = size(rasterPerClus,2);
        for iClus = 1:nClus
            currentRaster = rasterPerClus{1,iClus};
            spikeTimesCurrentSec = spikeTimesData.cluster_class(...
                spikeTimesData.cluster_class(:,1)==iClus,2)./MS_IN_1SEC;
            for iSdPressure = 1:nSdPressurePeriods
                [yokedSponPostOnset{ch,iClus}.sdPressure(iSdPressure)] = getYokedRasterFromSpontaneousAcitivty...
                    (spikeTimesCurrentSec,noiseTimesData,isiTimePeriods,currentRaster,timesMs, ...
                    onsetTimesMs, timePointsToObtain,iSdPerSdPressure{iSdPressure},...
                    iSdPerSdPressureIsi{iSdPressure});
            end
            [yokedSponPostOnset{ch,iClus}.qw] = getYokedRasterFromSpontaneousAcitivty...
                (spikeTimesCurrentSec,noiseTimesData,isiTimePeriods,currentRaster,timesMs, ...
                onsetTimesMs, timePointsToObtain,iQw,iQwIsi);
            [yokedSponPostOnset{ch,iClus}.nrem] = getYokedRasterFromSpontaneousAcitivty...
                (spikeTimesCurrentSec,noiseTimesData,isiTimePeriods,currentRaster,timesMs, ...
                onsetTimesMs, timePointsToObtain,iNrem,iNremIsi);
            [yokedSponPostOnset{ch,iClus}.rem] = getYokedRasterFromSpontaneousAcitivty...
                (spikeTimesCurrentSec,noiseTimesData,isiTimePeriods,currentRaster,timesMs, ...
                onsetTimesMs, timePointsToObtain,iRem,iRemIsi);
        end
        fprintf('Finished %s Channel %d\n',getSessionDirName(sessInfo),ch)
    end
    parforSaveYokedPostOnset(savePath,yokedSponPostOnset)
    fprintf('@@@@@@      Finished %s      @@@@@@\n',getSessionDirName(sessInfo))
end