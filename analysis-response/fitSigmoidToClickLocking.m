function [clickRateInflection, decayPerLogHz, rms, clickRate25Percent, normalizedResponsePerClickRate] = ...
    fitSigmoidToClickLocking(maxFr, clickRateHz, lockingFrPerClickRate)

lockingFrPerClickRate = makeColumn(lockingFrPerClickRate);
clickRateHz = makeColumn(clickRateHz);
logClickRate = log10(clickRateHz);
normalizedResponsePerClickRate = lockingFrPerClickRate./max([maxFr; lockingFrPerClickRate]);

% k=decayPerLogHz, x0=logClickRateInflection
% % %'1./(1+exp(k(x-x0)))' ~ 1./(1+exp(b1+b2*x))
% k(x-x0) = -kX0 + kX;
% b2 = k;
% b1 = -kX0

decayStart = log10(20);
x0Start = log10(20); %x0 starts at 20 clicks/s
b1Start = -decayStart*x0Start;
b2Start = decayStart;

% X=logClickRate, Y=normalizedResponsePerClickRate
fitobject = fit(logClickRate,normalizedResponsePerClickRate,'1./(1+exp(b1+b2*x))','start',[b1Start b2Start]);
MyCoeffs = coeffvalues(fitobject);
b1 = MyCoeffs(1);
b2 = MyCoeffs(2);

decayPerLogHz = b2;
x0 = b1/-decayPerLogHz;

predictedY = 1./(1+exp(decayPerLogHz.*(logClickRate-x0)));
rms = sqrt(mean((predictedY-normalizedResponsePerClickRate).^2));

clickRateInflection = (10^x0);

% lambda  = 1./(1+exp(decayPerHz.*(logClickRate-x0)))
% lambda* (1+exp(decayPerHz.*(logClickRate-x0)))= 1
% lambda + lambda * exp(decayPerHz.*(logClickRate-x0)) = 1
% exp(decayPerHz.*(logClickRate-x0)) = (1-lambda)/lambda
% decayPerHz.*(logClickRate-x0) = ln((1-lambda)/lambda)
% (logClickRate-x0) = ln((1-lambda)/lambda)/decayPerHz
% logClickRate = x0+ln((1-lambda)/lambda)/(decayPerHz)

lambda = 0.25; %response is down to 25% of max
logClickRateWithLambdaAdaptation = x0+log((1-lambda)/lambda)/(decayPerLogHz);
clickRate25Percent = (10^logClickRateWithLambdaAdaptation);%
  