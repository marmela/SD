function [iSdPerStimAndSdPressureAndTimeFromWheel] = getSdPeriodEpochs(...
    statePerEpoch,sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods)

nStims = length(statePerEpoch);
for iStim = nStims:-1:1
    stateCurrentStim = statePerEpoch(iStim);
    isQwSd = stateCurrentStim.isQuiescent & stateCurrentStim.isDuringSd & ...
        stateCurrentStim.sleepScoring==sleepStateToScoreValue('Q-Wake');
    
    nTotalTrials = length(isQwSd);
    nTrialsQwSd = sum(isQwSd);
    timeFromWheelInQwSd = stateCurrentStim.timeSinceWheelMoveSec(isQwSd);
    
    isInTimeFromWheelPeriod = false(nTimePeriods,nTotalTrials);
    for iTimePeriod = nTimePeriods:-1:1
        bottomPrctile = prctile(timeFromWheelInQwSd,(iTimePeriod-1)./nTimePeriods*100);
        topPrctile = prctile(timeFromWheelInQwSd,(iTimePeriod)./nTimePeriods*100);
        isInTimeFromWheelPeriod(iTimePeriod,:) = ...
            stateCurrentStim.timeSinceWheelMoveSec>=bottomPrctile & ...
            stateCurrentStim.timeSinceWheelMoveSec<topPrctile;
    end
    isInTimeFromWheelPeriod(nTimePeriods,:)= isInTimeFromWheelPeriod(nTimePeriods,:) | ...
        stateCurrentStim.timeSinceWheelMoveSec'==topPrctile;
    
    iQwSd = find(isQwSd);
    isInSdPressurePeriod = false(nSdPressurePeriods,nTotalTrials);
    for iSdPressurePeriods = 1:nSdPressurePeriods
        firstTrialIndex = iQwSd(round((iSdPressurePeriods-1)./nSdPressurePeriods*nTrialsQwSd)+1);
        lastTrialIndex = iQwSd(round(iSdPressurePeriods./nSdPressurePeriods*nTrialsQwSd));
        isInSdPressurePeriod(iSdPressurePeriods,firstTrialIndex:lastTrialIndex) = true;
    end
    
    for iTimePeriod = 1:nTimePeriods
        for iSdPressurePeriods = 1:nSdPressurePeriods
            isInCurrentState = isQwSd & isInSdPressurePeriod(iSdPressurePeriods,:)' & ...
                isInTimeFromWheelPeriod(iTimePeriod,:)';
            
            iSdPerStimAndSdPressureAndTimeFromWheel{iStim,iSdPressurePeriods,iTimePeriod} = ...
                find(isInCurrentState);
            
            %                 stimOnsetPerStimAndState{iStim,iSdPressurePeriods,iTimePeriod} = ...
            %                     stateCurrentStim.onsetSec(isInCurrentState);
        end
    end
    
    
    %     nStims = length(statePerEpoch);
    %     for iStim = nStims:-1:1
    %         iQw{iStim} = find(statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('Q-Wake'));
    %         iNrem{iStim} = find(statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('NREM'));
    %         iRem{iStim} = find( statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('REM'));
    %     end
end