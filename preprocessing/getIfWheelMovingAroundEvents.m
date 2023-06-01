function isMovingPerEvent = getIfWheelMovingAroundEvents(wheelSpeedData,...
    minWheelSpeedMetersPerSec, eventTimeSec, periEventTimeWindowSec)

nEvents = length(eventTimeSec);
isMovingPerEvent = true(nEvents,1);
for iEvent = 1:nEvents
    currentEventTimeSec = eventTimeSec(iEvent);
    wheelSpeedReadingDuringWindowIndex = find(...
        wheelSpeedData.times>=currentEventTimeSec+periEventTimeWindowSec(1) & ...
        wheelSpeedData.times<currentEventTimeSec+periEventTimeWindowSec(2));
    if isempty(wheelSpeedReadingDuringWindowIndex) || ...
            all(wheelSpeedData.meterPerSec(wheelSpeedReadingDuringWindowIndex)<minWheelSpeedMetersPerSec)
        isMovingPerEvent(iEvent) = false;
    end
end