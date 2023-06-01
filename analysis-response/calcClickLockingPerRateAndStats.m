function [statsPerStatesPair,plotDataPerStatesPair,plotDataFitVars,iExamplePerUnit] = ...
    calcClickLockingPerRateAndStats(statesData, isValidUnit, minUnitsPerAnimal, ...
    minUnitsPerSess, exampleUnit, clickRateHz)

nStates = length(statesData);
sessionPerUnit = extractfield(statesData{1}.unitData(isValidUnit),'session');
channelPerUnit = extractfield(statesData{1}.unitData(isValidUnit),'ch');
nUnits = length(statesData{1}.unitData(isValidUnit));
isUnitExample = strcmp(extractfield(statesData{1}.unitData(isValidUnit),'session'),exampleUnit.session) & ...
    extractfield(statesData{1}.unitData(isValidUnit),'ch')==exampleUnit.ch & ...
    extractfield(statesData{1}.unitData(isValidUnit),'clus')==exampleUnit.clus;
clickRateOfHalfResponse = nan(nStates,nUnits);
decayPerHz = nan(nStates,nUnits);
rms = nan(nStates,nUnits);
clickRate25Percent = nan(nStates,nUnits);
isDecreasingWithClickRatePerStateAndUnit = false(nStates,nUnits);
isValidUnitForLockedFrGain = true(nUnits,1);

for iState = nStates:-1:1
    statesData{iState}.unitData = statesData{iState}.unitData(isValidUnit);
    for iUnit = nUnits:-1:1
        clicksLockedFr{iState}(iUnit,:) = statesData{iState}.unitData(iUnit).clicksAll.clicksLockedFr;
        clicksOnsetNormFr = mean(statesData{iState}.unitData(iUnit).clicksAll.clicksOnsetNormFr);
        if any(clicksLockedFr{iState}(iUnit,:)==0)
            isValidUnitForLockedFrGain(iUnit) = false;
            continue;
        end
        isDecreasingWithClickRatePerStateAndUnit(iState,iUnit) = ...
            clicksLockedFr{iState}(iUnit,1)>clicksLockedFr{iState}(iUnit,end);
        
        [clickRateOfHalfResponse(iState,iUnit), decayPerHz(iState,iUnit), rms(iState,iUnit),...
            clickRate25Percent(iState,iUnit),normalizedResponsePerStateAndUnit{iState,iUnit}] = ...
            fitSigmoidToClickLocking(clicksOnsetNormFr, ...
            clickRateHz, clicksLockedFr{iState}(iUnit,:));
    end
end

%%

meanRmsPerUnit = mean(rms);
isValidUnitForClickRateInflection =  all(isDecreasingWithClickRatePerStateAndUnit) & ...
    all(clickRate25Percent>2 & clickRate25Percent<150)  & meanRmsPerUnit<0.07; 
clickRateOfAdaptedResponseValid = clickRate25Percent(:,isValidUnitForClickRateInflection);

plotDataFitVars.normalizedResponsePerStateAndUnit = normalizedResponsePerStateAndUnit(:,isValidUnitForClickRateInflection);
plotDataFitVars.clickRate25Percent = clickRate25Percent(:,isValidUnitForClickRateInflection);
plotDataFitVars.rms = rms(:,isValidUnitForClickRateInflection);
plotDataFitVars.decayPerHz = decayPerHz(:,isValidUnitForClickRateInflection);
plotDataFitVars.clickRateOfHalfResponse = clickRateOfHalfResponse(:,isValidUnitForClickRateInflection);
iExamplePerUnit.rateAdaptation = nan(sum(isValidUnitForClickRateInflection),1);
iExamplePerUnit.lockingModulation = nan(sum(isValidUnitForLockedFrGain),1);
iExamplePerUnit.rateAdaptation(isUnitExample(isValidUnitForClickRateInflection)) = 1;
iExamplePerUnit.lockingModulation(isUnitExample(isValidUnitForLockedFrGain)) = 1;

