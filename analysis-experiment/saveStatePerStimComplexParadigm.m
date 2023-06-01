function saveStatePerStimComplexParadigm(allSessions)

PRE_WHEEL_MOVE_BUFFER_SEC = 0.8;
POST_WHEEL_MOVE_BUFFER_SEC = 2.2;
MIN_WHEEL_MOVE_LENGTH = 5;
MS_IN_1SEC = 1000;
PRE_STIM_ONSET_MS = 500;
POST_STIM_OFFSET_MS = 500;
clickStampsPerRate = 101;
clickLengthMs = 500;
clickRateHz = [40];

toneStreamStampsMin = ParadigmConsts.TONE_STREAM_BASE_ID;
toneStreamStampsMax = ParadigmConsts.TONE_STREAM_LAST_POSSIBLE_ID;
drcTuningStampMin = ParadigmConsts.DRC_TUNING_BASE_ID;
drcTuningStampMax = ParadigmConsts.DRC_TUNING_LAST_POSSIBLE_ID;
toneStreamLengthMs = 2000;
statePerStimAnalysisDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'State\StatePerStim'];


%%
for iSess = length(allSessions):-1:1
    %% Load Wheel/Scoring/Stimuli
    sessionInfo =  allSessions{iSess};
    dlc = getDeepLabCutAnalysis(sessionInfo);
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
    
    %% get state per every second of DRC-tuning
    clear statePerStim drcPartOnsetSec drcPartStamp drcPartIndexInDrc
    preStimOnsetTimeMs = 0;
    postStimOnsetTimeMs = 1000;
    iDrcOnset = find(stimuli.stampValues>=drcTuningStampMin & stimuli.stampValues<=drcTuningStampMax);
    nDrcReps = length(iDrcOnset);
    drcTotalPartCount = 0;
    for iDrcRep = 1:nDrcReps
        currentDrcPartIndex = iDrcOnset(iDrcRep);
        currentStamp = stimuli.stampValues(currentDrcPartIndex);
        partInDrcCount = 1;
        
        drcTotalPartCount = drcTotalPartCount+1;
        drcPartOnsetSec(drcTotalPartCount,1) = stimuli.stampTimesSec(currentDrcPartIndex);
        drcPartStamp(drcTotalPartCount,1) = currentStamp;
        drcPartIndexInDrc(drcTotalPartCount,1) = partInDrcCount;
        
        currentDrcPartIndex = currentDrcPartIndex + 1;
        
        nextPartStamp = ParadigmConsts.EVERY_SECOND_BASE_ID+partInDrcCount;

        while nextPartStamp<=ParadigmConsts.EVERY_SECOND_LAST_POSSIBLE_ID && ...
                stimuli.stampValues(currentDrcPartIndex)==nextPartStamp
            drcTotalPartCount = drcTotalPartCount+1;
            partInDrcCount = partInDrcCount + 1;
            drcPartOnsetSec(drcTotalPartCount,1) = stimuli.stampTimesSec(currentDrcPartIndex);
            drcPartStamp(drcTotalPartCount,1) = currentStamp;
            drcPartIndexInDrc(drcTotalPartCount,1) = partInDrcCount;
            nextPartStamp = nextPartStamp+1;
            currentDrcPartIndex = currentDrcPartIndex + 1;
        end
    end
    statePerStim = getStatePerRep(drcPartOnsetSec, dlc, wheel, isWheelMoving, ...
        firstWheelMoveSec, lastWheelMoveSec, scoring, preStimOnsetTimeMs, ...
        postStimOnsetTimeMs);
    statePerStim.stamp = drcPartStamp;
    statePerStim.partIndexInDrc = drcPartIndexInDrc;
    
    fileName = sprintf('DRC-Tuning-%s-%d',sessionInfo.animal,sessionInfo.animalSession);
    filePath = [statePerStimAnalysisDir filesep fileName];
    save(filePath, 'statePerStim', 'sleepStateToScoreValue', 'preStimOnsetTimeMs',...
        'postStimOnsetTimeMs')
    disp(fileName);
    
    %% get state per rep for every click rate and save
    clear statePerStim
    nClickRates = length(clickStampsPerRate);
    preStimOnsetTimeMs = PRE_STIM_ONSET_MS;
    postStimOnsetTimeMs = clickLengthMs+POST_STIM_OFFSET_MS;
    for iClickRate = 1:nClickRates
        clickOnsetSec = stimuli.stampTimesSec(stimuli.stampValues==clickStampsPerRate(iClickRate));
        statePerRepCurrentStim = getStatePerRep(clickOnsetSec, dlc, wheel, isWheelMoving, ...
            firstWheelMoveSec, lastWheelMoveSec, scoring, preStimOnsetTimeMs, ...
            postStimOnsetTimeMs);
        statePerRepCurrentStim.clickRateHz = clickRateHz(iClickRate);
        statePerRepCurrentStim.stamp = clickStampsPerRate(iClickRate);
        statePerStim(iClickRate) = statePerRepCurrentStim;
    end
    
    fileName = sprintf('Clicks-%s-%d',sessionInfo.animal,sessionInfo.animalSession);
    filePath = [statePerStimAnalysisDir filesep fileName];
    save(filePath, 'statePerStim', 'sleepStateToScoreValue', 'preStimOnsetTimeMs',...
        'postStimOnsetTimeMs')
    disp(fileName);
    
    %% get state for tone stream and save
    clear statePerStim
    toneStreamStamps = unique(stimuli.stampValues(stimuli.stampValues>=toneStreamStampsMin & ...
        stimuli.stampValues<=toneStreamStampsMax));
    nToneStreams = length(toneStreamStamps);
    preStimOnsetTimeMs = PRE_STIM_ONSET_MS;
    postStimOnsetTimeMs = toneStreamLengthMs+POST_STIM_OFFSET_MS;
    
    for iStream = 1:nToneStreams
        streamOnsetSec = stimuli.stampTimesSec(stimuli.stampValues==toneStreamStamps(iStream));
        statePerRepCurrentStim = getStatePerRep(streamOnsetSec, dlc, wheel, isWheelMoving, ...
            firstWheelMoveSec, lastWheelMoveSec, scoring, preStimOnsetTimeMs, ...
            postStimOnsetTimeMs);
        statePerRepCurrentStim.stamp = toneStreamStamps(iStream);
        statePerStim(iStream) = statePerRepCurrentStim;
    end
    fileName = sprintf('ToneStream-%s-%d',sessionInfo.animal,sessionInfo.animalSession);
    filePath = [statePerStimAnalysisDir filesep fileName];
    save(filePath, 'statePerStim', 'sleepStateToScoreValue', 'preStimOnsetTimeMs',...
        'postStimOnsetTimeMs')
    disp(fileName);
    
