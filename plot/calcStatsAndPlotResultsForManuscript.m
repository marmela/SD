function calcStatsAndPlotResultsForManuscript(contextSessions, complexSessions, minUnitsPerAnimal, minUnitsPerSess)

%% Define State Info
stateInfoQw.str = 'QWake';
stateInfoQw.state = State.QW;
stateInfoQw.color = [0,114,178]./255;

stateInfoNrem.str = 'NREM';
stateInfoNrem.state = State.NREM;
stateInfoNrem.color = [0,0,0]; 

stateInfoRem.str = 'REM';
stateInfoRem.state = State.REM;
stateInfoRem.color = [204,121,167]./255;

stateInfoSD1.str = 'Vigilant';
stateInfoSD1.state = State.SD1;
stateInfoSD1.color = [0,154, 255]./255;

stateInfoSD3.str = 'Tired';
stateInfoSD3.state = State.SD3;
stateInfoSD3.color =  [0,101,168]./255;

%% Obtain Vigilant (SD1) and Tired (SD3) results for DeepLabCut control analysis
sessionToExclude = {'AM_A1_05 - 8', 'AM_A1_09 - 8', 'AM_A1_10 - 3'}; %session with horrible sync/lostframes in video decided on "testManuallyGetTimesPerVideo.m"
[dlcPerSess] = getDlcAnalysisPerSession(contextSessions,complexSessions,sessionToExclude);
[dlcUnitDataSD1,dlcSssDataSD1, dlcChDataSD1] = getContextAndComplexResultsForStateDLC(contextSessions,complexSessions,State.SD1);
[dlcUnitDataSD3,dlcSessDataSD3, dlcChDataSD3] = getContextAndComplexResultsForStateDLC(contextSessions,complexSessions,State.SD3);

dlcStateDataSD1.unitData = dlcUnitDataSD1;
dlcStateDataSD1.sessData = dlcSssDataSD1;
dlcStateDataSD1.chData = dlcChDataSD1;
dlcStateDataSD1.info = stateInfoSD1;
dlcStateDataSD3.unitData = dlcUnitDataSD3;
dlcStateDataSD3.sessData = dlcSessDataSD3;
dlcStateDataSD3.chData = dlcChDataSD3;
dlcStateDataSD3.info = stateInfoSD3;

%% Get gradual SD 1h bin results instead of just Vigilant and Tired
N_SD_BINS = 5;
for iSdBin = N_SD_BINS:-1:1
    [unitDataGradSd{iSdBin},~, ~] = getContextAndComplexResultsForGradualSd(...
        contextSessions,complexSessions,iSdBin,N_SD_BINS);
end

%% Get all states data Vigilant (SD1), Tired (SD3), QWake recovery sleep, REM, NREM
[unitDataQw,sessDataQw, chDataQw] = getContextAndComplexResultsForState(contextSessions,complexSessions,State.QW);
[unitDataNrem,sessDataNrem, chDataNrem] = getContextAndComplexResultsForState(contextSessions,complexSessions,State.NREM);
[unitDataRem,sessDataRem, chDataRem] = getContextAndComplexResultsForState(contextSessions,complexSessions,State.REM);
[unitDataSD1,sessDataSD1, chDataSD1] = getContextAndComplexResultsForState(contextSessions,complexSessions,State.SD1);
[unitDataSD3,sessDataSD3, chDataSD3] = getContextAndComplexResultsForState(contextSessions,complexSessions,State.SD3);

stateDataQw.unitData = unitDataQw;
stateDataQw.sessData = sessDataQw;
stateDataQw.chData = chDataQw;
stateDataQw.info = stateInfoQw;

stateDataNrem.unitData = unitDataNrem;
stateDataNrem.sessData = sessDataNrem;
stateDataNrem.chData = chDataNrem;
stateDataNrem.info = stateInfoNrem ;

stateDataRem.unitData = unitDataRem;
stateDataRem.sessData = sessDataRem;
stateDataRem.chData = chDataRem;
stateDataRem.info = stateInfoRem;

stateDataSD1.unitData = unitDataSD1;
stateDataSD1.sessData = sessDataSD1;
stateDataSD1.chData = chDataSD1;
stateDataSD1.info = stateInfoSD1;

