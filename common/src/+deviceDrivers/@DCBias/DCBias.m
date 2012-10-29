%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : DCBias
%
% Author/Date : B.C Donovan 10/3/2010
%
% Description : Object to manage access to DC bias box.
%               Inherits from deviceDrivers.lib.Serial
%               Based on untested driver from C. Lirakis
%
% Restrictions/Limitations :
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%                BCD
%
% RCS header info.
% ----------------
% $RCSfile$
% $Author$
% $Date$
% $Locker$
% $Name$
% $Revision$
%
% $Log: $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef (Sealed) DCBias < deviceDrivers.lib.Serial
    properties
        %
        % It is a good idea to record the board serial numbers.
        BoardSerialNumbers;
        % Not sure what we need yet.
        % Probably want to have a description of what is hooked up
        % to each channel.
        
        ComPortName = '';
    end
    properties (Constant = true)
        MAX_CHANNELS  =  12;
        MAX_POT = 2;
        MAX_POT_VALUE = 1023;
        MAX_VALUE = 1e-3;  % maximum current value
        MIN_VALUE = -1e-3; % firmware does not support negative current
    end
    methods
        
        %%
        % Constructor ---------------------------------
        % must supply com port parameters such as name.
        % We may need to specify baud rate etc later.
        function obj = DCBias()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
            obj.Name = 'DCBias';
            % write and empty command at start to prevent
            % first command "huh" response to valid command
        end
        
        % setAll is called as part of the Experiment initialize instruments
        function setAll(obj,init_params)
            %             fs = fields(init_params);
            %             for i = 1:length(fs)
            %                 initStr = sprintf('obj.%s = init_params.%s;',fs{i},fs{i});
            %                 eval(initStr);
            %             end
            for i = 0:11
                chName = ['ch' num2str(i)];
                % if channel is 'on', set it
                if isfield(init_params, chName) && isfield(init_params, [chName 'on']) && init_params.([chName 'on']) && isnumeric(init_params.(chName))
                    % for now, hard code to set the coarse pot until
                    % setting currents works
                    obj.SetSinglePot(i, 0, init_params.(chName));
                end
            end
			
			% wait for channels to settle
			pause(.5);
        end
        
        %
        % Dump the properties of the DC Bias port. Debugging tool
        % Not needed for this class
        %
        % Dialog for configuring DC bias, including com port.
        %
        function Configure(obj)
            error('Not completed');
        end
        %
        % Write all parameters associated with com port to a config file
        %
        function SaveParameters(obj)
            error('Not completed');
        end
        %
        % Read back parameters from config file.
        %
        function LoadParameters(obj)
            error('Not completed');
        end
        
        function connect(obj,address)
            obj.connect@deviceDrivers.lib.Serial(address);
            obj.WriteAndRead(''); % clear input;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Module Name : SetSinglePot
        %
        % Author/Date : C.B. Lirakis / 27-May-09
        %
        % Description : Set the specified value on a specific pot. Note
        %   that the channel mapping is here in this code. The channel
        %   coming in ranges from 0-23. The pot ranges from 0-2 and is
        %   remappd appropriately. The value ranges from 0-1023.
        %
        %   If an OK is not detected from the Arduino, the command is
        %   resent.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [ReturnString] = SetSinglePot(obj,channel, pot, value)
            %
            % Input
            % Channel (0:23)
            % Pot (0:2) Coarse, Medium, Fine
            % Value (0:1023)
            % Channel is the channel under test.
            % Pot is 0 - Coarse, 1 - Medium, 2 - Fine setting
            obj.PendingArduino();
            ReturnString = 'none';
            
            % Test Input - If there is an error raise an error
            
            if (channel > obj.MAX_CHANNELS) || (channel < 0)
                MException('DCBias:SetSinglePot:BadInput', ...
                    'Channel number: %i is invalid',channel);
            end
            
            if (pot > obj.MAX_POT) || (pot < 0)
                MException('DCBias:SetSinglePot:BadInput', ...
                    'Pot number: %i is invalid',pot);
            end
            
            if (value > obj.MAX_POT_VALUE) || (value < 0)
                MException('DCBias:SetSinglePot:BadInput', ...
                    'Value number: %i is invalid',Value);
            end
            
            Repeat = true;
            RepeatCount = 0;
            
            warnStr = 'CMD: %s Response: %s\n';
            
            % Check to see if there is anything coming back at us.
            while (Repeat)
                cmd = sprintf('S %d %d %d;', channel, pot, value);
                ReturnString = obj.WriteAndRead(cmd);
                
                % Do some error checking here.
                if (length(ReturnString) < 2)
                    warning('DCBias:SetSinglePot:SetArduino_1', ...
                        warnStr, cmd, ReturnString);
                    Repeat = false;
                elseif (length(ReturnString) > 2)
                    warning('DCBias:SetSinglePot:SetArduino_2', ...
                        warnStr, cmd, ReturnString);
                    pause(1.0);
                elseif strcmp(ReturnString,'OK')
                    Repeat = false; % DONE
                else
                    warning('DCBias:SetSinglePot:InvalidCommand', ...
                        warnStr, cmd, ReturnString);
                    Repeat = false;
                end
                RepeatCount = RepeatCount + 1;
                if (RepeatCount > 3)
                    Repeat = false;
                end
            end
            if (obj.DebugLevel > 0)
                % used for debug purposes.
                warning('DCBias:SetSinglePot:Debug', ...
                    warnStr, cmd, ReturnString);
            end
        end % Set Single Pot method
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : ReadADC
        %
        % Description : Perform an ADC on a single DC bias channel.
        % Note this is about a 200ms conversion time.
        %
        % Inputs : channel to acquire data from.
        %
        % Returns : ADC value or NaN on error.
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on: 13-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [ADCValue] = ReadADC(obj,channel)
            %% Get the ADC Data
            obj.PendingArduino();   % Trash any read data in the buffer.
            %
            ADCValue = NaN;
            
            if (channel > obj.MAX_CHANNELS) || (channel < 0)
                MException('DCBias:SetSinglePot:BadInput', ...
                    'Channel number: %i is invalid',channel);
            end
            
            cmd = sprintf('A %d;', channel);
            ADCValueString = obj.WriteAndRead(cmd);
            
            % Should be followed by an OK.
            StatusString = obj.ReadRetry();
            if ~strcmp(StatusString,'OK')
                keyboard
                warning('DCBias:ReadADC:ArduinoError', ...
                    'Did not receive expected OK');
                return
            end
            ADCValue = str2double(ADCValueString);
            if (obj.DebugLevel>0)
                dgbStr = 'DEBUG(ReadADC): CMD: %s ADCValue: %s Status: %s\n';
                fprintf(dgbStr, cmd, ADCValueString, StatusString);
            end
        end % Method read ADC.
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : ZeroAll
        %
        % Description : Set all channels to zero current.
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
        function ZeroAll(obj)
            obj.PendingArduino();   % Trash any read data in the buffer.
            rv = obj.WriteAndRead('Z;');
            if (obj.DebugLevel>0)
                fprintf('DEBUG(ZeroAll): CMD: Z; Status: %s\n', cmd, rv);
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : SetCurrent
        %
        % Description :  Set the current on a specific channel.
        %
        % Inputs : channel number
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
        function ret = SetCurrent(obj,channel,value)
            if (channel > obj.MAX_CHANNELS) || (channel < 0)
                MException('DCBias:SetCurrent:BadInput', ...
                    'Channel number: %i is invalid',channel);
            end
            
            if (value > obj.MAX_VALUE) || (value < obj.MIN_VALUE)
                MException('DCBias:SetCurrent:BadInput', ...
                    'Value number: %i is invalid',Value);
            end
            obj.PendingArduino();
            cmd = sprintf('I %01d %g;', channel, value);
            rc = obj.WriteAndRead(cmd);
            if ~strcmp(rc,'OK')
                fprintf('rc = %s',rc);
                ret = -1;
            else
                ret = 0;
            end
        end % Method Set current
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fuction Name: GetCurrent
        %
        % Description: Get's current value using on board ADC
        %
        % Input: channel = 0 based channel number
        %
        % Output: current value as double, NaN on error
        
        function [val] = GetCurrent(obj,channel)
            cmd = sprintf('G %i\n', channel);
            val = obj.WriteAndRead(cmd);
            if ~isempty(val)
                val = str2num(val);
            else
                val = NaN;
            end
            
            rc = obj.ReadRetry();
            if ~strcmp(rc,'OK')
                keyboard
                warning('DCBias:PendingArduino:GetCurrent','Did not receive expected OK');
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fuction Name: SetCalibrationData
        %
        % Description: Programs calibration data into arduino flash
        %
        % Input: calType = 'ADC','C','M','F'
        %        channel = 0 based channel number
        %        poly = order 1 poly fit
        %
        % Output: 0 - on success, -1 on error
        
        function rc = SetCalibrationData(obj,calType, channel, poly, pot_max_i, pot_min_i)
            rc1 = 'OK';
            rc2 = 'OK';
            rc3 = 'OK';
            rc4 = 'OK';
            if strcmp(calType,'ADC')
                % load ADC slope and intercept
                % note pot is ignore by ardunio but is still expected
                % so we give it a bogus value
                cmd = sprintf('CD %i 0 %g\n', channel, poly(1));
                rc1 = obj.WriteAndRead(cmd);
                cmd = sprintf('CJ %i 0 %g\n', channel, poly(2));
                rc2 = obj.WriteAndRead(cmd);
            else
                switch calType
                    case 'C'
                        % load course slope and overall current intercept
                        pot = 0;
                    case 'M';
                        % load medium slope only
                        pot = 1;
                    case 'F'
                        pot = 2;
                end % switch
                cmd = sprintf('CP %i %i %g\n', channel, pot, poly(1));
                rc1 = obj.WriteAndRead(cmd);
                if pot == 0
                    cmd = sprintf('CI %i %i %g\n', channel, pot, poly(2));
                    rc2 = obj.WriteAndRead(cmd);
                end
                cmd = sprintf('CA %i %i %g\n', channel, pot, pot_max_i);
                rc3 = obj.WriteAndRead(cmd);
                cmd = sprintf('CB %i %i %g\n', channel, pot, pot_min_i);
                rc4 = obj.WriteAndRead(cmd);
            end % if
            % assume things worked
            rc = 0;
            
            % bit mapped error
            if ~strcmp(rc1,'OK')
                rc = rc + 1;
            end
            if ~strcmp(rc2,'OK')
                rc = rc + 2;
            end
            if ~strcmp(rc3,'OK')
                rc = rc + 4;
            end
            if ~strcmp(rc4,'OK')
                rc = rc + 8;
            end
            rc = -1 * rc;   % convert rc to negative
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fuction Name: GetCalibrationData
        %
        % Description: Programs calibration data into arduino flash
        %
        % Input: calType = 'ADC','C','M','F'
        %        channel = 0 based channel number
        %        poly = order 1 poly fit
        %
        % Output: 0 - on success, -1 on error
        
        function [poly] = GetCalibrationData(obj,calType, channel)
            rc1 = 'OK';
            rc2 = 'OK';
            
            
            if strcmp(calType,'ADC')
                % load ADC slope and intercept
                % note pot is ignore by ardunio but is still expected
                % so we give it a bogus value
                cmd = sprintf('BD %i 0\n', channel);
                poly.slope = str2double(obj.WriteAndRead(cmd));
                
                rc = obj.ReadRetry(); % get OK
                cmd = sprintf('BJ %i 0\n', channel);
                poly.intercept = str2double(obj.WriteAndRead(cmd));
                rc = obj.ReadRetry(); % get OK
            else
                switch calType
                    case 'C'
                        pot = 0;
                        
                    case 'M';
                        pot = 1;
                    case 'F'
                        pot = 2;
                end % switch
                % load course slope and overall current intercept
                cmd = sprintf('BP %i %i\n', channel,pot);
                poly.slope= str2double(obj.WriteAndRead(cmd));
                rc = obj.ReadRetry(); % get OK
                if pot == 0
                    cmd = sprintf('BI %i %i\n', channel,pot);
                    poly.intercept = str2double(obj.WriteAndRead(cmd));
                    rc = obj.ReadRetry(); % get OK
                end
                cmd = sprintf('BA %i %i\n', channel,pot);
                poly.max = str2double(obj.WriteAndRead(cmd));
                rc = obj.ReadRetry(); % get OK
                cmd = sprintf('BB %i %i\n', channel,pot);
                poly.min = str2double(obj.WriteAndRead(cmd));
                rc = obj.ReadRetry(); % get OK
            end
            % assume things worked
            rc = 0;
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : LogData
        %
        % Description : Acquire and log data associated with this
        % instrument. In this case, loop over all the ADCs
        % and log their settings.
        %
        % Inputs : fid - file descriptor associated with a log file.
        %          NChannels - number of channels to read.
        %
        % Returns : false on failure
        %
        % Error Conditions :
        %      0 SUCCESS!
        %     -3 no FID available
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rc = LogData(obj, logFid,NChannels)
            
            if NChannels > MAX_CHANNEL
                MException('DCBias:SetCurrent:BadInput', ...
                    'Number of channels: %i is invalid',NChannels);
            end
            
            fprintf( logFid, '%s %f ', obj.Name, now);
            
            % Loop over all channels and get the data.
            % log channel too so we can modify which channels are
            % written in the future
            for channel=0:NChannels
                data = obj.ReadADC(channel);
                fprintf( logFid, '%d %f ', channel, data);
            end
            fprintf ( logFid, '\n');
        end % method Log data.
    end % Methods
    
    methods (Static)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : ParseLine
        %
        % Description : Assume somewhere else that the user
        % has opened a data file and is parsing out strings.
        % Additionally, that the line has already been determined
        % to be a DC bias data format.
        %
        % Inputs : line to parse.
        %
        % Returns : Parsed data. Structure
        %         NumberChannels - Number of channels read. Data
        %                          stored in array as shown.
        %         Value[i].channel - Channel number associated with data
        %         Value[i].current - Current found on channel
        %
        % Error Conditions :
        %      0 SUCCESS!
        %     -4 Error parsing data.
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function Data = ParseLine(obj,line)
            Data.NumberChannels = 0;
            % note that while obj is an argument, it doesn't count against
            % nargin
            if ~exist('line','var')
                LastError = -3;
                return;
            end
            count = 1;
            if ~isempty(line)
                linedat = strread(line,'%s');
                if (length(linedat) <= 1)
                    LastError = -4;  % no real data to parse.
                    return;
                end
                if strcmp(linedat(1), 'DCBias')
                    % Get the time
                    Data.time = linedat(2);
                    Data.NumberChannels = (length(linedat)-2)/2;
                    index = 3;
                    for i=1:Data.NumberChannels
                        Data(i).channel = linedat(index); index = index+1;
                        Data(i).value   = linedat(index); index = index+1;
                        count = count+1;
                    end
                end
            end
        end % ParseLine
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : ParseLogFile
        %
        % Description : Return an array of all data points of the type
        % DCBias from the logfile pointed to by fid.
        %
        % Inputs : fid - legitimate file pointer
        %
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on: 14-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function Data = ParseLogFile(obj,fid)
            if nargin == 0
                LastError = -3;
                Data.Lines = 0;
                return;
            end
            % Rewind the file.
            fseek( fid, 0, 'bof');
            line = fgetl(fid); % returns the next line of a file associated with file
            % identifier FID as a MATLAB string
        end % Method ParseLogFile
    end % Static Methods
end % Class