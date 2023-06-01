function plotRemFigForManuscript(statesData, isSigUnitTuning, isSigUnitClicks, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning, exampleUnitClicks)


figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'RemFig'];
makeDirIfNeeded(figDir);
figName = 'RemFig';

%%
figPositions = [10,50,950*0.85,950]; 
fontMultiplierForWidth = figPositions(3)/1000;

figProperties.fontSize = 13.5.*fontMultiplierForWidth; 
figProperties.stateFontSize = 15.*fontMultiplierForWidth; 
figProperties.tuning.examplePlotLineWidth = 1.8*fontMultiplierForWidth; %1;
figProperties.tuning.examplePlotArrowHeadWidth = 3; %2;
figProperties.tuning.examplePlotArrowHeadLength = 3; %2;

figProperties.clicks.color = 'k';
figProperties.clicks.lineWidth = 2.5*fontMultiplierForWidth;
figProperties.psthLineWidth = 1.3*fontMultiplierForWidth;
figProperties.xTickPsthMs = [0,500];
figProperties.timeMsLimits = [-200,600];

clicks.rateHz = [2,10,20,30,40];
clicks.iRateToPlot = [1,5];
clicks.lengthMs = 500;

barsProperties.markerPixels = 2.2.*fontMultiplierForWidth; 
barsProperties.markerPixelsSess = 7.5.*fontMultiplierForWidth; 
barsProperties.xJitterRange = 0.95;
barsProperties.sizeRatioState = 1.45;
barsProperties.nReps = 10000; 
barsProperties.shadingAlpha = 0.3;
barsProperties.xStateText = 1.2;

fitProperties.lineWidth = 3*fontMultiplierForWidth; %2;
fitProperties.markerSize = 37*fontMultiplierForWidth; %30;
fitProperties.marker = '.';
fitProperties.fitMarkerSize = 22*fontMultiplierForWidth; %18;
fitProperties.fitMarker = '+';    
fitProperties.fitMarkerLineWidth = 3*fontMultiplierForWidth; %3;
fitProperties.fitNormalizedResponse = 0.25;

iShading = 1;
shadingProperties(iShading).timesMs = [130,530];
shadingProperties(iShading).alpha = barsProperties.shadingAlpha;
shadingProperties(iShading).color = [90	60	0]/95;
shadingProperties(iShading).iClickTrains = 5;

iShading = 2;
shadingProperties(iShading).timesMs = [30,80];
shadingProperties(iShading).alpha = barsProperties.shadingAlpha;
shadingProperties(iShading).color = [0	60	50]*0.85/95;
shadingProperties(iShading).iClickTrains = 1;

% color per: spon. FR, onset FR, pop. sync, 40Hz locking, post-onset FR
colorPerMeasure = {[],[],[],shadingProperties(1).color ,shadingProperties(2).color};

panelLetterXShift = -0.055; %-0.03;
panelLetterYShift = 0.016; %0.007;

FONT_SIZE_LETTER = 26.*fontMultiplierForWidth; %26/1400*figPositions(3);

StrfRowY = 0.815; %0.86;
strfHeight =  0.155;% 0.115;
distanceBetweenExamplePlots = 0.005;
exampleTuningPlotWidth = 0.035;
exampleStrfWidth = 0.15; %0.18;
examplesX = 0.08; %0.055;
endFigureX = 0.985;

colorBarWidth = 0.015;

interPanelWidth = 0.11; %0.08;
interPanelWidthNoLabel = 0.05;
interRasterWidth = distanceBetweenExamplePlots;
interScatterWidth = 0.025;

firstRowY = 0.58; %0.645;
barsPopulationHeight = 0.17;
clicksPopulationHeight = 0.195;

psthHeight = 0.11;
stimClicksHeight = 0.012;

interPanelHeight = 0.095; %0.049;
yFigStart = 0.055; %0.04;


%%
sessionStr = extractfield(statesData{1}.sessData,'session');
isContextSess = cell2mat(extractfield(statesData{1}.sessData,'isContext'));
contextSessionsStr = sessionStr(isContextSess);
isContextUnit = cell2mat(extractfield(statesData{1}.unitData,'isContext'))';


