function plotTuningAndClickTrainFigForManuscriptDLC(dlcPerSess,state1Data, state2Data, isSigClicksUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitClicks, statesToPlotClickRaster)

%%
[statsClicks,clicksPlotData] = calcClickResponsesAndStats(state1Data,state2Data, isSigClicksUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitClicks, statesToPlotClickRaster);
[statsDlc,dlcPlotData] = calcDlcMovementAndStats(dlcPerSess);
statsDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'DlcFig'];
makeDirIfNeeded(statsDir)
statsFileName = sprintf('DLC_Movement_FigStats_%s-%s',state1Data.info.str,state2Data.info.str);
statsPath = [statsDir filesep statsFileName];
statsClicks.isSigUnit = isSigClicksUnit;
save(statsPath,'statsClicks','clicksPlotData');
[sessionStr,iUniqeSessions,~] = unique(extractfield(state1Data.unitData,'session'));
isContextSess = cell2mat(extractfield(state1Data.unitData(iUniqeSessions),'isContext'));
markerAnimalMap = Consts.MARKER_ANIMAL_MAP;
plotTuningAndClicksFig(clicksPlotData,state1Data.info,state2Data.info,...
    statesToPlotClickRaster,sessionStr(isContextSess), markerAnimalMap,statsDlc,dlcPlotData)

function plotTuningAndClicksFig(clicksPlotData,state1Info,state2Info,...
    statesToPlotClickRaster,contextSessionsStr, markerAnimalMap, statsDlc,dlcPlotData)

%% Various Figure Properties

figPositions =  [0,50,1000,900]; %[0,50,1400,1100];
fontMultiplierForWidth = figPositions(3)/1000;
markerPixels = 2.2.*fontMultiplierForWidth; %3.5;
markerPixelsSess = 7.5.*fontMultiplierForWidth; %10; %markerPixels*2.5; %1.92;
xJitterRange = 0.95;
nReps = 10000; 

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
clicksPopulationX = 0.45;
clicksPopulationWidth = 0.52;tuningWidthPopulationWidth+interPanelWidth+tuningCorrPopulationWidth; 
psthHeight = 0.14;
stimClicksHeight = 0.012;
rasterHeight = secondRowHeight-psthHeight-stimClicksHeight; %0.24;
FONT_SIZE = 13.5.*fontMultiplierForWidth; %13.5.*fontMultiplierForWidth; %12;
STATE_FONT_SIZE = 15.*fontMultiplierForWidth; %16;
sizeRatioState = 1.45;
SHADING_ONSET_COLOR = ones(1,3)*0.4;%[80	60	70]*0.9/100; %[0.9,0.1,0]; %[80	60	70]*1.1/95;
SHADING_LOCKING_COLOR =  [90	60	0]/95; %[95	90	25]/95;
SHADING_POST_ONSET_COLOR = [0	60	50]*0.85/95; %[253,165,15]/255;
figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'DlcFig'];
makeDirIfNeeded(figDir);
SHADING_ALPHA = 0.25; %0.3;
colorPerMeasure = {[],SHADING_ONSET_COLOR,[],...
    SHADING_LOCKING_COLOR,SHADING_POST_ONSET_COLOR};

figName = sprintf('DLC_Movement_%s-%s',state1Info.str,state2Info.str);
dlcMovementPlotPositions = [clicksPopulationX,firstRowY,clicksPopulationWidth,firstRowHeight];
clicksPopulationPlotPositions = [clicksPopulationX,secondRowY,clicksPopulationWidth,secondRowHeight];
%%
hFig = figure('Position',figPositions);
%% plot DLC movement per session
1;
BAR_WIDTH = 0.95;
BAR_LINE_WIDTH = 1.5; %1.25;
barColor = [0.85,0.85,0.85];
SEM_LINE_WIDTH = 4.5; %4.5;
SEM_COLOR = 'k';
dlcMarkerPixelsSess = 3.5;
nStates = length(dlcPlotData.statesStr);
XLIM = [0.5,nStates+0.5];
xLoc = 1:nStates;
meanMovementPerState = nanmean(dlcPlotData.movementPerSessAndState,1);
semMovementPerState = nanstd(dlcPlotData.movementPerSessAndState,1)./sqrt(sum(~isnan(dlcPlotData.movementPerSessAndState),1));

subplot('position',dlcMovementPlotPositions);
hold on;
bar(meanMovementPerState,BAR_WIDTH,'FaceColor',barColor)
for iState = 1:nStates
    plot([iState,iState],meanMovementPerState(iState)+[-1,1].*semMovementPerState(iState), ...
        'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
    plotPointsPerSess(dlcPlotData.movementPerSessAndState(:,iState),iState,xJitterRange,nReps,...
        dlcMarkerPixelsSess,dlcPlotData.sessionsStr,1,...
        dlcPlotData.sessionsStr(dlcPlotData.isContextSession),markerAnimalMap)
end
bar(meanMovementPerState,BAR_WIDTH,'FaceColor','none','LineWidth',BAR_LINE_WIDTH)
xlim(XLIM)
ylabel('Movement (pixels)');
set(gca,'XTick',xLoc,'XTickLabel',dlcPlotData.statesStr);%measuresLabels);
set(gca,'FontSize',FONT_SIZE);



%% plot clicks modulation/gain index per unit 
nMeasures = length(clicksPlotData.gainIndex);
XLIM = [0.5,nMeasures+0.5];
YLIM = [-100,100]; %[-1,1];

subplot('position',clicksPopulationPlotPositions);
hold on;
plot([2.5,2.5],YLIM,'--k','LineWidth',1)
xlim(XLIM)
ylim(YLIM)
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
%             measuresLabels{iMeasure} = ['\color[rgb]{' sprintf('%f,%f,%f',colorPerMeasure{iMeasure}) '}' measuresLabels{iMeasure}];
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
            currentEdgeColor,'LineWidth',1.1);
        hScatter.MarkerFaceAlpha = ALPHA_SCATTER;
        hScatter.MarkerEdgeAlpha = ALPHA_SCATTER;
    end
end

meanValUnits = nanmean(values);
semUnits = nanstd(values)./sqrt(sum(~isnan(values)));
plot([xLoc,xLoc],[meanValUnits-semUnits,meanValUnits+semUnits],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)
