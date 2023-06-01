function widthMs = getPeakToTroughSpikeWidth(spikeShape,peakIndex,sr)
    if spikeShape(peakIndex)<0
        spikeShape = -spikeShape;
    end
    sampleSubRes = 1/100;
    newSamples = 1:sampleSubRes:length(spikeShape);
    newSpikeShape = interp1(1:length(spikeShape),spikeShape,newSamples,'spline');
    newPeakIndex = find(newSamples>=peakIndex,1,'first');
    [~,nNewSamplesAfterPeak] = min(newSpikeShape(newPeakIndex+1:end));
    widthMs = nNewSamplesAfterPeak*sampleSubRes/sr*1000;
end