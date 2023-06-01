classdef TdtConsts
   properties (Constant)

        EEG_SR = 1000;
        STIM_SR = 25000;
        MIC_SR = 200000;
      
        ODDBALL_STIM_REFRACTORY_PERIOD_SEC = 0.1;
        BROADBAND_NOISE_REFRACTORY_PERIOD_SEC = 0.4;
        
        RAW_LFP_NAME = 'Raw1';
        AUDITORY_STIM_TTL_NAME = 'RTTL';
        WHEEL1_NAME = 'Whl1';
        WHEEL2_NAME = 'Whl2';
        EEG_NAME = 'EEGx';
        EMG_NAME = 'EMGs';
        PUFF_NAME = 'Puff';
        MIC_NAME = 'Mic_';
        
        N_EEG_CHANNELS = 4;
   end
end