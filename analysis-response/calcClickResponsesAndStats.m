function [stats,plotData] = calcClickResponsesAndStats(state1Data,state2Data, isValidUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnit, statesToPlot)

plotData.example = getExampleRasterAndPsth(exampleUnit,statesToPlot);

unitDataAll = {state1Data.unitData(isValidUnit), state2Data.unitData(isValidUnit)}; 
sessionPerUnit = extractfield(state1Data.unitData(isValidUnit),'session');
nUnits = length(unitDataAll{1});

for iState = 1:2    
    clicks40Hz = cell2mat(extractfield(unitDataAll{iState},'clicks40Hz')');
    clicksAll = cell2mat(extractfield(unitDataAll{iState},'clicksAll')');

    baseFr{iState} = extractfield(unitDataAll{iState},'baseFr');
    clicksOnsetFr{iState} = extractfield(clicks40Hz,'clicksOnsetFr');
    basePopCoupling{iState} = abs(extractfield(unitDataAll{iState},'basePopCoupling'));  
    clicksLockedFr{iState} = extractfield(clicks40Hz,'clicksLockedFr');
    clicksPostOnsetFr{iState} = extractfield(clicksAll,'clicksPostOnsetFr');
end

%%
iExamplePerUnit = nan(nUnits,1);
channelPerUnit = extractfield(unitDataAll{1},'ch');
clusPerUnit = extractfield(unitDataAll{1},'clus');

iExampleUnit = find(strcmp(sessionPerUnit,exampleUnit.session) & ...
    exampleUnit.ch==channelPerUnit & exampleUnit.clus==clusPerUnit);
assert(length(iExampleUnit)==1);
iExamplePerUnit(iExampleUnit) = 1; %onlt one example so iExample==1

%% Calculate Modulation(gain) Index, Cohen D'
clear gainIndex

iMeasure = 0;
CONVERT_TO_PERCENT = 100;
iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(baseFr{1},baseFr{2})*CONVERT_TO_PERCENT;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = {'Spontaneous    ', '        FR    '};

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksOnsetFr{1},clicksOnsetFr{2})*CONVERT_TO_PERCENT;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = {'Onset', '   FR  '};

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(basePopCoupling{1},basePopCoupling{2})*CONVERT_TO_PERCENT;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = {'Population', 'synchrony'};

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{1},clicksLockedFr{2})*CONVERT_TO_PERCENT;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = {' 40 Hz ', 'locking'};

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksPostOnsetFr{1},clicksPostOnsetFr{2})*CONVERT_TO_PERCENT;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = {'Post-Onset','      FR    '};

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
    isValidGain = ~isnan(gainIndex{iMeasure});
    gainIndexNotNan = gainIndex{iMeasure}(isValidGain);
    %% Linear Mixed Effects - diff from 0 for all measures
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
    %% Stats Per Unit - diff from 0 for all measures
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
    if nanmean(gainIndexForComparingBetweenMeasures1)<0
        gainIndexForComparingBetweenMeasures1 = -gainIndexForComparingBetweenMeasures1;
    end
    
    for iMeasure2 = iMeasure+1:nMeasures
        gainIndexForComparingBetweenMeasures2 = gainIndex{iMeasure2};
        if nanmean(gainIndexForComparingBetweenMeasures2)<0
            gainIndexForComparingBetweenMeasures2 = -gainIndexForComparingBetweenMeasures2;
        end
        isValidGainForPair = ~isnan(gainIndexForComparingBetweenMeasures2) & isValidGain;
        %% isValidGainForPair
        diffBetweenPair = gainIndexForComparingBetweenMeasures1(isValidGainForPair)-...
            gainIndexForComparingBetweenMeasures2(isValidGainForPair);
        [lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
            diffBetweenPair, iAnimalPerUnit(isValidGainForPair), ...
            iSessionPerUnit(isValidGainForPair), channelPerUnit(isValidGainForPair));
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.model = lme;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.meanGain = miEstimated;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.semGain = stdError;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.p = pValue;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.t = tStat;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.df = df;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.gainCI = miCI95;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.test = 'Linear Mixed Effects Model';
        
        %% Stats Per Unit - diff between pairs of measures
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
    for iState = 1:2
        basePopCouplingSessNormalized{iState}(isCurrSess) = basePopCoupling{iState}(isCurrSess)-...
            mean(basePopCoupling{iState}(isCurrSess));
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
% a note - Friedman test were done on the gains without negating any measure (e.g. making
% population synchrony to negative to match the trend of all the other measures to
% negativity). negating the measures so they will all have positive mean values was only
% done when comparing pairs of measures above (so that 40 Hz won't be necessarily
% different from population synchrony just because they have different signs)
gainPerMeasure = cell2mat(gainIndex')';
isNanUnitAnyMeasure = any(isnan(gainPerMeasure),2);
gainPerMeasureValid = gainPerMeasure(~isNanUnitAnyMeasure,:);
isNegativeMeanGain = mean(gainPerMeasureValid)<0;
gainPerMeasureValid(:,isNegativeMeanGain) = gainPerMeasureValid(:,isNegativeMeanGain)*-1;
FRIEDMAN_STR = 'Friedman Test';
[p,~,statsFriedman] = friedman(gainPerMeasureValid,1,'off');
stats.varianceAcrossMeasures.perUnit.p = p;
stats.varianceAcrossMeasures.perUnit.n = statsFriedman.n;
stats.varianceAcrossMeasures.perUnit.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perUnit.stats = statsFriedman;

gainPerSessionAndMeasure = cell2mat(gainIndexPerSession);
isNanSessAnyMeasure = any(isnan(gainPerSessionAndMeasure),2);
gainPerSessionAndMeasureValid = gainPerSessionAndMeasure(~isNanSessAnyMeasure,:);
isNegativeMeanGain = mean(gainPerSessionAndMeasureValid)<0;
gainPerSessionAndMeasureValid(:,isNegativeMeanGain) = gainPerSessionAndMeasureValid(:,isNegativeMeanGain)*-1;
[p,~,statsFriedman] = friedman(gainPerSessionAndMeasureValid,1,'off');
stats.varianceAcrossMeasures.perSession.p = p;
stats.varianceAcrossMeasures.perSession.n = statsFriedman.n;
stats.varianceAcrossMeasures.perSession.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perSession.stats = statsFriedman;

gainPerAnimalAndMeasure = cell2mat(gainIndexPerAnimal);
isNanAnimalAnyMeasure = any(isnan(gainPerAnimalAndMeasure),2);
gainPerAnimalAndMeasureValid = gainPerAnimalAndMeasure(~isNanAnimalAnyMeasure,:);
isNegativeMeanGain = mean(gainPerAnimalAndMeasureValid)<0;
gainPerAnimalAndMeasureValid(:,isNegativeMeanGain) = gainPerAnimalAndMeasureValid(:,isNegativeMeanGain)*-1;
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
