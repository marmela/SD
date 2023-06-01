function result = getDrcTuningAndContext(spikeTimesSec, ...
    drcStartTimesSec, drcs,  nFirstChordsToIgnore, peakTimeMsToUse,iFreqToIgnore)

if ~exist('iFreqToIgnore','var')
    iFreqToIgnore = [];
end
preStimStartTimeInSec = 0.05;
postStimStartTimeInSec = 0.1;
binSizeMs = 1;
gaussSmoothWin = getGaussWin(5,20)';
maxLatencyMs = 50;
MS_IN_SEC = 1000;

psthTimes = -preStimStartTimeInSec*1000+binSizeMs./2:binSizeMs:postStimStartTimeInSec*1000-binSizeMs./2;
nTimepointsPsth = length(psthTimes);
%% Constants
RASTER_BIN_SIZE_MS = 1;

%%
nDrcs = length(drcs);
toneLengthMs = drcs{1,1}.soundData.properties.tonePipLengthMs;
drcLengthSec = drcs{1}.soundData.properties.DrcLengthSec;
[timesSecPerChord,soundLevelIndPerFreqAndChord,freqs,soundLevelsDb] = ...
    getChordsFromDrc(drcStartTimesSec,drcs,nFirstChordsToIgnore);
nFreqs = length(freqs);
isFreqToInclude = true(1,nFreqs);
isFreqToInclude(iFreqToIgnore) = false;
iFreqsToInclude = find(isFreqToInclude);

%%
allDrcStartTimesSec = [];
for iDrc=1:length(drcStartTimesSec)
    allDrcStartTimesSec = [allDrcStartTimesSec; drcStartTimesSec{iDrc}];
end
periDrcTimeAllDrcAvg = 0.5;
allDrcAvgBinSizeMs = 1;
rasterAllDrc = getRaster(spikeTimesSec, allDrcStartTimesSec, ...
    periDrcTimeAllDrcAvg, periDrcTimeAllDrcAvg+drcLengthSec, allDrcAvgBinSizeMs);
psthAllDrcsFr = mean(rasterAllDrc)*MS_IN_SEC./allDrcAvgBinSizeMs;
timesMsPsthAllDrcs = -periDrcTimeAllDrcAvg*MS_IN_SEC+allDrcAvgBinSizeMs./2:allDrcAvgBinSizeMs:...
    (periDrcTimeAllDrcAvg+drcLengthSec)*MS_IN_SEC;
result.AllDrcs.psthFr = psthAllDrcsFr;
result.AllDrcs.timesMs = timesMsPsthAllDrcs;


%% STATS for signficant responses
alphaStats = 0.001;
STATS_BIN_SIZE_MS = 10;
STATS_PRE_STIM_TIME_SEC = 0;
STATS_POST_STIM_TIME_SEC = 0.1;
[allChordsRaster] = getRaster(spikeTimesSec, timesSecPerChord, ...
    STATS_PRE_STIM_TIME_SEC, STATS_POST_STIM_TIME_SEC, STATS_BIN_SIZE_MS);
nStatsBins = size(allChordsRaster,2);
nTonesTotal = sum(soundLevelIndPerFreqAndChord(:));
allResponses = nan(nTonesTotal,nStatsBins);
iFreqPerTone = nan(nTonesTotal,1);
chordCount = 0;
for iFreq = iFreqsToInclude%1:nFreqs
    isFreqInChord = logical(soundLevelIndPerFreqAndChord(iFreq,:));
    nChordsForCurrentFreq = sum(isFreqInChord);
    allResponses(chordCount+1:chordCount+nChordsForCurrentFreq,:) = ...
        allChordsRaster(isFreqInChord,:);
    iFreqPerTone(chordCount+1:chordCount+nChordsForCurrentFreq,:) = iFreq;
    chordCount = chordCount + nChordsForCurrentFreq;
end
iFreqPerTone(chordCount+1:end,:) = [];
allResponses(chordCount+1:end,:) = [];
for iBin = nStatsBins:-1:1
    pPerBin(iBin) = kruskalwallis(allResponses(:,iBin),iFreqPerTone,'off');
end
alphaStatsBonferroni = alphaStats./nStatsBins;
result.stats.significantBonferroni = any(pPerBin<alphaStatsBonferroni);
result.stats.pPerBinUnCorrected = pPerBin;
result.stats.binsEdgesMs = -STATS_PRE_STIM_TIME_SEC*MS_IN_SEC:STATS_BIN_SIZE_MS:...
    STATS_POST_STIM_TIME_SEC*MS_IN_SEC;

