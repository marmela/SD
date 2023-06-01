function isValueWithin  = getIfValuesWithinRanges(values, ranges)
    assert(iscolumn(values) || isrow(values))
    isValueWithin = false(size(values,1),size(values,2));
    nRanges = size(ranges,1);
    assert(size(ranges,2)==2);
    for rangeInd = 1:nRanges
        isValueWithin = isValueWithin | ...
            (values>=ranges(rangeInd,1) & values<ranges(rangeInd,2));
    end
end
    

