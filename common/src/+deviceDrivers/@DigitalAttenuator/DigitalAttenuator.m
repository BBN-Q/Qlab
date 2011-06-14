%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : DigitalAttenuator
%
% Author/Date : Blake R. Johnson 6/10/2011
%
% Description : Object to manage access to the BBN digital attenuator.
%               Inherits from deviceDrivers.lib.Serial. Borrows some code
%               from DCBias driver.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Copyright 2010 Raytheon BBN Technologies
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

classdef (Sealed) DigitalAttenuator < deviceDrivers.lib.Serial
    properties
        ComPortName = '';
        serial = 0; % ID of the device to distinguish multiple instances
    end
    properties (Constant = true)
        MAX_CHANNELS  =  3;
        MAX_VALUE = 31.5;  % maximum attenuation value
        MIN_VALUE = 0; % minimum attenuation value
    end
    methods
        
        %%
        % Constructor ---------------------------------
        function obj = DigitalAttenuator()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
            obj.Name = 'DigitalAttenuator';
        end
        
        % setAll is called as part of the Experiment initialize instruments
        function setAll(obj,init_params)
        end
        
        function connect(obj,address)
            obj.connect@deviceDrivers.lib.Serial(address);
        end
        
        % Function ReadUntilEND
        % Reads from the Arduino until it receives 'END'
        function out = ReadUntilEND(obj)
            out = '';
            val = obj.ReadRetry();
            while (strcmp(val, 'END') == 0)
                out = [out val];
                val = obj.ReadRetry();
            end
        end
        
        % poll device for its serial number
        function val = get.serial(obj)
            obj.Write('ID?;');
            val = obj.ReadUntilEND();
            val = str2double(val);
            obj.serial = val;
        end
        
        function setAttenuation(obj, channel, value)
            % error check inputs
            if (channel < 1 || channel > obj.MAX_CHANNELS)
                error('DigitalAttenuator:setAttenuation:channel', 'Invalid channel number %d', channel);
            end
            if (value < obj.MIN_VALUE)
                value = obj.MIN_VALUE;
            end
            if (value > obj.MAX_VALUE)
                value = obj.MAX_VALUE;
            end
            
            cmd = sprintf('SET %d %.1f', [channel value]);
            %fprintf([cmd '\n']);
            obj.Write(cmd);
            msg = obj.ReadUntilEND();
            %fprintf([msg '\n']);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : ZeroAll
        %
        % Description : Set all channels to zero attenuation.
        %
        % Inputs : None
        %
        % Returns : None
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function ZeroAll(obj)
            for channel=1:obj.MAX_CHANNEL
                obj.setAttenuation(channel, 0);
            end
        end % Method zero all.
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : PendingArduino
        %
        % Description : Clear all Arduino output that we haven't accounted
        %               for
        %
        % Inputs : None
        %
        % Returns : None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function PendingArduino(obj)
            if ( obj.FileDescriptor.BytesAvailable > 0)
                rv = obj.Read();
                if (~isempty(rv))
                    warning('DCBias:PendingArduino:Data','%s\n', rv);
                end
            end
        end % Method Pending Arduino
        

    end % Methods
    
end % Class