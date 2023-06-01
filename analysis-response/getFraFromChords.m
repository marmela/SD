function [fraSpikesPerSec,stats] = getFraFromChords (timesSecPerChord, ...
    soundLevelIndPerFreqAndChord,spikeTimesSec,spikingTemporalWindowLengthMs,isCalcStats)

if ~exist('isCalcStats','var')
    isCalcStats = false;
end
preStimStartTimeInSec = -spikingTemporalWindowLengthMs(1)./1000; %0;%0.1;
postStimStartTimeInSec = spikingTemporalWindowLengthMs(2)./1000;%0.05; %0.2;
sizeOfBinForRsterInMs = diff(spikingTemporalWindowLengthMs); %50; %1;
[allChordsRaster] = getRaster(spikeTimesSec, timesSecPerChord, ...
    preStimStartTimeInSec, postStimStartTimeInSec, sizeOfBinForRsterInMs);
assert(iscolumn(allChordsRaster));
nFreqs = size(soundLevelIndPerFreqAndChord,1);
nSoundLevels = max(soundLevelIndPerFreqAndChord(:));
fraSpikesPerSec = nan(nFreqs,nSoundLevels);

for iFreq = nFreqs:-1:1
    isChordWithoutFreq = soundLevelIndPerFreqAndChord(iFreq,:)==0;
    noFreqMeanResponseSpikesPerSec = mean(allChordsRaster(isChordWithoutFreq))*...
        (1000./sizeOfBinForRsterInMs);
    
    for iSoundLevel = nSoundLevels:-1:1
        isChordWithFreqAndSoundLevel =soundLevelIndPerFreqAndChord(iFreq,:)==iSoundLevel;
        fraSpikesPerSec(iFreq,iSoundLevel) = mean(allChordsRaster(isChordWithFreqAndSoundLevel))*...
            (1000./sizeOfBinForRsterInMs)-noFreqMeanResponseSpikesPerSec;
    end
end

%%
if isCalcStats
    nTotalTonePips = sum(sum(soundLevelIndPerFreqAndChord~=0));
    spikesPerTonePip = nan(nTotalTonePips,1);
    groupPerTonePip = nan(nTotalTonePips,1);
    nToneRepsCount = 0;
    for iFreq = nFreqs:-1:1
        isChordWithoutFreq = soundLevelIndPerFreqAndChord(iFreq,:)==0;
        for iSoundLevel = nSoundLevels:-1:1
            currentToneId = (iFreq-1)*nSoundLevels + iSoundLevel;
            isChordWithFreqAndSoundLevel =soundLevelIndPerFreqAndChord(iFreq,:)==iSoundLevel;
            currentToneSpikesPerTrial= allChordsRaster(isChordWithFreqAndSoundLevel);
            nRepsCurrentTone = length(currentToneSpikesPerTrial);

            spikesPerTonePip(nToneRepsCount+1:nToneRepsCount+nRepsCurrentTone) = currentToneSpikesPerTrial;
            groupPerTonePip(nToneRepsCount+1:nToneRepsCount+nRepsCurrentTone) = currentToneId;

            nToneRepsCount = nToneRepsCount + nRepsCurrentTone;
        end
    end
    [stats.p,stats.tbl,stats.stats] = kruskalwallis(spikesPerTonePip,groupPerTonePip,'off');    
else
    stats = [];
end


end
