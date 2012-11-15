%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First author/Date : C.B. Lirakis / 17-Jul-09
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef GPIB < deviceDrivers.lib.deviceDriverBase
    properties
        interface = []
        buffer_size = 1048576 % 1 MB buffer
    end
  
    methods
        %%
        function connect(obj, address)
            if ischar(address)
                address = str2double(address);
            end
            
            % create a GPIB object
            if ~isempty(obj.interface)
                fclose(obj.interface);
                delete(obj.interface);
            end
                
            obj.interface = gpib('ni', 0, address);
            obj.interface.InputBufferSize = obj.buffer_size;
            obj.interface.OutputBufferSize = obj.buffer_size;
            fopen(obj.interface);
        end

        function disconnect(obj)
            flushoutput(obj.interface);
            fclose(obj.interface);
        end
        %%
        % Destructor method
        %
        function delete(obj)
            obj.disconnect();
        end
        
        function write(obj, string)
            fprintf(obj.interface, string);
        end
        
        function val = query(obj, string)
            val = query(obj.interface, string);
        end
        
        function val = read(obj)
            val = fgetl(obj.interface);
        end
        
        % binary read/write functions
        function binblockwrite(obj, varargin)
            binblockwrite(obj.interface, varargin{:});
        end
        
        function val = binblockread(obj, varargin)
            val = binblockread(obj.interface, varargin{:});
        end
        
        % instrument meta-setter
        function setAll(obj, settings)
            fields = fieldnames(settings);
            for j = 1:length(fields);
                name = fields{j};
                if ismember(name, methods(obj))
                    feval(['obj.' name], settings.(name));
                elseif ismember(name, properties(obj))
                    obj.(name) = settings.(name);
                end
            end
        end
    end
    
end