%% Times for raster and PSTH
timesRasterMs = -preStimStartTimeInSec*1000+RASTER_BIN_SIZE_MS/2:RASTER_BIN_SIZE_MS:...
    postStimStartTimeInSec*1000-RASTER_BIN_SIZE_MS/2;

%% Get PSTH for two halves of data
medianChordTimeSec = median(timesSecPerChord);
isChordInFirstHalf = timesSecPerChord<=medianChordTimeSec;
for iHalf = [2,1]
    if iHalf==1
        isChordInCurrentHalf = isChordInFirstHalf;
    else
        isChordInCurrentHalf = ~isChordInFirstHalf;
    end
    timesSecPerChordCurrentHalf = timesSecPerChord(isChordInCurrentHalf);
    [allChordsRasterCurrentHalf] = getRaster(spikeTimesSec, timesSecPerChordCurrentHalf, ...
        preStimStartTimeInSec, postStimStartTimeInSec, RASTER_BIN_SIZE_MS);
    
    allChordsRasterFr = allChordsRasterCurrentHalf*1000./RASTER_BIN_SIZE_MS;
    meanAllTrials = mean(allChordsRasterFr);
    for iFreq = iFreqsToInclude %nFreqs:-1:1
        isFreqInChord = logical(soundLevelIndPerFreqAndChord(iFreq,isChordInCurrentHalf));
        pFreq = mean(isFreqInChord);
        meanForCurrentFreq = mean(allChordsRasterFr(isFreqInChord,:));
        psthPerFreqPerHalf{iHalf}(iFreq,:) = (meanForCurrentFreq-meanAllTrials)./(1-pFreq);
    end

end

%%
[allChordsRaster] = getRaster(spikeTimesSec, timesSecPerChord, ...
    preStimStartTimeInSec, postStimStartTimeInSec, RASTER_BIN_SIZE_MS);

%% Get psth per frequency
allChordsRasterFr = allChordsRaster*1000./RASTER_BIN_SIZE_MS;
meanAllTrials = mean(allChordsRasterFr);
for iFreq = iFreqsToInclude %nFreqs:-1:1
    isFreqInChord = logical(soundLevelIndPerFreqAndChord(iFreq,:));
    pFreq = mean(isFreqInChord);
    meanForCurrentFreq = mean(allChordsRasterFr(isFreqInChord,:));
    psthPerFreq(iFreq,:) = (meanForCurrentFreq-meanAllTrials)./(1-pFreq);
end
timesPsthMs = (-preStimStartTimeInSec*1000:RASTER_BIN_SIZE_MS:...
    (postStimStartTimeInSec*1000-RASTER_BIN_SIZE_MS))+ RASTER_BIN_SIZE_MS./2;

%%
smoothedPsthPerFreq = conv2(psthPerFreq,gaussSmoothWin,'same');
isRelevantTime = timesRasterMs>0 & timesRasterMs<=50;
relevantTimesRaster = timesRasterMs(isRelevantTime);
psthPerFreqSmoothedRelevantTimes = smoothedPsthPerFreq(:,isRelevantTime);
[~,peakIndex] = max(max(psthPerFreqSmoothedRelevantTimes));
peakTimeMs = relevantTimesRaster(peakIndex);
meanFrPerFreq = psthPerFreqSmoothedRelevantTimes(:,peakIndex);
if exist('peakTimeMsToUse','var') && ~isempty(peakTimeMsToUse)
    iPeakToUse = find(timesRasterMs==peakTimeMsToUse,1,'first');
    if ~isempty(iPeakToUse)
        meanFrPerFreqSameTimeAllStates = smoothedPsthPerFreq(:,iPeakToUse);
    else
        meanFrPerFreqSameTimeAllStates = [];
    end
end

[~,iBestFreq] = max(meanFrPerFreq);

%%
tic;
nValidChordsInDrc = size(drcs{1,1}.soundData.soundLevelIndPerFreqAndChord,2)-nFirstChordsToIgnore;
nValidChordPairs = nValidChordsInDrc-1;
toneLengthSec = toneLengthMs./MS_IN_SEC;
timesSecValidChordsFromDrcOnset = (nFirstChordsToIgnore:...
    nValidChordPairs+nFirstChordsToIgnore-1)'*toneLengthSec;
