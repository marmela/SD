%% analyzeComplexParadigmScript
clear allSessions
allSessions{1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #3');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #7');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_06 #2');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_07 #4');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_08 #4');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #5');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #4');
allSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #8');
nBinsForGradualSd = 5;
%%
calculateAndSaveSpikeShape(allSessions)
saveStateOfInterStimulusIntervals(allSessions)
saveStatePerStimComplexParadigm(allSessions)
disp('Finished saveStatePerStimContextParadigm');
calculateAndSaveFraPerState(allSessions)
disp('Finished calculateAndSaveFraPerState');
saveClicksAndToneStreamRastersForSpikesAndLfps(allSessions,true)
saveClicksAndToneStreamRastersForSpikesAndLfps(allSessions,false)
disp('Finished saveClicksAndToneStreamRastersForSpikesAndLfps');
calculateAndSaveLatencyFromClicks(allSessions)
disp('Finished calculateAndSaveLatencyFromClicks');
calculateAndSaveClickOrTonesResponsePerStateDLC(allSessions,true)
calculateAndSaveClickOrTonesResponsePerStateFromEpochs(allSessions,true)
calculateAndSaveClickOrTonesResponsePerStateFromEpochs(allSessions,false)
calculateAndSaveClickOrTonesResponsePerStateFromEpochs(allSessions,true,nBinsForGradualSd)
calculateAndSaveClickOrTonesResponsePerStateFromEpochs(allSessions,false,nBinsForGradualSd)
disp('Finished calculateAndSaveClickOrTonesResponsePerStateFromEpochs');

