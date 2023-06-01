function plotPostOnsetFigForManuscript(statesData, isValidUnit, minUnitsPerAnimal, ...
    minUnitsPerSess, exampleUnit)

%% Various Figure Properties

figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'OffStatesFig'];
makeDirIfNeeded(figDir);
figName = 'OffStatesFig';

IS_PLOT_50MS_INSTEAD_GAMMA_FIT = true;
figPositions = [10,50,1400,600];

figProperties.psthLineWidth = 1.5; %PSTH_LINE_WIDTH
figProperties.xTickPsthMs = [0,500]; %XTICK_PSTH_MS
figProperties.timeMsLimits = [-200,600]; %timeMsLimits
figProperties.fontSize = 12; %FONT_SIZE
figProperties.stateFontSize = 16; %STATE_FONT_SIZE
figProperties.clicks.color = 'k';
figProperties.clicks.lineWidth = 3;
figProperties.postOnsetColor = [80	40	0]/95; 
figProperties.baselineColor = [0.4,0.4,0.4];

pIsiToDefineOffState = 0.99;
clicks.rateHz = [2,10,20,30,40];
clicks.lengthMs = 500;
postOnsetTimesMs = [30,80];
shadingProperties = [];
barsProperties.markerPixels = 3.5;
barsProperties.markerPixelsSess = 10; 
barsProperties.xJitterRange = 0.95;
barsProperties.sizeRatioState = 1.45;
barsProperties.nReps = 10000; 

%% Panels Positions
FONT_SIZE_LETTER = 26;
panelLetterXShift = -0.03;
panelLetterYShift = 0.025;
TOTAL_HEIGHT = 0.84;
PSTH_HEIGHT = 0.24;
RASTER_HEIGHT = TOTAL_HEIGHT-PSTH_HEIGHT;
STIM_CLICKS_HEIGHT = 0.025;
X_PANEL_CLICKS_EX = 0.055;
Y_PANEL = 0.1;
WIDTH_PANEL_CLICKS_EX = 0.25;
INTER_PANEL_WIDTH = 0.05;
INTER_PROB_PANEL_WIDTH = 0.015;
WIDTH_PANEL_BARS = 0.2;
STIM_CLICKS_SPACING_FROM_RASTER = 0.002;

%% Set Positions Per Subplot
Y_RASTER = Y_PANEL+PSTH_HEIGHT;
Y_STIM_CLICKS = Y_RASTER+RASTER_HEIGHT+STIM_CLICKS_SPACING_FROM_RASTER;
positionsExample.psth = [X_PANEL_CLICKS_EX, Y_PANEL, WIDTH_PANEL_CLICKS_EX, PSTH_HEIGHT];
positionsExample.raster = [X_PANEL_CLICKS_EX, Y_RASTER, WIDTH_PANEL_CLICKS_EX, RASTER_HEIGHT];
positionsExample.stimClicks = [X_PANEL_CLICKS_EX,Y_STIM_CLICKS,WIDTH_PANEL_CLICKS_EX,STIM_CLICKS_HEIGHT]; 
xProbBarsPanel = X_PANEL_CLICKS_EX + WIDTH_PANEL_CLICKS_EX + INTER_PANEL_WIDTH;
for iPanel = 2:-1:1
    xCurrentPanel = xProbBarsPanel+(iPanel-1)*(WIDTH_PANEL_BARS+INTER_PROB_PANEL_WIDTH);
    offStateProbBarsPosition{iPanel} = [xCurrentPanel,Y_PANEL,WIDTH_PANEL_BARS,TOTAL_HEIGHT];
end
xModulationBarsPanel = offStateProbBarsPosition{end}(1)+WIDTH_PANEL_BARS+INTER_PANEL_WIDTH;
offStateModulationBarsPosition = [xModulationBarsPanel,Y_PANEL, WIDTH_PANEL_BARS*2/3,TOTAL_HEIGHT];

%%
sessionStr = extractfield(statesData{1}.sessData,'session');
isContextSess = cell2mat(extractfield(statesData{1}.sessData,'isContext'));
contextSessionsStr = sessionStr(isContextSess);
nStates = length(statesData);
for iState = nStates:-1:1
    statesInfo(iState) = statesData{iState}.info;
end
exampleData = getExampleRasterAndPsth(exampleUnit,statesInfo);
figure('Position',figPositions);
plotExampleRasterOffState(exampleData,statesInfo, positionsExample, figProperties, ...
    shadingProperties, clicks, pIsiToDefineOffState, IS_PLOT_50MS_INSTEAD_GAMMA_FIT, postOnsetTimesMs);

%%
[stats,plotData,iExamplePerUnit] = calcPostOnsetPlotAndStats(statesData, ...
    isValidUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnit);
statsPath = [figDir filesep figName '_stats'];
save(statsPath,'stats');

isPostOnset = false;
plotOffStateProbPerState(plotData, offStateProbBarsPosition{1},  exampleUnit, iExamplePerUnit, ...
    minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, statesInfo, isPostOnset,IS_PLOT_50MS_INSTEAD_GAMMA_FIT)
