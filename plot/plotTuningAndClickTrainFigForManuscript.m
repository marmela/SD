function plotTuningAndClickTrainFigForManuscript(state1Data,state2Data, isSigTuningUnit, ...
    isSigClicksUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning, exampleUnitClicks, ...
    statesToPlotClickRaster, dirName, fileName)

%%
[statsClicks,clicksPlotData] = calcClickResponsesAndStats(state1Data,state2Data, isSigClicksUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitClicks, statesToPlotClickRaster);
[statsTuning,tuningPlotData] = calcTuningCorrelationAndStats(state1Data,state2Data, isSigTuningUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning);

if exist('dirName','var')
    statsDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep dirName];
else
    statsDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'MainFig'];
end
makeDirIfNeeded(statsDir)
if exist('fileName','var')
    statsFileName = sprintf('%sStats_%s-%s',fileName,state1Data.info.str,state2Data.info.str);
else
    statsFileName = sprintf('MainFigStats_%s-%s',state1Data.info.str,state2Data.info.str);
end
statsPath = [statsDir filesep statsFileName];
statsTuning.isSigUnit = isSigTuningUnit;
statsClicks.isSigUnit = isSigClicksUnit;
save(statsPath,'statsTuning','statsClicks','tuningPlotData','clicksPlotData');

sessionStr = extractfield(state1Data.sessData,'session');
isContextSess = cell2mat(extractfield(state1Data.sessData,'isContext'));
markerAnimalMap = Consts.MARKER_ANIMAL_MAP;
if exist('fileName','var')
    plotTuningAndClicksFig(tuningPlotData,clicksPlotData,state1Data.info,state2Data.info,...
        statesToPlotClickRaster,sessionStr(isContextSess), markerAnimalMap, dirName, fileName)
elseif exist('dirName','var')
    plotTuningAndClicksFig(tuningPlotData,clicksPlotData,state1Data.info,state2Data.info,...
        statesToPlotClickRaster,sessionStr(isContextSess), markerAnimalMap, dirName)
else
    plotTuningAndClicksFig(tuningPlotData,clicksPlotData,state1Data.info,state2Data.info,...
        statesToPlotClickRaster,sessionStr(isContextSess), markerAnimalMap)
end









function plotTuningAndClicksFig(tuningPlotData,clicksPlotData,state1Info,state2Info,...
    statesToPlotClickRaster,contextSessionsStr, markerAnimalMap, dirName, fileName)

%% Various Figure Properties

figProperties.tuning.examplePlotArrowHeadLength = 7;
figProperties.tuning.examplePlotArrowHeadWidth = 7;

figPositions =  [0,50,1000,900]; %[0,50,1400,1100];
fontMultiplierForWidth = figPositions(3)/1000;
MS_IN_SEC = 1000;
CLICKS_LENGTH_MS = 500;
markerPixels = 2.2.*fontMultiplierForWidth; 
markerPixelsSess = 7.5.*fontMultiplierForWidth; 
xJitterRange = 0.95;
nReps = 10000;

onsetTimesMs = [0,30]; 
postOnsetTimesMs = [30,80]; 
sustainedLockingTimesMs = [130,530]; 

clickRateHz = [2,10,20,30,40];
iClickRateToPlot = [1,5];

firstRowY = 0.65; 
firstRowHeight = 0.31; 
distanceBetweenExamplePlots = 0.005;
exampleTuningPlotWidth = 0.035;
exampleStrfWidth = 0.15;
examplesX = 0.08; 
colorBarWidth = 0.015;


tuningPopulationX = 0.59;
tuningWidthPopulationWidth = 0.07;
interPanelWidth = 0.1; 
tuningCorrPopulationWidth = 0.21;


secondRowY = 0.07;
secondRowHeight = 0.49;
clicksPopulationX = tuningPopulationX;
clicksPopulationWidth = tuningWidthPopulationWidth+interPanelWidth+tuningCorrPopulationWidth; % 0.415;

psthHeight = 0.14;
stimClicksHeight = 0.012;
rasterHeight = secondRowHeight-psthHeight-stimClicksHeight; %0.24;

 
panelLetterXShift = -0.05; 
panelLetterYShift = 0.02*figPositions(3)./figPositions(4);%0.01;

PLOT_LINE_WIDTH = 1.5*fontMultiplierForWidth; 
PLOT_LINE_COLOR = 'k';
TUNING_LINE_COLOR = 'r';
PSTH_LINE_WIDTH = 1.2*fontMultiplierForWidth; 

