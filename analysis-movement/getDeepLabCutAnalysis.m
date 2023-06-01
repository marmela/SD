function dlc = getDeepLabCutAnalysis(sessInfo)
HEADER_INFO_COL = 1;
N_MAX_HEADER_ROWS = 5;
FRAME_NUM_COL = 1;
SHIFTS_FRAME_COL = 1;
SHIFTS_DATETIME_COL = 2;
VIDEO_SR_HZ = 10;
MAX_SHIFT_BETWEEN_ANY_VIDEO_AND_TDT_ONSETS = duration(14,0,0);
MAX_SHIFT_DELAY_SEC = 10;
BODY_PARTS_ROW_STR = 'bodyparts';
COORDS_ROW_STR = 'coords';
likelihoodStr = 'likelihood';
xStr = 'x';
yStr = 'y';

relevantBodyParts = {'EyeRightMedial','EyeRightLateral','EyeLeftMedial','EyeLeftLateral','Snout','HeadCap'};
videoFrameTimingFile = [SdLocalPcDef.ANALYSIS_DIR filesep 'Video' filesep 'VideoOnsets.mat'];
videoFrameTiming = load(videoFrameTimingFile);
deepLabCutDir = [SdLocalPcDef.RAW_DATA_DIR filesep 'DeepLabCut'];
[videoFileNames,~,~] = getVideoFileNamesForSession(sessInfo);
videoFileNames = sort(videoFileNames);
listing = dir(deepLabCutDir);
animalNameParts = strsplit(sessInfo.animal,'_');
dlcDirPrefix = ['A' animalNameParts{end}];
listingNames = extractfield(listing,'name');
isListingDir = cell2mat(extractfield(listing,'isdir'));
iDir = find(startsWith(listingNames,dlcDirPrefix) & isListingDir);
assert(length(iDir)==1);
animalDirName = listingNames{iDir};
csvDir = [deepLabCutDir filesep animalDirName filesep 'videos'];
listingCsv = dir(fullfile(csvDir, '*.csv'));
csvFileFullNames = extractfield(listingCsv,'name')';
isRelevantCsvFile = startsWith(csvFileFullNames,videoFileNames);
relevantCsvFileNames = sort(csvFileFullNames(isRelevantCsvFile));
nVideoFiles = length(videoFileNames);
dataInfo = TDT2mat(sessInfo.tdtTank,['Block-',num2str(sessInfo.tdtBlock)], 'TYPE',5, 'T1',0,'T2',1,'VERBOSE', false);
dateTimeStr = [dataInfo.info.date ' ' dataInfo.info.starttime];
recordingOnsetDateTime = datetime(dateTimeStr, 'InputFormat', 'yyyy-MMM-dd HH:mm:ss');
timePerFrameAllFiles = [];
for iFile = 1:nVideoFiles
    iCsvFile = find(startsWith(relevantCsvFileNames,videoFileNames{iFile}));
    if isempty(iCsvFile); continue; end
    assert(length(iCsvFile)==1);
    csvFileName = relevantCsvFileNames{iCsvFile};
    csvPath = [csvDir filesep csvFileName];
    tempT = readtable(csvPath,'ReadVariableNames',false);
    nRowsTable = size(tempT,1);
    iFirstFrame = find(strcmp(table2cell(tempT(1:N_MAX_HEADER_ROWS,HEADER_INFO_COL)),...
        '0'),1,'first');
    nFrames = nRowsTable-iFirstFrame+1;
    timePerFrameCurrentFile = nan(nFrames,1);
    if ~exist('T','Var')
        T = tempT;
    else
        T = [T; tempT(iFirstFrame:nRowsTable,:)];
    end

    %% load date time
    assert(str2num(tempT{nRowsTable,FRAME_NUM_COL}{1})+1 == nFrames);
    timeShiftsInVideo = videoFrameTiming.fileToOnsetTimeMap(videoFileNames{iFile});
    if isdatetime (timeShiftsInVideo)
        timeShiftsInVideo = {1, timeShiftsInVideo};
    else
        assert(iscell(timeShiftsInVideo));
    end
    nTimeShifts = size(timeShiftsInVideo,1);
    for iTimeShift = 1:nTimeShifts
        iCurrentFrame = timeShiftsInVideo{iTimeShift,SHIFTS_FRAME_COL};
        timeCurrentFrame = timeShiftsInVideo{iTimeShift,SHIFTS_DATETIME_COL};
        timeDiffFromTdtRecStart = timeCurrentFrame-recordingOnsetDateTime;
        assert(timeDiffFromTdtRecStart<MAX_SHIFT_BETWEEN_ANY_VIDEO_AND_TDT_ONSETS);
        currentFrameTimeFromTdtRecOnsetSec = seconds(timeDiffFromTdtRecStart);
        1;
        % ASSERT that shift modification for frames are not too large to assure no mistakes
        % in the manual files
        if ~isnan(timePerFrameCurrentFile(iCurrentFrame))
            assert(abs(currentFrameTimeFromTdtRecOnsetSec-...
                timePerFrameCurrentFile(iCurrentFrame))<MAX_SHIFT_DELAY_SEC)
        end
        timePerFrameCurrentFile(iCurrentFrame:end) = currentFrameTimeFromTdtRecOnsetSec + ...
            (0:(nFrames-iCurrentFrame))./VIDEO_SR_HZ;
    end
    timePerFrameAllFiles = [timePerFrameAllFiles; timePerFrameCurrentFile];
