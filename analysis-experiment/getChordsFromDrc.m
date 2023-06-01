function [timesSecPerChord,soundLevelIndPerFreqAndChord,freqs,soundLevelsDb] = ...
    getChordsFromDrc(drcStartTimesSec,drcs,nFirstChordsToIgnore)
    
    freqs = drcs{1}.soundData.freqs;
    soundLevelsDb = drcs{1}.soundData.soundLevelsDb;
    nFreqs = length(freqs);
    nDrcs = length(drcs);
    nTotalChords = 0;
    for drcInd = 1:nDrcs
        nChordsInCurrentDrc = size(drcs{drcInd}.soundData.soundLevelIndPerFreqAndChord,2);
        nRepsCurrentDrc = length(drcStartTimesSec{drcInd});
        nTotalChords = nTotalChords + (nChordsInCurrentDrc-nFirstChordsToIgnore)*nRepsCurrentDrc;
    end
    timesSecPerChord = nan(nTotalChords,1);
    soundLevelIndPerFreqAndChord = nan(nFreqs,nTotalChords);
    chordCount = 0;
    for drcInd = 1:nDrcs
        currentDrcStartTimes = drcStartTimesSec{drcInd};
        nRepsCurrentDrc = length(currentDrcStartTimes);
        soundLevelIndPerFreqAndChordCurrentDrc = drcs{drcInd}.soundData.soundLevelIndPerFreqAndChord;
        nChordsInCurrentDrc = size(soundLevelIndPerFreqAndChordCurrentDrc,2)-nFirstChordsToIgnore;
        tonePipLengthSec = drcs{drcInd}.soundData.properties.tonePipLengthMs/1000;
        timesCurrentDrcChords = (nFirstChordsToIgnore+(0:(nChordsInCurrentDrc-1))).*tonePipLengthSec;
        for repInd = 1:nRepsCurrentDrc
            timesSecPerChord(chordCount+1:chordCount+nChordsInCurrentDrc) = ...
                currentDrcStartTimes(repInd)+timesCurrentDrcChords;
            soundLevelIndPerFreqAndChord(:,chordCount+1:chordCount+nChordsInCurrentDrc) = ...
                soundLevelIndPerFreqAndChordCurrentDrc(:,nFirstChordsToIgnore+1:end);
            chordCount = chordCount + nChordsInCurrentDrc;
        end
    end
end