function [analysisPerState,chosenBodyPart] = getDlcAnalysisPerTrialType(statePerStim,trialTypes,trialTypesName)
nTrialTypes = length(trialTypes);
iSdTrialType = find(startsWith(trialTypesName,'SD'));
MIN_PROB_LIKELY_FOR_TRIAL = 0.5;
MAX_PROB_UNLIKELY = 0.1;
MIN_PROB_LIKELY_SEGMENT_FOR_TRIAL = 0.3;
nSdEpochs = length(iSdTrialType);
nStims = length(trialTypes{iSdTrialType(end)});
probLikelySd = [];
probLikelyTwoPartsSd = [];
for iStim = 1:nStims
    iTrialsCurrentStim = [];
    for iSd = 1:nSdEpochs
        iTrialsCurrentStim = [iTrialsCurrentStim; trialTypes{iSdTrialType(iSd)}{iStim}];
    end
    probLikelySd = [probLikelySd; statePerStim(iStim).dlc.probLikely(iTrialsCurrentStim,:)];
    probLikelyTwoPartsSd = [probLikelyTwoPartsSd; ...
        statePerStim(iStim).dlc.probLikelyTwoParts(iTrialsCurrentStim,:,:)];
end

bodyPartsStr = statePerStim(1).dlc.bodyParts;
iLeftEye = find(startsWith(bodyPartsStr, 'EyeLeft'));
iRightEye = find(startsWith(bodyPartsStr, 'EyeRight'));
[maxProbBodyPart,iBodyPart] = max(nanmean(probLikelySd));
avgProbLikelyTwoPartsSd = squeeze(nanmean(probLikelyTwoPartsSd));
[maxProbBodyPartPair,I] = max(avgProbLikelyTwoPartsSd(:));
[iBodyPartPair(1),iBodyPartPair(2)] = ind2sub(size(avgProbLikelyTwoPartsSd),I);
probLikelyBestSegment = probLikelyTwoPartsSd(:,iBodyPartPair(1),iBodyPartPair(2));
isSegmentLikely = probLikelyBestSegment>MIN_PROB_LIKELY_SEGMENT_FOR_TRIAL;
segmentLengthAllTrials = [];
for iStim = 1:nStims
    iAllTrialsCurrentStim = [];
    for iTrialType = 1:nTrialTypes
        iAllTrialsCurrentStim = union(iAllTrialsCurrentStim,trialTypes{iTrialType}{iStim});
    end
    dlcCurrentStim = statePerStim(iStim).dlc;
    isSegmentLikelyThisStim = dlcCurrentStim.probLikelyTwoParts(iAllTrialsCurrentStim,...
        iBodyPartPair(1),iBodyPartPair(2))>MIN_PROB_LIKELY_SEGMENT_FOR_TRIAL;
    segmentLengthAllTrials = [segmentLengthAllTrials; dlcCurrentStim.distanceBetweenParts(...
        iAllTrialsCurrentStim(isSegmentLikelyThisStim),iBodyPartPair(1),iBodyPartPair(2))];
    1;
