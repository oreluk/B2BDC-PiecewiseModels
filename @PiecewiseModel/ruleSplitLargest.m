function [varIdx, newBound1, newBound2, data] = ruleSplitLargest(obj, varList, data)
%% RULE: Split largest parameter uncertainty in half
H = varList.calBound;
w = H(:,2)-H(:,1);
[~,varIdx] = max(w);

var2Split = varList.Values(varIdx(1));
l = var2Split.LowerBound;
u = var2Split.UpperBound;
newBound1 = [l (u+l)/2];
newBound2 = [(u+l)/2 u];