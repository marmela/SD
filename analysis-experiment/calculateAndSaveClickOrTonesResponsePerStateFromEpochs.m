function calculateAndSaveClickOrTonesResponsePerStateFromEpochs(allSessions,isClicks,nBins)

if (~exist('isClicks','var'))
    isClicks = true;
end
if exist('nBins','var')
    isDefaultBins = false;
else
    isDefaultBins = true;
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
    sessInfo = allSessions{iSess};
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    stateData = load([epochsDir filesep getEpochsFileName(sessInfo) fileNamePostfix]);   
    [iQw,iNrem, iRem] = getRecoveryPeriodEpochs(stateData.statePerStimValidTrials,...
        stateData.sleepStateToScoreValue);
    nStims = length(iQw);
    if isDefaultBins
        nSdPressurePeriods = N_DEFAULT_BINS;
    else
        nSdPressurePeriods = nBins;
    end
    nTimePeriods = 1;
    iSdPerStimAndSdPressure = getSdPeriodEpochs(...
        stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods);    
    nSdPressurePeriods = 1;
    if isDefaultBins
        nTimePeriods = N_DEFAULT_BINS;
    else
        nTimePeriods = nBins;
    end
    iSdPerStimAndMomentArousal = squeeze(getSdPeriodEpochs(...
        stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods));
    % if there is only 1 stim the squeeze messes up the dimensions
    if iscolumn(iSdPerStimAndMomentArousal)
        iSdPerStimAndMomentArousal = iSdPerStimAndMomentArousal';
    end        
    %% attach responses from all channels
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
            %             if nClus>0
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
        for iTimePeriod = 1:size(iSdPerStimAndMomentArousal,2)
            responseCurrent = getClickResponsePerStateForAllDataTypes(...
                epochsDataAll, iSdPerStimAndMomentArousal{iStim,iTimePeriod}, iStim, clickRateHz, params);
            responseCurrent.eeg = getClickEegResponsePerStateForAllDataTypes(...
                eegData, iSdPerStimAndMomentArousal{iStim,iTimePeriod}, iStim, clickRateHz, params);
            responseAll{iStim}.sd.arousal(iTimePeriod) = responseCurrent;
        end
        responseCurrent = getClickResponsePerStateForAllDataTypes(...
            epochsDataAll, iQw{iStim}, iStim, clickRateHz, params);
        responseCurrent.eeg = getClickEegResponsePerStateForAllDataTypes(...
            eegData, iQw{iStim}, iStim, clickRateHz, params);
        responseAll{iStim}.recovery.qw = responseCurrent;
        
        responseCurrent = getClickResponsePerStateForAllDataTypes(...
            epochsDataAll, iNrem{iStim}, iStim, clickRateHz, params);
        responseCurrent.eeg = getClickEegResponsePerStateForAllDataTypes(...
            eegData, iNrem{iStim}, iStim, clickRateHz, params);
        responseAll{iStim}.recovery.nrem = responseCurrent;
        
        responseCurrent = getClickResponsePerStateForAllDataTypes(...
            epochsDataAll, iRem{iStim}, iStim, clickRateHz, params);
        responseCurrent.eeg = getClickEegResponsePerStateForAllDataTypes(...
            eegData, iRem{iStim}, iStim, clickRateHz, params);
        responseAll{iStim}.recovery.rem = responseCurrent;
    end
    
    baselineAll = [];
    
    for iSdPressure = 1:size(iSdPerStimAndSdPressure,2)
        [baselineAll.sd.pressure{iSdPressure}] = analyzeBaselineSpikes(...
            epochsDataAll, iSdPerStimAndSdPressure(:,iSdPressure));
    end
    for iTimePeriod = 1:size(iSdPerStimAndMomentArousal,2)
        [baselineAll.sd.arousal{iTimePeriod}] = analyzeBaselineSpikes(...
            epochsDataAll, iSdPerStimAndMomentArousal(:,iTimePeriod));
    end
    [baselineAll.qw] = analyzeBaselineSpikes(epochsDataAll, iQw);
    [baselineAll.nrem] = analyzeBaselineSpikes(epochsDataAll, iNrem);
    [baselineAll.rem] = analyzeBaselineSpikes(epochsDataAll, iRem);
    
    toc
    
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
        for iTimePeriod = 1:size(iSdPerStimAndMomentArousal,2)
            [baseline{ch}.sd.arousal{iTimePeriod}] = analyzeBaselineSpikes(...
                epochsData, iSdPerStimAndMomentArousal(:,iTimePeriod), epochsDataAll);
        end
        [baseline{ch}.qw] = analyzeBaselineSpikes(epochsData, iQw, epochsDataAll);
        [baseline{ch}.nrem] = analyzeBaselineSpikes(epochsData, iNrem, epochsDataAll);
        [baseline{ch}.rem] = analyzeBaselineSpikes(epochsData, iRem, epochsDataAll);

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
            for iTimePeriod = 1:size(iSdPerStimAndMomentArousal,2)
                response{iStim,ch}.sd.arousal(iTimePeriod) = getClickResponsePerStateForAllDataTypes(...
                    epochsData, iSdPerStimAndMomentArousal{iStim,iTimePeriod}, iStim, clickRateHz, params);
            end
            response{iStim,ch}.recovery.qw = getClickResponsePerStateForAllDataTypes(...
                    epochsData, iQw{iStim}, iStim, clickRateHz, params);   
                response{iStim,ch}.recovery.nrem = getClickResponsePerStateForAllDataTypes(...
                    epochsData, iNrem{iStim}, iStim, clickRateHz, params);
                response{iStim,ch}.recovery.rem = getClickResponsePerStateForAllDataTypes(...
                    epochsData, iRem{iStim}, iStim, clickRateHz, params);
        end
        fprintf('Finished %s-%d ch%d - time: %ds\n',sessInfo.animal,sessInfo.animalSession,ch,round(toc))
    end
    if isDefaultBins
        [sessFilePath,~,fileDir] = getClickResponsePerStateAnalysisFilePath(sessInfo,isClicks);
    else
        [sessFilePath,~,fileDir] = getClickResponsePerStateAndBinsAnalysisFilePath(sessInfo,isClicks,nBins);
    end
    makeDirIfNeeded(fileDir)
    parforSaveBaselineResponse(sessFilePath,baseline,baselineAll,response,responseAll,params)
end

