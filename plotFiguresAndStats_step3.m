%% manuscriptScript
clear contextSessions
contextSessions{1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #4');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #8');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_06 #3');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_07 #3');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_08 #3');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #4');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #8');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_10 #3');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_10 #8');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #3');
contextSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #7');

clear complexSessions
complexSessions{1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #3');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_05 #7');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_06 #2');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_07 #4');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_08 #4');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_09 #5');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #4');
complexSessions{end+1} = getSessionInfo(ExpInfo.ANIMAL_AND_SESSION, 'AM_A1_11 #8');

%%
minUnitsPerSess = 5;
minUnitsPerAnimal = 5;

calcStatsAndPlotResultsForManuscript(contextSessions, complexSessions, minUnitsPerAnimal, minUnitsPerSess)