timesSecPerPairAll = [];
isCombinationPerPairAll = false(0,0,0);
for iDrc = nDrcs:-1:1
    isTonePerFreqAndChord = logical(drcs{iDrc}.soundData.soundLevelIndPerFreqAndChord(...
        :,nFirstChordsToIgnore+1:end));
    currentDrcTimeSec = drcStartTimesSec{iDrc};
    isCombinationInChord = false(nFreqs,nFreqs,nValidChordsInDrc-1);
    for iPair = 1:nValidChordPairs
        isFreqIn1stChord = isTonePerFreqAndChord(:,iPair);
        isFreqIn2ndChord = isTonePerFreqAndChord(:,iPair+1);
        isCombinationInChord(isFreqIn1stChord,isFreqIn2ndChord,iPair) = true;
    end
    nDrcReps = length(currentDrcTimeSec);
    isCombinationInChordAllRepsCurrentDrc = repmat(isCombinationInChord,1,1,nDrcReps);
    nChordPairsCurrentDrc = size(isCombinationInChordAllRepsCurrentDrc,3);
    for iDrcRep = 1:nDrcReps
        timesSecPerPairAll = [timesSecPerPairAll; ...
            timesSecValidChordsFromDrcOnset+currentDrcTimeSec(iDrcRep)];
    end
    isCombinationPerPairAll(:,:,end+1:end+nChordPairsCurrentDrc) = ...
        isCombinationInChordAllRepsCurrentDrc;
end

preStimStartTimeInSecPairs = 0;
postStimStartTimeInSecPairs = 0.1;
binSizeMsPairs = 100;
[rasterAllChords] = getRaster(spikeTimesSec , timesSecPerPairAll, ...
    preStimStartTimeInSecPairs, postStimStartTimeInSecPairs, binSizeMsPairs);

meanFrPerFreqPair = nan(nFreqs,nFreqs);
directionSelectivityIndex = nan(nFreqs,nFreqs);
pPerFreqPair = nan(nFreqs,nFreqs);

for iFreq1st = 1:nFreqs-1
    for iFreq2nd = iFreq1st+1:nFreqs
        isForwardPairInChord = squeeze(isCombinationPerPairAll(iFreq1st,iFreq2nd,:));
        isBackwardPairInChord = squeeze(isCombinationPerPairAll(iFreq2nd,iFreq1st,:));
        
        [~,pPerFreqPair(iFreq1st,iFreq2nd)] = ttest2(...
            rasterAllChords(isForwardPairInChord),rasterAllChords(isBackwardPairInChord));
        meanForward = mean(rasterAllChords(isForwardPairInChord))./binSizeMsPairs*MS_IN_SEC;
        meanBackward = mean(rasterAllChords(isBackwardPairInChord))./binSizeMsPairs*MS_IN_SEC;
        meanFrPerFreqPair(iFreq1st,iFreq2nd) = meanForward;
        meanFrPerFreqPair(iFreq2nd,iFreq1st) = meanBackward;
        directionSelectivityIndex(iFreq1st,iFreq2nd) = (meanForward-meanBackward)./max(meanForward,meanBackward);
        directionSelectivityIndex(iFreq2nd,iFreq1st) = -directionSelectivityIndex(iFreq1st,iFreq2nd);
    end
end
result.pairDirection.meanFrPerFreqPair = meanFrPerFreqPair;
result.pairDirection.directionSelectivityIndex = directionSelectivityIndex;
result.pairDirection.pPerFreqPair = pPerFreqPair;

%%
nValidChordsInDrc = size(drcs{1,1}.soundData.soundLevelIndPerFreqAndChord,2)-nFirstChordsToIgnore;
nTotalBestFreqReps = 0;
for iDrc = 1:nDrcs
    isTonePerFreqAndChord = logical(drcs{iDrc}.soundData.soundLevelIndPerFreqAndChord(...
        :,nFirstChordsToIgnore+1:end));
    nRepsFreqInCurrentDrc = sum(isTonePerFreqAndChord(iBestFreq,:));
    nRepsFreqInCurrentDrc = nRepsFreqInCurrentDrc-1; %remove the first one because it has no known context
    if nRepsFreqInCurrentDrc<0
        nRepsFreqInCurrentDrc = 0;
    end
    nRepsCurrentDrc = length(drcStartTimesSec{iDrc});
    nTotalBestFreqReps = nTotalBestFreqReps + nRepsCurrentDrc*nRepsFreqInCurrentDrc;
end

rasterBestFreq = nan(nTotalBestFreqReps,nTimepointsPsth);
nChordsFromPreviousTone =  nan(nTotalBestFreqReps,1);
psthPerNChordsFromPreviousTone = zeros(nValidChordsInDrc,nTimepointsPsth);
distanceFromPreviousToneCount = zeros(nValidChordsInDrc,1);
psthNoBestFreq = zeros(1,nTimepointsPsth);
noBestFreqCount = 0;

