function [result] = getYokedRasterFromSpontaneousAcitivty(spikeTimesCurrentSec,noiseTimesData,...
    isiTimePeriods,raster,timesMs, onsetTimesMs, timePointsToObtain,iStateStim,iStateIsi)
isOnsetTime = timesMs>=onsetTimesMs(1) & timesMs<onsetTimesMs(2);
isRelevantTime = timesMs>=timePointsToObtain(1) & timesMs<timePointsToObtain(2);
currentStateOnsetResponse = raster(iStateStim,isOnsetTime);
spikeTrainPerPeriod = getSpikeTrainBetweenTimePeriods(spikeTimesCurrentSec,...
    isiTimePeriods(iStateIsi,:), noiseTimesData.noiseTimesSec);
[newRaster,isExactMatch] = lookForRasterInSpikeTrains(currentStateOnsetResponse,...
    spikeTrainPerPeriod,timePointsToObtain);
result.raster.real = raster(iStateStim,isRelevantTime);
result.raster.yolked = newRaster;
result.timesMs = timesMs(isRelevantTime);
result.yokedTimesMs = onsetTimesMs;
result.isExactMatch = isExactMatch;