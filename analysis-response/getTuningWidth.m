function [fullWidthHalfMaxOctaves,fwhmOnset,fwhmOffset] = getTuningWidth(frPeak,interFreqIntervalOctaves)
    freqIndicesInterp = 1:0.01:length(frPeak);
    frPeakInterp = interp1(1:length(frPeak),frPeak,freqIndicesInterp,'linear');
    [peakVal,iPeak] = max(frPeakInterp);
    halfPeak = peakVal./2;

    
    iHalfPeakPrevious = find(frPeakInterp(1:iPeak)<=halfPeak,1,'last');
    iHalfPeakAfter = find(frPeakInterp(iPeak+1:end)<=halfPeak,1,'first')+iPeak;
    
    if isempty(iHalfPeakAfter)        
        [fullWidthHalfMaxOctaves,~] = max([(freqIndicesInterp(find(~isnan(frPeakInterp),1,'last'))-...
            freqIndicesInterp(iHalfPeakPrevious))*interFreqIntervalOctaves,...
            2*(freqIndicesInterp(iPeak)-freqIndicesInterp(iHalfPeakPrevious))*interFreqIntervalOctaves]);
    elseif isempty(iHalfPeakPrevious)
        [fullWidthHalfMaxOctaves,~] = max([(freqIndicesInterp(iHalfPeakAfter)-freqIndicesInterp(...
            find(~isnan(frPeakInterp),1,'first')))*interFreqIntervalOctaves,...
            2*(freqIndicesInterp(iHalfPeakAfter)-freqIndicesInterp(iPeak))*interFreqIntervalOctaves]);
    else
        fullWidthHalfMaxOctaves = (freqIndicesInterp(iHalfPeakAfter)-freqIndicesInterp(iHalfPeakPrevious))*...
            interFreqIntervalOctaves;
        fwhmOnset = freqIndicesInterp(iHalfPeakPrevious);
        fwhmOffset = freqIndicesInterp(iHalfPeakAfter);
    end