end

end

%% get state info per each repetition
function statePerRep = getStatePerRep(stimOnsetSec, dlc, wheel, isWheelMoving, ...
    firstWheelMoveSec, lastWheelMoveSec, scoring, preStimOnsetTimeMs, postStimOnsetTimeMs)

MS_IN_1SEC = 1000;
TIMES_TO_CALC_VIDEO_MOVE_SEC = [-3,1];
minLikelihoodMove = 0.99;
minProportionOfValidFrames = 0.9;

minNFrames = floor(diff(TIMES_TO_CALC_VIDEO_MOVE_SEC)*dlc.sr*minProportionOfValidFrames);

isClickAfterSd = stimOnsetSec>lastWheelMoveSec;
isClickDuringSd = stimOnsetSec>firstWheelMoveSec & stimOnsetSec<=lastWheelMoveSec;
nRepsStim = length(stimOnsetSec);
sleepScorePerRep = nan(nRepsStim,1);
isQuiescentPerRep = false(nRepsStim,1);
timeFromLastWheelMoveSec = nan(nRepsStim,1);
nMoves = height(wheel.wheelMovementsSec);
nBodyParts = width(dlc.likelihoodTable);
movementPerBodyPart.x = nan(nRepsStim,nBodyParts);
movementPerBodyPart.y = nan(nRepsStim,nBodyParts);
locationPerBodyPart.x = nan(nRepsStim,nBodyParts);
locationPerBodyPart.y = nan(nRepsStim,nBodyParts);
anglePerBodyPartPair = nan(nRepsStim,nBodyParts,nBodyParts);
distancePerBodyPartPair = nan(nRepsStim,nBodyParts,nBodyParts);
probPerBodyPart = nan(nRepsStim,nBodyParts);
probPerTwoBodyParts = nan(nRepsStim,nBodyParts,nBodyParts);


