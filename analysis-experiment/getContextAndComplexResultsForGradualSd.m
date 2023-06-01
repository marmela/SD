function [unitData,sessData, channelData] = getContextAndComplexResultsForGradualSd(...
    contextSessions,complexSessions,iSdBin,nTotalSdBins)

i40HzClicksContext = 5;
i40HzClicksComplex = 1;
ALPHA_STAT = 0.001;

nContextSessions= length(contextSessions);
nComplexSessions= length(complexSessions);
allSessions = [contextSessions,complexSessions];
isContextSession = [true(1,nContextSessions), false(1,nComplexSessions)];
yokedPostOnsetDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Post Onset'];
nSessions = length(allSessions);
for iSess = 1:nSessions
    clear unitDataCurrentSess channelDataCurrentSess normRealLockingPerClickRate normSimLockingPerClickRate
    isCurrentSessContext = isContextSession(iSess);
    sessInfo = allSessions{iSess};
    sessionStr = getSessionDirName(sessInfo);
    
    [clicksFilePath,~,~] = getClickResponsePerStateAndBinsAnalysisFilePath(sessInfo,true,nTotalSdBins);
    clicks = load(clicksFilePath);
    
    %% Spike shape and sorting data (MU/SU)
        [filePath,~,~] = getSpikeShapeFilePath(sessInfo);
    spikeShapeData = load(filePath);
    sessionName = getSessionDirName(sessInfo);
    spikesSortingXclFile  = [SdLocalPcDef.ANALYSIS_DIR filesep 'Spikes' filesep ...
        'Sorting' filesep sessionName filesep 'Sorting.xlsx'];
    if (~exist(spikesSortingXclFile,'file'))
        spikesSortingXclFile  = [SdLocalPcDef.ANALYSIS_DIR filesep 'Spikes' filesep ...
        'Sorting' filesep sessionName filesep sprintf('Sorting %s-%d.xlsx',...
        sessInfo.animal,sessInfo.animalSession)];
    end
    sortingTable = readtable(spikesSortingXclFile);
    
    %%
    
    if isCurrentSessContext
        i40HzClicks = i40HzClicksContext;
    else
        i40HzClicks = i40HzClicksComplex;
    end
    
    nChannels = length(clicks.baseline);
    nClickTrains = size(clicks.response,1);
    
    baselinePerCh = cell(nChannels,1);
    responsePerStimAndChannel = cell(nClickTrains,nChannels);
    
    nUnitsInSess = 0;
    nChannelsInSess = 0;
    isSigClickResponseHighest = false(nChannels,1);

    for ch = 1:nChannels
        if isempty(clicks.baseline{ch})
            continue
        end
        
        unitsInCh = length(clicks.baseline{ch}.nrem);
        if unitsInCh>0
            nChannelsInSess = nChannelsInSess + 1;
        end
        nUnitsInSess = nUnitsInSess + unitsInCh;
        baselinePerCh{ch} = clicks.baseline{ch}.sd.pressure{iSdBin};

        
        for iStim = 1:nClickTrains
            responsePerStimAndChannel{iStim,ch} = clicks.response{iStim,ch}.sd.pressure(iSdBin);
        end
    end
    
    baselineAllCh = clicks.baselineAll.sd.pressure{iSdBin}{1};
    for iStim = nClickTrains:-1:1
        responseAllChPerStim{iStim} = clicks.responseAll{iStim}.sd.pressure(iSdBin);
    end
    

    iUnit = nUnitsInSess;
    iValidChannel = nChannelsInSess;
    clear lfpErpPerChAndClickRateReal
    for ch = nChannels:-1:1
        if isempty(clicks.baseline{ch})
            continue
        end
        
        unitsInCh = length(clicks.baseline{ch}.nrem);
        for clus = unitsInCh:-1:1
            unitDataCurrentSess(iUnit).session = sessionStr;
            unitDataCurrentSess(iUnit).isContext = isCurrentSessContext;
            unitDataCurrentSess(iUnit).ch = ch;
            unitDataCurrentSess(iUnit).clus = clus;
            unitDataCurrentSess(iUnit).clusType = getClusTypeFromStr(sortingTable{ch,sprintf('Clus%d',clus)});
            unitDataCurrentSess(iUnit).spikeShape = spikeShapeData.spk(ch,clus);
            
            currentClusBaseline = baselinePerCh{ch}{clus};
            unitDataCurrentSess(iUnit).baseFr = currentClusBaseline.magnitudeHz;
            unitDataCurrentSess(iUnit).baseFanoFactor = currentClusBaseline.fanoFactor;
            unitDataCurrentSess(iUnit).baseIsiCv = currentClusBaseline.isiCv;
            unitDataCurrentSess(iUnit).basePopCoupling = currentClusBaseline.populationCoupling;
            
            currentUnitAndStimResponse = responsePerStimAndChannel{i40HzClicks,ch}.spikesPerClus{clus};
            
            
            unitDataCurrentSess(iUnit).clicks40Hz.clicksOnsetFr = currentUnitAndStimResponse.onset.magnitude;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksPostOnsetFr = currentUnitAndStimResponse.postOnset.magnitude;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksOnsetNormFr = currentUnitAndStimResponse.onset.magnitudeNormalized;
            
            unitDataCurrentSess(iUnit).clicks40Hz.clicksLockedFr = currentUnitAndStimResponse.sustainedLocked.magnitude;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksLockedP = currentUnitAndStimResponse.sustainedLocked.stats.p;
            
            unitDataCurrentSess(iUnit).clicks40Hz.clicksSustainedFr = currentUnitAndStimResponse.sustained.magnitude;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksSustainedNormFr = currentUnitAndStimResponse.sustained.magnitudeNormalized;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksSustainedP = currentUnitAndStimResponse.sustained.stats.p;
            
            unitDataCurrentSess(iUnit).clicks40Hz.clicksOffsetFr = currentUnitAndStimResponse.offset.magnitude;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksOffsetNormFr = currentUnitAndStimResponse.offset.magnitudeNormalized;
            unitDataCurrentSess(iUnit).clicks40Hz.clicksOffsetP = currentUnitAndStimResponse.offset.stats.p;
            
            %% Obtain response per click-train
            postOnsetPerClick = nan(nClickTrains,1);
            for iStim = 1:nClickTrains
                currentUnitAndStimResponse = responsePerStimAndChannel{iStim, ch}.spikesPerClus{clus};
                unitDataCurrentSess(iUnit).clicksAll.clicksOnsetFr(iStim) = currentUnitAndStimResponse.onset.magnitude;
                postOnsetPerClick(iStim) = currentUnitAndStimResponse.postOnset.magnitude;
                unitDataCurrentSess(iUnit).clicksAll.clicksOnsetNormFr(iStim) = currentUnitAndStimResponse.onset.magnitudeNormalized;
            end
            if isCurrentSessContext
                unitDataCurrentSess(iUnit).clicksAll.clicksPostOnsetFr = mean(postOnsetPerClick(1:min(2,nClickTrains)));
                for iStim = min(2,nClickTrains):-1:1
                    currentUnitAndStimResponse = responsePerStimAndChannel{iStim, ch}.spikesPerClus{clus};
                    offStatePoisson(iStim) = currentUnitAndStimResponse.offState.probNoSpikes.poisson;
                    offStateBaseline(iStim) = currentUnitAndStimResponse.offState.probNoSpikes.baseline;
                    offStatePostOnset(iStim) = currentUnitAndStimResponse.offState.probNoSpikes.postOnset;
                end
                unitDataCurrentSess(iUnit).offState.poisson = mean(offStatePoisson);
                unitDataCurrentSess(iUnit).offState.baseline = mean(offStateBaseline);
                unitDataCurrentSess(iUnit).offState.postOnset = mean(offStatePostOnset);

                %% Calculate OffState probability for 2Hz Click trains.
                I_STIM_2HZ = 1; %2Hz click train
                currentUnitAndStimResponse = responsePerStimAndChannel{I_STIM_2HZ, ch}.spikesPerClus{clus};
                unitDataCurrentSess(iUnit).offState.perTrial = currentUnitAndStimResponse.offState.perTrial;
                unitDataCurrentSess(iUnit).clicksSim = simulateClickResponsesByClickErp(...
                    currentUnitAndStimResponse.erp,currentUnitAndStimResponse.erpTimesMs,...
                    clicks.params.sustainedTimeMs);
                
                %% Channel Data
                if clus == unitsInCh
                    channelDataCurrentSess(iValidChannel).session = sessionStr;
                    channelDataCurrentSess(iValidChannel).isContext = isCurrentSessContext;
                    channelDataCurrentSess(iValidChannel).ch = ch;
                    iStim = 1; %2Hz click train
                    currentChannelAndStimResponse = responsePerStimAndChannel{iStim, ch}.spikes;
                    channelDataCurrentSess(iValidChannel).offState.offState.perTrial = currentChannelAndStimResponse.offState.perTrial;

                    offStatePoisson = [];
                    offStateBaseline = [];
                    offStatePostOnset = [];
                    for iStim = min(2,nClickTrains):-1:1
                        currentChannelAndStimResponse = responsePerStimAndChannel{iStim, ch}.spikes;
                        offStatePoisson(iStim) = currentChannelAndStimResponse.offState.probNoSpikes.poisson;
                        offStateBaseline(iStim) = currentChannelAndStimResponse.offState.probNoSpikes.baseline;
                        offStatePostOnset(iStim) = currentChannelAndStimResponse.offState.probNoSpikes.postOnset;
                    end
                    channelDataCurrentSess(iValidChannel).offState.poisson = mean(offStatePoisson);
                    channelDataCurrentSess(iValidChannel).offState.baseline = mean(offStateBaseline);
                    channelDataCurrentSess(iValidChannel).offState.postOnset = mean(offStatePostOnset);
                    
                    iValidChannel = iValidChannel -1;
                end
            else
                unitDataCurrentSess(iUnit).clicksAll.clicksPostOnsetFr = nan;
                unitDataCurrentSess(iUnit).offState = [];
                unitDataCurrentSess(iUnit).clicksSim = [];
            end
            unitDataCurrentSess(iUnit).clicksAll.clicksPostOnsetFrAll = postOnsetPerClick;
            %             unitDataCurrentSess(iUnit).clicksOnsetNormFr = mean(onsetNormPerClick);
            
            
            for iStim = nClickTrains:-1:1
                currentUnitAndStimResponse = responsePerStimAndChannel{iStim, ch}.spikesPerClus{clus};
                unitDataCurrentSess(iUnit).clicksAll.clicksLockedFr(iStim) = currentUnitAndStimResponse.sustainedLocked.magnitude;
                unitDataCurrentSess(iUnit).clicksAll.clicksLockedP(iStim) = currentUnitAndStimResponse.sustainedLocked.stats.p;
                
                unitDataCurrentSess(iUnit).clicksAll.clicksSustainedFr(iStim) = currentUnitAndStimResponse.sustained.magnitude;
                unitDataCurrentSess(iUnit).clicksAll.clicksSustainedNormFr(iStim) = currentUnitAndStimResponse.sustained.magnitudeNormalized;
                unitDataCurrentSess(iUnit).clicksAll.clicksSustainedP(iStim) = currentUnitAndStimResponse.sustained.stats.p;
                
                unitDataCurrentSess(iUnit).clicksAll.clicksOffsetFr(iStim) = currentUnitAndStimResponse.offset.magnitude;
                unitDataCurrentSess(iUnit).clicksAll.clicksOffsetNormFr(iStim) = currentUnitAndStimResponse.offset.magnitudeNormalized;
                unitDataCurrentSess(iUnit).clicksAll.clicksOffsetP(iStim) = currentUnitAndStimResponse.offset.stats.p;
                
            end
            
            %%
            iUnit = iUnit - 1;
        end
        %% LFP - channel data
        I_STIM_SINGLE_CLICK = 1;
        if isCurrentSessContext
            lockingPerClickRate = nan(nClickTrains,1);
            lfpTimesMs = responsePerStimAndChannel{1,ch}.lfp.erpTimesMs;
            onsetLfpTimesMs = [0,200];
            isOnsetTime = lfpTimesMs>=onsetLfpTimesMs(1) & lfpTimesMs<onsetLfpTimesMs(2);
            erpOnset = responsePerStimAndChannel{1,ch}.lfp.erp(isOnsetTime);
            onsetClickLock = max(erpOnset)-min(erpOnset);
            clickErp = responsePerStimAndChannel{I_STIM_SINGLE_CLICK,ch}.lfp.erp;
            clear lfpErpPerClickRateReal
            for iStim = nClickTrains:-1:1
                lockingPerClickRate(iStim) = responsePerStimAndChannel{iStim,ch}.lfp.sustainedLocked.magnitude;
                lfpErpPerClickRateReal(iStim,:) = responsePerStimAndChannel{iStim,ch}.lfp.erp;
            end
            
            pLfpHighestClickRate = responsePerStimAndChannel{nClickTrains,ch}.lfp.sustainedLocked.stats.p;
            res = simulateClickResponsesByClickErp(clickErp,lfpTimesMs,clicks.params.sustainedTimeMs);

            isSigClickResponseHighest(ch) = pLfpHighestClickRate<ALPHA_STAT;
            normRealLockingPerClickRate(ch,:) = lockingPerClickRate(2:end)./ onsetClickLock; %lockingPerClickRate(1);
            normSimLockingPerClickRate(ch,:) = res.lockingPerClickRate./ onsetClickLock; %lockingPerClickRate(1);
        end
        1;
    end
    
    %%
    if ~exist('unitData','var')
        unitData = unitDataCurrentSess;
    else
        unitData = [unitData, unitDataCurrentSess];
    end
    
    if ~exist('channelData','var')
        channelData = channelDataCurrentSess;
    elseif exist('channelDataCurrentSess','var')
        channelData = [channelData, channelDataCurrentSess];    
    end
    
    sessData(iSess).session = sessionStr;
    sessData(iSess).isContext = isCurrentSessContext;
    sessData(iSess).baseFr = baselineAllCh.magnitudeHz;
    sessData(iSess).baseFanoFactor50MsPerTrial = baselineAllCh.fanoFactor.perTrial50MsBin;
    sessData(iSess).baseFanoFactorAcrossTrial = baselineAllCh.fanoFactor.entireBaseline;
    sessData(iSess).isiCv = baselineAllCh.isiCv;
    
    EEG_CHANNEL = 1;
    DELTA_BAND_HZ = [0.3,2];
    DELTA_THETA_BAND_HZ = [2,6];
    BETA_BAND_HZ = [13,30];
    GAMMA_BAND_HZ = [40,100];
    
    allSpikesResponse40Hz = responseAllChPerStim{i40HzClicks}.spikes;
    allLfpResponse40Hz = responseAllChPerStim{i40HzClicks}.lfp;
    allEegResponse40Hz = responseAllChPerStim{i40HzClicks}.eeg(EEG_CHANNEL);
    sessData(iSess).clicks40Hz.clicksOnsetFr = allSpikesResponse40Hz.onset.magnitude;
    sessData(iSess).clicks40Hz.clicksPostOnsetFr = allSpikesResponse40Hz.postOnset.magnitude;
    sessData(iSess).clicks40Hz.clicksOnsetNormFr = allSpikesResponse40Hz.onset.magnitudeNormalized;
    
    sessData(iSess).clicks40Hz.clicksLockedFr = allSpikesResponse40Hz.sustainedLocked.magnitude;
    sessData(iSess).clicks40Hz.clicksLockedP = allSpikesResponse40Hz.sustainedLocked.stats.p;
    sessData(iSess).clicks40Hz.clicksSustainedFr = allSpikesResponse40Hz.sustained.magnitude;
    sessData(iSess).clicks40Hz.clicksSustainedNormFr = allSpikesResponse40Hz.sustained.magnitudeNormalized;
    sessData(iSess).clicks40Hz.clicksSustainedP = allSpikesResponse40Hz.sustained.stats.p;
    sessData(iSess).clicks40Hz.clicksOffsetFr = allSpikesResponse40Hz.offset.magnitude;
    sessData(iSess).clicks40Hz.clicksOffsetNormFr = allSpikesResponse40Hz.offset.magnitudeNormalized;
    sessData(iSess).clicks40Hz.clicksOffsetP = allSpikesResponse40Hz.offset.stats.p;
    
    sessData(iSess).clicks40Hz.clicksOnsetLfp = allLfpResponse40Hz.onset.magnitude;
    sessData(iSess).clicks40Hz.clicksPostOnsetLfp  = allLfpResponse40Hz.postOnset.magnitude;
    sessData(iSess).clicks40Hz.clicksLockedLfp = allLfpResponse40Hz.sustainedLocked.magnitude;
    sessData(iSess).clicks40Hz.clicksLockedLfpP = allLfpResponse40Hz.sustainedLocked.stats.p;
    sessData(iSess).clicks40Hz.clicksSustainedLfp = allLfpResponse40Hz.sustained.magnitude;
    sessData(iSess).clicks40Hz.clicksSustainedLfpP = allLfpResponse40Hz.sustained.stats.p;
    sessData(iSess).clicks40Hz.clicksOffsetLfp = allLfpResponse40Hz.offset.magnitude;
    sessData(iSess).clicks40Hz.clicksOffsetLfpP = allLfpResponse40Hz.offset.stats.p;
    
    eegFreqs = allEegResponse40Hz.baseline.power.freqs;
    eegDeltaPower = mean(allEegResponse40Hz.baseline.power.dbPerFreq(...
        eegFreqs>=DELTA_BAND_HZ(1) & eegFreqs<=DELTA_BAND_HZ(2)));
    eegThetaPower = mean(allEegResponse40Hz.baseline.power.dbPerFreq(...
        eegFreqs>=DELTA_THETA_BAND_HZ(1) & eegFreqs<=DELTA_THETA_BAND_HZ(2)));
    eegBetaPower = mean(allEegResponse40Hz.baseline.power.dbPerFreq(...
        eegFreqs>=BETA_BAND_HZ(1) & eegFreqs<=BETA_BAND_HZ(2)));
    eegGammaPower = mean(allEegResponse40Hz.baseline.power.dbPerFreq(...
        eegFreqs>=GAMMA_BAND_HZ(1) & eegFreqs<=GAMMA_BAND_HZ(2)));
    eegPowerPerFreq = allEegResponse40Hz.baseline.power.dbPerFreq;
    
    sessData(iSess).clicks40Hz.eegDeltaPower = mean(eegDeltaPower);
    sessData(iSess).clicks40Hz.eegThetaPower = mean(eegThetaPower);
    sessData(iSess).clicks40Hz.eegBetaPower = mean(eegBetaPower);
    sessData(iSess).clicks40Hz.eegGammaPower = mean(eegGammaPower);
    sessData(iSess).clicks40Hz.eegPowerPerFreq = mean(eegPowerPerFreq);
    sessData(iSess).clicks40Hz.eegFreqs = eegFreqs;
    
    sessData(iSess).clicks40Hz.clicksLockedEeg = allEegResponse40Hz.sustainedLocked.magnitude;
    sessData(iSess).clicks40Hz.clicksLockedEegP = allEegResponse40Hz.sustainedLocked.stats.p;
    
    %% Obtain sess data per click train
    
    for iStim = nClickTrains:-1:1
        allSpikesResponse = responseAllChPerStim{iStim}.spikes;
        sessData(iSess).clicksAll.clicksOnsetFr(iStim) = allSpikesResponse.onset.magnitude;
        postOnsetPerClick(iStim) = allSpikesResponse.postOnset.magnitude;
        sessData(iSess).clicksAll.clicksOnsetNormFr(iStim) = allSpikesResponse.onset.magnitudeNormalized;
        
    end
    sessData(iSess).clicksPostOnsetFr = mean(postOnsetPerClick(1:min(2,nClickTrains)));
    
    if isCurrentSessContext
        for iStim = min(2,nClickTrains):-1:1
            allSpikesResponse = responseAllChPerStim{iStim}.spikes;
            offStatePoisson(iStim) = allSpikesResponse.offState.probNoSpikes.poisson;
            offStateBaseline(iStim) = allSpikesResponse.offState.probNoSpikes.baseline;
            offStatePostOnset(iStim) = allSpikesResponse.offState.probNoSpikes.postOnset;
        end
        sessData(iSess).offState.poisson = mean(offStatePoisson);
        sessData(iSess).offState.baseline = mean(offStateBaseline);
        sessData(iSess).offState.postOnset = mean(offStatePostOnset);
        
        %% Calculate OffState probability for 2Hz Click trains.
        iStim = 1; %2Hz click train
        allSpikesResponse = responseAllChPerStim{iStim}.spikes;
        sessData(iSess).offState.perTrial = allSpikesResponse.offState.perTrial;
        1;
    else
        sessData(iSess).offState = [];
    end

    
    for iStim = nClickTrains:-1:1
        allSpikesResponse = responseAllChPerStim{iStim}.spikes;
        allLfpResponse = responseAllChPerStim{iStim}.lfp;
        allEegResponse = responseAllChPerStim{iStim}.eeg(EEG_CHANNEL);
        sessData(iSess).clicksAll.clicksLockedFr(iStim) = allSpikesResponse.sustainedLocked.magnitude;
        sessData(iSess).clicksAll.clicksLockedP(iStim) = allSpikesResponse.sustainedLocked.stats.p;
        
        sessData(iSess).clicksAll.clicksSustainedFr(iStim) = allSpikesResponse.sustained.magnitude;
        sessData(iSess).clicksAll.clicksSustainedNormFr(iStim) = allSpikesResponse.sustained.magnitudeNormalized;
        sessData(iSess).clicksAll.clicksSustainedP(iStim) = allSpikesResponse.sustained.stats.p;
        
        sessData(iSess).clicksAll.clicksOffsetFr(iStim) = allSpikesResponse.offset.magnitude;
        sessData(iSess).clicksAll.clicksOffsetNormFr(iStim) = allSpikesResponse.offset.magnitudeNormalized;
        sessData(iSess).clicksAll.clicksOffsetP(iStim) = allSpikesResponse.offset.stats.p;
        
        %     end
        sessData(iSess).clicksAll.clicksOnsetLfp(iStim) = allLfpResponse.onset.magnitude;
        sessData(iSess).clicksAll.clicksPostOnsetLfp(iStim)  = allLfpResponse.postOnset.magnitude;
        sessData(iSess).clicksAll.clicksLockedLfp(iStim) = allLfpResponse.sustainedLocked.magnitude;
        sessData(iSess).clicksAll.clicksLockedLfpP(iStim) = allLfpResponse.sustainedLocked.stats.p;
        sessData(iSess).clicksAll.clicksSustainedLfp(iStim) = allLfpResponse.sustained.magnitude;
        sessData(iSess).clicksAll.clicksSustainedLfpP(iStim) = allLfpResponse.sustained.stats.p;
        sessData(iSess).clicksAll.clicksOffsetLfp(iStim) = allLfpResponse.offset.magnitude;
        sessData(iSess).clicksAll.clicksOffsetLfpP(iStim) = allLfpResponse.offset.stats.p;
        
        
        
        eegFreqs = allEegResponse.baseline.power.freqs;
        eegDeltaPower(iStim) = mean(allEegResponse.baseline.power.dbPerFreq(...
            eegFreqs>=DELTA_BAND_HZ(1) & eegFreqs<=DELTA_BAND_HZ(2)));
        eegThetaPower(iStim) = mean(allEegResponse.baseline.power.dbPerFreq(...
            eegFreqs>=DELTA_THETA_BAND_HZ(1) & eegFreqs<=DELTA_THETA_BAND_HZ(2)));
        eegBetaPower(iStim) = mean(allEegResponse.baseline.power.dbPerFreq(...
            eegFreqs>=BETA_BAND_HZ(1) & eegFreqs<=BETA_BAND_HZ(2)));
        eegGammaPower(iStim) = mean(allEegResponse.baseline.power.dbPerFreq(...
            eegFreqs>=GAMMA_BAND_HZ(1) & eegFreqs<=GAMMA_BAND_HZ(2)));
        eegPowerPerFreq(iStim,:) = allEegResponse.baseline.power.dbPerFreq;
    end
    
    if isCurrentSessContext
        iClickStim = 1;
        clickLfpResponse = responseAllChPerStim{iClickStim}.lfp;
        sessData(iSess).clicksSim = simulateClickResponsesByClickErp(clickLfpResponse.erp,clickLfpResponse.erpTimesMs,...
            clicks.params.sustainedTimeMs);
        
        sessData(iSess).clicksSim.meanAcrossChannel.real = mean(normRealLockingPerClickRate(isSigClickResponseHighest,:));
        sessData(iSess).clicksSim.meanAcrossChannel.sim = mean(normSimLockingPerClickRate(isSigClickResponseHighest,:));
        sessData(iSess).clicksSim.meanAcrossChannel.clickRates = res.clickRates;
    else
        sessData(iSess).clicksSim = [];
    end
        
    
    sessData(iSess).clicksAll.eegDeltaPower = mean(eegDeltaPower);
    sessData(iSess).clicksAll.eegThetaPower = mean(eegThetaPower);
    sessData(iSess).clicksAll.eegBetaPower = mean(eegBetaPower);
    sessData(iSess).clicksAll.eegGammaPower = mean(eegGammaPower);
    sessData(iSess).clicksAll.eegPowerPerFreq = mean(eegPowerPerFreq);
    sessData(iSess).clicksAll.eegFreqs = eegFreqs;
    
    
    fprintf('Finished %s - SD #%d\n', sessionStr, iSdBin);
end

function clusType = getClusTypeFromStr(str)
if contains(str,'noise','IgnoreCase',true)
    clusType = 'Noise';
elseif contains(str,'MU','IgnoreCase',true)
    if contains(str,'SU','IgnoreCase',true)
        clusType = 'SU/MU';
    else
        clusType = 'MU';
    end
elseif contains(str,'SU')
    clusType = 'SU';
else
    clusType = 'Unknown';
end

    
1;
