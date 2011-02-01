function cmdString = setParameter(parameterName,parameterValue,TaskParams,Instr,SDMode)

if ~exist('SDMode','var')
    SDMode = 1;
end
deviceTag = TaskParams.taskParameters.deviceTag;
propNames = properties(Instr);
% we check to see whethere "parameterName" is a property or a method
if sum(strcmp(propNames,parameterName))
    % if it's a property we set it equal to parameterValue
    if isstruct(parameterValue)
        % almostany2str can't handle structures, but this works
        cmdString = ['Instr.' ...
            parameterName ' = parameterValue;'];
    else
        cmdString = ['Instr.' ...
            parameterName ' = ' almostany2str(parameterValue) ';'];
    end
elseif ismethod(Instr,parameterName)
    % if it's a method we pass in both parameterValue, and TaskParams, in
    % that order.
    if isstruct(parameterValue)
        % almostany2str can't handle structures, but this works
        cmdString = ['Instr.' ...
            parameterName '(parameterValue,TaskParams);'];
    else
        cmdString = ['Instr.' ...
            parameterName '(' almostany2str(parameterValue) ',TaskParams);'];
    end
else
    error('%s is neither a method nor a property of %s',parameterName,deviceTag);
end
% finally, if we're not in SDMode we evaluate the statement
disp(cmdString)
if ~SDMode
    eval(cmdString)
end

end