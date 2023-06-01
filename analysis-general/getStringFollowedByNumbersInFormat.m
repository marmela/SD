function [str,nums] = getStringFollowedByNumbersInFormat(strExpression)
    strs = strtrim(strsplit(strExpression,'#')); 
    str = strs{1};
    nums = [];
    for strInd = 2:length(strs)
        numSubstrings = strsplit(strs{strInd},'-');
        if (length(numSubstrings)==1)
            nums = [nums, str2num(numSubstrings{1})];
        elseif (length(numSubstrings)==2)
            nums = [nums, str2num(numSubstrings{1}):str2num(numSubstrings{2})];
        else
            error('invalid syntax');
        end
    end
%     nums = cellfun(@str2num,strs(2:end));

end