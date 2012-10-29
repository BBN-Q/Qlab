classdef GPIBorEthernet < hgsetget
%     properties (Constant = true)
%        
%     end
    
    properties (Access = protected)
        interface
        buffer_size = 1048576 % 1 MB buffer
        DEFAULT_PORT = 5025; % for TCP/IP communication
    end
    methods
        function connect(obj, address)
            % determine whether to use GPIB or TCPIP by the form of the
            % address
            ip_re = '\d+\.\d+\.\d+\.\d+';
            gpib_re = '\d+';

            if ischar(address) && ~isempty(regexp(address, ip_re, 'once'))
                % Create a TCPIP object.
                obj.interface = tcpip(address, obj.DEFAULT_PORT);
            elseif ischar(address) && ~isempty(regexp(address, gpib_re, 'once'))
                % create a GPIB object
                obj.interface = gpib('ni', 0, str2double(address));
            elseif isnumeric(address)
                obj.interface = gpib('ni', 0, address);
            else
                error(['connect: Invalid address: ', address]);
            end
            
            obj.interface.InputBufferSize = obj.buffer_size;
            obj.interface.OutputBufferSize = obj.buffer_size;
            fopen(obj.interface);
        end
        
        function disconnect(obj)
            flushoutput(obj.interface);
            fclose(obj.interface);
            delete(obj.interface);
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