function [stats,plotData] = calcTuningCorrelationAndStats(state1Data,state2Data, isValidUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning)

assert(numel(exampleUnitTuning)==1); %assert only one example,old relic when I used to plot multiple examples
exampleUnits(1) = exampleUnitTuning; %old relic when I used to plot multiple examples
allExampleSessions = extractfield(exampleUnits,'session');
allExampleChannels = extractfield(exampleUnits,'ch');
allExampleClus = extractfield(exampleUnits,'clus');

unitDataAll = {state1Data.unitData(isValidUnit), state2Data.unitData(isValidUnit)}; %{unitData1,unitData2};
sessionPerUnit = extractfield(state1Data.unitData(isValidUnit),'session');
% nUnits = length(unitDataAll{1});

isUnitIncludedInAnalysis = isValidUnit;
iValidUnits = find(isValidUnit);
%% session and animal per unit
[sessionsStr,~,iSessionPerUnit] = unique(sessionPerUnit);
nSessions = length(sessionsStr);
isSessWithEnoughUnits = false(nSessions,1);
for iSess = 1:nSessions
    isSessWithEnoughUnits(iSess) = sum(iSessionPerUnit==iSess)>=minUnitsPerSess;
    animalAndSessNumStr = strsplit(sessionsStr{iSess},' - ');
    animalPerSession{iSess} = animalAndSessNumStr{1};
end
[animalStr,~,iAnimalPerSession] = unique(animalPerSession);
nAnimals = length(animalStr);

%% Consts and smoothing windows for STRFs and FRAs
N_STATES = 2;
N_HALVES = 2;
relevantTimeMs = [0,60];
% STRF smoothing
smoothWin = getGaussWin(5,30)';
% FRA smoothing
nFreqsSmoothFra = 3;
nSoundLevelsSmoothFra = 1;
smoothFraWin = ones(nSoundLevelsSmoothFra,nFreqsSmoothFra)./(nFreqsSmoothFra*nSoundLevelsSmoothFra);

%% Initialization of results arrays
strPerState{1} = state1Data.info.str;
strPerState{2} = state2Data.info.str;
meanCorrWithinStatePerUnitAll = [];
meanCorrBetweenStatesPerUnitAll = [];
meanCorrBetweenStatesWithOtherUnitsAll = [];
isContextSessPerUnitAll = false(0);
iAnimalPerUnit = [];
sessionStrPerUnitValid = [];
iExamplePerUnit = [];
tuningWidthFwhmOctPerUnitAndStateAll = [];
tuningWidthGainPerUnitAll = [];

meanCorrWithinStatePerSess = nan(nSessions,1);
meanCorrBetweenStatesPerSess = nan(nSessions,1);
meanCorrBetweenStatesDiffUnitsPerSess = nan(nSessions,1);
tuningWidthFwhmOctPerSessAndState = nan(nSessions,N_STATES);
tuningWidthGainPerSess = nan(nSessions,1);
isSessContext = false(nSessions,1);