isPostOnset = true;
plotOffStateProbPerState(plotData, offStateProbBarsPosition{2},  exampleUnit, iExamplePerUnit, ...
    minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, statesInfo, isPostOnset,IS_PLOT_50MS_INSTEAD_GAMMA_FIT)
iStatesToCompare = [1,2]; % Tired-Vigilant
plotOffStateModulationPerState(plotData, offStateModulationBarsPosition,  exampleUnit, iExamplePerUnit, ...
    minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, statesInfo,IS_PLOT_50MS_INSTEAD_GAMMA_FIT,iStatesToCompare)
%% Plot Panels Letters
addPanelsLetters({positionsExample.raster,offStateProbBarsPosition{1},offStateModulationBarsPosition},...
    {'A','B','C'},panelLetterXShift,panelLetterYShift,FONT_SIZE_LETTER)

%%
makeDirIfNeeded(figDir);
figPath = [figDir filesep figName];
hgexport(gcf,figPath ,hgexport('factorystyle'), 'Format', 'png');
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r300')
savefig(figPath);
close(gcf)

%%
function plotOffStateModulationPerState(plotData, subplotPosition,  exampleUnit, iExamplePerUnit, ...
    minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, statesInfo,isPlot50Ms,iStatesToCompare)

if isPlot50Ms
    relevantData = plotData.modulation50MsPerChAndStatePair;
else
    relevantData = plotData.modulationGammaFitPerChAndStatePair;
end
baselineData = relevantData.baseline(:,iStatesToCompare(1),iStatesToCompare(2));
postOnsetData = relevantData.postOnset(:,iStatesToCompare(1),iStatesToCompare(2));
yLims = [min([baselineData; postOnsetData],[],'all'), max([baselineData; postOnsetData],[],'all')];
colorPerMeasure = {figProperties.baselineColor, figProperties.postOnsetColor};
strPerMeasure = {'Spontaneous ',' Induced'};
dataToPlot = [baselineData, postOnsetData];
nMeasures = size(dataToPlot,2);
XLIM = [0.5,nMeasures+0.5];
subplot('position',subplotPosition);
hold on;
xlim(XLIM)
ylim(yLims)

for iMeasure = 1:nMeasures
    colorCurrentState = colorPerMeasure{iMeasure};
    xLocCurrentMeasure = plotBarAndPoints(dataToPlot(:,iMeasure),iMeasure,...
        barsProperties.xJitterRange,barsProperties.nReps,barsProperties.markerPixels,...
        iExamplePerUnit,colorCurrentState);
    plotPointsPerSess(dataToPlot(:,iMeasure),iMeasure,barsProperties.xJitterRange,barsProperties.nReps,...
        barsProperties.markerPixelsSess,plotData.sessionPerChannel,minUnitsPerSess,...
        contextSessionsStr,Consts.MARKER_ANIMAL_MAP) 
    plotExamplePoints(dataToPlot(:,iMeasure),xLocCurrentMeasure,...
       barsProperties. markerPixels,exampleUnit,iExamplePerUnit);
   xTickLabelStates{iMeasure} = ['\bf\it\fontsize{' num2str(figProperties.fontSize) ...
       '}\color[rgb]{' sprintf('%f,%f,%f',colorCurrentState) '}' strPerMeasure{iMeasure}];
end

text(1.5,0.95,['\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' ...
    sprintf('%f,%f,%f',statesInfo(iStatesToCompare(2)).color) '}' statesInfo(iStatesToCompare(2)).str '>' ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) ...
    '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(iStatesToCompare(1)).color) '}' statesInfo(iStatesToCompare(1)).str],'HorizontalAlignment','center');
text(1.5,-0.95,['\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(iStatesToCompare(2)).color) '}' statesInfo(iStatesToCompare(2)).str  ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(iStatesToCompare(1)).color) '}' '<' statesInfo(iStatesToCompare(1)).str],'HorizontalAlignment','center');
set(gca,'XTick',1:nMeasures,'XTickLabel',xTickLabelStates);
set(gca,'YTick',-1:0.1:1)
ylabel('Modulation Index');
set(gca,'FontSize',figProperties.fontSize);
grid on

%%
function plotOffStateProbPerState(plotData, subplotPosition,  exampleUnit, iExamplePerUnit, ...
    minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, statesInfo, isPostOnset,isPlot50Ms)

if isPlot50Ms
    dataBaselineAndPostOnset = plotData.probOffState50MsPerChAndState;
    postOnsetNorm = dataBaselineAndPostOnset.postOnset-dataBaselineAndPostOnset.poisson;
    baselineNorm = dataBaselineAndPostOnset.baseline-dataBaselineAndPostOnset.poisson;
    yLims = [min([postOnsetNorm; baselineNorm],[],'all'), max([postOnsetNorm; baselineNorm],[],'all')];
    if isPostOnset
        dataToPlot = postOnsetNorm;
    else
        dataToPlot = baselineNorm;
    end
