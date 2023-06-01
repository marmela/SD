function extractAndSaveRawTracesOfSession(sessionsInfo)
nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    animal = currentSession.animal;
    animalSession = currentSession.animalSession;
    tankStr = currentSession.tdtTank;
    block = currentSession.tdtBlock;
    badChannelsToExclude = currentSession.badChannels;
    nLocations = length(currentSession.electrodes.locations);
    channelsPerLocation = cell(nLocations,1);
    for locInd = 1:nLocations
        channelsPerLocation{locInd} = setdiff(currentSession.electrodes.channelsPerLocation{locInd},...
            badChannelsToExclude);
    end
    rawMatDirPath = getRawTraceMatDirPath(animal,animalSession);
    if (~exist(rawMatDirPath,'dir'))
        mkdir(rawMatDirPath);
    end
    for locInd = 1:nLocations
        channelsCurrentLocation = channelsPerLocation{locInd};
        for ch = channelsCurrentLocation
            rawFilePath = [rawMatDirPath, filesep, getRawLfpSpikesTraceFilename(ch), '.mat'];
            [channelData,srData] = getAndSaveRawTrace(tankStr,block,TdtConsts.RAW_LFP_NAME,ch,rawFilePath); %QWERTY - maybe try to load from file instead of directly from function to avoid the weird memory leak
            if(~exist('sumAllChannelsInLoc','var'))
                sumAllChannelsInLoc = channelData;
            else
                sumAllChannelsInLoc = sumAllChannelsInLoc + channelData;
            end
        end
        clear channelData
        data = sumAllChannelsInLoc./length(channelsCurrentLocation); %mean all valid channels
        clear sumAllChannelsInLoc
        currentLocationStr = currentSession.electrodes.locations{locInd};
        rawFilePath = [rawMatDirPath, filesep, getAvgRawTracePerLocFilename(currentLocationStr), '.mat'];
        save(rawFilePath,'data','srData','-v7.3');
        clear data
    end
    
end


end