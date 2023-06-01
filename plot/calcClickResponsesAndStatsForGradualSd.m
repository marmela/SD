function [stats,plotData] = calcClickResponsesAndStatsForGradualSd(unitDataGradSd, isValidUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnit)

figPositions =  [10,50,1900,700]; %[10,50,950*0.85,950];
fontMultiplierForWidth = figPositions(3)/1000;

barsProperties.markerPixels = 1.5.*fontMultiplierForWidth; %2.2.*fontMultiplierForWidth; %3
barsProperties.markerPixelsSess = 5.*fontMultiplierForWidth; %7.5.*fontMultiplierForWidth; %9 %markerPixels*2.5; %1.92;
barsProperties.xJitterRange = 0.95;
barsProperties.sizeRatioState = 1.45;
barsProperties.nReps = 10000; 

nSdBins = length(unitDataGradSd);
for iSdBin = 1:nSdBins
    unitDataGradSd{iSdBin}(~isValidUnit) = [];
end
sessionPerUnit = extractfield(unitDataGradSd{1},'session');
nUnits = length(unitDataGradSd{1});

for iSdBin = nSdBins:-1:1
    clicks40Hz = cell2mat(extractfield(unitDataGradSd{iSdBin},'clicks40Hz')');
    clicksAll = cell2mat(extractfield(unitDataGradSd{iSdBin},'clicksAll')');
    baseFr(:,iSdBin) = extractfield(unitDataGradSd{iSdBin},'baseFr');
    clicksOnsetFr(:,iSdBin) = extractfield(clicks40Hz,'clicksOnsetFr');
    basePopCoupling(:,iSdBin) = abs(extractfield(unitDataGradSd{iSdBin},'basePopCoupling'));     %QWERTY! had to put abs since negative value screw with the gain index
    clicksLockedFr(:,iSdBin) = extractfield(clicks40Hz,'clicksLockedFr');
    clicksPostOnsetFr(:,iSdBin) = extractfield(clicksAll,'clicksPostOnsetFr');
end

baseFrNorm = (baseFr./repmat(mean(baseFr,2),1,nSdBins)-1)*100;
clicksOnsetFrNorm = (clicksOnsetFr./repmat(mean(clicksOnsetFr,2),1,nSdBins)-1)*100;
basePopCouplingNorm = (basePopCoupling./repmat(mean(basePopCoupling,2),1,nSdBins)-1)*100;
clicksLockedFrNorm = (clicksLockedFr./repmat(mean(clicksLockedFr,2),1,nSdBins)-1)*100;
clicksPostOnsetFrNorm = (clicksPostOnsetFr./repmat(mean(clicksPostOnsetFr,2),1,nSdBins)-1)*100;

dataToPlot{1} = basePopCouplingNorm;
dataToPlot{2} = clicksLockedFrNorm;
dataToPlot{3} = clicksPostOnsetFrNorm;
dataToPlot{4} = baseFrNorm;
dataToPlot{5} = clicksOnsetFrNorm;

dataStr{1} = 'Population Synchrony';
dataStr{2} = '40 Hz Locking';
dataStr{3} = 'Post Onset FR';
dataStr{4} = 'Spontaneous FR';
dataStr{5} = 'Onset FR';

sessionStr = extractfield(unitDataGradSd{1},'session');
isContextSess = cell2mat(extractfield(unitDataGradSd{1},'isContext'));
contextSessionsStr = unique(sessionStr(isContextSess));

%%
cappedYLim = ([-40,60]);
yTicks =  -40:10:60;
nTicks = length(yTicks);
yTickLabelsStr = cell(nTicks,1);
for iTick = 1:nTicks
    yTickLabelsStr{iTick} = num2str(yTicks(iTick));
end
yTickLabelsStr{1} = ['\leq' yTickLabelsStr{1}];
yTickLabelsStr{end} = ['\geq' yTickLabelsStr{end}];
hFig = figure('Position',figPositions);
for iPlot = 1:3
    
    isValidUnit = ~any(dataToPlot{iPlot}==0 | isnan(dataToPlot{iPlot}),2);
    subplot(1,3,iPlot)
    xlim([0.5,5.5])
    ylim(cappedYLim);
    hold on;
    bar(median(dataToPlot{iPlot}(isValidUnit,:)));
    for iSdBin = 1:nSdBins
        plotPointsPerSessMedianCapped(dataToPlot{iPlot}(isValidUnit,iSdBin), iSdBin, ...
        barsProperties.xJitterRange, barsProperties.nReps, barsProperties.markerPixelsSess, ...
            sessionPerUnit(isValidUnit),minUnitsPerSess, contextSessionsStr,Consts.MARKER_ANIMAL_MAP,cappedYLim) 
    end
    xlabel('Hours SD');
    ylabel('% change from mean');
    title(dataStr{iPlot})
    set(gca,'YTick',yTicks,'yTickLabel',yTickLabelsStr);
    grid on

    set(gca,'FontSize',16)
end
figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'Extra' filesep 'GradualSD'];
figPath = [figDir filesep 'GradualSDAcrossMotifs'];
print(gcf,[figPath '.png'],'-dpng','-r600')
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r600')
savefig(figPath);
close(hFig)
error('end of valid code')


%% Calculate Modulation(gain) Index, Cohen D'
clear gainIndex

iMeasure = 0;

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(baseFr{1},baseFr{2});
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = 'Spontaneous FR';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksOnsetFr{1},clicksOnsetFr{2});
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = 'Onset FR';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = -getGainIndex(basePopCoupling{1},basePopCoupling{2});
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = {'Population', 'Asynchrony'};

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{1},clicksLockedFr{2});
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = '40Hz locking';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksPostOnsetFr{1},clicksPostOnsetFr{2});
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = 'Post-Onset FR';

