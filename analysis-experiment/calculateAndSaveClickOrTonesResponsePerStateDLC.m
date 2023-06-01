function calculateAndSaveClickOrTonesResponsePerStateDLC(allSessions,isClicks)

if (~exist('isClicks','var'))
    isClicks = true;
end
N_DEFAULT_BINS = 3;
params.baselineTimeMs = [-500,0];
params.onsetTimeMs = [0,50];
params.postOnsetTimeMs = [30,80]; %[40,100];
params.smooth.sigmaMs = 2;
params.baselineTimeMsEegPower = [-1000,0];
params.eegPowerFreqs = 0.5:0.5:100;
params.stats.on = true;
params.stats.nReps = 1000;
params.noise.nMedianAbsDevToExcludeTrials = 5;
params.pIsiToDefineOffState = 0.99;
if isClicks
    params.sustainedTimeMs = [130,530];
    params.offsetTimeMs = [550,650];
    fileNamePostfix  = '';
else
    params.sustainedTimeMs = [200,2000];
    params.offsetTimeMs = [2050,2150];
    fileNamePostfix  = '_Tones';
end
CHORD_RATE_HZ = 50;
params.timef.data = ['lfp'];
params.timef.trialbase = 'full';
params.timef.lowBand.cycles = [2,7];
params.timef.lowBand.winsize = 500;
params.timef.lowBand.freqs = [4,70];
params.timef.highBand.cycles = 0;
params.timef.highBand.winsize = 100;
params.timef.highBand.freqs = [70,200];
epochsDir = 'E:\SD\Temp Analysis\Epochs';
nSessions = length(allSessions);