end

%% Extract header info from table
bodyPartsRow = find(strcmp(table2cell(T(1:N_MAX_HEADER_ROWS,HEADER_INFO_COL)),...
    BODY_PARTS_ROW_STR),1,'first');
coordsRow = find(strcmp(table2cell(T(1:N_MAX_HEADER_ROWS,HEADER_INFO_COL)),...
    COORDS_ROW_STR),1,'first');
nRowsTable = size(T,1);
iFirstFrame = find(strcmp(table2cell(T(1:N_MAX_HEADER_ROWS,HEADER_INFO_COL)),...
    '0'),1,'first');
nFrames = nRowsTable-iFirstFrame+1;
iLikelihoodColumns = find(strcmp(table2cell(T(coordsRow,:)), likelihoodStr));
likelihoodTable = array2table(str2double(table2cell(T(iFirstFrame:nRowsTable,iLikelihoodColumns))));
likelihoodTableBodyParts = table2cell(T(bodyPartsRow,iLikelihoodColumns));
likelihoodTable.Properties.VariableNames = likelihoodTableBodyParts;
iXColumns = find(strcmp(table2cell(T(coordsRow,:)), xStr));
xTable = array2table(str2double(table2cell(T(iFirstFrame:nRowsTable,iXColumns))));
xTableBodyParts = table2cell(T(bodyPartsRow,iXColumns));
xTable.Properties.VariableNames = xTableBodyParts;
iYColumns = find(strcmp(table2cell(T(coordsRow,:)), yStr));
yTable = array2table(str2double(table2cell(T(iFirstFrame:nRowsTable,iYColumns))));
yTableBodyParts = table2cell(T(bodyPartsRow,iYColumns));
yTable.Properties.VariableNames = yTableBodyParts;
assert(all(strcmp(yTableBodyParts,xTableBodyParts)) && all(strcmp(likelihoodTableBodyParts,xTableBodyParts)))
clear T

%% Make Tables Short and with relevant bodt parts and likelihood
[~,~,iAllBodyParts] = intersect(relevantBodyParts,yTable.Properties.VariableNames);
nRelevantBodyParts = length(relevantBodyParts);
assert(length(iAllBodyParts) == nRelevantBodyParts);
likelihoodTable = likelihoodTable(:,iAllBodyParts);
xTable = xTable(:,iAllBodyParts);
yTable = yTable(:,iAllBodyParts);
dlc.timeSec = timePerFrameAllFiles;
dlc.xTable = xTable;
dlc.yTable = yTable;
dlc.likelihoodTable = likelihoodTable;
dlc.sr = VIDEO_SR_HZ;