else
    dataBaselineAndPostOnset = plotData.probOffStateGammaFitPerChAndState;
    if isPostOnset
        dataToPlot = dataBaselineAndPostOnset.postOnset;
    else
        dataToPlot = dataBaselineAndPostOnset.baseline;
    end
    yLims = [min([dataBaselineAndPostOnset.postOnset; dataBaselineAndPostOnset.baseline],[],'all'),...
        max([dataBaselineAndPostOnset.postOnset; dataBaselineAndPostOnset.baseline],[],'all')];

end

nMeasures = size(dataToPlot,2);
XLIM = [0.5,nMeasures+0.5];
subplot('position',subplotPosition);
hold on;
xlim(XLIM)
ylim(yLims)

for iState = 1:nMeasures
    colorCurrentState = statesInfo(iState).color;
    xLocCurrentMeasure = plotBarAndPoints(dataToPlot(:,iState),iState,...
        barsProperties.xJitterRange,barsProperties.nReps,barsProperties.markerPixels,...
        iExamplePerUnit,colorCurrentState);
    plotPointsPerSess(dataToPlot(:,iState),iState,barsProperties.xJitterRange,barsProperties.nReps,...
        barsProperties.markerPixelsSess,plotData.sessionPerChannel,minUnitsPerSess,...
        contextSessionsStr,Consts.MARKER_ANIMAL_MAP) 
    plotExamplePoints(dataToPlot(:,iState),xLocCurrentMeasure,...
       barsProperties. markerPixels,exampleUnit,iExamplePerUnit);
   xTickLabelStates{iState} = ['\bf\it\fontsize{' num2str(figProperties.stateFontSize) ...
       '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(iState).color) '}' statesInfo(iState).str];
end

set(gca,'XTick',1:nMeasures,'XTickLabel',xTickLabelStates);
set(gca,'YTick',-1:0.1:1)
if isPostOnset
    set(gca,'YTickLabel',{})
    title(['\bf\it\fontsize{' num2str(figProperties.stateFontSize) ...
       '}\color[rgb]{' sprintf('%f,%f,%f',figProperties.postOnsetColor) '}' 'Induced'])
else
    if isPlot50Ms
        ylabel('\DeltaOff-State Probability');
    else
        ylabel('Off-State Probability');
    end
    title(['\bf\it\fontsize{' num2str(figProperties.stateFontSize) ...
       '}\color[rgb]{' sprintf('%f,%f,%f',figProperties.baselineColor) '}' 'Spontaneous'])
end
set(gca,'FontSize',figProperties.fontSize);
grid on
1;

function coloredRaster = colorOffStatesOfRaster(raster, timesMs, pIsiToDefineOffState, ...
    isPlot50Ms,figProperties, postOnsetTimesMs)
SPIKE_COLOR = [0,0,0];
SPIKE_THICKEN_ADDITION = 2;

MS_IN_SEC = 1000;

N_RGB = 3;
isDuringBaseline = timesMs<0;
nTrials = size(raster,1);

if isPlot50Ms
    minIsiOffState = 50;
else
    nIsis = sum(sum(raster(:,isDuringBaseline)))-nTrials;
    allIsis = nan(nIsis,1);
    isiCount = 0;
    for iTrial = 1:nTrials
        currentIsis = diff(find(raster(iTrial,isDuringBaseline)));
        [pCurrentTrial,~] = gamfit(currentIsis);
        minIsiOffStatePerTrial(iTrial) = gaminv(pIsiToDefineOffState,pCurrentTrial(1),pCurrentTrial(2));
    end
end
nTimepoints = size(raster,2);
coloredRaster = ones(nTrials,nTimepoints,N_RGB);

if isPlot50Ms
    iMidPostOnset = find(timesMs>=mean(postOnsetTimesMs),1,'first');
    iMidBaseline = find(timesMs>=-diff(postOnsetTimesMs)/2,1,'first');
    iZeroTime =  find(timesMs>=0,1,'first');
    isPostOnsetTime = timesMs>=postOnsetTimesMs(1) & timesMs<postOnsetTimesMs(2);
    isBaselineTime = timesMs>=-diff(postOnsetTimesMs) & timesMs<0;
    for iTrial = 1:nTrials
        currentTrialSpikes = find(raster(iTrial,:));            
        isis = diff(currentTrialSpikes);
        nIsis = length(isis);
        if ~any(raster(iTrial,isPostOnsetTime))
            iLastSpikeBeforePostOnset = currentTrialSpikes(find(currentTrialSpikes<iMidPostOnset,1,'last'))+1;  
            iFirstSpikeAfterPostOnset = currentTrialSpikes(find(currentTrialSpikes>iMidPostOnset,1,'first'))-1;
            indicesToColor = max(iLastSpikeBeforePostOnset,iZeroTime):min(iFirstSpikeAfterPostOnset,nTimepoints);
            coloredRaster(iTrial,indicesToColor,:) = repmat(figProperties.postOnsetColor,length(indicesToColor),1);
        end
        
         if ~any(raster(iTrial,isBaselineTime))
            iLastSpikeBeforeBaseline = currentTrialSpikes(find(currentTrialSpikes<iMidBaseline,1,'last'))+1;  
            iFirstSpikeAfterBaseline = currentTrialSpikes(find(currentTrialSpikes>iMidBaseline,1,'first'))-1;
            indicesToColor = max(iLastSpikeBeforeBaseline,1):min(iFirstSpikeAfterBaseline,iZeroTime);
            coloredRaster(iTrial,indicesToColor,:) = repmat(figProperties.baselineColor,length(indicesToColor),1);
        end
        for iIsi = 1:nIsis
            spikeIndices = max(currentTrialSpikes(iIsi)-SPIKE_THICKEN_ADDITION,1):...
                min(currentTrialSpikes(iIsi)+SPIKE_THICKEN_ADDITION,nTimepoints);
            coloredRaster(iTrial,spikeIndices,:) = repmat(SPIKE_COLOR,length(spikeIndices),1);
            
        end
        if ~isempty(currentTrialSpikes)
            spikeIndices = max(currentTrialSpikes(end)-SPIKE_THICKEN_ADDITION,1):...
                min(currentTrialSpikes(end)+SPIKE_THICKEN_ADDITION,nTimepoints);
            coloredRaster(iTrial,spikeIndices,:) = repmat(SPIKE_COLOR,length(spikeIndices),1);
        end
        
    end
