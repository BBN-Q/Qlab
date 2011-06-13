%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : DigitalAttenuator
%
% Author/Date : Blake R. Johnson 6/10/2011
%
% Description : Object to manage access to the digital attenuator.
%               Inherits from deviceDrivers.lib.Serial. Borrows some code
%               from DCBias driver.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef (Sealed) DigitalAttenuator < deviceDrivers.lib.Serial
    properties
        ComPortName = '';
        serial = 0;
    end
    properties (Constant = true)
        MAX_CHANNELS  =  3;
        MAX_VALUE = 31.5;  % maximum attenuation value
        MIN_VALUE = 0; % minimum attenuation value
    end
    methods
        
        %%
        % Constructor ---------------------------------
        % must supply com port parameters such as name.
        % We may need to specify baud rate etc later.
        function obj = DigitalAttenuator()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
            obj.Name = 'DigitalAttenuator';
            % write an empty command at start to prevent
            % first command "huh" response to valid command
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
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on: 13-Jul-09
        %
        % Unit Tested by: CBL
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