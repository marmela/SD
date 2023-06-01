function extractAndSaveAuditoryStimTimesOfSession(sessionsInfo)
nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    animal = currentSession.animal;
    animalSession = currentSession.animalSession;
    tankStr = currentSession.tdtTank;
    block = currentSession.tdtBlock;
    [data,sr] = getAndSaveRawTrace(tankStr,block,TdtConsts.AUDITORY_STIM_TTL_NAME,1);
    [stampValues,stampIndices,stampTimesSec] = readTtlStampsChannel (data,sr);
    stimsDir = getAuditoryStimsAnalysisDirPath(animal,animalSession);
    if(~exist(stimsDir,'dir')); mkdir(stimsDir); end
    stampsFilePath = [stimsDir,filesep, getTtlStampsFilename()];
    save(stampsFilePath,'stampValues','stampIndices','stampTimesSec');
    fprintf('\t@@@ Saved TTL stamps of session %s - %d @@@\n',animal,animalSession);
end

end