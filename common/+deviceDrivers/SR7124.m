% CLASS SR7124 - Instrument driver for the Signal Recovery 7124 lock-in

% Original Author for SR830: Colm Ryan (colm.ryan@bbn.com)
% Editor for SR7124: Evan Walsh (evanwalsh@seas.harvard.edu)

% Copyright 2015 Raytheon BBN Technologies
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

classdef (Sealed) SR7124 < deviceDrivers.lib.GPIBorEthernet
    
    properties
        timeConstant % time constant for the filter in seconds
        sineAmp % output amplitude of the sin output (0.004 to 5.000V)
        sineFreq % reference frequency (Hz)
        Name
    end

    properties (SetAccess=private)
        R % read magnitude of signal
        TH % read angle of signal
        X % read X value of signal
        Y % read Y value of signal
    end

    properties(Constant)
        timeConstantMap = containers.Map(num2cell(0:32), num2cell(kron(10.^(-5:5), [1, 2, 5])));
    end
    
    methods
        function obj = SR7124()
        end
        
        %Filter time constant
        function val = get.timeConstant(obj)
            fprintf(obj.interface,'TC.');
            val = str2double(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        function obj = set.timeConstant(obj, value)
            %STILL HAS A BUG, NEEDS SOME WORK
            inverseMap = invertMap(obj.timeConstantMap);
            mapKeys = keys(inverseMap);
            [~, index] = min(abs(value - cell2mat(mapKeys)));
            fprintf(obj.interface,'TC %d', inverseMap(mapKeys{index}));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        
        %Reference frequency
        function val = get.sineFreq(obj)
            fprintf(obj.interface,'OF.');
            val = str2double(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        function obj = set.sineFreq(obj, value)
            assert(isnumeric(value) && (value >= 0.000) && (value <= 150000), 'Oops! The reference frequency must be between 1 mHz and 2 MHz');
            fprintf(obj.interface,'OF %E',value);
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        %Sine output amplitude
         function val = get.sineAmp(obj)
            fprintf(obj.interface,'OA.');
            val = str2double(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        function obj = set.sineAmp(obj, value)
            assert(isnumeric(value) && (value >= 0) && (value <= 5), 'Oops! The reference frequency must be between 1 mHz and 2 MHz');
            fprintf(obj.interface,'OA %E',value);
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        
        %Getter for X and Y at the same point in time
        function [X, Y] = get_XY(obj)
            fprintf(obj.interface,'XY.');
            values = str2num(fscanf(obj.interface));
            X = values(1,1);
            Y = values(1,2);
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        %Getter for R and theta at the same point in time
        function [R, TH] = get_RTH(obj)
            fprintf(obj.interface,'MP.');
            values = str2num(fscanf(obj.interface));
            R = values(1,1);
            TH = values(1,2);
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        
        %Getter for signal magnitude
        function R = get.R(obj)
            fprintf(obj.interface,'MAG.');
            R = str2num(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        %Getter for signal angle
        function TH = get.TH(obj)
            fprintf(obj.interface,'PHA.');
            TH = str2num(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        %Getter for signal X
        function X = get.X(obj)
            fprintf(obj.interface,'X.');
            X = str2num(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end
        
        %Getter for signal Y
        function Y = get.Y(obj)
            fprintf(obj.interface,'Y.');
            Y = str2num(fscanf(obj.interface));
            flushinput(obj.interface); %Required because Matlab can't handle 3 terminator bytes
        end     
               
    end
    
end