else
    
    %QWERTY!!!!! Continue here to implement for Gamma fit!!!
    error('Not implemented Yet!');
    for iTrial = 1:nTrials
        currentTrialSpikes = find(raster(iTrial,:));
        isis = diff(currentTrialSpikes);
        nIsis = length(isis);
        for iIsi = 1:nIsis
            if (isis(iIsi)>=minIsiOffState)
                indicesToColor = currentTrialSpikes(iIsi):currentTrialSpikes(iIsi+1);
                coloredRaster(iTrial,indicesToColor,:) = repmat(OFF_STATE_COLOR,length(indicesToColor),1);
            end
            spikeIndices = max(currentTrialSpikes(iIsi)-SPIKE_THICKEN_ADDITION,1):...
                min(currentTrialSpikes(iIsi)+SPIKE_THICKEN_ADDITION,nTimepoints);
            coloredRaster(iTrial,spikeIndices,:) = repmat(SPIKE_COLOR,length(spikeIndices),1);
            
        end
        if ~isempty(currentTrialSpikes)
            spikeIndices = max(currentTrialSpikes(end)-SPIKE_THICKEN_ADDITION,1):...
                min(currentTrialSpikes(end)+SPIKE_THICKEN_ADDITION,nTimepoints);
            coloredRaster(iTrial,spikeIndices,:) = repmat(SPIKE_COLOR,length(spikeIndices),1);
        end
    end
end

1;