nStates = length(statesData);
iStateRem = 0;
for iState = 1:nStates
   if  statesData{iState}.info.state == State.REM
       iStateRem = iState;
   end
   statesInfo(iState) = statesData{iState}.info;
end
 [statsAdaptation,plotData,plotDataFit,iExamplePerUnitClickLocking] = calcClickLockingPerRateAndStats(statesData, ...
     isSigUnitClicks & isContextUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitClicks, clicks.rateHz);

assert(iStateRem>0);
stateDataRem = statesData{iStateRem};
iStatesNotRem = [1:iStateRem-1,iStateRem+1:nStates];
stateDataOther = statesData(iStatesNotRem);
nOtherStates = length(stateDataOther);
clear statesData

stateDataToCompareVsRem = stateDataOther{1};
[statsTuning,tuningPlotData] = calcTuningCorrelationAndStats(stateDataRem, stateDataToCompareVsRem, ...
    isSigUnitTuning, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning);
statesTuningInfo = [stateDataRem.info, stateDataToCompareVsRem.info];

for iOtherState = 1:nOtherStates
    [statsClicks{iOtherState},clicksPlotData{iOtherState}] = calcClickResponsesAndStats(...
        stateDataRem, stateDataOther{iOtherState}, isSigUnitClicks, minUnitsPerAnimal, ...
        minUnitsPerSess, exampleUnitClicks, statesInfo);
    
    statesInfoRemVsOther{iOtherState} = [stateDataRem.info, stateDataOther{iOtherState}.info];
end

statsPath = [figDir filesep figName '_stats'];

statsForAdaptation.stats = statsAdaptation;
statsForAdaptation.plotData = plotData;
statsForAdaptation.plotDataFit = plotDataFit;
statsForAdaptation.iExamplePerUnit = iExamplePerUnitClickLocking;
statsForAdaptation.statesInfo = statesInfo;

statsForTuning.stats = statsTuning;
statsForTuning.statesInfo = statesTuningInfo;

statsForClicks.stats = statsClicks;
statsForClicks.statesInfo = statesInfoRemVsOther;
save(statsPath,'statsForClicks','statsForTuning','statsForAdaptation');


%% Subplot Poistions
examplePlotPosition{2} = [examplesX,StrfRowY,exampleTuningPlotWidth,strfHeight];
examplePlotPosition{1} = [examplesX+exampleTuningPlotWidth+exampleStrfWidth+distanceBetweenExamplePlots,...
    StrfRowY,exampleTuningPlotWidth,strfHeight];

exampleStrfPosition{2} = [examplesX+exampleTuningPlotWidth,StrfRowY,exampleStrfWidth,strfHeight];
exampleStrfPosition{1} = [examplesX+exampleStrfWidth+exampleTuningPlotWidth*2+distanceBetweenExamplePlots,...
    StrfRowY,exampleStrfWidth,strfHeight];
exampleColorBarPos = [exampleStrfPosition{1}(1)+exampleStrfWidth+distanceBetweenExamplePlots,...
    StrfRowY,colorBarWidth,strfHeight];

totalTuningWidth = exampleColorBarPos(1)+exampleColorBarPos(3)-examplesX;
tuningWidthPopulationPanelWidth = (totalTuningWidth-interPanelWidth)./4;
tuningWidthPopulationPosition = [examplesX,firstRowY,tuningWidthPopulationPanelWidth,...
    barsPopulationHeight];
tuningCorrPopulationPosition = [examplesX+tuningWidthPopulationPanelWidth+interPanelWidth,...
    firstRowY,tuningWidthPopulationPanelWidth*3,barsPopulationHeight];