%% Sessions Loop 
for iSess = 1:nSessions
    %% get units and animal of sess
    iUnitsOfSession = find(iSessionPerUnit==iSess);
    nUnitsInSess = length(iUnitsOfSession);
    iAnimalOfSession = iAnimalPerSession(iSess);
    
    %% initialization
    tuningMatPerUnitAndStateAndHalf = cell(nUnitsInSess,N_STATES, N_HALVES);
    corrsWithinStatePerUnitAndState = nan(nUnitsInSess,N_STATES);
    corrsBetweenStatesPerUnit = nan(nUnitsInSess,N_HALVES.^2);
    channelPerUnit = nan(nUnitsInSess,1);
    isUnitContext = false(nUnitsInSess,1);
    iAnimalPerUnitCurrentSess = ones(nUnitsInSess,1)*iAnimalOfSession;
    sessionStrPerUnitCurrentSess = sessionPerUnit(iUnitsOfSession)';
    iExamplePerUnitCurrentSess = nan(nUnitsInSess,1);
    tuningFwhmOctavesPerState = nan(nUnitsInSess,N_STATES);
    
    %% Units in Session Loop
    for iUnitInSess = nUnitsInSess:-1:1
        %% Get current Unit Info
        iUnit = iUnitsOfSession(iUnitInSess);
        isCurrentUnitContext = unitDataAll{1}(iUnit).isContext;
        currrentCh = unitDataAll{1}(iUnit).ch;
        currentClus = unitDataAll{1}(iUnit).clus;
        channelPerUnit(iUnitInSess) = currrentCh;
        isUnitContext(iUnitInSess) = isCurrentUnitContext;
        
        %% If current unit is an example unit, get STRF per state and unit info
        iExampleUnit = find(strcmp(allExampleSessions,sessionStrPerUnitCurrentSess{iUnitInSess}) & ...
            allExampleChannels==currrentCh & allExampleClus==currentClus);
        if ~isempty(iExampleUnit)
            exampleData.session = exampleUnits(iExampleUnit).session;
            exampleData.ch = exampleUnits(iExampleUnit).ch;
            exampleData.clus = exampleUnits(iExampleUnit).clus;  
            exampleData.unitStr = sprintf('%s Ch%d Clus%d',exampleUnits(iExampleUnit).session,...
                exampleUnits(iExampleUnit).ch,exampleUnits(iExampleUnit).clus);
            
            iExamplePerUnitCurrentSess(iUnitInSess) = iExampleUnit;
            if isCurrentUnitContext
                exampleData.freqs = unitDataAll{1}(iUnit).drc.freqs.valid;
                exampleData.timesPsthMs = unitDataAll{1}(iUnit).drc.timesPsthMs;
                exampleData.smoothWin = smoothWin;
                exampleData.relevantTimeMs = relevantTimeMs;
                exampleData.strPerState = strPerState;
                interFreqIntervalOctaves = mean(diff(log2(unitDataAll{1}(iUnit).drc.freqs.all)));
                for iState = 1:N_STATES
                    exampleData.strfExamplePerState{iState} = unitDataAll{iState}(iUnit).drc.psthPerFreq;
                    exampleData.meanFrPerFreqPerState{iState} = ...
                        unitDataAll{iState}(iUnit).drc.meanFrPerFreqSameTimeAllStates; 
                    
                    [exampleData.fwhmOctaves(iState),exampleData.iFwhm(iState).onset,...
                        exampleData.iFwhm(iState).offset] = getTuningWidth(...
                        exampleData.meanFrPerFreqPerState{iState},interFreqIntervalOctaves);
                end
                exampleData.peakTimeMsAllTrials = unitDataAll{iState}(iUnit).drc.peakTimeMsAllTrials;
            else
                error('handling of FRA example unit is not yet implemented')
            end
        end
        
        %%
        if isCurrentUnitContext
            timesPsthMs = unitDataAll{1}(iUnit).drc.timesPsthMs;
            isDuringRelevantTime = timesPsthMs>=relevantTimeMs(1) & timesPsthMs<relevantTimeMs(2);
            
            interFreqIntervalOctaves = mean(diff(log2(unitDataAll{1}(iUnit).drc.freqs.all)));
            
            for iState = 1:N_STATES
                stateData{iState} = unitDataAll{iState}(iUnit).drc.psthPerFreqPerHalf;
                
                frAroundPeak = getTuningAroundPeak(unitDataAll{iState}(iUnit).drc.meanFrPerFreqSameTimeAllStates);
                tuningFwhmOctavesPerState(iUnitInSess,iState) = getTuningWidth(frAroundPeak,interFreqIntervalOctaves);
                
                for iHalf = 1:N_HALVES
                    stateData{iState}{iHalf} = conv2(stateData{iState}{iHalf},smoothWin,'same');
                    stateData{iState}{iHalf} = stateData{iState}{iHalf}(:,isDuringRelevantTime);
                    tuningMatPerUnitAndStateAndHalf{iUnitInSess,iState,iHalf} = stateData{iState}{iHalf};
                end
            end
            
            
        else
            1;
                        interFreqIntervalOctaves = mean(diff(log2(unitDataAll{1}(iUnit).drc.freqs))); %QWERTY!

            for iState = 1:N_STATES
                stateData{iState} = unitDataAll{iState}(iUnit).drc.fraPerHalf;
                frPerFreqMaxSoundLevel = unitDataAll{iState}(iUnit).drc.fra(:,end);
                frAroundPeak = getTuningAroundPeak(frPerFreqMaxSoundLevel);
                tuningFwhmOctavesPerState(iUnitInSess,iState) = getTuningWidth(frAroundPeak,interFreqIntervalOctaves);
                for iHalf = 1:N_HALVES
                    stateData{iState}{iHalf} = conv2(stateData{iState}{iHalf}',smoothFraWin,'valid');
                    tuningMatPerUnitAndStateAndHalf{iUnitInSess,iState,iHalf} = stateData{iState}{iHalf};
                end
            end
        end
        %% calculate correlation within state for each unit (a control, the max corr. one can expect)
        for iState = 1:N_STATES
            corrsWithinStatePerUnitAndState(iUnitInSess,iState) = corr(tuningMatPerUnitAndStateAndHalf{iUnitInSess,iState,1}(:),...
                tuningMatPerUnitAndStateAndHalf{iUnitInSess,iState,2}(:));
        end
        %% calculate correlation across states for each unit (the signal corrtelation across states)
        for iHalf = 1:N_HALVES
            for iHalf2 = 1:N_HALVES
                iHalvesPair = (iHalf-1)*N_HALVES+iHalf2;
                corrsBetweenStatesPerUnit(iUnitInSess,iHalvesPair) = corr(...
                    tuningMatPerUnitAndStateAndHalf{iUnitInSess,1,iHalf}(:),...
                    tuningMatPerUnitAndStateAndHalf{iUnitInSess,2,iHalf2}(:));
            end
        end
    end
    
    %% calculate gain index per unit for tuning width (A-B)./MAX(A,B)
    CONVERT_TO_PERCENT = 100;
    gainIndexPerUnitCurrentSess = getGainIndex(tuningFwhmOctavesPerState(:,1),tuningFwhmOctavesPerState(:,2))*CONVERT_TO_PERCENT;
    
    %% calculate mean corr per unit
    meanCorrWithinStatePerUnit = nanmean(corrsWithinStatePerUnitAndState,2);
    meanCorrBetweenStatesPerUnit = nanmean(corrsBetweenStatesPerUnit,2);
    
    assert(all(isUnitContext) || ~any(isUnitContext))
    isSessContext(iSess) = all(isUnitContext);
    %% if there aren't at least two units on different channels then there is no control for the session and throw it out
    if length(unique(channelPerUnit))<2
        isUnitIncludedInAnalysis(iValidUnits(iUnitsOfSession)) = false;
        continue;
    end
    
    %% calculate correlation across states of different units (a control, the min corr. one can expect)
    corrBetweenStatesOfUnitPairs = nan(nUnitsInSess,nUnitsInSess,N_HALVES.^2);
    for iUnitInSess1 = 1:nUnitsInSess
        currentUnitChannel = channelPerUnit(iUnitInSess1);
        iUnitsOnDifferentChannels = find(channelPerUnit~=currentUnitChannel)';
        for iUnitInSess2 = iUnitsOnDifferentChannels %[1:iUnit1-1,iUnit1+1:nUnits]
            
            for iHalf = 1:N_HALVES
                for iHalf2 = 1:N_HALVES
                    iHalvesPair = (iHalf-1)*N_HALVES+iHalf2;
                    corrBetweenStatesOfUnitPairs(iUnitInSess1,iUnitInSess2,iHalvesPair) = corr(...
                        tuningMatPerUnitAndStateAndHalf{iUnitInSess1,1,iHalf}(:),...
                        tuningMatPerUnitAndStateAndHalf{iUnitInSess2,2,iHalf2}(:));
                end
            end
        end
    end
    
    meanCorrBetweenStatesWithOtherUnits = nan(nUnitsInSess,1);
    for iUnitInSess1 = 1:nUnitsInSess
        meanCorrBetweenStatesWithOtherUnits(iUnitInSess1) = mean(...
            [nanmean(corrBetweenStatesOfUnitPairs(iUnitInSess1,:,:),'all'),...
            nanmean(corrBetweenStatesOfUnitPairs(:,iUnitInSess1,:),'all')]);
    end
    
    %% append all current session results
    iExamplePerUnit = [iExamplePerUnit; iExamplePerUnitCurrentSess];
    iAnimalPerUnit = [iAnimalPerUnit; iAnimalPerUnitCurrentSess];
    sessionStrPerUnitValid = [sessionStrPerUnitValid; sessionStrPerUnitCurrentSess];
    isContextSessPerUnitAll = [isContextSessPerUnitAll; isUnitContext];
    meanCorrWithinStatePerUnitAll = [meanCorrWithinStatePerUnitAll; meanCorrWithinStatePerUnit];
    meanCorrBetweenStatesPerUnitAll = [meanCorrBetweenStatesPerUnitAll; meanCorrBetweenStatesPerUnit];
    meanCorrBetweenStatesWithOtherUnitsAll = [meanCorrBetweenStatesWithOtherUnitsAll; ...
        meanCorrBetweenStatesWithOtherUnits];
    tuningWidthFwhmOctPerUnitAndStateAll = [tuningWidthFwhmOctPerUnitAndStateAll; tuningFwhmOctavesPerState];
    tuningWidthGainPerUnitAll = [tuningWidthGainPerUnitAll; gainIndexPerUnitCurrentSess];
        
    meanCorrWithinStatePerSess(iSess) = mean(meanCorrWithinStatePerUnit);
    meanCorrBetweenStatesPerSess(iSess) = mean(meanCorrBetweenStatesPerUnit);
    meanCorrBetweenStatesDiffUnitsPerSess(iSess) = mean(meanCorrBetweenStatesWithOtherUnits);
    tuningWidthFwhmOctPerSessAndState(iSess,:) = nanmean(tuningFwhmOctavesPerState);
    tuningWidthGainPerSess(iSess) = nanmean(gainIndexPerUnitCurrentSess);
    
    
    
end

%% NEW for hierarchical clustering
[~,~,iSessionPerUnit] = unique(sessionStrPerUnitValid);
channelPerUnit = extractfield(state1Data.unitData,'ch')';
channelPerUnit = channelPerUnit(isUnitIncludedInAnalysis);

%% Data to plot
plotData.tuningWidthFwhmOctPerUnitAndStateAll = tuningWidthFwhmOctPerUnitAndStateAll;
plotData.tuningWidthGainPerUnitAll = tuningWidthGainPerUnitAll;
plotData.meanCorrBetweenStatesWithOtherUnitsAll = meanCorrBetweenStatesWithOtherUnitsAll;
plotData.exampleUnits = exampleUnits;
plotData.iExamplePerUnit = iExamplePerUnit;
plotData.meanCorrBetweenStatesPerUnitAll = meanCorrBetweenStatesPerUnitAll;
plotData.meanCorrWithinStatePerUnitAll = meanCorrWithinStatePerUnitAll;
plotData.sessionStrPerUnitValid = sessionStrPerUnitValid;
plotData.meanCorrBetweenStatesPerUnitAll = meanCorrBetweenStatesPerUnitAll;
plotData.minUnitsPerAnimal = minUnitsPerAnimal;
plotData.minUnitsPerSess = minUnitsPerSess;
plotData.example = exampleData;

%% Stats
WSRT_STR = 'Wilcoxon Sign Rank Test';
meanCorrWithinStatePerAnimal = nan(nAnimals,1);
meanCorrBetweenStatesPerAnimal = nan(nAnimals,1);
meanCorrBetweenStatesDiffUnitsPerAnimal = nan(nAnimals,1);
tuningWidthGainPerAnimal = nan(nAnimals,1);
tuningWidthFwhmOctPerAnimalAndState = nan(nAnimals,N_STATES);

isAnimalWithEnoughUnits = false(nAnimals,1);
for iAnimal = 1:nAnimals
    isAnimalWithEnoughUnits(iAnimal) = sum(iAnimalPerUnit==iAnimal)>=minUnitsPerAnimal;
    meanCorrWithinStatePerAnimal(iAnimal) = mean(...
        meanCorrWithinStatePerUnitAll(iAnimalPerUnit==iAnimal));
    meanCorrBetweenStatesPerAnimal(iAnimal) = mean(...
        meanCorrBetweenStatesPerUnitAll(iAnimalPerUnit==iAnimal));
    meanCorrBetweenStatesDiffUnitsPerAnimal(iAnimal) = mean(...
        meanCorrBetweenStatesWithOtherUnitsAll(iAnimalPerUnit==iAnimal));
    tuningWidthGainPerAnimal(iAnimal) = mean(tuningWidthGainPerUnitAll(iAnimalPerUnit==iAnimal));
    tuningWidthFwhmOctPerAnimalAndState(iAnimal,:) =  mean(...
        tuningWidthFwhmOctPerUnitAndStateAll(iAnimalPerUnit==iAnimal,:));
end

%% Stats - Tuning Width
stats.isUnitSignificantAndValid = isUnitIncludedInAnalysis;

% Linear Mixed Effects Model - Gain
[lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
    tuningWidthGainPerUnitAll, iAnimalPerUnit, iSessionPerUnit, channelPerUnit);
stats.width.gain.linearMixedEffects.model = lme;
stats.width.gain.linearMixedEffects.meanGain = miEstimated;
stats.width.gain.linearMixedEffects.semGain = stdError;
stats.width.gain.linearMixedEffects.p = pValue;
stats.width.gain.linearMixedEffects.t = tStat;
stats.width.gain.linearMixedEffects.df = df;
stats.width.gain.linearMixedEffects.gainCI = miCI95;
stats.width.gain.linearMixedEffects.test = 'Linear Mixed Effects Model';

% Per Unit - GAIN
stats.width.gain.perUnit.mean = mean(tuningWidthGainPerUnitAll);
stats.width.gain.perUnit.median = median(tuningWidthGainPerUnitAll);
stats.width.gain.perUnit.n = length(tuningWidthGainPerUnitAll);
stats.width.gain.perUnit.sem = std(tuningWidthGainPerUnitAll)./sqrt(length(tuningWidthGainPerUnitAll));
stats.width.gain.perUnit.test = WSRT_STR;
[stats.width.gain.perUnit.p,~,signRankStats] = signrank(tuningWidthGainPerUnitAll);
stats.width.gain.perUnit.z = signRankStats.zval;
% Per Unit - full-width-half-max octaves
stats.width.fwhmOctaves.perUnit.mean = mean(tuningWidthFwhmOctPerUnitAndStateAll);
stats.width.fwhmOctaves.perUnit.median = median(tuningWidthFwhmOctPerUnitAndStateAll);
stats.width.fwhmOctaves.perUnit.n = size(tuningWidthFwhmOctPerUnitAndStateAll,1);
stats.width.fwhmOctaves.perUnit.sem = std(tuningWidthFwhmOctPerUnitAndStateAll)./ ...
    sqrt(size(tuningWidthFwhmOctPerUnitAndStateAll,1));

%Per Session - GAIN 
tuningWidthGainPerValidSess = tuningWidthGainPerSess(isSessWithEnoughUnits);
stats.width.gain.perSession.mean = mean(tuningWidthGainPerValidSess);
stats.width.gain.perSession.median = median(tuningWidthGainPerValidSess);
stats.width.gain.perSession.n = length(tuningWidthGainPerValidSess);
stats.width.gain.perSession.sem = std(tuningWidthGainPerValidSess)./sqrt(length(tuningWidthGainPerValidSess));
stats.width.gain.perSession.test = WSRT_STR;
[stats.width.gain.perSession.p,~,signRankStats] = signrank(tuningWidthGainPerValidSess);
if (isfield(signRankStats,'zval'))
    stats.width.gain.perSession.z = signRankStats.zval;
end

%Per Session - full-width-half-max octaves
tuningWidthFwhmOctPerValidSessAndState = tuningWidthFwhmOctPerSessAndState(isSessWithEnoughUnits,:);
stats.width.fwhmOctaves.perSession.mean = mean(tuningWidthFwhmOctPerValidSessAndState);
stats.width.fwhmOctaves.perSession.median = median(tuningWidthFwhmOctPerValidSessAndState);
stats.width.fwhmOctaves.perSession.n = size(tuningWidthFwhmOctPerValidSessAndState,1);
stats.width.fwhmOctaves.perSession.sem = std(tuningWidthFwhmOctPerValidSessAndState)./ ...
    sqrt(size(tuningWidthFwhmOctPerValidSessAndState,1));

%Per Animal - GAIN
tuningWidthGainPerValidAnimal = tuningWidthGainPerAnimal(isAnimalWithEnoughUnits);
stats.width.gain.perAnimal.mean = mean(tuningWidthGainPerValidAnimal);
stats.width.gain.perAnimal.median = median(tuningWidthGainPerValidAnimal);
stats.width.gain.perAnimal.n = length(tuningWidthGainPerValidAnimal);
stats.width.gain.perAnimal.sem = std(tuningWidthGainPerValidAnimal)./sqrt(length(tuningWidthGainPerValidAnimal));
stats.width.gain.perAnimal.test = WSRT_STR;
[stats.width.gain.perAnimal.p,~,signRankStats] = signrank(tuningWidthGainPerValidAnimal);
if (isfield(signRankStats,'zval'))
    stats.width.gain.perAnimal.z = signRankStats.zval;
end

%Per Animal - full-width-half-max octaves
tuningWidthFwhmOctPerValidAnimalAndState = tuningWidthFwhmOctPerAnimalAndState(isAnimalWithEnoughUnits,:);
stats.width.fwhmOctaves.perSession.mean = mean(tuningWidthFwhmOctPerValidAnimalAndState);
stats.width.fwhmOctaves.perSession.median = median(tuningWidthFwhmOctPerValidAnimalAndState);
stats.width.fwhmOctaves.perSession.n = size(tuningWidthFwhmOctPerValidAnimalAndState,1);
stats.width.fwhmOctaves.perSession.sem = std(tuningWidthFwhmOctPerValidAnimalAndState)./ ...
    sqrt(size(tuningWidthFwhmOctPerValidAnimalAndState,1));

1;
%% Stats Per Unit - Signal (tuning) Correlation
stats.corr.withinState.perUnit.mean = mean(meanCorrWithinStatePerUnitAll);
stats.corr.withinState.perUnit.median = median(meanCorrWithinStatePerUnitAll);
stats.corr.withinState.perUnit.n = length(meanCorrWithinStatePerUnitAll);
stats.corr.withinState.perUnit.sem = ...
    std(meanCorrWithinStatePerUnitAll)./sqrt(length(meanCorrWithinStatePerUnitAll));

stats.corr.betweenStates.perUnit.mean = mean(meanCorrBetweenStatesPerUnitAll);
stats.corr.betweenStates.perUnit.median = median(meanCorrBetweenStatesPerUnitAll);
stats.corr.betweenStates.perUnit.n = length(meanCorrBetweenStatesPerUnitAll);
stats.corr.betweenStates.perUnit.sem = ...
    std(meanCorrBetweenStatesPerUnitAll)./sqrt(length(meanCorrBetweenStatesPerUnitAll));

stats.corr.diffUnitsBetweenStates.perUnit.mean = mean(meanCorrBetweenStatesWithOtherUnitsAll);
stats.corr.diffUnitsBetweenStates.perUnit.median = median(meanCorrBetweenStatesWithOtherUnitsAll);
stats.corr.diffUnitsBetweenStates.perUnit.n = length(meanCorrBetweenStatesWithOtherUnitsAll);
stats.corr.diffUnitsBetweenStates.perUnit.sem = ...
    std(meanCorrBetweenStatesWithOtherUnitsAll)./sqrt(length(meanCorrBetweenStatesWithOtherUnitsAll));


nValidUnits = length(iAnimalPerUnit);
%% Compare Signal correlation Between states vs. within states
% Linear Mixed Effects Model
[lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
    meanCorrBetweenStatesPerUnitAll-meanCorrWithinStatePerUnitAll, iAnimalPerUnit, ...
    iSessionPerUnit, channelPerUnit);
stats.compareConditions.betweenVsWithin.linearMixedEffects.model = lme;
stats.compareConditions.betweenVsWithin.linearMixedEffects.meanGain = miEstimated;
stats.compareConditions.betweenVsWithin.linearMixedEffects.semGain = stdError;
stats.compareConditions.betweenVsWithin.linearMixedEffects.p = pValue;
stats.compareConditions.betweenVsWithin.linearMixedEffects.t = tStat;
stats.compareConditions.betweenVsWithin.linearMixedEffects.df = df;
stats.compareConditions.betweenVsWithin.linearMixedEffects.gainCI = miCI95;
stats.compareConditions.betweenVsWithin.linearMixedEffects.test = 'Linear Mixed Effects Model';

% Per Unit Signrank
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrBetweenStatesPerUnitAll,meanCorrWithinStatePerUnitAll);
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidUnits;
tempStats.test = WSRT_STR;
stats.compareConditions.betweenVsWithin.perUnit = tempStats;