nMeasures = length(gainIndex);

1;

%% Stats

[sessionsStr,~,iSessionPerUnit] = unique(sessionPerUnit);
nSessions = length(sessionsStr);
meanValPerSess = nan(nSessions,1);
isSessWithEnoughUnits = false(nSessions,1);
for iSess = 1:nSessions
    isSessWithEnoughUnits(iSess) = sum(iSessionPerUnit==iSess)>=minUnitsPerSess;
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end
[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);


iAnimalPerUnit = iAnimalPerSession(iSessionPerUnit);
isAnimalWithEnoughUnits = false(nAnimals,1);
for iAnimal = 1:nAnimals
    isAnimalWithEnoughUnits(iAnimal) = sum(iAnimalPerUnit==iAnimal)>=minUnitsPerAnimal;
end

for iMeasure = 1:nMeasures
    gainIndexPerSession{iMeasure} = nan(nSessions,1);
    for iSess = 1:nSessions
        gainIndexPerSession{iMeasure}(iSess) = nanmean(gainIndex{iMeasure}(iSessionPerUnit==iSess));
    end
    gainIndexPerSession{iMeasure}= gainIndexPerSession{iMeasure}(isSessWithEnoughUnits);
    
    gainIndexPerAnimal{iMeasure} = nan(nAnimals,1);
    for iAnimal = 1:nAnimals
        gainIndexPerAnimal{iMeasure}(iAnimal) = nanmean(gainIndex{iMeasure}(iAnimalPerUnit==iAnimal));
    end
    gainIndexPerAnimal{iMeasure} = gainIndexPerAnimal{iMeasure}(isAnimalWithEnoughUnits);
end

