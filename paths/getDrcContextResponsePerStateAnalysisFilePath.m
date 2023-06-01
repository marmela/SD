function [filePath,fileName,fileDir] = getDrcContextResponsePerStateAnalysisFilePath(sessInfo)
    fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Responses' filesep 'DrcContext'];
    fileName = sprintf('ResponsePerState_%s-%d',sessInfo.animal,sessInfo.animalSession);
    filePath = [fileDir filesep fileName];