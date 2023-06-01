%% get state info per each repetition
function statePerRep = getStatePerStim(stimOnsetSec,wheel,isWheelMoving,firstWheelMoveSec,lastWheelMoveSec,...
    scoring,preStimOnsetTimeMs,postStimOnsetTimeMs)

MS_IN_1SEC = 1000;
artifactScore = scoring.outputScoreValues(strcmp(scoring.scroeStrings,'ARTIFACT'));
isClickAfterSd = stimOnsetSec>lastWheelMoveSec;
isClickDuringSd = stimOnsetSec>firstWheelMoveSec & stimOnsetSec<=lastWheelMoveSec;
nRepsStim = length(stimOnsetSec);
sleepScorePerRep = nan(nRepsStim,1);
isQuiescentPerRep = false(nRepsStim,1);
isWheelMovingPerRep = false(nRepsStim,1);
isArtifactPerRep = false(nRepsStim,1);
timeFromLastWheelMoveSec = nan(nRepsStim,1);
nMoves = height(wheel.wheelMovementsSec);

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
    isWheelMovingPerRep(iRep) = any(isWheelMovingDuringRep);
    isArtifactPerRep(iRep) = any(scoringDuringRep==artifactScore);
    isQuiescentPerRep(iRep) = ~any(isWheelMovingDuringRep);
    
    %calculate time from last wheel movement per epoch
    while (repOnsetSec>wheel.wheelMovementsSec.onset(iWheelMove) && iWheelMove<nMoves)
        iWheelMove = iWheelMove + 1;
    end
    timeFromLastWheelMoveSec(iRep) = repOnsetSec-wheel.wheelMovementsSec.offset(iWheelMove-1);
    
end
% in cases where rep is during wheel movement that time from last wheel movement
% will be considered nan.
timeFromLastWheelMoveSec(timeFromLastWheelMoveSec<0) = nan;

%%
statePerRep.onsetSec = stimOnsetSec;
statePerRep.isDuringSd = isClickDuringSd;
statePerRep.isAfterSd = isClickAfterSd;
statePerRep.isQuiescent = isQuiescentPerRep;
statePerRep.isWheelMoving = isWheelMovingPerRep;
statePerRep.isArtifact = isArtifactPerRep;
statePerRep.sleepScoring = sleepScorePerRep;
statePerRep.timeSinceWheelMoveSec = timeFromLastWheelMoveSec;


end