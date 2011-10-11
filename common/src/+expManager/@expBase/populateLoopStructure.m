function Loop = populateLoopStructure(obj, sweepPtsOnly)

    if nargin < 2
        sweepPtsOnly = false;
    end
    SweepParams  = obj.inputStructure.SweepParams;

    SweepNames = fieldnames(SweepParams);
    numSweepVariables = numel(SweepNames);
    Loop = struct('one',[],'two',[],'three',[]);
    % error checking
    for i_loop = 1:numSweepVariables
        % find all sweeps that have a number
        if isfield(SweepParams.(SweepNames{i_loop}), 'number')
            switch SweepParams.(SweepNames{i_loop}).number
                case 1
                    if ~isempty(Loop.one),error('there can only be one structure assigned to loop 1'),end
                    Loop.one = SweepParams.(SweepNames{i_loop});
                case 2
                    if ~isempty(Loop.two),error('there can only be one structure assigned to loop 2'),end
                    Loop.two = SweepParams.(SweepNames{i_loop});
                case 3
                    if ~isempty(Loop.three),error('there can only be one structure assigned to loop 3'),end
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
            Loop.(i_loop_str).sweep = feval(Loop.(i_loop_str).type, ...
                Loop.(i_loop_str), obj.Instr, obj.inputStructure.ExpParams, sweepPtsOnly);
            Loop.(i_loop_str).steps = length(Loop.(i_loop_str).sweep.points);
            Loop.(i_loop_str).plotRange = Loop.(i_loop_str).sweep.points;
        end
    end
end