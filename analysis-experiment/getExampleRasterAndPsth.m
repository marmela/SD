function exampleData = getExampleRasterAndPsth(exampleUnit,statesToPlot)

sigmaMs = 5;
plotTimesMs = [-200,600];

MS_IN_SEC = 1000;
c = strsplit(exampleUnit.session,' - ');
animalStr = c{1};
sessNumStr = c{2};
sessInfo = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, sprintf('%s #%s',animalStr,sessNumStr));

epochsDir = [SdLocalPcDef.TEMP_ANALYSIS_DIR filesep 'Epochs'];
stateData = load([epochsDir filesep getEpochsFileName(sessInfo)]);
[iQw, iNrem, iRem, iAwRecovery, iAwAll] = getRecoveryPeriodEpochs(stateData.statePerStimValidTrials,...
    stateData.sleepStateToScoreValue);

nStims = length(iQw);

nSdPressurePeriods = 3;
nTimePeriods = 1;
iSdPerStimAndSdPressure = getSdPeriodEpochs(...
    stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods);

nSdPressurePeriods = 1;
nTimePeriods = 3;
iSdPerStimAndMomentArousal = squeeze(getSdPeriodEpochs(...
    stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods));

filePath = [epochsDir filesep getEpochsFileName(sessInfo,exampleUnit.ch) '.mat'];

assert(logical(exist(filePath,'file')))
epochsData = load(filePath);
assert(isfield(epochsData.spikes,'rasterPerStimAndClus'))



nClus = size(epochsData.spikes.rasterPerStimAndClus,2);
binSizeMs = epochsData.spikes.binSizeMs;
preStimStartTimeInSec = epochsData.preStimStartTimeInSec;
postStimStartTimeInSec = epochsData.postStimStartTimeInSec;
timeMsAll = -preStimStartTimeInSec*MS_IN_SEC+binSizeMs/2 : binSizeMs : ...
    postStimStartTimeInSec*MS_IN_SEC;

isPlotTime = timeMsAll>=plotTimesMs(1) & timeMsAll<plotTimesMs(2);
timeMsValid = timeMsAll(isPlotTime);
iClus = exampleUnit.clus;
nStatesToPlot = length(statesToPlot);
smoothWin = getGaussWin(sigmaMs./binSizeMs,ceil(sigmaMs./binSizeMs*6)+1);

% make sure that smoothing window is smaller than unused temporal edges of the raster, so
% the values of the convolution will be valid.
assert(length(smoothWin)< find(isPlotTime,1,'first'))
assert(length(smoothWin)< length(isPlotTime)-find(isPlotTime,1,'last'))

rasterPerStimAndState = cell(nStims,nStatesToPlot);
psthPerStimAndState = cell(nStims,nStatesToPlot);

for iStim = 1:nStims
    raster = epochsData.spikes.rasterPerStimAndClus{iStim,iClus};
    
    for iState = 1:nStatesToPlot
        switch statesToPlot(iState).state
            case State.SD1
                currentStimAndStateRaster = raster(iSdPerStimAndSdPressure{iStim,1},:);
            case State.SD2
                currentStimAndStateRaster = raster(iSdPerStimAndSdPressure{iStim,2},:);
            case State.SD3
                currentStimAndStateRaster = raster(iSdPerStimAndSdPressure{iStim,3},:);
            case State.Arousal1
                currentStimAndStateRaster = raster(iSdPerStimAndMomentArousal{iStim,1},:);
            case State.Arousal2
                currentStimAndStateRaster = raster(iSdPerStimAndMomentArousal{iStim,2},:);
            case State.Arousal3
                currentStimAndStateRaster = raster(iSdPerStimAndMomentArousal{iStim,3},:);
            case State.QW
                currentStimAndStateRaster = raster(iQw{iStim},:);
            case State.NREM
                currentStimAndStateRaster = raster(iNrem{iStim},:);
            case State.REM
                currentStimAndStateRaster = raster(iRem{iStim},:);
            case State.AW
                currentStimAndStateRaster = raster(iAwAll{iStim},:);
        end
        
        currentPsth = conv(mean(double(full(currentStimAndStateRaster)))*MS_IN_SEC/binSizeMs,smoothWin,'same');
        psthPerStimAndState{iStim,iState} = currentPsth(:,isPlotTime);
        rasterPerStimAndState{iStim,iState} = currentStimAndStateRaster(:,isPlotTime);
        
    end
end

exampleData.rasterPerStimAndState = rasterPerStimAndState;
exampleData.psthPerStimAndState = psthPerStimAndState;
exampleData.timeMs = timeMsValid;
exampleData.binSizeMs = binSizeMs;