FONT_SIZE = 13.5.*fontMultiplierForWidth; 
STATE_FONT_SIZE = 15.*fontMultiplierForWidth; 
sizeRatioState = 1.45;
FONT_SIZE_LETTER = 26.*fontMultiplierForWidth; 

CLICK_COLOR = 'k';
CLICK_LINE_WIDTH = PLOT_LINE_WIDTH*1.5;

XTICK_PSTH_MS = [0,500];

SHADING_BASELINE_COLOR = [0.4,0.4,0.4];
SHADING_ONSET_COLOR = ones(1,3)*0.4;
SHADING_LOCKING_COLOR =  [90	60	0]/95; 
SHADING_POST_ONSET_COLOR = [0	60	50]*0.85/95; 

if exist('dirName','var')
    figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep dirName];    
else
    figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'MainFig'];
end
makeDirIfNeeded(figDir);
SHADING_ALPHA = 0.25; 
colorPerMeasure = {[],SHADING_ONSET_COLOR,[],...
    SHADING_LOCKING_COLOR,SHADING_POST_ONSET_COLOR};

COLORMAP_STRF = parula;%turbo(200);


if exist('fileName','var')
    figName = sprintf('%s_%s-%s',fileName,state1Info.str,state2Info.str);
else
    figName = sprintf('MainFig_%s-%s',state1Info.str,state2Info.str);
end

examplePlotPosition{2} = [examplesX,firstRowY,exampleTuningPlotWidth,firstRowHeight];
examplePlotPosition{1} = [examplesX+exampleTuningPlotWidth+exampleStrfWidth+distanceBetweenExamplePlots,...
    firstRowY,exampleTuningPlotWidth,firstRowHeight];

exampleStrfPosition{2} = [examplesX+exampleTuningPlotWidth,firstRowY,exampleStrfWidth,firstRowHeight];
exampleStrfPosition{1} = [examplesX+exampleStrfWidth+exampleTuningPlotWidth*2+distanceBetweenExamplePlots,...
    firstRowY,exampleStrfWidth,firstRowHeight];
exampleColorBarPos = [exampleStrfPosition{1}(1)+exampleStrfWidth+distanceBetweenExamplePlots,...
    firstRowY,colorBarWidth,firstRowHeight];



tuningWidthPopulationPlotPositions = [tuningPopulationX,firstRowY,tuningWidthPopulationWidth,firstRowHeight];
tuningCorrPopulationPlotPositions = [tuningPopulationX+tuningWidthPopulationWidth+interPanelWidth,...
    firstRowY,tuningCorrPopulationWidth,firstRowHeight];

clicksPopulationPlotPositions = [clicksPopulationX,secondRowY,clicksPopulationWidth,secondRowHeight];

endOfTuningExamplesX = exampleColorBarPos(1)+colorBarWidth;
distanceBetweenRasters = 0.01;
rasterPsthWidth = (clicksPopulationX-interPanelWidth-examplesX-distanceBetweenRasters)/2; %(endOfTuningExamplesX-examplesX-distanceBetweenRasters)/2;

examplePsthPosition{1} = [examplesX,secondRowY,rasterPsthWidth,psthHeight];
examplePsthPosition{2} = [examplesX+rasterPsthWidth+distanceBetweenRasters,secondRowY,rasterPsthWidth,psthHeight];

exampleRasterPosition{1} = [examplesX,secondRowY+psthHeight,rasterPsthWidth,rasterHeight];
exampleRasterPosition{2} = [examplesX+rasterPsthWidth+distanceBetweenRasters,secondRowY+psthHeight,...
    rasterPsthWidth,rasterHeight];

exampleStimClicksPosition{1} = [examplesX,secondRowY+psthHeight+rasterHeight,rasterPsthWidth,stimClicksHeight];
exampleStimClicksPosition{2} = [examplesX+rasterPsthWidth+distanceBetweenRasters,...
    secondRowY+psthHeight+rasterHeight,rasterPsthWidth,stimClicksHeight];





