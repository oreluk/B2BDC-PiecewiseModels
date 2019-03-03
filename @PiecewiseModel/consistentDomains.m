function consistency = consistentDomains(obj, newModel)
% find joint consistency

%% Current consistent dataset
ds = obj.Options.jointConsistency;

%% for the domain considered in newModel
varList = newModel.Variables;

% build dataset with newmodel and olds dsu's on new domain.
newDS = generateDataset('test');
dsU = generateDSunit('newModel', newModel, obj.Options.ExpBounds);
newDS.addDSunit(dsU)

for ii = 1:length(ds)
    dsu = ds.DatasetUnits.Values(ii);
    if isa(dsu.SurrogateModel, 'B2BDC.B2Bmodels.QModel')
        model = dsu.SurrogateModel;
    elseif isa(dsu.SurrogateModel, 'B2BDC.B2Bmodel.PiecewiseModel')
        for jj = 1:length(dsu.SurrogateModel)
            modelVarList = ds.DatasetUnits.Values(ii).SurrogateModel.Variables;
            if isIntersecting(varList, modelVarList)
                model = dsu.SurrogateModel.ModelTree(jj);
            end
        end
    end
    % change bounds of intersecting variables...to newModel.Variables
    % bounds, leave all others the same
    
    model = changeModelBounds(model, newModel.Variables);
    expBounds = [dsu.LowerBound, dsu.UpperBound];
    newDSU = generateDSunit(strcat('qoi_', num2str(ii)), model, expBounds);
    newDS.addDSunit(newDSU);
end

%% Check consistency of newDS
opt = B2BDC.Option;
opt.AddFitError = true;
opt.Display = false;
consistency = newDS.isConsistent(opt);

%% Internal Function

    function flag = isIntersecting(varList1, varList2)
        varNames1 = {varList1.Values.Name};
        varNames2 = {varList2.Values.Name};
        
        % Check common variable names
        % C = varNames1(IA);
        % C = varNames2(IB);
        [C,IA,IB] = intersect(varNames1, varNames2,'stable');
        
        varBounds1 = varList1.calBound;
        varBounds2 = varList2.calBound;
        c1 = varBounds1(IA,:);
        c2 = varBounds2(IB,:);
        
        if any(c1(:,1) > c2(:,2)) || any(c1(:,2) < c2(:,1) )
            % disjoint
            flag = false;
        else
            % intersection
            flag = true;
        end
    end

    function model = changeModelBounds(model, varList)
        varNames1 = {model.Variables.Values.Name};
        varNames2 = {varList.Values.Name};
        
        [C,IA,IB] = intersect(varNames1, varNames2, 'stable');
        
        coefMatrix = model.CoefMatrix;
        eStats = model.ErrorStats;
        
        names = {model.Variables.Values.Name};
        bounds = model.Variables.calBound;
        varBounds = varList.calBound;
        bounds(IA,:) = varBounds(IB,:);
        
        newList = generateVar(names, bounds);
        model = generateModel(coefMatrix, newList);
        model.ErrorStats = eStats;
    end

end