%% Compare Signal correlation Between states vs. different units between states
% Linear Mixed Effects Model
[lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
    meanCorrBetweenStatesPerUnitAll-meanCorrBetweenStatesWithOtherUnitsAll, iAnimalPerUnit, ...
    iSessionPerUnit, channelPerUnit);
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.model = lme;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.meanGain = miEstimated;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.semGain = stdError;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.p = pValue;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.t = tStat;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.df = df;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.gainCI = miCI95;
stats.compareConditions.betweenVsDiffUnitsBetween.linearMixedEffects.test = 'Linear Mixed Effects Model';

% Per Unit Signrank
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrBetweenStatesPerUnitAll,meanCorrBetweenStatesWithOtherUnitsAll);
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidUnits;
tempStats.test = WSRT_STR;
stats.compareConditions.betweenVsDiffUnitsBetween.perUnit = tempStats;

%% Compare Signal correlation same unit within state vs. different units between states -
% kind of uninteresting comparison as both ar type of control
% Linear Mixed Effects Model
[lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex(...
    meanCorrWithinStatePerUnitAll-meanCorrBetweenStatesWithOtherUnitsAll, iAnimalPerUnit, ...
    iSessionPerUnit, channelPerUnit);
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.model = lme;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.meanGain = miEstimated;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.semGain = stdError;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.p = pValue;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.t = tStat;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.df = df;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.gainCI = miCI95;
stats.compareConditions.withinVsDiffUnitsBetween.linearMixedEffects.test = 'Linear Mixed Effects Model';

% Per Unit Signrank
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrWithinStatePerUnitAll,meanCorrBetweenStatesWithOtherUnitsAll);
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidUnits;
tempStats.test = WSRT_STR;
stats.compareConditions.withinVsDiffUnitsBetween.perUnit = tempStats;