%%
hFig = figure('Position',figPositions);
%% Plot Panels Letters
annotation('textbox', [examplesX+panelLetterXShift, firstRowY+firstRowHeight+panelLetterYShift, 0, 0],...
    'string', 'A','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [tuningWidthPopulationPlotPositions(1)+panelLetterXShift, firstRowY+firstRowHeight+panelLetterYShift, 0, 0],...
    'string', 'B','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [tuningCorrPopulationPlotPositions(1)+panelLetterXShift, firstRowY+firstRowHeight+panelLetterYShift, 0, 0],...
    'string', 'C','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [examplesX+panelLetterXShift, secondRowY+secondRowHeight+panelLetterYShift, 0, 0],...
    'string', 'D','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [clicksPopulationPlotPositions(1)+panelLetterXShift, secondRowY+secondRowHeight+panelLetterYShift, 0, 0],...
    'string', 'E','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')
%% Plot tuning plots examples
freqsToPlot = 1000*2.^(0:6);
freqs = tuningPlotData.example.freqs;
[Lia,Locb] = ismember(round(freqs),freqsToPlot);

nStates = length(tuningPlotData.example.strfExamplePerState);
minFr = Inf;
maxFr = -Inf;
for iState = 1:nStates
    frPerFreqToPlot{iState} = tuningPlotData.example.meanFrPerFreqPerState{iState};
    minFr = min(minFr, min(frPerFreqToPlot{iState}));
    maxFr = max(maxFr, max(frPerFreqToPlot{iState}));
end
    
for iState = 1:nStates
    subplot('position',examplePlotPosition{iState});
    hold on;
    plot(frPerFreqToPlot{iState},1:length(frPerFreqToPlot{iState}),'color',PLOT_LINE_COLOR,...
        'LineWidth',PLOT_LINE_WIDTH);
    
    %% plotting tuning width line
    anArrow = annotation('line','LineWidth',PLOT_LINE_WIDTH*1.3,'color',TUNING_LINE_COLOR) ; %'doublearrow'
    anArrow.Parent = gca;  % or any other existing axes or figure
    anArrow.Position = [max(frPerFreqToPlot{iState})/2, tuningPlotData.example.iFwhm(iState).onset, ...
        0, tuningPlotData.example.iFwhm(iState).offset-tuningPlotData.example.iFwhm(iState).onset] ;
    
    %%
    set(gca,'XDir','reverse')
    ylim([0.5,length(frPerFreqToPlot{iState})+0.5])
    if iState==nStates
        set(gca,'YTick',find(Lia),'YTickLabel',freqsToPlot(Locb(Lia))./1000);
        ylabel('Frequency (KHz)');
    else
        set(gca,'YTick',[]);
    end
    set(gca,'FontSize',FONT_SIZE);
    xlim([minFr,maxFr]);
    set(gca,'XTick',[]);
    if iState==nStates
        frRange = [0,50];
        yFreqIndRefLine = [-0.5,-0.5];
        plot(frRange,yFreqIndRefLine,'k','LineWidth',1.5)
        hText = text(mean(frRange),yFreqIndRefLine(1)-1.5,...
            sprintf('%d spikes/s',diff(frRange)),'HorizontalAlignment','center','FontSize',FONT_SIZE);
        set(gca,'Clipping','Off')
    end
    
end


%% Plot STRF Examples
timesPsthMs = tuningPlotData.example.timesPsthMs;
isDuringRelevantTime = timesPsthMs>=tuningPlotData.example.relevantTimeMs(1) & ...
    timesPsthMs<tuningPlotData.example.relevantTimeMs(2);
for iState = nStates:-1:1
    strfExamplePerState{iState} = conv2(tuningPlotData.example.strfExamplePerState{iState},...
        tuningPlotData.example.smoothWin,'same');
    strfExamplePerState{iState}  = strfExamplePerState{iState} (:,isDuringRelevantTime);
end

maxVal = -Inf;
minVal = Inf;
for iState = 1:nStates
    maxVal = max(maxVal,max(strfExamplePerState{iState},[],'all'));
    minVal = min(minVal,min(strfExamplePerState{iState},[],'all'));
    
end

for iState = 1:nStates
    subplot('position',exampleStrfPosition{iState});
    imagesc(timesPsthMs(isDuringRelevantTime),1:length(freqs),strfExamplePerState{iState});
    hold on;
    colormap(COLORMAP_STRF)
    set(gca,'YTick',[]);
    set(gca,'XTick',[]); 
    set(gca,'YDir','normal')
    set(gca,'FontSize',FONT_SIZE);
    
    title(tuningPlotData.example.strPerState{iState},'FontSize',STATE_FONT_SIZE,...
        'color',eval(sprintf('state%dInfo.color',iState)))
    
    if iState==nStates
        timesMsRefLine = [20,40];
        yFreqIndRefLine = [-0.5,-0.5];
        plot(timesMsRefLine,yFreqIndRefLine,'k','LineWidth',1.5)
        hText = text(mean(timesMsRefLine),yFreqIndRefLine(1)-1.5,...
            sprintf('%d ms',diff(timesMsRefLine)),'HorizontalAlignment','center','FontSize',FONT_SIZE);
        set(gca,'Clipping','Off')
    end
