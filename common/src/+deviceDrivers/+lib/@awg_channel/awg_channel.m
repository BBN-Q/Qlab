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

classdef awg_channel < handle
	%AWG_CHANNEL objects are constructed during the AWG's initial connection to the controller. It
	% provides an interface to the individual output channels on the AWG.
	%
	%	Example:
	%
	%	Remarks: 
	%
	%	See also AWG5014, KEITHLEY220.
	%	
	%	References:
	%
	%	Author: Bhaskar Mookerji, BU-Q @ BBN
	%	Date: 14 July 2009
	%	$Revision: $  $Date: $
    %
    %   Revised by Blake Johnson, 3/29/2011
	
    % Define properties
    properties (Constant = true)
    end
    properties (Access = public)		
		deviceObj_awg;			%
        channelName;			%
        
        amplitude;              %	       
        analogHigh;             %	
        analogLow;              %	
        DACResolution;          %	
        delay;                 	%
        enabled;				%
        lowpassFilterFrequency;	%
        marker1High;			%	
        marker1Level;			%
        marker1Low;				%
        marker1Offset;			%
        marker1Amplitude;		%
        marker2High;			%
        marker2Level;			%
        marker2Low;				%
        marker2Offset;			%
        marker2Amplitude;		%
        name;					%
        outputWaveformName;		%
        offset;					%
        skew;					%	
		phase; 					%
    end % end properties

    % Define methods
    methods (Access = public)
        function obj = awg_channel(index, channel_obj)
            obj.channelName = index;
            obj.deviceObj_awg = channel_obj;
        end

		function val = Write(obj, string)
			obj.deviceObj_awg.write(string);
			val = true;
		end
		
		function val = Query(obj, string)
            val = obj.deviceObj_awg.query(string);
        end
        
        function setWaveform(obj, buffer, marker1, marker2, name)
            if nargin < 4
                marker1 = zeros(length(buffer), 1);
                marker2 = marker1;
            end
            if exist('name', 'var')
                wname = name;
            else
                wname = ['ch' obj.channelName];
            end
 
            obj.deviceObj_awg.sendWaveform(wname, buffer, marker1, marker2);
            obj.outputWaveformName = wname;
            obj.Enabled = 1;
        end
        
        function val = getWaveform(obj)
            name = obj.outputWaveformName;
            val = obj.deviceObj_awg.getWaveform(name);
        end
    end 
    methods (Access = private)

    end % end private methods
    methods
		% meta-setter
		function setAll(obj, settings)
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
				if ismember(name, methods(obj))
					feval(['obj.' name], settings.(name));
				elseif ismember(name, properties(obj))
					obj.(name) = settings.(name);
				end
			end
		end
        %	
		% property get accessors 
		%
		% property get functions for channel group object
		function val = get.amplitude(obj)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:AMPLitude?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.analogHigh(obj)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:HIGH?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.analogLow(obj)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:LOW?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.DACResolution(obj)
            gpib_string = ['SOURce', obj.channelName ,':DAC:RESolution?'];
            val = obj.Query(gpib_string);
        end
        function val = get.delay(obj)
            gpib_string = ['SOURce', obj.channelName ,':DELay?'];
            val = obj.Query(gpib_string);
        end
        function val = get.enabled(obj)
            gpib_string = ['OUTPut', obj.channelName, ':STATe?'];
            val = obj.Query(gpib_string);
        end
        function val = get.lowpassFilterFrequency(obj)
            gpib_string = ['OUTPut', obj.channelName, ':FILTer:LPASs:FREQuency?'];
            val = obj.Query(gpib_string);
        end
        function val = get.marker1High(obj)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:HIGH?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.marker1Low(obj)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:LOW?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.marker1Offset(obj)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:OFFSet?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.marker2High(obj)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:HIGH?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.marker2Low(obj)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:LOW?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.marker2Offset(obj)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:OFFSet?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.name(obj)
            val = obj.outputWaveformName();
        end
        function val = get.outputWaveformName(obj)
            gpib_string = ['SOURce', obj.channelName ,':WAVeform?'];
            val = obj.Query(gpib_string);
        end
        function val = get.offset(obj)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:OFFSet?'];
            val = str2double(obj.Query(gpib_string));
        end
        function val = get.skew(obj)
            gpib_string = ['SOURce', obj.channelName ,':SKEW?'];
            val = str2double(obj.Query(gpib_string));
        end
     
        %	
		% property set accessors 
		%
		% property set ('put') functions for channel group object
		function obj = set.amplitude(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:AMPLitude ', num2str(value)];
            obj.Write(gpib_string);
            obj.amplitude = value;
        end
        function obj = set.analogHigh(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:HIGH ', num2str(value)];
            obj.Write(gpib_string);
            obj.analogHigh = value;
        end
        function obj = set.analogLow(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:LOW ', num2str(value)];
            obj.Write(gpib_string);
            obj.analogLow = value;
        end
        function obj = set.DACResolution(obj, value)
            checkSet = [8 10 14];
            if ~(isnumeric(value) && member(value, checkSet))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['SOURce', obj.channelName ,':DAC:RESolution', num2str(value)];
            obj.Write(gpib_string);
            obj.DACResolution = value; 
        end
        function obj = set.delay(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':DELay ', num2str(value)];
            obj.Write(gpib_string);
            obj.delay = value;
        end
        function obj = set.enabled(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            propMapObj = containers.Map({'on', '1', 'off', '0'},{'ON','ON','OFF','OFF'});
            if not(propMapObj.isKey(value))
                error(['Channel Property: ', 'Invalid ', 'Enabled', ' value: ', value]);
            end
            gpib_string = ['OUTPut', obj.channelName, ':STATe ', propMapObj(value)];
            obj.Write(gpib_string);
            obj.enabled = value;
        end
        function obj = set.lowpassFilterFrequency(obj, value)
            gpib_string = ['OUTPut', obj.channelName, ':FILTer:LPASs:FREQuency', num2str(value)];
            obj.Write(gpib_string);
            obj.lowpassFilterFrequency = value;
        end
        function obj = set.marker1High(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:HIGH ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker1High = value;
        end
        function obj = set.marker1Low(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:LOW ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker1Low = value;
        end
        function obj = set.marker1Offset(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:OFFSet ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker1Offset = value;
        end
        function obj = set.marker1Amplitude(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:AMPLitude ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker1Amplitude = value;
        end
        function obj = set.marker2High(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:HIGH ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker2High = value;
        end
        function obj = set.marker2Low(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:LOW ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker2Low = value;
        end
        function obj = set.marker2Offset(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:OFFSet ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker2Offset = value;
        end
        function obj = set.marker2Amplitude(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:AMPLitude ', num2str(value)];
            obj.Write(gpib_string);
            obj.marker2Amplitude = value;
        end
        function obj = set.name(obj, value)
            obj.outputWaveformName = value;
        end
        function obj = set.outputWaveformName(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':WAVeform ', '"', value, '"'];
            obj.Write(gpib_string);
            obj.outputWaveformName = value;
        end
        function obj = set.offset(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':VOLTage:OFFSet ', num2str(value)];
            obj.Write(gpib_string);
            obj.offset = value;
        end
        function obj = set.skew(obj, value)
            gpib_string = ['SOURce', obj.channelName ,':SKEW ', num2str(value)];
            obj.Write(gpib_string);
            obj.skew = value;
        end
    end	% end private methods  
end     
