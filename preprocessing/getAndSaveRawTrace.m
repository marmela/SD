function [data,srData] = getAndSaveRawTrace(tankStr,block,rawLfpStreamStr,channel,rawFilePath)

MAX_HOURS_TO_LOAD_FROM_TDT = 1;

dataInfo = TDT2mat(tankStr,['Block-',num2str(block)], 'TYPE',5, 'T1',0,'T2',1,'VERBOSE', false); % Read scalars (5), from start to first second (1). Just to get also the by product - "rcording info"

SECONDS_IN_AN_HOUR = 60*60;
MAX_SECONDS_TO_LOAD = round(MAX_HOURS_TO_LOAD_FROM_TDT*SECONDS_IN_AN_HOUR);
N_SECONDS_IN_A_DAY = 24*SECONDS_IN_AN_HOUR;
durationSecs = round(N_SECONDS_IN_A_DAY*mod(datenum(dataInfo.info.duration),1));
durationHours = durationSecs/SECONDS_IN_AN_HOUR;
timeT1 = 0; 
ic = 1; 
totalSize = 0;

data_cell = cell(1, ceil(durationSecs/MAX_SECONDS_TO_LOAD));
% Get all parts of data, except last one
while durationSecs > MAX_SECONDS_TO_LOAD
    disp(['@@@ Get part ', num2str(ic),' out of ', num2str(length(data_cell))]);
    timeT2 = timeT1 + MAX_SECONDS_TO_LOAD;
    data_struct = TDT2mat(tankStr,['Block-',num2str(block)], 'TYPE',[2 4],...
        'STORE', rawLfpStreamStr ,'CHANNEL',channel,'T1',timeT1,'T2',timeT2, 'VERBOSE', false);
    data_cell{ic} = data_struct.streams.(rawLfpStreamStr).data(1:end-1);
    timeT1 = timeT1 + MAX_SECONDS_TO_LOAD;
    durationSecs = durationSecs - MAX_SECONDS_TO_LOAD;
    totalSize = totalSize + length(data_cell{ic});
    ic = ic + 1; 
end

% Get last part of data
disp(['@@@ Get part ', num2str(ic),' (last) out of ', num2str(length(data_cell))]);
data_struct = TDT2mat(tankStr,['Block-',num2str(block)], 'TYPE',[2 4],...
        'STORE', rawLfpStreamStr ,'CHANNEL',channel, 'T1',timeT1,'T2', ...
        timeT1 + durationSecs-1,'VERBOSE', false);
data_cell{ic} = data_struct.streams.(rawLfpStreamStr).data;              
totalSize = totalSize + length(data_cell{ic});

% Unite all parts of data
data = nan(1,totalSize,'single');  
st = 1;
for ic = 1:length(data_cell)
    disp(['@@@ !!UNITE!! part ', num2str(ic),' out of ', num2str(length(data_cell))]);
    en = st + length(data_cell{ic})-1;
    row = 1; if size(data_cell{ic},1) > 1, [~,row] = max(sum(abs(data_cell{ic}(:,2:4)),2)); end % Sometimes get extra garbege (zeros/nans) rows before/after the correct row - fix it
    data(st:en) = data_cell{ic}(row,:);
    st = st + length(data_cell{ic});    
    data_cell{ic} = [];
end

% normalize data to mean
data = data - mean(data);

% Save as Single/Double and other kinds of data
data = single(data);

srData = data_struct.streams.(rawLfpStreamStr).fs;

if(exist('rawFilePath','var') && ~isempty(rawFilePath))
    disp('@@@ Save process');
    save(rawFilePath,'data','srData','-v7.3');
end

end