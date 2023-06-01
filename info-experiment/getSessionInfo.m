function sessionInfoStruct = getSessionInfo(varargin)
%% ExpInfo.SESSION - x or [x1,x2,x3] - select sessions with num. x1 or any of x1,x2,x3
%% ExpInfo.ANIMAL - 'name1' or {'name1'} - select just sessions of animal 'name1'
%   {'name1','name2'} - select just sessions of animal 'name1' or 'name2'
%% ExpInfo.DATE - 'dd/mm/yyyy' for specific date or {'dd/mm/yyyy','dd/mm/yyyy'} 
%   for a range of of dates (first date to second date including)
%% ExpInfo.START_TIME - [rangeStartTimeHours,rangeEndTimeHours] - 
%       select sessions starting in time range
%% ExpInfo.END_TIME - [rangeStartTimeHours,rangeEndTimeHours] - 
%       select sessions ending in time range
%% ExpInfo.AUDITORY_PARADIGM - 'name1' or {'name1'} - select just sessions of auditory paradigm 'name1'
%   {'name1','name2'} - select just sessions of auditory paradigm 'name1' or 'name2'
%% ExpInfo.BEHAVIORAL_STATES - 'Awake' - select sessions with 'Awake' state
%       {'Awake'} - select sessions with 'Awake' state
%       {'Awake','SD'} - select sessions with both 'Awake' *and* 'SD' state
%       {'Awake/SD'} - select sessions with 'Awake' *or* 'SD' state
%       {'Awake/Sleep','SD'} - select sessions with (('Awake' *or* 'Sleep') *and* 'SD') states
%% ExpInfo.MICROWIRES_LOCATION - 'A1' - select sessions with 'A1' location
%       {'A1'} - select sessions with 'Awake' location
%       {'A1','PR'} - select sessions with both 'A1' *and* 'PR' locations
%       {'A1/PR'} - select sessions with either 'A1' *or* 'PR' locations
%       {'A1/PR','FPC'} - select sessions with (('A1' *or* 'PR') *and* 'FPC') locations
%% ExpInfo.TDT_TANK - 'TankName1' / {'TankName1'} for just sessions with 'TankName1' tank name
%       {'TankName1','TankName2'} for sessions with either names
%% ExpInfo.TDT_TANK_BLOCK - 'TankName1 #x #y #z' or {'TankName1 #x #y #z'} - ...
%       selects for sessions with TankName1 tank name and block x/y/z
%       {'TankName1 #x-y #z', 'TankName2 #w #y #q'} - select sessions with
%       tank name TankName1 and block x to y and z or sessions with tank name
%       'TankName2' and block w/y/q
%% ExpInfo.ANIMAL_AND_SESSION - 'AnimalName1 #x #y #z' or {'AnimalName1 #x #y #z'} - ...
%       {'TankName1 #x #y-z', 'TankName2 #w #y #q'} - Animal, and animal
%       sessions numbers. Accepts same syntax as ExpInfo.TDT_TANK_BLOCK

[~,~,raw] = xlsread(SdLocalPcDef.SESSIONS_INFO_EXCEL_PATH);

nCols = size(raw,2);
nRows = size(raw,1);
%% find Experiment column
col = 1;
while col<=nCols && ~strcmp(raw(1,col),ExpInfo.SESSION)
    col = col+1;
end
assert(strcmp(raw(1,col),ExpInfo.SESSION),...
    'Experiment column was not found in info file'); %make sure column was found
sessionColumn = col;


%% find last valid row
lastValidRow = nRows;
for row = 2:nRows
    if (isnan(raw{row, sessionColumn}))
        lastValidRow = row-1;
        break;
    end
end
nValidRows = lastValidRow-1;
validRows = 2:lastValidRow;
assert(nValidRows>=1,'No valid data found in info file');

%%
nArgs = length(varargin);
assert(mod(nArgs,2)==0, 'Num of args must be even');
nArgsPairs = floor(nArgs/2);
expInfoTypePerPair = cell(nArgsPairs,1);
expInfoDataPerPair = cell(nArgsPairs,1);

for argPairInd = 1:nArgsPairs
    expInfoTypePerPair{argPairInd} = varargin{argPairInd*2-1};
    expInfoDataPerPair{argPairInd} = varargin{argPairInd*2};
end
isSelectedExperiment = true(nValidRows,1);
assert(length(unique(expInfoTypePerPair)) == nArgsPairs);


