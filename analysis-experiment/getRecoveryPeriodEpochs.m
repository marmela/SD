function [iQw,iNrem, iRem, iAwRecovery, iAwAll] = getRecoveryPeriodEpochs(statePerEpoch,sleepStateToScoreValue)
    nStims = length(statePerEpoch);
    for iStim = nStims:-1:1
        iQw{iStim} = find(statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('Q-Wake'));
        iNrem{iStim} = find(statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('NREM'));
        iRem{iStim} = find( statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('REM'));
        iAwRecovery{iStim} = find(statePerEpoch(iStim).isAfterSd & statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('A-Wake'));
        iAwAll{iStim} = find(statePerEpoch(iStim).sleepScoring==sleepStateToScoreValue('A-Wake'));
    end
end