SPEARMAN_STR = 'Spearman Correlation';
WSRT_STR = 'Wilcoxon Sign Rank Test';
for iMeasure = 1:nMeasures
    %% Stats Per Unit
    isValidGain = ~isnan(gainIndex{iMeasure});
    gainIndexNotNan = gainIndex{iMeasure}(isValidGain);
    [lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
        gainIndexNotNan, iAnimalPerUnit(isValidGain), iSessionPerUnit(isValidGain), channelPerUnit(isValidGain));
    stats.diffFrom0(iMeasure).linearMixedEffects.model = lme;
    stats.diffFrom0(iMeasure).linearMixedEffects.meanGain = miEstimated;
    stats.diffFrom0(iMeasure).linearMixedEffects.semGain = stdError;
    stats.diffFrom0(iMeasure).linearMixedEffects.p = pValue;
    stats.diffFrom0(iMeasure).linearMixedEffects.t = tStat;
    stats.diffFrom0(iMeasure).linearMixedEffects.df = df;
    stats.diffFrom0(iMeasure).linearMixedEffects.gainCI = miCI95;
    stats.diffFrom0(iMeasure).linearMixedEffects.test = 'Linear Mixed Effects Model';

    stats.diffFrom0(iMeasure).perUnit.meanGain = mean(gainIndexNotNan);
    stats.diffFrom0(iMeasure).perUnit.medianGain = median(gainIndexNotNan);
    stats.diffFrom0(iMeasure).perUnit.semGain = std(gainIndexNotNan)./sqrt(length(gainIndexNotNan));
    [stats.diffFrom0(iMeasure).perUnit.p,~,statsSignrank] = signrank(gainIndexNotNan);
    if isfield(statsSignrank,'zval')
        stats.diffFrom0(iMeasure).perUnit.z = statsSignrank.zval;
    end
    stats.diffFrom0(iMeasure).perUnit.n = length(gainIndexNotNan);
    stats.diffFrom0(iMeasure).perUnit.test = WSRT_STR;
    
    gainIndexForComparingBetweenMeasures1 = gainIndex{iMeasure};
    if mean(gainIndexForComparingBetweenMeasures1)<0
        gainIndexForComparingBetweenMeasures1 = -gainIndexForComparingBetweenMeasures1;
    end
    
    for iMeasure2 = iMeasure+1:nMeasures
        gainIndexForComparingBetweenMeasures2 = gainIndex{iMeasure2};
        if mean(gainIndexForComparingBetweenMeasures2)<0
            gainIndexForComparingBetweenMeasures2 = -gainIndexForComparingBetweenMeasures2;
        end
        
        [stats.diffBetweenMeasures(iMeasure,iMeasure2).perUnit.p,~,statsSignrank] = signrank(...
            gainIndexForComparingBetweenMeasures1,gainIndexForComparingBetweenMeasures2);
        if isfield(statsSignrank,'zval')
            stats.diffBetweenMeasures(iMeasure,iMeasure2).perUnit.z = statsSignrank.zval;
        end
        stats.diffBetweenMeasures(iMeasure,iMeasure2).perUnit.n = sum(...
            ~isnan(gainIndexForComparingBetweenMeasures1) & ...
            ~isnan(gainIndexForComparingBetweenMeasures2));
        stats.diffBetweenMeasures(iMeasure,iMeasure2).perUnit.test = WSRT_STR;
    end
    
    %% stats per session
    gainIndexPerSessionNotNan = gainIndexPerSession{iMeasure}(~isnan(gainIndexPerSession{iMeasure}));
    stats.diffFrom0(iMeasure).perSession.meanGain = mean(gainIndexPerSessionNotNan);
    stats.diffFrom0(iMeasure).perSession.medianGain = median(gainIndexPerSessionNotNan);
    stats.diffFrom0(iMeasure).perSession.semGain = std(gainIndexPerSessionNotNan)./sqrt(length(gainIndexPerSessionNotNan));
    [stats.diffFrom0(iMeasure).perSession.p,~,statsSignrank] = signrank(gainIndexPerSessionNotNan);
    if isfield(statsSignrank,'zval')
        stats.diffFrom0(iMeasure).perSession.z = statsSignrank.zval;
    end
    stats.diffFrom0(iMeasure).perSession.n = length(gainIndexPerSessionNotNan);
    stats.diffFrom0(iMeasure).perSession.test = WSRT_STR;
    
    gainIndexForComparingBetweenMeasures1 = gainIndexPerSession{iMeasure};
    if mean(gainIndexForComparingBetweenMeasures1)<0
        gainIndexForComparingBetweenMeasures1 = -gainIndexForComparingBetweenMeasures1;
    end
    
    for iMeasure2 = iMeasure+1:nMeasures
        gainIndexForComparingBetweenMeasures2 = gainIndexPerSession{iMeasure2};
        if mean(gainIndexForComparingBetweenMeasures2)<0
            gainIndexForComparingBetweenMeasures2 = -gainIndexForComparingBetweenMeasures2;
        end
        
        [stats.diffBetweenMeasures(iMeasure,iMeasure2).perSession.p,~,statsSignrank] = signrank(...
            gainIndexForComparingBetweenMeasures1,gainIndexForComparingBetweenMeasures2);
        if isfield(statsSignrank,'zval')
            stats.diffBetweenMeasures(iMeasure,iMeasure2).perSession.z = statsSignrank.zval;
        end
        stats.diffBetweenMeasures(iMeasure,iMeasure2).perSession.n = sum(...
            ~isnan(gainIndexForComparingBetweenMeasures1) & ...
            ~isnan(gainIndexForComparingBetweenMeasures2));
        stats.diffBetweenMeasures(iMeasure,iMeasure2).perSession.test = WSRT_STR;
    end
    
    %% stats per animal
    gainIndexPerAnimalNotNan = gainIndexPerAnimal{iMeasure}(~isnan(gainIndexPerAnimal{iMeasure}));
    stats.diffFrom0(iMeasure).perAnimal.meanGain = mean(gainIndexPerAnimalNotNan);
    stats.diffFrom0(iMeasure).perAnimal.medianGain = median(gainIndexPerAnimalNotNan);
    stats.diffFrom0(iMeasure).perAnimal.semGain = std(gainIndexPerAnimalNotNan)./sqrt(length(gainIndexPerAnimalNotNan));
    [stats.diffFrom0(iMeasure).perAnimal.p,~,statsSignrank] = signrank(gainIndexPerAnimalNotNan);
    if isfield(statsSignrank,'zval')
        stats.diffFrom0(iMeasure).perAnimal.z = statsSignrank.zval;
    end
    stats.diffFrom0(iMeasure).perAnimal.n = length(gainIndexPerAnimalNotNan);
    stats.diffFrom0(iMeasure).perAnimal.test = WSRT_STR;
    
    gainIndexForComparingBetweenMeasures1 = gainIndexPerAnimal{iMeasure};
    if mean(gainIndexForComparingBetweenMeasures1)<0
        gainIndexForComparingBetweenMeasures1 = -gainIndexForComparingBetweenMeasures1;
    end
    
    for iMeasure2 = iMeasure+1:nMeasures
        gainIndexForComparingBetweenMeasures2 = gainIndexPerAnimal{iMeasure2};
        if mean(gainIndexForComparingBetweenMeasures2)<0
            gainIndexForComparingBetweenMeasures2 = -gainIndexForComparingBetweenMeasures2;
        end
        
        [stats.diffBetweenMeasures(iMeasure,iMeasure2).perAnimal.p,~,statsSignrank] = signrank(...
            gainIndexForComparingBetweenMeasures1,gainIndexForComparingBetweenMeasures2);
        if isfield(statsSignrank,'zval')
            stats.diffBetweenMeasures(iMeasure,iMeasure2).perAnimal.z = statsSignrank.zval;
        end
        stats.diffBetweenMeasures(iMeasure,iMeasure2).perAnimal.n = sum(...
            ~isnan(gainIndexForComparingBetweenMeasures1) & ...
            ~isnan(gainIndexForComparingBetweenMeasures2));
        stats.diffBetweenMeasures(iMeasure,iMeasure2).perAnimal.test = WSRT_STR;
    end
