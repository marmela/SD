function [iTrials] = balanceTrialsMovementAndHeadAngle(iTrials, movement, probLikely, ...
    iBodyPart, angleBetweenParts, probLikelyTwoParts,bodyParts)
% probLikelyBodyPart = probLikely(:,iBodyPart);
MAX_MOVEMENT_PIXELS = 3;
MIN_PROB_VISIBLE_BODY_PART = 0.5;
isLikelyBodtPartPerTrial = probLikely>=MIN_PROB_VISIBLE_BODY_PART;
nStates = length(iTrials);

isLeftEye = startsWith(bodyParts,'EyeLeft');
isRightEye = startsWith(bodyParts,'EyeRight');
isNotEyes = ~isLeftEye & ~isRightEye;
isLikelyBodtPartPerTrialSimplified = [any(isLikelyBodtPartPerTrial(:,isLeftEye),2), ...
    any(isLikelyBodtPartPerTrial(:,isRightEye),2), isLikelyBodtPartPerTrial(:,isNotEyes)];

for iState = nStates:-1:1
    nTrialsCurrentState = length(iTrials{iState});
    movementPerState{iState} = nan(nTrialsCurrentState,1);
    for iTrialWithinState = 1:nTrialsCurrentState
        iTrial = iTrials{iState}(iTrialWithinState);
        isLikelyBodtPartCurrentTrial = isLikelyBodtPartPerTrial(iTrial,:);
        movementPerState{iState}(iTrialWithinState) = ...
            mean((movement.x(iTrial,isLikelyBodtPartCurrentTrial) + ...
            movement.y(iTrial,isLikelyBodtPartCurrentTrial))./2);
    end
    isNanTrial = isnan(movementPerState{iState});
    isTooMuchMovement = movementPerState{iState}>MAX_MOVEMENT_PIXELS;
    isBodyPartsInvisible = all(~isLikelyBodtPartPerTrial(iTrials{iState},:),2);
    isBadTrial = isNanTrial | isTooMuchMovement | isBodyPartsInvisible;
    iTrials{iState}(isBadTrial) = [];
    movementPerState{iState}(isBadTrial) = [];
    isLikelyBodyPartSimplifiedPerState{iState} = isLikelyBodtPartPerTrialSimplified(iTrials{iState},:);
    
end

nTrialsPerState = cellfun(@length,iTrials);
for iState = nStates:-1:1
    isValidTrialPerState{iState} = false(nTrialsPerState(iState),1);
end

bodyPartsPatterns = unique([isLikelyBodyPartSimplifiedPerState{1}; isLikelyBodyPartSimplifiedPerState{end}],'rows');
nBodyPartsPatterns = size(bodyPartsPatterns,1);
for iPattern = 1:nBodyPartsPatterns
    currentPattern = bodyPartsPatterns(iPattern,:);
%     for i
    iTrialsCurrentPatternState1 = find(all(isLikelyBodyPartSimplifiedPerState{1}==currentPattern,2));
    iTrialsCurrentPatternState3 = find(all(isLikelyBodyPartSimplifiedPerState{end}==currentPattern,2));
    nBalancedTrialsCurrentPattern = min(length(iTrialsCurrentPatternState1),length(iTrialsCurrentPatternState3));
    for iState = 1:nStates
        iCurrentStatePatternTrials = find(all(isLikelyBodyPartSimplifiedPerState{iState}==currentPattern,2));
        if length(iCurrentStatePatternTrials)<=nBalancedTrialsCurrentPattern
            isValidTrialPerState{iState}(iCurrentStatePatternTrials) = true;
        else
            iRandTrials=randsample(iCurrentStatePatternTrials,nBalancedTrialsCurrentPattern);
            isValidTrialPerState{iState}(iRandTrials) = true;
        end
    end    
end

for iState = 1:nStates
    iTrials{iState}(~isValidTrialPerState{iState}) = [];
end
1;