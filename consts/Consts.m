classdef Consts
    properties (Constant)
        
        LINE_FREQUENCY = 50;  %50Hz
        FILTER_WINDOW_WIDTH = 1; %1 sec - for line noise filtering
        
        MUA_LOW_CUT_HZ = 300;
        MUA_HIGH_CUT_HZ = 3000;
        MUA_FILTER_ORDER = 4;
        MUA_ENVELOPE_LOWPASS_FILTER_CUTOFF = 400;
        MUA_ENVELOPE_FILTER_ORDER = 6;
        MUA_ENVELOPE_SR = 1000;
        
        LFP_LOW_CUT_HZ = 0.3;
        LFP_HIGH_CUT_HZ = 300;
        LFP_FILTER_ORDER = 2;
        LFP_SR = 1000;
        
        WHEEL_SR = 100;
        
        
        ANIMAL_COLORS = {[35	70	90]/95,... sky-blue
            [80	60	70]*1.1/95,... reddish purple
            [0	45	70]/95,... blue
            [0	60	50]*0.85/95,... bluish green
            [95	90	25]/95,... yellow
            [80	40	0]*0.8/95,... vermillion
            [90	60	0]/95,... orange
            };
        
        MARKER_ANIMAL_MAP = containers.Map(...
            {'AM_A1_05', 'AM_A1_06', 'AM_A1_07', 'AM_A1_08', 'AM_A1_09', 'AM_A1_10', 'AM_A1_11',}, ...
            {'o','^','<','h','d','v','s'});
        
    end
end