%% Stats Per Session
tempData = meanCorrWithinStatePerSess(isSessWithEnoughUnits);
stats.corr.withinState.perSession.mean = mean(tempData);
stats.corr.withinState.perSession.median = median(tempData);
stats.corr.withinState.perSession.n = length(tempData);
stats.corr.withinState.perSession.sem = ...
    std(tempData)./sqrt(length(tempData));

tempData = meanCorrBetweenStatesPerSess(isSessWithEnoughUnits);
stats.corr.betweenStates.perSession.mean = mean(tempData);
stats.corr.betweenStates.perSession.median = median(tempData);
stats.corr.betweenStates.perSession.n = length(tempData);
stats.corr.betweenStates.perSession.sem = ...
    std(tempData)./sqrt(length(tempData));


tempData = meanCorrBetweenStatesDiffUnitsPerSess(isSessWithEnoughUnits);
stats.corr.diffUnitsBetweenStates.perSession.mean = mean(tempData);
stats.corr.diffUnitsBetweenStates.perSession.median = median(tempData);
stats.corr.diffUnitsBetweenStates.perSession.n = length(tempData);
stats.corr.diffUnitsBetweenStates.perSession.sem = ...
    std(tempData)./sqrt(length(tempData));


nValidSessions = sum(isSessWithEnoughUnits);
% Compare Signal correlation Between states vs. within states
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrBetweenStatesPerSess(isSessWithEnoughUnits),meanCorrWithinStatePerSess(isSessWithEnoughUnits));
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidSessions;
tempStats.test = WSRT_STR;
stats.compareConditions.betweenVsWithin.perSession = tempStats;

