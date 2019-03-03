function [varIdx, newBound1, newBound2, data] = ruleSplitMinError(obj, varList, data);
oldData = data;

%% chemical kinetic example - qoi2 only
% if obj.Options.jointConsistency
%     oldData.y = oldData.y(:,2);
% end

qoi = obj.Options.QOI;


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
        y1New = obj.FunctionHandle(X1new);


        %%
        %% chemical kinetic example
%         if obj.Options.jointConsistency
%             y1New = y1New(:,2);
%         end

        y1 = [y1; y1New];
        X1 = [X1; X1new];

        % save new data generated
        oldData.X  = [oldData.X; X1new];
        oldData.y = [oldData.y; y1New];

    end



    percTraining = 0.8;
    trainingIdx = randperm(size(y1,1));
    nTraining = floor(percTraining*size(y1,1));

    xTrain = X1(trainingIdx(1:nTraining), :);
    xTest = X1(trainingIdx(nTraining+1:end), :);

    yTrain = y1(trainingIdx(1:nTraining), qoi);
    yTest =  y1(trainingIdx(nTraining+1:end), qoi);

    % Build Model
    newModel1 = generateModelbyFit(xTrain, yTrain, v1, 'q2norm');

    % Evaluate Test Error
    ySurrogate = newModel1.eval(xTest);
    absE = abs(ySurrogate - yTest);

    % Update Error
    newModel1.ErrorStats.absMax = max(absE);
    newModel1.ErrorStats.absAvg = mean(absE);
    relE = absE./yTest;
    newModel1.ErrorStats.relMax = max(relE);
    newModel1.ErrorStats.relAvg = mean(relE);

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
        y2New = obj.FunctionHandle(X2new);


        %% chemical kinetic example
%         if obj.Options.jointConsistency
%             y2New = y2New(:,2);
%         end

        y2 = [y2; y2New];
        X2 = [X2; X2new];

        % save new data generated
        oldData.X  = [oldData.X; X2new];
        oldData.y = [oldData.y; y2New];
    end


    percTraining = 0.8;
    trainingIdx = randperm(size(y2,1));
    nTraining = floor(percTraining*size(y2,1));

    xTrain2 = X2(trainingIdx(1:nTraining), :);
    xTest2 = X2(trainingIdx(nTraining+1:end), :);

    yTrain2 = y2(trainingIdx(1:nTraining), qoi);
    yTest2 =  y2(trainingIdx(nTraining+1:end), qoi);

    % Build Model
    newModel2 = generateModelbyFit(xTrain2, yTrain2, v2, 'q2norm');

    % Evaluate Test Error
    ySurrogate = newModel2.eval(xTest2);
    absE = abs(ySurrogate - yTest2);

    % Update Error
    newModel2.ErrorStats.absMax = max(absE);
    newModel2.ErrorStats.absAvg = mean(absE);
    relE = absE./yTest2;
    newModel2.ErrorStats.relMax = max(relE);
    newModel2.ErrorStats.relAvg = mean(relE);

    minError(i) = min(newModel1.ErrorStats.absMax, newModel2.ErrorStats.absMax);
end

varIdx = find(min(minError) == minError);

var2Split = varList.Values(varIdx(1));
l = var2Split.LowerBound;
u = var2Split.UpperBound;
newBound1 = [l (u+l)/2];
newBound2 = [(u+l)/2 u];

data = oldData;