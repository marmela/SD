function plotModulationClickFeaturesPopulation(clicksPlotData, subplotPosition, ...
    statesInfo, figProperties, barsProperties, clicks, colorPerMeasure, contextSessionsStr,isPlotYAxis)

if ~exist('isPlotYAxis','var')
    isPlotYAxis = true;
end
nMeasures = length(clicksPlotData.gainIndex);
XLIM = [0.5,nMeasures+0.5];
YLIM = [-100,100];
X_TICK_ANGLE = 25;
subplot('position',subplotPosition);
hold on;
plot([2.5,2.5],YLIM,'--k','LineWidth',1)
xlim(XLIM)
ylim(YLIM)

for iMeasure = 1:nMeasures
    if isempty(colorPerMeasure{iMeasure})
        colorAfterAlpha = [];
    else
        colorAfterAlpha = 1-(1-colorPerMeasure{iMeasure})*sqrt(barsProperties.shadingAlpha);
    end
    xLocCurrentMeasure = plotBarAndPoints(clicksPlotData.gainIndex{iMeasure},iMeasure,...
        barsProperties.xJitterRange,barsProperties.nReps,barsProperties.markerPixels,...
        clicksPlotData.iExamplePerUnit, colorAfterAlpha);
    plotPointsPerSess(clicksPlotData.gainIndex{iMeasure}, iMeasure, ...
        barsProperties.xJitterRange, barsProperties.nReps, barsProperties.markerPixelsSess, ...
        clicksPlotData.sessionStrPerUnitValid,clicksPlotData.minUnitsPerSess,...
        contextSessionsStr,Consts.MARKER_ANIMAL_MAP) 
    plotExamplePoints(clicksPlotData.gainIndex{iMeasure},xLocCurrentMeasure,...
        barsProperties.markerPixels,clicksPlotData.exampleUnits,clicksPlotData.iExamplePerUnit);
end

text(barsProperties.xStateText,90,['\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str '>' ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' statesInfo(2).str],'HorizontalAlignment','center');
text(barsProperties.xStateText,-90,['\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str  ...
    '\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' '<' statesInfo(2).str],'HorizontalAlignment','center');

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
set(gca,'FontSize',figProperties.fontSize);
set(gca,'YTick',-100:20:100)
if isPlotYAxis
    ylabel('Modulation Index (%)');
else
    set(gca,'YTickLabel',{})
end

grid on

end