% Compare Signal correlation Between states vs. different units between states
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrBetweenStatesPerSess(isSessWithEnoughUnits),meanCorrBetweenStatesDiffUnitsPerSess(isSessWithEnoughUnits));
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidSessions;
tempStats.test = WSRT_STR;
stats.compareConditions.betweenVsDiffUnitsBetween.perSession = tempStats;

% Compare Signal correlation same unit within state vs. different units between states -
% kind of uninteresting comparison as both are type of control
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrWithinStatePerSess(isSessWithEnoughUnits),meanCorrBetweenStatesDiffUnitsPerSess(isSessWithEnoughUnits));
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidSessions;
tempStats.test = WSRT_STR;
stats.compareConditions.withinVsDiffUnitsBetween.perSession = tempStats;


%% Stats Per Animal
tempData = meanCorrWithinStatePerAnimal(isAnimalWithEnoughUnits);
stats.corr.withinState.perAnimal.mean = mean(tempData);
stats.corr.withinState.perAnimal.median = median(tempData);
stats.corr.withinState.perAnimal.n = length(tempData);
stats.corr.withinState.perAnimal.sem = ...
    std(tempData)./sqrt(length(tempData));

tempData = meanCorrBetweenStatesPerAnimal(isAnimalWithEnoughUnits);
stats.corr.betweenStates.perAnimal.mean = mean(tempData);
stats.corr.betweenStates.perAnimal.median = median(tempData);
stats.corr.betweenStates.perAnimal.n = length(tempData);
stats.corr.betweenStates.perAnimal.sem = ...
    std(tempData)./sqrt(length(tempData));

