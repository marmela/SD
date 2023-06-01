function isStringComboInCellArr = isStringsCombinationInCellArray(cellArray,stringCombo)
    isStringComboInCellArr = true;
    if (iscell(stringCombo))
        nArgsInStringCombo = length(stringCombo);
    else
        nArgsInStringCombo = 1;
        strs = getAllStrsFromArg (stringCombo);
        isStringComboInCellArr = any(ismember(lower(cellArray),lower(strs)));
        return;
    end
    
    for argInd = 1:nArgsInStringCombo
        strs = getAllStrsFromArg (stringCombo{argInd});
        isStringComboInCellArr = isStringComboInCellArr & any(ismember(lower(cellArray),lower(strs)));
    end
    
    
end

function strs = getAllStrsFromArg (argStr)
    strs = strtrim(strsplit(argStr,{'\','/'}));
end