%% calculate stats and plot data per states pair.
for iState1 = nStates:-1:1
    for iState2 = iState1-1:-1:1
        [statsPerStatesPair(iState1,iState2),plotDataPerStatesPair(iState1,iState2)] = ...
            calcGainIndexAndStatsForStatesPair(iState1,iState2,sessionPerUnit, ...
            channelPerUnit, clicksLockedFr, isValidUnitForLockedFrGain, ...
            isValidUnitForClickRateInflection, clickRateOfHalfResponse, decayPerHz, rms, ...
            clickRate25Percent, normalizedResponsePerStateAndUnit, minUnitsPerSess, ...
            minUnitsPerAnimal,clickRateHz);

        plotDataPerStatesPair(iState1,iState2).adaptationRateVsModulation.stateUsedToCalculateAdaptationRate = statesData{iState2}.info;

    end
end

function [stats,plotData] = calcGainIndexAndStatsForStatesPair(iState1, iState2, ...
    sessionPerUnit,channelPerUnit, clicksLockedFr, isValidUnitForLockedFrGain, ...
    isValidUnitForClickRateInflection, clickRateOfHalfResponse, decayPerHz, rms, ...
    clickRate25Percent, normalizedResponsePerStateAndUnit, minUnitsPerSess, ...
    minUnitsPerAnimal,clickRateHz)

MULTIPLY_TO_PERCENTS = 100;
clickRateOfQuarterResponseValid = clickRate25Percent([iState1,iState2],isValidUnitForClickRateInflection);
gainIndexClickRateQuarterResponse = getGainIndex(...
    clickRate25Percent(iState1,isValidUnitForClickRateInflection),...
    clickRate25Percent(iState2,isValidUnitForClickRateInflection))*MULTIPLY_TO_PERCENTS;

gainIndexClickRateHalfResponse = getGainIndex(...
    clickRateOfHalfResponse(iState1,isValidUnitForClickRateInflection),...
    clickRateOfHalfResponse(iState2,isValidUnitForClickRateInflection))*MULTIPLY_TO_PERCENTS;

clear gainIndex
iMeasure = 0;
iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{iState1}(isValidUnitForLockedFrGain,1),...
    clicksLockedFr{iState2}(isValidUnitForLockedFrGain,1))*MULTIPLY_TO_PERCENTS;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = '2 Hz locking';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{iState1}(isValidUnitForLockedFrGain,2),...
    clicksLockedFr{iState2}(isValidUnitForLockedFrGain,2))*MULTIPLY_TO_PERCENTS;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = '10 Hz locking';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{iState1}(isValidUnitForLockedFrGain,3),...
    clicksLockedFr{iState2}(isValidUnitForLockedFrGain,3))*MULTIPLY_TO_PERCENTS;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = '20 Hz locking';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{iState1}(isValidUnitForLockedFrGain,4),...
    clicksLockedFr{iState2}(isValidUnitForLockedFrGain,4))*MULTIPLY_TO_PERCENTS;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = '30 Hz locking';

iMeasure = iMeasure+1;
gainIndex{iMeasure} = getGainIndex(clicksLockedFr{iState1}(isValidUnitForLockedFrGain,5),...
    clicksLockedFr{iState2}(isValidUnitForLockedFrGain,5))*MULTIPLY_TO_PERCENTS;
cohenDZ(iMeasure) = getCohensDZ(gainIndex{iMeasure});
measureStr{iMeasure} = '40 Hz locking';


%% Stats
[sessionsStr,~,iSessionPerUnit] = unique(sessionPerUnit);
nSessions = length(sessionsStr);
meanValPerSess = nan(nSessions,1);
isSessWithEnoughUnits = false(nSessions,1);
isSessWithEnoughUnitsValidForRate = false(nSessions,1);

iSessionPerUnitValidForRate = iSessionPerUnit(isValidUnitForClickRateInflection);
iSessionPerUnitValidForGain = iSessionPerUnit(isValidUnitForLockedFrGain);
for iSess = 1:nSessions
    isSessWithEnoughUnitsValidForRate(iSess) = sum(iSessionPerUnitValidForRate==iSess)>=minUnitsPerSess;
    isSessWithEnoughUnits(iSess) = sum(iSessionPerUnitValidForGain==iSess)>=minUnitsPerSess;
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end
[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);

iAnimalPerUnit = iAnimalPerSession(iSessionPerUnit);
iAnimalPerUnitValidForRate = iAnimalPerUnit(isValidUnitForClickRateInflection);
iAnimalPerUnitValidForGain = iAnimalPerUnit(isValidUnitForLockedFrGain);
isAnimalWithEnoughUnits = false(nAnimals,1);
isAnimalWithEnoughUnitsValidForRate = false(nAnimals,1);

