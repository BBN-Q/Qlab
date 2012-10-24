function range = generateParamRange(ParamStart,ParamEnd,numSteps)

% we're going to assume that ParamStart and ParamEnd have identical
% structure.  If not we'll definitely get an error.

if isnumeric(ParamStart)
    numValues = numel(ParamStart);
    temp = zeros(numSteps,numValues);
    for i_value = 1:numValues
        temp(:,i_value) = linspace(ParamStart(i_value),ParamEnd(i_value),numSteps);
    end
    range = mat2cell(temp,ones(1,numSteps),size(temp,2));
elseif iscell(ParamStart)
    error('Have not implemented cell case yet')
elseif isstruct(ParamStart)
    fNames = fieldnames(ParamStart);
    range = cell(1,numSteps);
    for name_index = 1:numel(fNames)
        name_i = fNames{name_index};
        % we use a recursive function call to handle structures.  The
        % assumption is that eventually we'll get to an array or a cell.
        temp = generateParamRange(ParamStart.(name_i),ParamEnd.(name_i),numSteps);
        for step_index = 1:numSteps
            range{step_index}.(name_i) = temp{step_index};
        end
    end
else
end

end