classdef PiecewiseModel < B2BDC.B2Bmodels.Model
    
    properties
        ModelTree = []; % Array of submodels
        Options = [];
        FunctionHandle = []; % Used to build piecewise model
        Type = [];
        ModelConsistency = []; % Index of consistent models in ModelTree
        %  each model in ModelTree
        ErrorFlag = 0; % Used to indicate a specific error in the
        %  construction of a pwm
    end
    
    properties (Hidden = true)
        Depth = 0; % Used in treeBuilder to determine current depth of node
    end
    
    methods
        function obj = PiecewiseModel(funcHandle, type, varList, data, option)
            % PiecewiseModel constructs a binary tree of surrogate models
            % where each leave is a new sub-domain of the original VARLIST.
            % Surrogate models are fit to FUNCHANDLE as specified by TYPE.
            % FUNCHANDLE is a function handle which takes as an input a
            % matrix of size nSamples-by-nVars and returns a vector of
            % size nSamples-by-1 of responses. ERRTOL and DEPTHTOL both
            % terminate branching of the binary tree. ERRTOL specifies an
            % absolute maximum error tolerance to be satisfied. MAXDEPTH
            % specifies how many branches from the root a node can span.
            % VARLIST is a VariableList specifying the original domain.
            % DATA is an optional structure input with fields of DATA.X and
            % DATA.y if the function has been evaluated
            % previous.
            
            % User supplied data
            if nargin > 3
                if ~isempty(data)
                    if ~isstruct(data)
                        error('Data must be supplied as a structure with X and y fields');
                    end
                else
                    data.X = [];
                    data.y = [];
                end
            end
            
            if nargin > 4
                if isstruct(option)
                    obj.Options = option;
                else
                    error('Options for Piecewise model must be created by piecewiseOptions()')
                end
            else
                obj.Options = piecewiseOptions;
            end
            
            if ~isa(funcHandle, 'function_handle')
                error('Must provide a function_handle to construct a PiecewiseModel');
            elseif ~ischar(type)
                error('Must provide a string specifying the type of models to fit for a PiecewiseModel (qinf/q2norm/rq)');
            elseif ~isa(varList, 'B2BDC.B2Bvariables.VariableList')
                error('Must provide a B2BDC.B2Bvariables.VariableList for constructions of a PiecewiseModel');
            end
            
            obj.FunctionHandle = funcHandle;
            obj.Type = type;
            obj.Variables = varList;
            obj.grow(varList, data);
            
        end
        
        function idx = findModelIndex(obj, X)
            % Takes in a matrix of design points X and returns a vector of
            % indices idx for the relevant models in ModelTree
            
            nSamples = size(X,1);
            nModels = length(obj.ModelTree);
            idx = zeros(nSamples,1);
            for ii = 1:nSamples
                for jj = 1:nModels
                    if obj.inDomain(obj.ModelTree(jj).Variables, X(ii,:))
                        idx(ii) = jj;
                        break;
                    end
                end
            end
        end
        
        function y = eval(obj, X)
            % Takes in an matrix of points, finds the B2BDC.B2Bmodels in
            % ModelTree associated with those points, and evaluates the
            % relevant models to return a vector of output.
            
            nSamples = size(X,1);
            idx = obj.findModelIndex(X);
            y = zeros(nSamples,1);
            
            % Loop over models and evaluate the data points
            modelIdx = unique(idx);
            for ii = 1:length(modelIdx)
                filter = idx == modelIdx(ii);
                y(filter) = obj.ModelTree(modelIdx(ii)).eval(X(filter, :));
            end
        end
        
        function y = length(obj)
            % Return number of models in obj.ModelTree
            y = length(obj.ModelTree);
        end
        
    end
end

