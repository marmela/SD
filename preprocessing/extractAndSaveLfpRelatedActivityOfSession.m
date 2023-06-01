function extractAndSaveLfpRelatedActivityOfSession(sessionsInfo,isMUA, isLFP, channelsPerSession)

if (~exist('isMUA','var'))
    isMUA = true;
end
if (~exist('isLFP','var'))
    isLFP = true;
end

if (~exist('channelsPerSession','var'))
    isSpecificChannelsPerSession = false;
else
    isSpecificChannelsPerSession = true;
end

nSessions = length(sessionsInfo);
for sessInd = 1:nSessions
    currentSession = sessionsInfo(sessInd);
    animal = currentSession.animal;
    animalSession = currentSession.animalSession;
    badChannelsToExclude = currentSession.badChannels;
    nLocations = length(currentSession.electrodes.locations);
    
    fprintf('\n@@@ Started Session %s - %d @@@\n',animal,animalSession);
    channelsPerLocation = cell(nLocations,1);
    for locInd = 1:nLocations
        channelsPerLocation{locInd} = setdiff(currentSession.electrodes.channelsPerLocation{locInd},...
            badChannelsToExclude);
    end
    rawMatDirPath = getRawTraceMatDirPath(animal,animalSession);
    
    if (isLFP)
        lfpTraceDirPath = getLfpTraceDirPath(animal,animalSession);
        if (~exist(lfpTraceDirPath,'dir'))
            mkdir(lfpTraceDirPath);
        end
    end
    
    
    if (isMUA)
        muaTraceDirPath = getMuaTraceDirPath(animal,animalSession);
        if (~exist(muaTraceDirPath,'dir'))
            mkdir(muaTraceDirPath);
        end
    end
    for locInd = 1:nLocations
        channelsCurrentLocation = channelsPerLocation{locInd};
        currentLocationStr = currentSession.electrodes.locations{locInd};
        rawFilePath = [rawMatDirPath, filesep, getAvgRawTracePerLocFilename(currentLocationStr), '.mat'];
        nChannelsInCurrentLoc = length(channelsCurrentLocation);
        rawFilePathPerTrace{nChannelsInCurrentLoc+1} = rawFilePath;
        lfpFilePathPerTrace{nChannelsInCurrentLoc+1} = [lfpTraceDirPath, filesep, ...
            getAvgLfpPerLocFilename(currentLocationStr)];
        muaFilePathPerTrace{nChannelsInCurrentLoc+1} = [muaTraceDirPath, filesep, ...
            getAvgMuaPerLocFilename(currentLocationStr)];
        
        for chInd = 1:nChannelsInCurrentLoc
            ch = channelsCurrentLocation(chInd);
            rawFilePathPerTrace{chInd} = [rawMatDirPath, filesep, ...
                getRawLfpSpikesTraceFilename(ch), '.mat'];
            lfpFilePathPerTrace{chInd} = [lfpTraceDirPath, filesep, getLfpTraceFilename(ch)];
            muaFilePathPerTrace{chInd} = [muaTraceDirPath, filesep,  getMuaTraceFilename(ch)];
        end
            
        for traceInd = 1:length(rawFilePathPerTrace)
            rawFilePath = rawFilePathPerTrace{traceInd};
            lfpFilePath = lfpFilePathPerTrace{traceInd};
            muaFilePath = muaFilePathPerTrace{traceInd};
            
            if (isLFP)
                rawTraceData = load(rawFilePath);
                sr = rawTraceData.srData;
                lfp = bandpassHeavyData(rawTraceData.data, rawTraceData.srData, ...
                    Consts.LFP_LOW_CUT_HZ, Consts.LFP_HIGH_CUT_HZ, Consts.LFP_FILTER_ORDER, true);
                clear rawTraceData
                data = resampleHeavyData(lfp, sr,Consts.LFP_SR,'linear');
                clear lfp
                srData = Consts.LFP_SR;
                
                params.Consts.LFP_LOW_CUT_HZ = Consts.LFP_LOW_CUT_HZ;
                params.Consts.LFP_HIGH_CUT_HZ = Consts.LFP_HIGH_CUT_HZ;
                params.Consts.LFP_FILTER_ORDER = Consts.LFP_FILTER_ORDER;

                save(lfpFilePath,'data','srData','params');
                clear data
                
                [~,filename,~] = fileparts(lfpFilePath);
                fprintf('\t@@@ Saved %s (session %s - %d) @@@\n',filename,animal,animalSession);
            end
            
            if (isMUA)
                rawTraceData = load(rawFilePath);
                
                powerEnvelope = getPowerEnvelopeHeavyData(rawTraceData.data,...
                    rawTraceData.srData,Consts.MUA_LOW_CUT_HZ,Consts.MUA_HIGH_CUT_HZ,...
                    Consts.MUA_FILTER_ORDER,Consts.MUA_ENVELOPE_LOWPASS_FILTER_CUTOFF,...
                    Consts.MUA_ENVELOPE_FILTER_ORDER);
                sr = rawTraceData.srData;
                clear rawTraceData;
                data = resampleHeavyData(powerEnvelope, sr,Consts.MUA_ENVELOPE_SR,'linear');
                clear powerEnvelope;
                srData = Consts.MUA_ENVELOPE_SR;
                params.Consts.MUA_LOW_CUT_HZ = Consts.MUA_LOW_CUT_HZ;
                params.Consts.MUA_HIGH_CUT_HZ = Consts.MUA_HIGH_CUT_HZ;
                params.Consts.MUA_FILTER_ORDER = Consts.MUA_FILTER_ORDER;
                params.Consts.MUA_ENVELOPE_LOWPASS_FILTER_CUTOFF = Consts.MUA_ENVELOPE_LOWPASS_FILTER_CUTOFF;
                params.Consts.MUA_ENVELOPE_FILTER_ORDER = Consts.MUA_ENVELOPE_FILTER_ORDER;
                
                save(muaFilePath,'data','srData','params');
                clear data
                [~,filename,~] = fileparts(muaFilePath);
                fprintf('\t@@@ Saved %s (session %s - %d) @@@\n',filename,animal,animalSession);          
            end
        end
    end
    
end


end