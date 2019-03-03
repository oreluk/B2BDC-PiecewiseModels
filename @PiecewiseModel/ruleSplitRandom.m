function [varIdx, newBound1, newBound2, data] = ruleSplitRandom(obj, varList, data)
%% RULE: Split random variable in half

H = varList.calBound;
varIdx = randperm(length(varList));

var2Split = varList.Values(varIdx(1));
l = var2Split.LowerBound;
u = var2Split.UpperBound;
newBound1 = [l (u+l)/2];
newBound2 = [(u+l)/2 u];

