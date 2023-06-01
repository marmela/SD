function calculateAndSaveDrcContextPerState(allSessions)

paradigmName = allSessions{1}.paradigmDir;
drcDir = [SdLocalPcDef.AUDITORY_PARADIGMS_DIR filesep ...
    paradigmName  filesep ParadigmConsts.DRC_TUNING_DIR];
spikesFileNameFormat = 'times_Raw_%03g.mat';
statePerClickAnalysisDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'State\StatePerStim'];
MS_IN_SEC = 1000;
nFirstChordsToIgnore = 5;
iFreqToIgnore = 36; %Anomaly for highest frequency (too many responsive units) - removed in order to not bias the dataset for tuning analysis
%%
listing = dir(drcDir);
lastDrcFileName = listing(end).name;
assert(strcmp(lastDrcFileName(1:4),'DRC_') && strcmp(lastDrcFileName(8:end),'.mat'));
maxDrcNum = str2num(lastDrcFileName(5:7));
assert(~exist([drcDir filesep sprintf('DRC_%03g.mat',maxDrcNum+1)],'file'))
drcs = cell(maxDrcNum,1);
for iDrc = 1:maxDrcNum
    drcs{iDrc} = load([drcDir filesep sprintf('DRC_%03g.mat',iDrc)]);
end
%%
nSessions = length(allSessions);
for iSess = 1:nSessions
    sessInfo = allSessions{iSess};
    clear response unitInfo
    assert(strcmp(sessInfo.paradigmDir,paradigmName));
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    spikesDir =  getSpikesSortingDirPath(sessInfo.animal,sessInfo.animalSession);
    stateFileName = sprintf('DrcContext-%s-%d',sessInfo.animal,sessInfo.animalSession);
    stateFilePath = [statePerClickAnalysisDir filesep stateFileName];
    tmp = load(stateFilePath);
    sleepStateToScoreValue = tmp.sleepStateToScoreValue;
    %%
    statePerStim = tmp.statePerStim;
    [iQw,iNrem, iRem, ~, iAwAll] = getRecoveryPeriodEpochs(statePerStim, sleepStateToScoreValue);
    iRem = iRem{1};
    iNrem = iNrem{1};
    iQw = iQw{1};
    iAw = iAwAll{1};
    nSdPressurePeriods = 3;
    nTimePeriods = 1;
    iSdPerStimAndSdPressure = getSdPeriodEpochs(statePerStim, sleepStateToScoreValue, ...
        nSdPressurePeriods,nTimePeriods);
    iAll = [iQw; iNrem; iRem];
    for iSd = 1:nSdPressurePeriods
        iAll = [iAll; iSdPerStimAndSdPressure{iSd}];
    end
    nSdPressurePeriods = 1;
    nTimePeriods = 3;
    iSdPerStimAndMomentArousal = squeeze(getSdPeriodEpochs(statePerStim, sleepStateToScoreValue, ...
        nSdPressurePeriods,nTimePeriods));
        stimOnsetPerStimAw = statePerStim.onsetSec(iAw);
        stimOnsetPerStimRem = statePerStim.onsetSec(iRem);
        stimOnsetPerStimNrem = statePerStim.onsetSec(iNrem);
        stimOnsetPerStimQwRecovery = statePerStim.onsetSec(iQw);
        stimOnsetPerStimAll = statePerStim.onsetSec(iAll);
        stimIdPerStimAw = statePerStim.drcId(iAw);
        stimIdPerStimRem = statePerStim.drcId(iRem);
        stimIdPerStimNrem = statePerStim.drcId(iNrem);
        stimIdPerStimQwRecovery = statePerStim.drcId(iQw); 
        stimIdPerStimAll = statePerStim.drcId(iAll);
        drcStartTimesSecAw = cell(maxDrcNum,1);
        drcStartTimesSecRem = cell(maxDrcNum,1);
        drcStartTimesSecNrem = cell(maxDrcNum,1);
        drcStartTimesSecQwRecovery = cell(maxDrcNum,1);
        drcStartTimesSecAll = cell(maxDrcNum,1);
        for iDrc = 1:maxDrcNum
            drcStartTimesSecAw{iDrc} = stimOnsetPerStimAw(stimIdPerStimAw==iDrc);
            drcStartTimesSecRem{iDrc} = stimOnsetPerStimRem(stimIdPerStimRem==iDrc);
            drcStartTimesSecNrem{iDrc} = stimOnsetPerStimNrem(stimIdPerStimNrem==iDrc);
            drcStartTimesSecQwRecovery{iDrc} = stimOnsetPerStimQwRecovery(...
                stimIdPerStimQwRecovery==iDrc);
            drcStartTimesSecAll{iDrc} = stimOnsetPerStimAll(stimIdPerStimAll==iDrc);
        end
        for iSdPressure = 1:length(iSdPerStimAndSdPressure)
            currentOnset = statePerStim.onsetSec(iSdPerStimAndSdPressure{iSdPressure});
            currentStimId = statePerStim.drcId(iSdPerStimAndSdPressure{iSdPressure});
            drcStartTimesSecPerSdPressure{iSdPressure} = cell(maxDrcNum,1);
            for iDrc = 1:maxDrcNum
                drcStartTimesSecPerSdPressure{iSdPressure}{iDrc} = currentOnset(currentStimId==iDrc);
            end
        end
        for iTimePeriod = 1:length(iSdPerStimAndMomentArousal)
            currentOnset = statePerStim.onsetSec(iSdPerStimAndMomentArousal{iTimePeriod});
            currentStimId = statePerStim.drcId(iSdPerStimAndMomentArousal{iTimePeriod});
            drcStartTimesSecPerSdArousal{iTimePeriod} = cell(maxDrcNum,1);
            for iDrc = 1:maxDrcNum
                drcStartTimesSecPerSdArousal{iTimePeriod}{iDrc} = currentOnset(currentStimId==iDrc);
            end
        end  
    %%
    unitCount = 0;
    for ch = channels
        spikePath = [spikesDir filesep sprintf(spikesFileNameFormat,ch)];
        if ~exist(spikePath,'file')
            continue;
        end
        spikeTimesData = load(spikePath);
        nClus = max(spikeTimesData.cluster_class(:,1));
        for iClus = 1:nClus
            tic;
            spikeTimesSec = spikeTimesData.cluster_class(spikeTimesData.cluster_class(:,1)==iClus,2)./MS_IN_SEC;
            unitCount = unitCount + 1;
            unitInfo(unitCount).channel = ch;
            unitInfo(unitCount).cluster = iClus;
            response(unitCount).all = getDrcTuningAndContext(spikeTimesSec, ...
                drcStartTimesSecAll, drcs,  nFirstChordsToIgnore,[],iFreqToIgnore);
            peakTimeMs = response(unitCount).all.peakTimeMs;
            response(unitCount).qw = getDrcTuningAndContext(spikeTimesSec, ...
                drcStartTimesSecQwRecovery, drcs,  nFirstChordsToIgnore, peakTimeMs,iFreqToIgnore);
            response(unitCount).rem = getDrcTuningAndContext(spikeTimesSec, ...
                drcStartTimesSecRem, drcs,  nFirstChordsToIgnore, peakTimeMs,iFreqToIgnore);
            response(unitCount).nrem = getDrcTuningAndContext(spikeTimesSec, ...
                drcStartTimesSecNrem, drcs,  nFirstChordsToIgnore, peakTimeMs,iFreqToIgnore);
            response(unitCount).aw = getDrcTuningAndContext(spikeTimesSec, ...
                drcStartTimesSecAw, drcs,  nFirstChordsToIgnore, peakTimeMs,iFreqToIgnore);
            for iSdPressure = 1:length(iSdPerStimAndSdPressure)
                response(unitCount).sd.pressure(iSdPressure) = getDrcTuningAndContext(spikeTimesSec, ...
                    drcStartTimesSecPerSdPressure{iSdPressure}, drcs,  nFirstChordsToIgnore, peakTimeMs,iFreqToIgnore);
            end
            for iTimePeriod = 1:length(iSdPerStimAndMomentArousal)
                response(unitCount).sd.arousal(iTimePeriod) = getDrcTuningAndContext(spikeTimesSec, ...
                    drcStartTimesSecPerSdArousal{iTimePeriod}, drcs,  nFirstChordsToIgnore, peakTimeMs,iFreqToIgnore);
            end
            fprintf('%s-%d Channel %d clus %d     %3gs\n',sessInfo.animal,sessInfo.animalSession,ch,iClus,toc);
        end
        
    end
    
    freqs = drcs{1}.soundData.freqs;
    [sessFilePath,sessFileName,~] = getDrcContextResponsePerStateAnalysisFilePath(sessInfo);
    save(sessFilePath,'response','unitInfo','freqs');
    fprintf('Finished %s\n',sessFileName);
end