for iAnimal = 1:nAnimals
    isAnimalWithEnoughUnits(iAnimal) = sum(iAnimalPerUnitValidForGain==iAnimal)>=minUnitsPerAnimal;
    isAnimalWithEnoughUnitsValidForRate(iAnimal) = sum(iAnimalPerUnitValidForRate==iAnimal)>=minUnitsPerAnimal;
end

nMeasures = length(gainIndex);
for iMeasure = 1:nMeasures
    gainIndexPerSession{iMeasure} = nan(nSessions,1);
    for iSess = 1:nSessions
        gainIndexPerSession{iMeasure}(iSess) = nanmean(gainIndex{iMeasure}(iSessionPerUnitValidForGain==iSess));
    end
    gainIndexPerSession{iMeasure}= gainIndexPerSession{iMeasure}(isSessWithEnoughUnits);
    
    gainIndexPerAnimal{iMeasure} = nan(nAnimals,1);
    for iAnimal = 1:nAnimals
        gainIndexPerAnimal{iMeasure}(iAnimal) = nanmean(gainIndex{iMeasure}(iAnimalPerUnitValidForGain==iAnimal));
    end
    gainIndexPerAnimal{iMeasure} = gainIndexPerAnimal{iMeasure}(isAnimalWithEnoughUnits);
end

plotData.lockedFrModulation.gainIndexPerUnit = gainIndex;
plotData.lockedFrModulation.gainIndexPerSession = gainIndexPerSession;
plotData.lockedFrModulation.gainIndexPerAnimal = gainIndexPerAnimal;
plotData.lockedFrModulation.sessionPerUnit = sessionPerUnit(isValidUnitForLockedFrGain);

%% Gain for click-rate of 1/4 response (75% adaptation) per session/animal
gainIndexRateQuarterPerSession = nan(nSessions,1);
clickRateInflectionPerSessionAndState =  nan(nSessions,2);
for iSess = 1:nSessions
    gainIndexRateQuarterPerSession(iSess) = nanmean(gainIndexClickRateQuarterResponse(iSessionPerUnitValidForRate==iSess));
    clickRateInflectionPerSessionAndState(iSess,:) = ...
        geomean(clickRateOfQuarterResponseValid(:,iSessionPerUnitValidForRate==iSess),2);
end
gainIndexRateQuarterPerSession = gainIndexRateQuarterPerSession(isSessWithEnoughUnitsValidForRate);

gainIndexRateQuarterPerAnimal = nan(nAnimals,1);
for iAnimal = 1:nAnimals
    gainIndexRateQuarterPerAnimal(iAnimal) = nanmean(gainIndexClickRateQuarterResponse(iAnimalPerUnitValidForRate==iAnimal));
end
gainIndexRateQuarterPerAnimal = gainIndexRateQuarterPerAnimal(isAnimalWithEnoughUnitsValidForRate);

plotData.rateOfQuarterResponse.ratePerUnit = clickRateOfQuarterResponseValid;
plotData.rateOfQuarterResponse.gainIndexPerUnit = gainIndexClickRateQuarterResponse;
plotData.rateOfQuarterResponse.gainIndexPerSession = gainIndexRateQuarterPerSession;
plotData.rateOfQuarterResponse.gainIndexPerAnimal = gainIndexRateQuarterPerAnimal;
plotData.rateOfQuarterResponse.sessionPerUnit = sessionPerUnit(isValidUnitForClickRateInflection);

%% Stats click rate of 1/4 adaptation
WSRT_STR = 'Wilcoxon Sign Rank Test';

%% %% Linear Mixed Effects - click rate of 1/2 adaptation (alternative to the original 1/4)

[lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
    gainIndexClickRateHalfResponse, iAnimalPerUnit(isValidUnitForClickRateInflection),...
    iSessionPerUnit(isValidUnitForClickRateInflection), ...
    channelPerUnit(isValidUnitForClickRateInflection));
stats.rateOfAdaptation50Alternative.linearMixedEffects.model = lme;
stats.rateOfAdaptation50Alternative.linearMixedEffects.meanGain = miEstimated;
stats.rateOfAdaptation50Alternative.linearMixedEffects.semGain = stdError;
stats.rateOfAdaptation50Alternative.linearMixedEffects.p = pValue;
stats.rateOfAdaptation50Alternative.linearMixedEffects.t = tStat;
stats.rateOfAdaptation50Alternative.linearMixedEffects.df = df;
stats.rateOfAdaptation50Alternative.linearMixedEffects.gainCI = miCI95;
stats.rateOfAdaptation50Alternative.linearMixedEffects.test = 'Linear Mixed Effects Model';
stats.rateOfAdaptation50Alternative.linearMixedEffects.test = 'This is alternative for ''rateOfAdaptation'' that uses 50% instead of 25% to show it works across different values ';

