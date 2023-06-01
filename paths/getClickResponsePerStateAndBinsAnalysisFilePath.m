function [filePath,fileName,fileDir] = getClickResponsePerStateAndBinsAnalysisFilePath(sessInfo,isClicks,nBins)
if ~exist('isClicks','var')
    isClicks = true;
end
if isClicks
    fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Responses' filesep sprintf('Clicks-%dBins',nBins)];
else
    fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Responses' filesep sprintf('ToneStream-%dBins',nBins)];
end
fileName = sprintf('ResponsePerState_%s-%d',sessInfo.animal,sessInfo.animalSession);
filePath = [fileDir filesep fileName];
1;