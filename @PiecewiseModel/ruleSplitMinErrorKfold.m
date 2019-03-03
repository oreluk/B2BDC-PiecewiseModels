function [varIdx, newBound1, newBound2, data] = ruleSplitMinErrorKfold(obj, varList, data)
oldData = data;

%
% Change Template QOI is 1 when we are consistent & fitting error of the selected
%  'Template QOI' is less than Error Tolerance. QOI with the worst fitting error becomes
%  the new 'Template QOI' to guide splitting decisions.
% 
% ChangeTemplateQOI is set in 'approach2'

if obj.Options.ChangeTemplateQOI == 1
    obj.Options.ChangeTemplateQOI = 0;
    ds = obj.Options.Dataset{length(obj.ModelTree) + 1};
    
    for i = 1:length(ds)
        absErr(i) = ds.DatasetUnits.Values(i).SurrogateModel.ErrorStats.absMax;
        relErr(i) = ds.DatasetUnits.Values(i).SurrogateModel.ErrorStats.relMax;
    end
    
    if strcmpi(obj.Options.ErrorType, 'absolute')
        qoi = find(max(absErr) == absErr);
    elseif strcmpi(obj.Options.ErrorType, 'relative')
        qoi = find(max(relErr) == relErr);
    end
else
    qoi = obj.Options.QOI;
end

%%

nVar = length(varList);
nSample = 2 * (nVar + 1) * (nVar + 2);
for i = 1:nVar
    var2Split = varList.Values(i);
    l = var2Split.LowerBound;
    u = var2Split.UpperBound;
    newBound1 = [l (u+l)/2];
    newBound2 = [(u+l)/2 u];
    
    % Fit Child 1
    v1 = varList.changeBound(newBound1, i);
    inVarList1 = obj.inDomain(v1, oldData.X);
    idx1 = find(inVarList1 == 1);
    X1 = oldData.X(idx1, :);
    y1 = oldData.y(idx1, :);
    nX = size(X1,1);
    
    
    if nX < nSample
        % do not have enough points...
        % add diag noise (regularizer)
        %         warning('Required more Samples in Rule')
        
        % for the time being...take a little more samples than required to be a determined system.
        X1new = v1.makeLHSsample(floor(1.1*(nSample - nX)));
        [y1New, X1new] = obj.FunctionHandle(X1new);
        
        y1 = [y1; y1New];
        X1 = [X1; X1new];
        
        % save new data generated
        oldData.X  = [oldData.X; X1new];
        oldData.y = [oldData.y; y1New];
    end
    
    
    
    %% Estimate Test Error: k-fold

    % To make permIdx (i.e., the folds) deterministic, uncomment 69, 70, and comment 73. 
%     s = RandStream('mt19937ar','Seed',0);
%     permIdx = randperm(s, size(X1,1)); % Random ordering of X/y data
    kFolds = 10;

    permIdx = randperm(size(X1,1));
    nPerFold = floor(size(X1,1)/kFolds); %
    err = [];
    relErr = [];
    
    for k = 1:kFolds
        % kRange is defines elements for each fold
        if k == kFolds
            kRange = (k*nPerFold + 1) - nPerFold : size(X1, 1);
        else
            kRange = (k*nPerFold + 1) - nPerFold : k*nPerFold;
        end
        
        % k-fold index is zero for elements in k-th fold
        kIndex = ones(size(X1,1), 1);
        kIndex(kRange) = 0;
        
        % Filter X/y data for elements in k-fold index
        try
            Xtrain = X1(permIdx(logical(kIndex)),:);
            
            yTrain = y1(permIdx(logical(kIndex)), qoi);
            
        catch
            keyboard
        end
        
        
        Xtest = X1(permIdx(~logical(kIndex)),:);
        yTest = y1(permIdx(~logical(kIndex)), qoi);
        
        newModel = generateModelbyFit(Xtrain, yTrain, v1, 'q2norm');
        yPred = newModel.eval(Xtest);
        e = abs(yPred - yTest);
        relE = abs(e./yTest);
        err = [err; e];
        relErr = [relErr; relE];
    end
    
    maxError = max(err);
    maxRelativeError = max(relErr);
    newModel1 = generateModelbyFit(X1, y1(:,qoi), v1, 'q2norm');
    newModel1.ErrorStats.absMax = maxError * obj.Options.SafetyFactor;
    newModel1.ErrorStats.relMax = maxRelativeError * obj.Options.SafetyFactor;
    
    %% Fit Child 2
    v2 = varList.changeBound(newBound2, i);
    inVarList2 = obj.inDomain(v2, oldData.X);
    idx2 = find(inVarList2 == 1);
    X2 = oldData.X(idx2,:);
    y2 = oldData.y(idx2,:);
    nX = size(X2,1);
    
    if nX < nSample
        % do not have enough points...
        % add diag noise (regularizer)
        %         warning('Required more samples in Rule')
        % for the time being...take a little more samples than required to be a determined system.
        X2new = v2.makeLHSsample(floor(1.1*(nSample - nX)));
        [y2New, X2new] = obj.FunctionHandle(X2new);
        
        y2 = [y2; y2New];
        X2 = [X2; X2new];
        
        % save new data generated
        oldData.X  = [oldData.X; X2new];
        oldData.y = [oldData.y; y2New];
    end
    
    
    
    %% Estimate Test Error: k-fold
%     s = RandStream('mt19937ar','Seed',0);
    kFolds = 10;
%     permIdx = randperm(s, size(X2,1)); % Random ordering of X/y data
    permIdx = randperm(size(X2,1));
    nPerFold = floor(size(X2,1)/kFolds); %
    err = [];
    relErr = [];
    
    for k = 1:kFolds
        % kRange is defines elements for each fold
        if k == kFolds
            kRange = (k*nPerFold + 1) - nPerFold : size(X2, 1);
        else
            kRange = (k*nPerFold + 1) - nPerFold : k*nPerFold;
        end
        
        % k-fold index is zero for elements in k-th fold
        kIndex = ones(size(X2,1), 1);
        kIndex(kRange) = 0;
        
        % Filter X/y data for elements in k-fold index
        try
            Xtrain = X2(permIdx(logical(kIndex)),:);
            
            yTrain = y2(permIdx(logical(kIndex)), qoi);
        catch
            keyboard
        end
        
        Xtest = X2(permIdx(~logical(kIndex)),:);
        yTest = y2(permIdx(~logical(kIndex)), qoi);
        
        newModel = generateModelbyFit(Xtrain, yTrain, v2, 'q2norm');
        yPred = newModel.eval(Xtest);
        e = abs(yPred - yTest);
        relE = abs(e./yTest);
        err = [err; e];
        relErr = [relErr; relE];
    end
    
    maxError = max(err);
    maxRelativeError = max(relErr);
    newModel2 = generateModelbyFit(X2, y2(:,qoi), v2, 'q2norm');
    newModel2.ErrorStats.absMax = maxError * obj.Options.SafetyFactor;
    newModel2.ErrorStats.relMax = maxRelativeError * obj.Options.SafetyFactor;
    
    minError(i) = min(newModel1.ErrorStats.absMax, newModel2.ErrorStats.absMax);
end

varIdx = find(min(minError) == minError);

var2Split = varList.Values(varIdx(1));
l = var2Split.LowerBound;
u = var2Split.UpperBound;
newBound1 = [l (u+l)/2];
newBound2 = [(u+l)/2 u];

data = oldData;