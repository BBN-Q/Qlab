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
	
    % Define properties
    properties (Constant = true)
        checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
		
		TEK_DRIVER = 1;
		NATIVE_DRIVER = 2;
    end
    properties (Access = public)
		driver_mode;			%
		
		deviceObj_awg;			%
        chanObj_awg;			%
        channelName;			%

        Count;					%		
        Coupled_State;        	%
        
        Amplitude;              %	       
        AnalogHigh;             %	
        AnalogLow;              %	
        DACResolution;          %	
        Delay;                 	% 		
        DelayInputMethod;		%	
        DigitalHigh;			%
        DigitalLow;				%
        DigitalOffset;			%
        Enabled;				%
        LowpassFilterFrequency;	%
        Marker1High;			%	
        Marker1Level;			%
        Marker1Low;				%
        Marker1Offset;			%
        Marker2High;			%
        Marker2Level;			%
        Marker2Low;				%
        Marker2Offset;			%
        Name;					%
        outputWaveformName;				%
        offset;					%
        Skew;					%	
        DigitalAmplitude;		%
		Phase; 					%
    end % end properties

    % Define methods
    methods (Access = public)
        function obj = awg_channel(index, driver_select, channel_obj)
            obj.channelName = index; 
            obj.driver_mode = driver_select;
            
            if driver_select == obj.TEK_DRIVER
                obj.chanObj_awg = channel_obj;
            elseif driver_select == obj.NATIVE_DRIVER
                obj.deviceObj_awg = channel_obj;
            end
        end

		function val = Write(obj, string)
			% Do error checking here.
			fprintf(obj.deviceObj_awg, string);
			val = true;
		end
		
		function val = Query(obj, string)
			val = query(obj.deviceObj_awg, string);
		end
    end 
    methods (Access = private)
        function val = getChannelParam(obj, optionString, markerNumber)
            if nargin == 2
                val = invoke(obj.chanObj_awg, ['get',optionString], obj.channelName);
                return;
            elseif nargin == 3
                if (markerNumber ~= 1) && (markerNumber ~= 2) 
                    error(['Invalid marker value: ', markerNumber]);
                end
                val = invoke(obj.chanObj_awg, ['get',optionString], obj.channelName, markerNumber);
                return;
            end
        end
        
        function val = setChannelParam(obj, optionString, value, markerNumber)
            if not(obj.checkMapObj.isKey(class(value)))
                if not(isequal(optionString, 'outputWaveformName'))
                    error(['Invalid ', optionString, ' value: ', value]);
                end
            end
            if nargin == 3
                invoke(obj.chanObj_awg, ['put',optionString], obj.channelName, value);
                val = value;
                return;
            elseif nargin == 4
                if (markerNumber ~= 1) && (markerNumber ~= 2) 
                    error(['Invalid marker value: ', markerNumber]);
                end
                invoke(obj.chanObj_awg, ['put',optionString], obj.channelName, value, markerNumber);
                val = value;
                return;
            end
        end

		function val = function_call_dispatch(obj, tek_string, gpib_string, read_write)
			if obj.driver_mode == obj.TEK_DRIVER
				val = eval(tek_string);
			elseif obj.driver_mode == obj.NATIVE_DRIVER
                if read_write == true
					obj.Write(gpib_string);
					val = fscanf(obj.deviceObj_awg);
				elseif read_write == false
					obj.Write(gpib_string);
					val = gpib_string;
				else 
					error(['Invalid read_write value in function_call_dispach: ', read_write]);
                end
			else
				error(['Invalid driver selection: ', obj.driver_mode]);
			end
		end
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
		function val = get.Amplitude(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'Amplitude');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:AMPLitude?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
			
        end
        function val = get.AnalogHigh(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'AnalogHigh');                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:HIGH?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.AnalogLow(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'AnalogLow');                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:LOW?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.DACResolution(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'DACResolution');                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DAC:RESolution?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Delay(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'Delay');                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DELay?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.DelayInputMethod(obj)
            if obj.driver_mode == obj.TEK_DRIVER
    			val = getChannelParam(obj, 'DelayInputMethod');                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:AMPLitude?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.DigitalHigh(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'DigitalHigh');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:HIGH?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.DigitalLow(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'DigitalLow');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:LOW?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.DigitalOffset(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'DigitalOffset');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:OFFSet?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Enabled(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'Enabled');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['OUTPut', obj.channelName, ':STATe?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.LowpassFilterFrequency(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'LowpassFilterFrequency');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['OUTPut', obj.channelName, ':FILTer:LPASs:FREQuency?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Marker1High(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'MarkerHigh', 1);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:HIGH?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Marker1Low(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'MarkerLow', 1);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:LOW?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Marker1Offset(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'MarkerOffset', 1);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:OFFSet?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Marker2High(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'MarkerHigh', 2);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:HIGH?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Marker2Low(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'MarkerLow', 2);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:LOW?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Marker2Offset(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'MarkerOffset', 2, true);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:OFFSet?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Name(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'Name');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:HIGH?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.outputWaveformName(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'outputWaveformName');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':WAVeform?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.offset(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'offset');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:OFFSet?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.Skew(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'Skew');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':SKEW?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.DigitalAmplitude(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getChannelParam(obj, 'DigitalAmplitude');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:AMPLitude?'];
                val = obj.Query(gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
     
        %	
		% property set accessors 
		%
		% property set ('put') functions for channel group object
		function obj = set.Amplitude(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Amplitude = setChannelParam(obj, 'Amplitude', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:AMPLitude ', num2str(value)];
                obj.Write(gpib_string);
                obj.Amplitude = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.AnalogHigh(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.AnalogHigh = setChannelParam(obj, 'AnalogHigh', value);                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:HIGH ', num2str(value)];
                obj.Write(gpib_string);
                obj.AnalogHigh = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.AnalogLow(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.AnalogLow = setChannelParam(obj, 'AnalogLow', value);                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:LOW ', num2str(value)];
                obj.Write(gpib_string);
                obj.AnalogLow = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.DACResolution(obj, value)
			check_val = class(value);
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
            if obj.driver_mode == obj.TEK_DRIVER
                obj.DACResolution = setChannelParam(obj, 'DACResolution', value);                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
				if not(checkMapObj.isKey(check_val)) || (value == 8) || (value == 10)
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                end
                gpib_string = ['SOURce', obj.channelName ,':DAC:RESolution', num2str(value)];
                obj.Write(gpib_string);
                obj.DACResolution = value; 
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Delay(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Delay = setChannelParam(obj, 'Delay', value);                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DELay ', num2str(value)];
                obj.Write(gpib_string);
                obj.Delay = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.DelayInputMethod(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.DelayInputMethod = setChannelParam(obj, 'DelayInputMethod', value);                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:AMPLitude ', num2str(value)];
                obj.Write(gpib_string);
                obj.DelayInputMethod = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.DigitalHigh(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.DigitalHigh = setChannelParam(obj, 'DigitalHigh', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:HIGH ', num2str(value)];
                obj.Write(gpib_string);
                obj.DigitalHigh = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.DigitalLow(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.DigitalLow = setChannelParam(obj, 'DigitalLow', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:LOW ', num2str(value)];
                obj.Write(gpib_string);
                obj.DigitalLow = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.DigitalOffset(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.DigitalOffset = setChannelParam(obj, 'DigitalOffset', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:OFFSet ', num2str(value)];
                obj.Write(gpib_string);
                obj.DigitalOffset = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Enabled(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Enabled = setChannelParam(obj, 'Enabled', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                propMapObj = containers.Map({'on', '1', 'off', '0'},{'ON','ON','OFF','OFF'});
                if not(propMapObj.isKey(value))
                    error(['Channel Property: ', 'Invalid ', 'Enabled', ' value: ', value]);
                end
                gpib_string = ['OUTPut', obj.channelName, ':STATe ', propMapObj(value)];
                obj.Write(gpib_string);
                obj.Enabled = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.LowpassFilterFrequency(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.LowpassFilterFrequency = setChannelParam(obj, 'LowpassFilterFrequency ', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['OUTPut', obj.channelName, ':FILTer:LPASs:FREQuency', num2str(value)];
                obj.Write(gpib_string);
                obj.LowpassFilterFrequency = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Marker1High(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Marker1High = setChannelParam(obj, 'MarkerHigh', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:HIGH ', num2str(value)];
                obj.Write(gpib_string);
                obj.Marker1High = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Marker1Low(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Marker1Low = setChannelParam(obj, 'MarkerLow', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:LOW ', num2str(value)];
                obj.Write(gpib_string);
                obj.Marker1Low = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Marker1Offset(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Marker1Offset = setChannelParam(obj, 'MarkerOffset', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:OFFSet ', num2str(value)];
                obj.Write(gpib_string);
                obj.Marker1Low = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Marker2High(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Marker2High = setChannelParam(obj, 'MarkerHigh', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:HIGH ', num2str(value)];
                obj.Write(gpib_string);
                obj.Marker2High = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Marker2Low(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Marker2Low = setChannelParam(obj, 'MarkerLow', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:LOW ', num2str(value)];
                obj.Write(gpib_string);
                obj.Marker2Low = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Marker2Offset(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Marker2Offset = setChannelParam(obj, 'MarkerOffset', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':MARKer2:VOLTage:OFFSet ', num2str(value)];
                obj.Write(gpib_string);
                obj.Marker2Offset = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Name(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Name = setChannelParam(obj, 'Name', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
				% clearly not doing the right thing; commenting out (BRJ)
%                 gpib_string = ['SOURce', obj.channelName ,':MARKer1:VOLTage:HIGH ', value];
%                 obj.Write(gpib_string);
%                 obj.Name = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.outputWaveformName(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.outputWaveformName = setChannelParam(obj, 'outputWaveformName', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':WAVeform ', '"', value, '"'];
                obj.Write(gpib_string);
                obj.outputWaveformName = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.offset(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.offset = setChannelParam(obj, 'offset', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':VOLTage:OFFSet ', num2str(value)];
                obj.Write(gpib_string);
                obj.offset = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.Skew(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.Skew = setChannelParam(obj, 'Skew', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':SKEW ', num2str(value)];
                obj.Write(gpib_string);
                obj.Skew = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function obj = set.DigitalAmplitude(obj, value)
            if obj.driver_mode == obj.TEK_DRIVER
                obj.DigitalAmplitude = setChannelParam(obj, 'DigitalAmplitude', value);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = ['SOURce', obj.channelName ,':DIGital:VOLTage:AMPLitude ', num2str(value)];
                obj.Write(gpib_string);
                obj.DigitalAmplitude = value;
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
    end	% end private methods  
end     
