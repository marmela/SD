function saveClicksRastersForSpikesAndLfps(allSessions)

preStimStartTimeInSec = 1;
postStimStartTimeInSec = 1;
sizeOfBinForRsterInMs = 1;
MS_IN_SEC = 1000;
epochsDir = [SdLocalPcDef.TEMP_ANALYSIS_DIR filesep 'Epochs'];
spikesFileNameFormat = 'times_Raw_%03g.mat';
statePerClickAnalysisDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'State\StatePerStim'];
nSessions = length(allSessions);

for iSess = nSessions:-1:1
    sessInfo = allSessions{iSess};
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    spikesDir =  getSpikesSortingDirPath(sessInfo.animal,sessInfo.animalSession);
    lfpDir = getLfpTraceDirPath(sessInfo.animal,sessInfo.animalSession);
    muaDir = getMuaTraceDirPath(sessInfo.animal,sessInfo.animalSession);
    eegDir = getEegTraceDirPath(sessInfo);
    stateFileName = sprintf('Clicks-%s-%d',sessInfo.animal,sessInfo.animalSession);
    stateFilePath = [statePerClickAnalysisDir filesep stateFileName];
    tmp = load(stateFilePath);
    sleepStateToScoreValue = tmp.sleepStateToScoreValue;
    %%
    statePerStim = tmp.statePerStim;
    nStims = length(statePerStim);    
    statePerStimValidTrials = statePerStim;
    for iStim = 1:nStims
        stateCurrentStim = statePerStim(iStim);
        isQwSd = stateCurrentStim.isQuiescent & stateCurrentStim.isDuringSd & ...
            stateCurrentStim.sleepScoring==sleepStateToScoreValue('Q-Wake');
        isAw = stateCurrentStim.isQuiescent &  ...
            stateCurrentStim.sleepScoring==sleepStateToScoreValue('A-Wake');
        isRemTrial = stateCurrentStim.isAfterSd & stateCurrentStim.sleepScoring==sleepStateToScoreValue('REM');
        isNremTrial = stateCurrentStim.isAfterSd & stateCurrentStim.sleepScoring==sleepStateToScoreValue('NREM');
        isQwRecovery = stateCurrentStim.isAfterSd & stateCurrentStim.sleepScoring==sleepStateToScoreValue('Q-Wake');
        isTrialValid = isQwSd | isAw | isRemTrial | isNremTrial | isQwRecovery;
        statePerStimValidTrials(iStim).onsetSec(~isTrialValid) = [];
        statePerStimValidTrials(iStim).isDuringSd(~isTrialValid) = [];
        statePerStimValidTrials(iStim).isAfterSd(~isTrialValid) = [];
        statePerStimValidTrials(iStim).isQuiescent(~isTrialValid) = [];
        statePerStimValidTrials(iStim).sleepScoring(~isTrialValid) = [];
        statePerStimValidTrials(iStim).timeSinceWheelMoveSec(~isTrialValid) = [];
        statePerStimValidTrials(iStim).dlc.movement.x(~isTrialValid,:) = [];
        statePerStimValidTrials(iStim).dlc.movement.y(~isTrialValid,:) = [];
        statePerStimValidTrials(iStim).dlc.location.x(~isTrialValid,:) = [];
        statePerStimValidTrials(iStim).dlc.location.y(~isTrialValid,:) = [];       
        statePerStimValidTrials(iStim).dlc.angleBetweenParts(~isTrialValid,:,:) = [];  
        statePerStimValidTrials(iStim).dlc.distanceBetweenParts(~isTrialValid,:,:) = [];  
        statePerStimValidTrials(iStim).dlc.probLikely(~isTrialValid,:) = [];  
        statePerStimValidTrials(iStim).dlc.probLikelyTwoParts(~isTrialValid,:,:) = [];  
    end
    
    save([epochsDir filesep getEpochsFileName(sessInfo)], 'statePerStimValidTrials',...
        'sleepStateToScoreValue')
    
    %% EEG
    stdOfEpochsStdToRejectEeg = Inf;
    stdOfValuesToRejectEeg = Inf;
    isRemoveBaselineEeg = true;
    N_EEGS = 4;
    for iEEG = N_EEGS:-1:1
       eegFileName = sprintf('EEG_%03g',iEEG);
       eegFilePath = [eegDir filesep eegFileName];
       eegData = load(eegFilePath);
       for iStim = 1:nStims
           [~,eeg(iEEG).times,eeg(iEEG).epochsPerStim{iStim},noisyEpochs, ~,isInvalidEvent] = getErp(...
               eegData.data, eegData.srData, statePerStimValidTrials(iStim).onsetSec, ...
               preStimStartTimeInSec, postStimStartTimeInSec, isRemoveBaselineEeg, ...
               stdOfEpochsStdToRejectEeg, stdOfValuesToRejectEeg);
           
           eeg(iEEG).isNoisyEpochPerStim{iStim} = noisyEpochs | isInvalidEvent;
           eeg(iEEG).epochsPerStim{iStim} = single(eeg(iEEG).epochsPerStim{iStim});
       end
       eeg(iEEG).sr = eegData.srData;
    end
    eegFileName = getEegEpochsFileName(sessInfo);
    save([epochsDir filesep eegFileName], 'eeg', 'preStimStartTimeInSec','postStimStartTimeInSec');
    disp(eegFileName)
    %%
    for ch = channels
        spikePath = [spikesDir filesep sprintf(spikesFileNameFormat,ch)];
        muaPath = [muaDir filesep getMuaTraceFilename(ch)];
        lfpPath = [lfpDir filesep getLfpTraceFilename(ch)];
        if ~exist(spikePath,'file')
            continue;
        end
        spikeTimesData = load(spikePath);
        nClus = max(spikeTimesData.cluster_class(:,1));
        muaData = load(muaPath);
        lfpData = load(lfpPath);
        isRemoveBaseline = true;
        stdOfEpochsStdToReject = Inf;
        stdOfValuesToReject = Inf;
        clear spikes lfp mua
        for iStim = 1:nStims
            [~,~,lfp.epochsPerStim{iStim},noisyEpochs, ~,isInvalidEvent] = getErp(...
                lfpData.data, lfpData.srData, statePerStimValidTrials(iStim).onsetSec, ...
                preStimStartTimeInSec, postStimStartTimeInSec, isRemoveBaseline, ...
                stdOfEpochsStdToReject, stdOfValuesToReject);
            lfp.isNoisyEpochPerStim{iStim} = noisyEpochs | isInvalidEvent;
            lfp.epochsPerStim{iStim} = single(lfp.epochsPerStim{iStim});
        end
        lfp.sr = lfpData.srData;
        for iStim = 1:nStims
            [~,~,mua.epochsPerStim{iStim},noisyEpochs, ~,isInvalidEvent] = getErp(...
                muaData.data, muaData.srData, statePerStimValidTrials(iStim).onsetSec, ...
                preStimStartTimeInSec, postStimStartTimeInSec, isRemoveBaseline, ...
                stdOfEpochsStdToReject, stdOfValuesToReject);
            mua.isNoisyEpochPerStim{iStim} = noisyEpochs | isInvalidEvent;
            mua.epochsPerStim{iStim} = single(mua.epochsPerStim{iStim});
        end
        mua.sr = muaData.srData;
        spikes.binSizeMs = sizeOfBinForRsterInMs;
        for iClus = 1:nClus
            isCurrentClus =spikeTimesData.cluster_class(:,1)==iClus;
            spikeTimesSec = spikeTimesData.cluster_class(isCurrentClus,2)./MS_IN_SEC;
            spikeShapeCurrentClus = mean(spikeTimesData.spikes(isCurrentClus,:));
            spikes.shapePerClus{iClus} = spikeShapeCurrentClus;
            for iStim = 1:nStims
                spikes.rasterPerStimAndClus{iStim,iClus} = sparse(logical(getRaster(spikeTimesSec, ...
                    statePerStimValidTrials(iStim).onsetSec, preStimStartTimeInSec, ...
                    postStimStartTimeInSec, sizeOfBinForRsterInMs)));
            end
        end
        epochsFileName = getEpochsFileName(sessInfo,ch);
        save([epochsDir filesep epochsFileName], 'spikes','lfp','mua',...
            'preStimStartTimeInSec','postStimStartTimeInSec');
        disp(epochsFileName)
    end
    
end