function extractAndSaveEMGOfSession(sessionsInfo)

EMG_CHANNEL = 1;
nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    animal = currentSession.animal;
    animalSession = currentSession.animalSession;
    tankStr = currentSession.tdtTank;
    block = currentSession.tdtBlock;
    emgTraceDirPath = getEmgTraceDirPath(currentSession);
    if (~exist(emgTraceDirPath,'dir'))
        mkdir(emgTraceDirPath);
    end
    sessionStr = getSessionDirName(currentSession);
    [data,srData] = getAndSaveRawTrace(tankStr,block,TdtConsts.EMG_NAME,EMG_CHANNEL);
    emgFilename = getEmgTraceFilename();
    filePath = [emgTraceDirPath filesep emgFilename];
    save(filePath,getVarName(data),getVarName(srData));
    fprintf('\nFinished %s EMG\n\n',sessionStr)
end
end