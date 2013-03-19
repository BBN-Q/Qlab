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

classdef (Sealed) Tek5014 < deviceDrivers.lib.GPIBorEthernet
	% AWG5014 is an instrument wrapper class for the Tektronix Arbitrary Waveform Generator 5014.
	% Like the other instrument classes, it provides an interface for interacting with device 
	% while abstracting away the GPIB instruction set.
	%
	%
	%	Author: Bhaskar Mookerji, BU-Q @ BBN
	%	Date: July 2009
	%	$Revision: $  $Date: $
    %
    %   Revised by Blake Johnson, 3/29/2011
	
    % Define properties
    properties (Constant = true)
        LRG_WAVEFORM = 0	%	Split waveforms into smaller subunits (0 = off, 1 = on)
    end
    
    properties (Access = public)
		%% Device, group, and channel object for the AWG.

        chan_1;             %	Instantiation of awg_channel object.
        chan_2;             %	Instantiation of awg_channel object.	
        chan_3;             %	Instantiation of awg_channel object.
        chan_4;             %	Instantiation of awg_channel object.  
	
        %% Instrument Properties
        sequenceElement = 1;
        trigger_run_mode_toggle = false; % Set trigger parameters in Sequence mode.
        
		% Trigger group object properties
		Impedance;  		%	Values: 500Ohms, 1Ohms
		InternalRate;		%	Values: <numeric>
		Level;				%	Values: <numeric>
		Polarity; 			%	Values: Positive, Negative
		Slope;    			%	Values: Positive, Negative
		triggerSource;		%	Values: Internal, External
		WaitValue;			%	Values: First, Last
		
		% Control group object properties
		ChannelCount;		%	<Returns number of available channels.>
		ClockSource;     	%	Values: Internal, External		
		runMode;            %	Values: Continuous, Sequence, Gated, Triggered
		OperationState;  	%   Values: 0 (stopped) 1 (waiting for trigger) 2 (running)
		RepetitionRate;  	%	Values: <numeric>
		samplingRate;    	%	Values: <numeric>
		
		%% ArbSeq group object properties
		% Most of these remain unimplemented in GPIB.
		ArbSeqType;			
		CurrentPosition;
        Length;	
% 		GotoIndex;
% 		GotoState;
% 		InfiniteLoop;
% 		Jump;
% 		JumpTargetIndex;
% 		JumpTargetType;		
		loopCount;
