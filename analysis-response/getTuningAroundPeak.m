function frAroundPeak = getTuningAroundPeak(frPerFreq)
    nFreqs = length(frPerFreq);
    frAroundPeak = nan(1,nFreqs*2-1);
    [~,peakInd] = max(frPerFreq);
    frAroundPeak(nFreqs-peakInd+(1:nFreqs)) =  frPerFreq;