%% Get time from last wheel move per rep
%start from 2nd index since always looks one back
iWheelMove = 2;
for iRep = 1:nRepsStim
    repOnsetSec = stimOnsetSec(iRep);
    repOnsetMs = round(repOnsetSec*MS_IN_1SEC);
    repMsIndices = repOnsetMs-preStimOnsetTimeMs:repOnsetMs+postStimOnsetTimeMs;
    
    if (repMsIndices(1)<=0 || repMsIndices(end)>length(scoring.scoring))
        continue;
    end
    
    scoringDuringRep = scoring.scoring(repMsIndices);
    % only if solely 1 sleep-state during entire trial give a state for such trial
    if length(unique(scoringDuringRep))==1
        sleepScorePerRep(iRep) = scoringDuringRep(1);
    end
    isWheelMovingDuringRep = isWheelMoving(repMsIndices);
    isQuiescentPerRep(iRep) = ~any(isWheelMovingDuringRep);
    
    %calculate time from last wheel movement per epoch
    while (repOnsetSec>wheel.wheelMovementsSec.onset(iWheelMove) && iWheelMove<nMoves)
        iWheelMove = iWheelMove + 1;
    end
    timeFromLastWheelMoveSec(iRep) = repOnsetSec-wheel.wheelMovementsSec.offset(iWheelMove-1);
    %% DLC per rep
    iFrames = find(dlc.timeSec>=repOnsetSec+TIMES_TO_CALC_VIDEO_MOVE_SEC(1) & ...
        dlc.timeSec<repOnsetSec+TIMES_TO_CALC_VIDEO_MOVE_SEC(2));
    if length(iFrames)>=minNFrames
        [movement,  location, angleBetweenBodyParts, distanceBetweenBodyParts, ...
            probLikelyPerBodyPart,probLikelyTwoBodyParts, bodyParts] = calcMovementsFromFrames(dlc.xTable(iFrames,:), ...
            dlc.yTable(iFrames,:),dlc.likelihoodTable(iFrames,:), dlc.timeSec(iFrames), minLikelihoodMove);
        movementPerBodyPart.x(iRep,:) = movement.x;
        movementPerBodyPart.y(iRep,:) = movement.y;
        locationPerBodyPart.x(iRep,:) = location.x;
        locationPerBodyPart.y(iRep,:) = location.y;
        anglePerBodyPartPair(iRep,:,:) = angleBetweenBodyParts;
        distancePerBodyPartPair(iRep,:,:) = distanceBetweenBodyParts;
        probPerBodyPart(iRep,:) = probLikelyPerBodyPart;
        probPerTwoBodyParts(iRep,:,:) = probLikelyTwoBodyParts;
    end
end
% in cases where rep is during wheel movement that time from last wheel movement
% will be considered nan.
timeFromLastWheelMoveSec(timeFromLastWheelMoveSec<0) = nan;

%%
statePerRep.onsetSec = stimOnsetSec;
statePerRep.isDuringSd = isClickDuringSd;
statePerRep.isAfterSd = isClickAfterSd;
statePerRep.isQuiescent = isQuiescentPerRep;
statePerRep.sleepScoring = sleepScorePerRep;
statePerRep.timeSinceWheelMoveSec = timeFromLastWheelMoveSec;
statePerRep.dlc.movement = movementPerBodyPart;
statePerRep.dlc.location = locationPerBodyPart;
statePerRep.dlc.angleBetweenParts = anglePerBodyPartPair;
statePerRep.dlc.distanceBetweenParts = distancePerBodyPartPair;
statePerRep.dlc.probLikely = probPerBodyPart; %proportion (probability) of trials with sufficient likelihood per body part
statePerRep.dlc.probLikelyTwoParts = probPerTwoBodyParts;
statePerRep.dlc.bodyParts = bodyParts;
end