stateDataSD3.unitData = unitDataSD3;
stateDataSD3.sessData = sessDataSD3;
stateDataSD3.chData = chDataSD3;
stateDataSD3.info = stateInfoSD3;

%% Select Units with statistically significant responses and minimal firing rate
ALPHA_STAT = 0.001;
nUnits = length(stateDataNrem.unitData);
isSigClicksUnit = false(nUnits,1);
minBaseFrPerUnit = nan(nUnits,1);
isContextUnit = cell2mat(extractfield(unitDataNrem,'isContext')');
isSigTuningUnit = false(nUnits,1);
isSigTuningRemUnit = false(nUnits,1);

for iUnit = 1:nUnits
    isSigClicksUnit(iUnit) = stateDataNrem.unitData(iUnit).clicks40Hz.clicksLockedP<ALPHA_STAT || ...
        stateDataSD1.unitData(iUnit).clicks40Hz.clicksLockedP<ALPHA_STAT || ...
        stateDataSD3.unitData(iUnit).clicks40Hz.clicksLockedP<ALPHA_STAT;
    minBaseFrPerUnit(iUnit) = min([stateDataNrem.unitData(iUnit).baseFr, stateDataRem.unitData(iUnit).baseFr...
        stateDataSD1.unitData(iUnit).baseFr, stateDataSD3.unitData(iUnit).baseFr]);
    if isContextUnit(iUnit)
        isSigTuningUnit(iUnit) = stateDataNrem.unitData(iUnit).drc.stats.significantBonferroni && ...
            stateDataSD1.unitData(iUnit).drc.stats.significantBonferroni && ...
            stateDataSD3.unitData(iUnit).drc.stats.significantBonferroni;
        isSigTuningRemUnit(iUnit) = stateDataRem.unitData(iUnit).drc.stats.significantBonferroni && ...
            stateDataSD1.unitData(iUnit).drc.stats.significantBonferroni;
    else
        isSigTuningUnit(iUnit) = stateDataNrem.unitData(iUnit).drc.stats.p<ALPHA_STAT && ...
            stateDataSD1.unitData(iUnit).drc.stats.p<ALPHA_STAT && ...
            stateDataSD3.unitData(iUnit).drc.stats.p<ALPHA_STAT;
        isSigTuningRemUnit(iUnit) = stateDataRem.unitData(iUnit).drc.stats.p<ALPHA_STAT && ...
            stateDataSD1.unitData(iUnit).drc.stats.p<ALPHA_STAT;
    end
end

isMinFrLargeEnough = minBaseFrPerUnit>0.5;
isSigClicksAndMinFrUnit = isSigClicksUnit & isMinFrLargeEnough;
isSigTuningAndMinFrUnit = isSigTuningUnit & isMinFrLargeEnough;
isSigTuningRemAndMinFrUnit = isSigTuningRemUnit & isMinFrLargeEnough;

%% Neuronal Stability Figures (Figure S4)
stabilityDir = [SdLocalPcDef.ANALYSIS_DIR filesep 'Spikes' filesep 'Stability' filesep 'Barak'];
stableUnitsFilePath = [stabilityDir filesep 'filtered_units_logical.mat'];
stableUnits = load(stableUnitsFilePath);
isSigTuningMinFrAndStableUnit = isSigClicksAndMinFrUnit & stableUnits.units_true_th;
isSigTuningMinFrAnd99StableUnit = isSigClicksAndMinFrUnit & stableUnits.units_true_099;

figDir = 'StabilityFig';

exampleUnitClicksREM.session = 'AM_A1_11 - 3';
exampleUnitClicksREM.ch = 12;
exampleUnitClicksREM.clus = 1;
exampleUnitClicksREM.color = [1,0,0];

exampleUnitTuningREM.session = 'AM_A1_09 - 4';
exampleUnitTuningREM.ch = 7;
exampleUnitTuningREM.clus = 1;
exampleUnitTuningREM.color = [1,0,0];

% A conservative threshold for which the false-positive rate of declaring units from the
% surrogate distribution as stable is 1%
plotTuningAndClickTrainFigForManuscript(stateDataNrem,stateDataSD1, isSigTuningAndMinFrUnit, ...
    isSigTuningMinFrAnd99StableUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuningREM, ...
    exampleUnitClicksREM, [stateInfoSD1,stateInfoNrem],figDir,'Stability99')
plotTuningAndClickTrainFigForManuscript(stateDataSD3,stateDataSD1, isSigTuningAndMinFrUnit, ...
    isSigTuningMinFrAnd99StableUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuningREM, ...
    exampleUnitClicksREM, [stateInfoSD1,stateInfoSD3],figDir,'Stability99')

% 'Optimal' threshold with maximal separation between the surrogate and real waveform
% stability distributions
plotTuningAndClickTrainFigForManuscript(stateDataNrem,stateDataSD1, isSigTuningAndMinFrUnit, ...
    isSigTuningMinFrAndStableUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuningREM, ...
    exampleUnitClicksREM, [stateInfoSD1,stateInfoNrem],figDir,'StabilityOptimal')
plotTuningAndClickTrainFigForManuscript(stateDataSD3,stateDataSD1, isSigTuningAndMinFrUnit, ...
    isSigTuningMinFrAndStableUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuningREM, ...
    exampleUnitClicksREM, [stateInfoSD1,stateInfoSD3],figDir,'StabilityOptimal')

%% Select units for DeepLabCut analysis with signifcant responses, min FR and enought trials. 
allUnitsSessions = extractfield(stateDataNrem.unitData,'session');
allUnitsChannels = extractfield(stateDataNrem.unitData,'ch');
allUnitsClus = extractfield(stateDataNrem.unitData,'clus');
nDlcUnits = length(dlcStateDataSD1.unitData);
isDlcUnitValid = false(nDlcUnits,1);

MIN_N_TRIALS = 20;
for iDlcUnit = 1:nDlcUnits
    indexInAllUnits = find(strcmp(allUnitsSessions, dlcStateDataSD1.unitData(iDlcUnit).session) & ...
        dlcStateDataSD1.unitData(iDlcUnit).ch == allUnitsChannels & ...
        dlcStateDataSD1.unitData(iDlcUnit).clus == allUnitsClus);
    nTrialsSd1 = dlcStateDataSD1.unitData(iDlcUnit).clicks40Hz.nTrials;
    nTrialsSd3 = dlcStateDataSD3.unitData(iDlcUnit).clicks40Hz.nTrials;
    assert(length(indexInAllUnits)==1);
    isCurrentUnitSigAndMinFr = isSigClicksAndMinFrUnit(indexInAllUnits);
    isCurrentUnitSufficientTrials = min(nTrialsSd1,nTrialsSd3)>=MIN_N_TRIALS;
    isValidSession = ~any(strcmp(sessionToExclude,dlcStateDataSD1.unitData(iDlcUnit).session));
    isDlcUnitValid(iDlcUnit) = isCurrentUnitSigAndMinFr & isCurrentUnitSufficientTrials & isValidSession;
end

1;

%% Plot DeepLabCut movement control figures (Figure S2)
exampleUnitClicksSD.session = 'AM_A1_11 - 3';
exampleUnitClicksSD.ch = 12;
exampleUnitClicksSD.clus = 1;
exampleUnitClicksSD.color = [1,0,0];

plotTuningAndClickTrainFigForManuscriptDLC(dlcPerSess,dlcStateDataSD3,dlcStateDataSD1, ...
    isDlcUnitValid, minUnitsPerAnimal, minUnitsPerSess, exampleUnitClicksSD, ...
    [stateInfoSD1,stateInfoSD3])

%% Example Unit for tuning figures
exampleUnitTuning.session = 'AM_A1_09 - 4';
exampleUnitTuning.ch = 7;
exampleUnitTuning.clus = 1;
exampleUnitTuning.color = [1,0,0];

%% NREM-QW in recovery sleep Figure S5 (like Main Fig but for control - showing the spike stability isn't an issue)

exampleUnitClicksSleep.session = 'AM_A1_11 - 3';
exampleUnitClicksSleep.ch = 16;
exampleUnitClicksSleep.clus = 2;
exampleUnitClicksSleep.color = [1,0,0];

plotTuningAndClickTrainFigForManuscript(stateDataNrem,stateDataQw, isSigTuningAndMinFrUnit, ...
    isSigClicksAndMinFrUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning, ...
    exampleUnitClicksSleep, [stateInfoQw,stateInfoNrem])

%% Plot Gradual SD figure (Figure S1) 
exampleUnitClicksSD.session = 'AM_A1_11 - 3';
exampleUnitClicksSD.ch = 12;
exampleUnitClicksSD.clus = 1;
exampleUnitClicksSD.color = [1,0,0];
[statsGradualSd,plotData] = calcClickResponsesAndStatsForGradualSd(unitDataGradSd, isSigClicksAndMinFrUnit, ...
    minUnitsPerAnimal, minUnitsPerSess, exampleUnitClicksSD)


%% Plot Post-onset FR reduction doesn’t explain reduced locking figure (S6)
exampleUnitAdaptationClicks.session = 'AM_A1_11 - 3';
exampleUnitAdaptationClicks.ch = 3; %14;
exampleUnitAdaptationClicks.clus = 1;
exampleUnitAdaptationClicks.color = [1,0,0];
plotClicksSimVsRealSuppFig({stateDataSD1,stateDataSD3,stateDataNrem,stateDataRem},...
    isSigClicksAndMinFrUnit,exampleUnitAdaptationClicks)

%% Plot click latency (Fig 1C)
calculateAndSaveLatencyFromClicks([contextSessions, complexSessions])

%% Plot REM figure (Fig. 6)
close all
exampleUnitClicksREM.session = 'AM_A1_11 - 3';
exampleUnitClicksREM.ch = 12;
exampleUnitClicksREM.clus = 1;
exampleUnitClicksREM.color = [1,0,0];

exampleUnitTuningREM.session = 'AM_A1_09 - 4';
exampleUnitTuningREM.ch = 7;
exampleUnitTuningREM.clus = 1;
exampleUnitTuningREM.color = [1,0,0];

plotRemFigForManuscript({stateDataSD1,stateDataNrem,stateDataRem},...
    isSigTuningRemAndMinFrUnit,isSigClicksAndMinFrUnit, minUnitsPerAnimal, minUnitsPerSess, ...
    exampleUnitTuningREM,exampleUnitClicksREM)

%% Tired-Vigilant Fig. 2
exampleUnitClicksSD.session = 'AM_A1_11 - 3';
exampleUnitClicksSD.ch = 12;
exampleUnitClicksSD.clus = 1;
exampleUnitClicksSD.color = [1,0,0];

plotTuningAndClickTrainFigForManuscript(stateDataSD3,stateDataSD1, isSigTuningAndMinFrUnit, ...
    isSigClicksAndMinFrUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning, ...
    exampleUnitClicksSD, [stateInfoSD1,stateInfoSD3])

%% NREM-Vigilant (Fig. 3)
exampleUnitClicksSleep.session = 'AM_A1_11 - 3';
exampleUnitClicksSleep.ch = 16;
exampleUnitClicksSleep.clus = 2;
exampleUnitClicksSleep.color = [1,0,0];

plotTuningAndClickTrainFigForManuscript(stateDataNrem,stateDataSD1, isSigTuningAndMinFrUnit, ...
    isSigClicksAndMinFrUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitTuning, ...
    exampleUnitClicksSleep, [stateInfoSD1,stateInfoNrem])

%% Click Rates Adaptation (Fig. 4)
exampleUnitAdaptationClicks.session = 'AM_A1_11 - 3';
exampleUnitAdaptationClicks.ch = 3; %14;
exampleUnitAdaptationClicks.clus = 1;
exampleUnitAdaptationClicks.color = [1,0,0];

plotAdaptationOfClicksFigForManuscriptNoPanelF({stateDataSD1,stateDataSD3,stateDataNrem},...
    isSigClicksAndMinFrUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitAdaptationClicks)
%% Post-Onset (Fig. 5)
exampleUnitOffState.session = 'AM_A1_11 - 3';
exampleUnitOffState.ch = 3; %14;
exampleUnitOffState.clus = 1;
exampleUnitOffState.color = [1,0,0];

plotPostOnsetFigForManuscript({stateDataSD1,stateDataSD3,stateDataNrem},...
    isSigClicksAndMinFrUnit, minUnitsPerAnimal, minUnitsPerSess, exampleUnitOffState)


%% Slow-Wave Activity + Hypnogram (Fig. 1D)
calcAndPlotSwaAndHypnogramAnalysis([contextSessions, complexSessions], stateInfoSD1, ...
    stateInfoNrem, stateInfoRem)