end
assert(all(~isnan(segmentLengthAllTrials)));
meanSegLengthAllTrials = mean(segmentLengthAllTrials);
for iTrialType = 1:nTrialTypes
    iTrials = trialTypes{iTrialType};
    iTrialsAllStims = [];
    movementX = [];
    movementY = [];
    locationX = [];
    locationY = [];
    probLikely = [];
    probLikelyAllParts = [];
    angleBetweenParts = [];
    distanceBetweenParts = [];
    probLikelyTwoParts = [];
    assert(numel(iTrials) == length(iTrials))
    nStims = length(iTrials);
    for iStim = 1:nStims
        iTrialsCurrentStim = iTrials{iStim};
        dlcCurrentStim = statePerStim(iStim).dlc;
        movementX = [movementX; dlcCurrentStim.movement.x(iTrialsCurrentStim,iBodyPart)];
        movementY = [movementY; dlcCurrentStim.movement.y(iTrialsCurrentStim,iBodyPart)];
        locationX = [locationX; dlcCurrentStim.location.x(iTrialsCurrentStim,iBodyPart)];
        locationY = [locationY; dlcCurrentStim.location.y(iTrialsCurrentStim,iBodyPart)];
        probLikely = [probLikely; dlcCurrentStim.probLikely(iTrialsCurrentStim,iBodyPart)];
        probLikelyAllParts = [probLikelyAllParts; dlcCurrentStim.probLikely(iTrialsCurrentStim,:)];
        
        angleBetweenParts = [angleBetweenParts; dlcCurrentStim.angleBetweenParts(...
            iTrialsCurrentStim,iBodyPartPair(1),iBodyPartPair(2))];
        distanceBetweenParts = [distanceBetweenParts; dlcCurrentStim.distanceBetweenParts(...
            iTrialsCurrentStim,iBodyPartPair(1),iBodyPartPair(2))];
        probLikelyTwoParts = [probLikelyTwoParts; dlcCurrentStim.probLikelyTwoParts(...
            iTrialsCurrentStim,iBodyPartPair(1),iBodyPartPair(2))];
    end
    isLikelyBodyPart = probLikely>MIN_PROB_LIKELY_FOR_TRIAL;
    isLikelySegment = probLikelyTwoParts>MIN_PROB_LIKELY_SEGMENT_FOR_TRIAL;
    segLengthPopulation = distanceBetweenParts(isLikelySegment)./meanSegLengthAllTrials;
    isLeftFacing = any(probLikelyAllParts(:,iRightEye)>=MIN_PROB_LIKELY_FOR_TRIAL,2) & all(probLikelyAllParts(:,iLeftEye)<MIN_PROB_LIKELY_FOR_TRIAL,2);
    isRightFacing = any(probLikelyAllParts(:,iLeftEye)>=MIN_PROB_LIKELY_FOR_TRIAL,2) & all(probLikelyAllParts(:,iRightEye)<MIN_PROB_LIKELY_FOR_TRIAL,2);
    isForwardFacing = any(probLikelyAllParts(:,iRightEye)>=MIN_PROB_LIKELY_FOR_TRIAL,2) & any(probLikelyAllParts(:,iLeftEye)>=MIN_PROB_LIKELY_FOR_TRIAL,2);
    isBackwardFacing = all(probLikelyAllParts<MAX_PROB_UNLIKELY,2);
    probFacingAny = mean(isLeftFacing | isRightFacing | isForwardFacing | isBackwardFacing);
    analysisPerState(iTrialType).trialType = trialTypesName{iTrialType};
    analysisPerState(iTrialType).probLikelyBodyPart = mean(isLikelyBodyPart);
    analysisPerState(iTrialType).nTrialsLikelyBodyPart = sum(isLikelyBodyPart);
    movementPerLikelyTrialXY = (movementX(isLikelyBodyPart)+movementY(isLikelyBodyPart))/2;
    analysisPerState(iTrialType).population.movement = movementPerLikelyTrialXY;
    analysisPerState(iTrialType).mean.movement = mean(movementPerLikelyTrialXY);
    locationPerLikelyTrialXY = [locationX(isLikelyBodyPart), locationY(isLikelyBodyPart)];
    analysisPerState(iTrialType).population.location = locationPerLikelyTrialXY;
    analysisPerState(iTrialType).mean.location = mean(locationPerLikelyTrialXY);
    analysisPerState(iTrialType).population.isLeftFacing = isLeftFacing;
    analysisPerState(iTrialType).mean.probLeftFacing = mean(isLeftFacing)./probFacingAny;
    analysisPerState(iTrialType).population.isRightFacing = isRightFacing;
    analysisPerState(iTrialType).mean.probRightFacing = mean(isRightFacing)./probFacingAny;
    analysisPerState(iTrialType).population.isForwardFacing = isForwardFacing;
    analysisPerState(iTrialType).mean.probForwardFacing = mean(isForwardFacing)./probFacingAny;
    analysisPerState(iTrialType).population.isBackwardFacing = isBackwardFacing;
    analysisPerState(iTrialType).mean.probBackwardFacing = mean(isBackwardFacing)./probFacingAny;
    analysisPerState(iTrialType).population.segmentLength = segLengthPopulation;
    analysisPerState(iTrialType).mean.segmentLength = mean(segLengthPopulation);
    
end
chosenBodyPart.i = iBodyPart;
chosenBodyPart.probLikely = maxProbBodyPart;
1;