%% Linear Mixed Effects - click rate of 1/4 adaptation
[lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
    gainIndexClickRateQuarterResponse, iAnimalPerUnit(isValidUnitForClickRateInflection),...
    iSessionPerUnit(isValidUnitForClickRateInflection), ...
    channelPerUnit(isValidUnitForClickRateInflection));
stats.rateOfAdaptation.linearMixedEffects.model = lme;
stats.rateOfAdaptation.linearMixedEffects.meanGain = miEstimated;
stats.rateOfAdaptation.linearMixedEffects.semGain = stdError;
stats.rateOfAdaptation.linearMixedEffects.p = pValue;
stats.rateOfAdaptation.linearMixedEffects.t = tStat;
stats.rateOfAdaptation.linearMixedEffects.df = df;
stats.rateOfAdaptation.linearMixedEffects.gainCI = miCI95;
stats.rateOfAdaptation.linearMixedEffects.test = 'Linear Mixed Effects Model';

%% per unit - click rate of 1/4 adaptation
stats.rateOfAdaptation.perUnit.meanGain = mean(gainIndexClickRateQuarterResponse);
stats.rateOfAdaptation.perUnit.medianGain = median(gainIndexClickRateQuarterResponse);
stats.rateOfAdaptation.perUnit.geomeanRateHz = geomean(clickRateOfQuarterResponseValid,2);
stats.rateOfAdaptation.perUnit.semGain =std(gainIndexClickRateQuarterResponse)./ ...
    sqrt(length(gainIndexClickRateQuarterResponse));
[stats.rateOfAdaptation.perUnit.p,~,statsSignrank] = signrank(gainIndexClickRateQuarterResponse);
if isfield(statsSignrank,'zval')
    stats.rateOfAdaptation.perUnit.z = statsSignrank.zval;
end
stats.rateOfAdaptation.perUnit.n = length(gainIndexClickRateQuarterResponse);
stats.rateOfAdaptation.perUnit.test = WSRT_STR;
stats.rateOfAdaptation.perSession.meanGain = mean(gainIndexRateQuarterPerSession);
stats.rateOfAdaptation.perSession.medianGain = median(gainIndexRateQuarterPerSession);
stats.rateOfAdaptation.perSession.geomeanRateHz = geomean(clickRateInflectionPerSessionAndState,1);
stats.rateOfAdaptation.perSession.semGain =std(gainIndexRateQuarterPerSession)./...
    sqrt(length(gainIndexRateQuarterPerSession));
[stats.rateOfAdaptation.perSession.p,~,statsSignrank] = signrank(gainIndexRateQuarterPerSession);
if isfield(statsSignrank,'zval')
    stats.rateOfAdaptation.perSession.z = statsSignrank.zval;
end
stats.rateOfAdaptation.perSession.n = length(gainIndexRateQuarterPerSession);
stats.rateOfAdaptation.perSession.test = WSRT_STR;


stats.rateOfAdaptation.perAnimal.meanGain = mean(gainIndexRateQuarterPerAnimal);
stats.rateOfAdaptation.perAnimal.medianGain = median(gainIndexRateQuarterPerAnimal);
stats.rateOfAdaptation.perAnimal.semGain =std(gainIndexRateQuarterPerAnimal)./...
    sqrt(length(gainIndexRateQuarterPerAnimal));
[stats.rateOfAdaptation.perAnimal.p,~,statsSignrank] = signrank(gainIndexRateQuarterPerAnimal);
if isfield(statsSignrank,'zval')
    stats.rateOfAdaptation.perAnimal.z = statsSignrank.zval;
end
stats.rateOfAdaptation.perAnimal.n = length(gainIndexRateQuarterPerAnimal);
stats.rateOfAdaptation.perAnimal.test = WSRT_STR;

