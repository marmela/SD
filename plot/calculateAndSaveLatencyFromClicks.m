function calculateAndSaveLatencyFromClicks(allSessions)

params.baselineTimeMs = [-500,0];
params.onsetTimeMs = [0,50];
params.sustainedTimeMs = [130,530]; 
params.offsetTimeMs = [550,650]; 
params.smooth.sigmaMs = 2;
params.stats.on = true;
params.stats.nReps = 1000;
params.noise.nMedianAbsDevToExcludeTrials = 5;

alphaStatLatency = 0.001;
binSizeMs = 5;
gaussWinSizeMs = 1.5;

firstSpikeBinSizeMs = 1;
alphaStatFirstSpikeLatency = 0.01;
minConescutiveSignficantBins = 3;

epochsDir = 'E:\SD\Temp Analysis\Epochs';
figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'MethodsFig'];
nSessions = length(allSessions);

all.pOnsetMax = [];
all.diffFromBaselinePeakLatency = [];
all.diffFromBaselinePeakP = [];
all.diffFromBaselineFirstSpikeLatency = [];
all.diffFromBaselineFirstSpikeP = [];
all.peakLatencyMs = [];
all.diffFromBaselineLatency = [];
all.diffFromBaselineP = [];
all.sessionPerUnit = [];
all.channelPerUnit = [];
all.clusPerUnit = [];

wake.pOnsetMax = [];
wake.diffFromBaselinePeakLatency = [];
wake.diffFromBaselinePeakP = [];
wake.diffFromBaselineFirstSpikeLatency = [];
wake.diffFromBaselineFirstSpikeP = [];
wake.peakLatencyMs = [];
wake.diffFromBaselineLatency = [];
wake.diffFromBaselineP = [];
wake.sessionPerUnit = [];
wake.channelPerUnit = [];
wake.clusPerUnit = [];


nrem.pOnsetMax = [];
nrem.diffFromBaselinePeakLatency = [];
nrem.diffFromBaselinePeakP = [];
nrem.diffFromBaselineFirstSpikeLatency = [];
nrem.diffFromBaselineFirstSpikeP = [];
nrem.peakLatencyMs = [];
nrem.diffFromBaselineLatency = [];
nrem.diffFromBaselineP = [];
nrem.sessionPerUnit = [];
nrem.channelPerUnit = [];
nrem.clusPerUnit = [];


for iSess = nSessions:-1:1
    sessInfo = allSessions{iSess};
    
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    
    stateData = load([epochsDir filesep getEpochsFileName(sessInfo)]);
    
    [iQw,iNrem, iRem] = getRecoveryPeriodEpochs(stateData.statePerStimValidTrials,...
        stateData.sleepStateToScoreValue);
    
    nStims = length(iQw);
    
    nSdPressurePeriods = 3;
    nTimePeriods = 1;
    iSdPerStimAndSdPressure = getSdPeriodEpochs(...
        stateData.statePerStimValidTrials,stateData.sleepStateToScoreValue,nSdPressurePeriods,nTimePeriods);
    
    for ch = channels %parfor ch = channels
        tic
        filePath = [epochsDir filesep getEpochsFileName(sessInfo,ch) '.mat'];
        if ~exist(filePath,'file')
            continue;
        end
        epochsData = load(filePath);
        if ~isfield(epochsData.spikes,'rasterPerStimAndClus')
            continue;
        end
        
        timesMs = -epochsData.preStimStartTimeInSec*1000+epochsData.spikes.binSizeMs/2:...
            epochsData.spikes.binSizeMs:epochsData.postStimStartTimeInSec*1000;
        iOnsetTime = find(timesMs>=0 & timesMs<100);
        isBaseline = timesMs<0 & timesMs>=-200;
        timesMsOnset = timesMs(iOnsetTime);
        %%
        nClus = size(epochsData.spikes.rasterPerStimAndClus,2);
        for iClus = 1:nClus
            %% All-States
            rasterAllStim = [];
            for iStim = 1:nStims
                nSdPeriods = size(iSdPerStimAndSdPressure,2);
                iTrials = [iQw{iStim}; iRem{iStim}; iNrem{iStim}];
                for iSdPeriod = 1:nSdPeriods
                    iTrials = [iTrials; iSdPerStimAndSdPressure{iStim,iSdPeriod}];
                end
                currentStimRaster = epochsData.spikes.rasterPerStimAndClus{iStim,iClus}(iTrials,:);
                rasterAllStim = [rasterAllStim; currentStimRaster];
            end
            [all.diffFromBaselinePeakLatency(end+1),all.diffFromBaselinePeakP(end+1),~] = calcPeakLatency(rasterAllStim, timesMs, gaussWinSizeMs, ...
                    params.baselineTimeMs,params.onsetTimeMs, alphaStatLatency);
                
             [all.diffFromBaselineFirstSpikeLatency(end+1),all.diffFromBaselineFirstSpikeP(end+1),~] = ...
                calcDiffFromBaselineFirstSpikeLatency(rasterAllStim,timesMs,firstSpikeBinSizeMs,...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatFirstSpikeLatency, minConescutiveSignficantBins);   
                
            [all.diffFromBaselineLatency(end+1),all.diffFromBaselineP(end+1),~] = ...
                calcDiffFromBaselineLatency(rasterAllStim,timesMs,binSizeMs,...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatLatency);

            all.sessionPerUnit(end+1) = iSess;
            all.channelPerUnit(end+1) = ch;
            all.clusPerUnit(end+1) = iClus;

            %% Wake
            rasterAllStim = [];
            for iStim = 1:nStims
                nSdPeriods = size(iSdPerStimAndSdPressure,2);
                iTrials = iQw{iStim};
                for iSdPeriod = 1:nSdPeriods
                    iTrials = [iTrials; iSdPerStimAndSdPressure{iStim,iSdPeriod}];
                end
                currentStimRaster = epochsData.spikes.rasterPerStimAndClus{iStim,iClus}(iTrials,:);
                rasterAllStim = [rasterAllStim; currentStimRaster];
            end
            [wake.diffFromBaselinePeakLatency(end+1),wake.diffFromBaselinePeakP(end+1),~] = ...
                calcPeakLatency(rasterAllStim, timesMs, gaussWinSizeMs, ...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatLatency);
            [wake.diffFromBaselineFirstSpikeLatency(end+1),wake.diffFromBaselineFirstSpikeP(end+1),~] = ...
                calcDiffFromBaselineFirstSpikeLatency(rasterAllStim,timesMs,firstSpikeBinSizeMs,...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatFirstSpikeLatency, minConescutiveSignficantBins);
            [wake.diffFromBaselineLatency(end+1),wake.diffFromBaselineP(end+1),pBerBin] = ...
                calcDiffFromBaselineLatency(rasterAllStim,timesMs,binSizeMs,...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatLatency);

            wake.sessionPerUnit(end+1) = iSess;
            wake.channelPerUnit(end+1) = ch;
            wake.clusPerUnit(end+1) = iClus;
            
            
            %% NREM
            rasterAllStim = [];
            for iStim = 1:nStims
                nSdPeriods = size(iSdPerStimAndSdPressure,2);
                iTrials = iNrem{iStim};
                currentStimRaster = epochsData.spikes.rasterPerStimAndClus{iStim,iClus}(iTrials,:);
                rasterAllStim = [rasterAllStim; currentStimRaster];
            end
            [nrem.diffFromBaselinePeakLatency(end+1),nrem.diffFromBaselinePeakP(end+1),~] = ...
                calcPeakLatency(rasterAllStim, timesMs, gaussWinSizeMs, ...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatLatency);
            [nrem.diffFromBaselineFirstSpikeLatency(end+1),nrem.diffFromBaselineFirstSpikeP(end+1),~] = ...
                calcDiffFromBaselineFirstSpikeLatency(rasterAllStim,timesMs,firstSpikeBinSizeMs,...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatFirstSpikeLatency, minConescutiveSignficantBins);
            [nrem.diffFromBaselineLatency(end+1),nrem.diffFromBaselineP(end+1),pBerBin] = ...
                calcDiffFromBaselineLatency(rasterAllStim,timesMs,binSizeMs,...
                params.baselineTimeMs,params.onsetTimeMs, alphaStatLatency);
            
            nrem.sessionPerUnit(end+1) = iSess;
            nrem.channelPerUnit(end+1) = ch;
            nrem.clusPerUnit(end+1) = iClus;
        end
    end
