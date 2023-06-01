function powerEnvelope = getPowerEnvelopeHeavyData(data,sr,freqLowCutHz,...
    freqHighCutHz,filterOrder,envelopeLowpassHighCutHz,envelopeLowpassFilterOrder)

nPointsSignal = length(data);
nPointsInSegment = max(sr*freqLowCutHz*2,5e7);
nPointsOverlap = round(nPointsInSegment/4);
nPointsToNotIncludeFromStartOfSegment = round(nPointsOverlap/2);
powerEnvelope = nan(1,length(data),'like',data);
segmentStartSampleInd = 1;
segmentEndSampleInd = min(nPointsInSegment,nPointsSignal);
powerEnvelope(segmentStartSampleInd:segmentEndSampleInd) = getPowerEnvelopeForSegment(...
    data(segmentStartSampleInd:segmentEndSampleInd),sr,freqLowCutHz,freqHighCutHz,filterOrder,...
    envelopeLowpassHighCutHz,envelopeLowpassFilterOrder);

while segmentEndSampleInd<nPointsSignal
    segmentStartSampleInd = segmentEndSampleInd-nPointsOverlap+1;
    segmentEndSampleInd = min(segmentStartSampleInd+nPointsInSegment-1,nPointsSignal);
    
    tempEnvelope = getPowerEnvelopeForSegment(...
    data(segmentStartSampleInd:segmentEndSampleInd),sr,freqLowCutHz,freqHighCutHz,filterOrder,...
    envelopeLowpassHighCutHz,envelopeLowpassFilterOrder);
    
    powerEnvelope(segmentStartSampleInd+nPointsToNotIncludeFromStartOfSegment:...
        segmentEndSampleInd) = tempEnvelope(nPointsToNotIncludeFromStartOfSegment+1:end);
    clear tempEnvelope
end
                
end                
                
function muaEnvelopeLowpssed = getPowerEnvelopeForSegment(...
    data,sr,freqLowCutHz,freqHighCutHz,filterOrder,...
    envelopeLowpassHighCutHz,envelopeLowpassFilterOrder)

muaEnvelope = getEnvelopeOfBandpassSignal(data,sr,freqLowCutHz,freqHighCutHz,filterOrder);
[b,a] = butter(envelopeLowpassFilterOrder,envelopeLowpassHighCutHz/(sr/2));
muaEnvelopeLowpssed = single(filtfilt(b,a,double(muaEnvelope)));
clear muaEnvelope
end



