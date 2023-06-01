function [filePath,fileName,fileDir] = getSpikeShapeFilePath(sessInfo)
    fileDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Spikes' filesep 'Shape'];
    fileName = sprintf('SpikeShape_%s-%d',sessInfo.animal,sessInfo.animalSession);
    filePath = [fileDir filesep fileName];