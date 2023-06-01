function result = analyzeBaselineSpikesCvFano(raster)
MS_IN_1SEC = 1000;
MIN_ISIS_TO_CALC_CV = 5;
nTrials = size(raster,1);
nTimepoints = size(raster,2);

isiCvPerTrial = nan(nTrials,1);
for iTrial = nTrials:-1:1
    currentTrialIsis = diff(find(raster(iTrial,:)));
    isisPerTrial{iTrial} = currentTrialIsis;
    if length(currentTrialIsis)>MIN_ISIS_TO_CALC_CV
        isiCvPerTrial(iTrial) = std(currentTrialIsis)./mean(currentTrialIsis);
    end
end

samplesInBin =50;
raster50SamplesBins = reshape(raster,[size(raster,1),samplesInBin,size(raster,2)./samplesInBin]);
sumSpikesPerBin = squeeze(sum(raster50SamplesBins,2));
fanoFactorPerTrial = var(sumSpikesPerBin,[],2)./mean(sumSpikesPerBin,2);
result.fanoFactor.perTrial50MsBin = nanmean(fanoFactorPerTrial);

samplesInBin =25;
raster50SamplesBins = reshape(raster,[size(raster,1),samplesInBin,size(raster,2)./samplesInBin]);
sumSpikesPerBin = squeeze(sum(raster50SamplesBins,2));
fanoFactorPerTrial = var(sumSpikesPerBin,[],2)./mean(sumSpikesPerBin,2);
result.fanoFactor.perTrial25MsBin = nanmean(fanoFactorPerTrial);


spikesPerTrial = sum(raster,2);
result.magnitudeHz = mean(raster(:))*MS_IN_1SEC;

result.fanoFactor.entireBaseline = var(spikesPerTrial)./mean(spikesPerTrial);

result.isiCv = nanmean(isiCvPerTrial);


1;