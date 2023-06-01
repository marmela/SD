function spikeSortingOfSession(sessionsInfo, isParallel, channelsPerSession, isUseAvgReferencing, isExcludeWheelMovements)
%This function uses Wave_Clus 3.0 package 
if (~exist('channelsPerSession','var') || isempty(channelsPerSession))
    isUseSelectedChannels = false;
else
    if ~iscell(channelsPerSession)
        temp = channelsPerSession;
        clear channelsPerSession
        channelsPerSession{1} = temp;
    end
    isUseSelectedChannels = true;
end
if (~exist('isUseAvgReferencing','var'))
    isUseAvgReferencing = true;
end
if (~exist('isExcludeWheelMovements','var'))
    isExcludeWheelMovements = true;
end
nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    animal = currentSession.animal;
    animalSession = currentSession.animalSession;
    tankStr = currentSession.tdtTank;
    block = currentSession.tdtBlock;
    if isExcludeWheelMovements
        wheelFilePath = [getWheelAnalysisDirPath(currentSession) filesep ...
            getWheelAnalysisFilename(currentSession)];
        tmp = load(wheelFilePath,'wheelMovementsSec');
        wheelMovementsSec = tmp.wheelMovementsSec;
        clear tmp;
    end
    spikesSortingDirPath = getSpikesSortingDirPath(animal,animalSession);
    makeDirIfNeeded(spikesSortingDirPath);
    nLocations = length(currentSession.electrodes.locations);
    rawMatDirPath = getRawTraceMatDirPath(animal,animalSession);
    for locInd = 1:nLocations
        channelsCurrentLocation = setdiff(...
            currentSession.electrodes.channelsPerLocation{locInd},...
            currentSession.badChannels);
        currentLocationStr = currentSession.electrodes.locations{locInd};
        rawAvgAllChannelInLocationFilePath = [rawMatDirPath, filesep, getAvgRawTracePerLocFilename(currentLocationStr), '.mat'];
        
        if(isUseSelectedChannels)
            channelsCurrentLocation = intersect(channelsCurrentLocation,channelsPerSession{sessInd});
        end
        
        rawTraceFilePath = cell(length(channelsCurrentLocation),1);
        spikesFilePath = cell(length(channelsCurrentLocation),1);
        for i=1:length(channelsCurrentLocation)
            rawFileName = getRawLfpSpikesTraceFilename(channelsCurrentLocation(i));
            rawTraceFilePath{i,1} = [rawMatDirPath, filesep, rawFileName, '.mat'];
            spikesFilePath{i,1} = [spikesSortingDirPath,filesep,rawFileName,'_spikes.mat'];
        end
        if isUseAvgReferencing
            if isExcludeWheelMovements
                Get_spikes_Amit2019(rawTraceFilePath, 'refPath', rawAvgAllChannelInLocationFilePath,...
                    'outputDir', spikesSortingDirPath,'parallel',isParallel,'noiseTimesSec',wheelMovementsSec)
            else
                Get_spikes_Amit2019(rawTraceFilePath, 'refPath', rawAvgAllChannelInLocationFilePath,...
                    'outputDir', spikesSortingDirPath,'parallel',isParallel)
            end
        else
            if isExcludeWheelMovements
                Get_spikes_Amit2019(rawTraceFilePath, 'outputDir', spikesSortingDirPath, ...
                    'parallel',isParallel,'noiseTimesSec',wheelMovementsSec)
            else
                Get_spikes_Amit2019(rawTraceFilePath, 'outputDir', spikesSortingDirPath, ...
                    'parallel',isParallel)
            end
        end
        
        Do_clustering(spikesFilePath,'parallel',isParallel,'resolution','-r300')
    end
    

end