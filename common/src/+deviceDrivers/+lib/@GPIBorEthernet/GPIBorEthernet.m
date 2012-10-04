classdef GPIBorEthernet < hgsetget
    properties (Access = protected)
        interface
        buffer_size = 1048576 % 1 MB buffer
    end
    methods
        function connect(obj, address)
            % determine whether to use GPIB or TCPIP by the form of the
            % address
            ip_re = '\d+\.\d+\.\d+\.\d+';
            gpib_re = '\d+';

            if ischar(address) && ~isempty(regexp(address, ip_re, 'once'))
                % Create a TCPIP object.
                obj.interface = tcpip(address, obj.DEFAULT_SOCKET);
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
        
        function Write(obj, string)
            fprintf(obj.interface, string);
        end
        
        function val = Query(obj, string)
            val = query(obj.interface, string);
        end
        
        function val = Read(obj)
            val = fgets(obj.interface);
        end
    end
end