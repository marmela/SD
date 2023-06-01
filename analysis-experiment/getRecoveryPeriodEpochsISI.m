function [iQw,iNrem, iRem, iAwRecovery, iAwAll] = getRecoveryPeriodEpochsISI(statePerSeg,sleepStateToScoreValue)

iQw = find(cell2mat(extractfield(statePerSeg,'isAfterSd')) & ...
  extractfield(statePerSeg,'scoring')==sleepStateToScoreValue('Q-Wake'));
iNrem = find(cell2mat(extractfield(statePerSeg,'isAfterSd')) & ...
  extractfield(statePerSeg,'scoring')==sleepStateToScoreValue('NREM'));
iRem = find(cell2mat(extractfield(statePerSeg,'isAfterSd')) & ...
  extractfield(statePerSeg,'scoring')==sleepStateToScoreValue('REM'));
iAwRecovery = find(cell2mat(extractfield(statePerSeg,'isAfterSd')) & ...
  extractfield(statePerSeg,'scoring')==sleepStateToScoreValue('A-Wake'));
iAwAll = find(extractfield(statePerSeg,'scoring')==sleepStateToScoreValue('A-Wake'));

end