parfor iSess = 1:nSessions
    
    rng(1); %Set Random number generator seed to 1 to create repeatable results. it is done within each session because of possible use of parfor loop
    sessInfo = allSessions{iSess};
    
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    
    stateData = load([epochsDir filesep getEpochsFileName(sessInfo) fileNamePostfix]);
    
    [iQw,iNrem, iRem, iAwRecovery, iAwAll] = getRecoveryPeriodEpochs(stateData.statePerStimValidTrials,...
        stateData.sleepStateToScoreValue);
    
    nStims = length(iQw);
    
    nSdPressurePeriods = N_DEFAULT_BINS;
    nTimePeriods = 1;
    iSdPerStimAndSdPressure = getSdPeriodEpochs(...
        stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods);
    
    nSdPressurePeriods = 1;
    nTimePeriods = N_DEFAULT_BINS;
    iSdPerStimAndMomentArousal = squeeze(getSdPeriodEpochs(...
        stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods));
    % if there is only 1 stim the squeeze messes up the dimensions
    if iscolumn(iSdPerStimAndMomentArousal)
        iSdPerStimAndMomentArousal = iSdPerStimAndMomentArousal';
    end
    
    %% Analyze DLC per trial-type
    trialTypes = cell(11,1);
    trialTypesName = cell(11,1);
    trialTypes{1} = iQw;
    trialTypesName{1} = 'QW';
    trialTypes{2} = iNrem;
    trialTypesName{2} = 'NREM';
    trialTypes{3}= iRem;
    trialTypesName{3} = 'REM';
    trialTypes{4} = iAwAll;
    trialTypesName{4} = 'AW';
    trialTypes{5} = iAwRecovery;
    trialTypesName{5} = 'AW-Just_Recovery';
    iTrialType = 6;
    for iBin = 1:size(iSdPerStimAndSdPressure,2)
        trialTypes{iTrialType} = iSdPerStimAndSdPressure(:,iBin);
        trialTypesName{iTrialType} = sprintf('SD%d',iBin);
        iTrialType = iTrialType + 1;
    end
    for iBin = 1:size(iSdPerStimAndMomentArousal,2)
        trialTypes{iTrialType} = iSdPerStimAndMomentArousal(:,iBin);
        trialTypesName{iTrialType} = sprintf('Arousal%d',iBin);
        iTrialType = iTrialType + 1;
    end
    [dlcAnalysisPerState,chosenBodyPart] = getDlcAnalysisPerTrialType(stateData.statePerStimValidTrials,trialTypes,trialTypesName);
    
    %% EQUALIZE SD MOVEMENT
    for iStim = 1:nStims
        [iSdPerStimAndSdPressure(iStim,:)] = balanceTrialsMovementAndHeadAngle(iSdPerStimAndSdPressure(iStim,:),...
            stateData.statePerStimValidTrials(iStim).dlc.movement,...
            stateData.statePerStimValidTrials(iStim).dlc.probLikely, chosenBodyPart.i, ...
            stateData.statePerStimValidTrials(iStim).dlc.angleBetweenParts, ...
            stateData.statePerStimValidTrials(iStim).dlc.probLikelyTwoParts, ...
            stateData.statePerStimValidTrials(iStim).dlc.bodyParts);
    end
    1;
    %% attach responses from all channels
    % % %     clear epochsDataAll
    isResponseAllNotYetCreated = true;
    nValidChannels = 0;
    for ch = channels
        filePath = [epochsDir filesep getEpochsFileName(sessInfo,ch) fileNamePostfix '.mat'];
        if ~exist(filePath,'file')
            continue;
        end
        epochsData = load(filePath);
        if ~isfield(epochsData.spikes,'rasterPerStimAndClus')
            continue;
        end
        nValidChannels = nValidChannels + 1;
        
        nClus = size(epochsData.spikes.rasterPerStimAndClus,2);
        if isResponseAllNotYetCreated
            epochsDataAll = epochsData;
            isResponseAllNotYetCreated = false;
            epochsDataAll.spikes.rasterPerStimAndClus = cell(nStims,1);
            for iStim = 1:nStims
                epochsDataAll.spikes.rasterPerStimAndClus{iStim} = ...
                    double(full(epochsData.spikes.rasterPerStimAndClus{iStim}));
                for iClus = 2:nClus
                    epochsDataAll.spikes.rasterPerStimAndClus{iStim} = ...
                        epochsDataAll.spikes.rasterPerStimAndClus{iStim} + ...
                        double(full(epochsData.spikes.rasterPerStimAndClus{iStim,iClus}));
                end
                
            end
            
        else
            for iStim = 1:nStims
                epochsDataAll.lfp.epochsPerStim{iStim} = ...
                    epochsDataAll.lfp.epochsPerStim{iStim} + ...
                    epochsData.lfp.epochsPerStim{iStim} ;
                epochsDataAll.lfp.isNoisyEpochPerStim{iStim} = ...
                    epochsDataAll.lfp.isNoisyEpochPerStim{iStim} | ...
                    epochsData.lfp.isNoisyEpochPerStim{iStim};
                epochsDataAll.mua.epochsPerStim{iStim} = ...
                    epochsDataAll.mua.epochsPerStim{iStim} + ...
                    epochsData.mua.epochsPerStim{iStim} ;
                epochsDataAll.mua.isNoisyEpochPerStim{iStim} = ...
                    epochsDataAll.mua.isNoisyEpochPerStim{iStim} | ...
                    epochsData.mua.isNoisyEpochPerStim{iStim};
                for iClus = 1:nClus
                    epochsDataAll.spikes.rasterPerStimAndClus{iStim} = ...
                        epochsDataAll.spikes.rasterPerStimAndClus{iStim} + ...
                        double(full(epochsData.spikes.rasterPerStimAndClus{iStim,iClus}));
                end
            end
        end
    end
    
    for iStim = 1:nStims
        epochsDataAll.lfp.epochsPerStim{iStim} = ...
            epochsDataAll.lfp.epochsPerStim{iStim}./nValidChannels;
        epochsDataAll.mua.epochsPerStim{iStim} = ...
            epochsDataAll.mua.epochsPerStim{iStim}./nValidChannels;
    end
    
    %%
    eegData = load([epochsDir filesep getEegEpochsFileName(sessInfo) fileNamePostfix]);
    
    %% analyze response all
    responseAll = {};
    tic
    for iStim = 1:nStims
        if isClicks
            clickRateHz = stateData.statePerStimValidTrials(iStim).clickRateHz;
        else
            clickRateHz = CHORD_RATE_HZ;
        end
        for iSdPressure = 1:size(iSdPerStimAndSdPressure,2)
            responseCurrent = getClickResponsePerStateForAllDataTypes(...
                epochsDataAll, iSdPerStimAndSdPressure{iStim,iSdPressure}, iStim, clickRateHz, params);
            responseCurrent.eeg = getClickEegResponsePerStateForAllDataTypes(...
                eegData, iSdPerStimAndSdPressure{iStim,iSdPressure}, iStim, clickRateHz, params);
            responseAll{iStim}.sd.pressure(iSdPressure) = responseCurrent;
        end
    end
    
    baselineAll = [];
    
    for iSdPressure = 1:size(iSdPerStimAndSdPressure,2)
        [baselineAll.sd.pressure{iSdPressure}] = analyzeBaselineSpikes(...
            epochsDataAll, iSdPerStimAndSdPressure(:,iSdPressure));
    end
    
    %%
    baseline = cell(1,max(channels));
    response = cell(nStims,max(channels),1);
    for ch = channels %parfor ch = channels
        tic
        filePath = [epochsDir filesep getEpochsFileName(sessInfo,ch) fileNamePostfix '.mat'];
        if ~exist(filePath,'file')
            continue;
        end
        epochsData = load(filePath);
        if ~isfield(epochsData.spikes,'rasterPerStimAndClus')
            continue;
        end
        
        for iSdPressure = 1:size(iSdPerStimAndSdPressure,2)
            [baseline{ch}.sd.pressure{iSdPressure}] = analyzeBaselineSpikes(...
                epochsData, iSdPerStimAndSdPressure(:,iSdPressure),epochsDataAll);
        end
        for iStim = 1:nStims
            if isClicks
                clickRateHz = stateData.statePerStimValidTrials(iStim).clickRateHz;
            else
                clickRateHz = CHORD_RATE_HZ;
            end
            for iSdPressure = 1:size(iSdPerStimAndSdPressure,2)
                response{iStim,ch}.sd.pressure(iSdPressure) = getClickResponsePerStateForAllDataTypes(...
                    epochsData, iSdPerStimAndSdPressure{iStim,iSdPressure}, iStim, clickRateHz, params);
            end
        end
        
        fprintf('Finished %s-%d ch%d - time: %ds\n',sessInfo.animal,sessInfo.animalSession,ch,round(toc))
    end
    
    baselineAll.dlcAnalysisPerState = dlcAnalysisPerState;
    [sessFilePath,~,fileDir] = getDlcClickResponsePerStateAnalysisFilePath(sessInfo,isClicks);
    %% code for non-deafult bins not implemented for DLC
    makeDirIfNeeded(fileDir)
    parforSaveBaselineResponse(sessFilePath,baseline,baselineAll,response,responseAll,params)
end

