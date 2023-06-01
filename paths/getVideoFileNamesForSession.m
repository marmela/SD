function [videoFileNames,videoFileExt,videoDir] = getVideoFileNamesForSession(sessInfo)

videoDir = [SdLocalPcDef.RAW_DATA_DIR filesep sessInfo.animal filesep ...
    sprintf('Block-%d',sessInfo.tdtBlock)];
listing = dir(fullfile(videoDir, '*.mp4'));
videoFileFullNames = extractfield(listing,'name')';
[~, videoFileNames, videoFileExt] = cellfun(@fileparts,videoFileFullNames,'UniformOutput',false);
1;
