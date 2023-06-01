function plotTuningWidthModulationPopulation(tuningPlotData,statesInfo,plotPositions,figProperties, barsProperties, contextSessionsStr)
%% plot Tuning Width Modulation per unit
subplot('position',plotPositions);
hold on;
XLIM = [0.5,1+0.5];
YLIM = [-100,100];
xlim(XLIM)
ylim(YLIM)
text(0.51,90,['\bf\it\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str '>' ...
    '\bf\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' statesInfo(2).str],'HorizontalAlignment','left');
text(0.51,-90,['\bf\it\fontsize{' num2str(figProperties.stateFontSize/barsProperties.sizeRatioState) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color) '}' statesInfo(1).str  ...
    '\bf\fontsize{' num2str(figProperties.stateFontSize) '}\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' '<' statesInfo(2).str],'HorizontalAlignment','left');
xloc1 = plotBarAndPoints(tuningPlotData.tuningWidthGainPerUnitAll,1,barsProperties.xJitterRange,...
    barsProperties.nReps,barsProperties.markerPixels,tuningPlotData.iExamplePerUnit);
plotPointsPerSess(tuningPlotData.tuningWidthGainPerUnitAll,1,barsProperties.xJitterRange,...
    barsProperties.nReps, barsProperties.markerPixelsSess, tuningPlotData.sessionStrPerUnitValid, ...
    tuningPlotData.minUnitsPerSess, contextSessionsStr,Consts.MARKER_ANIMAL_MAP)
plotExamplePoints(tuningPlotData.tuningWidthGainPerUnitAll,xloc1,...
    barsProperties.markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
set(gca,'XTick',1,'XTickLabel','Tuning Width');
set(gca,'YTick',-100:20:100)
ylabel('Modulation Index');
set(gca,'FontSize',figProperties.fontSize);
grid on
