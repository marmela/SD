function [raster] = getRasterFastForSorted(spikeTimesInSec, stimStartTimesInSec, ...
    preStimStartTimeInSec, postStimStartTimeInSec, sizeOfBinForRsterInMs)

if(size(stimStartTimesInSec,1)<size(stimStartTimesInSec,2))
    stimStartTimesInSec = stimStartTimesInSec';
end
assert(issorted(spikeTimesInSec));
assert(issorted(stimStartTimesInSec));
assert(postStimStartTimeInSec>-preStimStartTimeInSec);
nSpikes = length(spikeTimesInSec);

%% This part is important to deal with machine percision problems
% if our spike & stim times are rounded to the closest millisecond (e.g. 2327ms), their
% representation as double variables could be very slightly less or more than that (e.g.
% 2326.999999999ms). if our sizeOfBinForRsterInMs==1 than the spike at 2327ms could fall to
% both the [2326,2327)ms bin as well as the [2327,2328)ms bin. To make sure that spikes
% that fall exactly on raster bin edges will consistently land on one side of the bin
% edge I am increasing each spike time by infinitesimal amount. That way, if a spike is
% at X ms, it will always fall to the [X,X+1) bin and never to the [X-1,X) bin
spikeTimesInSec = spikeTimesInSec + eps(spikeTimesInSec);
spikeTimesInSec = spikeTimesInSec + eps(spikeTimesInSec); 
%%
numOfEvents = length(stimStartTimesInSec);
totalTimeOfDataSegmentsInMs = (preStimStartTimeInSec + ...
    postStimStartTimeInSec)*1000;

EPSILON = 10^-9;

lastEdgeForRaster = ceil(totalTimeOfDataSegmentsInMs/sizeOfBinForRsterInMs-EPSILON)*sizeOfBinForRsterInMs; %round to the next bin
binsEdgesInSecForRaster = (0:sizeOfBinForRsterInMs:lastEdgeForRaster)/1000;
numOfBinsForRaster = numel(binsEdgesInSecForRaster)-1;

raster = zeros(numOfEvents,numOfBinsForRaster);

iCurrentSpike = 1;

for iEvent=1:numOfEvents
    dataSegmentStartTimeSec = stimStartTimesInSec(iEvent)-preStimStartTimeInSec;
    dataSegmentEndTimeSec = dataSegmentStartTimeSec+binsEdgesInSecForRaster(end);
    
    %% 
    % advance spike index until spike after event onset or no more spikes
    while iCurrentSpike<=nSpikes && spikeTimesInSec(iCurrentSpike)<dataSegmentStartTimeSec  
        iCurrentSpike = iCurrentSpike+1;
    end
    % if ran out of spikes than we're done
    if iCurrentSpike>nSpikes
        break;
    end
    
    % if first spike after event onset is also after event offset than no spikes for this
    % event
    if spikeTimesInSec(iCurrentSpike)>=dataSegmentEndTimeSec
        continue;
    end
    iFirstSpikeCurrentSegment = iCurrentSpike;
    % advance spike index until spike after event onset or no more spikes
    while iCurrentSpike<=nSpikes && spikeTimesInSec(iCurrentSpike)<dataSegmentEndTimeSec
        iCurrentSpike = iCurrentSpike+1;
    end
    iLastSpikeCurrentSegment = iCurrentSpike-1;
    
    %extract segment spikes
    relevantSpikeTimesSec = spikeTimesInSec(iFirstSpikeCurrentSegment:iLastSpikeCurrentSegment);
    nSegmentSpikes = length(relevantSpikeTimesSec);
    %calculate each spike relevant bin index
    segmentSpikeTimesSecRelativeToOnset = relevantSpikeTimesSec-dataSegmentStartTimeSec;
    relativeSpikeTimesMs = segmentSpikeTimesSecRelativeToOnset.*1000;
    iBinPerSegmentSpike = floor(relativeSpikeTimesMs./sizeOfBinForRsterInMs)+1;
    
    % add each spike to its appropriate bin
    for iSegSpike = 1:nSegmentSpikes
        iBin = iBinPerSegmentSpike(iSegSpike);
        raster(iEvent,iBin) = raster(iEvent,iBin) + 1;
    end
    % next round start from the first spike of this segment (since segments might be
    % overlapping, current segments spikes might be relevant as well)
    iCurrentSpike = iFirstSpikeCurrentSegment;
end