for iDrc = nDrcs:-1:1
    isTonePerFreqAndChord = logical(drcs{iDrc}.soundData.soundLevelIndPerFreqAndChord(...
        :,nFirstChordsToIgnore+1:end));
    bestFreqChordIndices = find(isTonePerFreqAndChord(iBestFreq,:))+nFirstChordsToIgnore;
    noBestFreqChordIndices = setdiff(bestFreqChordIndices(1):nFirstChordsToIgnore+nValidChordsInDrc,...
        bestFreqChordIndices);
    nChordsFromPreviousFreq = diff(bestFreqChordIndices);
    bestFreqChordIndices(1) = [];
    bestFreqTimeFromDrcOnsetSec = (bestFreqChordIndices-1)*toneLengthMs./1000;
    noBestFreqTimeFromDrcOnsetSec = (noBestFreqChordIndices-1)*toneLengthMs./1000;
    currentDrcTimeSec = drcStartTimesSec{iDrc};
    nRepsOfFreqInCurrentDrc = length(bestFreqTimeFromDrcOnsetSec);
    nRepsCurrentDrc = length(currentDrcTimeSec);
    nTotalBestFreqCurrentDrcReps = nRepsOfFreqInCurrentDrc*nRepsCurrentDrc;
    bestFreqInAllCurrentDrcRepsTimeSec =  ...
        repmat(bestFreqTimeFromDrcOnsetSec,nRepsCurrentDrc,1)+...
        repmat(currentDrcTimeSec,1,nRepsOfFreqInCurrentDrc);
    nChordsFromPreviousFreqAllCurrentDrcReps = repmat(nChordsFromPreviousFreq,nRepsCurrentDrc,1);
    bestFreqInAllCurrentDrcRepsTimeSec = bestFreqInAllCurrentDrcRepsTimeSec(:);
    nChordsFromPreviousFreqAllCurrentDrcReps = nChordsFromPreviousFreqAllCurrentDrcReps(:);
    nRepsOfNoBestFreqInCurrentDrc = length(noBestFreqTimeFromDrcOnsetSec);
    noBestFreqInAllCurrentDrcRepsTimeSec =  ...
        repmat(noBestFreqTimeFromDrcOnsetSec,nRepsCurrentDrc,1)+...
        repmat(currentDrcTimeSec,1,nRepsOfNoBestFreqInCurrentDrc);
    noBestFreqInAllCurrentDrcRepsTimeSec = noBestFreqInAllCurrentDrcRepsTimeSec(:);
    [rasterCurrentDrc] = getRaster(spikeTimesSec , bestFreqInAllCurrentDrcRepsTimeSec, ...
        preStimStartTimeInSec, postStimStartTimeInSec, binSizeMs);
    
    for iRep = 1:nTotalBestFreqCurrentDrcReps
        nChordsFromTone = nChordsFromPreviousFreqAllCurrentDrcReps(iRep);
        psthPerNChordsFromPreviousTone(nChordsFromTone,:) = ...
            psthPerNChordsFromPreviousTone(nChordsFromTone,:) + rasterCurrentDrc(iRep,:);
        distanceFromPreviousToneCount(nChordsFromTone,:) = ...
            distanceFromPreviousToneCount(nChordsFromTone,:) + 1;
    end
    [rasterCurrentDrcNoBestFreq] = getRaster(spikeTimesSec , noBestFreqInAllCurrentDrcRepsTimeSec, ...
        preStimStartTimeInSec, postStimStartTimeInSec, binSizeMs);
    psthNoBestFreq = psthNoBestFreq + sum(rasterCurrentDrcNoBestFreq);
    noBestFreqCount = noBestFreqCount + size(rasterCurrentDrcNoBestFreq,1);
end

psthNoBestFreqHz = psthNoBestFreq./noBestFreqCount*1000./binSizeMs;
psthPerNChordsFromPreviousToneHz = psthPerNChordsFromPreviousTone*1000./binSizeMs ./ ...
    repmat(distanceFromPreviousToneCount,1,nTimepointsPsth);
psthPerNChordsFromPreviousToneNormalizedHz = conv2(psthPerNChordsFromPreviousToneHz-...
    repmat(psthNoBestFreqHz,nValidChordsInDrc,1),gaussSmoothWin,'same');
psthPerNChordsFromPreviousToneSmoothedHz = conv2(psthPerNChordsFromPreviousToneHz,...
    gaussSmoothWin,'same');

