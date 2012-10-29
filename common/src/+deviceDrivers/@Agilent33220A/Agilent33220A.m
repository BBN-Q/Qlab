% Driver for Agilent 33220A function generator

% Original author: Will Kelly
% Updated by: Blake Johnson on 10/4/12

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

classdef (Sealed) Agilent33220A < deviceDrivers.lib.GPIBorEthernet

    % Device properties correspond to instrument parameters
    properties (Access = public)
        identity;
        outputLoad      % output impedance (1 - 1e-4 Ohms)
        triggerSource   % {IMMediate|EXTernal|BUS}
        samplingRate    % in Samp/sec
        waveformDuration % in seconds
        numWaveforms    % for use in burst mode
        burstMode       % {TRIGgered|GATed}
        burstState      % {ON|OFF}
        offset          % in Volts
        period          % in seconds
    end % end device properties
 
        
    methods (Access = public)
        function obj = Agilent33220A()
        end
        function reset(obj)
            %RESET
            gpib_string = '*RST';
            obj.write(gpib_string);
            pause(3)
        end
        function trigger(obj)
            gpib_string = '*TRG';
            obj.write(gpib_string);
        end
    end
    methods % Instrument parameter accessors
        %% get
        function val = get.identity(obj)
            gpib_string = '*IDN';
            val = obj.query([gpib_string '?']);
        end
        function val = get.outputLoad(obj)
            gpib_string = 'OUTPut:LOAD';
            temp = obj.query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.triggerSource(obj)
            gpib_string = 'TRIGger:SOURce';
            val = obj.query([gpib_string '?']);
        end
        function val = get.samplingRate(obj)
            val = obj.samplingRate;
        end
        function val = get.waveformDuration(obj)
            val = obj.waveformDuration;
        end
        function val = get.numWaveforms(obj)
            gpib_string = 'BURSt:NCYCles';
            temp = obj.query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.burstMode(obj)
            gpib_string = 'BURSt:MODE';
            val = obj.query([gpib_string '?']);
        end
        function val = get.burstState(obj)
            gpib_string = 'BURSt:STATE';
            val = obj.query([gpib_string '?']);
        end
        function val = get.offset(obj)
            gpib_string = 'VOLT:OFFSET';
            temp = obj.query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.period(obj)
            gpib_string = 'PULSE:PERIOD?';
            temp = obj.query(gpib_string);
            val = str2double(temp);
        end
        %% set
%         function obj = set.trigger_slope(obj, value)
%             gpib_string = 'TRIGger:MAIn:EDGE:SLOpe';
%             % Validate input
%             checkMapObj = containers.Map({'RISE','rise','Rise','FALL','fall','Fall'},...
%                 {'rise','rise','rise','fall','fall','fall'});
%             if not (checkMapObj.isKey(value))
%                 error('Invalid input');
%             end
%             gpib_string = [gpib_string ' ' checkMapObj(value)];
%             obj.write(gpib_string);
%         end
        function obj = set.outputLoad(obj, value)
            gpib_string = 'OUTPut:LOAD';
            % Validate input
            if ~(isnumeric(value) && isscalar(value))
                error('value must be a numeric scalar')
            else
                valueStr = num2str(value);
            end
            gpib_string = [gpib_string ' ' valueStr];
            obj.write(gpib_string);
        end
        function obj = set.burstMode(obj, value)
            gpib_string = 'BURSt:MODE';
            % Validate input
            % {TRIGgered|GATed}
            checkMapObj = containers.Map({'TRIGgered','TRIGGERED','triggered'...
                ,'TRIG','GATed','GATED','gated','GAT'},...
                {'TRIG','TRIG','TRIG','TRIG',...
                'GAT','GAT','GAT','GAT'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.write(gpib_string);
        end
        function obj = set.triggerSource(obj, value)
            gpib_string = 'TRIGger:SOURce';
            % Validate input
            % {IMMediate|EXTernal|BUS}
            checkMapObj = containers.Map({'IMMediate','IMMEDIATE','immediate','IMM'...
                ,'EXTernal','EXTERNAL','external','EXT','BUS','bus'},...
                {'IMM','IMM','IMM','IMM','EXT','EXT','EXT','EXT',...
                'BUS','BUS'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.write(gpib_string);
        end
        function obj = set.samplingRate(obj, value)
            if ~(isnumeric(value) && isscalar(value))
                error('value must be a numeric scalar')
            else
                obj.samplingRate = value;
            end
        end
        function obj = set.waveformDuration(obj, value)
            if ~(isnumeric(value) && isscalar(value))
                error('value must be a numeric scalar')
            else
                obj.waveformDuration = value;
            end
        end
        function obj = set.numWaveforms(obj, value)
            gpib_string = 'BURSt:NCYCles';
            % Validate input
            if ~(isnumeric(value) && isscalar(value))
                error('value must be a numeric scalar')
            else
                valueStr = num2str(value);
            end
            gpib_string = [gpib_string ' ' valueStr];
            obj.write(gpib_string);
        end
        function obj = set.burstState(obj, value)
            gpib_string = 'BURSt:STATE';
            % Validate input
            % {ON|OFF}
            checkMapObj = containers.Map({'ON','On','on'...
                ,'OFF','Off','off'},...
                {'ON','ON','ON','OFF','OFF','OFF',});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.write(gpib_string);
        end
        function obj = set.offset(obj, value)
            gpib_string = 'VOLT:OFFSET';
            % Validate input
            if ~(isnumeric(value) && isscalar(value))
                error('value must be a numeric scalar')
            else
                valueStr = num2str(value);
            end
            gpib_string = [gpib_string ' ' valueStr];
            obj.write(gpib_string);
        end
        function obj = set.period(obj, value)
            gpib_string = 'PULSE:PERIOD';
            % validate input
            if ~(isnumeric(value) && isscalar(value))
                error('value must be a numeric scalar')
            else
                valueStr = num2str(value);
            end
            gpib_string = [gpib_string ' ' valueStr];
            obj.write(gpib_string);
        end
    end
end % end class definition
