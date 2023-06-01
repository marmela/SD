function makeDirIfNeeded (dirPath)
if (~exist(dirPath,'dir'))
    mkdir(dirPath);
end