function [raster] = getRaster(spikeTimesInSec, stimStartTimesInSec, ...
    preStimStartTimeInSec, postStimStartTimeInSec, sizeOfBinForRsterInMs)

if ~issorted(spikeTimesInSec)
    spikeTimesInSec = sort(spikeTimesInSec,'ascend');
end
if issorted(stimStartTimesInSec)
    [raster] = getRasterFastForSorted(spikeTimesInSec, stimStartTimesInSec, ...
        preStimStartTimeInSec, postStimStartTimeInSec, sizeOfBinForRsterInMs);
else
    [stimStartTimesInSecSorted,iSorted] = sort(stimStartTimesInSec,'ascend');
    [rasterSorted] = getRasterFastForSorted(spikeTimesInSec, stimStartTimesInSecSorted, ...
        preStimStartTimeInSec, postStimStartTimeInSec, sizeOfBinForRsterInMs);
    raster(iSorted,:) = rasterSorted;
end
