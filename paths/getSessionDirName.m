function dirName = getSessionDirName(sessionInfo) 
    dirName = sprintf('%s - %d',sessionInfo.animal,sessionInfo.animalSession);
end