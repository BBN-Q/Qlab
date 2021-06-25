% CLASS GPIBorVISA - Provides interface to smartly choose GPIB or
% VISA connection based on the address string

% Original author: Blake Johnson

% Copyright 2013 Raytheon BBN Technologies
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

classdef GPIBorVISA < hgsetget
    
    properties (Access = protected)
        interface
        buffer_size = 1048576 % 1 MB buffer
    end

    properties (SetAccess=private)
        identity % standard *IDN? response
    end

    methods
        function connect(obj, address)
            % determine whether to use GPIB or VISA by the form of the
            % address
            ip_re = '\d+\.\d+\.\d+\.\d+';
            gpib_re = '^\d+$';
            % Recognize VISA addresses by the '::' separator
            if ischar(address) && ~isempty(strfind(address, '::'))
                % create a VISA object
                obj.interface = visa('ni', address);
            elseif ischar(address) && ~isempty(regexp(address, ip_re, 'once'))
                % Create a TCPIP object.
                obj.interface = visa('ni',strcat('TCPIP::',address,'::INSTR'));
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
        
        function write(obj, varargin)
            fprintf(obj.interface, sprintf(varargin{:}));
        end
        
        function val = query(obj, varargin)
            val = query(obj.interface, varargin{:});
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