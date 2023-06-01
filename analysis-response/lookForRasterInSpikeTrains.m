function [newRaster,isExactMatch] = lookForRasterInSpikeTrains(raster,spikeTrainPerPeriod,timePointsToObtain)
EPSILON = 0.001;
nRasterTrials = size(raster,1);
nSpikeTrains = size(spikeTrainPerPeriod,1);
newRaster = nan(nRasterTrials,ceil(diff(timePointsToObtain)));
firstSpikeTrainIndex = max(-timePointsToObtain(1)+1,1);
nTimepointsRaster = size(raster,2);
nTimepointsToReduceFromEnd = max(nTimepointsRaster,timePointsToObtain(2));
SIGMA_MS = 3;
gaussWin = getGaussWin(SIGMA_MS,SIGMA_MS*8+1)';
rasterSmoothed = conv2(full(raster),gaussWin,'same');
nValidTimePointsPerSpikeTrain = nan(nSpikeTrains,1);
for iSpikeTrain = 1:nSpikeTrains
    nValidTimePointsPerSpikeTrain(iSpikeTrain) = length(spikeTrainPerPeriod{iSpikeTrain})-...
        nTimepointsToReduceFromEnd-firstSpikeTrainIndex+1;
end
nTotalTimePoints = sum(nValidTimePointsPerSpikeTrain);
cumSumTimePointsPerSpikeTrain = cumsum(nValidTimePointsPerSpikeTrain);
isExactMatch = true(nRasterTrials,1);
for iTrial = 1:nRasterTrials
    currentRasterTrial = raster(iTrial,:);
    
    iRandSpikeTrain = find(cumSumTimePointsPerSpikeTrain>rand()*nTotalTimePoints,1,'first');
    isFoundMatch = false;
    for iSpikeTrain = [iRandSpikeTrain:nSpikeTrains, 1:iRandSpikeTrain-1]
        currentSpikeTrain = spikeTrainPerPeriod{iSpikeTrain};
        lastSpikeTrainIndex = length(currentSpikeTrain)-nTimepointsToReduceFromEnd;
        for iTimePoint = randsample(firstSpikeTrainIndex:lastSpikeTrainIndex,...
                lastSpikeTrainIndex-firstSpikeTrainIndex+1)%[iTimePointRand:lastSpikeTrainIndex, firstSpikeTrainIndex:iTimePointRand-1]
            if currentSpikeTrain(iTimePoint:iTimePoint+nTimepointsRaster-1)==currentRasterTrial
                indices = round(iTimePoint+timePointsToObtain(1):1:iTimePoint+timePointsToObtain(2)-EPSILON);
                newRaster(iTrial,:) = spikeTrainPerPeriod{iSpikeTrain}(indices);
                isFoundMatch = true;
                break
            end
        end
        if isFoundMatch; break; end
    end
    
    if isFoundMatch; continue; end
    %% no exact match - pick best not exact match
    isExactMatch(iTrial) = false;
    nSpikesInTrial = sum(currentRasterTrial);
    minError = Inf;
    currentRasterTrial = rasterSmoothed(iTrial,:);

    for iSpikeTrain = 1:nSpikeTrains
                currentSpikeTrain = spikeTrainPerPeriod{iSpikeTrain};
        lastSpikeTrainIndex = length(currentSpikeTrain)-nTimepointsToReduceFromEnd;
        for iTimePoint = firstSpikeTrainIndex:lastSpikeTrainIndex
            currentSeg = currentSpikeTrain(iTimePoint:iTimePoint+nTimepointsRaster-1);
            if sum(currentSeg)~=nSpikesInTrial; continue; end; %Look at only segments with same num of spikes
            smoothedSeg = conv(currentSeg,gaussWin,'same');
            currentError = mean((smoothedSeg-currentRasterTrial).^2);
            if currentError>=minError; continue; end
            %% New Best Match
            minError = currentError;
            indices = round(iTimePoint+timePointsToObtain(1):1:iTimePoint+timePointsToObtain(2)-EPSILON);
            newRaster(iTrial,:) = spikeTrainPerPeriod{iSpikeTrain}(indices);
            1;
        end
    end
    
    %% if no single match for same number of spikes, than try again and don't check num of spikes
    if minError~=Inf; continue; end
    
    for iSpikeTrain = 1:nSpikeTrains
                currentSpikeTrain = spikeTrainPerPeriod{iSpikeTrain};
        lastSpikeTrainIndex = length(currentSpikeTrain)-nTimepointsToReduceFromEnd;
        for iTimePoint = firstSpikeTrainIndex:lastSpikeTrainIndex
            currentSeg = currentSpikeTrain(iTimePoint:iTimePoint+nTimepointsRaster-1);
            smoothedSeg = conv(currentSeg,gaussWin,'same');
            currentError = mean((smoothedSeg-currentRasterTrial).^2);
            if currentError>=minError; continue; end
            %% New Best Match
            minError = currentError;
            indices = round(iTimePoint+timePointsToObtain(1):1:iTimePoint+timePointsToObtain(2)-EPSILON);
            newRaster(iTrial,:) = spikeTrainPerPeriod{iSpikeTrain}(indices);
            1;
        end
    end
end

if any(isnan(newRaster(:)))
    disp('NAN IN RASTER!')
end