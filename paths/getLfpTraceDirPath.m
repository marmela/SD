function lfpTraceDirPath = getLfpTraceDirPath(animal,animalSession)
    lfpTraceDirPath = [SdLocalPcDef.ANALYSIS_DIR filesep ...
        DirPathsFromBaseDir.LFP_ANALYSIS_DIR_NAME filesep ...
        DirPathsFromBaseDir.TRACES_DIR_NAME  filesep ...
        sprintf('%s - %d',animal,animalSession)];
end