end

%%
fontSize = 14;
barFaceColor = [0.6,0.6,0.6];
edgeColor = [0,0,0];

figPosition = [10,50,500,500];
makeDirIfNeeded(figDir)
isSigOriginal = wake.diffFromBaselineP<alphaStatLatency & nrem.diffFromBaselineP<alphaStatLatency;	
isSigFirstSpike = wake.diffFromBaselineFirstSpikeP<alphaStatFirstSpikeLatency & ...
    nrem.diffFromBaselineFirstSpikeP<alphaStatFirstSpikeLatency & ...
    all.diffFromBaselineFirstSpikeP<alphaStatFirstSpikeLatency;	
isSigPeak = wake.diffFromBaselinePeakP<alphaStatLatency ...
    & nrem.diffFromBaselinePeakP<alphaStatLatency ...
    & all.diffFromBaselinePeakP<alphaStatLatency;	
isSigPeakAndFirstSpike = isSigPeak & isSigFirstSpike;

%% Revision - Peak Latency Figure
barLineWidth = 1; 
meanLatency = mean(all.diffFromBaselinePeakLatency(isSigPeak));
medianLatency = median(all.diffFromBaselinePeakLatency(isSigPeak));
[corrWithOriginal.rho, corrWithOriginal.p] = corr(...
    all.diffFromBaselinePeakLatency(isSigPeak & isSigOriginal)',...
    all.diffFromBaselineLatency(isSigPeak & isSigOriginal)');

histogramEdges = params.onsetTimeMs(1):1:params.onsetTimeMs(2);
[nUnitsPerBin,~] = histcounts(all.diffFromBaselinePeakLatency(isSigPeak),histogramEdges);
percentPerBin = nUnitsPerBin./sum(nUnitsPerBin)*100;
binsCenter = (histogramEdges(1:end-1)+histogramEdges(2:end))./2;
hFig = figure('Position',figPosition);
hold on;
bar(binsCenter,percentPerBin,'FaceColor',barFaceColor,'EdgeColor',edgeColor,'LineWidth',barLineWidth);
ylimCurr = ylim();
plot(repmat(medianLatency,1,2),ylimCurr,'--r','LineWidth',barLineWidth)
xlim([histogramEdges(1),histogramEdges(end)]);
xlabel('Latency (ms)');
ylabel('% units');
set(gca,'FontSize',fontSize)

figPath = [figDir filesep 'LatencyAllUnitsClicksPeak'];
savefig(figPath);
hgexport(gcf,figPath ,hgexport('factorystyle'), 'Format', 'png');
hgexport(gcf,figPath ,hgexport('factorystyle'), 'Format', 'eps');
close(hFig)

statsPath = [figPath '_stats'];
save(statsPath,'percentPerBin','histogramEdges','nrem','wake','all',...
    'meanLatency','medianLatency','corrWithOriginal');

%%

statsPath = [figPath '_stats'];
save(statsPath,'percentPerBin','histogramEdges','nrem','wake','all');