% 		WaitTriggerState
		waveformName;

		% Directory and memory operations
		current_working_directory;
        
        % Controlexternalclocksource group object properties
        DividerRate;

        % ControlexternalrefOsc group object properties
        refOsc;             %	Values: Internal, External
        refOscType;         %   Values: Fixed, Variable
        refOscMultiplier;   %   Clock at a multiplier of a variable external reference
        refOscFrequency;    %   Frequency of fixed external reference, 10 MHz, 20 MHz, or 100 MHz
        
    end
    
    properties (Access = private) 
    end % end properties


    % Define methods
    %% Private methods
    methods (Access = private)
        function init_params(obj)
        end
        
        function val = seq_string(obj)
            if obj.trigger_run_mode_toggle
                val = ':SEQuence';
            else
                val = '';
            end
        end
    end
    
    methods (Access = public) 
        function obj = Tek5014()
            obj.DEFAULT_PORT = 4000;
        end
        
        function delete(obj)
            obj.disconnect();
        end
        
        function obj = connect(obj, address)
		% connect(address) initiates a connection to the AWG over TCPIP or GPIB
        % depending on the form of the address
            import deviceDrivers.lib.awg_channel;
            
            % call superclass method
            connect@deviceDrivers.lib.GPIBorEthernet(obj, address);
            
            % set up channel objects
            obj.chan_1 = awg_channel('1', obj);
            obj.chan_2 = awg_channel('2', obj);
            obj.chan_3 = awg_channel('3', obj);
            obj.chan_4 = awg_channel('4', obj);
        end
		
		% instrument meta-setter
		function setAll(obj, settings)
			% load AWG file before doing anything else
			if isfield(settings, 'seqfile')
				if ~isfield(settings, 'seqforce')
					settings.seqforce = false;
				end
				
				% load an AWG file if the settings file is changed or if force == true
				if (~strcmp(obj.getSetupFileName(), settings.seqfile) || settings.seqforce)
					obj.openConfig(settings.seqfile);
                    obj.operationComplete(); % wait until we're done with the load to continue
				end
			end
			settings = rmfield(settings, 'seqfile');
			settings = rmfield(settings, 'seqforce');
			
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
				switch name
					case 'chan_1'
						obj.chan_1.setAll(settings.chan_1);
					case 'chan_2'
						obj.chan_2.setAll(settings.chan_2);
					case 'chan_3'
						obj.chan_3.setAll(settings.chan_3);
					case 'chan_4'
						obj.chan_4.setAll(settings.chan_4);
					case 'scaleMode'
                    case 'Level'
                        obj.Level = settings.Level;
					case 'triggerSource'
						obj.triggerSource = settings.triggerSource;
					case 'InternalRate'
						obj.InternalRate = settings.InternalRate;
					case 'samplingRate'
						obj.samplingRate = settings.samplingRate;
					otherwise
						if ismember(name, methods(obj))
							feval(['obj.' name], settings.(name));
						elseif ismember(name, properties(obj))
							obj.(name) = settings.(name);
						end
				end
			end
		end
        
        %% Memory and directory structure methods
        function val = getSetupFileName(obj)
            %GETSETUPFILENAME returns the current setup file for the AWG.
            %
            gpib_string = 'AWGControl:SNAMe?';
            val = obj.query(gpib_string);
            
            % output is of the form: "name","basepath"
            expr = '"(.*)","(.*)"';
            matches = regexp(val, expr, 'tokens');
            if ~isempty(matches)
                matches = fliplr(matches{1}); %put the path in front
                val = [matches{:}]; %then concatenate
            end
        end
        
        function saveConfig(obj, name)
            %SAVECONFIG(NAME) saves the current AWG configuration to a specified 
			% settings file on the AWG's main hard drive (usually 'C:\'). If a 
			% path is not specified, the local (or default) path is assumed. 
			%	
			%	Argument(s):
			%		name	A MATLAB string specifying the path to a file.
			%
			%	Example: 
			%		% myAWG is a pre-existing AWG object connected to the instrument
			%		myAWG.saveConfig('\my\project\awg\foo.awg');
			%
			%		myAWG.saveConfig('foo.awg');
            %
            if ~ischar(name)
				error('');
			end
			name = ['"' name '"'];
            gpib_string = ['AWGControl:SSAVe ' name];
            obj.write(gpib_string);
        end
        
        function openConfig(obj, name)
			%OPENCONFIG(NAME) opens an AWG configuration from a specified 
			% settings file on the AWG's main hard drive (usually 'C:\'). If a 
			% path is not specified, the local (or default) path is assumed. 
			%	
			%	Argument(s):
			%		name	A MATLAB string specifying the path to a file.
			%
			%	Example: 
			%		% myAWG is a pre-existing AWG object connected to the instrument
			%		myAWG.openConfig('\my\project\awg\foo.awg');
			%
			%		myAWG.openConfig('foo.awg'); 
            %
			if ~isa(name, 'char')
				error('Invalid file name');
            end
            %if ~exist(name, 'file')
            %    error('Could not find %s', name);
            %end
			name = ['"' name '"'];
            gpib_string = ['AWGControl:SREStore ' name];
            obj.write(gpib_string);
        end
        
        function importWaveform(obj, waveform_name, file_name, type)
            %IMPORTWAVEFORM imports a file into the AWG's setup as a 
            %waveform.
            %
            %   Arugment(s):
            %       waveform_name   waveform string, overwritten if exists
            %       file_name       file string, can contain a path
            %       type            file format string for waveform
            %
            %   'type' Options:
            %       isf             TDS3000 and DPO4000 waveform format
            %       tds             TDS5000/6000/7000 Series waveform
            %       txt             text file with analog data
            %       txt8            text file with 8-bit DAC resolution
            %       txt10           text file with 10-bit DAC resolution
            %       wfm             AWG400/500/600/700 Series waveform
            %       pat             AWG400/500/600/700 Series pattern waveform
            %       tfw             AFG3000 Series waveform file format
            %
            %   Example:
            %       % myAWG is an pre-existing waveform
            %       myAWG.importWaveform('name', 'name.txt', 'txt8');
            %
            if ~ischar(waveform_name) && ~ischar(file_name) && ~ischar(type)
				error('');
            end
            waveform_name = ['"' waveform_name '"'];
            file_name = ['"' file_name '"'];
            typeMapObj = containers.Map({...
                'isf','tds','txt','txt8','txt10','wfm','pat','tfw'...
                },{'ISF', 'TDS', 'TXT', 'TXT8', 'TXT10', 'WFM', 'PAT', 'TFW'});
            type = typeMapObj(type);
            gpib_string = ['MMEMory:IMPort ' waveform_name ',' file_name ',' type];
            obj.write(gpib_string);
        end
        
        function makeDirectory(obj, directory_name)
            %MAKEDIRECTORY creates a new directory IN THE CURRENT PATH on
            % the AWG.
            %  
            %   Example:
            %   myAWG.makeDirectory('foo');
            %
            if not(isa(directory_name, 'char'))
				error('');
            end
            gpib_string = ['MMEMory:MDIRectory' directory_name];
            obj.write(gpib_string);
        end
		
		%% Reset, stop, start methods for AWG.
        function reset(obj)
            %RESET returns the AWG to its default state.
            obj.write('*RST;');
        end

		function val = calibrate(obj)
			%CALIBRATE performs an internal calibration on the instrument and returns the 
			%status
			%
			gpib_string = '*CAL?';
			val = obj.query(gpib_string);
		end
        
        function run(obj)
            %RUN enables active output from the AWG. For a given channel
            % to output a waveform, however, it must be enabled (see
            % 'awg_channel.Enabled'.).
            gpib_string = 'AWGControl:RUN';
            obj.write(gpib_string);
        end

		function stop(obj)
			%STOP ends the output of a waveform or sequence
			gpib_string = 'AWGControl:STOP';
			obj.write(gpib_string);
            %Wait for it to actually stop. 
            obj.operationComplete();
        end
        
        function sync(obj)
            %SYNC ensures the first command is finished before executing
            % a second one. By default, this command is off and can
            % possibly be turned off by issuing a reset() command.
            gpib_string = '*OPC';
            obj.write(gpib_string);
        end
        
        function operationComplete(obj)
           val = 0;
           max_count = 3;
           count = 1;
           while ~(val == 1 || count > max_count)
               val = str2double(obj.query('*OPC?'));
               count = count + 1;
           end
        end
        
        function clearSeq(obj)
            obj.Length = 0;
        end
        
        %% Waveform methods
        function out = packPattern(obj, pattern, marker1, marker2)
			% AWG 5000 series binary data format
			% m2 m1 d14 d13 d12 d11 d10 d9 d8 d7 d6 d5 d4 d3 d2 d1
			% 16-bit format with markers occupying left 2 bits followed by the 14 bit
			% analog channel value
			
			% clip patterns to 14-bits
            pattern = uint16(pattern);
			pattern( pattern > 2^14 - 1 ) = 2^14 - 1;

			% force markers to binary
			marker1 = uint16(bitand(1, marker1));
			marker2 = uint16(bitand(1, marker2));

			out = bitor(pattern, bitor(bitshift(marker1, 14), bitshift(marker2, 15)));
        end
        
        function sendWaveform(obj, name, waveform, marker1, marker2)
            if nargin < 5 % markers not provided, zero them
                marker1 = zeros(length(waveform), 1);
                marker2 = marker1;
            end
            
            data = obj.packPattern(waveform, marker1, marker2);
    
            % pack waveform by separating waveform values into (low-8, high-8)
            % sequential values, aka LSB format
            bindata = zeros(2*length(data),1);
            bindata(1:2:end) = bitand(data,255);
            bindata(2:2:end) = bitshift(data,-8);
            bindata = bindata';

            % write
            obj.deleteWaveform(name);
            obj.createWaveform(name, length(waveform), 'integer');
            obj.binblockwrite(bindata, [':wlist:waveform:data "' name '",']); %data transmission
        end

        function sendWaveformReal(obj, name, waveform, marker1, marker2)
		% SENDWAVEFORMREAL sends a floating point (i.e., real) waveform buffer to the AWG.
		% It currently sends a row buffer but should work with column buffers.
		%
        %   Arguments:
        %       name        A name string 
        %       buffer      Row vector of an instrument
        %
		%   Example:
		%       myAWG = AWG5014();
		%       myAWG.init_connection('visa_string');
		%       myAWG.sendWaveformReal('test_wfm', sin([0:pi/100:2*pi]));
        %
            waveform = single(waveform); % need sinle-precision (32-bit) data
            
            if nargin < 5 % markers not provided, zero them
                marker1 = zeros(length(waveform), 1);
                marker2 = marker1;
            end
            
            % encode marker 1 bits to bit 6
            marker1 = bitshift(uint8(logical(marker1)),6); %check dec2bin(marker1(2),8)

            % encode marker 2 bits to bit 7
            marker2 = bitshift(uint8(logical(marker2)),7); %check dec2bin(marker2(2),8)

            % merge markers
            m = marker1 + marker2; %check dec2bin(m(2),8)

            % stitch waveform data with marker data as per progammer manual
            binblock = zeros(1,length(waveform)*5,'uint8'); % real uses 5 bytes per sample
            for k=1:length(waveform)
                binblock((k-1)*5+1:(k-1)*5+5) = [typecast(waveform(k),'uint8') m(k)];
            end
            
            obj.deleteWaveform(name);
            obj.createWaveform(name, 'real', length(buffer));
            obj.binblockwrite(binblock, [':wlist:waveform:data "' name '",']); %data transmission
        end
        
        function createWaveform(obj, name, size, type)
            gpib_string = [':WLISt:WAVeform:NEW "', name , '",', num2str(size), ', ',type];
            obj.write(gpib_string);
        end
        
        function deleteWaveform(obj, name) 
            obj.write([':wlist:waveform:del "' name '";']);
        end
        
        function val = getWaveform(obj, name)
            gpib_string = ['WLIST:WAVeform:DATA? "', name, '"'];
            obj.write(gpib_string);
            val = obj.binblockread('uint16');
        end
        
        function val = getWaveformReal(obj, name, startIndex, blockSize)
            gpib_string = ['WLIST:WAVeform:DATA? ', name, ',', ... 
                    num2str(startIndex),',', num2str(blockSize)];
            obj.write(gpib_string);
            val = obj.binblockread('single');
        end

        function sendMarkerData(obj, name, marker1, marker2)
            if not(isa(name, 'char')) || ...
                    (length(marker1) ~= length(marker2))
                error('');
            end
            
            % encode marker 1 bits to bit 6
            marker1 = bitshift(uint8(logical(marker1)),6); %check dec2bin(marker1(2),8)

            % encode marker 2 bits to bit 7
            marker2 = bitshift(uint8(logical(marker2)),7); %check dec2bin(marker2(2),8)

            % merge markers
            m = marker1 + marker2; %check dec2bin(m(2),8)
            
            obj.binblockwrite(m, [':wlist:waveform:marker:data "' name '",']); %data transmission
        end

    end % end public methods
    
    methods 
		%%	
		% property get accessors 
		%
        function val = get.current_working_directory(obj)
			gpib_string = 'MMEMory:CDIRectory?';
            val = obj.query(gpib_string);
        end
        
		%% property get functions for Trigger group object
		function val = get.Impedance(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':IMPedance?']);
		end
		function val = get.InternalRate(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':TIMer?']);
		end
		function val = get.Level(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':LEVel?']);
		end
		function val = get.Polarity(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':POLarity?']);
		end
		function val = get.Slope(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':SLOPe?']);
		end
		function val = get.triggerSource(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':SOURce?']);
		end
		function val = get.WaitValue(obj)
            val = obj.query(['TRIGger' seq_string(obj) ':WVALue?']);
		end
		
		%% property get functions for Control group object
		function val = get.ChannelCount(obj)
            val = obj.query('AWGControl:CONFigure:CNUMber?');
		end
		function val = get.ClockSource(obj)
            val = obj.query('AWGControl:CLOCk:SOURce?');
		end
		function val = get.runMode(obj)
            val = obj.query('AWGControl:RMODe?');
		end
		function val = get.OperationState(obj)
            val = obj.query('AWGControl:RSTate?');
        end
		function val = get.RepetitionRate(obj)
            val = obj.query('AWGControl:RRATe?');
		end
		function val = get.samplingRate(obj)
            temp = obj.query('SOURce1:FREQuency?');
            val = str2double(temp);
        end
        function val = get.DividerRate(obj) % external clock source divider rate
            temp = obj.query('AWGControl:CLOCk:DRATe?');
            val = str2double(temp);
        end

		%% property get functions for ArbSeq group object
		function val = get.ArbSeqType(obj)
            val = obj.query('SEQ:Type?');
		end
		function val = get.CurrentPosition(obj)
            temp = obj.query('SEQ:Position?');
            val = str2double(temp);
		end
		function val = get.Length(obj)
            temp = obj.query('SEQ:Length?');
            val = str2double(temp);
        end

        %% Reference oscillator functions
        function val = get.refOsc(obj)
            val = obj.query('SOURce1:ROSCillator:SOURce?');
        end
        
        function val = get.refOscType(obj)
            val = obj.query('SOURce1:ROSCillator:TYPE?');
        end

        function val = get.refOscMultiplier(obj)
            temp = obj.query('SOURce1:ROSCillator:MULTiplier?');
            val = str2double(temp);
        end
        function val = get.refOscFrequency(obj)
            val = obj.query('SOURce1:ROSCillator:FREQuency?');
        end
		
		
		%%
		% property set accessors 
		%
		%% property get functions for Trigger group object
		function obj = set.Impedance(obj, value)
			check_val = ['TekFgenTriggerImpedance',value];
            optionString = 'Impedance';            
            checkMapObj = containers.Map({...
                'TekFgenTriggerImpedance500Ohms',...
                'TekFgenTriggerImpedance1KOhms'...
                },{'50','1k'});
            checkMapObj = containers.Map({'50', '1000', '1k', '1K'},...
                {'50', '1k', '1k', '1k'});

            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':IMPedance ',checkMapObj(check_val)];
                obj.write(gpib_string);
                obj.Impedance = check_val; 
            end
        end
        
		function obj = set.InternalRate(obj, value)
            optionString = 'InternalRate';

            if ~isnumeric(value)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':TIMer ', num2str(value)];
                obj.write(gpib_string);
                obj.InternalRate = value; 
            end
		end
		function obj = set.Level(obj, value) % trigger level
            optionString = 'Level';
            if ~isnumeric(value)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':LEVel ', num2str(value)];
                obj.write(gpib_string);
                %obj.Level = check_value; 
            end
		end
		function obj = set.Polarity(obj, value) % trigger polarity
            optionString = 'Polarity';            
	        checkMapObj = containers.Map({...
	            'Positive',...
	            'Negative'...
	            },{'POSitive', 'NEGative'});

            if not(checkMapObj.isKey(value))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':POLarity ', value];
                obj.write(gpib_string);
                obj.Polarity = value; 
            end
		end
		function obj = set.Slope(obj, value)
            optionString = 'Slope';            
	        checkMapObj = containers.Map({...
	            'Positive',...
	            'Negative'...
	            },{'POSitive', 'NEGative'});

            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':SLOPe ', value];
                obj.write(gpib_string);
                obj.Slope = value; 
            end
		end
		function obj = set.triggerSource(obj, value)
			check_val = value;
            optionString = 'Source';
	        checkMapObj = containers.Map({...
	            'internal','external',...
                'int', 'ext'
	            },{'INTernal','EXTernal','INTernal','EXTernal'});

            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':SOURce ', checkMapObj(check_val)];
                obj.write(gpib_string);
                %obj.triggerSource = check_val;
            end
		end
		function obj = set.WaitValue(obj, value)
			check_val = value;
            optionString = 'WaitValue';
	        checkMapObj = containers.Map({...
	            'First',...
	            'Last'...
	            },{'First','Last'});
            
            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['TRIGger' seq_string(obj) ':WVALue ', checkMapObj(check_val)];
                obj.write(gpib_string);
                obj.WaitValue = check_value; 
            end
		end
		

		%% property get functions for Control group object
		function obj = set.ClockSource(obj, value)
			check_val = lower(value);
            optionString = 'ClockSource';
            checkMapObj = containers.Map({...
                'internal', 'int', ...
                'external', 'ext', ...
                },{'INTernal','INTernal','EXTernal','EXTernal'});
            
            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['AWGControl:CLOCk:SOURce ', checkMapObj(check_val)];
                obj.write(gpib_string);
                obj.ClockSource = check_value; 
            end
		end
        function obj = set.runMode(obj, value)
            checkMapObj = containers.Map({...
                'TRIG','TRIGGERED','triggered','Triggered',...
                'SEQ','SEQUENCE','sequence','Sequence',...
                'GAT','GATED','gated','Gated',...
                'CONT','CONTINUOUS','continuous','Continuous'},...
                {'TRIG','TRIG','TRIG','TRIG',...
                'SEQ','SEQ','SEQ','SEQ',...
                'GAT','GAT','GAT','GAT',...
                'CONT','CONT','CONT','CONT'});

            if not(checkMapObj.isKey(value))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['AWGControl:RMODe ',checkMapObj(value)];
                obj.write(gpib_string);
