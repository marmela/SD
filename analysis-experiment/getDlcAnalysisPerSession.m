function [dlcPerSessionAndState] = getDlcAnalysisPerSession(contextSessions,complexSessions,sessionToExclude)

nContextSessions= length(contextSessions);
isValidSess = true(nContextSessions,1);
for iSess = 1:nContextSessions
    sessionStr = [contextSessions{iSess}.animal  ' - ' num2str(contextSessions{iSess}.animalSession)];
    if any(strcmp(sessionToExclude,sessionStr))
        isValidSess(iSess)=false;
    end
end
contextSessions(~isValidSess) = [];
nContextSessions= length(contextSessions);

nComplexSessions= length(complexSessions);
isValidSess = true(nComplexSessions,1);
for iSess = 1:nComplexSessions
    sessionStr = [complexSessions{iSess}.animal  ' - ' num2str(complexSessions{iSess}.animalSession)];
    if any(strcmp(sessionToExclude,sessionStr))
        isValidSess(iSess)=false;
    end
end
complexSessions(~isValidSess) = [];
nComplexSessions= length(complexSessions);

allSessions = [contextSessions,complexSessions];
isContextSession = [true(1,nContextSessions), false(1,nComplexSessions)];

nSessions = length(allSessions);
for iSess = nSessions:-1:1
    isCurrentSessContext = isContextSession(iSess);
    sessInfo = allSessions{iSess};
    sessionStr = getSessionDirName(sessInfo);
    [clicksFilePath,~,~] = getDlcClickResponsePerStateAnalysisFilePath(sessInfo);
    if ~exist([clicksFilePath '.mat'],'file')
        continue;
    end
    clicks = load(clicksFilePath);
    
    %%
    nStates = length(clicks.baselineAll.dlcAnalysisPerState);
    if ~exist('statesStr','var')
        statesStr = extractfield(clicks.baselineAll.dlcAnalysisPerState, 'trialType');
    else
        assert(all(strcmp(statesStr,extractfield(clicks.baselineAll.dlcAnalysisPerState, 'trialType'))))
    end
    meanValuesPerState = cell2mat(extractfield(clicks.baselineAll.dlcAnalysisPerState, 'mean'));
    movementPerState(iSess,:) = extractfield(meanValuesPerState,'movement');
    segLengthPerState(iSess,:) = extractfield(meanValuesPerState,'segmentLength');
    
    for iState = nStates:-1:1
        locationPerState(iSess,iState,:) = meanValuesPerState(iState).location;
        probFacingForward(iSess,iState) = meanValuesPerState(iState).probForwardFacing;
        probFacingBackward(iSess,iState) = meanValuesPerState(iState).probBackwardFacing;
        probFacingRight(iSess,iState) = meanValuesPerState(iState).probRightFacing;
        probFacingLeft(iSess,iState) = meanValuesPerState(iState).probLeftFacing;
    end
    
end
dlcPerSessionAndState.sessions = allSessions;
dlcPerSessionAndState.isContextSession = isContextSession;
dlcPerSessionAndState.states = statesStr;
dlcPerSessionAndState.movement = movementPerState;
dlcPerSessionAndState.bodySegmentLength = segLengthPerState;
dlcPerSessionAndState.location = locationPerState;
dlcPerSessionAndState.probFacing.forward = probFacingForward;
dlcPerSessionAndState.probFacing.backward = probFacingBackward;
dlcPerSessionAndState.probFacing.right = probFacingRight;
dlcPerSessionAndState.probFacing.left = probFacingLeft;

