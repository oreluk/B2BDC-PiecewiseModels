function opt = piecewiseOptions(varargin)
% OPT = PIECEWISEOPTION(VARARGIN) returns a structure of options used by
% PiecewiseModel. ErrorTolernace, MaxDepth, MaxNumberOfModels, and ExpBounds 
% are used in treeBuilder to determine if branching occurs for a 
% PiecewiseModel. If any tolerances are exceeded or self-inconsistency is 
% shown, the model is saved and no longer branches further. A description 
% of the Options and the associated field names are: 
% 
% ErrorTolerance: the maximum absolute error tolerance between simulation
% and surrogate model. Piecewise model will continue to branch until error
% tolerance is met. Default value = 0.1.
% 
% MaxDepth: is a positive integer specifying the maximum depth a tree can 
% span. Once a Piecewise model spans beyond the maximum depth, the 
% branching stops. For a binary tree, the depth and maximum number of 
% models are associated by: 
%
%                   Maximum Number of Models = 2^(depth);
%
% The default value for maximum depth is 5. 
% 
% MaximumNumberOfModels: is an positive integer value specifying the maximum 
% number of models in ModelTree. Once met, branching of the PiecewiseModel 
% tree stops and all leaves not stored are added. This results in the
% number of Models in ModelTree to exceed MaximumNumberOfNodes. Default
% value = Inf.
%
% ExpBounds: is a 1-by-2 numerical array containing experimental bounds for
% the quantity-of-interest. If experimental bounds are provided, 
% self-consistency of that model is checked. If the Model is inconsistent, 
% the model is saved and no longer branched.  Default value = [].
%
% Verbose: is a logical value to turn on verbose output during the
% construction of PiecewiseModels. Default value = true. 
%
% OutputMessage: is a string used to update the printed progress. 
%
% SafetyFactor is a multipler on the error estimate. If SafetyFactor is 2, the error estimated 
% for the surrogate model will be doubled. 
%
% JointConsistency is a logical true / false. If True, a function called approach2(obj, newModel, data) is called 
% which will construct a dataset over the piecewise domain currently being assessed. 
% 
% QOI is an integer value specifying which column of y-data is the QOI being assessed.
% 
%% Default Options

opt.ErrorTolerance = 0.1;
opt.MaxDepth = 5;
opt.MaxNumberOfModels = Inf;
opt.ExpBounds = [];
opt.Verbose = true;
opt.OutputMessage = '';
opt.jointConsistency = false;
opt.SafetyFactor = 1;
opt.ErrorType = 'absolute';
opt.QOI = 1;
opt.Dataset = {};
opt.ChangeTemplateQOI = 0;


%% Update option with user input

optPairs = varargin;
if mod(length(optPairs), 2)
    error('Piecewise Option requires pairs of inputs. An option field name and value.')
end

for i = 1:2:length(optPairs)
    if ischar(optPairs{i})
        switch lower(optPairs{i})
            case 'errortolerance'
                if isnumeric(optPairs{i+1})
                    opt.ErrorTolerance = optPairs{i+1};
                else
                    error('Absolute Error Tolerance needs to be a numerical value.')
                end
                
            case 'maxdepth'
                % if Positive Integer
                if (optPairs{i+1} >= 0) && (mod(optPairs{i+1},1) == 0)
                    opt.MaxDepth = optPairs{i+1};
                else
                    error('Max Depth needs to be a positive integer.')
                end
                
            case 'maxnumberofmodels'
                if isinteger(optPairs{i+1})
                    opt.MaxNumberOfModels = optPairs{i+1};
                else
                    error('Max Number of Models in Model Tree needs to be an integer value.')
                end
                
            case 'expbounds'
                if isnumeric(optPairs{i+1}) && all(size(optPairs{i+1}) == [1 2])
                    opt.ExpBounds = optPairs{i+1};
                else
                    error('Experimental Bounds should be specified as a 1-by-2 array of numerical values.')
                end
                
            case 'verbose'
                if islogical(optPairs{i+1})
                    opt.Verbose = optPairs{i+1};
                else
                    error('Verbose should be specified as a logical value.')
                end
                
            case 'jointconsistency'
                opt.jointConsistency = optPairs{i+1};
            
            case 'safetyfactor'
                opt.SafetyFactor = optPairs{i+1};
                
            case 'errortype'
                opt.ErrorType = optPairs{i+1};
                
            case 'qoi'
                opt.QOI = optPairs{i+1};
                
            otherwise
                string = ['The option field name ', optPairs{i}, ...
                    ' did not match any entries and will be ignored.'];
                warning(string)
        end
    end
end

opt.remainingNodes = 2^(opt.MaxDepth);
