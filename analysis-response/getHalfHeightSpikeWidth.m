function widthMs = getHalfHeightSpikeWidth(spikeShape,sr)

[~,maxIndex] = max(abs(spikeShape));
maxValue = spikeShape(maxIndex);
isNegative = maxValue<0;
if isNegative
    spikeShape = -spikeShape;
    maxValue = spikeShape(maxIndex);
end
halfHeight = maxValue/2;
lastIndexBeforeHalfWidthStart = find(spikeShape(1:maxIndex)<=halfHeight,1,'last');
firstIndexAfterHalfWidthend = maxIndex+find(spikeShape(maxIndex+1:end)<=halfHeight,1,'first');
if isempty(lastIndexBeforeHalfWidthStart) || isempty(firstIndexAfterHalfWidthend)
    widthMs = nan;
    return
end
exactCrossingStart = lastIndexBeforeHalfWidthStart + ...
    (halfHeight-spikeShape(lastIndexBeforeHalfWidthStart))./ ...
    (spikeShape(lastIndexBeforeHalfWidthStart+1)-spikeShape(lastIndexBeforeHalfWidthStart));
exactCrossingEnd = firstIndexAfterHalfWidthend-1 + ...
    (spikeShape(firstIndexAfterHalfWidthend-1)-halfHeight)./ ...
    (spikeShape(firstIndexAfterHalfWidthend-1)-spikeShape(firstIndexAfterHalfWidthend));
widthSamples = exactCrossingEnd-exactCrossingStart;
widthMs = widthSamples./sr*1000;
end