% example rasters+Psths positions
xRasters = tuningCorrPopulationPosition(1)+tuningCorrPopulationPosition(3)+interPanelWidth;
nRasters = 2;
widthRasters = (endFigureX-xRasters-interRasterWidth*(nRasters-1))/nRasters;
totalHeightFirstRow = StrfRowY+strfHeight-firstRowY;
rasterHeight = totalHeightFirstRow-psthHeight-stimClicksHeight;
for iPanel = 1:nRasters
    currentPanelX = xRasters+(widthRasters+interRasterWidth)*(iPanel-1);
    positionsPerClickEx.psth{iPanel} = [...
        currentPanelX, firstRowY, widthRasters, psthHeight];
    positionsPerClickEx.raster{iPanel} = [...
        currentPanelX, firstRowY+psthHeight, widthRasters, rasterHeight];
    positionsPerClickEx.stimClicks{iPanel} = [...
        currentPanelX,firstRowY+psthHeight+rasterHeight,widthRasters,stimClicksHeight]; 
end

%
totalFigWidth = endFigureX-examplesX;
barsPopulationPerStateWidth = (totalFigWidth-interPanelWidthNoLabel*(nOtherStates-1))/nOtherStates;
subplotRow = 2;
yClicksFeatures = yFigStart+(barsPopulationHeight+interPanelHeight)*(subplotRow-1);
for iOtherState = nOtherStates:-1:1
    xCurrent = examplesX+(interPanelWidthNoLabel+barsPopulationPerStateWidth)*(iOtherState-1);
    clicksFeaturesPosition{iOtherState} = [xCurrent, yClicksFeatures, ...
        barsPopulationPerStateWidth, clicksPopulationHeight];
end

subplotRow = 1;
yClicksAdaptation = yFigStart+(barsPopulationHeight+interPanelHeight)*(subplotRow-1);

sigmoidFitScatterWidth = barsPopulationHeight*1.2; %create quasi square 
sigmoidFitExampleWidth = totalFigWidth + interScatterWidth - interPanelWidth -...
    (interScatterWidth+sigmoidFitScatterWidth)*nOtherStates;


sigmoidFitExamplePosition = [examplesX, yClicksAdaptation, sigmoidFitExampleWidth, ...
    barsPopulationHeight];
for iOtherState = nOtherStates:-1:1
    xCurrent = examplesX + sigmoidFitExampleWidth + interPanelWidth +...
        (interScatterWidth+sigmoidFitScatterWidth)*(iOtherState-1);
    sigmoidFitScatterPosition{iOtherState} = [xCurrent, yClicksAdaptation, ...
        sigmoidFitScatterWidth,barsPopulationHeight];
end


%% Plot Figures
hFig = figure('Position',figPositions);
plotStrfExamples (tuningPlotData, statesTuningInfo, figProperties, examplePlotPosition, ...
    exampleStrfPosition, exampleColorBarPos)
plotTuningWidthModulationPopulation(tuningPlotData, statesTuningInfo, ...
    tuningWidthPopulationPosition, figProperties, barsProperties, contextSessionsStr)
plotTuningCorrelationPopulation(tuningPlotData, statesTuningInfo, ...
    tuningCorrPopulationPosition, figProperties, barsProperties, contextSessionsStr)
plotRastersAndPsthExamples(clicksPlotData{1}.example, positionsPerClickEx, ...
    statesInfo, figProperties, clicks, shadingProperties, true)

for iOtherState = 1:nOtherStates
    isPlotYAxis = iOtherState == 1;
    plotModulationClickFeaturesPopulation(clicksPlotData{iOtherState}, ...
        clicksFeaturesPosition{iOtherState}, statesInfoRemVsOther{iOtherState} , figProperties, barsProperties, ...
        clicks, colorPerMeasure, contextSessionsStr, isPlotYAxis)
end

% Plot Sigmoid Fit for adaptation per rate
plotAdaptationPerClickRateFitExample(plotDataFit,iExamplePerUnitClickLocking,statesInfo,...
    sigmoidFitExamplePosition, clicks, fitProperties, figProperties)

for iOtherState = 1:nOtherStates
    isPlotYLabel = iOtherState==1;
    plotAdaptedRatePerStatePopulation(plotData(iStateRem,iStatesNotRem(iOtherState)),...
        sigmoidFitScatterPosition{iOtherState},exampleUnitClicks,iExamplePerUnitClickLocking, ...
        statesInfoRemVsOther{iOtherState},figProperties,minUnitsPerSess,contextSessionsStr,...
        isPlotYLabel,true)