function plotExampleRasterOffState(exampleData,statesInfo, positions, figProperties, ...
    shadingProperties, clicks, pIsiToDefineOffState, isPlot50Ms, postOnsetTimesMs)
    iClickRate = 1; 
    %% PSTH Subplot
    subplot('position',positions.psth)
    hold on;
    nStates = length(statesInfo);
    for iState = 1:nStates
        plot(exampleData.timeMs,exampleData.psthPerStimAndState{iClickRate,iState},...
            'color',statesInfo(iState).color,'LineWidth',figProperties.psthLineWidth);
    end
    ylabel('Spikes/s'); %'Firing Rate (spks/s)')
    set(gca,'XTick',figProperties.xTickPsthMs)
    ylimCurr = ylim();
    xlabel('Time (ms)','Position',[mean(figProperties.timeMsLimits) ylimCurr(1)-diff(ylimCurr)*0.02],...
        'VerticalAlignment','top','HorizontalAlignment','center')
    set(gca,'FontSize',figProperties.fontSize)
    xlim(figProperties.timeMsLimits);
    
    yLimToUse = ylimCurr;
    %% shading
    nShadings = length(shadingProperties);
    for iShading = 1:nShadings
        iClickTrainToShade = shadingProperties(iShading).iClickTrains;
        if ~ismember(iClickRate,iClickTrainToShade)
            continue;
        end
        area(shadingProperties(iShading).timesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),...
            'FaceAlpha',shadingProperties(iShading).alpha,'EdgeColor','none',...
            'FaceColor',shadingProperties(iShading).color);
    end
    ylim(yLimToUse);
    
    %% Raster Subplot
    subplot('position',positions.raster)
    timeMsStateText = 350;
    nTotalTrials = 0;
    unitedRaster = [];
    for iState = 1:nStates
        currentRasterPerState{iState} = exampleData.rasterPerStimAndState{iClickRate,iState};
        nTotalTrials = nTotalTrials + size(currentRasterPerState{iState},1);
        coloredOffStatesRaster = colorOffStatesOfRaster(full(currentRasterPerState{iState}),...
            exampleData.timeMs, pIsiToDefineOffState,isPlot50Ms,figProperties,postOnsetTimesMs);
        unitedRaster = [unitedRaster; coloredOffStatesRaster];%currentRasterPerState{iState}];
        borderTrialBetweenStates(iState) = nTotalTrials;
    end
    hRaster = imagesc(exampleData.timeMs, 1:nTotalTrials, unitedRaster);
    colormap(gca,flipud(gray))
            hold on;
    for iState = 1:nStates-1
        plot([floor(exampleData.timeMs(1)),ceil(exampleData.timeMs(end))],repmat(borderTrialBetweenStates(iState)+0.5,1,2),'k');
    end
    trialEdgesOfStates = [0,borderTrialBetweenStates];
    for iState = 1:nStates
        previousStateLine = trialEdgesOfStates(iState);
        nTrialsCurrentState = trialEdgesOfStates(iState+1)-trialEdgesOfStates(iState);
        text(timeMsStateText,previousStateLine+nTrialsCurrentState/2,...
            statesInfo(iState).str,'HorizontalAlignment','center',...
            'Color',statesInfo(iState).color,'FontSize',figProperties.stateFontSize ,...
            'FontWeight','bold','BackgroundColor','w','Margin',1.5,'EdgeColor',...
            statesInfo(iState).color);
    end
    
    yLimToUse = [0,nTotalTrials]+0.5;
    
    %% shading Raster
    nShadings = length(shadingProperties);
    for iShading = 1:nShadings
        iClickTrainToShade = shadingProperties(iShading).iClickTrains;
        if ~ismember(iClickRate,iClickTrainToShade)
            continue;
        end
        area(shadingProperties(iShading).timesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),...
            'FaceAlpha',shadingProperties(iShading).alpha,'EdgeColor','none',...
            'FaceColor',shadingProperties(iShading).color);
    end
    ylim(yLimToUse);
    
    %%
    xlim(figProperties.timeMsLimits)
    ylim(yLimToUse);
    set(gca,'YDir','reverse')
    if nTotalTrials<500
        set(gca,'YTick',(0:100:nTotalTrials)+0.5, 'YTickLabel',(0:100:nTotalTrials))
    else
        set(gca,'YTick',(0:200:nTotalTrials)+0.5, 'YTickLabel',(0:200:nTotalTrials))
    end
    ylabel('Trial');
    set(gca,'XTick',[]);
    set(gca,'FontSize',figProperties.fontSize)
    
    %% Stimulus Clicks above Raster Subplot
    MS_IN_SEC = 1000;
    subplot('position',positions.stimClicks)
    clickTimesMs = 0:MS_IN_SEC/clicks.rateHz(iClickRate):clicks.lengthMs;
    hold on;
    for iClick=1:length(clickTimesMs)
        plot(repmat(clickTimesMs(iClick),1,2),[0,1],'color',figProperties.clicks.color,...
            'LineWidth',figProperties.clicks.lineWidth);
    end
    ylim([0,1])
    xlim(figProperties.timeMsLimits);
    set(gca,'XTick',[],'YTick',[]);
    set(gca,'FontSize',figProperties.fontSize);
    set(gca,'XColor','none')

%%
function [stats,plotData,iExamplePerUnit] = calcPostOnsetPlotAndStats(statesData, ...
    isValidUnit, minUnitsPerAnimal, minChannelsPerSess, exampleChannel)

nStates = length(statesData);
isContextUnit = cell2mat(extractfield(statesData{1}.unitData,'isContext'))';
isValidAndContext = isValidUnit & isContextUnit;
nUnits = sum(isValidAndContext);
sessionPerUnit = extractfield(statesData{1}.unitData,'session');
chPerUnit = extractfield(statesData{1}.unitData,'ch');
sessionPerUnit(~isValidAndContext) = [];
chPerUnit(~isValidAndContext) = [];
sessionPerChannel = extractfield(statesData{1}.chData,'session');
chPerChannel = extractfield(statesData{1}.chData,'ch');
nTotalChannels = length(chPerChannel);
isValidCh = false(nTotalChannels,1);
for iCh = 1:nTotalChannels
    isValidCh(iCh) = any(strcmp(sessionPerUnit,sessionPerChannel(iCh)) & chPerUnit==chPerChannel(iCh));
end
nValidChannels = sum(isValidCh);
isOffStatePerTrialPostOnset = cell(nValidChannels,nStates);
isOffStatePerTrialBaseline = cell(nValidChannels,nStates);
isOffStatePerTrialEntireBaseline = cell(nValidChannels,nStates);
frPerTrialPostOnset = cell(nValidChannels,nStates);
frPerTrialBaseline = cell(nValidChannels,nStates);
frPerTrialEntireBaseline = cell(nValidChannels,nStates);
prob50MsOffStatePoissonPerChAndState = nan(nValidChannels,nStates);
prob50MsOffStateBaselinePerChAndState = nan(nValidChannels,nStates);
prob50MsOffStatePostOnsetPerChAndState = nan(nValidChannels,nStates);
probGammaFitOffStateEntireBaselinePerChAndState = nan(nValidChannels,nStates);
probGammaFitOffStateBaselinePerChAndState = nan(nValidChannels,nStates);
probGammaFitOffStatePostOnsetPerChAndState = nan(nValidChannels,nStates);