%% get all the columns
for col=1:nCols
    columnHeader = raw{1,col};
    switch columnHeader
        case ExpInfo.SESSION
            se.session = raw(2:lastValidRow,col);
            sessionNumMat = cell2mat(se.session);
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.SESSION),1,'first');
            if (~isempty(argPairInd))
                isSelectedExperiment = isSelectedExperiment & ismember(sessionNumMat,...
                    expInfoDataPerPair{argPairInd});
            end
        case ExpInfo.ANIMAL
            se.animal = raw(2:lastValidRow,col);
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.ANIMAL),1,'first');
            if (~isempty(argPairInd))
                isSelectedExperiment = isSelectedExperiment & ismember(se.animal,...
                    expInfoDataPerPair{argPairInd});
            end
        case ExpInfo.ANIMAL_SESSION
            se.animalSession = raw(2:lastValidRow,col);
 
        case ExpInfo.DATE
            rawDatesStr = raw(2:lastValidRow,col);
            dateNums = datenum(rawDatesStr,'dd/mm/yyyy');
            se.date= cellfun(@datestr,num2cell(dateNums),'UniformOutput',false);
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.DATE),1,'first');
            if (~isempty(argPairInd))
                nCellsInData = length(expInfoDataPerPair{argPairInd});
                assert(nCellsInData==1 || nCellsInData==2);
                if (nCellsInData==1)
                    isSelectedExperiment = isSelectedExperiment & ...
                        ismember(dateNums,datenum(expInfoDataPerPair{argPairInd},'dd/mm/yyyy'));
                elseif (nCellsInData==2)
                    isSelectedExperiment = isSelectedExperiment & ...
                        dateNums>=datenum(expInfoDataPerPair{argPairInd}{1},'dd/mm/yyyy') & ...
                        dateNums<=datenum(expInfoDataPerPair{argPairInd}{2},'dd/mm/yyyy');
                end
            end
        case ExpInfo.START_TIME
            isNumberValue = false(nValidRows,1);
            for rowInd = 1:nValidRows
                currentRow = validRows(rowInd);
                if isnumeric(raw{currentRow,col})
                    isNumberValue(rowInd) = true;
                end
            end
            timeAsDayFraction = cell2mat(raw(validRows(isNumberValue),col));  
            HOURS_IN_A_DAY = 24;
            startTimeHours = nan(nValidRows,1);
            startTimeHours(isNumberValue) = timeAsDayFraction*HOURS_IN_A_DAY;
            
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.START_TIME),1,'first');
            if (~isempty(argPairInd))
                isSelectedExperiment = isSelectedExperiment & ...
                    startTimeHours>=expInfoDataPerPair{argPairInd}(1) & ...
                    startTimeHours<=expInfoDataPerPair{argPairInd}(2);
            end
            se.startTimeHours = num2cell(startTimeHours);
        case ExpInfo.END_TIME
            isNumberValue = false(nValidRows,1);
            for rowInd = 1:nValidRows
                currentRow = validRows(rowInd);
                if isnumeric(raw{currentRow,col})
                    isNumberValue(rowInd) = true;
                end
            end
            timeAsDayFraction = cell2mat(raw(validRows(isNumberValue),col));  
            HOURS_IN_A_DAY = 24;
            endTimeHours = nan(nValidRows,1);
            endTimeHours(isNumberValue) = timeAsDayFraction*HOURS_IN_A_DAY;
            
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.END_TIME),1,'first');
            if (~isempty(argPairInd))
                isSelectedExperiment = isSelectedExperiment & ...
                    endTimeHours>=expInfoDataPerPair{argPairInd}(1) & ...
                    endTimeHours<=expInfoDataPerPair{argPairInd}(2);
            end
            se.endTimeHours = num2cell(endTimeHours);
        case ExpInfo.AUDITORY_PARADIGM
            se.auditoryParadigm = raw(2:lastValidRow,col);
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.AUDITORY_PARADIGM),1,'first');
            if (~isempty(argPairInd))
                isSelectedExperiment = isSelectedExperiment & ...
                    ismember(se.auditoryParadigm,expInfoDataPerPair{argPairInd});
            end
            
            
        case ExpInfo.BEHAVIORAL_STATES
            rowNum = 1;
            se.sessionStates = cell(nValidRows,1);
            for row = 2:lastValidRow
                temp = raw{row,col};
                statesStrForCurrentRow = strsplit(temp,',');
                nStates = length(statesStrForCurrentRow);
                allStates = cell(1,nStates);
                for stateInd = 1:nStates
                    currentState = strtrim(statesStrForCurrentRow{stateInd});
                    switch currentState
                        case ExpInfo.STATE_AWAKE
                            allStates{stateInd} = ExpInfo.STATE_AWAKE;
                        case ExpInfo.STATE_SD
                            allStates{stateInd} = ExpInfo.STATE_SD;
                        case ExpInfo.STATE_SLEEP
                            allStates{stateInd} = ExpInfo.STATE_SLEEP;
                        case ExpInfo.STATE_ANESTHESIA
                            allStates{stateInd} = ExpInfo.STATE_SLEEP;    
                        otherwise
                            error('Unknown session state');
                    end
                end
                se.sessionStates{rowNum} = allStates;
                rowNum = rowNum+1;
            end
            
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.BEHAVIORAL_STATES),1,'first');
            if (~isempty(argPairInd))
                isValueSelected = false(nValidRows,1);
                for rowInd = 1:nValidRows
                    isValueSelected(rowInd) = isStringsCombinationInCellArray(...
                        se.sessionStates{rowInd},expInfoDataPerPair{argPairInd});

                end
                isSelectedExperiment = isSelectedExperiment & isValueSelected;
            end

            
        case ExpInfo.MICROWIRES_LOCATION
            rowNum = 1;
            for row = 2:lastValidRow
                temp = raw{row,col};
                locsStrForCurrentRow = strsplit(temp,',');
                nLocs = length(locsStrForCurrentRow);
                allLocs = cell(1,nLocs);
                allLocsChannels = cell(1,nLocs);
                for locInd = 1:nLocs
                    currentLocStr = locsStrForCurrentRow{locInd};
                    
                    [~,tokens] = regexp(currentLocStr, ...
                        '\s*([\w\d]+)\s*\(\s*(\d+)\s*-\s*(\d+)\s*\)\s*','match','tokens');
                    loc = tokens{1}{1};
                    firstChannel = str2num(tokens{1}{2});
                    lastChannel = str2num(tokens{1}{3});
                    switch loc
                        case ExpInfo.LOC_PERI_RHINAL_CORTEX
                            allLocs{locInd} = ExpInfo.LOC_PERI_RHINAL_CORTEX;
                        case ExpInfo.LOC_A1
                            allLocs{locInd} = ExpInfo.LOC_A1;
                        otherwise
                            error('Unknown session state');
                    end
                    allLocsChannels{locInd} = firstChannel:lastChannel;
                end
                se.electrodes{rowNum,1}.locations = allLocs;
                se.electrodes{rowNum,1}.channelsPerLocation = allLocsChannels;
                rowNum = rowNum+1;
            end
            
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.MICROWIRES_LOCATION),1,'first');
            if (~isempty(argPairInd))
                isValueSelected = false(nValidRows,1);
                for rowInd = 1:nValidRows
                    isValueSelected(rowInd) = isStringsCombinationInCellArray(...
                        se.electrodes{rowInd,1}.locations,expInfoDataPerPair{argPairInd});
                    
                end
                isSelectedExperiment = isSelectedExperiment & isValueSelected;
            end
            
        case ExpInfo.GOOD_UNITS_CHANNELS
            se.goodUnitsChannels = cell(nValidRows,1);
            rowNum = 1;
            for row = 2:lastValidRow
                temp = raw{row,col};
                if isnan(temp) %if is empty place in table
                    rowNum = rowNum+1;
                    continue;
                elseif isnumeric(temp)
                    se.goodUnitsChannels{rowNum} = temp;
                    rowNum = rowNum+1;
                    continue;
                end
                channelsStrForCurrentRow = strsplit(temp,',');
                nChannelsForExperiment = length(channelsStrForCurrentRow);
                if nChannelsForExperiment>0
                    se.goodUnitsChannels{rowNum} = nan(1,nChannelsForExperiment);
                    for chInd = 1:nChannelsForExperiment
                        se.goodUnitsChannels{rowNum}(chInd) = str2double(channelsStrForCurrentRow(chInd));
                    end
                end
                
                rowNum = rowNum+1;
            end
        case ExpInfo.BAD_CHANNELS
            se.badChannels = cell(nValidRows,1);
            rowNum = 1;
            for row = 2:lastValidRow
                temp = raw{row,col};
                if isnan(temp) %if is empty place in table
                    rowNum = rowNum+1;
                    continue;
                elseif isnumeric(temp)
                    se.badChannels{rowNum} = temp;
                    rowNum = rowNum+1;
                    continue;
                end
                channelsStrForCurrentRow = strsplit(temp,',');
                nChannelsForExperiment = length(channelsStrForCurrentRow);
                if nChannelsForExperiment>0
                    se.badChannels{rowNum} = nan(1,nChannelsForExperiment);
                    for chInd = 1:nChannelsForExperiment
                        se.badChannels{rowNum}(chInd) = str2double(channelsStrForCurrentRow(chInd));
                    end
                end
                
                rowNum = rowNum+1;
            end
        case ExpInfo.TDT_TANK
            se.tdtTank = raw(2:lastValidRow,col);
            argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.TDT_TANK),1,'first');
            if (~isempty(argPairInd))
                isSelectedExperiment = isSelectedExperiment & ismember(se.tdtTank,...
                    expInfoDataPerPair{argPairInd});
            end
        case ExpInfo.TDT_BLOCK
            se.tdtBlock = raw(2:lastValidRow,col);
        case ExpInfo.PARADIGM_DIR
            se.paradigmDir = raw(2:lastValidRow,col);
        case ExpInfo.PARADIGM_INFO_FILE
            se.paradigmInfoFile = raw(2:lastValidRow,col);
        case ExpInfo.COMMENTS
            se.comments = cell(nValidRows,1);
            rowNum = 1;
            for row = 2:lastValidRow
                temp = raw{row,col};
                if isnan(temp)
                    se.comments{rowNum} = '';
                else
                    se.comments{rowNum} = temp;
                end
                rowNum = rowNum + 1;
            end
        case ExpInfo.BEHAVIORAL_EPOCHS
            se.behavioralEpochs = cell(nValidRows,1);
            1;
            rowNum = 1;
            for row = 2:lastValidRow
                temp = raw{row,col};
                if isnan(temp)
                    rowNum = rowNum + 1;
                    continue
                end
                behavioralEpochsStrForCurrentRow = strsplit(temp,',');
                nEpochs = length(behavioralEpochsStrForCurrentRow);
                
                for epochInd = nEpochs:-1:1
                    currentEpochStr = behavioralEpochsStrForCurrentRow{epochInd};
                    
                    [~,tokens] = regexp(currentEpochStr, ...
                        '\s*([\w\d]+)\s*\(\s*(\d+\.?\d*)\s*-\s*(\d+\.?\d*|\w+)\s*\)\s*','match','tokens');
                    
                    epochStr = tokens{1}{1};
                    assert(strcmp(epochStr,ExpInfo.STATE_AWAKE) || ...
                        strcmp(epochStr,ExpInfo.STATE_SLEEP) || ...
                        strcmp(epochStr,ExpInfo.STATE_SD) || ...
                        strcmp(epochStr,ExpInfo.STATE_ANESTHESIA) || ...
                        strcmp(epochStr,ExpInfo.STATE_TRANSITION),...
                        sprintf('Unknown behavioral epoch name ''%s'' #%d  (row %d, column %d)',epochStr,epochInd,row,col))
                    endTimeStr = tokens{1}{3};
                    if strcmp(endTimeStr,ExpInfo.END_OF_RECORDING)
                        epochEndTimeSec = Inf;
                    else
                        epochEndTimeSec = str2double(tokens{1}{3});
                    end
                    epochStartTimeSec = str2double(tokens{1}{2});
                    assert(epochStartTimeSec<epochEndTimeSec, ...
                        sprintf('epoch #%d start time must be smaller than its end time ''%s''  (row %d, column %d)',...
                        epochInd,currentEpochStr,row,col))
                    se.behavioralEpochs{rowNum}(epochInd).type = epochStr;
                    se.behavioralEpochs{rowNum}(epochInd).startTimeSec = epochStartTimeSec;
                    se.behavioralEpochs{rowNum}(epochInd).endTimeSec = epochEndTimeSec;
                    switch epochStr
                        case ExpInfo.STATE_AWAKE
                            se.behavioralEpochs{rowNum}(epochInd).color = 'b';
                        case ExpInfo.STATE_ANESTHESIA
                            se.behavioralEpochs{rowNum}(epochInd).color = 'r';
                        case ExpInfo.STATE_SLEEP
                            se.behavioralEpochs{rowNum}(epochInd).color = 'k';
                        case ExpInfo.STATE_SD
                            se.behavioralEpochs{rowNum}(epochInd).color = 'g';
                        case ExpInfo.STATE_TRANSITION
                            se.behavioralEpochs{rowNum}(epochInd).color = [0.7,0.7,0.7];
                    end
                end %end of epochs loop for certain session
                rowNum = rowNum + 1;
            end 
            
        case ExpInfo.EPOCHS_TO_EXCLUDE %time epochs to exclude from analysis (bad data etc.)
            se.epochsToExclude = cell(nValidRows,1);
            1;
            rowNum = 1;
            for row = 2:lastValidRow
                temp = raw{row,col};
                if isnan(temp)
                    rowNum = rowNum + 1;
                    continue
                end
                epochsToExcludeStrForCurrentRow = strsplit(temp,',');
                nEpochs = length(epochsToExcludeStrForCurrentRow);
                
                for epochInd = nEpochs:-1:1
                    currentEpochStr = epochsToExcludeStrForCurrentRow{epochInd};
                    
                    [~,tokens] = regexp(currentEpochStr, ...
                        '\s*(\d+\.?\d*)\s*-\s*(\d+\.?\d*|\w+)\s*','match','tokens');
                    
                    
                    endTimeStr = tokens{1}{2};
                    if strcmp(endTimeStr,ExpInfo.END_OF_RECORDING)
                        epochEndTimeSec = Inf;
                    else
                        epochEndTimeSec = str2double(tokens{1}{2});
                    end
                    epochStartTimeSec = str2double(tokens{1}{1});
                    assert(epochStartTimeSec<epochEndTimeSec, ...
                        sprintf('epoch #%d start time must be smaller than its end time ''%s''  (row %d, column %d)',...
                        epochInd,currentEpochStr,row,col))
                    se.epochsToExclude{rowNum}(epochInd).startTimeSec = epochStartTimeSec;
                    se.epochsToExclude{rowNum}(epochInd).endTimeSec = epochEndTimeSec;
                end %end of epochs loop for certain session
                rowNum = rowNum + 1;
            end 
            1;
    end
    
   