%% gain for different click rates
for iMeasure = 1:nMeasures
    currentGainIndex1 = gainIndex{iMeasure};
    
    %% Linear Mixed Effects 
    [lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
        currentGainIndex1, iAnimalPerUnit(isValidUnitForLockedFrGain),...
        iSessionPerUnit(isValidUnitForLockedFrGain), ...
        channelPerUnit(isValidUnitForLockedFrGain));
    stats.diffFrom0(iMeasure).linearMixedEffects.model = lme;
    stats.diffFrom0(iMeasure).linearMixedEffects.meanGain = miEstimated;
    stats.diffFrom0(iMeasure).linearMixedEffects.semGain = stdError;
    stats.diffFrom0(iMeasure).linearMixedEffects.p = pValue;
    stats.diffFrom0(iMeasure).linearMixedEffects.t = tStat;
    stats.diffFrom0(iMeasure).linearMixedEffects.df = df;
    stats.diffFrom0(iMeasure).linearMixedEffects.gainCI = miCI95;
    stats.diffFrom0(iMeasure).linearMixedEffects.test = 'Linear Mixed Effects Model';
    
    %% Stats Per Unit
    stats.diffFrom0(iMeasure).perUnit.meanGain = mean(currentGainIndex1);
    stats.diffFrom0(iMeasure).perUnit.medianGain = median(currentGainIndex1);
    stats.diffFrom0(iMeasure).perUnit.semGain = std(currentGainIndex1)./sqrt(length(currentGainIndex1));
    [stats.diffFrom0(iMeasure).perUnit.p,~,statsSignrank] = signrank(currentGainIndex1);
    if isfield(statsSignrank,'zval')
        stats.diffFrom0(iMeasure).perUnit.z = statsSignrank.zval;
    end
    stats.diffFrom0(iMeasure).perUnit.n = length(currentGainIndex1);
    stats.diffFrom0(iMeasure).perUnit.test = WSRT_STR;
    
    gainIndexForComparingBetweenMeasures1 = currentGainIndex1;
    if mean(gainIndexForComparingBetweenMeasures1)<0
        gainIndexForComparingBetweenMeasures1 = -gainIndexForComparingBetweenMeasures1;
    end
    
    %% compare pairs of click rates
    for iMeasure2 = iMeasure+1:nMeasures
        gainIndexForComparingBetweenMeasures2 = gainIndex{iMeasure2};
        %QWERTY - Continue Here to add LME
        if nanmean(gainIndexForComparingBetweenMeasures2)<0
            gainIndexForComparingBetweenMeasures2 = -gainIndexForComparingBetweenMeasures2;
        end
        
        %% Linear Mixed Effects 
        [lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
            gainIndexForComparingBetweenMeasures1-gainIndexForComparingBetweenMeasures2,...
            iAnimalPerUnit(isValidUnitForLockedFrGain), iSessionPerUnit(isValidUnitForLockedFrGain), ...
            channelPerUnit(isValidUnitForLockedFrGain));
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.model = lme;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.meanGain = miEstimated;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.semGain = stdError;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.p = pValue;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.t = tStat;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.df = df;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.gainCI = miCI95;
        stats.diffBetweenMeasures(iMeasure,iMeasure2).linearMixedEffects.test = 'Linear Mixed Effects Model';
        
        1;
        %% Per unit Wilcoxon Sign-rank
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
    stats.diffFrom0(iMeasure).perSession.meanGain = mean(gainIndexPerSession{iMeasure});
    stats.diffFrom0(iMeasure).perSession.medianGain = median(gainIndexPerSession{iMeasure});
    stats.diffFrom0(iMeasure).perSession.semGain = std(gainIndexPerSession{iMeasure})./sqrt(length(gainIndexPerSession{iMeasure}));
    [stats.diffFrom0(iMeasure).perSession.p,~,statsSignrank] = signrank(gainIndexPerSession{iMeasure});
    if isfield(statsSignrank,'zval')
        stats.diffFrom0(iMeasure).perSession.z = statsSignrank.zval;
    end
    stats.diffFrom0(iMeasure).perSession.n = length(gainIndexPerSession{iMeasure});
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
    stats.diffFrom0(iMeasure).perAnimal.meanGain = mean(gainIndexPerAnimal{iMeasure});
    stats.diffFrom0(iMeasure).perAnimal.medianGain = median(gainIndexPerAnimal{iMeasure});
    stats.diffFrom0(iMeasure).perAnimal.semGain = std(gainIndexPerAnimal{iMeasure})./sqrt(length(gainIndexPerAnimal{iMeasure}));
    [stats.diffFrom0(iMeasure).perAnimal.p,~,statsSignrank] = signrank(gainIndexPerAnimal{iMeasure});
    if isfield(statsSignrank,'zval')
        stats.diffFrom0(iMeasure).perAnimal.z = statsSignrank.zval;
    end
    stats.diffFrom0(iMeasure).perAnimal.n = length(gainIndexPerAnimal{iMeasure});
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
    
    %%
    
    
    1;
