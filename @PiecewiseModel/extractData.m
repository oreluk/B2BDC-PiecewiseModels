function data = extractData(obj)
% data is a structure with two fields, X and y. 
% obj is a B2BDC Piecewise Surrogate Model
% 
% extractData will loop over the piecewise surrogate model object and
% obtain data from all pieces of the ModelTree
% 

data.X = [];
data.y = [];

for i = 1:length(obj)
    data.X = [data.X; obj.ModelTree(i).Data.X];
    data.y = [data.y; obj.ModelTree(i).Data.y];
end