end

%% Plot Panels Letters

clickFeatures2Tight = clicksFeaturesPosition{2};
clickFeatures2Tight(1) = clickFeatures2Tight(1)+0.035; %Make letter close to figure because no labels
addPanelsLetters({examplePlotPosition{2},tuningWidthPopulationPosition,...
    tuningCorrPopulationPosition,positionsPerClickEx.stimClicks{1},clicksFeaturesPosition{1},...
    clickFeatures2Tight, sigmoidFitExamplePosition,sigmoidFitScatterPosition{1}},...
    {'A','B','C','D','E','F','G','H'},panelLetterXShift,panelLetterYShift,FONT_SIZE_LETTER)

%% save fig
makeDirIfNeeded(figDir);
figPath = [figDir filesep figName];
print(gcf,[figPath '.png'],'-dpng','-r600')
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r600')
savefig(figPath);
close(gcf)


function plotAdaptedRatePerStatePopulation(plotData,subplotPosition, exampleUnit, iExamplePerUnit, ...
    statesInfo, figProperties, minUnitsPerSess, contextSessionsStr, isPlotYTicksAndLabel,isFlipStates)

adaptedRateProperties.markerPixels = 4;
adaptedRateProperties.markerPixelsSess = 10;
adaptedRateProperties.diagonalColor = 'k';
adaptedRateProperties.diagonalWidth = 1;

%% plot Units
MARKER_FACE_COLOR = [0.65,0.65,0.65];
MARKER_EDGE_COLOR = MARKER_FACE_COLOR;%'none'; %'k';
rateLimis = [7,120];

if isFlipStates
    iState1 = 2;
    iState2 = 1;
else
    iState1 = 1;
    iState2 = 2;
end

subplot('position',subplotPosition);
hold on;
plot(rateLimis,rateLimis,'color',adaptedRateProperties.diagonalColor,'LineWidth',adaptedRateProperties.diagonalWidth);
plot(plotData.rateOfQuarterResponse.ratePerUnit(iState1,:),plotData.rateOfQuarterResponse.ratePerUnit(iState2,:),...
    'o','MarkerSize',adaptedRateProperties.markerPixels,...
    'MarkerFaceColor', MARKER_FACE_COLOR,'MarkerEdgeColor',MARKER_EDGE_COLOR,'LineWidth',0.25)
set(gca,'XScale','log','YScale','log')

xlabel(['\bf\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',...
  statesInfo(iState1).color) '}' statesInfo(iState1).str])
if isPlotYTicksAndLabel
    ylabel(['\bf\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',...
        statesInfo(iState2).color) '}' statesInfo(iState2).str])
end

iUnitExample = find(iExamplePerUnit.rateAdaptation==1,1,'first');
plot(plotData.rateOfQuarterResponse.ratePerUnit(iState1,iUnitExample),...
    plotData.rateOfQuarterResponse.ratePerUnit(iState2,iUnitExample),...
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
if isPlotYTicksAndLabel
    title('                                   Adapted rate (Hz)')
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
        hScatter = scatter(meanValPerSessAndState(iCurrSess,iState1),meanValPerSessAndState(iCurrSess,iState2),...
            adaptedRateProperties.markerPixelsSess ^2,currentAnimalMarker,'MarkerFaceColor',...
            MARKER_FACE_COLOR,'MarkerEdgeColor',currentEdgeColor,'LineWidth',1.1);%0.25);
        hScatter.MarkerFaceAlpha = ALPHA_SCATTER;
        hScatter.MarkerEdgeAlpha = ALPHA_SCATTER;
        
    end
end

