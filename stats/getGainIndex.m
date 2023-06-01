function gainIndex = getGainIndex(values1,values2)
assert(isequal(size(values2),size(values1)));

if isrow(values2)
    gainIndex = (values1-values2)./max([values2; values1],[],1);
elseif iscolumn(values2)
    gainIndex = (values1-values2)./max([values2, values1],[],2);
else
    assert(length(size(values2))==2);
    mat3d(:,:,2) = values1;
    mat3d(:,:,1) = values2;
    gainIndex = (values1-values2)./max(mat3d,[],3);
end