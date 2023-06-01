classdef TtlStampConsts
   properties (Constant)
       N_BITS = 14;
       ZERO_TIME_MS = 1;
       BIT_SIZE_MS = 5;
       ONSET_TTL_LENGTH_MS = 10;
       TTL_STAMP_LENGTH_MS = TtlStampConsts.ONSET_TTL_LENGTH_MS+TtlStampConsts.BIT_SIZE_MS*TtlStampConsts.N_BITS;
   end
end