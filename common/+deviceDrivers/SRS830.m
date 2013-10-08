% CLASS SRS830 - Instrument driver for the SRS 830 lock-in

% Author: Colm Ryan (colm.ryan@bbn.com)

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

classdef (Sealed) SRS830 < deviceDrivers.lib.GPIB
    
    properties
        timeConstant % time constant for the filter in seconds
        inputCoupling % 'AC' or 'DC'
    end

    properties (SetAccess=private)
        R % read magnitude of signal
        theta % read angle of signal
        X % read X value of signal
        Y % read Y value of signal
    end

    properties(Constant)
        timeConstantMap = containers.Map(num2cell(0:19), num2cell(kron(10.^(-6:3), [10, 30])));
        inputCouplingMap = containers.Map({'AC', 'DC'}, {uint32(0), uint32(1)});
    end
    
    methods
        
        %Filter time constant
        function val = get.timeConstant(obj)
            val = obj.timeConstantMap(uint32(str2double(obj.query('OFLT?'))));
        end
        function obj = set.timeConstant(obj, value)
            inverseMap = invertMap(obj.timeConstantMap);
            mapKeys = keys(inverseMap);
            [~, index] = min(abs(value - cell2mat(mapKeys)));
            obj.write(sprintf('OFLT %d', inverseMap(mapKeys{index})));
        end
        
        %Input coupling
         function val = get.inputCoupling(obj)
            inverseMap = invertMap(obj.inputCouplingMap);
            val = inverseMap(uint32(obj.query('ICPL?')));
        end
        function obj = set.inputCoupling(obj, value)
            assert(isKey(obj.inputCouplingMap, value), 'Oops! the input coupling must be one of "AC" or "DC"');
            obj.write(sprintf('ICPL %d', obj.inputCouplingMap(value)));
        end
        
        %Getter for the current signal level in any flavour
        function [X, Y, R, theta] = get_signal(obj)
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            X = values{1}(1);
            Y = values{1}(2);
            R = values{1}(3);
            theta = values{1}(4);
        end
        
        %Getter for signal magnitude
        function R = get.R(obj)
            R = str2double(obj.query('OUTP ? 3'));
        end
        
        %Getter for signal angle
        function theta = get.theta(obj)
            theta = str2double(obj.query('OUTP ? 4'));
        end
        
        %Getter for signal X
        function X = get.X(obj)
            X = str2double(obj.query('OUTP ? 1'));
        end
        
        %Getter for signal Y
        function Y = get.Y(obj)
            Y = str2double(obj.query('OUTP ? 2'));
        end

        function auto_phase(obj)
            obj.write('APHS');
        end
        
    end
    
end

