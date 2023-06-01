function vec = makeColumn(vec)
assert(isvector(vec));
if (isrow(vec))
    vec = vec';
end