end
FRIEDMAN_STR = 'Friedman Test';
[p,~,statsFriedman] = friedman([gainIndex{1},gainIndex{2},gainIndex{3},gainIndex{4},gainIndex{5}],1,'off');
stats.varianceAcrossMeasures.perUnit.p = p;
stats.varianceAcrossMeasures.perUnit.n = statsFriedman.n;
stats.varianceAcrossMeasures.perUnit.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perUnit.stats = statsFriedman;

[p,~,statsFriedman] = friedman([gainIndexPerSession{1}, gainIndexPerSession{2}, ...
    gainIndexPerSession{3}, gainIndexPerSession{4}, gainIndexPerSession{5}],1,'off');
stats.varianceAcrossMeasures.perSession.p = p;
stats.varianceAcrossMeasures.perSession.n = statsFriedman.n;
stats.varianceAcrossMeasures.perSession.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perSession.stats = statsFriedman;

[p,~,statsFriedman] = friedman([gainIndexPerAnimal{1}, gainIndexPerAnimal{2}, ...
    gainIndexPerAnimal{3}, gainIndexPerAnimal{4}, gainIndexPerAnimal{5}],1,'off');
stats.varianceAcrossMeasures.perAnimal.p = p;
stats.varianceAcrossMeasures.perAnimal.n = statsFriedman.n;
stats.varianceAcrossMeasures.perAnimal.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perAnimal.stats = statsFriedman;


stats.selection.sessions.minUnitsPerSess = minUnitsPerSess;
stats.selection.sessions.isEnoughUnits = isSessWithEnoughUnits;
stats.selection.animals.minUnitsPerSess = minUnitsPerAnimal;
stats.selection.animals.isEnoughUnits = isAnimalWithEnoughUnits;


%%

isValidForModulationAndRateFit = isValidUnitForLockedFrGain & isValidUnitForClickRateInflection';
SPEARMAN_STR = 'Spearman Correlation';
for iMeasure = nMeasures:-1:1
    gainIndexMatchedToRate(:,iMeasure) = gainIndex{iMeasure}(isValidUnitForClickRateInflection(isValidUnitForLockedFrGain));
end
clickRateOfQuarterResponseValidForBoth = clickRate25Percent(iState2,isValidForModulationAndRateFit);
nValidUnits = sum(isValidForModulationAndRateFit);
for iUnit=nValidUnits:-1:1
    gainIndexCurrentUnit = gainIndexMatchedToRate(iUnit,:);
    [maxGainCurrentUnit,iMin] = min(gainIndexCurrentUnit); %negative gain
    iFirstCloseToMax = find(gainIndexCurrentUnit<0.95*maxGainCurrentUnit,1,'first');
    clickRateOfMaxModulation(iUnit) = clickRateHz(iMin);
    if isempty(iFirstCloseToMax)
        iFirstCloseToMax = iMin;
    end
    clickRateFirstCloseToMaxModulation(iUnit) = clickRateHz(iFirstCloseToMax);

end
[rho2,p2] = corr(clickRateOfMaxModulation',clickRateOfQuarterResponseValidForBoth','type','spearman');
[rho,p] = corr(clickRateFirstCloseToMaxModulation',clickRateOfQuarterResponseValidForBoth','type','spearman');

plotData.adaptationRateVsModulation.maxModulationRate = clickRateOfMaxModulation;
plotData.adaptationRateVsModulation.quarterResponseRate = clickRateOfQuarterResponseValidForBoth;


stats.corrAdaptationRateMaxModulation.perUnit.p = p;
stats.corrAdaptationRateMaxModulation.perUnit.rho = rho;
stats.corrAdaptationRateMaxModulation.perUnit.n = length(clickRateOfQuarterResponseValidForBoth);
stats.corrAdaptationRateMaxModulation.perUnit.test = SPEARMAN_STR;
