function [timesSecPerChord,soundLevelIndPerFreqAndChord,freqs,soundLevelsDb] = ...
    getChordTimesFromDrcParts(drcs,nFirstChordsToIgnore,drcPartOnsetSec,drcId,drcPartIndex,iFreqsToIgnore)

if ~exist('iFreqsToIgnore','var')
    iFreqsToIgnore = [];
end
MS_IN_SEC = 1000;
assert(length(drcPartOnsetSec)==length(drcId))
assert(length(drcId)==length(drcPartIndex));
freqs = drcs{1}.soundData.freqs;
freqs(iFreqsToIgnore) = [];
soundLevelsDb = drcs{1}.soundData.soundLevelsDb;
chordLengthMs = drcs{1}.soundData.properties.tonePipLengthMs;
chordLengthSec = chordLengthMs./MS_IN_SEC;
nFreqs = length(freqs);
nDrcs = length(drcs);
nSecLongDrcParts = length(drcPartOnsetSec);
nChordsInSec = round(MS_IN_SEC./chordLengthMs);
assert(nChordsInSec==MS_IN_SEC./chordLengthMs);
maxNChords = nSecLongDrcParts*nChordsInSec;
timesSecPerChord = nan(maxNChords,1);
soundLevelIndPerFreqAndChord = nan(nFreqs,maxNChords);
chordCount = 0;
for drcInd = 1:nDrcs
    iAllPartsInCurrentDrc = find(drcId==drcInd);
    nRepsCurrentDrc = length(iAllPartsInCurrentDrc);
    soundLevelIndPerFreqAndChordCurrentDrc = drcs{drcInd}.soundData.soundLevelIndPerFreqAndChord;
    soundLevelIndPerFreqAndChordCurrentDrc(iFreqsToIgnore,:) = [];
    
    for iPartRep = iAllPartsInCurrentDrc'
        iPartInDrc = drcPartIndex(iPartRep);
        partOnsetSec = drcPartOnsetSec(iPartRep);
        partChordsIndicesInDrc = (iPartInDrc-1)*nChordsInSec + (1:nChordsInSec);
        
        timesCurrentDrcChordsSec = partOnsetSec + (0:nChordsInSec-1).*chordLengthSec;
        
        %if first part then need to remove first chords
        if iPartInDrc == 1
            partChordsIndicesInDrc(1:nFirstChordsToIgnore) = [];
            timesCurrentDrcChordsSec(1:nFirstChordsToIgnore) = [];
        end
        
        nChordsInCurrentPart = length(partChordsIndicesInDrc);
        timesSecPerChord(chordCount+1:chordCount+nChordsInCurrentPart) = timesCurrentDrcChordsSec;
        soundLevelIndPerFreqAndChord(:,chordCount+1:chordCount+nChordsInCurrentPart) = ...
            soundLevelIndPerFreqAndChordCurrentDrc(:,partChordsIndicesInDrc);
        chordCount = chordCount + nChordsInCurrentPart;
        
    end
end

timesSecPerChord(chordCount+1:end) = [];
soundLevelIndPerFreqAndChord(:,chordCount+1:end) = [];
end