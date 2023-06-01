function win = getGaussWin(sigma,nPoints)

if(~exist('nPoints','var'))
    nPoints = round(sigma*6);
end
assert(nPoints==round(nPoints));
alpha = (nPoints-1)./(2*sigma);
win = gausswin(nPoints,alpha);
win = win./sum(win);