meanRatePerState = nanmean(plotData.rateOfQuarterResponse.ratePerUnit');
semUnits = nanstd(plotData.rateOfQuarterResponse.ratePerUnit')./sqrt(nUnits);

plot(meanRatePerState(iState1)+[-semUnits(iState1),semUnits(iState1)],ones(1,2).*meanRatePerState(iState2),'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
plot(ones(1,2).*meanRatePerState(iState1),meanRatePerState(iState2)+[-semUnits(iState2),semUnits(iState2)],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
set(gca,'FontSize',figProperties.fontSize)

1;

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
%     xlimCurr= xlim();
    plot(XLIM,ones(1,2)*fitProperties.fitNormalizedResponse,'--k')
    
    clickRateXTick = [1,2,5,10,20,40,80]; % [1,2,5,10,20,30,40,80];
    xTick = log10(clickRateXTick);
    ax = gca();
    ax.XTick = xTick;
    ax.XTickLabel = clickRateXTick;
    ax.YTick = [0:0.25:1];
    ylabel('Normalized Response');
    xlabel('Click Rate (Hz)');
    set(gca,'FontSize',figProperties.fontSize)
    grid on
    
    clickRateHzLegend = 60;
    for iState = 1:nStates
        text(log10(clickRateHzLegend),1-iState*0.11,['\bf\fontsize{' ...
            num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',...
            statesInfo(iState).color) '}' statesInfo(iState).str],'HorizontalAlignment','center');
    end
    xlim(XLIM);
    1;


function gainIndex = getGainIndex(values1,values2)

assert(isequal(size(values2),size(values1)));

if isrow(values2)
    gainIndex = (values1-values2)./max([values2; values1],[],1);
elseif iscolumn(values2)
    gainIndex = (values1-values2)./max([values2, values1],[],2);
else
    assert(length(size(values2))==2);
    mat3d(:,:,2) = values1;
    mat3d(:,:,1) = values2;
    gainIndex = (values1-values2)./max(mat3d,[],3);
end
    
function dz = getCohensDZ(diffs)
dz = nanmean(diffs)./nanstd(diffs);


function [clickRateInflection, decayPerHz, rms, normalizedResponsePerClickRate] = fitSigmoidToClickLocking2(maxFr, clickRateHz, lockingFrPerClickRate)

lockingFrPerClickRate = makeColumn(lockingFrPerClickRate);
clickRateHz = makeColumn(clickRateHz);
interClickIntervalSec = 1./clickRateHz;
x = [0; interClickIntervalSec];
y = [0; lockingFrPerClickRate./maxFr];

% % %'1./(1+exp(-k(x-x0)))'
% -k(x-x0) = -kX + kX0;
% b2 = -k;
% b1 = kX0

decayStart = 20;
x0Start = 1/20;
b1Start = decayStart*x0Start;
b2Start = -decayStart;

fitobject = fit(x,y,'1./(1+exp(b1+b2*x))','start',[b1Start b2Start]);
MyCoeffs = coeffvalues(fitobject);
decayPerHz = -MyCoeffs(2);
x0 = MyCoeffs(1)/decayPerHz;

predictedY = 1./(1+exp(-decayPerHz.*(interClickIntervalSec-x0)));
rms = mean((predictedY-y(2:end)).^2);

clickRateInflection = 1./x0;


function plotLockingModulationPerClickRate(plotData, subplotPosition,  exampleUnit, ...
    iExamplePerUnit, minUnitsPerSess, contextSessionsStr, barsProperties, figProperties, clicks, statesInfo)

gainIndex = plotData.lockedFrModulation.gainIndexPerUnit;

nMeasures = length(gainIndex);
XLIM = [0.5,nMeasures+0.5];
YLIM = [-1,1];

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

text(barsProperties.xStateText,0.9,['\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str '>' ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' statesInfo(2).str],'HorizontalAlignment','center');
text(barsProperties.xStateText,-0.9,['\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str  ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' '<' statesInfo(2).str],'HorizontalAlignment','center');
ylabel('Modulation Index');

xTickLabels = cell(nMeasures,1);
for iMeasure = 1:nMeasures
    xTickLabels{iMeasure} = sprintf('%d Hz',clicks.rateHz(iMeasure));
end

set(gca,'XTick',1:nMeasures,'XTickLabel',xTickLabels);%measuresLabels);
set(gca,'FontSize',figProperties.fontSize);
set(gca,'YTick',-1:0.2:1)
grid on


1;

