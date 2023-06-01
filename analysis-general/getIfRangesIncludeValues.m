function isRangeInclude  = getIfRangesIncludeValues(ranges,values)
    assert(iscolumn(values) || isrow(values))
    assert(size(ranges,2)==2);
    nRanges = size(ranges,1);
    isRangeInclude = false(nRanges,1);
    for rangeInd = 1:nRanges
        isRangeInclude(rangeInd) = any(values>=ranges(rangeInd,1) & values<ranges(rangeInd,2));
    end
    
end
    