for iState = 1:nStates
   offStateCurrentState = cell2mat(extractfield(statesData{iState}.chData(isValidCh),'offState'));
   temp = cell2mat(extractfield(offStateCurrentState,'offState'));
   perTrial = cell2mat(extractfield(temp,'perTrial'));
    isOffState = cell2mat(extractfield(perTrial,'isOffState'));
    frPerTrial = cell2mat(extractfield(perTrial,'fr'));
    isOffStatePerTrialPostOnset(:,iState) = extractfield(isOffState,'postOnset');
    isOffStatePerTrialBaseline(:,iState) = extractfield(isOffState,'baseline');
    for iCh = 1:nValidChannels
        isOffStatePerTrialEntireBaseline{iCh,iState} =isOffState(iCh).probInEntireBaseline; %   extractfield(isOffState,'probInEntireBaseline');
        frPerTrialPostOnset{iCh,iState} =frPerTrial(iCh).postOnset;
        frPerTrialBaseline{iCh,iState} =frPerTrial(iCh).equalLengthBaseline;
        frPerTrialEntireBaseline{iCh,iState} =frPerTrial(iCh).entireBaseline;
        
    end
    prob50MsOffStatePoissonPerChAndState(:,iState) = extractfield(offStateCurrentState,'poisson');
    prob50MsOffStateBaselinePerChAndState(:,iState) = extractfield(offStateCurrentState,'baseline');
    prob50MsOffStatePostOnsetPerChAndState(:,iState) = extractfield(offStateCurrentState,'postOnset');
end
for iState = 1:nStates
    for iCh = 1:nValidChannels
        probGammaFitOffStatePostOnsetPerChAndState(iCh,iState) = mean(isOffStatePerTrialPostOnset{iCh,iState});
        probGammaFitOffStateBaselinePerChAndState(iCh,iState) = mean(isOffStatePerTrialBaseline{iCh,iState});
        probGammaFitOffStateEntireBaselinePerChAndState(iCh,iState) = mean(isOffStatePerTrialEntireBaseline{iCh,iState});
    end
end

%% Calc "Modulation Index" between states pair for changes in off-states during baseline and post onset
% MI = (State2-State1)./(max([state1,state2,...,stateN])-min([state1,state2,...,stateN]))
modulationGammaFitPerChAndStatePairBaseline = nan(nValidChannels,nStates,nStates);
modulationGammaFitPerChAndStatePairPostOnset = nan(nValidChannels,nStates,nStates);

for iCh = 1:nValidChannels
    baselineOffStatesCurrChPerState = probGammaFitOffStateBaselinePerChAndState(iCh,:);
    postOnsetOffStatesCurrChPerState = probGammaFitOffStatePostOnsetPerChAndState(iCh,:);
    rangeBaseline = max(baselineOffStatesCurrChPerState)-min(baselineOffStatesCurrChPerState);
    rangePostOnset = max(postOnsetOffStatesCurrChPerState)-min(postOnsetOffStatesCurrChPerState);
    for iState1 = 1:nStates
        for iState2 = iState1+1:nStates
            modulationGammaFitPerChAndStatePairBaseline(iCh,iState1,iState2) = ...
                diff(baselineOffStatesCurrChPerState([iState1,iState2]))./rangeBaseline;
            modulationGammaFitPerChAndStatePairPostOnset(iCh,iState1,iState2) = ...
                diff(postOnsetOffStatesCurrChPerState([iState1,iState2]))./rangePostOnset;
            modulationGammaFitPerChAndStatePairBaseline(iCh,iState2,iState1) = ...
                -modulationGammaFitPerChAndStatePairBaseline(iCh,iState1,iState2);
            modulationGammaFitPerChAndStatePairPostOnset(iCh,iState2,iState1) = ...
                -modulationGammaFitPerChAndStatePairPostOnset(iCh,iState1,iState2);
        end
    end
end

modulation50MsPerChAndStatePairBaseline = nan(nValidChannels,nStates,nStates);
modulation50MsPerChAndStatePairPostOnset = nan(nValidChannels,nStates,nStates);
for iCh = 1:nValidChannels
    baselineOffStatesCurrChPerState = prob50MsOffStateBaselinePerChAndState(iCh,:)-...
        prob50MsOffStatePoissonPerChAndState(iCh,:);
    postOnsetOffStatesCurrChPerState = prob50MsOffStatePostOnsetPerChAndState(iCh,:)-...
        prob50MsOffStatePoissonPerChAndState(iCh,:);
    rangeBaseline = max(baselineOffStatesCurrChPerState)-min(baselineOffStatesCurrChPerState);
    rangePostOnset = max(postOnsetOffStatesCurrChPerState)-min(postOnsetOffStatesCurrChPerState);
    for iState1 = 1:nStates
        for iState2 = iState1+1:nStates
            modulation50MsPerChAndStatePairBaseline(iCh,iState1,iState2) = ...
                diff(baselineOffStatesCurrChPerState([iState1,iState2]))./rangeBaseline;
            modulation50MsPerChAndStatePairPostOnset(iCh,iState1,iState2) = ...
                diff(postOnsetOffStatesCurrChPerState([iState1,iState2]))./rangePostOnset;
            modulation50MsPerChAndStatePairBaseline(iCh,iState2,iState1) = ...
                -modulation50MsPerChAndStatePairBaseline(iCh,iState1,iState2);
            modulation50MsPerChAndStatePairPostOnset(iCh,iState2,iState1) = ...
                -modulation50MsPerChAndStatePairPostOnset(iCh,iState1,iState2);
        end
    end
