%% analyzeContextParadigmScript
clear allSessions
allSessions{1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #4'); 
allSessions{2} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #8'); 
allSessions{3} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_06 #3'); 
allSessions{4} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_07 #3'); 
allSessions{5} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_08 #3'); 
allSessions{6} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #4'); 
allSessions{7} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #8');
allSessions{8} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_10 #3');
allSessions{9} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_10 #8');
allSessions{10} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #3');
allSessions{11} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #7');

%%
nBinsForGradualSd = 5;
saveStatePerStimContextParadigm(allSessions)
disp('Finished saveStatePerStimContextParadigm');
saveClicksRastersForSpikesAndLfps(allSessions)
disp('Finished saveClicksRastersForSpikesAndLfps');
calculateAndSaveLatencyFromClicks(allSessions)
disp('Finished calculateAndSaveLatencyFromClicks');
calculateAndSaveClickOrTonesResponsePerStateDLC(allSessions,true)
calculateAndSaveClickOrTonesResponsePerStateFromEpochs(allSessions,true,nBinsForGradualSd)
calculateAndSaveClickResponsePerStateFromEpochs(allSessions)
disp('Finished calculateAndSaveClickResponsePerStateFromEpochs');
calculateAndSaveDrcContextPerState(allSessions)
disp('Finished calculateAndSaveDrcContextPerState');
saveStateOfInterStimulusIntervals(allSessions)
calcAndSaveYokedPostOnsetFromSpontaneousActivity(allSessions)
calculateAndSaveSpikeShape(allSessions)