tempData = meanCorrBetweenStatesDiffUnitsPerAnimal(isAnimalWithEnoughUnits);
stats.corr.diffUnitsBetweenStates.perAnimal.mean = mean(tempData);
stats.corr.diffUnitsBetweenStates.perAnimal.median = median(tempData);
stats.corr.diffUnitsBetweenStates.perAnimal.n = length(tempData);
stats.corr.diffUnitsBetweenStates.perAnimal.sem = ...
    std(tempData)./sqrt(length(tempData));

nValidAnimals = sum(isAnimalWithEnoughUnits);
% Compare Signal correlation Between states vs. within states
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrBetweenStatesPerAnimal(isAnimalWithEnoughUnits),meanCorrWithinStatePerAnimal(isAnimalWithEnoughUnits));
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidAnimals;
tempStats.test = WSRT_STR;
stats.compareConditions.betweenVsWithin.perAnimal = tempStats;

% Compare Signal correlation Between states vs. different units between states
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrBetweenStatesPerAnimal(isAnimalWithEnoughUnits),meanCorrBetweenStatesDiffUnitsPerAnimal(isAnimalWithEnoughUnits));
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidAnimals;
tempStats.test = WSRT_STR;
stats.compareConditions.betweenVsDiffUnitsBetween.perAnimal = tempStats;

% Compare Signal correlation same unit within state vs. different units between states -
% kind of uninteresting comparison as both ar type of control
clear tempStats
[tempStats.p,~,statsSignrank] = signrank(...
    meanCorrWithinStatePerAnimal(isAnimalWithEnoughUnits),meanCorrBetweenStatesDiffUnitsPerAnimal(isAnimalWithEnoughUnits));
if isfield(statsSignrank,'zval')
    tempStats.z = statsSignrank.zval;
end
tempStats.n = nValidAnimals;
tempStats.test = WSRT_STR;
stats.compareConditions.withinVsDiffUnitsBetween.perAnimal = tempStats;

%%
stats.selection.sessions.minUnitsPerSess = minUnitsPerSess;
stats.selection.sessions.isEnoughUnits = isSessWithEnoughUnits;
stats.selection.animals.minUnitsPerSess = minUnitsPerAnimal;
stats.selection.animals.isEnoughUnits = isAnimalWithEnoughUnits;

1;