end

argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.TDT_TANK_BLOCK),1,'first');
if (~isempty(argPairInd))
    if (iscell(expInfoDataPerPair{argPairInd}))
        isValueSelected = false(nValidRows,1);
        nCells = length(expInfoDataPerPair{argPairInd});
        for cellInd = 1:nCells
            tdtTankBlockStr = expInfoDataPerPair{argPairInd}{cellInd};
            [tdtTankStr,tdtBlocks] = getStringFollowedByNumbersInFormat(tdtTankBlockStr); %getTdtTankBlock(tdtTankBlockStr);
            isValueSelected = isValueSelected | ...
                ismember(se.tdtTank,tdtTankStr) & ...
                ismember(cell2mat(se.tdtBlock),tdtBlocks);
        end

        
    else
        tdtTankBlockStr = expInfoDataPerPair{argPairInd};
        [tdtTankStr,tdtBlocks] = getStringFollowedByNumbersInFormat(tdtTankBlockStr); %getTdtTankBlock(tdtTankBlockStr);
        isValueSelected = ismember(se.tdtTank,tdtTankStr) & ...
                ismember(cell2mat(se.tdtBlock),tdtBlocks);
    end
    
    isSelectedExperiment = isSelectedExperiment & isValueSelected;
end


argPairInd = find(strcmp(expInfoTypePerPair,ExpInfo.ANIMAL_AND_SESSION),1,'first');
if (~isempty(argPairInd))
    if (iscell(expInfoDataPerPair{argPairInd}))
        isValueSelected = false(nValidRows,1);
        nCells = length(expInfoDataPerPair{argPairInd});
        for cellInd = 1:nCells
            animalAndSessionStr = expInfoDataPerPair{argPairInd}{cellInd};
            [animalStr,numAnimalSessions] = getStringFollowedByNumbersInFormat(animalAndSessionStr); %getTdtTankBlock(tdtTankBlockStr);
            isValueSelected = isValueSelected | ...
                ismember(se.animal,animalStr) & ...
                ismember(cell2mat(se.animalSession),numAnimalSessions);
        end

        
    else
        animalAndSessionStr = expInfoDataPerPair{argPairInd};
        [animalStr,numAnimalSessions] = getStringFollowedByNumbersInFormat(animalAndSessionStr); %getTdtTankBlock(tdtTankBlockStr);
        isValueSelected = ismember(se.animal,animalStr) & ...
                ismember(cell2mat(se.animalSession),numAnimalSessions);
    end
    
    isSelectedExperiment = isSelectedExperiment & isValueSelected;
end



selectedExperimentsIndices = find(isSelectedExperiment);
    allFieldNames = fieldnames(se);
    nFieldNames = length(allFieldNames);
    structInitializationString = [];
    for fieldNameInd = 1:nFieldNames-1
        structInitializationString = [structInitializationString, ...
            sprintf('allFieldNames{%d},se.(allFieldNames{%d})(selectedExperimentsIndices),',fieldNameInd,fieldNameInd)];
    end
    structInitializationString = [structInitializationString, ...
            sprintf('allFieldNames{%d},se.(allFieldNames{%d})(selectedExperimentsIndices)',nFieldNames,nFieldNames)];
    
    eval(['sessionInfoStruct = struct(' structInitializationString ');']);
end