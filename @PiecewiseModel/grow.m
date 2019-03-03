function obj = grow(obj, listOrIdx, data)
% OBJ = GROW(OBJ, LISTORIDX) will take a PiecewiseModel object OBJ and
% grow the tree at a LISTORIDX, where LISTORIDX is either a
% B2BDC.B2Bvariables.VariableList or an index of a pre-existing model.
% This allows a user to build a tree specified by the
% B2BDC.B2Bvariable.VariableList. If LISTORIDX is a numerical value
% specifying the model index to grow from, then the
% B2BDC.B2Bvariable.VariableList will be taken from the specified model.
%
% Grow is recursively called by branch when error tolerance, max depth
% tolerance or maximum number of models is not met.
%

%% Check inputs
if nargin < 3
    data.X = [];
    data.y = [];
end

if isa(listOrIdx, 'B2BDC.B2Bvariables.VariableList')
    if size(listOrIdx, 2) > 1
        % Array of VariableLists
        for ii = 1:size(listOrIdx, 2)
            obj.grow(listOrIdx(ii), data);
        end
        return
    else
        varList = listOrIdx;
        % TODO we should remove any model with this variable list
    end
elseif isnumeric(listOrIdx)
    % An index is only passed to grow when building/growing from an already
    %  completed PWM
    
    if listOrIdx > length(obj.ModelTree)
        error('Model Index exceeds number of Models in ModelTree.');
    end
    for ii = 1:numel(listOrIdx)
        varList = obj.ModelTree(listOrIdx(ii)).Variables;
        data = obj.ModelTree(listOrIdx(ii)).Data;
        
        % Remove model from tree
        obj.ModelTree(listOrIdx(ii)) = [];
        obj.ModelConsistency(listOrIdx(ii)) = [];
        
        obj.grow(varList, data);
    end
    return
end

%% Create output table

if obj.Depth == 0 && obj.Options.Verbose
    fprintf(['\n\t size(ModelTree) \t\t Tree Depth \t\t max(|Error|) \t\t Nodes Remaining \n', ...
        '\t----------------- \t\t------------- \t\t-------------- \t\t----------------- \n'])
end

%% Fit model of OBJ.TYPE on domain of VARLIST

[newModel, data] = obj.fitSubDomain(varList, data);

if strcmpi(obj.Options.ErrorType, 'absolute')
    modelError = newModel.ErrorStats.absMax;
elseif strcmpi(obj.Options.ErrorType, 'relative')
    modelError = newModel.ErrorStats.relMax;
else
    error('Option:ErrorType is unknown')
end

%% Check Self Consistency
if ~obj.ErrorFlag
    selfConsistent = true;
    if ~isempty(obj.Options.ExpBounds)
        opt = generateOpt();
        opt.Display = false;
        opt.AddFitError = true;
        dsTest = B2BDC.B2Bdataset.Dataset;
        dsUnit = generateDSunit('test', newModel, obj.Options.ExpBounds);
        dsTest.addDSunit(dsUnit);
        dsTest.isConsistent(opt);
        
        
        measure = dsTest.ConsistencyMeasure(2);
        if measure < 0
            selfConsistent = 0;
        else
            selfConsistent = 1;
        end
    end
    
    % If jointConsistency is set to True, a function called 'approach2' is needed to construct a dataset and
    % check for consistency and return modelError. 
    if obj.Options.jointConsistency
        [selfConsistent, measure, modelError] = approach2(obj, newModel, data);
    end
    
    
    %% Decision to branch or save model
    
    s1 = modelError > obj.Options.ErrorTolerance;
    s2 = obj.Depth < obj.Options.MaxDepth;
    s3 = length(obj.ModelTree) < obj.Options.MaxNumberOfModels;
    
    if s1 && s2 && s3 && selfConsistent
        % Branch domain and increase depth
        obj.Depth = obj.Depth+1;
        printProgress(1);
        obj.branch(varList, data);
    else
        % Save model to ModelTree
        newModel.Data = data;
        obj.ModelTree = [obj.ModelTree newModel];
        
        if ~isempty(obj.Options.ExpBounds)
            obj.ModelConsistency = [obj.ModelConsistency measure];
        end
        printProgress(2);
        
        % Update PiecewiseModel error as maximum of error in ModelTree
        errStruct = [obj.ModelTree.ErrorStats];
        obj.ErrorStats.absMax = max([errStruct.absMax]);
        
        d = obj.ModelTree;
        save('currentPWM_progress', 'd');
    end
else
    % Error Occured in FitSubDomain
    obj.ErrorFlag = 0;
    
    % Save model to ModelTree
    newModel.Data = data;
    obj.ModelTree = [obj.ModelTree newModel];
    
    if ~isempty(obj.Options.ExpBounds)
        obj.ModelConsistency = [obj.ModelConsistency -Inf];
    end
    printProgress(2);
    
    % Update PiecewiseModel error as maximum of error in ModelTree
    try
        errStruct = [obj.ModelTree.ErrorStats];
    catch
        keyboard
    end
    obj.ErrorStats.absMax = max([errStruct.absMax]);
    obj.ErrorStats.relMax = max([errStruct.relMax]);
    
    d = obj.ModelTree;
    save('currentPWM_progress', 'd');
end

%% Internal Function

    function printProgress(flag)
        % PRINTPROGRESS updates the progress of fitting the PiecewiseModel
        if flag == 1 % update current line of progress
            if obj.Options.Verbose
                rev = repmat(sprintf('\b'), 1, length(obj.Options.OutputMessage));
                obj.Options.OutputMessage = sprintf(['\t\t ', ...
                    num2str(length(obj.ModelTree)+1), '\t\t\t\t\t\t ', ...
                    num2str(obj.Depth), '/', num2str(obj.Options.MaxDepth), ...
                    '\t\t\t   ', num2str(round(modelError,3)), '\t\t\t\t', ...
                    num2str(obj.Options.remainingNodes-1), '\n']);
                fprintf([rev, obj.Options.OutputMessage]);
            end
            
        elseif flag == 2 % create a new line of progress
            nodesBelow = 2^(obj.Options.MaxDepth-obj.Depth);
            obj.Options.remainingNodes = obj.Options.remainingNodes - nodesBelow;
            
            if obj.Options.Verbose
                rev = repmat(sprintf('\b'), 1, length(obj.Options.OutputMessage));
                obj.Options.OutputMessage = sprintf(['\t\t ', ...
                    num2str(length(obj.ModelTree)), '\t\t\t\t\t\t ', ...
                    num2str(obj.Depth), '/', num2str(obj.Options.MaxDepth), ...
                    '\t\t\t   ', num2str(round(modelError,3)), '\t\t\t\t', ...
                    num2str(obj.Options.remainingNodes) ,'\n']);
                fprintf([rev, obj.Options.OutputMessage]);
                obj.Options.OutputMessage = '';
            end
        end
    end
end
