function calcAndPlotSwaAndHypnogramAnalysis(sessionsInfo,stateInfoQw, stateInfoNrem, stateInfoRem)

%% Consts
EEG_CHANNEL = 1;
BIN_LENGTH_MS = 2000;
PRE_WHEEL_MOVE_BUFFER_SEC = 2;%0.8;
POST_WHEEL_MOVE_BUFFER_SEC = 3; %2.2;
MIN_WHEEL_MOVE_LENGTH = 5;
MS_IN_1SEC = 1000;

statsDir = [SdLocalPcDef.FIGURES_DIR filesep 'paper' filesep 'Extra' filesep 'HypnogramSWA'];
statsFileName = 'Stats-HypnogramSWA';

%% go over all sessions
nSessions = length(sessionsInfo);
for iSess = 1:nSessions
    sessInfo = sessionsInfo{iSess};
    %% Load Data
    wheelDirPath = getWheelAnalysisDirPath(sessInfo);
    wheelFilename = getWheelAnalysisFilename(sessInfo);
    wheel = load([wheelDirPath filesep wheelFilename]);
    sleepScoringDirPath = getSleepScoringDirPath(sessInfo);
    scoring = load([sleepScoringDirPath filesep 'sleep_scoring_final.mat']);
    eegTraceDirPath = getEegTraceDirPath(sessInfo);
    eegFilename = getEegTraceFilename(EEG_CHANNEL);
    eegFilePath = [eegTraceDirPath filesep eegFilename];
    eeg = load(eegFilePath);
    %%
    wheel.wheelMovementsSec.onset = wheel.wheelMovementsSec.onset - PRE_WHEEL_MOVE_BUFFER_SEC;
    wheel.wheelMovementsSec.offset = wheel.wheelMovementsSec.offset + POST_WHEEL_MOVE_BUFFER_SEC;
    maxTimeSec = length(wheel.data)./wheel.srData;
    maxTimeMs = ceil(maxTimeSec*MS_IN_1SEC);
    isWheelMoving = false(1,maxTimeMs);
    nMoves = height(wheel.wheelMovementsSec);
    for iMove = 1:nMoves
    isWheelMoving(max(1,floor(wheel.wheelMovementsSec.onset(iMove)*MS_IN_1SEC)):...
        ceil(wheel.wheelMovementsSec.offset(iMove)*MS_IN_1SEC)) = true;
    end
    wheelMoveLengthSec = wheel.wheelMovementsSec.offset-wheel.wheelMovementsSec.onset;
    firstWheelMoveSec = wheel.wheelMovementsSec.offset(find(wheelMoveLengthSec>MIN_WHEEL_MOVE_LENGTH,1,'first'));
    lastWheelMoveSec = wheel.wheelMovementsSec.offset(find(wheelMoveLengthSec>MIN_WHEEL_MOVE_LENGTH,1,'last'));
    lastRelevantTimeMs = length(scoring.scoring)-BIN_LENGTH_MS;
    eegWindowOnsetSec = 0:BIN_LENGTH_MS/MS_IN_1SEC:lastRelevantTimeMs/MS_IN_1SEC;
    timePreWindowOnsetMs = 0;
    timePostWindowOnsetMs = BIN_LENGTH_MS;
    statePerRep = getStatePerStim(eegWindowOnsetSec,wheel,isWheelMoving,firstWheelMoveSec,lastWheelMoveSec,...
    scoring,timePreWindowOnsetMs,timePostWindowOnsetMs);
    isValidWindow = ~statePerRep.isArtifact & ~statePerRep.isWheelMoving;
    validWindowsOnsetTimesSec = eegWindowOnsetSec(isValidWindow);
    sleepScoringValid = statePerRep.sleepScoring(isValidWindow);
    isDuringSdValid = statePerRep.isDuringSd(isValidWindow);
    sleepScoringDuringSd = sleepScoringValid(isDuringSdValid);
    stateToScoringMap = containers.Map(scoring.scroeStrings,scoring.outputScoreValues);
    isQwDuringSd = sleepScoringDuringSd == stateToScoringMap('Q-Wake');
    isAwDuringSd = sleepScoringDuringSd == stateToScoringMap('A-Wake');
    isGroomingDuringSd = sleepScoringDuringSd == stateToScoringMap('Grooming');
    isAwakeDuringSd = sleepScoringDuringSd == stateToScoringMap('Wake') | isQwDuringSd | isAwDuringSd | isGroomingDuringSd;
    isDefinedStateDuringSd = ~isnan(sleepScoringDuringSd);
    isNremDuringSd = sleepScoringDuringSd == stateToScoringMap('NREM') | ...
        sleepScoringDuringSd == stateToScoringMap('TRANSITION-NR');
    isRemDuringSd = sleepScoringDuringSd == stateToScoringMap('REM');
    isTransitionDuringSd = sleepScoringDuringSd == stateToScoringMap('TRANSITION-WN');
    isUnknownDuringSd = sleepScoringDuringSd == stateToScoringMap('UNKNOWN');
    isNotAwakeDuringSd = isNremDuringSd | isRemDuringSd | isTransitionDuringSd | isUnknownDuringSd;
    fractionValidPeriods = mean(isDefinedStateDuringSd);
    if fractionValidPeriods<0.9
        warning(sprintf('Too few valid trials in SD: %.3g%%\n',fractionValidPeriods*100))
    end
    fractionInStateSd(iSess).awake = mean(isAwakeDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).notAwake = mean(isNotAwakeDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).qw = mean(isQwDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).aw = mean(isAwDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).grooming = mean(isGroomingDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).nrem = mean(isNremDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).rem = mean(isRemDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).transition = mean(isTransitionDuringSd)./fractionValidPeriods;
    fractionInStateSd(iSess).unknown = mean(isUnknownDuringSd)./fractionValidPeriods;
    isDuringRecoveryPeriod = statePerRep.isAfterSd(isValidWindow);
    sleepScoringDuringRecoveryPeriod = sleepScoringValid(isDuringRecoveryPeriod);
    isQwAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('Q-Wake');
    isAwAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('A-Wake');
    isGroomingAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('Grooming');
    isAwakeAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('Wake') | isQwAfterSd | isAwAfterSd | isGroomingAfterSd;
    isDefinedStateAfterSd = ~isnan(sleepScoringDuringRecoveryPeriod);
    isNremAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('NREM') | ...
        sleepScoringDuringRecoveryPeriod == stateToScoringMap('TRANSITION-NR');
    isRemAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('REM');
    isTransitionAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('TRANSITION-WN');
    isUnknownAfterSd = sleepScoringDuringRecoveryPeriod == stateToScoringMap('UNKNOWN');
    isNotAwakeAfterSd = isNremAfterSd | isRemAfterSd | isTransitionAfterSd | isUnknownAfterSd;
    fractionValidPeriods = mean(isDefinedStateAfterSd);
    if fractionValidPeriods<0.9
        warning(sprintf('Too few valid trials in recovery sleep period: %.3g%%\n',fractionValidPeriods*100))
    end
    fractionInStateRecovery(iSess).awake = mean(isAwakeAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).notAwake = mean(isNotAwakeAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).qw = mean(isQwAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).aw = mean(isAwAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).grooming = mean(isGroomingAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).nrem = mean(isNremAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).rem = mean(isRemAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).transition = mean(isTransitionAfterSd)./fractionValidPeriods;
    fractionInStateRecovery(iSess).unknown = mean(isUnknownAfterSd)./fractionValidPeriods;

    %%
    clear isInState;
    isInState{3} = scoring.scoring == stateToScoringMap('Q-Wake') | scoring.scoring == stateToScoringMap('A-Wake');
    isInState{2} = scoring.scoring == stateToScoringMap('NREM');
    isInState{1} = scoring.scoring == stateToScoringMap('REM');
    
    %%
    preTimeSec = timePreWindowOnsetMs/MS_IN_1SEC;
    postTimeSec = timePostWindowOnsetMs/MS_IN_1SEC;
    isRemoveBaseline = false;
    stdOfEpochsStdToReject = 8;
    stdOfValuesToReject = 10;
    MEDUSA_EEG_SCALE = 20;
    eegDataMicroVolts = eeg.data./MEDUSA_EEG_SCALE;
    [erp,times,allEpochs,noisyEpochs, semEpochs,isInvalidEvent] = getErp(eegDataMicroVolts, eeg.srData,...
    validWindowsOnsetTimesSec, preTimeSec, postTimeSec, isRemoveBaseline, stdOfEpochsStdToReject, ...
    stdOfValuesToReject);
    validWindowsOnsetTimesSec(isInvalidEvent)=[];
    allEpochs(isInvalidEvent,:)=[];
    frequencies = 1:0.5:4;
    nEpochs = size(allEpochs,1);
    swaPerEpoch = nan(nEpochs,1);
    for iEpoch = 1:nEpochs
        currentEpoch = allEpochs(iEpoch,:);
        pxx = pwelch(currentEpoch,length(currentEpoch),0,frequencies,eeg.srData);
        swaPerEpoch(iEpoch) = mean(pxx);
    end
    allQwSdTrials = find(sleepScoringValid(~isInvalidEvent)== stateToScoringMap('Q-Wake') & ...
        isDuringSdValid(~isInvalidEvent)');
    sdFirstThirdTrials = allQwSdTrials(1:floor(length(allQwSdTrials)./3));
    sdLastThirdTrials = allQwSdTrials(ceil(length(allQwSdTrials).*(2/3)):end);
    allNremTrials = find(sleepScoringValid(~isInvalidEvent)== stateToScoringMap('NREM') & ...
        isDuringRecoveryPeriod(~isInvalidEvent)');
    nremFirstThirdTrials = allNremTrials(1:floor(length(allNremTrials)./3));
    nremLastThirdTrials = allNremTrials(ceil(length(allNremTrials).*(2/3)):end);
    swaPowerPerSess(iSess).vigilant = nanmean(swaPerEpoch(sdFirstThirdTrials));
    swaPowerPerSess(iSess).tired = nanmean(swaPerEpoch(sdLastThirdTrials));
    swaPowerPerSess(iSess).allSdQw = nanmean(swaPerEpoch(allQwSdTrials));
    swaPowerPerSess(iSess).nrem = nanmean(swaPerEpoch(allNremTrials));
    swaPowerPerSess(iSess).nremFirstThird = nanmean(swaPerEpoch(nremFirstThirdTrials));
    swaPowerPerSess(iSess).nremLastThird = nanmean(swaPerEpoch(nremLastThirdTrials));
    1;
end

swAnalysis.swaPowerPerSess = swaPowerPerSess;
vigilantPowerPerSess = extractfield(swaPowerPerSess,'vigilant');
tiredPowerPerSess = extractfield(swaPowerPerSess,'tired');
nremFirstThirdPowerPerSess = extractfield(swaPowerPerSess,'nremFirstThird');
nremLastThirdPowerPerSess = extractfield(swaPowerPerSess,'nremLastThird');
miTiredVigilant = getGainIndex(tiredPowerPerSess,vigilantPowerPerSess);
miNremFirstThirdTired = getGainIndex(nremFirstThirdPowerPerSess,tiredPowerPerSess);
fields = fieldnames(swaPowerPerSess);
nFields = length(fields);

for iField = 1:nFields
    fieldStr = fields{iField};
    allSessionsPower = extractfield(swaPowerPerSess,fieldStr);
    swAnalysis.(fieldStr).mean = mean(allSessionsPower);
    swAnalysis.(fieldStr).std = std(allSessionsPower);
    swAnalysis.(fieldStr).sem = std(allSessionsPower)./sqrt(nSessions);
end
swAnalysis.units = '1-4 Hz Power (microVolt^2/Hz)';

hypnogramAnalysis.sd.fractionInStatePerSess = fractionInStateSd;
hypnogramAnalysis.recovery.fractionInStatePerSess = fractionInStateRecovery;
fields = fieldnames(fractionInStateSd);
nFields = length(fields);
for iField = 1:nFields
    fieldStr = fields{iField};
    allSessionsFractionInStateSd = extractfield(fractionInStateSd,fieldStr);
    hypnogramAnalysis.sd.(fieldStr).mean = mean(allSessionsFractionInStateSd);
    hypnogramAnalysis.sd.(fieldStr).std = std(allSessionsFractionInStateSd);
    hypnogramAnalysis.sd.(fieldStr).sem = std(allSessionsFractionInStateSd)./sqrt(nSessions);
    
    allSessionsFractionInStateRecovery = extractfield(fractionInStateRecovery,fieldStr);
    hypnogramAnalysis.recovery.(fieldStr).mean = mean(allSessionsFractionInStateRecovery);
    hypnogramAnalysis.recovery.(fieldStr).std = std(allSessionsFractionInStateRecovery);
    hypnogramAnalysis.recovery.(fieldStr).sem = std(allSessionsFractionInStateRecovery)./sqrt(nSessions);
end
makeDirIfNeeded(statsDir);
statsPath = [statsDir filesep statsFileName];
save(statsPath,'hypnogramAnalysis','swAnalysis')

1;
%%
powerWindowSizeSec = 100; %180
powerWindowOnset = 0:powerWindowSizeSec:validWindowsOnsetTimesSec(end);
nWindows = length(powerWindowOnset)-1;
powerPerWin = nan(nWindows,1);
for iWin = 1:nWindows
    isInCurrentWin = validWindowsOnsetTimesSec>=powerWindowOnset(iWin) & ...
        validWindowsOnsetTimesSec<powerWindowOnset(iWin+1);
    if sum(isInCurrentWin)>1
        powerPerWin(iWin) = mean(swaPerEpoch(isInCurrentWin));
    end
end


%%
SEC_IN_1HOUR = 3600;
timesScoringHours = (1:length(scoring.scoring))/MS_IN_1SEC/SEC_IN_1HOUR;
stateToScoringMap = containers.Map(scoring.scroeStrings,scoring.outputScoreValues);
clear isInState;
isInState{3} = scoring.scoring == stateToScoringMap('Q-Wake') | scoring.scoring == stateToScoringMap('A-Wake');
isInState{2} = scoring.scoring == stateToScoringMap('NREM');
isInState{1} = scoring.scoring == stateToScoringMap('REM');
infoPerState{3} = stateInfoQw;
infoPerState{2} = stateInfoNrem;
infoPerState{1} = stateInfoRem;

stateStr = {'REM','NREM','Wake'};
FONT_SIZE = 20;
X_ONSET = 0.1;
WIDTH = 0.87;
XLIM_HOURS = [0,10];
recoverySleepOnsetHours = (lastWheelMoveSec+5)/SEC_IN_1HOUR;
figPositions=[0,50,1600,500];
figure('Position',figPositions);
subplot('position',[X_ONSET,0.17,0.87,0.14])
hold on;
nStates = length(isInState);
for iState = 1:nStates
    currentIsInState =  isInState{iState}';
    currentIsInState = [false; currentIsInState; false];
    changesToAndOutOfState = diff(currentIsInState);
    stateOnsetIndices = find(changesToAndOutOfState==1);
    stateOffsetIndices = find(changesToAndOutOfState==-1);
    nStateEpochs = length(stateOnsetIndices);
    assert(nStateEpochs == length(stateOffsetIndices))
    currentColor = infoPerState{iState}.color;
    for iEpoch = 1:nStateEpochs
        rectangle('Position',[timesScoringHours(stateOnsetIndices(iEpoch)),iState, ...
            timesScoringHours(stateOffsetIndices(iEpoch))-...
            timesScoringHours(stateOnsetIndices(iEpoch)), 1],'FaceColor',currentColor,'EdgeColor',currentColor);
    end
end
ylimCurr = ylim();
plot([recoverySleepOnsetHours,recoverySleepOnsetHours],ylimCurr,'--r','LineWidth',1.5);
set(gca,'YTick',(1:nStates)+0.5,'YTickLabel',stateStr)
xlabel('Time (hours)');
set(gca,'FontSize',FONT_SIZE);
xlim(XLIM_HOURS)

winSizeHour = powerWindowSizeSec/SEC_IN_1HOUR;
EPSILON = 0.001;
barWidth = winSizeHour./EPSILON; % necessary to have fixed bar width across different states with different spacings

timesPowerWin = (powerWindowOnset(1:end-1)+powerWindowSizeSec/2)/SEC_IN_1HOUR;
subplot('position',[X_ONSET,0.34,WIDTH,0.63])
hold on;
maxPower = -Inf;
isAnyState = false(size(powerPerWin,1),size(powerPerWin,2));
for iState = 1:nStates
    currentIsInState =  isInState{iState}';
    currentIsInState = [false; currentIsInState; false];
    changesToAndOutOfState = diff(currentIsInState);
    stateOnsetIndices = find(changesToAndOutOfState==1);
    stateOffsetIndices = find(changesToAndOutOfState==-1);
    stateOnsetHours = timesScoringHours(stateOnsetIndices)';
    stateOffsetHours = timesScoringHours(stateOffsetIndices)';
    currentColor = infoPerState{iState}.color;
    isSwaBinWithinStateRangesPerState{iState} = getIfValuesWithinRanges(...
        timesPowerWin, [stateOnsetHours,stateOffsetHours]);
    isAnyState = isAnyState | isSwaBinWithinStateRangesPerState{iState}';
end
meanPowerPerWin = mean(powerPerWin(isAnyState));
for iState = 1:nStates
    currentColor = infoPerState{iState}.color;
    normPowerPerWinCurrentState = powerPerWin(isSwaBinWithinStateRangesPerState{iState})./meanPowerPerWin*100;
    bar([timesPowerWin(isSwaBinWithinStateRangesPerState{iState}),...
        timesPowerWin(find(isSwaBinWithinStateRangesPerState{iState},1,'last'))+EPSILON],...
        [normPowerPerWinCurrentState; nan],...
        barWidth,'FaceColor',currentColor,'edgeColor','none')
    maxPower = max(maxPower,max(normPowerPerWinCurrentState));
    
end
ylimsData = [0,maxPower];
plot([recoverySleepOnsetHours,recoverySleepOnsetHours],ylimsData,'--r','LineWidth',1.5);
ylim(ylimsData);
xlim(XLIM_HOURS);
ylabel('Norm. SW power (%)');
set(gca,'xTick',[],'yTick',0:100:2000);
set(gca,'FontSize',FONT_SIZE);
figDir = [SdLocalPcDef.FIGURES_DIR filesep 'paper' filesep 'MethodsFig' filesep 'HypnoSWA_Norm'];
makeDirIfNeeded(figDir)
figName = sprintf('HypnoNormSWA-%s-%d',sessInfo.animal,sessInfo.animalSession);
figPath = [figDir filesep figName];
hgexport(gcf,figPath ,hgexport('factorystyle'), 'Format', 'png');
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r300')
savefig(figPath);
end