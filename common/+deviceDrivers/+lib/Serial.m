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
        DTR = 'off' % default to off for Arduinos
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
            obj.interface.DataTerminalReady = obj.DTR:
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
            if ~isempty(obj.interface)
                delete(obj.interface);
            end
        end
        
        function write(obj, string)
            fprintf(obj.interface, string);
            flushoutput(obj.interface);
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
    end
    
end
