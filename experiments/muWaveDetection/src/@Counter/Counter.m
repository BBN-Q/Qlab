classdef Counter < handle
    properties
        value
        uihandles
    end
    methods
        function obj = Counter(initial_value)
            if nargin < 1
                initial_value = 1;
            end
            
            obj.value = initial_value;
        end
        
        function reset(obj, data_path)
            % if the current data path is not empty, reset the counter to
            % one more than the highest value file name in the path
            newval = 0;
            if ~strcmp(data_path, '')
                %Get the list of current output files
                file_list = dir([data_path filesep '*.h5']);
                % pull out the number from ###_device_experiment.out
                tokens = regexp({file_list.name}, '(\d+)_.*\.h5', 'tokens', 'once');
                if ~isempty(tokens)
                    expNums = cellfun(@str2double, tokens);
                    newval = max(expNums);
                end
            end
            obj.value = newval+1;
        end
        
        function increment(obj)
            obj.value = obj.value + 1;
        end
        
        function out = get.value(obj)
            out = obj.value;
        end
        
        function set.value(obj, value)
            obj.value = int32(value);
            %Broadcast the notification that we've changed
            notify(obj, 'valueChanged')
        end
        
    end
    
    events
        valueChanged
    end
    
end