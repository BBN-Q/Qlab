% CLASS GPIBorEthernet - Provides interface to smartly choose GPIB or
% Ethernet connection based on the address string

% Original author: Blake Johnson

% Copyright 2012 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef GPIBorEthernet < hgsetget
    
    properties (Access = protected)
        interface
        buffer_size = 1048576 % 1 MB buffer
        DEFAULT_PORT = 5025; % for TCP/IP communication
    end
    
    properties (SetAccess=private)
        identity % standard *IDN? response
        isConnected
    end

    methods
        function delete(obj)
            if obj.isConnected
                obj.disconnect();
            end
        end
        
        function connect(obj, address)
            % determine whether to use GPIB or TCPIP by the form of the
            % address
            if ~obj.isConnected
                ip_re = '\d+\.\d+\.\d+\.\d+';
                gpib_re = '^\d+$';

                if ischar(address) && ~isempty(regexp(address, ip_re, 'once'))
                    % Create a TCPIP object.
                    obj.interface = tcpip(address, obj.DEFAULT_PORT);
                elseif ischar(address) && ~isempty(regexp(address, gpib_re, 'once'))
                    % create a GPIB object
                    obj.interface = gpib('ni', 0, str2double(address));
                elseif isnumeric(address)
                    obj.interface = gpib('ni', 0, address);
                else % Probably a hostname
                    obj.interface = tcpip(address, obj.DEFAULT_PORT);
                end

                obj.interface.InputBufferSize = obj.buffer_size;
                obj.interface.OutputBufferSize = obj.buffer_size;
                fopen(obj.interface);
            end
        end
        
        function disconnect(obj)
            if ~isempty(obj.interface)
              flushoutput(obj.interface);
              flushinput(obj.interface);              
              fclose(obj.interface);
              delete(obj.interface);
              obj.interface = [];
            end
        end
        
        function val = get.isConnected(obj)
            val = ~isempty(obj.interface) && strcmp(obj.interface.Status, 'open');
        end
        
        function write(obj, varargin)
            fprintf(obj.interface, sprintf(varargin{:}));
        end
        
        function val = query(obj, string)
            val = strtrim(query(obj.interface, string));
        end
        
        function val = read(obj)
            val = fgetl(obj.interface);
        end
        
        %typically available SCPI commands
        function val = get.identity(obj)
            val = obj.query('*IDN?');
        end
        function reset(obj)
            obj.write('*RST');
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