end
%% Set Plot Data
sessionPerChannelValid = sessionPerChannel(isValidCh);
chPerChannelValid = chPerChannel(isValidCh);
plotData.sessionPerChannel = sessionPerChannelValid;
plotData.chPerChannel = chPerChannelValid;
plotData.probOffStateGammaFitPerChAndState.postOnset = probGammaFitOffStatePostOnsetPerChAndState;
plotData.probOffStateGammaFitPerChAndState.baseline = probGammaFitOffStateBaselinePerChAndState;
plotData.probOffStateGammaFitPerChAndState.entireBaseline = probGammaFitOffStateEntireBaselinePerChAndState;
plotData.probOffState50MsPerChAndState.postOnset = prob50MsOffStatePostOnsetPerChAndState;
plotData.probOffState50MsPerChAndState.baseline = prob50MsOffStateBaselinePerChAndState;
plotData.probOffState50MsPerChAndState.poisson = prob50MsOffStatePoissonPerChAndState;
plotData.modulationGammaFitPerChAndStatePair.baseline = modulationGammaFitPerChAndStatePairBaseline;
plotData.modulationGammaFitPerChAndStatePair.postOnset = modulationGammaFitPerChAndStatePairPostOnset;
plotData.modulation50MsPerChAndStatePair.baseline = modulation50MsPerChAndStatePairBaseline;
plotData.modulation50MsPerChAndStatePair.postOnset = modulation50MsPerChAndStatePairPostOnset;

iExamplePerUnit = nan(sum(isValidCh),1);
iExamplePerUnit(strcmp(sessionPerChannelValid,exampleChannel.session) & ...
    chPerChannelValid==exampleChannel.ch)=1;

%% Stats - get if sessions/animals have enough channels, and calculate mean values per session/animal
[sessionsStr,~,iSessionPerCh] = unique(sessionPerChannelValid);
nSessions = length(sessionsStr);
isSessWithEnoughChannels = false(nSessions,1);

for iSess = 1:nSessions
    isSessWithEnoughChannels(iSess) = sum(iSessionPerCh==iSess)>=minChannelsPerSess;
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end
[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);

iAnimalPerCh = iAnimalPerSession(iSessionPerCh);
isAnimalWithEnoughChannels = false(nAnimals,1);

for iAnimal = 1:nAnimals
    isAnimalWithEnoughChannels(iAnimal) = sum(iAnimalPerCh==iAnimal)>=minUnitsPerAnimal;
end

%% Calculate Stats
prob50MsOffStatePostOnsetPerChAndStateNormalized = prob50MsOffStatePostOnsetPerChAndState-...
    prob50MsOffStatePoissonPerChAndState;
prob50MsOffStateBaselinePerChAndStateNormalized = prob50MsOffStateBaselinePerChAndState-...
    prob50MsOffStatePoissonPerChAndState;

stats.probGammaFit = calcStatsForBaselineAndPostOnset(probGammaFitOffStateBaselinePerChAndState,...
    probGammaFitOffStatePostOnsetPerChAndState, iSessionPerCh, iAnimalPerCh, ...
    isSessWithEnoughChannels,isAnimalWithEnoughChannels);

stats.prob50Ms = calcStatsForBaselineAndPostOnset(prob50MsOffStateBaselinePerChAndStateNormalized,...
    prob50MsOffStatePostOnsetPerChAndStateNormalized, iSessionPerCh, iAnimalPerCh, ...
    isSessWithEnoughChannels,isAnimalWithEnoughChannels);

stats.probGammaFit = calcStatsForBaselineAndPostOnset(probGammaFitOffStateBaselinePerChAndState,...
    probGammaFitOffStatePostOnsetPerChAndState, iSessionPerCh, iAnimalPerCh, ...
    isSessWithEnoughChannels,isAnimalWithEnoughChannels);

% Tachles I am mostly interested in stats.modulationGammaFit/modulation50Ms(1,2).postOnsetVsBaseline 
% to compare how modulation of Tired-Vigilant/range(Vigilant,Tired,NREM) compares between 
% baseline and post-onset off states - to show that Tiredness shows effects mostly for
% post-onset stimuli.
for iState1 = 1:nStates-1
    for iState2 = iState1+1:nStates
        stats.modulationGammaFit(iState1,iState2) = calcStatsForBaselineAndPostOnset(...
            modulationGammaFitPerChAndStatePairBaseline(:,iState1,iState2),...
            modulationGammaFitPerChAndStatePairPostOnset(:,iState1,iState2), iSessionPerCh, iAnimalPerCh, ...
            isSessWithEnoughChannels,isAnimalWithEnoughChannels);
        
        stats.modulation50Ms(iState1,iState2) = calcStatsForBaselineAndPostOnset(...
            modulation50MsPerChAndStatePairBaseline(:,iState1,iState2),...
            modulation50MsPerChAndStatePairPostOnset(:,iState1,iState2), iSessionPerCh, iAnimalPerCh, ...
            isSessWithEnoughChannels,isAnimalWithEnoughChannels);
        
    end
