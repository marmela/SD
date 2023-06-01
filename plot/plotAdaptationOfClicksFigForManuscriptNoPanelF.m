function plotAdaptationOfClicksFigForManuscriptNoPanelF(statesData, isSigUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnit)

figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'ClickRatesFig'];
makeDirIfNeeded(figDir);
figName = 'ClickRatesFig';
clickRateHz = [2,10,20,30,40];
figPositions =  [10,50,950*0.85,950]; 
fontMultiplierForWidth = figPositions(3)/1000;

%% Panels Positions
FONT_SIZE_LETTER = 26.*fontMultiplierForWidth;%26;
panelLetterXShift = -0.05; %-0.028;
panelLetterYShift = 0.02; %0.01;
PSTH_HEIGHT = 0.11;
RASTER_HEIGHT = 0.23;
STIM_CLICKS_HEIGHT = 0.008; %0.012;
X_PANEL_CLICKS_EX = 0.08; %0.055;
Y_PANEL_CLICKS_EX = 0.62;
WIDTH_PANEL_CLICKS_EX = 0.178;
INTER_PANEL_WIDTH_CLICKS_EX = 0.005; %0.01;
STIM_CLICKS_SPACING_FROM_RASTER = 0.002;
INTER_PANEL_WIDTH_POPULATION = 0.08;
INTER_PANEL_WIDTH_CLICKS_POPULATION = 0.02;
MODULATION_PANEL_HEIGHT = 0.25;
Y_PANEL_MODULATION = 0.32;
RATE_FIT_HEIGHT = 0.19;
RATE_FIT_WIDTH = 0.368; %0.24;
Y_PANEL_RATE_FIT = 0.06;

%% Various Figure Properties
figProperties.psthLineWidth = 1.3*fontMultiplierForWidth; %1.5; %PSTH_LINE_WIDTH
figProperties.xTickPsthMs = [0,500]; %XTICK_PSTH_MS
figProperties.timeMsLimits = [-200,600]; %timeMsLimits
figProperties.fontSize = 13.5.*fontMultiplierForWidth; %12;
figProperties.stateFontSize = 15.*fontMultiplierForWidth; %16; %STATE_FONT_SIZE
figProperties.clicks.color = 'k';
figProperties.clicks.lineWidth = figProperties.psthLineWidth*1.5;
clicks.rateHz = [2,10,20,30,40];
clicks.iRateToPlot = 1:length(clicks.rateHz);
clicks.lengthMs = 500;
iShading = 1;
shadingProperties(iShading).timesMs = [130,530];
shadingProperties(iShading).alpha = 0.3;
shadingProperties(iShading).color = [90	60	0]/95;
shadingProperties(iShading).iClickTrains = 1:length(clicks.rateHz);

%%
barsProperties.markerPixels = 2.6.*fontMultiplierForWidth; %2.2.*fontMultiplierForWidth; %3
barsProperties.markerPixelsSess = 8.*fontMultiplierForWidth; %7.5.*fontMultiplierForWidth; %9 %markerPixels*2.5; %1.92;
barsProperties.xJitterRange = 0.95;
barsProperties.sizeRatioState = 1.45;
barsProperties.nReps = 10000; 

%%
fitProperties.lineWidth = 3*fontMultiplierForWidth; %3
fitProperties.markerSize = 37*fontMultiplierForWidth; %30
fitProperties.marker = '.';
fitProperties.fitMarkerSize = 22*fontMultiplierForWidth; %18;
fitProperties.fitMarker = '+';    
fitProperties.fitMarkerLineWidth = 3*fontMultiplierForWidth; %3;
fitProperties.fitNormalizedResponse = 0.25;

