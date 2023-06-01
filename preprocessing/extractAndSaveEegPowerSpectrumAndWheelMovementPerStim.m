function extractAndSaveEegPowerSpectrumAndWheelMovementPerStim(sessionsInfo, ...
    maxAllowedSpeedMetersPerSec, periClickTimeNotMoving, periClickEegWindowSec, ...
    periTonesTimeNotMoving, periTonesEegWindowSec, eegChannel, stdOfEpochsStdToReject, ...
    stdOfValuesToReject, freqsHz, nw)

if ~exist('maxAllowedSpeedMetersPerSec','var'); maxAllowedSpeedMetersPerSec = 0.05; end
if ~exist('periClickTimeNotMoving','var');      periClickTimeNotMoving = [-1.5,3];  end
if ~exist('periClickEegWindowSec','var');       periClickEegWindowSec = [-2,1];     end
if ~exist('periTonesTimeNotMoving','var');      periTonesTimeNotMoving = [-1.5,4.5];end
if ~exist('periTonesEegWindowSec','var');       periTonesEegWindowSec = [-1,2];     end
if ~exist('eegChannel','var');                  eegChannel = 2;                     end
if ~exist('freqsHz','var');                     freqsHz = 0.5:0.5:100;              end
if ~exist('stdOfEpochsStdToReject','var');      stdOfEpochsStdToReject = 6;         end
if ~exist('stdOfValuesToReject','var');         stdOfValuesToReject = 8;            end
if ~exist('nw','var');                          nw = 3;                             end

for iSess = 1:length(sessionsInfo)
    currentSession = sessionsInfo(iSess);
    wheelFilePath = [getWheelAnalysisDirPath(currentSession) filesep getWheelAnalysisFilename(currentSession)];
    auditoryFilePath = [getAuditoryStimsAnalysisDirPath(currentSession.animal,currentSession.animalSession),...
        filesep, getTtlStampsFilename()];
    eegFilePath = [getEegTraceDirPath(currentSession) filesep getEegTraceFilename(eegChannel)];
    
    wheelData = load(wheelFilePath);
    auditoryData = load(auditoryFilePath);
    eegData = load(eegFilePath);
    toneStreamTtlValues = unique(auditoryData.stampValues(...
        auditoryData.stampValues>ParadigmConsts.TONE_STREAM_BASE_ID & ...
        auditoryData.stampValues<=ParadigmConsts.TONE_STREAM_LAST_POSSIBLE_ID));
    clicksTtlValues = unique(auditoryData.stampValues(...
        auditoryData.stampValues>ParadigmConsts.CLICK_BASE_ID & ...
        auditoryData.stampValues<=ParadigmConsts.CLICK_LAST_POSSIBLE_ID));
    drcTtlValues = unique(auditoryData.stampValues(...
        auditoryData.stampValues>ParadigmConsts.DRC_TUNING_BASE_ID & ...
        auditoryData.stampValues<=ParadigmConsts.DRC_TUNING_LAST_POSSIBLE_ID));
    stimuliTtlValues = [toneStreamTtlValues; clicksTtlValues];
    nStimuli = length(toneStreamTtlValues)+length(clicksTtlValues);
    
    for iStim = nStimuli:-1:1
        currentTtlValue = stimuliTtlValues(iStim);
        if ismember(currentTtlValue,clicksTtlValues)
            periStimTimeNotMoving = periClickTimeNotMoving;
            periStimEegWindowSec = periClickEegWindowSec;
            stimTypeStr = 'Clicks';
        elseif ismember(currentTtlValue,toneStreamTtlValues)
            periStimTimeNotMoving = periTonesTimeNotMoving;
            periStimEegWindowSec = periTonesEegWindowSec;
            stimTypeStr = 'ToneStream';
        else
            error('Unrecognized Stim Type');
        end
        stimOnsetSec = auditoryData.stampTimesSec(auditoryData.stampValues==currentTtlValue);
        isMoving = getIfWheelMovingAroundEvents(wheelData.speed,...
            maxAllowedSpeedMetersPerSec, stimOnsetSec, periStimTimeNotMoving);
        [powerPerTrialAndFreq, isNoisyEeg] = getMultiTaperPowerSpectrumPerTrial (...
            eegData.data, eegData.srData, stimOnsetSec, periStimEegWindowSec,...
            stdOfEpochsStdToReject, stdOfValuesToReject, freqsHz, nw);
        eegAndWheelPerStim(iStim).stimOnsetSec = stimOnsetSec;
        eegAndWheelPerStim(iStim).powerPerTrialAndFreq = powerPerTrialAndFreq;
        eegAndWheelPerStim(iStim).isNoisyEeg = isNoisyEeg;
        eegAndWheelPerStim(iStim).isMoving = isMoving;
        eegAndWheelPerStim(iStim).stim.type = stimTypeStr;
        eegAndWheelPerStim(iStim).stim.periStimTimeNotMoving = periStimTimeNotMoving;
        eegAndWheelPerStim(iStim).stim.periStimEegWindowSec = periStimEegWindowSec;
        eegAndWheelPerStim(iStim).stim.ttlValue = currentTtlValue;
    end
    eegParams.eegChannel = eegChannel;
    eegParams.freqsHz = freqsHz;
    eegParams.stdOfEpochsStdToReject = stdOfEpochsStdToReject;
    eegParams.stdOfValuesToReject = stdOfValuesToReject;
    eegParams.nw = nw;
    lastWheelMovementSec = wheelData.wheelEventsTimeSec(end);
     outputFilePath = [getAuditoryStimsAnalysisDirPath(currentSession.animal,currentSession.animalSession),...
        filesep, FileNames.EEG_AND_WHEEL_PER_STIM];
    save(outputFilePath,'eegAndWheelPerStim','eegParams','lastWheelMovementSec')
end

