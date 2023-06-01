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