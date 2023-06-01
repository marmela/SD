function saveStateOfInterStimulusIntervals(allSessions)

PRE_WHEEL_MOVE_BUFFER_SEC = 0.8;
POST_WHEEL_MOVE_BUFFER_SEC = 2.2;
MIN_WHEEL_MOVE_LENGTH = 5;
MS_IN_1SEC = 1000;
PRE_STIM_ONSET_MS = -500; %begin ISI period 500ms *after* previous sound offset
POST_STIM_OFFSET_MS = -100; %end ISI period 100ms *before* next sound offset
MIN_ISI_LENGTH_SEC = 5;
clickLengthMs = 500;
clickRateHz = [2,10,20,30,40];
statePerStimAnalysisDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'State\StatePerStim'];

%%
for iSess = length(allSessions):-1:1
    %% Load Wheel/Scoring/Stimuli
    sessionInfo =  allSessions{iSess};
    wheelDirPath = getWheelAnalysisDirPath(sessionInfo);
    wheelFilename = getWheelAnalysisFilename(sessionInfo);
    wheel = load([wheelDirPath filesep wheelFilename]);
    sleepScoringDirPath = getSleepScoringDirPath(sessionInfo);
    scoring = load([sleepScoringDirPath filesep 'sleep_scoring_final.mat']);
    stimsDir = getAuditoryStimsAnalysisDirPath(sessionInfo.animal,sessionInfo.animalSession);
    stimuli = load([stimsDir,filesep, getTtlStampsFilename()]);
    
    %% Add buffer to wheel movements and get wheel movement times
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
    sleepStateToScoreValue = containers.Map(scoring.scroeStrings, scoring.outputScoreValues);
    
    %% get state per rep for every click rate and save
    isiOnsetIndices = find(stimuli.stampValues==ParadigmConsts.STIM_OFFSET_ID);
    if isiOnsetIndices(end)>=length(stimuli.stampTimesSec)
        isiOnsetIndices(end) = [];
    end
    isiOnsetSec = stimuli.stampTimesSec(isiOnsetIndices);
    isiOffsetSec = stimuli.stampTimesSec(isiOnsetIndices+1);
    isiLengthSec = isiOffsetSec-isiOnsetSec;
    isIsiTooShort = isiLengthSec<MIN_ISI_LENGTH_SEC;
    isiOnsetSec(isIsiTooShort) = [];
    isiOffsetSec(isIsiTooShort) = [];
    isiLengthSec(isIsiTooShort) = [];
    statePerIsi = getStatePerIsi(isiOnsetSec, isiOffsetSec, wheel, isWheelMoving, ...
        firstWheelMoveSec, lastWheelMoveSec, scoring, PRE_STIM_ONSET_MS, POST_STIM_OFFSET_MS);
    fileName = sprintf('ISI-%s-%d',sessionInfo.animal,sessionInfo.animalSession);
    filePath = [statePerStimAnalysisDir filesep fileName];
    save(filePath, 'statePerIsi', 'sleepStateToScoreValue', 'PRE_STIM_ONSET_MS',...
        'POST_STIM_OFFSET_MS')
    disp(fileName);
    
    %% some checks that no wheel / more than one score in each segment
    nSegs = length(statePerIsi);
    for iSeg = 1:nSegs
        iOnset = round(statePerIsi(iSeg).onsetSec*1000);
        iOffset = round(statePerIsi(iSeg).offsetSec*1000)-1;
        if any(isWheelMoving(iOnset:iOffset))
            warning('Error, wheel moving seg %d\n',iSeg)
        end
        if length(unique(scoring.scoring(iOnset:iOffset)))>1
            warning('Error, too many scores %d\n',iSeg)
        end
    end
    
end

end

%% get state info per each repetition
function statePerSeg = getStatePerIsi(isiOnsetSec, isiOffsetSec,wheel,isWheelMoving,firstWheelMoveSec,lastWheelMoveSec,...
    scoring,preStimOnsetTimeMs,postStimOffsetTimeMs)

MS_IN_1SEC = 1000;

isClickAfterSd = isiOnsetSec>lastWheelMoveSec;
isClickDuringSd = isiOnsetSec>firstWheelMoveSec & isiOnsetSec<=lastWheelMoveSec;
nRepsStim = length(isiOnsetSec);
sleepScorePerRep = nan(nRepsStim,1);
isQuiescentPerRep = false(nRepsStim,1);
timeFromLastWheelMoveSec = nan(nRepsStim,1);
nMoves = height(wheel.wheelMovementsSec);

%% Get time from last wheel move per rep
%start from 2nd index since always looks one back
iSeg=0;
iWheelMove = 2;
for iRep = 1:nRepsStim
    repOnsetSec = isiOnsetSec(iRep)-preStimOnsetTimeMs./MS_IN_1SEC;
    repOnsetMs = round(repOnsetSec*MS_IN_1SEC);
    repOffsetSec = isiOffsetSec(iRep)+postStimOffsetTimeMs./MS_IN_1SEC;
    repOffsetMs = round(repOffsetSec*MS_IN_1SEC);
    repMsIndices = repOnsetMs:repOffsetMs;
    
    if (repMsIndices(1)<=0 || repMsIndices(end)>length(scoring.scoring))
        continue;
    end
    scoringDuringRep = scoring.scoring(repMsIndices);
    isWheelMovingDuringRep = [true, isWheelMoving(repMsIndices), true];
    iWheelRestOnset = find(diff(isWheelMovingDuringRep)==-1);
    iWheelRestOffset = find(diff(isWheelMovingDuringRep)==1)-1;
    nWheelRests = length(iWheelRestOnset);
    assert(length(iWheelRestOnset) == length(iWheelRestOnset));
    
    %calculate time from last wheel movement per epoch
    while (repOnsetSec>wheel.wheelMovementsSec.onset(iWheelMove) && iWheelMove<nMoves)
        iWheelMove = iWheelMove + 1;
    end
    timeFromLastWheelMoveSec = repOnsetSec-wheel.wheelMovementsSec.offset(iWheelMove-1);
    
    for iWheelRest = 1:nWheelRests
        scoringDuringSeg = scoringDuringRep(iWheelRestOnset(iWheelRest):iWheelRestOffset(iWheelRest));
        currentWheelRestShiftMs = iWheelRestOnset(iWheelRest) - 1;
        iScoringChanges = [0, find(diff(scoringDuringSeg)~=0), length(scoringDuringSeg)];
        nScoringChanges = length(iScoringChanges)-1;
        for iScoringSeg = 1:nScoringChanges
            iSeg = iSeg + 1;
            currentScoringSegShiftSec = (currentWheelRestShiftMs+iScoringChanges(iScoringSeg))./MS_IN_1SEC;
            statePerSeg(iSeg).onsetSec = repOnsetSec+currentScoringSegShiftSec;
            statePerSeg(iSeg).offsetSec = repOnsetSec+(currentWheelRestShiftMs+iScoringChanges(iScoringSeg+1))./MS_IN_1SEC;
            statePerSeg(iSeg).scoring = scoringDuringSeg(iScoringChanges(iScoringSeg)+1);
            statePerSeg(iSeg).isDuringSd = isClickDuringSd(iRep);
            statePerSeg(iSeg).isAfterSd = isClickAfterSd(iRep);
            statePerSeg(iSeg).isWheelAtRest = true; %for all segments wheel is necessarily at rest
            statePerSeg(iSeg).timeSinceWheelMoveSec = timeFromLastWheelMoveSec + currentScoringSegShiftSec;
        end
        
    end
end

end
