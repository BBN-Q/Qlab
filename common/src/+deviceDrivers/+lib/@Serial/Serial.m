%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First author/Date : C.B. Lirakis / 2009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef Serial < deviceDrivers.lib.deviceDriverBase
    properties
        interface = []
        bufferSize = 64 
        baudRate = 115200
    end
  
    methods
        %%
        function connect(obj, address)
            %Create a Serial object
            %Handle a double call on connect
            if ~isempty(obj.interface)
                fclose(obj.interface);
                delete(obj.interface);
            end
                
            obj.interface = serial(address);
            obj.interface.InputBufferSize = obj.bufferSize;
            obj.interface.OutputBufferSize = obj.bufferSize;
            obj.interface.BaudRate = obj.baudRate;
            fopen(obj.interface);
        end

        function disconnect(obj)
            if ~isempty(obj.interface)
                flushoutput(obj.interface);
                fclose(obj.interface);
            end
        end

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