%%
linearSumPerNChordsFromPreviousTone = repmat(smoothedPsthPerFreq(iBestFreq,:),nValidChordsInDrc,1); 
currentOffsetMs = 0;
assert(binSizeMs==1);
for nChordsFromPrevious = 1:nValidChordsInDrc
    currentOffsetMs = currentOffsetMs + toneLengthMs;
    if currentOffsetMs>nTimepointsPsth
        break
    end
    linearSumPerNChordsFromPreviousTone(nChordsFromPrevious,1:end-currentOffsetMs) = ...
        linearSumPerNChordsFromPreviousTone(nChordsFromPrevious,1:end-currentOffsetMs) + ...
        smoothedPsthPerFreq(iBestFreq,currentOffsetMs+1:end);
end
iPeakInPsth = find(timesRasterMs>=peakTimeMs,1,'first');
frPerNChordsPreviousTone = psthPerNChordsFromPreviousToneNormalizedHz(:,iPeakInPsth);
frNormalizedPerNChordsPreviousTone = (frPerNChordsPreviousTone - ...
    linearSumPerNChordsFromPreviousTone(:,iPeakInPsth))./meanFrPerFreq(iBestFreq);
frPerNChordsPreviousToneNotNormalized = psthPerNChordsFromPreviousToneSmoothedHz(:,iPeakInPsth);

%% now linear sum (control condition) is calculated on chords without shoort context (previous chords >100ms ago)
iFirstChord = 6; %ignore context <=100 ms to obtain the clean response without context
psthLongContext = sum(psthPerNChordsFromPreviousTone(iFirstChord:end,:));
countLongContext = sum(distanceFromPreviousToneCount(iFirstChord:end));
psthLongContextNormalizedHz = psthLongContext*1000./binSizeMs ./countLongContext-psthNoBestFreqHz;
psthLongContextHzSmoothed = conv(psthLongContextNormalizedHz,gaussSmoothWin,'same');
linearSumPerNChordsFromPreviousTone2 = repmat(psthLongContextHzSmoothed,nValidChordsInDrc,1); 
currentOffsetMs = 0;
assert(binSizeMs==1);
for nChordsFromPrevious = 1:nValidChordsInDrc
    currentOffsetMs = currentOffsetMs + toneLengthMs;
    if currentOffsetMs>nTimepointsPsth
        break
    end
    linearSumPerNChordsFromPreviousTone2(nChordsFromPrevious,1:end-currentOffsetMs) = ...
        linearSumPerNChordsFromPreviousTone2(nChordsFromPrevious,1:end-currentOffsetMs) + ...
        psthLongContextHzSmoothed(currentOffsetMs+1:end);
end
iPeakInPsth = find(timesRasterMs>=peakTimeMs,1,'first');
frNormalizedPerNChordsPreviousTone2 = (frPerNChordsPreviousTone - ...
    linearSumPerNChordsFromPreviousTone2(:,iPeakInPsth))./meanFrPerFreq(iBestFreq);

%%
result.timesPsthMs = timesRasterMs;
result.freqs.all = freqs;
result.freqs.valid = freqs(iFreqsToInclude);
result.psthPerFreq = psthPerFreq;
result.psthPerFreqPerHalf = psthPerFreqPerHalf;
result.peakTimeMs = peakTimeMs;
result.meanFrPerFreq = meanFrPerFreq;
if exist('peakTimeMsToUse','var') && ~isempty(peakTimeMsToUse)
    result.meanFrPerFreqSameTimeAllStates = meanFrPerFreqSameTimeAllStates;
end
result.frPerNChordsPreviousTone = frPerNChordsPreviousToneNotNormalized;

% result.frNormalizedPerNChordsPreviousTone = frNormalizedPerNChordsPreviousTone;
% REPLACED LINEAR SUM ESTIMATION with new estimate where I exclude chords with short
% context load (<=100 ms)
result.frNormalizedPerNChordsPreviousTone = frNormalizedPerNChordsPreviousTone2;
result.distanceFromPreviousToneCount = distanceFromPreviousToneCount;
result.psthPerNChordsFromPreviousToneNormalizedHz = psthPerNChordsFromPreviousToneNormalizedHz;
% result.linearSumPerNChordsFromPreviousTone = linearSumPerNChordsFromPreviousTone;
% REPLACED LINEAR SUM ESTIMATION with new estimate where I exclude chords with short
% context load (<=100 ms)
result.linearSumPerNChordsFromPreviousTone = linearSumPerNChordsFromPreviousTone2;
