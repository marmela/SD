function response = getContinuousDataClickResponse(lfpPerTrial,timesMs,clickRateHz,params)

MS_IN_SEC = 1000;

sampleSizeMs = timesMs(2)-timesMs(1);
nMedianAbsDevOfNoise = params.noise.nMedianAbsDevToExcludeTrials;
stdPerTrial = std(lfpPerTrial,[],2);
medianStd = median(stdPerTrial);
madStd = mad(stdPerTrial,1);
isNoise = stdPerTrial>medianStd+madStd*nMedianAbsDevOfNoise | ...
    stdPerTrial<medianStd-madStd*nMedianAbsDevOfNoise;
lfpPerTrial(isNoise,:) = [];
interClickIntervalMs = 1./clickRateHz*MS_IN_SEC;
EPSILON = 10^-6;
isBaselineTime = timesMs>=params.baselineTimeMs(1)-EPSILON & timesMs<params.baselineTimeMs(2)-EPSILON;
isPostOnsetTime = timesMs>=params.postOnsetTimeMs(1)-EPSILON & timesMs<params.postOnsetTimeMs(2)-EPSILON;
isOnsetTime = timesMs>=params.onsetTimeMs(1)-EPSILON & timesMs<params.onsetTimeMs(2)-EPSILON;
isSustainedTime = timesMs>=params.sustainedTimeMs(1)-EPSILON & timesMs<params.sustainedTimeMs(2)-EPSILON;
isOffsetTime = timesMs>=params.offsetTimeMs(1)-EPSILON & timesMs<params.offsetTimeMs(2)-EPSILON;
erp = mean(lfpPerTrial,1);
response.erp = erp;
response.erpTimesMs = timesMs;
response.baseline.magnitude =  mean(erp(isBaselineTime));
response.postOnset.magnitude =  mean(erp(isPostOnsetTime));
response.postOnset.magnitudeNormalized = response.postOnset.magnitude - response.baseline.magnitude;
response.sustained.magnitude = mean(erp(isSustainedTime));
response.sustained.magnitudeNormalized = response.sustained.magnitude - response.baseline.magnitude;
response.offset.magnitude = mean(erp(isOffsetTime));
response.offset.magnitudeNormalized = response.offset.magnitude - response.baseline.magnitude;
sigmaMs = params.smooth.sigmaMs;
sigmaSamples = sigmaMs./sampleSizeMs;
N_SD_TO_INCLUDE_IN_WIN = 6;
nPointsWin = round(sigmaSamples*N_SD_TO_INCLUDE_IN_WIN);
smoothWin = getGaussWin(sigmaMs,nPointsWin);
erpSmoothed = conv(erp,smoothWin,'same');
onsetErp = erpSmoothed(isOnsetTime);
onsetErpTimesMs = timesMs(isOnsetTime);
[~,onsetResponseIndex] = max(abs(onsetErp));
response.onset.magnitude = onsetErp(onsetResponseIndex);
response.onset.magnitudeNormalized = response.onset.magnitude - response.baseline.magnitude;
response.onset.timeMs = onsetErpTimesMs(onsetResponseIndex);
sustainedErp = erpSmoothed(isSustainedTime);
sustainedTimeMs = timesMs(isSustainedTime);
timeRelativeToClickBinMs = floor(mod(sustainedTimeMs,interClickIntervalMs)+1);
maxTimeBins = max(timeRelativeToClickBinMs);
for iBin=1:maxTimeBins
    meanPerBin(iBin) = mean(sustainedErp(iBin==timeRelativeToClickBinMs));
end
response.sustainedLocked.magnitude = max(meanPerBin)-min(meanPerBin);

if ~isfield(params,'stats') || ~isfield(params.stats,'on') || ~params.stats.on
    return
end

