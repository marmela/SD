function [filePath,fileName,fileDir] = getClickResponsePerStateAnalysisFilePath(sessInfo,isClicks)
if ~exist('isClicks','var')
    isClicks = true;
end
if isClicks
    fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Responses' filesep 'Clicks'];
else
    fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Responses' filesep 'ToneStream'];
end
fileName = sprintf('ResponsePerState_%s-%d',sessInfo.animal,sessInfo.animalSession);
filePath = [fileDir filesep fileName];
1;