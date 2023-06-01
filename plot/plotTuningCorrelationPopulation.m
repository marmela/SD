function plotTuningCorrelationPopulation(tuningPlotData, statesInfo, plotPositions, ...
    figProperties, barsProperties, contextSessionsStr)
%% plot signal correlation per unit
XLIM = [0.5,3+0.5];
YLIM = [-0.2,1];

subplot('position',plotPositions);
hold on;

xlim(XLIM)
ylim(YLIM)

xloc1 = plotBarAndPoints(tuningPlotData.meanCorrBetweenStatesWithOtherUnitsAll,1,...
    barsProperties.xJitterRange,barsProperties.nReps,barsProperties.markerPixels, ...
    tuningPlotData.iExamplePerUnit);
xloc2 = plotBarAndPoints(tuningPlotData.meanCorrBetweenStatesPerUnitAll,2,...
    barsProperties.xJitterRange,barsProperties.nReps, barsProperties.markerPixels,...
    tuningPlotData.iExamplePerUnit);
xloc3 = plotBarAndPoints(tuningPlotData.meanCorrWithinStatePerUnitAll,3,...
    barsProperties.xJitterRange,barsProperties.nReps, barsProperties.markerPixels, ...
    tuningPlotData.iExamplePerUnit);

plotPointsPerSess(tuningPlotData.meanCorrBetweenStatesWithOtherUnitsAll,1,...
    barsProperties.xJitterRange,barsProperties.nReps, barsProperties.markerPixelsSess,...
    tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,Consts.MARKER_ANIMAL_MAP)
plotPointsPerSess(tuningPlotData.meanCorrBetweenStatesPerUnitAll,2,...
    barsProperties.xJitterRange,barsProperties.nReps, barsProperties.markerPixelsSess, ...
    tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,Consts.MARKER_ANIMAL_MAP)
plotPointsPerSess(tuningPlotData.meanCorrWithinStatePerUnitAll,3,...
    barsProperties.xJitterRange,barsProperties.nReps,barsProperties.markerPixelsSess, ...
    tuningPlotData.sessionStrPerUnitValid,tuningPlotData.minUnitsPerSess,...
    contextSessionsStr,Consts.MARKER_ANIMAL_MAP)

plotExamplePoints(tuningPlotData.meanCorrBetweenStatesWithOtherUnitsAll,xloc1,...
    barsProperties.markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
plotExamplePoints(tuningPlotData.meanCorrBetweenStatesPerUnitAll,xloc2, ...
    barsProperties.markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);
plotExamplePoints(tuningPlotData.meanCorrWithinStatePerUnitAll,xloc3, ...
    barsProperties.markerPixels,tuningPlotData.exampleUnits,tuningPlotData.iExamplePerUnit);

state1XState2Str = {['\bf\it\color[rgb]{' sprintf('%f,%f,%f',statesInfo(2).color) '}' ...
    statesInfo(2).str '\color{black}x'], ['\bf\it\color[rgb]{' sprintf('%f,%f,%f',statesInfo(1).color)...
    '}' statesInfo(1).str ]};

% set(gca,'XTick',1:3,'XTickLabel',{'Between Units','Between States','Within State'})
row1 = {'Between  '   state1XState2Str{1}         '  Within'};
row2 = {'   units   '   state1XState2Str{2}         '  state'};
% Combine the rows of labels into a cell array; convert non-strings to strings/character vectors.
% labelArray is an nxm cell array with n-rows of m-tick-lables. 
labelArray = [row1; row2]; 
% To use right or center justification, 
% labelArray = strjust(pad(labelArray),'center'); % 'left'(default)|'right'|'center
% Combine the rows of labels into individual tick labels
% Change the compose() format according to your label classes.
% Place the \\newline command between rows of labels.
% This plot has 3 rows of labels so there are 2 \\newline commands.
tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
ax = gca(); 
ax.XTick = 1:3; 
ax.XTickLabel = tickLabels; 
ylabel('Signal Correlation');
if min(ylim())<YLIM(1)
    warning('AXIS OUTSIDE OF PREDEFINED Y-LIM');
end
ylim(YLIM)
set(gca,'FontSize',figProperties.fontSize);
ax.XAxis.FontSize = figProperties.fontSize;
grid on