%% Stats
nTrials = size(lfpPerTrial,1);
nTimePointsSustained = sum(isSustainedTime);
nReps = params.stats.nReps;
lfpPerTrialSmoothed = conv2(lfpPerTrial,smoothWin','same');

%% Offset Stats
nOffsetSamples = sum(isOffsetTime);
iBaseline = find(timesMs<0,nOffsetSamples,'last');
baselinePerTrial = mean(lfpPerTrialSmoothed(:,iBaseline),2);
offsetPerTrial = mean(lfpPerTrialSmoothed(:,isOffsetTime),2);
[p,~,stats] = signrank(baselinePerTrial,offsetPerTrial);
response.offset.stats.p = p;
if isfield(stats,'zval')
    response.offset.stats.z = stats.zval;
else
    response.offset.stats.z = nan;
end
response.offset.stats.n = nTrials;
response.offset.stats.test = 'signrank';

%% Onset Stats
nOnsetSamples = sum(isOnsetTime);
iBaseline = find(timesMs<0,nOnsetSamples,'last');

baselinePerTrial = lfpPerTrialSmoothed(:,iBaseline);
onsetPerTrial = lfpPerTrialSmoothed(:,isOnsetTime);
realPeakDiff = max(abs(mean(onsetPerTrial)))-max(abs(mean(baselinePerTrial)));

for iRep = nReps:-1:1
    isFlipLabel = rand(nTrials,1)<0.5;
    surrogateOnsetTrials = [onsetPerTrial(~isFlipLabel,:); baselinePerTrial(isFlipLabel,:)];
    surrogateBaselineTrials = [onsetPerTrial(isFlipLabel,:); baselinePerTrial(~isFlipLabel,:)];
    surrogatePeakDiff(iRep) = max(abs(mean(surrogateOnsetTrials)))-max(abs(mean(surrogateBaselineTrials)));
end
response.onset.stats.p = mean(realPeakDiff<surrogatePeakDiff);
response.onset.stats.t = (realPeakDiff-...
    mean(surrogatePeakDiff))./std(surrogatePeakDiff);
response.onset.stats.n = nTrials;
response.onset.stats.nReps = nReps;
response.onset.stats.test = 'Monte Carlo Permutation Test - randomly flipped tags between baseline and onset periods of equal lengths and compared their peak diff';

%% Post-Onset stats
nPostOnsetSamples = sum(isPostOnsetTime);
iBaseline = find(timesMs<0,nPostOnsetSamples,'last');
baselinePerTrial = mean(lfpPerTrialSmoothed(:,iBaseline),2);
postOnsetPerTrial = mean(lfpPerTrialSmoothed(:,isPostOnsetTime),2);
[p,~,stats] = signrank(baselinePerTrial,postOnsetPerTrial);
response.postOnset.stats.p = p;
if isfield(stats,'zval')
    response.postOnset.stats.z = stats.zval;
else
    response.postOnset.stats.z = nan;
end
response.postOnset.stats.n = nTrials;
response.postOnset.stats.test = 'signrank';

%% Sustained stats - Induced Response
nSustainedSamples = sum(isSustainedTime);
iBaseline = find(timesMs<0,nSustainedSamples,'last');
baselinePerTrial = mean(lfpPerTrialSmoothed(:,iBaseline),2);
sustainedPerTrial = mean(lfpPerTrialSmoothed(:,isSustainedTime),2);
[p,~,stats] = signrank(baselinePerTrial,sustainedPerTrial);
response.sustained.stats.p = p;
if isfield(stats,'zval')
    response.sustained.stats.z = stats.zval;
else
    response.sustained.stats.z = nan;
end
response.sustained.stats.n = nTrials;
response.sustained.stats.test = 'signrank';

%% Sustained Stats - Locked Response
iSustainedStart = find(timesMs>params.sustainedTimeMs(1)-EPSILON,1,'first');
iSustainedEnd = find(timesMs<params.sustainedTimeMs(2)-EPSILON,1,'last');
for iRep = nReps:-1:1
    shiftPerTrial = floor(rand(nTrials,1)*interClickIntervalMs)-round(interClickIntervalMs/2);
    erpSum = zeros(1,nTimePointsSustained);
    for iTrial = 1:nTrials
        currentTrialShift = shiftPerTrial(iTrial);
        erpSum = erpSum + lfpPerTrialSmoothed(iTrial,iSustainedStart+currentTrialShift:...
            iSustainedEnd+currentTrialShift);
    end
    erpSurrogate = erpSum./nTrials;
    
    meanPerBin = nan(maxTimeBins,1);
    for iBin=1:maxTimeBins
        meanPerBin(iBin) = mean(erpSurrogate(iBin==timeRelativeToClickBinMs));
    end
    surrogateSustainedResponse(iRep) = max(meanPerBin)-min(meanPerBin);
end
response.sustainedLocked.stats.p = mean(response.sustainedLocked.magnitude<surrogateSustainedResponse);
response.sustainedLocked.stats.t = (response.sustainedLocked.magnitude-...
    mean(surrogateSustainedResponse))./std(surrogateSustainedResponse);
response.sustainedLocked.stats.n = nTrials;
response.sustainedLocked.stats.nReps = nReps;
response.sustainedLocked.stats.test = 'Monte Carlo Permutation Test - randomly shifted trials by up to inter click interval';

%% PLOT DEBUG
DEBUG_MODE = false;
if DEBUG_MODE
    ONSET_COLOR = 'k';
    SUSTAINED_COLOR = 'g';
    SUSTAINED_LOCKED_COLOR = 'm';
    OFFSET_COLOR = 'b';
    FONT_SIZE = 16;
    MARKER_SIZE = 16;
    LINE_WIDTH = 2;
    maxPVal = 0.001;
    figure('Position',[10,50,1900,950]);
    hold on;
    plot(timesMs,erpSmoothed,'LineWidth',LINE_WIDTH);
    currYlim = ylim();
    diffYlim = diff(currYlim);
    if response.onset.stats.p<maxPVal
        plotBackground(params.onsetTimeMs,[currYlim(1),currYlim(1)],[0,0],[diffYlim,diffYlim],ONSET_COLOR,0.2);
        plot(response.onset.timeMs,response.onset.magnitude,'o','MarkerEdgeColor',ONSET_COLOR,...
            'MarkerSize',MARKER_SIZE,'LineWidth',LINE_WIDTH);
    end
    if response.sustained.stats.p<maxPVal
        plotBackground(params.sustainedTimeMs,[currYlim(1),currYlim(1)],[0,0],[diffYlim,diffYlim],...
            SUSTAINED_COLOR,0.2);
    end
    if response.sustainedLocked.stats.p<maxPVal
        plot(timesMs(isSustainedTime),erpSmoothed(isSustainedTime),SUSTAINED_LOCKED_COLOR,...
            'LineWidth',LINE_WIDTH*1.5)
    end
    if response.offset.stats.p<maxPVal
        plotBackground(params.offsetTimeMs,[currYlim(1),currYlim(1)],[0,0],[diffYlim,diffYlim],...
            OFFSET_COLOR,0.2);
    end
    titleStr  = sprintf('Onset p=%.03f     Sustained p=%.03f     Sustained Locked p=%.03f     Offset p=%.03f\n',...
        response.onset.stats.p, response.sustained.stats.p, response.sustainedLocked.stats.p, ...
        response.offset.stats.p);
    titleStr2 = sprintf('%.03f                          %.03f                             %.03f                          %.03f',...
        response.onset.magnitude, response.sustained.magnitude,...
        response.sustainedLocked.magnitude,response.offset.magnitude);
    title([titleStr,titleStr2])
    set(gca,'FontSize',16)
end

