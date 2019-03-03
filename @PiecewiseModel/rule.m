function [varList1, varList2, data] = rule(obj, varList, data)
% [VARLIST1, VARLIST2] = RULE(OBJ, VARLIST) heuristic rules for determining
% sub-domains of VARLIST.

% RULE is used to determine how and where to split VARLIST which is a
% B2BDC.B2Bvariables.VariableList into two sub-domains VARLIST1 and
% VARLIST2.

%% RULE: Split largest parameter uncertainty in half
% 
% [varIdx, newBound1, newBound2, data] = obj.ruleSplitLargest(varList, data);

%% RULE: Split random variable in half
% 
% [varIdx, newBound1, newBound2, data] = obj.ruleSplitRandom(varList, data);

%% RULE: Split each variable one at a time and fit with a 2norm quadratic
% model. Model with smallest 2norm error is the varIdx to be split in half.

% [varIdx, newBound1, newBound2, data] = obj.ruleSplitMinError(varList, data);

%% RULE: Split each variable by the golden ratio one-at-a-time
% 
% [varIdx, newBound1, newBound2, data] = obj.ruleSplitMinErrorGolden(varList, data);

%% RULE: Split each variable one-at-a-time and fit with a 2 norm quadratic model. 
% Model with smallest 2 norma error is the var to split, splits can occur at 
% (1/4, 1/3, 1/2, 2/3, 3/4)
% 
%
% [varIdx, newBound1, newBound2, data] = obj.ruleSplitMinErrorVariousPartitions(varList, data)

%% Rule: Split each variable one-at-a-time and fit with a 2norm quadratic
% k-fold is used to estimate error. 

[varIdx, newBound1, newBound2, data] = obj.ruleSplitMinErrorKfold(varList, data);

%%

varList1 = varList.changeBound(newBound1, varIdx(1));
varList2 = varList.changeBound(newBound2, varIdx(1));


