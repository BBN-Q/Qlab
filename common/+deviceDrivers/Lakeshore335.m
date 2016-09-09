% Class Lakeshore335 - Instrument driver for the Lakeshore 335 Temperature Controller

% Original Author: Colm Ryan (cryan@bbn.com)

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

classdef (Sealed) Lakeshore335 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIBorVISA
    properties (Access = public)
		leds
    end

	methods
        function instr = Lakeshore335()
        end

		%Getter/setter for front-panel LEDs as boolean
		function val = get.leds(instr)
			val = logical(str2double(query(instr, 'LEDS?')));
		end

		function set.leds(instr, val)
			write(instr, sprintf('LEDS %d', val));
		end

		function val = get_temperature(instr, chan)
			%Get current temperature in Kelvin for a specified channel
			assert(chan == 'A' || chan == 'B', 'Channel must be "A" or "B"');
			val = str2double(query(instr, sprintf('KRDG? %c', chan)));
		end

		function [val, temp] = get_curve_val(instr, curve, index)
			%Get a calibration curve tuple for a curve at a specified index
			strs = strsplit(query(instr, sprintf('CRVPT? %d,%d'), curve, index), ',');
			val = str2double(strs{1});
			temp = str2double(strs{2});
		end

		function set_curve_val(instr, curve, index, val, temp)
			%Set a calibration curve (val, temp) tuple for a curve at a specified index
			write(instr, sprintf('CRVPT %d,%d,%d,%d', curve, index, val, temp));
		end

	end

end
