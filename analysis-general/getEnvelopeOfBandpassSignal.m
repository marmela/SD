function envelope = getEnvelopeOfBandpassSignal(data,sr,bandpassLow,bandpassHigh,filterOrder)
    envelope = abs(hilbert(bandpassHeavyData(data, sr, bandpassLow, bandpassHigh, filterOrder,'true')));
end