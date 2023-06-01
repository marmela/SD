function [drc,drcStartTimesSec]  = loadDrcParadigmData(sessionInfo,isDrcTuning)
if isDrcTuning
    drcBaseIndex = ParadigmConsts.DRC_TUNING_BASE_ID;
    drcMaxIndex = ParadigmConsts.DRC_TUNING_LAST_POSSIBLE_ID;
    drcDirName = StimDirNames.DRC_TUNING;
else
    drcBaseIndex = ParadigmConsts.DRC_CONTEXT_BASE_ID;
    drcMaxIndex = ParadigmConsts.DRC_CONTEXT_LAST_POSSIBLE_ID;
    drcDirName = StimDirNames.DRC_CONTEXT;
end
stimsDir = getAuditoryStimsAnalysisDirPath(sessionInfo.animal,sessionInfo.animalSession);
stimuliStampsFilePath = [stimsDir,filesep, getTtlStampsFilename()];
stimStamps = load(stimuliStampsFilePath);
stampValues = stimStamps.stampValues;
stampTimesSec = stimStamps.stampTimesSec;
isDrcTtlStamp = stampValues>=drcBaseIndex & stampValues<drcMaxIndex;
allDrcTtlStamps = sort(unique(stampValues(isDrcTtlStamp)))';
nDrcFiles = length(allDrcTtlStamps);
drcStartTimesSec = cell(nDrcFiles,1);
drcDataDirPath = [SdLocalPcDef.AUDITORY_PARADIGMS_DIR filesep sessionInfo.paradigmDir ...
    filesep drcDirName];
for drcFileInd = nDrcFiles:-1:1
    drcStartTimesSec{drcFileInd} = stampTimesSec(stampValues == allDrcTtlStamps(drcFileInd));
    drcStampIndex = allDrcTtlStamps(drcFileInd)-drcBaseIndex;
    drcFilePath = [drcDataDirPath filesep getDrcFileName(drcStampIndex)];
    drc{drcFileInd} = load(drcFilePath);
    
end