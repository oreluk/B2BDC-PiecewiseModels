function branch(obj, varList, data)
% BRANCH(OBJ, VARLIST) branches a binary tree into two sub-domains
% (children nodes) of VARLIST1 and VARLIST2. The VARLIST is divided by
% heuristics detailed in RULE.

[varList1, varList2, data] = obj.rule(varList, data); % Split VARLIST

% Divide data into two parts
inVarList = obj.inDomain(varList1, data.X);
data1.X = data.X(logical(inVarList), :);
data1.y = data.y(logical(inVarList), :);
data2.X = data.X(~inVarList, :);
data2.y = data.y(~inVarList, :);

obj.grow(varList1, data1); % Child Node 1
obj.grow(varList2, data2); % Child Node 2
obj.Depth = obj.Depth - 1;

