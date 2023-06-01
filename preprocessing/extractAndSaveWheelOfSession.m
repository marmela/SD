function extractAndSaveWheelOfSession(sessionsInfo)

N_STATE_CHANGES_BETWEEN_MAGNETS = 4;
N_MAGNETS_PER_ROTATION = 14;
CIRCUMFERENCE_METERS = 1.1;
nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    tankStr = currentSession.tdtTank;
    block = currentSession.tdtBlock;
    wheelDirPath = getWheelAnalysisDirPath(currentSession);
    makeDirIfNeeded(wheelDirPath);
    wheelFilename = getWheelAnalysisFilename(currentSession);
    wheelFilePath = [wheelDirPath filesep wheelFilename];
    clear data
    [data(2,:),~] = getAndSaveRawTrace(tankStr,block,TdtConsts.WHEEL1_NAME,2); %WHEEL2_NAME,1);
    [data(1,:),srData] = getAndSaveRawTrace(tankStr,block,TdtConsts.WHEEL1_NAME,1);
    nSamples = size(data,2);
    speed.meterPerSec = [];
    speed.times = [];
    wheelEventsTimeSec = [];
    for iWheel = 1:2
        [~,clustersMeans] = kmeans(randsample(data(iWheel,:)',min(1e7,nSamples)),2);
        wheelThreshold =  mean(clustersMeans);
        stateChangeTimeSec = (find(diff(data(iWheel,:)>wheelThreshold)~=0)+0.5)./srData;
        timeBetweenAdjacentMagnetsCrossing = stateChangeTimeSec(1+N_STATE_CHANGES_BETWEEN_MAGNETS:end) - ...
            stateChangeTimeSec(1:end-N_STATE_CHANGES_BETWEEN_MAGNETS);
        speed.meterPerSec = [speed.meterPerSec, ...
            CIRCUMFERENCE_METERS./N_MAGNETS_PER_ROTATION./timeBetweenAdjacentMagnetsCrossing];
        speed.times = [speed.times, stateChangeTimeSec(1+N_STATE_CHANGES_BETWEEN_MAGNETS:end)];
        wheelEventsTimeSec = [wheelEventsTimeSec, stateChangeTimeSec];
    end
    [speed.times,iTimesSorted] = sort(speed.times);
    speed.meterPerSec = speed.meterPerSec(iTimesSorted);
    wheelEventsTimeSec = sort(wheelEventsTimeSec);
    wheelMovementsSec = getWheelMovementsSec(wheelEventsTimeSec);
    save(wheelFilePath, getVarName(data), getVarName(srData), ...
        getVarName(wheelEventsTimeSec),getVarName(speed), getVarName(wheelMovementsSec));
end
end

