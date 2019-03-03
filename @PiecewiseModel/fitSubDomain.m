function  [newModel, data] = fitSubDomain(obj, varList, data)
% NEWMODEL = fitSubDomain(OBJ, VARLIST, DATA)

% FITSUBDOMAIN will take in a PiecewiseModel OBJ and determine from TYPE
% how many samples are needed to fit on new sub-domain. TYPE is a string
% specifying the type of surrogate models used in GENERATEMODELBYFIT.
% Previous data coming from OBJ.DATA is recycled and only if new data is
% needed, FUNCHANDLE is evaluated on new X values to fit a model of TYPE.
% VARLIST is a B2BDC.B2Bvariables.VariableList specifying the new
% sub-domain to fit a surrogate model on.

if strcmpi(obj.Type, 'qinf') || strcmpi(obj.Type, 'q2norm')
    nSample = 4 * (length(varList) + 2) * (length(varList) + 1);
elseif strcmpi(obj.Type, 'rq')
    nSample = 4 * (length(varList) + 2) * (length(varList) + 1);
else
    error('Type not recognized.')
end

% Input Data is in Domain
if obj.Depth == 0
    oldData = data;
    inVarList = obj.inDomain(varList, oldData.X);
    idx = find(inVarList == 1);
    X = oldData.X(idx,:);
    y = oldData.y(idx,:);
else
    X = data.X;
    y = data.y;
end

nX = size(X,1);

if nX < nSample
    XNew = varList.makeLHSsample(nSample-nX);
    [yNew, XNew] = obj.FunctionHandle(XNew);
    
    X = [X; XNew];
    y = [y; yNew];
    
    
    %% If returned data is less than 75% of the samples. 
    % Resample region

    nResamples = 5;
    iter = 0;
    while length(y) < 0.75 * nSample && iter < numResamples
        iter = iter + 1;
        nX = size(X,1);
        XNew = varList.makeLHSsample(nSample-nX);
        [yNew, XNew] = obj.FunctionHandle(XNew);
        
        X = [X; XNew];
        y = [y; yNew];
    end
    
     %% Check if enough data is returned
    if length(y) < 0.75 * nSample
        obj.ErrorFlag = 1;
        nVar = length(varList);
        coef = zeros(nVar+1, nVar+1);
        coef(1,1) = Inf;
        newModel = B2BDC.B2Bmodels.QModel(coef, varList);
        newModel.ErrorStats.absMax = -1;
        newModel.ErrorStats.absAvg = -1;
        newModel.ErrorStats.relMax = -1;
        newModel.ErrorStats.relAvg = -1;
        newModel.ErrorStats.PhysicalUnits.Absolute = -1;
        newModel.ErrorStats.PhysicalUnits.Relative = -1;
        data = [];
        warning('Returned Data was less than 75% which was requested. Domain deemed invalid due to insufficent data')
        return
    end
end


%% for joint consistency , we only fit on the selected QOI at first
if obj.Options.jointConsistency
    yOriginal = y;
    y = y(:,obj.Options.QOI);
end


%% Estimate Test Error: k-fold
% s = RandStream('mt19937ar','Seed',0);
% permIdx = randperm(s, size(X,1)); % Random ordering of X/y data

permIdx = randperm(size(X,1));

kFolds = 10;
nPerFold = floor(size(X,1)/kFolds); %
err = [];
relErr = [];

for k = 1:kFolds
    % kRange is defines elements for each fold
    if k == kFolds
        kRange = (k*nPerFold + 1) - nPerFold : size(X, 1);
    else
        kRange = (k*nPerFold + 1) - nPerFold : k*nPerFold;
    end
    
    % k-fold index is zero for elements in k-th fold
    kIndex = ones(length(y), 1);
    kIndex(kRange) = 0;
    
    % Filter X/y data for elements in k-fold index
    Xtrain = X(permIdx(logical(kIndex)),:);
    yTrain = y(permIdx(logical(kIndex)));
    
    Xtest = X(permIdx(~logical(kIndex)),:);
    yTest = y(permIdx(~logical(kIndex)));
    
    newModel = generateModelbyFit(Xtrain, yTrain, varList, obj.Type);
    yPred = newModel.eval(Xtest);
    e = abs(yPred - yTest);
    relE = abs(e./yTest);
    err = [err; e];
    relErr = [relErr; relE];
end

maxError = max(err);
maxRelativeError = max(relErr);
newModel = generateModelbyFit(X, y, varList, obj.Type);
newModel.ErrorStats.absMax = maxError * obj.Options.SafetyFactor;
newModel.ErrorStats.relMax = maxRelativeError * obj.Options.SafetyFactor;

%% Estimate Test Error: Hold Out set  70/30 split (train/test)
% percTraining = 0.7;
% trainingIdx = randperm(size(y,1));
% nTraining = floor(percTraining*size(y,1));
%
% xTrain = X(trainingIdx(1:nTraining), :);
% xTest = X(trainingIdx(nTraining+1:end), :);
%
% yTrain = y(trainingIdx(1:nTraining), :);
% yTest =  y(trainingIdx(nTraining+1:end), :);
%
% % Build Model
% newModel = generateModelbyFit(xTrain, yTrain, varList, obj.Type);
%
% % Evaluate Test Error
% ySurrogate = newModel.eval(xTest);
% absE = abs(ySurrogate - yTest);
%
% % Update Error
% newModel.ErrorStats.absMax = max(absE);
% newModel.ErrorStats.absAvg = mean(absE);
% relE = absE./yTest;
% newModel.ErrorStats.relMax = max(relE);
% newModel.ErrorStats.relAvg = mean(relE);




%% chemical kinetics example
if obj.Options.jointConsistency
    y = yOriginal;
end


%% Update Data


data.X = X;
data.y = y;