%                     obj.runMode = check_val; 
            end
		end
		function obj = set.refOsc(obj, value)
			check_val = value;
            optionString = 'ReferenceSource';            
            checkMapObj = containers.Map({...
                'internal', 'int', ...
                'external', 'ext', ...
                },{'INTernal','INTernal','EXTernal','EXTernal'});
            
            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            else
                gpib_string = ['SOURce1:ROSCillator:SOURce ',checkMapObj(check_val)];
                obj.write(gpib_string);
                obj.refOsc = check_val; 
            end
		end
		function obj = set.RepetitionRate(obj, value)
            optionString = 'RepetitionRate';
            
            if (~isnumeric(value) || value <= 0)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            else
                gpib_string = ['AWGControl:RRATe ', num2str(value)];
                obj.write(gpib_string);
                obj.RepetitionRate = check_val; 
            end
		end
		function obj = set.samplingRate(obj, value)
            optionString = 'SamplingRate';

            if (~isnumeric(value) || value < 10^7 || value > 10^10)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            else
                gpib_string = ['SOURce1:FREQuency ', num2str(value)];
                obj.write(gpib_string);
                obj.samplingRate = value;
            end
        end

        %% property set functions for Arbseq group object
        function set.Length(obj, value)
            optionString = 'Length';
            if (~isnumeric(value) || value < 0 || value > 16000)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            obj.write(['SEQuence:LENGth ', num2str(value)]);
        end

        function set.loopCount(obj, value)
            optionString = 'LoopCount';            

            if (~isnumeric(value) || value > 65536 || value < 1)
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['SEQuence:ELEMent:LOOP:COUNt ', num2str(value)];
            obj.write(gpib_string);
            obj.loopCount = value;
        end

        function set.waveformName(obj, value)
            obj.Length = 1;
            gpib_string = ['SEQuence:ELEMent1:WAVeform', ...
                    num2str(value{1}),' "', value{2}, '"'];
            obj.write(gpib_string);
            obj.waveformName = value; 
        end
        
        %% property set functions for external clock soure group
        function obj = set.DividerRate(obj, value)
            optionString = 'DividerRate';
            checkSet = [1 2 4 8];

            if ~(isnumeric(value) && ismember(value, checkSet))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['AWGControl:CLOCk:DRATe ' num2str(value)];
            obj.write(gpib_string);
            obj.DividerRate = value; 
        end
        
        function obj = set.refOscType(obj, value)
			optionString = 'refOscType';   
            checkMapObj = containers.Map({...
                'Fixed',...
                'Variable'...
                },{'FIXed', 'VARiable'});

            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['SOURce1:ROSCillator:TYPE ' checkMapObj(value)];
            obj.write(gpib_string);
            obj.refOscType = value; 
        end
        function obj = set.refOscMultiplier(obj, value)
            optionString = 'refOscMultiplier';

            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['SOURce1:ROSCillator:MULTiplier ' num2str(value)];
            obj.write(gpib_string);
            obj.refOscMultiplier = value;
		end
        function obj = set.refOscFrequency(obj, value)
			optionString = 'Frequency';  
            checkMapObj = containers.Map({...
                '10MHz', '20MHz', '100MHz'...
                },{'10MHz', '20MHz', '100MHz'});

            if not(checkMapObj.isKey(check_val))
                error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
            end
            gpib_string = ['SOURce1:ROSCillator:FREQuency ' checkMapObj(value)];
            obj.write(gpib_string);
            obj.Frequency = value; 
		end
		
		% property get functions for current group object
        function set.current_working_directory(obj, value)
			value = ['"' value '"'];
			gpib_string = ['MMEMory:CDIRectory ' value ];
            obj.write(gpib_string);
        end
		
    end % end methhods
end % end class definition

