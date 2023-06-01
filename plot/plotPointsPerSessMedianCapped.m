function plotPointsPerSessMedianCapped(values,xLoc,xJitterRange,nReps,markerPixels,sessionPerValue,minUnitsPerSess,contextSessionsStr,markerAnimalMap,maxYLims)
%% plot Points per session but black&White

SEM_LINE_WIDTH = 4.5;
SEM_COLOR = 'k';
ALPHA_SCATTER = 0.87; %0.8;

MARKER_FACE_COLOR = [0.4,0.4,0.4];

edgeColorMarkerContext = 'k';
edgeColorMarkerComplex = MARKER_FACE_COLOR;

[sessionsStr,~,iSessionPerUnit] = unique(sessionPerValue);
nSessions = length(sessionsStr);
meanValPerSess = nan(nSessions,1);
isSessWithEnoughUnits = false(nSessions,1);

for iSess = 1:nSessions
    isSessWithEnoughUnits(iSess) = sum(iSessionPerUnit==iSess)>=minUnitsPerSess;
    meanValPerSess(iSess) = nanmedian(values(iSessionPerUnit==iSess));
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end

[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);

meanValAllSess = nanmedian(meanValPerSess);
sem = nanstd(meanValPerSess)./sqrt(sum(~isnan(meanValPerSess)));
currentStateXLoc = nan(nSessions,1);

assert(maxYLims(2)>maxYLims(1))
meanValPerSess(meanValPerSess>maxYLims(2)) = maxYLims(2);
meanValPerSess(meanValPerSess<maxYLims(1)) = maxYLims(1);
currentStateXLoc(isSessWithEnoughUnits) = xLoc+dispersePointsByAxis(meanValPerSess(...
    isSessWithEnoughUnits),xJitterRange,nReps,markerPixels);

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

meanValUnits = nanmedian(values);
semUnits = nanstd(values)./sqrt(sum(~isnan(values)));
plot([xLoc,xLoc],[meanValUnits-semUnits,meanValUnits+semUnits],'LineWidth',SEM_LINE_WIDTH,'color',SEM_COLOR)

1;