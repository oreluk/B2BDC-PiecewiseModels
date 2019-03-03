function inD = inDomain(obj, varList, X)
% IND = INDOMAIN(OBJ, VARLIST, X) checks to see if X is in the domain of
% VARLIST. 
%
% THIS FUNCTION MAY BE UNNECESSARY, VARLIST HAS IT'S OWN ISFEASIBLEPOINT IN
% B2BDC v0.8.

if isempty(X)
    inD = 0;
end

% This needs to change for linear constraints, also the function should be 
% the equivalent of isFeasiblePoint but for variablesList objects rather 
% than datasets.

H = varList.calBound;  
nSamples = size(X,1);
inD = ones(nSamples,1);

for ii = 1:nSamples
    if any(H(:,1) > X(ii,:)')
        inD(ii) = 0;
    elseif any(H(:,2) < X(ii,:)')
        inD(ii) = 0;
    end
end

