function [filePath,fileName,fileDir] = getFraPerStateAnalysisFilePath(sessInfo)
fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Responses' filesep 'FRA'];
fileName = sprintf('FraPerState_%s-%d',sessInfo.animal,sessInfo.animalSession);
filePath = [fileDir filesep fileName];