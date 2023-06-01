function extractAndSaveEEGOfSession(sessionsInfo)

nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    animal = currentSession.animal;
    animalSession = currentSession.animalSession;
    tankStr = currentSession.tdtTank;
    block = currentSession.tdtBlock;
    
    eegTraceDirPath = getEegTraceDirPath(currentSession);
    if (~exist(eegTraceDirPath,'dir'))
        mkdir(eegTraceDirPath);
    end
    
    sessionStr = getSessionDirName(currentSession);
    
    for channel = 1:TdtConsts.N_EEG_CHANNELS
        [data,srData] = getAndSaveRawTrace(tankStr,block,TdtConsts.EEG_NAME,channel);
        eegFilename = getEegTraceFilename(channel);
        filePath = [eegTraceDirPath filesep eegFilename];
        save(filePath,getVarName(data),getVarName(srData));
        fprintf('\nFinished EEG %s channel %d\n\n',sessionStr,channel)
    end
end