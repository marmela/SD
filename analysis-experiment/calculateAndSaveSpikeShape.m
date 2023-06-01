function calculateAndSaveSpikeShape(allSessions)

spikePeakIndex = 16; 
sr = 2.44140625e+04;

paradigmName = allSessions{1}.paradigmDir;
drcDir = [SdLocalPcDef.AUDITORY_PARADIGMS_DIR filesep ...
    paradigmName  filesep ParadigmConsts.DRC_TUNING_DIR];
spikesFileNameFormat = 'times_Raw_%03g.mat';

%%
listing = dir(drcDir);
lastDrcFileName = listing(end).name;
assert(strcmp(lastDrcFileName(1:4),'DRC_') && strcmp(lastDrcFileName(8:end),'.mat'));
maxDrcNum = str2num(lastDrcFileName(5:7));
assert(~exist([drcDir filesep sprintf('DRC_%03g.mat',maxDrcNum+1)],'file'))
%%
nSessions = length(allSessions);
for iSess = 1:nSessions
    clear spk
    sessInfo = allSessions{iSess};
    nLocs = length(sessInfo.electrodes.locations);
    channels = [];
    for iLoc =1:nLocs
        channels = [channels,sessInfo.electrodes.channelsPerLocation{iLoc}];
    end
    spikesDir =  getSpikesSortingDirPath(sessInfo.animal,sessInfo.animalSession);

    %%
    unitCount = 0;
    for ch = channels
        tic;
        spikePath = [spikesDir filesep sprintf(spikesFileNameFormat,ch)];
        if ~exist(spikePath,'file')
            continue;
        end
        spikeTimesData = load(spikePath);
        nClus = max(spikeTimesData.cluster_class(:,1));
        for iClus = 1:nClus
            
            isCurrentClus = spikeTimesData.cluster_class(:,1)==iClus;
            currentClusSpikesShape = spikeTimesData.spikes(isCurrentClus,:);
            meanSpikeShape = mean(currentClusSpikesShape);
            
            [~,peakAmpIndex] = max(abs(meanSpikeShape));
            if peakAmpIndex~=spikePeakIndex
                warning('%s-%d Ch%d Cl%d peak does not match default\n', ...
                    sessInfo.animal,sessInfo.animalSession,ch,iClus);
            end
            
            spk(ch,iClus).shape = meanSpikeShape;
            spk(ch,iClus).peakVolt = meanSpikeShape(spikePeakIndex);
            spk(ch,iClus).postPeakTroughVolt = sign(spk(ch,iClus).peakVolt)*min(meanSpikeShape(spikePeakIndex+1:end)*sign(spk(ch,iClus).peakVolt));
            spk(ch,iClus).peakToTroughAmp = abs(spk(ch,iClus).peakVolt-spk(ch,iClus).postPeakTroughVolt);
            spk(ch,iClus).peakToTotalAmpRatio = abs(spk(ch,iClus).peakVolt)./spk(ch,iClus).peakToTroughAmp;
            spk(ch,iClus).peakToTroughSpikeWidthMs = getPeakToTroughSpikeWidth(meanSpikeShape,spikePeakIndex,sr);
            spk(ch,iClus).halfHeightSpikeWidthMs = getHalfHeightSpikeWidth(meanSpikeShape,sr);
        end
        fprintf('%s-%d Channel %d     %3gs\n',sessInfo.animal,sessInfo.animalSession,ch,toc);
    end
    [sessFilePath,~,~] = getSpikeShapeFilePath(sessInfo);
    save(sessFilePath,'spk');
end