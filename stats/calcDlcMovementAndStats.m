function [stats,plotData] = calcDlcMovementAndStats(dlcPerSess)

relventStates = {'AW','SD1','SD3','NREM','REM'};
relventStatesLabels = {'AW','Vigilant','Tired','NREM','REM'};
WSRT_STR = 'Wilcoxon Sign Rank Test';
FRIEDMAN_STR = 'Friedman Test';
nRelevantStates = length(relventStates);
iPerState = nan(nRelevantStates,1);
for iState1 = 1:nRelevantStates
    iPerState(iState1) = find(strcmp(dlcPerSess.states,relventStates{iState1}));
end

movementPerSessAndState = dlcPerSess.movement(:,iPerState);

isNanSessionAnyState = any(isnan(movementPerSessAndState),2);
movementPerSessAndStateValid = movementPerSessAndState(~isNanSessionAnyState,:);
[p,~,statsFriedman] = friedman(movementPerSessAndStateValid,1,'off');
stats.varianceAcrossMeasures.perSession.p = p;
stats.varianceAcrossMeasures.perSession.n = statsFriedman.n;
stats.varianceAcrossMeasures.perSession.test = FRIEDMAN_STR;
stats.varianceAcrossMeasures.perSession.stats = statsFriedman;

for iState1 = 1:nRelevantStates
    for iState2 = iState1+1:nRelevantStates 
        stats.diffBetweenMeasures(iState1,iState2).comparingStates = ...
            {relventStates{iState1},relventStates{iState2}};
        [stats.diffBetweenMeasures(iState1,iState2).perSession.p,~,statsSignrank] = signrank(...
            movementPerSessAndState(:,iState1),movementPerSessAndState(:,iState2));
        if isfield(statsSignrank,'zval')
            stats.diffBetweenMeasures(iState1,iState2).perSession.z = statsSignrank.zval;
        end
        stats.diffBetweenMeasures(iState1,iState2).perSession.n = sum(...
            all(~isnan(movementPerSessAndState(:,[iState1,iState2])),2));
        stats.diffBetweenMeasures(iState1,iState2).perSession.test = WSRT_STR;
    end
end

plotData.movementPerSessAndState = movementPerSessAndState;
plotData.statesStr = relventStatesLabels;
plotData.sessions = dlcPerSess.sessions;
plotData.isContextSession = dlcPerSess.isContextSession;
for iSess = length(plotData.sessions):-1:1
    plotData.sessionsStr{iSess} = [plotData.sessions{iSess}.animal ' - ' ...
        num2str(plotData.sessions{iSess}.animalSession)];
end


