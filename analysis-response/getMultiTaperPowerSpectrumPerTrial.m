function [powerPerTrialAndFreq, isNoisyEpoch] = getMultiTaperPowerSpectrumPerTrial (...
    data, sr, eventStartTimesSec, periEventWindowSec,...
    stdOfEpochsStdToReject, stdOfValuesToReject, freqsHz, nw, isParfor)

if (~exist('isParfor','var'))
    isParfor = true;
end
isRemoveBaseline = false;
[~,~,allEpochs,isNoisyEpoch, ~,isInvalidEvent] = getErp(data, sr, eventStartTimesSec, ...
    -periEventWindowSec(1), periEventWindowSec(2), isRemoveBaseline, stdOfEpochsStdToReject, ...
    stdOfValuesToReject);
nTrials = length(eventStartTimesSec);
nFreqs = length(freqsHz);
powerPerTrialAndFreq = nan(nTrials,nFreqs);
iValidEvents = find(~isInvalidEvent)';
if isParfor
    parfor iTrial = iValidEvents
        [powerPerTrialAndFreq(iTrial,:),~] = pmtm(allEpochs(iTrial,:),nw,freqsHz,sr);
    end
else
    for iTrial = iValidEvents
        [powerPerTrialAndFreq(iTrial,:),~] = pmtm(allEpochs(iTrial,:),nw,freqsHz,sr);
    end
end