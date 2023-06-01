function dz = getCohensDZ(diffs)
dz = nanmean(diffs)./nanstd(diffs);