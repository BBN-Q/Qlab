classdef (Sealed) Tek5014 < deviceDrivers.lib.Ethernet
	% AWG5014 is an instrument wrapper class for the Tektronix Arbitrary Waveform Generator 5014.
	% Like the other instrument classes, it provides an interface for interacting with device 
	% while abstracting away the GPIB instruction set.
	%
	%	Example:
	% 
	%	
	%	Remarks: 
	%		1. P
	%			
	%	See also .
	%	
	%	References:
	%
	%	Author: Bhaskar Mookerji, BU-Q @ BBN
	%	Date: July 2009
	%	$Revision: $  $Date: $
	
    % Define properties
    properties (Constant = true)
        %% Class Constants
        REVISION_NUMBER = 0.01; 
        IVI_DRIVER_STRING = 'tektronix_awg5000_7000.mdd';
        %DEFAULT_TCPIP_STRING = 'TCPIP::128.33.89.153::4000::SOCKET';    
        DEFAULT_TCPIP_STRING = 'TCPIP::128.33.89.94::4000::SOCKET';
		TEK_DRIVER = 1;		%	Driver mode: At constructor, use Tektronix driver. 
		NATIVE_DRIVER = 2;	%	Driver mode: At constructor, use GPIB instruction set driver.
        LRG_WAVEFORM = 3	%	Hacked driver mode: See SENDWAVEFORMREAL.
    end
    
    properties (Access = public)
        % remember to add comments and restrict permissions to properties that
        % can't be set. 
        
		%% Device, group, and channel object for the AWG.
		deviceObj_awg;		%	Instrument object, either VISA or GPIB.
        buffer_size = 10;	%	Buffer size for sending floating point data.
        visa_string; 		%	VISA resource string for connecting to instrument.
        
		arbWfmObj_awg;		%	TekVISA group object: Waveform editing
		controlObj_awg;		%	TekVISA group object: Instrument Control
		utilityObj_awg;		%	TekVISA group object: Instrument Utilities
		triggerObj_awg;		%	TekVISA group object: Output Triggering
		chanObj_awg;		%	TekVISA group object: Channeling Properties
		arbSeqObj_awg;		%	TekVISA group object: Sequence Editing
        ctrlExtClockObj_awg;%	TekVISA group object: External Clock Properties	
        ctrlExtRefObj_awg;	%	TekVISA group object: External Reference Properties

        chan_1;             %	Instantiation of awg_channel object.
        chan_2;             %	Instantiation of awg_channel object.	
        chan_3;             %	Instantiation of awg_channel object.
        chan_4;             %	Instantiation of awg_channel object.
        
        %% Public class properties
        driver_mode;   
	
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
		runMode;   	%	Values: Continuous, Sequence, Gated, Triggered
		OperationState;  	%	 Values: 0 (stopped) 1 (waiting for trigger) 2 (running)
		refOsc; 	%	Values: Internal, External
		RepetitionRate;  	%	Values: <numeric>
		samplingRate;    	%	Values: <numeric>
        waveformDuration;   %   max length of all waveforms (not set on the device)
		
		% ArbSeq group object properties
		% Most of these remain unimplemented in GPIB.
		ArbSeqType;			
		CurrentPosition;	
		Length;	
		LengthMax;
		LengthMin;
		LoopCountMax;
		NumberSequencesMax;
			
		Clear;
		GotoIndex;
		GotoState;
		InfiniteLoop;
		Jump;
		JumpTargetIndex;
		JumpTargetType;		
		loopCount;
		WaitTriggerState
		waveformName;

		% Directory and memory operations
		current_working_directory;
        
        % Controlexternalclocksource group object properties
        DividerRate;

        % ControlexternalrefOsc group object properties 
        ControlExternalReferenceSourceType;
        ExternalRefVariableMultRate;
        Frequency;
        
    end
    
    properties (Access = private) 
		%driver_mode;
    end % end properties


    % Define methods
    %% Private methods
    methods (Access = private)
        function val = getInstrumentParam(obj, req_obj, optionString)
			val = get(req_obj, optionString);
        end    
            
		function val = checkInputandSet(obj, req_obj, optionString, check_val, value, checkMapObj, isnumerical)
            if not(checkMapObj.isKey(check_val))
               	error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
            end
            if isnumerical
                check_val = value;
            end
			set(req_obj, optionString, check_val);
			val = check_val;
        end
        
        function val = function_get_dispatch(obj, tek_string, gpib_string, read_write)
			if obj.driver_mode == obj.TEK_DRIVER
				val = eval(tek_string);
                return;
			elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, gpib_string);
                return;
			else
				error(['Invalid driver selection: ', obj.driver_mode]);
			end
        end
        
        function val = function_set_dispatch(obj, optionString, check_val, ...
                tek_string, gpib_string, isnumerical, value1)
            if (obj.driver_mode == obj.TEK_DRIVER)
                val = eval(tek_string);
                return;
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    val = false;
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    if isnumerical
                        check_val = value1;
                    end
                    gpib_string = [gpib_string, checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    val = check_val; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
        end

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
        function obj = Tek5014(driver_select)
            if nargin == 0
				driver_select = obj.NATIVE_DRIVER;
			end

            if (driver_select == obj.TEK_DRIVER) || (driver_select == obj.NATIVE_DRIVER)
				obj.driver_mode = driver_select;
			else 	
				error(['AWG Constructor: Invalid driver_select option: ', driver_select]);
            end
        end
        function obj = connect(obj,visaAddress)
            obj.driver_mode = 2;
            obj.init_connection(visaAddress);
        end
        function val = init_connection(obj, visa_string)
		%INIT_CONNECTION initiates a connection to the AWG over TCPIP using a VISA 
		% interface.
            import deviceDrivers.lib.awg_channel;
			% do error checking for visa_string
            if (isequal(visa_string,''))
                error(['Invalid VISA string for AWG5014: ', visa_string]);
            end
            obj.visa_string = visa_string;
			if (obj.driver_mode == obj.TEK_DRIVER)
				obj.deviceObj_awg = icdevice(obj.IVI_DRIVER_STRING, visa_string);
	            connect(obj.deviceObj_awg);
	            getTEST = get(obj.deviceObj_awg, 'Initialized');
	            if(isequal(getTEST,'on'))
% 	                disp('Great success!');

	                %awg_channel.setDevice(obj.chanObj_awg);
					obj.arbWfmObj_awg = get(obj.deviceObj_awg, 'Arbwfm');
					obj.arbSeqObj_awg = get(obj.deviceObj_awg, 'Arbseq');
					obj.controlObj_awg = get(obj.deviceObj_awg, 'Control');
					obj.utilityObj_awg = get(obj.deviceObj_awg, 'Utility');
					obj.triggerObj_awg = get(obj.deviceObj_awg, 'Trigger');
	                obj.chanObj_awg = get(obj.deviceObj_awg, 'Channel');
	                obj.ctrlExtClockObj_awg = get(obj.deviceObj_awg, 'Controlexternalclocksource');
	                obj.ctrlExtRefObj_awg = get(obj.deviceObj_awg, 'Controlexternalreferencesource');

	                obj.arbWfmObj_awg = obj.arbWfmObj_awg(1);
					obj.arbSeqObj_awg = obj.arbSeqObj_awg(1);
					obj.controlObj_awg = obj.controlObj_awg(1);
					obj.utilityObj_awg = obj.utilityObj_awg(1);
					obj.triggerObj_awg = obj.triggerObj_awg(1);
	                obj.chanObj_awg = obj.chanObj_awg(1);
	                obj.ctrlExtClockObj_awg = obj.ctrlExtClockObj_awg(1);
					obj.ctrlExtRefObj_awg = obj.ctrlExtRefObj_awg(1);

	                obj.chan_1 = awg_channel('CH1', obj.driver_mode, obj.chanObj_awg);
	                obj.chan_2 = awg_channel('CH2', obj.driver_mode, obj.chanObj_awg);
	                obj.chan_3 = awg_channel('CH3', obj.driver_mode, obj.chanObj_awg);
	                obj.chan_4 = awg_channel('CH4', obj.driver_mode, obj.chanObj_awg);
	                val = true;
					return;
	            else
	                val = false;
	                return; 
	            end
			elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                % Create a VISA-TCPIP object.
                obj.deviceObj_awg = instrfind('Type', 'visa-tcpip', 'RsrcName', visa_string, 'Tag', '');

                % Create the VISA-TCPIP object if it does not exist
                % otherwise use the object that was found.
                if isempty(obj.deviceObj_awg)
              %      obj.deviceObj_awg = visa('tek', visa_string);
                    obj.deviceObj_awg = gpib('ni', 0, visa_string);
                else
                    fclose(obj.deviceObj_awg);
                    obj.deviceObj_awg = obj.deviceObj_awg(1);
                end
                
                fopen(obj.deviceObj_awg);
				obj.chan_1 = awg_channel('1', obj.driver_mode, obj.deviceObj_awg);
                obj.chan_2 = awg_channel('2', obj.driver_mode, obj.deviceObj_awg);
                obj.chan_3 = awg_channel('3', obj.driver_mode, obj.deviceObj_awg);
                obj.chan_4 = awg_channel('4', obj.driver_mode, obj.deviceObj_awg);
				val = true;
%                 disp('Great success!');
			else
				error(['init_connection: Invalid driver mode:', obj.driver_mode]);
                val = false;
			end
        end

        function end_connection(obj)
		%END_CONNECTION terminates the connection to the AWG and deletes the AWG VISA object.
			if (obj.driver_mode == obj.TEK_DRIVER)
				invoke(obj.deviceObj_awg,'Close');
				disconnect(obj.deviceObj_awg);
            	delete(obj.deviceObj_awg);
%                 delete(obj.arbWfmObj_awg);
% 				delete(obj.controlObj_awg);
% 				delete(obj.utilityObj_awg);
% 				delete(obj.triggerObj_awg);
% 				delete(obj.chanObj_awg);
% 				delete(obj.arbSeqObj_awg);
% 		        delete(obj.ctrlExtClockObj_awg);
% 		        delete(obj.ctrlExtRefObj_awg);
			elseif (obj.driver_mode == obj.NATIVE_DRIVER)
				gpib_string = '';
				fprintf(obj.deviceObj_awg, gpib_string);
				fclose(obj.deviceObj_awg);
				delete(obj.deviceObj_awg);
			else
				error(['end_connection: Invalid driver mode:', obj.driver_mode]);
			end
% 			disp('Goodbye!');
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
            val = query(obj.deviceObj_awg, gpib_string);
            
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
			if not(isa(name, 'char'))
				error('');
			end
			name = ['"' name '"'];
            gpib_string = ['AWGControl:SSAVe ' name];
            fprintf(obj.deviceObj_awg, gpib_string);
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
			if not(isa(name, 'char'))
				error('');
			end
			name = ['"' name '"'];
            gpib_string = ['AWGControl:SREStore ' name];
            fprintf(obj.deviceObj_awg, gpib_string);
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
            if not(isa(waveform_name, 'char') || isa(file_name, 'char') ...
                   || isa(type, 'char'))
				error('');
            end
            waveform_name = ['"' waveform_name '"'];
            file_name = ['"' file_name '"'];
            typeMapObj = containers.Map({...
                'isf','tds','txt','txt8','txt10','wfm','pat','tfw'...
                },{'ISF', 'TDS', 'TXT', 'TXT8', 'TXT10', 'WFM', 'PAT', 'TFW'});
            type = typeMapObj(type);
            gpib_string = ['MMEMory:IMPort ' waveform_name ',' file_name ',' type];
            fprintf(obj.deviceObj_awg, gpib_string);
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
            fprintf(obj.deviceObj_awg, gpib_string);
        end
		
		%% Reset, stop, start methods for AWG.
        function reset(obj)
		%RESET returns the AWG to its default state.
			if (obj.driver_mode == obj.TEK_DRIVER)
				invoke(obj.utilityObj_awg,'Reset')
			elseif (obj.driver_mode == obj.NATIVE_DRIVER)
				fprintf(obj.deviceObj_awg, '*RST');
% 				disp('AWG reset.');
			else
				error(['reset: Invalid driver mode:', obj.driver_mode]);
			end
        end

		function val = calibrate(obj)
			%CALIBRATE performs an internal calibration on the instrument and returns the 
			%status
			%
			gpib_string = '*CAL?';
			val = query(obj.deviceObj_awg, gpib_string);
		end
        
        function run(obj)
            %RUN enables active output from the AWG. For a given channel
            % to output a waveform, however, it must be enabled (see
            % 'awg_channel.Enabled'.).
            gpib_string = 'AWGControl:RUN';
            fprintf(obj.deviceObj_awg, gpib_string);
        end

		function stop(obj)
			%STOP ends the output of a waveform or sequence
			gpib_string = 'AWGControl:STOP';
			fprintf(obj.deviceObj_awg, gpib_string);
        end
        
        function sync(obj)
            %SYNC ensures the first command is finished before executing
            % a second one. By default, this command is off and can
            % possibly be turned off by issuing a reset() command.
            gpib_string = '*OPC';
            fprintf(obj.deviceObj_awg, gpib_string);
        end
        
        %% Waveform methods 
        function sendWaveformReal(obj, name, buffer, wfm_option)
		%SENDWAVEFORMREAL sends a floating point (i.e., real) waveform buffer to the AWG.
		% It currently sends a row buffer but should work with column buffers.
		%
        %   Arguments:
        %       name        A name string 
        %       buffer      Row vector of an instrument
        %       wfm_option  If waveform is large, use TEKVISA driver with
        %                       boolean value.
        %
		%   Example:
		%       myAWG = AWG5014();
		%       myAWG.init_connection('visa_string');
		%       myAWG.sendWaveformReal('test_wfm', sin([0:pi/100:2*pi]));
        %
            if ~exist('wfm_option','var')
                wfm_option = 1;
            end
            if wfm_option
                obj.driver_mode = obj.LRG_WAVEFORM;
            end
            
            if (obj.driver_mode == obj.TEK_DRIVER)
				invoke(obj.arbWfmObj_awg,'SendWaveformReal',name, buffer);
            elseif (obj.driver_mode == obj.LRG_WAVEFORM)
                % disconnect from GPIB driver
                obj.driver_mode = obj.NATIVE_DRIVER;
                pause(1)
                obj.end_connection();
                pause(1)
                % connect using TEK IVI-COM driver
                obj.driver_mode = obj.TEK_DRIVER;
                obj.init_connection(obj.visa_string);
                
                % send waveform using TEK IVI-COM driver
                invoke(obj.arbWfmObj_awg,'SendWaveformReal',name, buffer);
                
                % end connection using TEK IVI-COM driver
                obj.end_connection();
                
                % reinitiate GPIB driver
                obj.driver_mode = obj.NATIVE_DRIVER;
                obj.init_connection(obj.visa_string);
			elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                name = ['"' name '"'];
                createWaveform(obj, name, 'REAL', length(buffer));
                g = obj.deviceObj_awg;
                g.ByteOrder = 'littleEndian'; 
                
                i = 0;
                while i <= (length(buffer)-1)
                    if (length(buffer)-i) < obj.buffer_size
                        blockSize = '1';
                        term_command = ',#15';
                        di = 1;
                    elseif (length(buffer)-i) >= obj.buffer_size
                        blockSize = num2str(obj.buffer_size);
                        num_chars = num2str(5*obj.buffer_size);
                        prefix = num2str(length(num_chars));
                        term_command = [',#' prefix num_chars];
                        di = obj.buffer_size;
                    else 
                        error('sendWaveformReal: Buffer out of bounds.');
                    end
                    myNum = num2hex(single(buffer(i+1:i+di)));
                    myNum = return_data(myNum);
                    
                    gpibCommand = ['WLISt:WAVeform:DATA ' name ',' num2str(i)...
                        ',' blockSize term_command];

                    g.EOIMode = 'off';                                    
                    fwrite(g,gpibCommand,'char');

                    g.EOIMode = 'on';  
                    fwrite(g, myNum); 
                    i = i+di;
                end
            else
				error(['end_connection: Invalid driver mode:', obj.driver_mode]);
            end
            
            function val = return_data(hex_array)
                if size(hex_array,1) == 1
                    val = [fliplr(split_num(hex_array)) 192];
                else
                    val = [[fliplr(split_num(hex_array(1,:))) 192] return_data(hex_array(2:end,:))];
                end
            end
            
            function val = split_num(hex_val)
            % SPLIT_NUM takes a hexadecimal string number and turns it into a decimal
            % number array
                if length(hex_val) == 2
                    val = hex2dec(hex_val);
                else
                    
                    val = [hex2dec(hex_val(1:2)) split_num(hex_val(3:end))];
                end
            end
        end
        
        function sendPartWaveformReal(obj, name, index, buffer)
		%SENDPARTWAVEFORMREAL allows piece-wise editing of a waveform on the AWG.
		%
		%	Remarks:
		%		1. Waveforms on the instrument are zero-indexed.
		%		2. Make sure the waveform already exists before using this 
		%			function.
            name = ['"' name '"'];
            g = obj.deviceObj_awg;
            g.ByteOrder = 'littleEndian'; 
            
            i = 0;
            j = index;
            while i <= (length(buffer)-1)
                if (length(buffer)-i) < obj.buffer_size
                    blockSize = '1';
                    term_command = ',#15';
                    di = 1;
                elseif (length(buffer)-i) >= obj.buffer_size
                    blockSize = num2str(obj.buffer_size);
                    num_chars = num2str(5*obj.buffer_size);
                    prefix = num2str(length(num_chars));
                    term_command = [',#' prefix num_chars];
                    di = obj.buffer_size;
                else 
                    error('sendPartWaveformReal: Buffer out of bounds.');
                end
                myNum = num2hex(single(buffer(i+1:i+di)));
                myNum = return_data(myNum);

                gpib_string = ['WLISt:WAVeform:DATA ' name ',' num2str(j)...
                    ',' blockSize term_command];

                g.EOIMode = 'off';                                    
                fwrite(g,gpib_string,'char');

                g.EOIMode = 'on';  
                fwrite(g, myNum); 
                i = i+di;
                j = j+di;
            end
            
            function val = return_data(hex_array)
                if size(hex_array,1) == 1
                    val = [fliplr(split_num(hex_array)) 192];
                else
                    val = [[fliplr(split_num(hex_array(1,:))) 192] return_data(hex_array(2:end,:))];
                end
            end
            
            function val = split_num(hex_val)
            % SPLIT_NUM takes a hexadecimal string number and turns it into a decimal
            % number array
                if length(hex_val) == 2
                    val = hex2dec(hex_val);
                else
                    
                    val = [hex2dec(hex_val(1:2)) split_num(hex_val(3:end))];
                end
            end    
        end
        
        function createWaveform(obj, name, type, size)
			if (obj.driver_mode == obj.TEK_DRIVER)
                invoke(obj.arbWfmObj_awg,'Create',name, type, size);                            
			elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                gpib_string = ['WLISt:WAVeform:NEW ', name , ',', num2str(size), ', ',type];
                fprintf(obj.deviceObj_awg, gpib_string);
            else
                error(['end_connection: Invalid driver mode:', obj.driver_mode]);
			end
        end
        function deleteWaveform(obj, name) 
			if (obj.driver_mode == obj.TEK_DRIVER)
                invoke(obj.arbWfmObj_awg,'Delete',name);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)

            else
                error(['end_connection: Invalid driver mode:', obj.driver_mode]);
			end
        end
        function val = getWaveformReal(obj, name, startIndex, blockSize)
			if (obj.driver_mode == obj.TEK_DRIVER)
                val = invoke(obj.arbWfmObj_awg,'GetWaveformReal',name);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                %startIndex = 0;
                %blockSize = 1;
                gpib_string = ['WLIST:WAVeform:DATA? ', name, ',', ... 
                    num2str(startIndex),',', num2str(blockSize)];
                % disp(gpib_string);
                fprintf(obj.deviceObj_awg, gpib_string);
                val = binblockread(obj.deviceObj_awg, 'single');
                %val = fscanf(obj.deviceObj_awg,'%3c %10c');

            else
                error(['end_connection: Invalid driver mode:', obj.driver_mode]);
			end
        end
        function val = getWaveformTimeStamp(obj, name)
			if (obj.driver_mode == obj.TEK_DRIVER)
                val = invoke(obj.arbWfmObj_awg,'TimeStamp',name);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
    
            else
                error(['end_connection: Invalid driver mode:', obj.driver_mode]);
			end
        end
        function sendMarkerData(obj, name, marker1, marker2, index)
            if not(isa(name, 'char')) || ...
                    (length(marker1) ~= length(marker2))
                error('');
            end
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                error(['end_connection: Invalid driver mode:', obj.driver_mode]);
            end
            
            % disconnect from GPIB driver
            obj.driver_mode = obj.NATIVE_DRIVER;
            pause(1)
            obj.end_connection();
            pause(1)
            % connect using TEK IVI-COM driver
            obj.driver_mode = obj.TEK_DRIVER;
            obj.init_connection(obj.visa_string);

            % send waveform using TEK IVI-COM driver
            invoke(obj.arbWfmObj_awg,'SendMarker',name, marker1, ... 
                marker2, index, length(marker1));

            % end connection using TEK IVI-COM driver
            obj.end_connection();

            % reinitiate GPIB driver
            obj.driver_mode = obj.NATIVE_DRIVER;
            obj.init_connection(obj.visa_string);
        end

    end % end public methods
    
    methods 
		%%	
		% property get accessors 
		%
		% property get functions for Trigger group object
		function val = get.Impedance(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'Impedance');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':IMPedance?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.InternalRate(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'InternalRate');                
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':TIMer?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.Level(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'Level');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':LEVel?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.Polarity(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'Polarity');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':POLarity?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.Slope(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'Slope');			
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':SLOPe?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.triggerSource(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'Source');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':SOURce?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.WaitValue(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.triggerObj_awg, 'WaitValue');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, ['TRIGger' seq_string(obj) ':WVALue?']);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		
		% property get functions for Control group object
		function val = get.ChannelCount(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.controlObj_awg, 'ChannelCount');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:CONFigure:CNUMber?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.ClockSource(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.controlObj_awg, 'ClockSource');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:CLOCk:SOURce?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.runMode(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.controlObj_awg, 'OperationMode');	
                warning('this property does not seem to query properly with TEKVISA driver')
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:RMODe?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.OperationState(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.controlObj_awg, 'OperationState');	
                error('this property does not seem to query properly with TEKVISA driver')
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:RSTate?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.refOsc(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.controlObj_awg, 'ReferenceSource');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'SOURce1:ROSCillator:SOURce?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.RepetitionRate(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.controlObj_awg, 'RepetitionRate');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:RRATe?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.samplingRate(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                temp = getInstrumentParam(obj, obj.controlObj_awg, 'SamplingRate');	
                val = str2double(temp);
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                temp = query(obj.deviceObj_awg, 'SOURce1:FREQuency?');
                val = str2double(temp);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.waveformDuration(obj)
            val = obj.waveformDuration;
	end		
		% property get functions for ArbSeq group object
		function val = get.ArbSeqType(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'ArbSeqType');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:SEQ:Type?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.CurrentPosition(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'CurrentPosition');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'AWGControl:SEQ:Position?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.Length(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'Length');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                val = query(obj.deviceObj_awg, 'SEQ:Length?');
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.LengthMax(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'LengthMax');
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
%                 val = query(obj.deviceObj_awg, 'SOURce1:FREQuency?');
%                 return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.LengthMin(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'LengthMin');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
%                 val = query(obj.deviceObj_awg, 'SOURce1:FREQuency?');
%                 return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.LoopCountMax(obj)
            if obj.driver_mode == obj.TEK_DRIVER
               	val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'LoopCountMax');	
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
%                 val = query(obj.deviceObj_awg, 'SOURce1:FREQuency?');
%                 return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
		end
		function val = get.NumberSequencesMax(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                val = getInstrumentParam(obj, obj.arbSeqObj_awg, 'NumberSequencesMax');		
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
%                 val = query(obj.deviceObj_awg, 'SOURce1:FREQuency?');
%                 return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        
        % property get functions for Controlexternalclocksource group
        % object
        function val = get.DividerRate(obj)
            if obj.driver_mode == obj.TEK_DRIVER
                return;
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = 'AWGControl:CLOCk:DRATe?';
                val = query(obj.deviceObj_awg, gpib_string);
                return;
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end

        % property get functions for Controlexternalreferencesource group object
        function val = get.ControlExternalReferenceSourceType(obj)
            if obj.driver_mode == obj.TEK_DRIVER
				val = getInstrumentParam(obj, obj.ctrlExtRefObj_awg, 'ControlExternalReferenceSourceType');					
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = 'SOURce1:ROSCillator:FREQuency?';
                val = query(obj.deviceObj_awg, gpib_string);
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
        function val = get.ExternalRefVariableMultRate(obj)
			val = getInstrumentParam(obj, obj.ctrlExtRefObj_awg, 'ExternalRefVariableMultRate');	
        end
        function val = get.Frequency(obj)
            if obj.driver_mode == obj.TEK_DRIVER
				val = getInstrumentParam(obj, obj.ctrlExtRefObj_awg, 'Frequency');	
            elseif obj.driver_mode == obj.NATIVE_DRIVER
                gpib_string = 'SOURce1:ROSCillator:TYPE?';
                val = query(obj.deviceObj_awg, gpib_string);
            else
                error(['Invalid driver selection: ', obj.driver_mode]);
            end
        end
		
		% property get functions for current group object
        function val = get.current_working_directory(obj)
			gpib_string = 'MMEMory:CDIRectory?';
            val = query(obj.deviceObj_awg, gpib_string);
        end
		
		
		%%
		% property set accessors 
		%
		% property get functions for Trigger group object
		function obj = set.Impedance(obj, value)
			check_val = ['TekFgenTriggerImpedance',value];
            optionString = 'Impedance';            
            checkMapObj = containers.Map({...
                'TekFgenTriggerImpedance500Ohms',...
                'TekFgenTriggerImpedance1KOhms'...
                },{'50','1k'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.Impedance = checkInputandSet(obj, obj.triggerObj_awg, optionString',...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':IMPedance ',checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.Impedance = check_val; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
        end
		function obj = set.InternalRate(obj, value)
			check_val = class(value);
            optionString = 'InternalRate';            
	        checkMapObj = containers.Map({...
	            'numeric','integer',...
	            'float','single','double'...
	            },{1,1,1,1,1});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.InternalRate = checkInputandSet(obj, obj.triggerObj_awg, optionString,...
                    check_val, value, checkMapObj, true);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':TIMer ', num2str(value)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.InternalRate = value; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.Level(obj, value)
			check_val = class(value);
            optionString = 'Level';            
	        checkMapObj = containers.Map({...
	            'numeric','integer',...
	            'float','single','double'...
	            },{1,1,1,1,1});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.Level = checkInputandSet(obj, obj.triggerObj_awg, optionString,...
                    check_val, value, checkMapObj, true);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':LEVel ', num2str(value)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.Level = check_value; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.Polarity(obj, value)
			check_val = ['TekFgenPolarity',value];
            optionString = 'Polarity';            
	        checkMapObj = containers.Map({...
	            'TekFgenPolarityPositive',...
	            'TekFgenPolarityNegative'...
	            },{'POSitive', 'NEGative'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.Polarity = checkInputandSet(obj, obj.triggerObj_awg, optionString,...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':POLarity ', checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.Polarity = check_value; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.Slope(obj, value)
			check_val = ['TekFgenTriggerSlope',value];
            optionString = 'Slope';            
	        checkMapObj = containers.Map({...
	            'TekFgenTriggerSlopePositive',...
	            'TekFgenTriggerSlopeNegative'...
	            },{'POSitive', 'NEGative'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.Slope = checkInputandSet(obj, obj.triggerObj_awg, optionString,...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':SLOPe ', checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.Slope = check_value; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.triggerSource(obj, value)
			check_val = value;
            optionString = 'Source';
	        checkMapObj = containers.Map({...
	            'Internal','External',...
                'Int', 'Ext'
	            },{'INTernal','EXTernal','INTernal','EXTernal'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.Source = checkInputandSet(obj, obj.triggerObj_awg, optionString,...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':SOURce ', checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    %obj.Source = check_val;
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.WaitValue(obj, value)
			check_val = ['TekFgenWaitValue',value];
            optionString = 'WaitValue';
	        checkMapObj = containers.Map({...
	            'TekFgenWaitValueFirst',...
	            'TekFgenWaitValueLast'...
	            },{1,1});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.WaitValue = checkInputandSet(obj, obj.triggerObj_awg, optionString,...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['TRIGger' seq_string(obj) ':WVALue ', checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.WaitValue = check_value; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		

		% property get functions for Control group object
		function obj = set.ClockSource(obj, value)
			check_val = ['TekFgenClockSource',value];
            optionString = 'ClockSource';
            checkMapObj = containers.Map({...
                'TekFgenClockSourceInternal',...
                'TekFgenClockSourceExternal'...
                },{'INTernal','EXTernal'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.ClockSource = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['AWGControl:CLOCk:SOURce ', checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.ClockSource = check_value; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
        function obj = set.runMode(obj, value)
            % 			check_val = ['TekFgenOperationMode',value];
            %             optionString = 'OperationMode';
            %             checkMapObj = containers.Map({...
            %                'TekFgenOperationModeContinuous',...
            %                'TekFgenOperationModeSequence',...
            %                'TekFgenOperationModeGated',...
            %                'TekFgenOperationModeTriggered'...
            %                 },{'CONTinuous', 'SEQuence', 'GATed', 'TRIGgered'});
            checkMapObj = containers.Map({...
                'TRIG','TRIGGERED','triggered','Triggered',...
                'SEQ','SEQUENCE','sequence','Sequence',...
                'GAT','GATED','gated','Gated',...
                'CONT','CONTINUOUS','continuous','Continuous'},...
                {'TRIG','TRIG','TRIG','TRIG',...
                'SEQ','SEQ','SEQ','SEQ',...
                'GAT','GAT','GAT','GAT',...
                'CONT','CONT','CONT','CONT'});
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.runMode = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                    check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(value))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['AWGControl:RMODe ',checkMapObj(value)];
%                     obj.Write(gpib_string);
                    fprintf(obj.deviceObj_awg, gpib_string);
%                     obj.runMode = check_val; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.refOsc(obj, value)
			check_val = ['TekFgenReferenceSource',value];
            optionString = 'ReferenceSource';            
            checkMapObj = containers.Map({...
                'TekFgenReferenceSourceInternal',...
                'TekFgenReferenceSourceExternal'...
                },{'INTernal','EXTernal'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.refOsc = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                	check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', value]);
                else
                    gpib_string = ['SOURce1:ROSCillator:SOURce ',checkMapObj(check_val)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.refOsc = check_val; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.RepetitionRate(obj, value)
			check_val = class(value);
            optionString = 'RepetitionRate';            
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.RepetitionRate = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                    check_val, value, checkMapObj, true);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val) || (value > 0))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                else
                    gpib_string = ['AWGControl:RRATe ', num2str(value)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.RepetitionRate = check_val; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
		end
		function obj = set.samplingRate(obj, value)
			check_val = class(value);
            optionString = 'SamplingRate';            
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});

            if (obj.driver_mode == obj.TEK_DRIVER)
                obj.samplingRate = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                    check_val, value, checkMapObj, true);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val)) || (value < 10^7) || (value > 10^10)
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                else
                    gpib_string = ['SOURce1:FREQuency ', num2str(value)];
                    fprintf(obj.deviceObj_awg, gpib_string);
                    obj.samplingRate = check_val; 
                end
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
        end
        function obj = set.waveformDuration(obj, value)
            if isscalar(value) && isnumeric(value)
                obj.waveformDuration = value;
            else
                error('waveformDuraiton must be a numeric scalar')
            end
        end
        % property set functions for Arbseq group object
        function obj = set.Length(obj, value)
			check_val = class(value);
            optionString = 'Length';            
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
            obj.Length = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                check_val, value, checkMapObj, true);
        end
        
        % invoke set methods for Arbseq group object
        function set.Clear(obj, value)
            optionString = 'Clear';   
			if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
			end         
            invoke(obj.arbSeqObj_awg, optionString);
            obj.Clear = value;
        end
        function set.GotoIndex(obj, value)
            optionString = 'GotoIndex';   
            if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
            end
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.GotoState = true;
        end
        function set.GotoState(obj, value)
            optionString = 'GotoState';  
			if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
			end          
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.GotoState = true;
        end
        function set.InfiniteLoop(obj, value)
            optionString = 'InfiniteLoop';   
			if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
			end         
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.InfiniteLoop = true;
        end
        function set.Jump(obj, value)
            optionString = 'Jump';         
			if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
			end   
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.Jump = true;
        end
        function set.JumpTargetIndex(obj, value)
            optionString = 'JumpTargetIndex';   
			if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
			end         
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.JumpTargetIndex = true;
        end
        function set.JumpTargetType(obj, value)
            optionString = 'JumpTargetType'; 
			if obj.driver_mode ~= obj.TEK_DRIVER
				error('Object must be NATIVE_DRIVER to use this function.');
			end           
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.JumpTargetType = true;
        end
        function set.loopCount(obj, value)
			check_val = class(value);
            optionString = 'LoopCount';            
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
            if (obj.driver_mode == obj.TEK_DRIVER)
	            invoke(obj.arbSeqObj_awg, optionString, value);
	            obj.loopCount = true;
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val)) || (value > 65536) || (value < 1)
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                end
                gpib_string = ['SEQuence:ELEMent', num2str(obj.sequenceElement), ...
                 		':LOOP:COUNt ', num2str(value)];
                fprintf(obj.deviceObj_awg, gpib_string);
                obj.loopCount = value; 
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
        end
        function set.WaitTriggerState(obj, value)
            optionString = 'WaitTriggerState';            
            invoke(obj.arbSeqObj_awg, optionString, value);
            obj.WaitTriggerState = true;
        end
        function set.waveformName(obj, value)
            obj.waveformName = true;
            if (obj.driver_mode == obj.TEK_DRIVER)
	            invoke(obj.arbSeqObj_awg, optionString, value{1}, value{2});
	            obj.waveformName = true;
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                fprintf(obj.deviceObj_awg, 'SEQuence:LENGth 1');
                gpib_string = ['SEQuence:ELEMent', num2str(obj.sequenceElement), ...
                 		':WAVeform', num2str(value{1}),' ', value{2}];
                fprintf(obj.deviceObj_awg, gpib_string);
                obj.waveformName = value; 
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
        end
        
        % property set functions for Controlexternalclocksource group
        % object
        function obj = set.DividerRate(obj, value)
			check_val = class(value);
            optionString = 'DividerRate';            
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
            if (obj.driver_mode == obj.TEK_DRIVER)
	            obj.DividerRate = checkInputandSet(obj, obj.controlObj_awg, optionString,...
                    check_val, value, checkMapObj, true);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val)) || ...
					(value == 1) || (value == 2) || (value == 4) || (value == 8)
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                end
                gpib_string = ['AWGControl:CLOCk:DRATe ' num2str(value)];
                fprintf(obj.deviceObj_awg, gpib_string);
                obj.DividerRate = value; 
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end
        end
        
        % property get functions for Controlexternalreferencesource group
        % object
        function obj = set.ControlExternalReferenceSourceType(obj, value)
			optionString = 'ControlExternalReferenceSourceType';   
			check_val = ['TekFgenRefType',value];
            checkMapObj = containers.Map({...
                'TekFgenRefTypeFixed',...
                'TekFgenRefTypeVariable'...
                },{'FIXed', 'VARiable'});
            if (obj.driver_mode == obj.TEK_DRIVER)
	            obj.ControlExternalReferenceSourceType = checkInputandSet(obj, obj.controlObj_awg,... 
	                optionString, check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                end
                gpib_string = ['SOURce1:ROSCillator:TYPE ' checkMapObj(check_val)];
                fprintf(obj.deviceObj_awg, gpib_string);
                obj.ControlExternalReferenceSourceType = value; 
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end	
        end
        function obj = set.ExternalRefVariableMultRate(obj, value)
			check_val = class(value);
            optionString = 'ExternalRefVariableMultRate';            
            checkMapObj = containers.Map({...
                'numeric','integer',...
                'float','single','double'...
                },{1,1,1,1,1});
            obj.ExternalRefVariableMultRate = checkInputandSet(obj, obj.controlObj_awg, ...
                optionString, check_val, value, checkMapObj, true);
		end
        function obj = set.Frequency(obj, value)
			optionString = 'Frequency';  
			check_val = ['TekFgenRefFrequency',value];          
            checkMapObj = containers.Map({...
                'TekFgenRefFrequency10MHz',...
                'TekFgenRefFrequency20MHz',...
                'TekFgenRefFrequency100MHz'...
                },{'10MHz', '20MHz', '100MHz'});
            
            if (obj.driver_mode == obj.TEK_DRIVER)
				obj.Frequency = checkInputandSet(obj, obj.controlObj_awg, optionString,...
	                check_val, value, checkMapObj, false);
            elseif (obj.driver_mode == obj.NATIVE_DRIVER)
                if not(checkMapObj.isKey(check_val))
                    error(['AWG Property: ', 'Invalid ', optionString, ' value: ', num2str(value)]);
                end
				gpib_string = ['SOURce1:ROSCillator:FREQuency ' checkMapObj(check_val)];
                fprintf(obj.deviceObj_awg, gpib_string);
                obj.Frequency = value; 
            else
                error([optionString, ': Invalid driver mode:', obj.driver_mode]);
            end	
		end
		
		% property get functions for current group object
        function set.current_working_directory(obj, value)
			value = ['"' value '"'];
			gpib_string = ['MMEMory:CDIRectory ' value ];
            fprintf(obj.deviceObj_awg, gpib_string);
        end
		
    end % end methhods
end % end class definition