end

%% correlation between gains normalized to session
iUniqueSession = unique(iSessionPerUnit)';
gainIndexSessNormalized = gainIndex;
basePopCouplingSessNormalized = basePopCoupling;
for iSess = iUniqueSession
    isCurrSess = iSessionPerUnit==iSess;
    for iSdBin = 1:2
        basePopCouplingSessNormalized{iSdBin}(isCurrSess) = basePopCoupling{iSdBin}(isCurrSess)-...
            mean(basePopCoupling{iSdBin}(isCurrSess));
    end
    for iMeasure = 1:nMeasures
        gainIndexSessNormalized{iMeasure}(isCurrSess) = gainIndex{iMeasure}(isCurrSess)-...
            mean(gainIndex{iMeasure}(isCurrSess));
    end
end

for iMeasure1 = 1:nMeasures
    isValid1 = ~isnan(gainIndexSessNormalized{iMeasure1});
    for iMeasure2 = iMeasure1+1:nMeasures
        isValidTwoStates = isValid1 & ~isnan(gainIndexSessNormalized{iMeasure2});
        [r,p] = corr(gainIndexSessNormalized{iMeasure1}(isValidTwoStates)',...
            gainIndexSessNormalized{iMeasure2}(isValidTwoStates)','type','spearman');
        stats.corrBetweenSessNormalizedMeasures(iMeasure1,iMeasure2).p = p;
        stats.corrBetweenSessNormalizedMeasures(iMeasure1,iMeasure2).r = r;
        stats.corrBetweenSessNormalizedMeasures(iMeasure1,iMeasure2).n = sum(isValidTwoStates);
        stats.corrBetweenSessNormalizedMeasures(iMeasure1,iMeasure2).test = SPEARMAN_STR;
        stats.corrBetweenSessNormalizedMeasures(iMeasure2,iMeasure1) = ...
            stats.corrBetweenSessNormalizedMeasures(iMeasure1,iMeasure2);
    end
end


%% Variance across measure - Friedman test
gainPerMeasure = cell2mat(gainIndex')';
isNanUnitAnyMeasure = any(isnan(gainPerMeasure),2);
gainPerMeasureValid = gainPerMeasure(~isNanUnitAnyMeasure,:);
FRIEDMAN_STR = 'Friedman Test';
[p,~,statsFriedman] = friedman(gainPerMeasureValid,1,'off');
stats.varianceAcrossMeasures.perUnit.p = p;
stats.varianceAcrossMeasures.perUnit.n = statsFriedman.n;
stats.varianceAcrossMeasures.perUnit.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perUnit.stats = statsFriedman;

gainPerSessionAndMeasure = cell2mat(gainIndexPerSession);
isNanSessAnyMeasure = any(isnan(gainPerSessionAndMeasure),2);
gainPerSessionAndMeasureValid = gainPerSessionAndMeasure(~isNanSessAnyMeasure,:);
[p,~,statsFriedman] = friedman(gainPerSessionAndMeasureValid,1,'off');
stats.varianceAcrossMeasures.perSession.p = p;
stats.varianceAcrossMeasures.perSession.n = statsFriedman.n;
stats.varianceAcrossMeasures.perSession.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perSession.stats = statsFriedman;

gainPerAnimalAndMeasure = cell2mat(gainIndexPerAnimal);
isNanAnimalAnyMeasure = any(isnan(gainPerAnimalAndMeasure),2);
gainPerAnimalAndMeasureValid = gainPerAnimalAndMeasure(~isNanAnimalAnyMeasure,:);
[p,~,statsFriedman] = friedman(gainPerAnimalAndMeasureValid,1,'off');
stats.varianceAcrossMeasures.perAnimal.p = p;
stats.varianceAcrossMeasures.perAnimal.n = statsFriedman.n;
stats.varianceAcrossMeasures.perAnimal.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perAnimal.stats = statsFriedman;

%%

stats.selection.sessions.minUnitsPerSess = minUnitsPerSess;
stats.selection.sessions.isEnoughUnits = isSessWithEnoughUnits;
stats.selection.animals.minUnitsPerSess = minUnitsPerAnimal;
stats.selection.animals.isEnoughUnits = isAnimalWithEnoughUnits;
plotData.gainIndex = gainIndex;
plotData.cohenDZ = cohenDZ;
plotData.measureStr = measureStr;

plotData.sessionStrPerUnitValid = sessionPerUnit;
plotData.minUnitsPerAnimal = minUnitsPerAnimal;
plotData.minUnitsPerSess = minUnitsPerSess;
plotData.exampleUnits = exampleUnit;
plotData.iExamplePerUnit = iExamplePerUnit;
1;