function iterateLoop(Loop,TaskParams,Instr,loop_index,SD_mode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% USAGE: iterateLoop(Loop,TaskParams,Instr,loop_index,SD_mode)
%
% Description: This routine will set all of the parameters in the structure
% Loop to the value appropriate value given by the parameter 'loop_index'.
% 
% v1.1 14 JUNE 2010 William Kelly <wkelly@bbn.com>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('SD_mode','var')
    SD_mode = 1;
end
numParameters = numel(Loop.parameter);
for param_index = 1:numParameters % for each parameter
    pName = Loop.parameter{param_index};
    pValue = Loop.range{param_index}{loop_index};
    pInstr = Instr.(Loop.deviceTag{param_index});
    taskName_i = Loop.taskName{param_index};
    taskParams_i = TaskParams.(taskName_i);
    taskParams_i.taskParameters.taskName = taskName_i;
    % finally, we call setParameter
    setParameter(pName,pValue,taskParams_i,pInstr,SD_mode);
end

end