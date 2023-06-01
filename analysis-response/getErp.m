function [erp,times,allEpochs,noisyEpochs, semEpochs,isInvalidEvent] = getErp(data, sr, eventStartTimesSec, ...
    preTimeSec, postTimeSec, isRemoveBaseline, stdOfEpochsStdToReject, stdOfValuesToReject)

if(~exist('stdOfEpochsStdToReject','var'))
    stdOfEpochsStdToReject = 0;
end
if (~exist('stdOfValuesToReject','var'))
    stdOfValuesToReject = 0;
end
times = (-preTimeSec):(1/sr):postTimeSec;
nEvents = length(eventStartTimesSec);
nPointsForEvent = length(times);
nPointsForBaseline = floor(preTimeSec*sr);
allEpochs = nan(nEvents,nPointsForEvent);
dataLength = length(data);
isInvalidEvent = false(nEvents,1);
for eventInd = 1:nEvents
    currentEventStartTime = eventStartTimesSec(eventInd);
    firstDataPointForEvent = round((currentEventStartTime-preTimeSec)*sr);
    lastDataPointForEvent = firstDataPointForEvent+nPointsForEvent-1;
    
    if (firstDataPointForEvent<1 || lastDataPointForEvent>dataLength)
        isInvalidEvent(eventInd) = true;
        fprintf('\nWARNING: event time %d is out of data\n', currentEventStartTime);
        continue;
    end
    if (isRemoveBaseline)
        baselineMean = mean(data(firstDataPointForEvent:...
            (firstDataPointForEvent+nPointsForBaseline-1)));
        allEpochs(eventInd,:) = data(firstDataPointForEvent:lastDataPointForEvent) - ...
            baselineMean;
    else
        allEpochs(eventInd,:) = data(firstDataPointForEvent:lastDataPointForEvent);
    end
end
maxOfEpochs = max(allEpochs,[],2);
minOfEpochs = min(allEpochs,[],2);
stdOfEpochs = std(allEpochs,[],2);
if (stdOfValuesToReject>0)
    allEpochsValues = allEpochs(:);
    maxValueThreshold = mean(allEpochsValues)+std(allEpochsValues)*stdOfValuesToReject;
    minValueThreshold = mean(allEpochsValues)-std(allEpochsValues)*stdOfValuesToReject;
else
    maxValueThreshold = Inf;
    minValueThreshold = -Inf;
end
if (stdOfEpochsStdToReject>0)
    stdOfEpochsThreshold = mean(stdOfEpochs)+std(stdOfEpochs)*stdOfEpochsStdToReject;
else
    stdOfEpochsThreshold = Inf;
end
noisyEpochs = (maxOfEpochs>maxValueThreshold) | (minOfEpochs<minValueThreshold) | ...
    (stdOfEpochs>stdOfEpochsThreshold);
nNoisyEpochs = sum(noisyEpochs);
if (nNoisyEpochs>0)
    warning('Found %d (out of %d) noisy epochs\n',nNoisyEpochs,length(noisyEpochs));
end
goodEpochs = allEpochs(~noisyEpochs,:);
semEpochs = std(goodEpochs)/sqrt(size(allEpochs,1));
erp = mean(goodEpochs,1);
end

