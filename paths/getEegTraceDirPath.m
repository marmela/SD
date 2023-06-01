function eegTraceDirPath = getEegTraceDirPath(sessionInfo)
    eegTraceDirPath = [SdLocalPcDef.ANALYSIS_DIR filesep ...
        DirPathsFromBaseDir.EEG_ANALYSIS_DIR_NAME filesep ...
        DirPathsFromBaseDir.TRACES_DIR_NAME  filesep ...
        getSessionDirName(sessionInfo) ];
end