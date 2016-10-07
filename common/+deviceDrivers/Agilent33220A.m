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

    properties (Access = public)
        outputLoad      % output impedance (1 - 1e-4 Ohms)
        triggerSource   % {IMMediate|EXTernal|BUS}
        numCycles       % for use in burst mode
        burstMode       % {TRIGgered|GATed}
        burstState      % {ON|OFF}
        offset          % in Volts
        high            % high voltage
        low             % low voltage
        period          % in seconds
        output          % output state
        voltage         % voltage amplitude
        outputFunction  % output type
        frequency       % output freq  
    end

    methods
        function reset(obj)
            %RESET
            obj.write('*RST');
            pause(3)
        end

        function trigger(obj)
            obj.write('*TRG');
        end
        
        %%getters
        function val = get.outputLoad(obj)
            temp = obj.query('OUTPut:LOAD?');
            val = str2double(temp);
        end
        function val = get.triggerSource(obj)
            val = obj.query('TRIGger:SOURce?');
        end
        function val = get.numCycles(obj)
            temp = obj.query('BURSt:NCYCles?');
            val = str2double(temp);
        end
        function val = get.burstMode(obj)
            val = obj.query('BURSt:MODE?');
        end
        function val = get.burstState(obj)
            val = obj.query('BURSt:STATE?');
        end
        function val = get.offset(obj)
            temp = obj.query('VOLT:OFFSET?');
            val = str2double(temp);
        end
        function val = get.high(obj)
            temp = obj.query('VOLT:HIGH?');
            val = str2double(temp);
        end
        function val = get.low(obj)
            temp = obj.query('VOLT:LOW?');
            val = str2double(temp);
        end
        function val = get.period(obj)
            temp = obj.query('PULSE:PERIOD?');
            val = str2double(temp);
        end
        function val = get.output(obj)
            temp = obj.query('OUTPut?');
            val = str2double(temp);
        end
        function val = get.voltage(obj)
            temp = obj.query('VOLTage?');
            val = str2double(temp);
        end
        function val = get.frequency(obj)   
            temp = obj.query('FREQuency?');
            val = str2double(temp);
        end
        function val = get.outputFunction(obj)
            val = obj.query('FUNCtion?');
        end
        
        %%setters
        function obj = set.outputLoad(obj, value)
            obj.write(['OUTPut:LOAD ' num2str(value)]);
        end
        function obj = set.burstMode(obj, value)
            % Validate input
            % {TRIGgered|GATed}
            checkMapObj = containers.Map({'TRIGgered','TRIGGERED','triggered'...
                ,'TRIG','GATed','GATED','gated','GAT'},...
                {'TRIG','TRIG','TRIG','TRIG',...
                'GAT','GAT','GAT','GAT'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            obj.write(['BURSt:MODE ' checkMapObj(value)]);
        end
        function obj = set.triggerSource(obj, value)
            % Validate input
            % {IMMediate|EXTernal|BUS}
            checkMapObj = containers.Map({'IMMediate','IMMEDIATE','immediate','IMM'...
                ,'EXTernal','EXTERNAL','external','EXT','BUS','bus'},...
                {'IMM','IMM','IMM','IMM','EXT','EXT','EXT','EXT',...
                'BUS','BUS'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            obj.write(['TRIGger:SOURce ' checkMapObj(value)]);
        end
        function obj = set.numCycles(obj, value)
            obj.write(['BURSt:NCYCles ' num2str(value)]);
        end
        function obj = set.burstState(obj, value)
            % Validate input
            % {ON|OFF}
            checkMapObj = containers.Map({'on','off'}, {'ON','OFF'});
            if not (checkMapObj.isKey(lower(value)))
                error('Invalid input');
            end
            obj.write(['BURSt:STATE ' checkMapObj(lower(value))]);
        end
        function obj = set.offset(obj, value)
            if isnumeric(value)
                obj.write(sprintf('VOLT:OFFSET %f', value));
            else
                value = validatestring(value, {'MIN', 'MAX'});
                obj.write(sprintf('VOLT:OFFSET %s', value))
            end
        end
        function obj = set.high(obj, high)
            obj.write(['VOLT:HIGH ' num2str(high)]);
        end
        function obj = set.low(obj, low)
            obj.write(['VOLT:LOW ' num2str(low)]);
        end
        function obj = set.period(obj, value)
            obj.write(['PULSE:PERIOD ' num2str(value)]);
        end
        function obj = set.output(obj, value)
            if islogical(value) || isnumeric(value)
                if value
                    value = 'ON';
                else
                    value = 'OFF';
                end
            else
                value = validatestring(value, {'ON', 'OFF'});
            end
            obj.write(sprintf('OUTPut %s', value))
        end
        function obj = set.voltage(obj, value)
            if isnumeric(value)
                obj.write(sprintf('VOLTage %f', value))
            else 
                value = validatestring(value, {'MIN', 'MAX'});
                obj.write(sprintf('VOLTage %s', value))
            end
        end
        function obj = set.frequency(obj, value)
            if isnumeric(value)
                obj.write(sprintf('FREQuency %f', value));
            else
                value = validatestring(value, {'MIN', 'MAX'});
                obj.write(sprintf('VOLTage %s', value))
            end
        end
        function obj = set.outputFunction(obj, value)
            value = validatestring(value, {'SIN', 'SQU', 'RAMP', 'PULS', ...
                'NOISE', 'DC', 'USER'});
            obj.write(sprintf('FUNCtion %s', value))
        end
        
        
    end
end