end

function stats = calcStatsForBaselineAndPostOnset(dataPerChAndStateBaseline,...
    dataPerChAndStatePostOnset, iSessionPerCh, iAnimalPerCh, isSessWithEnoughChannels, ...
    isAnimalWithEnoughChannels)

nStates = size(dataPerChAndStateBaseline,2);
[stats.baseline,~,~] = calcStatsPerChSessAndAnimal(...
    dataPerChAndStateBaseline, iSessionPerCh, iAnimalPerCh, isSessWithEnoughChannels, ...
    isAnimalWithEnoughChannels);
[stats.postOnset,~,~] = calcStatsPerChSessAndAnimal(...
    dataPerChAndStatePostOnset, iSessionPerCh, iAnimalPerCh, isSessWithEnoughChannels, ...
    isAnimalWithEnoughChannels);
for iState = nStates:-1:1
    [stats.PostOnsetVsBaseline(iState),~,~] = calcStatsPerChSessAndAnimal(...
    [dataPerChAndStatePostOnset(:,iState),dataPerChAndStateBaseline(:,iState)], ...
    iSessionPerCh, iAnimalPerCh, isSessWithEnoughChannels, isAnimalWithEnoughChannels);
end


function [stats,dataPerSessAndState, dataPerAnimalAndState] = calcStatsPerChSessAndAnimal(...
    dataPerChAndState, iSessionPerCh, iAnimalPerCh, isSessWithEnoughChannels, ...
    isAnimalWithEnoughChannels)
[dataPerSessAndState, dataPerAnimalAndState] = getMeanPerSessAndAnimal(dataPerChAndState,...
    iSessionPerCh,iAnimalPerCh,isSessWithEnoughChannels,isAnimalWithEnoughChannels);
%% Per Channel
stats.perChannel = calcStatsForDataPerState(dataPerChAndState);
stats.perSession = calcStatsForDataPerState(dataPerSessAndState);
stats.perAnimal = calcStatsForDataPerState(dataPerAnimalAndState);

function stats = calcStatsForDataPerState(dataPerSampleAndState)
WSRT_STR = 'Wilcoxon Sign Rank Test';
FRIEDMAN_STR = 'Friedman Test';

%% mean/median/sem/ signrank different from 0.
nStates = size(dataPerSampleAndState,2);
nSamples = size(dataPerSampleAndState,1);
stats.mean = mean(dataPerSampleAndState);
stats.median = median(dataPerSampleAndState);
stats.sem = std(dataPerSampleAndState)./sqrt(nSamples);
for iState = nStates:-1:1
    [stats.diffFrom0.p(iState),~,statsSignrank] = signrank(dataPerSampleAndState(:,iState));
    if isfield(statsSignrank,'zval')
        stats.diffFrom0.z(iState) = statsSignrank.zval;
    end
end
stats.diffFrom0.n = nSamples;
stats.diffFrom0.test = WSRT_STR;

%% variance across all states (Friedman test)
if nStates>2
    [p,~,statsFriedman] = friedman(dataPerSampleAndState,1,'off');
    stats.diffBetweenAll.p = p;
    stats.diffBetweenAll.n = statsFriedman.n;
    stats.diffBetweenAll.test = FRIEDMAN_STR;
    stats.diffBetweenAll.stats = statsFriedman;
end

%% signrank between each states pair
for iState1 = 1:nStates-1
    for iState2 = iState1+1:nStates
        [stats.diffBetweenPairs(iState1,iState2).p,~,statsSignrank] = signrank(...
            dataPerSampleAndState(:,iState1),dataPerSampleAndState(:,iState2));
        if isfield(statsSignrank,'zval')
            stats.diffBetweenPairs(iState1,iState2).z = statsSignrank.zval;
        end
        stats.diffBetweenPairs(iState1,iState2).n = sum(all(...
            ~isnan(dataPerSampleAndState(:,[iState1,iState2])),2));
        stats.diffBetweenPairs(iState1,iState2).test = WSRT_STR;

    end
end
if nStates==2
    stats.diffBetweenPairs = stats.diffBetweenPairs(1,2);
end

function [meanPerSessAndState,meanPerAnimalAndState] = getMeanPerSessAndAnimal(dataPerChAndState,...
    iSessionPerCh,iAnimalPerCh,isSessWithEnoughChannels,isAnimalWithEnoughChannels)

nStates = size(dataPerChAndState,2);
nSessions = max(iSessionPerCh);
nAnimals = max(iAnimalPerCh);
meanPerSessAndState = nan(nSessions,nStates);
for iSess = 1:nSessions
    meanPerSessAndState(iSess,:) = mean(dataPerChAndState(iSessionPerCh==iSess,:));
end
meanPerSessAndState(~isSessWithEnoughChannels,:) = [];

meanPerAnimalAndState = nan(nAnimals,nStates);
for iAnimal = 1:nAnimals
    meanPerAnimalAndState(iAnimal,:) = mean(dataPerChAndState(iAnimalPerCh==iAnimal,:));
end
meanPerAnimalAndState(~isAnimalWithEnoughChannels,:) = [];