function fileName = getEegEpochsFileName(sessionInfo)
fileName = sprintf('%s-%d_EEG',sessionInfo.animal,sessionInfo.animalSession);
