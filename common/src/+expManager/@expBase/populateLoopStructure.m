function [Loop, dimension] = populateLoopStructure(obj, sweepPtsOnly)

    if nargin < 2
        sweepPtsOnly = false;
    end
    SweepParams  = obj.inputStructure.SweepParams;

    SweepNames = fieldnames(SweepParams);
    numSweepVariables = numel(SweepNames);
    emptySweep = struct('type','sweeps.Nothing');
    Loop = struct('one',emptySweep,'two',emptySweep,'three',emptySweep);
    % error checking
    dimension = 0;
    for i_loop = 1:numSweepVariables
        % find all sweeps that have a number
        if isfield(SweepParams.(SweepNames{i_loop}), 'number')
            % update the dimension of the sweep
            if isnumeric(SweepParams.(SweepNames{i_loop}).number) && SweepParams.(SweepNames{i_loop}).number > dimension
                dimension = SweepParams.(SweepNames{i_loop}).number;
            end
            % copy the Sweep params to the Loop struct
            switch SweepParams.(SweepNames{i_loop}).number
                case 1
                    assert(strcmp(Loop.one.type,'sweeps.Nothing'), 'There can only be one structure assigned to loop 1')
                    Loop.one = SweepParams.(SweepNames{i_loop});
                case 2
                    assert(strcmp(Loop.two.type,'sweeps.Nothing'), 'There can only be one structure assigned to loop 2')
                    Loop.two = SweepParams.(SweepNames{i_loop});
                case 3
                    assert(strcmp(Loop.three.type,'sweeps.Nothing'), 'There can only be one structure assigned to loop 3')
                    Loop.three = SweepParams.(SweepNames{i_loop});
                otherwise
                    % if a sweep 'number' is a string, assign a loop with
                    % that name
                    if ischar(SweepParams.(SweepNames{i_loop}).number)
                        Loop.(SweepParams.(SweepNames{i_loop}).number) = SweepParams.(SweepNames{i_loop});
                    else
                        error('Unrecognized loop number');
                    end
            end
        end
    end

    % now generate the sweep objects
    for i_loop_cell = fieldnames(Loop)'
        i_loop_str = cell2mat(i_loop_cell);
        if ~isempty(Loop.(i_loop_str))
            if sweepPtsOnly
                Loop.(i_loop_str).sweep = feval(Loop.(i_loop_str).type, ...
                    Loop.(i_loop_str), [], obj.inputStructure, sweepPtsOnly);
            else
                Loop.(i_loop_str).sweep = feval(Loop.(i_loop_str).type, ...
                    Loop.(i_loop_str), obj.Instr, obj.inputStructure, sweepPtsOnly);
            end
            Loop.(i_loop_str).steps = length(Loop.(i_loop_str).sweep.points);
            Loop.(i_loop_str).plotRange = Loop.(i_loop_str).sweep.points;
        end
    end
end