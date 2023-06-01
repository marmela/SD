function dirPath = getWheelAnalysisDirPath(sessionInfo)
    dirPath = [SdLocalPcDef.ANALYSIS_DIR filesep DirPathsFromBaseDir.WHEEL_DIR_NAME ...
        filesep getSessionDirName(sessionInfo)];
end