sessionInfo =  getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #5');

extractAndSaveEEGOfSession(sessionInfo)
extractAndSaveEMGOfSession(sessionInfo)
extractAndSaveWheelOfSession(sessionInfo)
extractAndSaveAuditoryStimTimesOfSession(sessionInfo)
extractAndSaveRawTracesOfSession(sessionInfo)
extractAndSaveEegPowerSpectrumAndWheelMovementPerStim(sessionInfo)

isParallel = true;
spikeSortingOfSession(sessionInfo, isParallel, 1:3)
spikeSortingOfSession(sessionInfo, isParallel, 4:6)
spikeSortingOfSession(sessionInfo, isParallel, 7:9)
spikeSortingOfSession(sessionInfo, isParallel, 10:12)
spikeSortingOfSession(sessionInfo, isParallel, 13:14)
spikeSortingOfSession(sessionInfo, isParallel, 15:16)

extractAndSaveLfpRelatedActivityOfSession(sessionInfo)

isParallel = true;
getSpikesForOffStatesDetectionOfSession(sessionInfo, isParallel, 1:3)
getSpikesForOffStatesDetectionOfSession(sessionInfo, isParallel, 4:6)
getSpikesForOffStatesDetectionOfSession(sessionInfo, isParallel, 7:9)
getSpikesForOffStatesDetectionOfSession(sessionInfo, isParallel, 10:12)
getSpikesForOffStatesDetectionOfSession(sessionInfo, isParallel, 13:14)
getSpikesForOffStatesDetectionOfSession(sessionInfo, isParallel, 15:16)