%% analyze only context paradigm where there were multiple click rates 
sessionStr = extractfield(statesData{1}.sessData,'session');
isContextSess = cell2mat(extractfield(statesData{1}.sessData,'isContext'));
contextSessionsStr = sessionStr(isContextSess);
isContextUnit = cell2mat(extractfield(statesData{1}.unitData,'isContext')');
isValidUnit = isContextUnit & isSigUnit;

%%
 [stats,plotData,plotDataFit,iExamplePerUnit] = calcClickLockingPerRateAndStats(statesData, ...
     isValidUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnit,clicks.rateHz);
statesInfo = cell2mat(extractfield(cell2mat(statesData),'info'));
statsPath = [figDir filesep figName '_stats'];
save(statsPath,'stats','statesInfo','plotData','plotDataFit','iExamplePerUnit');

%% get Example Raster + PSTH Data
nStates = length(statesData);
for iState = nStates:-1:1
    statesInfo(iState) = statesData{iState}.info;
end
exampleData = getExampleRasterAndPsth(exampleUnit,statesInfo);

%% Calculate Positions 
%per  example panel
Y_RASTER = Y_PANEL_CLICKS_EX+PSTH_HEIGHT;
Y_STIM_CLICKS = Y_RASTER+RASTER_HEIGHT+STIM_CLICKS_SPACING_FROM_RASTER;
nPanels = length(clicks.rateHz);
for iPanel = 1:nPanels
    currentPanelX = X_PANEL_CLICKS_EX+(WIDTH_PANEL_CLICKS_EX+INTER_PANEL_WIDTH_CLICKS_EX)*(iPanel-1);
    positionsPerPanel.psth{iPanel} = [...
        currentPanelX, Y_PANEL_CLICKS_EX, WIDTH_PANEL_CLICKS_EX, PSTH_HEIGHT];
    positionsPerPanel.raster{iPanel} = [...
        currentPanelX, Y_RASTER, WIDTH_PANEL_CLICKS_EX, RASTER_HEIGHT];
    positionsPerPanel.stimClicks{iPanel} = [...
        currentPanelX,Y_STIM_CLICKS,WIDTH_PANEL_CLICKS_EX,STIM_CLICKS_HEIGHT]; 
end
% per clicks-modulation per rate panel
totalFigWidth = positionsPerPanel.psth{end}(1)+WIDTH_PANEL_CLICKS_EX-X_PANEL_CLICKS_EX;
nPopPanels = 2;
clicksModulationPopPanelWidth = (totalFigWidth-INTER_PANEL_WIDTH_CLICKS_POPULATION*(nPopPanels-1))/nPopPanels;
for iPanel=nPopPanels:-1:1
    currentPanelX = X_PANEL_CLICKS_EX+(clicksModulationPopPanelWidth+INTER_PANEL_WIDTH_CLICKS_POPULATION)*(iPanel-1);
    positionsPerModulationPanel{iPanel} = [currentPanelX,Y_PANEL_MODULATION, clicksModulationPopPanelWidth, MODULATION_PANEL_HEIGHT];
end
% Last Row - Adaptation rate Fit
positionRateFitExample = [X_PANEL_CLICKS_EX, Y_PANEL_RATE_FIT, RATE_FIT_WIDTH, RATE_FIT_HEIGHT];
for iPanel=nPopPanels:-1:1
    adaptedRatePopWidth = RATE_FIT_HEIGHT*(1.2-0.03684); %panel should be percieved close to a square.
    currentPanelX = X_PANEL_CLICKS_EX+RATE_FIT_WIDTH+INTER_PANEL_WIDTH_POPULATION+...
        (adaptedRatePopWidth+INTER_PANEL_WIDTH_CLICKS_EX*4)*(iPanel-1);
    positionsPerAdaptedRatePanel{iPanel} = [currentPanelX,Y_PANEL_RATE_FIT, adaptedRatePopWidth, RATE_FIT_HEIGHT];
end
xPanelCorrRateVsModulation = positionsPerAdaptedRatePanel{end}(1)+...
    positionsPerAdaptedRatePanel{end}(3)+INTER_PANEL_WIDTH_POPULATION;
% Panel F was Removed to symplify figure/main-text
    % positionCorrRateVsModulation = [xPanelCorrRateVsModulation,Y_PANEL_RATE_FIT, ...
    %     X_PANEL_CLICKS_EX+totalFigWidth-xPanelCorrRateVsModulation, RATE_FIT_HEIGHT];

%% Plot Fig
figure('Position',figPositions);

%% Plot 5 examples Rasters+PSTH
plotRastersAndPsthExamples(exampleData,positionsPerPanel,statesInfo, ...
    figProperties, clicks, shadingProperties)

%%
%% plot clicks modulation/gain index per unit 
for iState = nStates:-1:1
    states(iState) = statesData{iState}.info.state; 
    statesInfo(iState) = statesData{iState}.info;
end
iSdLow = find(states==State.SD1,1,'first');
iSdHigh = find(states==State.SD3,1,'first');
iNrem = find(states==State.NREM,1,'first');

iStatesToPlot = [iSdHigh,iSdLow];
plotLockingModulationPerClickRate(plotData(iStatesToPlot(1),iStatesToPlot(2)),...
    positionsPerModulationPanel{1}, exampleUnit, iExamplePerUnit, minUnitsPerSess, ...
    contextSessionsStr, barsProperties, figProperties, clicks, statesInfo(iStatesToPlot))

iStatesToPlot = [iNrem,iSdLow];
plotLockingModulationPerClickRate(plotData(iStatesToPlot(1),iStatesToPlot(2)),...
    positionsPerModulationPanel{2}, exampleUnit, iExamplePerUnit, minUnitsPerSess, ...
    contextSessionsStr, barsProperties, figProperties, clicks, statesInfo(iStatesToPlot))

%% Plot Sigmoid Fit for adaptation per rate
plotAdaptationPerClickRateFitExample(plotDataFit,iExamplePerUnit,statesInfo,positionRateFitExample,clicks, fitProperties, figProperties)

iStatesToPlot = [iSdHigh,iSdLow];
plotAdaptedRatePerStatePopulation(plotData(iStatesToPlot(1),iStatesToPlot(2)),positionsPerAdaptedRatePanel{1},...
    exampleUnit,iExamplePerUnit,statesInfo(iStatesToPlot),figProperties,minUnitsPerSess,contextSessionsStr,true)

iStatesToPlot = [iNrem,iSdLow];
plotAdaptedRatePerStatePopulation(plotData(iStatesToPlot(1),iStatesToPlot(2)),positionsPerAdaptedRatePanel{2},...
    exampleUnit,iExamplePerUnit,statesInfo(iStatesToPlot),figProperties,minUnitsPerSess,contextSessionsStr,false)

% Panel F was Removed to symplify figure/main-text
% iStatesToPlot = [iNrem,iSdLow];
% plotStateModulationVsAdaptedRate(plotData(iStatesToPlot(1),iStatesToPlot(2)),statesInfo(iStatesToPlot),positionCorrRateVsModulation,figProperties,barsProperties,clickRateHz)

%% Plot Panels Letters
panelLetterXShiftShort = -0.005;
annotation('textbox', [X_PANEL_CLICKS_EX+panelLetterXShift, Y_PANEL_CLICKS_EX+PSTH_HEIGHT+RASTER_HEIGHT+STIM_CLICKS_HEIGHT+panelLetterYShift, 0, 0],...
    'string', 'A','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [positionsPerModulationPanel{1}(1)+panelLetterXShift, Y_PANEL_MODULATION+MODULATION_PANEL_HEIGHT+panelLetterYShift, 0, 0],...
    'string', 'B','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [positionsPerModulationPanel{2}(1)+panelLetterXShiftShort, Y_PANEL_MODULATION+MODULATION_PANEL_HEIGHT+panelLetterYShift, 0, 0],...
    'string', 'C','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox', [positionRateFitExample(1)+panelLetterXShift, Y_PANEL_RATE_FIT+RATE_FIT_HEIGHT+panelLetterYShift, 0, 0],...
    'string', 'D','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

annotation('textbox',  [positionsPerAdaptedRatePanel{1}(1)+panelLetterXShift, Y_PANEL_RATE_FIT+RATE_FIT_HEIGHT+panelLetterYShift, 0, 0],...
    'string', 'E','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

% Panel F was Removed to symplify figure/main-text
% annotation('textbox',  [positionCorrRateVsModulation(1)+panelLetterXShift, Y_PANEL_RATE_FIT+RATE_FIT_HEIGHT+panelLetterYShift, 0, 0],...
%     'string', 'F','FontSize',FONT_SIZE_LETTER,'FontWeight','Bold','HorizontalAlignment','center','VerticalAlignment','middle')

%%
makeDirIfNeeded(figDir);
figPath = [figDir filesep figName];
% hgexport(gcf,figPath ,hgexport('factorystyle'), 'Format', 'png');
print(gcf,[figPath '.png'],'-dpng','-r600')
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r600')
savefig(figPath);
close(gcf)


function plotStateModulationVsAdaptedRate(plotData,statesInfo,positionCorrRateVsModulation,figProperties,barsProperties,clickRateHz)

clicks.rateHz = [2,10,20,30,40];
clicks.iRateToPlot = 1:length(clicks.rateHz);
clicks.lengthMs = 500;

iShading = 1;
shadingProperties(iShading).timesMs = [130,530];
shadingProperties(iShading).alpha = 0.3;
shadingProperties(iShading).color = [90	60	0]/95;
shadingProperties(iShading).iClickTrains = 1:length(clicks.rateHz);

%%
barsProperties.xJitterRange = 0.95;
barsProperties.sizeRatioState = 1.45;
barsProperties.nReps = 100; %10000;

subplot('position',positionCorrRateVsModulation);
hold on;
iRelevantClickTrains = 2:5;
XLIM = [iRelevantClickTrains(1)-0.5,iRelevantClickTrains(end)+0.5];
YLIM = [0,100];
xlim(XLIM)
ylim(YLIM)

for iClickTrain = iRelevantClickTrains
    clickTrainStr{iClickTrain} = sprintf('%d Hz',clickRateHz(iClickTrain));
    
    currentAdaptedClickRate = plotData.adaptationRateVsModulation.quarterResponseRate(...
        plotData.adaptationRateVsModulation.maxModulationRate==clickRateHz(iClickTrain)); %clickRateOf25PercentResponseMatchedToGain(iClickMaxModulationByState==iClickTrain);
    plotBarAndPoints(currentAdaptedClickRate,iClickTrain,barsProperties.xJitterRange,...
        barsProperties.nReps,barsProperties.markerPixels) ;
end

ylabel(['\bf\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' statesInfo(2).str '\rm\color[rgb]{0,0,0} adapted rate(Hz)    ' ]);
set(gca,'XTick',iRelevantClickTrains,'XTickLabel',clickRateHz(iRelevantClickTrains));
xlabel(['\bf\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str '\rm\color[rgb]{0,0,0} max   ' newline 'attenuation rate (Hz)      '])% xlabel('Click Rate (Hz) of Max. Modulation across States');
set(gca,'FontSize',figProperties.fontSize);
set(gca,'YTick',[0:20:100]);
grid on

function plotAdaptedRatePerStatePopulation(plotData,subplotPosition, exampleUnit, iExamplePerUnit, ...
    statesInfo, figProperties, minUnitsPerSess, contextSessionsStr, isPlotYTicksAndLabel)

adaptedRateProperties.markerPixels = 4;
adaptedRateProperties.markerPixelsSess = 10;
adaptedRateProperties.diagonalColor = 'k';
adaptedRateProperties.diagonalWidth = 1;

%% plot Units
MARKER_FACE_COLOR = [0.65,0.65,0.65];
MARKER_EDGE_COLOR = MARKER_FACE_COLOR;%'none'; %'k';
rateLimis = [7,120];

subplot('position',subplotPosition);
hold on;
plot(rateLimis,rateLimis,'color',adaptedRateProperties.diagonalColor,'LineWidth',adaptedRateProperties.diagonalWidth);
plot(plotData.rateOfQuarterResponse.ratePerUnit(1,:),plotData.rateOfQuarterResponse.ratePerUnit(2,:),...
    'o','MarkerSize',adaptedRateProperties.markerPixels,...
    'MarkerFaceColor', MARKER_FACE_COLOR,'MarkerEdgeColor',MARKER_EDGE_COLOR,'LineWidth',0.25)
set(gca,'XScale','log','YScale','log')
xlabel(['\bf\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',...
  statesInfo(1).color) '}' statesInfo(1).str])
if isPlotYTicksAndLabel
    ylabel(['\bf\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',...
    statesInfo(2).color) '}' statesInfo(2).str])
end

iUnitExample = find(iExamplePerUnit.rateAdaptation==1,1,'first');
plot(plotData.rateOfQuarterResponse.ratePerUnit(1,iUnitExample),...
    plotData.rateOfQuarterResponse.ratePerUnit(2,iUnitExample),...
    'o','MarkerSize',adaptedRateProperties.markerPixels,...
    'MarkerFaceColor', exampleUnit.color,'MarkerEdgeColor',exampleUnit.color,'LineWidth',0.25)
xlim(rateLimis);
ylim(rateLimis);
XYTicks = [5,10,20,40,80];
set(gca,'XTick',XYTicks);
if isPlotYTicksAndLabel
    set(gca,'YTick',XYTicks);
else
    set(gca,'YTick',[]);
end

%% plot sessions
MARKER_FACE_COLOR = [0.4,0.4,0.4];
edgeColorMarkerContext = 'k';
edgeColorMarkerComplex = MARKER_FACE_COLOR;
ALPHA_SCATTER = 0.87; %0.8;
SEM_LINE_WIDTH = 2.5;
SEM_COLOR = [0.9290 0.6940 0.1250];

[sessionsStr,~,iSessionPerUnit] = unique(plotData.rateOfQuarterResponse.sessionPerUnit);
nUnits = length(iSessionPerUnit);
nSessions = length(sessionsStr);
meanValPerSessAndState = nan(nSessions,2);
isSessWithEnoughUnits = false(nSessions,1);

for iSess = 1:nSessions
    isSessWithEnoughUnits(iSess) = sum(iSessionPerUnit==iSess)>=minUnitsPerSess;
    meanValPerSessAndState(iSess,:) = nanmean(plotData.rateOfQuarterResponse.ratePerUnit(:,iSessionPerUnit==iSess),2);
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end

[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);
for iAnimal = 1:nAnimals
    iCurrentAnimalSession = find(iAnimalPerSession==iAnimal);
    currentAnimalMarker = Consts.MARKER_ANIMAL_MAP(animalStr{iAnimal});
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
        hScatter = scatter(meanValPerSessAndState(iCurrSess,1),meanValPerSessAndState(iCurrSess,2),...
            adaptedRateProperties.markerPixelsSess ^2,currentAnimalMarker,'MarkerFaceColor',...
            MARKER_FACE_COLOR,'MarkerEdgeColor',currentEdgeColor,'LineWidth',1.1);%0.25);
        hScatter.MarkerFaceAlpha = ALPHA_SCATTER;
        hScatter.MarkerEdgeAlpha = ALPHA_SCATTER;
        
    end
end
if isPlotYTicksAndLabel
    title('                                           Adapted rate (Hz)')
end
meanRatePerState = nanmean(plotData.rateOfQuarterResponse.ratePerUnit');
semUnits = nanstd(plotData.rateOfQuarterResponse.ratePerUnit')./sqrt(nUnits);
plot(meanRatePerState(1)+[-semUnits(1),semUnits(1)],ones(1,2).*meanRatePerState(2),'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
plot(ones(1,2).*meanRatePerState(1),meanRatePerState(2)+[-semUnits(2),semUnits(2)],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
set(gca,'FontSize',figProperties.fontSize)

function plotAdaptationPerClickRateFitExample(plotDataFit,iExamplePerUnit,statesInfo,positionRateFitExample, clicks,fitProperties, figProperties)
    iUnitExample = find(iExamplePerUnit.rateAdaptation==1,1,'first');
    decayPerState = plotDataFit.decayPerHz(:,iUnitExample);
    x0SigmoidPerState = log10(plotDataFit.clickRateOfHalfResponse(:,iUnitExample));
    clickRate25PercentPerState = plotDataFit.clickRate25Percent(:,iUnitExample);
    
    XLIM = log10([1.5,100]);
    clickRatesToPredict = 10.^(log10(1):0.01:log10(100)); %[0.5,1,2,5,10,15,20,25,30,35,40,45,50,60,70,80,100];
    nStates = length(statesInfo);
    subplot('position',positionRateFitExample)
    hold on;
    for iState = 1:nStates
        yPredicted = 1./(1+exp(decayPerState(iState).*(...
            log10(clickRatesToPredict)-x0SigmoidPerState(iState))));
        plot(log10(clickRatesToPredict),yPredicted,'color',statesInfo(iState).color,'LineWidth',fitProperties.lineWidth);
        plot(log10(clicks.rateHz),plotDataFit.normalizedResponsePerStateAndUnit{iState,iUnitExample},fitProperties.marker,'color',...
            statesInfo(iState).color,'MarkerSize',fitProperties.markerSize,'LineWidth',fitProperties.lineWidth);
        plot(log10(clickRate25PercentPerState(iState)),fitProperties.fitNormalizedResponse,fitProperties.fitMarker,'color',...
            statesInfo(iState).color,'MarkerSize',fitProperties.fitMarkerSize,'LineWidth',fitProperties.fitMarkerLineWidth);
        
    end
    plot(XLIM,ones(1,2)*fitProperties.fitNormalizedResponse,'--k')
    
    clickRateXTick = [1,2,5,10,20,30,40,80];
    clickRateXTickStr = {'1','2','5','10','20','','40','80'};
    xTick = log10(clickRateXTick);
    ax = gca();
    ax.XTick = xTick;
    ax.XTickLabel = clickRateXTickStr;
    ax.YTick = [0:0.25:1];
    ylabel('Normalized Response');
    xlabel('Click Rate (Hz)');
    set(gca,'FontSize',figProperties.fontSize)
    grid on
    
    clickRateHzLegend = 50;
    for iState = 1:nStates
        text(log10(clickRateHzLegend),1.05-iState*0.11,['\bf\fontsize{' ...
            num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',...
            statesInfo(iState).color) '}' statesInfo(iState).str],'HorizontalAlignment','center');
    end
    xlim(XLIM);

function plotLockingModulationPerClickRate(plotData, subplotPosition,  exampleUnit, ...
    iExamplePerUnit, minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, clicks, statesInfo)

gainIndex = plotData.lockedFrModulation.gainIndexPerUnit;
nMeasures = length(gainIndex);
XLIM = [0.5,nMeasures+0.5];
YLIM = [-100,100]; %[-1,1];
subplot('position',subplotPosition);
hold on;
xlim(XLIM)
ylim(YLIM)
for iMeasure = 1:nMeasures
    colorAfterAlpha = [];
    xLocCurrentMeasure = plotBarAndPoints(gainIndex{iMeasure},iMeasure,...
        barsProperties.xJitterRange,barsProperties.nReps,barsProperties.markerPixels,...
        iExamplePerUnit.lockingModulation,colorAfterAlpha);
    plotPointsPerSess(gainIndex{iMeasure},iMeasure,barsProperties.xJitterRange,barsProperties.nReps,...
        barsProperties.markerPixelsSess,plotData.lockedFrModulation.sessionPerUnit,minUnitsPerSess,...
        contextSessionsStr,Consts.MARKER_ANIMAL_MAP) 
    plotExamplePoints(gainIndex{iMeasure},xLocCurrentMeasure,...
       barsProperties. markerPixels,exampleUnit,iExamplePerUnit.lockingModulation);
end

text(1.6,90,['\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str '>' ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' statesInfo(2).str],'HorizontalAlignment','center');
text(1.6,-90,['\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str  ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' '<' statesInfo(2).str],'HorizontalAlignment','center');

xTickLabels = cell(nMeasures,1);
for iMeasure = 1:nMeasures
    xTickLabels{iMeasure} = sprintf('%d Hz',clicks.rateHz(iMeasure));
end
set(gca,'XTick',1:nMeasures,'XTickLabel',xTickLabels);%measuresLabels);
set(gca,'FontSize',figProperties.fontSize);
set(gca,'YTick',-100:20:100)
%if first plot on the right
if (subplotPosition(1)<0.3)
    ylabel('Modulation Index (%)');
else
    set(gca,'YTickLabel',{})
end
grid on

