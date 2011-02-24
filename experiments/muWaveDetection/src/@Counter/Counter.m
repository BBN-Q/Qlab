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
        
        function reset(obj)
            obj.value = 1;
        end
        
        function increment(obj)
            obj.value = obj.value + 1;
        end
        
        function out = get.value(obj)
            out = obj.value;
        end
        
        function set.value(obj, value)
            obj.value = int32(value);
            
            % loop through uihandles and update them
            for h = obj.uihandles;
                if ishandle(h) && strcmp(get(h, 'Type'), 'uicontrol') && strcmp(get(h, 'Style'), 'edit')
                    set(h, 'String', sprintf('%03d', obj.value));
                else
                    % remove handle from list
                    obj.uihandles = setdiff(obj.uihandles, h);
                end
            end
        end
        
        function add_uihandle(obj, h)
            % add a uicontrol text box handle to the uihandles vector
            if ~ishandle(h)
                error('Counter:NOT_HANDLE', 'Input to add_uihandle is not a handle object');
            end
            obj.uihandles(length(obj.uihandles)+1) = h;
        end
    end
end