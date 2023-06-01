# SD

analysis pipeline in the paper went as follows:

Step 1: preprocessing the data for each individual/multiple session(s) using "preprocessingSessionsScript_step1.m"
This step includes extracting all the data, preprocessing, spikesorting, basic initial analyses

step 2: Analyze the two different auditory paradigms using "analyzeAuditoryParadigmAScript_step2a.m" and "analyzeAuditoryParadigmBScript_step2b.m"
These scripts analyze all the auditory response features across all arousal states for all units/channels/sessions.

step 3: plot figures and calculate stats for manuscript using "plotFiguresAndStats_step3.m"
obtains the responses in step 2, compares them between states, plot the figures of the paper and calculates statistics.



