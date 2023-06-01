function fileName = getEpochsFileName(sessionInfo,channel)
if exist('channel','var')
    fileName = sprintf('%s-%d_ch%d',sessionInfo.animal,sessionInfo.animalSession,channel);
else
    fileName = sprintf('%s-%d_StatePerEpoch',sessionInfo.animal,sessionInfo.animalSession);
end