end

%% STRF colorbar
hBar = colorbar('position',exampleColorBarPos);
caxis([minVal,maxVal]);
title(hBar,sprintf('\\DeltaSpikes/s'));

%% plot Tuning Width Modulation per unit

subplot('position',tuningWidthPopulationPlotPositions);
hold on;
XLIM = [0.5,1+0.5];
YLIM = [-100,100]; %[-1,1];
xlim(XLIM)
ylim(YLIM)


% \color[rgb]{specifier}
text(0.51,90,['\bf\it\fontsize{' num2str(STATE_FONT_SIZE) '}\color[rgb]{' sprintf('%f,%f,%f',state1Info.color) '}' state1Info.str '>' ...
    '\bf\fontsize{' num2str(STATE_FONT_SIZE/sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',state2Info.color) '}' state2Info.str],'HorizontalAlignment','left');
text(0.51,-90,['\bf\it\fontsize{' num2str(STATE_FONT_SIZE/sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',state1Info.color) '}' state1Info.str  ...
    '\bf\fontsize{' num2str(STATE_FONT_SIZE) '}\color[rgb]{' sprintf('%f,%f,%f',state2Info.color) '}' '<' state2Info.str],'HorizontalAlignment','left');

xloc1 = plotBarAndPoints(tuningPlotData.tuningWidthGainPerUnitAll,1,xJitterRange,nReps,...
    markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
plotPointsPerSess(tuningPlotData.tuningWidthGainPerUnitAll,1,xJitterRange,nReps, ...
    markerPixelsSess,tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,markerAnimalMap)

%don't plot example points in stability fig because might be missing (not stable enough?)
if ~exist('dirName','var') || ~strcmp(dirName,'StabilityFig')
    plotExamplePoints(tuningPlotData.tuningWidthGainPerUnitAll,xloc1,...
        markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
end

set(gca,'XTick',1,'XTickLabel','Tuning Width');
set(gca,'YTick',-100:20:100)
ylabel('Modulation Index (%)');
set(gca,'FontSize',FONT_SIZE);
grid on


%% plot signal correlation per unit
XLIM = [0.5,3+0.5];
YLIM = [-0.2,1];

subplot('position',tuningCorrPopulationPlotPositions);
hold on;

xlim(XLIM)
ylim(YLIM)

xloc1 = plotBarAndPoints(tuningPlotData.meanCorrBetweenStatesWithOtherUnitsAll,1,xJitterRange,nReps,...
    markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
xloc2 = plotBarAndPoints(tuningPlotData.meanCorrBetweenStatesPerUnitAll,2,xJitterRange,nReps, ...
    markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
xloc3 = plotBarAndPoints(tuningPlotData.meanCorrWithinStatePerUnitAll,3,xJitterRange,nReps, ...
    markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);

plotPointsPerSess(tuningPlotData.meanCorrBetweenStatesWithOtherUnitsAll,1,xJitterRange,nReps, ...
    markerPixelsSess,tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,markerAnimalMap)
plotPointsPerSess(tuningPlotData.meanCorrBetweenStatesPerUnitAll,2,xJitterRange,nReps, ...
    markerPixelsSess,tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,markerAnimalMap)
plotPointsPerSess(tuningPlotData.meanCorrWithinStatePerUnitAll,3,xJitterRange,nReps,...
    markerPixelsSess,tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,markerAnimalMap)

if ~exist('dirName','var') || ~strcmp(dirName,'StabilityFig')
    plotExamplePoints(tuningPlotData.meanCorrBetweenStatesWithOtherUnitsAll,xloc1,...
        markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
    plotExamplePoints(tuningPlotData.meanCorrBetweenStatesPerUnitAll,xloc2, ...
        markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
    plotExamplePoints(tuningPlotData.meanCorrWithinStatePerUnitAll,xloc3, ...
        markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
end

state1XState2Str = {['\bf\it\color[rgb]{' sprintf('%f,%f,%f',state2Info.color) '}' ...
    state2Info.str '\color{black}x'], ['   \bf\it\color[rgb]{' sprintf('%f,%f,%f',state1Info.color)...
    '}' state1Info.str ]};

row1 = {'Between    ' state1XState2Str{1}   '   Within'};
row2 = {'  units'     state1XState2Str{2}   '   state'};
labelArray = [row1; row2]; 
tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
ax = gca(); 
ax.XTick = 1:3; 
ax.XTickLabel = tickLabels; 
ylabel('Signal Correlation');
if min(ylim())<YLIM(1)
    warning('AXIS OUTSIDE OF PREDEFINED Y-LIM');
end
ylim(YLIM)
set(gca,'FontSize',FONT_SIZE);
ax.XAxis.FontSize = FONT_SIZE;

grid on

%% plot clicks modulation/gain index per unit 

nMeasures = length(clicksPlotData.gainIndex);
XLIM = [0.5,nMeasures+0.5];
YLIM = [-100,100]; %[-1,1];

X_TICK_ANGLE = 25;
subplot('position',clicksPopulationPlotPositions);
hold on;
plot([2.5,2.5],YLIM,'--k','LineWidth',1)


xlim(XLIM)
ylim(YLIM)

% maxAbsGain = 0.85;
for iMeasure = 1:nMeasures
    if isempty(colorPerMeasure{iMeasure})
        colorAfterAlpha = [];
    else
        colorAfterAlpha = 1-(1-colorPerMeasure{iMeasure})*sqrt(SHADING_ALPHA);
    end
    
    xLocCurrentMeasure = plotBarAndPoints(clicksPlotData.gainIndex{iMeasure},iMeasure,...
        xJitterRange,nReps,markerPixels,clicksPlotData.exampleUnits,clicksPlotData.iExamplePerUnit,colorAfterAlpha);
        
    plotPointsPerSess(clicksPlotData.gainIndex{iMeasure},iMeasure,xJitterRange,nReps,...
        markerPixelsSess,clicksPlotData.sessionStrPerUnitValid,clicksPlotData.minUnitsPerSess,...
        contextSessionsStr,markerAnimalMap)
    if ~exist('dirName','var') || ~strcmp(dirName,'StabilityFig')
        plotExamplePoints(clicksPlotData.gainIndex{iMeasure},xLocCurrentMeasure,...
            markerPixels,clicksPlotData.exampleUnits,clicksPlotData.iExamplePerUnit);
    end
end

text(1.6,90,['\bf\it\fontsize{' num2str(STATE_FONT_SIZE) '}\color[rgb]{' sprintf('%f,%f,%f',state1Info.color) '}' state1Info.str '>' ...
    '\bf\it\fontsize{' num2str(STATE_FONT_SIZE/sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',state2Info.color) '}' state2Info.str],'HorizontalAlignment','center');
text(1.6,-90,['\bf\it\fontsize{' num2str(STATE_FONT_SIZE/sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',state1Info.color) '}' state1Info.str  ...
    '\bf\it\fontsize{' num2str(STATE_FONT_SIZE) '}\color[rgb]{' sprintf('%f,%f,%f',state2Info.color) '}' '<' state2Info.str],'HorizontalAlignment','center');

ylabel('Modulation Index (%)');
measuresLabels = clicksPlotData.measureStr;
for iMeasure = 1:5
    if iscell(measuresLabels{iMeasure})
        nRowsStr = length(measuresLabels{iMeasure});
        for iRow = 1:nRowsStr
            currentStr = measuresLabels{iMeasure}{iRow};
            if (~isempty(colorPerMeasure{iMeasure}))
                labelPerRow{iRow,iMeasure} = ['\color[rgb]{' sprintf('%f,%f,%f',colorPerMeasure{iMeasure}) '}' currentStr];
            else
                labelPerRow{iRow,iMeasure} = currentStr;
            end
            
        end
    else

        if (isempty(colorPerMeasure{iMeasure}))
            labelPerRow{1,iMeasure} = measuresLabels{iMeasure};
        else
            labelPerRow{1,iMeasure} = ['\color[rgb]{' sprintf('%f,%f,%f',...
                colorPerMeasure{iMeasure}) '}' measuresLabels{iMeasure}];

        end
        
    end
end

tickLabels = strtrim(sprintf('%s\\newline%s\n', labelPerRow{:}));
set(gca,'XTick',1:nMeasures,'XTickLabel',tickLabels);%measuresLabels);
set(gca,'FontSize',FONT_SIZE);
set(gca,'YTick',-100:20:100)
grid on

%% Plot Rasters+PSTHs examples
nClickRasters = length(iClickRateToPlot);
nStatesToPlot = length(statesToPlotClickRaster);
timesMs = clicksPlotData.example.timeMs;

maxFr = -Inf;
for iRaster = 1:nClickRasters
    for iState = 1:nStates
        maxFr = max(maxFr,max(clicksPlotData.example.psthPerStimAndState{iClickRateToPlot(iRaster),iState}));
    end
end
yLimToUsePsth = [0,ceil(maxFr./5)*5];

for iRaster = 1:nClickRasters
    iClickRate = iClickRateToPlot(iRaster);
    %% PSTH Subplot
    subplot('position',examplePsthPosition{iRaster})
    hold on;
    stateStr = extractfield(statesToPlotClickRaster,'str');
    iRemState = find(strcmp(stateStr,'REM'));
    if ~isempty(iRemState)
        iStatesOrder = [iRemState, 1:iRemState-1, iRemState+1:nStatesToPlot];
    else
        iStatesOrder = 1:nStatesToPlot;
    end
    for iState = iStatesOrder
        plot(timesMs,clicksPlotData.example.psthPerStimAndState{iClickRate,iState},...
            'color',statesToPlotClickRaster(iState).color,'LineWidth',PSTH_LINE_WIDTH);
    end
    if iRaster==1
        ylabel('Spikes/s'); %'Firing Rate (spks/s)')
    else
        set(gca,'YTickLabel',{});
    end
    set(gca,'YTick',0:50:maxFr)
    xlimCurr = xlim();


    set(gca,'FontSize',FONT_SIZE)
    set(gca,'XTick',[]);
    if iRaster==1
        timesMsRefLine = [0,500];
        yFreqIndRefLine = repmat(diff(yLimToUsePsth)*-0.06,1,2); 
        plot(timesMsRefLine,yFreqIndRefLine,'k','LineWidth',1.5)
        hText = text(mean(timesMsRefLine),yFreqIndRefLine(1)*2.5,...
            sprintf('%d ms',diff(timesMsRefLine)),'HorizontalAlignment','center','FontSize',FONT_SIZE);
        set(gca,'Clipping','Off')
    end
    
    %% shading
    if iRaster==1
        area(postOnsetTimesMs,[yLimToUsePsth(2),yLimToUsePsth(2)],yLimToUsePsth(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_POST_ONSET_COLOR)
         area(onsetTimesMs,[yLimToUsePsth(2),yLimToUsePsth(2)],yLimToUsePsth(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_ONSET_COLOR)
    elseif iRaster==2
        area(sustainedLockingTimesMs,[yLimToUsePsth(2),yLimToUsePsth(2)],yLimToUsePsth(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_LOCKING_COLOR)
         area(onsetTimesMs,[yLimToUsePsth(2),yLimToUsePsth(2)],yLimToUsePsth(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_ONSET_COLOR)
    end
    ylim(yLimToUsePsth);
    
    %% Raster Subplot
    subplot('position',exampleRasterPosition{iRaster})
    nTotalTrials = 0;
    unitedRaster = [];
    timeMsLimits = [-200,600];
    timeMsStateText = -350;
    for iState = 1:nStatesToPlot
        currentRasterPerState{iState} = clicksPlotData.example.rasterPerStimAndState{iClickRate,iState};
        nTotalTrials = nTotalTrials + size(currentRasterPerState{iState},1);
        unitedRaster = [unitedRaster; currentRasterPerState{iState}];
        borderTrialBetweenStates(iState) = nTotalTrials;
    end
    hRaster = imagesc(timesMs,1:nTotalTrials, logical(conv2(double(full(unitedRaster)),ones(1,5),'same')));
    colormap(gca,flipud(gray))
            hold on;
    for iState = 1:nStatesToPlot-1
        plot([floor(timesMs(1)),ceil(timesMs(end))],repmat(borderTrialBetweenStates(iState)+0.5,1,2),'k');
    end
    trialEdgesOfStates = [0,borderTrialBetweenStates];
    
    if iRaster==1
        for iState = 1:nStatesToPlot
            previousStateLine = trialEdgesOfStates(iState);
            nTrialsCurrentState = trialEdgesOfStates(iState+1)-trialEdgesOfStates(iState);

            if iState==nStatesToPlot
                shiftTextByTrials = nTrialsCurrentState*0.4;
            else
                shiftTextByTrials = nTrialsCurrentState/2;
            end
            text(timeMsStateText,previousStateLine+shiftTextByTrials,...
                statesToPlotClickRaster(iState).str,'HorizontalAlignment','center',...
                'Color',statesToPlotClickRaster(iState).color,'FontSize',STATE_FONT_SIZE ,...
                'FontWeight','bold','Margin',1.5);
        end
        trialToEndRefLine = nTotalTrials*0.96;
        nTrialsForRefLine = 50;
        plot(repmat(timeMsLimits(1)-diff(timeMsLimits)*0.03,1,2),...
            trialToEndRefLine+[-nTrialsForRefLine,0],'k','LineWidth',1.5)
        hText = text(timeMsLimits(1)-diff(timeMsLimits)*0.15,trialToEndRefLine-nTrialsForRefLine/2,...
            sprintf('%d\ntrials',nTrialsForRefLine),'HorizontalAlignment','center','FontSize',FONT_SIZE);
        set(gca,'Clipping','Off')
    end
    
    yLimToUse = [0,nTotalTrials]+0.5;
    


    %% shading
    if iRaster==1
        area(postOnsetTimesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_POST_ONSET_COLOR)
         area(onsetTimesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_ONSET_COLOR)
    elseif iRaster==2
        area(sustainedLockingTimesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_LOCKING_COLOR)
         area(onsetTimesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),'FaceAlpha',...
            SHADING_ALPHA,'EdgeColor','none','FaceColor',SHADING_ONSET_COLOR)
    end
    
    %%
    
    xlim(timeMsLimits)
    ylim(yLimToUse);
    set(gca,'YDir','reverse')
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    set(gca,'FontSize',FONT_SIZE)
    
    %% Stimulus Clicks above Raster Subplot
    subplot('position',exampleStimClicksPosition{iRaster})
    clickTimesMs = 0:MS_IN_SEC/clickRateHz(iClickRate):CLICKS_LENGTH_MS;
    hold on;
    for iClick=1:length(clickTimesMs)
        plot(repmat(clickTimesMs(iClick),1,2),[0,1],'color',CLICK_COLOR,'LineWidth',CLICK_LINE_WIDTH);
    end
    ylim([0,1])
    xlim(timeMsLimits);
    set(gca,'XTick',[],'YTick',[]);
    set(gca,'FontSize',FONT_SIZE);
    set(gca,'XColor','none')
    title(sprintf('%d Clicks/s',clickRateHz(iClickRate)));
end
%%
figPath = [figDir filesep figName];
print(gcf,[figPath '.png'],'-dpng','-r600')
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r600')
savefig(figPath);
close(hFig)

function currentStateXLoc = plotBarAndPoints(values, xLoc, xJitterRange, nReps, ...
    markerPixels, exampleUnits, iExamplePerUnit,barColor,maxAbsValueToPlot)

if ~exist('barColor','var') || isempty(barColor)
    barColor = [0.85,0.85,0.85];
end
if exist('maxAbsValueToPlot','var')
    values(abs(values)>maxAbsValueToPlot) = maxAbsValueToPlot*sign(values(abs(values)>maxAbsValueToPlot));
end

BAR_LINE_WIDTH = 1.5; %1.25;
MARKER_FACE_COLOR = [0.65,0.65,0.65];
MARKER_EDGE_COLOR = MARKER_FACE_COLOR;%'none'; %'k';
SEM_LINE_WIDTH = 4.5; %4.5;
SEM_COLOR = 'k';
BAR_WIDTH = 0.95;

meanVal = nanmean(values);
sem = nanstd(values)./sqrt(sum(~isnan(values)));
currentStateXLoc = xLoc+dispersePointsByAxis(values,xJitterRange,nReps,markerPixels);
bar(xLoc,meanVal,BAR_WIDTH,'FaceColor',barColor)%,'LineWidth',2);

isExampleUnit = ~isnan(iExamplePerUnit);

plot(currentStateXLoc(~isExampleUnit),values(~isExampleUnit),'o','MarkerSize',markerPixels,...
    'MarkerFaceColor', MARKER_FACE_COLOR,'MarkerEdgeColor',MARKER_EDGE_COLOR,'LineWidth',0.25)
bar(xLoc,meanVal,BAR_WIDTH,'FaceColor','none','LineWidth',BAR_LINE_WIDTH);
plot([xLoc,xLoc],[meanVal-sem,meanVal+sem],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
1;

function plotExamplePoints(values,stateXLoc,markerPixels,exampleUnits,iExamplePerUnit,maxAbsValueToPlot)

if exist('maxAbsValueToPlot','var')
    values(abs(values)>maxAbsValueToPlot) = maxAbsValueToPlot*sign(values(abs(values)>maxAbsValueToPlot));
end
isExampleUnit = ~isnan(iExamplePerUnit);

iUnitsForExamples = find(isExampleUnit);
nExampleUnits = length(iUnitsForExamples);
for iUnit = 1:nExampleUnits
    iCurrentUnit = iUnitsForExamples(iUnit);
    iCurrentExample = iExamplePerUnit(iCurrentUnit);
    currentColor = exampleUnits(iCurrentExample).color;
    plot(stateXLoc(iCurrentUnit),values(iCurrentUnit),'o','MarkerSize',markerPixels,...
        'MarkerFaceColor', currentColor,'MarkerEdgeColor',currentColor,'LineWidth',1.5)
end

1;

function plotPointsPerSess(values,xLoc,xJitterRange,nReps,markerPixels,sessionPerValue,minUnitsPerSess,contextSessionsStr,markerAnimalMap)
%% plot Points per session but black&White

BAR_LINE_WIDTH = 1.25;
MARKER_EDGE_COLOR = 'k'; %[0.5,0.5,0.5];
SEM_LINE_WIDTH = 4.5;
SEM_COLOR = 'k';
BAR_WIDTH = 0.95;
ALPHA_SCATTER = 0.87; %0.8;

animalColors = Consts.ANIMAL_COLORS;
sessionMarkers = {'o','^','s','d'};

MARKER_FACE_COLOR = [0.4,0.4,0.4];

edgeColorMarkerContext = 'k';
edgeColorMarkerComplex = MARKER_FACE_COLOR;

[sessionsStr,~,iSessionPerUnit] = unique(sessionPerValue);
nSessions = length(sessionsStr);
meanValPerSess = nan(nSessions,1);
isSessWithEnoughUnits = false(nSessions,1);

for iSess = 1:nSessions
    isSessWithEnoughUnits(iSess) = sum(iSessionPerUnit==iSess)>=minUnitsPerSess;
    meanValPerSess(iSess) = nanmean(values(iSessionPerUnit==iSess));
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end

[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);

meanValAllSess = nanmean(meanValPerSess);
sem = nanstd(meanValPerSess)./sqrt(sum(~isnan(meanValPerSess)));
currentStateXLoc = xLoc+dispersePointsByAxis(meanValPerSess,xJitterRange,nReps,markerPixels);

for iAnimal = 1:nAnimals
    iCurrentAnimalSession = find(iAnimalPerSession==iAnimal);
    currentAnimalMarker = markerAnimalMap(animalStr{iAnimal});
    nSessionsForCurrentAnimal = length(iCurrentAnimalSession);
    for iSessInCurrAnimal = 1:nSessionsForCurrentAnimal
        iCurrSess = iCurrentAnimalSession(iSessInCurrAnimal);
        
        if ~isSessWithEnoughUnits(iCurrSess)
            continue;
        end
        
        currentSessStr = sessionsStr(iCurrSess);
        isCurrentSessContext = any(strcmp(contextSessionsStr,currentSessStr));
        if isCurrentSessContext
            currentEdgeColor = edgeColorMarkerContext;
        else
            currentEdgeColor = edgeColorMarkerComplex;
        end
        hScatter = scatter(currentStateXLoc(iCurrSess),meanValPerSess(iCurrSess),markerPixels^2,...
            currentAnimalMarker,'MarkerFaceColor',MARKER_FACE_COLOR,'MarkerEdgeColor',...
            currentEdgeColor,'LineWidth',1.1);%0.25);
        hScatter.MarkerFaceAlpha = ALPHA_SCATTER;
        hScatter.MarkerEdgeAlpha = ALPHA_SCATTER;
    end
end

meanValUnits = nanmean(values);
semUnits = nanstd(values)./sqrt(sum(~isnan(values)));
plot([xLoc,xLoc],[meanValUnits-semUnits,meanValUnits+semUnits],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)

1;