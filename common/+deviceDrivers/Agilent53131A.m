classdef (Sealed) Agilent53131A < deviceDrivers.lib.GPIB
%Agilent53131A is an instrument wrapper class for the Agilent 53131A Universal Counter. Like
% the other instrument classes, it provides an interface for interacting with device while 
% abstracting away the GPIB instruction set.
%
%	Example:
%		import dev.DAObject.GPIB.Agilent53131A;
%       myCounter = Agilent53131A();
%       myCounter.DeviceOpen(4);
%		myCounter.reset();
%       myCounter.configure('period', false);
%       myCounter.initiate;
%       myCounter.fetch();
%       myCounter.delete();
%       
%	Remarks: 
%		1. Use the 'configure' method to create measurements.
%			
%	See also .
%	
%	References:
%		[1] Programming Guide: Agilent 53131A/132A 225MHz Universal Counter 
%			Agilent Technologies
%
%	Author: Bhaskar Mookerji, BU-Q @ BBN
%	Date: 14 July 2009
%	$Revision: $  $Date: $

    % Define properties
    properties (Constant = true)
        REVISION_NUMBER = 0.01; 		%
    end

	properties (Access = public)
		deviceObj_ag53131A;				% 
		
		input_chan_value = '1';			% 
		joint_chan_value = '1,2';		%
		source_chan_value = '(@1)'; 	%
		
		% input channel conditioning
		% trigger
		trigger_auto;					%   Values: on, off
		trigger_level;					%   Values: <numeric>
		trigger_slope;					%   Values: positive, negative
		trigger_sensitivity;			%   Values: high, medium, low
		% channel measurement
		initiate_auto;					%   Values: on, off
		initiate_continuous;			%   Values: on, off
		
		% input parameters
		input_attenuation;				%   Values: x10, x1
		input_coupling;					%   Values: AC, DC
		input_filter_frequency;			%   Values: 
		input_filter_enable				%   Values: on, off
		input_impedance;				%   Values: 50Ohm, 1MOhm
		
		% oscillator
		source_oscillator;				%   Values: internal, external, auto_on, auto_off
						
		% parameters for gate and external arming
		% frequency, period, and ratio
		freq_arm_start;					%   struct tags: 'slope'|'source' 
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, external
        freq_arm_stop;                  %   struct tags: 'slope'|'source'
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, external,
                                        %       timer, digits.    
		phase_arm_start;				%   struct tags: 'slope'|'source'
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, external
		tot_arm_start;					%   struct tags: 'slope'|'source'
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, external    
        tot_arm_stop;					%   struct tags: 'slope'|'source'        
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, external,
                                        %       timer, digits.            
		tint_arm_start;					%   struct tags: 'slope'|'source' 
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, external        
        tint_arm_stop;                  %   struct tags: 'slope'|'source' 
                                        %   'slope' Values: positive, negative
                                        %   'source' Values: immediate, timer            
	end
	
	methods (Access = private)
		function function_string = meas_dispatch(obj, function_select, toggle_query, value1, value2)
            switch lower(function_select)
				case 'duty_cycle'
					gpib_string = ':DCYCle';
				case 'fall_time'
					gpib_string = ':FTIMe';				
				case 'frequency'
					gpib_string = ':FREQuency';
				case 'frequency_ratio'
					gpib_string = ':FREQuency:RATio';
				case 'maximum'
					gpib_string = ':MAXimum';
				case 'minimum'	
					gpib_string = ':MINinum';
				case 'neg_width'
					gpib_string = ':NWIDth';
				case 'period'
					gpib_string = ':PERiod';
				case 'phase'
					gpib_string = ':PHASe';
				case 'p2peak'	
					gpib_string = ':PTPeak';
				case 'pulse_width'
					gpib_string = ':PWIDTH';
				case 'rise_time'
					gpib_string = ':RTIMe';
				case 'time_interval'
					gpib_string = ':TINTerval';
				case 'totalize_cont'
					gpib_string = ':TOTalize:CONTinuous';
				case 'totalize_timed'
					gpib_string = ':TOTalize:TIMed';
				otherwise
					error(['Invalid measurement function: ' function_select]);
            end
            
			function_string = [gpib_string return_q(nargin)];
			
			function val = return_q(num_args)
                if toggle_query == true
					val = [gpib_string '?'];
				elseif toggle_query == false
                    switch num_args
                        case 3
                            val = [' ' obj.source_chan_value];
                        case 4 
                            val = [' ' value1 ' ' obj.source_chan_value];
                        case 5
                            val = [' ' value1 ',' value2 ' ' obj.source_chan_value];
                        otherwise
                            error(['meas_dispatch: Invalid number of arguments: ' nargin]);
                    end
				else 
					error(['meas_dispatch: Invalid toggle_query: ' toggle_query]);
                end
            end
        end
    end
        
   methods (Access = public)
	function obj = Agilent53131A()
        end
        		
        %% Deprecated instrument connection functions.
        function init_conection(obj, visa_string)
			% Create a VISA-TCPIP object.
            obj.deviceObj_ag53131A = instrfind('Type', 'gpib', 'RsrcName', visa_string, 'Tag', '');

            % Create the VISA-GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.deviceObj_ag53131A)
                obj.deviceObj_ag53131A = visa('ni', visa_string);
            else
                fclose(obj.deviceObj_ag53131A);
                obj.deviceObj_ag53131A = obj.deviceObj_ag53131A(1);
            end

			fopen(obj.deviceObj_ag53131A);
			disp('Great success!');
		end
		
		function end_connection(obj)
			if isempty(obj.deviceObj_ag53131A)
				error('Nonexistent instrument object for Agilent 53131A counter.');
			end
			
			gpib_string = '';
			obj.write(gpib_string);
			fclose(obj.deviceObj_ag53131A);
			delete(obj.deviceObj_ag53131A);
        end
		
        %% Agilent Counter Utilities
		function reset(obj)
            %   Why does the following line not work?
            %       Error:
            %       "@" Within a method, a superclass method of the same
            %       name is called by saying method@superclass.  The left
            %       operand of "@" must be the method name.
            %   write@dev.DAObject.GPIB.GPIBWrapper(obj,'*RST')
            
            %	obj.write('*RST');
            obj.write('*RST');
			disp('Agilent 53131A reset.');
        end
        
        function complete_reset(obj)
            %RESET_AND_CLEAR
            %
            %   Remarks:
            %   1. See page 3-38 in Agilent Counter Manual.
            %
            reset(obj);
            obj.write('*CLS');          % Reset the counter
            obj.write('*SRE 0');        % Clear event registers and error queue    
            obj.write('*ESE 0');        % Clear event status enable register
            obj.write(':STAT:PRES');    % Preset enable registers and transition
                                        %   filters for Operation and 
                                        %   Questionable status structures.
        end
        
        function holdoff(obj)
            %HOLDOFF prevents device from executing further commands
            % until the measurement cycle transitions from measuring
            % to idle.
            %
            %   Remarks:
            %       1. The only way to cancel the hold off is to 
            %           power cycle the counter or issue the rest command.          
            obj.write('*WAI');
        end
        
        function recall_config(obj, val)
            %RECALL_CONFIG restores the state of the instrument from a copy 
            % stored in nonlocal memory. The current state is stored at 0.
            %
            %   Arguments:
            %       val     An integer between 0 and 20
            %
            if not(isnumeric(val))
                error('');
            end
            
            if (val > 20) || (val < 0)
                error('');
            end
            gpib_string = ['*RCL ' num2str(val)];
            obj.write(gpib_string);
        end
        
        function save_config(obj, val)
            %SAVE_CONFIG saves the state of the instrument to a copy 
            % stored in nonlocal memory.
            %
            %   Arguments:
            %       val     An integer between 0 and 20
            %
            if not(isnumeric(val))
                error('');
            end
            
            if (val > 20) || (val < 0)
                error('');
            end
            gpib_string = ['*SAV ' num2str(val)];
            obj.write(gpib_string);
        end
        
        function val = last_error(obj)
            %LAST_ERROR returns the last error experienced via the counter.
            %
            %   Returns:
            %      val  A string with error code and description.
            %
            val = obj.query(':SYST:ERR?');
        end
        
        function optimize_throughput(obj)
            %OPTIMIZE_THROUGHPUT sets the counter to transfer data at the
            %fastest possible rate.
        end
		
        %% Measurement Configuration
		function val = configure(obj, function_select, toggle_query, value1, value2)
			%CONFIGURE configures the counter to carry out a particular measurement given 	
			%	an option, a possible parameter, and, if necessary, a channel. Following 
			%	configuration, you can use either READ or INITIATE/FETCH to carry out 
			%	measurements with the instrument.
            %
			%   Remarks:
            %   1. Currently, configure accepts up to two arguments for
            %   reference and expected value arguments, as described on
            %   page 4-59 in the Agilent Counter model. The dispatch
            %   function used here _does not_ check the value of your
            %   arguments. For now, please see values in manual and use
            %   them as strings.
            %   
			%	Argument Options:
            %       function_select:
			%           'duty_cycle'
			%           'fall_time'
			%           'frequency'
			%           'frequency_ratio'
			%           'maximum'
			%           'minimum'	
			%           'n_width'
			%           'period'
			%           'phase'
			%           'p2peak'	
			%           'pulse_width'
			%           'rise_time'
			%           'time_interval'
			%           'totalize_cont'
			%           'totalize_timed'
            %       toggle_query:
            %           read            Returns last configured function     
            %           write           Configures device
            %
            %       value1,2            Appropriate configuration value
            %                           (string)
            %   Returns:
            %   
            switch nargin
                case 3
                    if strcmp(toggle_query, 'read')
                        gpib_string = ':CONFigure?';
                        val = obj.query(gpib_string);
                        return;
                    elseif strcmp(toggle_query, 'write')
                        gpib_string = [':CONFigure' ...
                            meas_dispatch(obj, function_select, false)];
                    else
                        error('');
                    end
                case 4
                    gpib_string = [':CONFigure' ...
                        meas_dispatch(obj, function_select, toggle_query, value1)];
                case 5
                    gpib_string = [':CONFigure' ...
                        meas_dispatch(obj, function_select, toggle_query, value1, value2)];
                otherwise
                    error('');
            end
			obj.write(gpib_string);
            val = true;
		end
		
		function initiate(obj)
			obj.write(':INITiate');
		end
		
		function val = measure(obj)
			%MEASURE configures and carries out a particular measurement given 	
			%	an option, a possible parameter, and, if necessary, a channel. 
			%
			%	Options:
			%	  	'duty_cycle'
			%		'fall_time'
			%		'frequency'
			%		'frequency_ratio'
			%		'maximum'
			%		'minimum'	
			%		'n_width'
			%		'period'
			%		'phase'
			%		'p2peak'	
			%		'pulse_width'
			%		'rise_time'
			%		'time_interval'
			%		'totalize_cont'
			%		'totalize_timed'
            switch nargin
                case 3
                    gpib_string = [':MEASure ' ...
                        meas_dispatch(obj, function_select, toggle_query)];
                case 4
                    gpib_string = [':MEASure ' ...
                        meas_dispatch(obj, function_select, toggle_query, value1)];
                case 5
                    gpib_string = [':MEASure ' ...
                        meas_dispatch(obj, function_select, toggle_query, value1, value2)];
                otherwise
                    error('');
            end
			val = obj.query(gpib_string);
		end
		
		function val = sense(obj, option)
			%SENSE configures and carries out a particular measurement given 	
			%	an option, a possible parameter, and, if necessary, a channel. 
			%
			%	Options:
			%	  	'duty_cycle'
			%		'fall_time'
			%		'frequency'
			%		'frequency_ratio'
			%		'maximum'
			%		'minimum'	
			%		'n_width'
			%		'period'
			%		'phase'
			%		'p2peak'	
			%		'pulse_width'
			%		'rise_time'
			%		'time_interval'
			%		'totalize_cont'
			%		'totalize_timed'
			gpib_string = ':SENSe ';
			val = obj.query(gpib_string);
		end
		
		function val = read_instr(obj)
			%READ_INSTR initiates a measurement and queries the result.
			val = obj.query(':READ?');
		end
		
		function result = fetch(obj)
			%FETCH queries a measurement after it has been initiated
			%(either by CON)
            %
            %   Returns: 
            %       result      A double for the current measurement
            %                     result.
			temp = obj.query(':FETCH?');
            result = str2double(temp);
		end
		
		function abort(obj)
            %ABORT ends the current measurement routine.
			obj.write(':ABORt');
		end
		
		function enableFastThroughput(obj)
		end
	end
	
	methods
        %% Property 'get' accessors   
	 	% input channel conditioning
		% trigger
		function val = get.trigger_auto(obj)
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ':LEVel:AUTO?'];
			val = obj.query(gpib_string);
		end	
		function val = get.trigger_level(obj)
			gpib_string = [':SENSe:EVENTt' obj.input_chan_value ' :LEVel?'];
			val = obj.query(gpib_string);
		end
		function val = get.trigger_slope(obj)
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ':SLOPe?'];
			val = obj.query(gpib_string);
		end
		function val = get.trigger_sensitivity(obj)
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ':HYSTeresis:RELative?'];
			val = obj.query(gpib_string); 
		end  
	
		% channel measurement
		function val = get.initiate_auto(obj)
			gpib_string = ':INITiate:AUTO?';
			val = obj.query(gpib_string);
		end
		function val = get.initiate_continuous(obj)
			gpib_string = ':INITiate:CONTinuous?';
			val = obj.query(gpib_string);
		end 
		
		% input parameters
		function val = get.input_attenuation(obj)
			gpib_string = [':INPut' obj.input_chan_value ':ATTenuation?'];
			val = obj.query(gpib_string);
		end
		function val = get.input_coupling(obj)
			gpib_string = [':INPut' obj.input_chan_value ':COUPling?'];
			val = obj.query(gpib_string);
		end
		function val = get.input_filter_enable(obj)
			gpib_string = [':INPut' obj.input_chan_value ':STATe?'];
			val = obj.query(gpib_string);
		end
		function val = get.input_filter_frequency(obj)
			gpib_string = [':INPut' obj.input_chan_value ':STATe:FREQuency?'];
			val = obj.query(gpib_string);
		end
		function val = get.input_impedance(obj)
			gpib_string = [':INPut' obj.input_chan_value ':IMPedance?'];
			val = obj.query(gpib_string);
        end
		
		% oscillator
		function val = get.source_oscillator(obj)
			gpib_string = [':SENSE:ROSCillator:SOURce?'];
			val = obj.query(gpib_string);
        end
		
        % arming functions
        function val = get.freq_arm_start(obj)
            gpib_string = ':SENSe:FREQuency:ARM:STARt';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end
        function val = get.freq_arm_stop(obj)
            gpib_string = ':SENSe:FREQuency:ARM:STOP';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end
        function val = get.phase_arm_start(obj)
            gpib_string = ':SENSe:PHASe:ARM:STARt';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end
        function val = get.tot_arm_start(obj)
            gpib_string = ':SENSe:TOTalize:ARM:STARt';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end
        function val = get.tot_arm_stop(obj)
            gpib_string = ':SENSe:TOTalize:ARM:STOP';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end
        function val = get.tint_arm_start(obj)
            gpib_string = ':SENSe:TINTerval:ARM:STARt';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end		
        function val = get.tint_arm_stop(obj)
            gpib_string = ':SENSe:TINTerval:ARM:STOP';
            gpib_string0 = [gpib_string ':SLOPe?'];
            gpib_string1 = [gpib_string ':SOURce?'];
			val = struct('slope', obj.query(gpib_string0),...
			 'source', obj.query(gpib_string1));
        end		
        
		
		%% Property set accessors
		%
		function obj = set.trigger_auto(obj, value)
            checkMapObj = containers.Map({'on', 'off'},{'ON','OFF'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ...
                ':LEVel:AUTO ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.trigger_auto = value;
		end
		function obj = set.trigger_level(obj, value)
            check_val = class(value);
            checkMapObj = containers.Map({...
	            'numeric','integer',...
	            'float','single','double'...
	            },{1,1,1,1,1});
            if not(checkMapObj.isKey(check_val))
                error('');
            end
            
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ...
                ':LEVel ' num2str(value)];
			obj.write(gpib_string);
			obj.trigger_level = value;
		end
		function obj = set.trigger_slope(obj, value)
            checkMapObj = containers.Map({'positive', 'negative'}, ...
                {'POSitive','NEGative'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ...
                ':SLOPe ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.trigger_slope = value;
		end
		function obj = set.trigger_sensitivity(obj, value)
            checkMapObj = containers.Map({'low', 'medium', 'high'},...
                {'100','50', '1'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':SENSe:EVENt' obj.input_chan_value ...
                ':HYSTeresis:RELative ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.trigger_sensitivity = value;
		end		
		
		function obj = set.initiate_auto(obj, value)
            checkMapObj = containers.Map({'on', 'off'},{'ON','OFF'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':INITiate:AUTO ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.initiate_auto = value;
		end
		function obj = set.initiate_continuous(obj, value)
            checkMapObj = containers.Map({'on', 'off'},{'ON','OFF'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':INITiate:CONTinuous ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.initiate_continuous = value;
		end
		
		function obj = set.input_attenuation(obj, value)
            checkMapObj = containers.Map({'x1', 'x2'},{'1','10'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':INPut' obj.input_chan_value ...
                ':ATTenuation ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.input_attenuation = value;
		end
		function obj = set.input_coupling(obj, value)
            checkMapObj = containers.Map({'AC', 'DC'},{'AC','DC'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':INPut' obj.input_chan_value ...
                ':COUPling ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.input_coupling = value;
		end
		function obj = set.input_filter_enable(obj, value)
            checkMapObj = containers.Map({'on', 'off'},{'ON','OFF'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':INPut' obj.input_chan_value ... 
                ':STATe ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.input_filter_enable = value;
		end
		function obj = set.input_impedance(obj, value)
            checkMapObj = containers.Map({'50Ohm', '1MOhm'},{'50','1E6'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':INPut' obj.input_chan_value ... 
                ':IMPedance ' checkMapObj(value)];
			obj.write(gpib_string);
			obj.input_impedance = value;
		end     
        
        % oscillator
		function set.source_oscillator(obj, value)
            % values associated with keys typically don't have spaces
            %   Note however, that some of the values have spaces and some
            %   have colons. Therefore, the space is omitted in the
            %   gpib_string prefix and included appropriately in the Map
            %   value.
            checkMapObj = containers.Map(...
                {'internal', 'external', 'auto_on', 'auto_off'}, ...
                {' INTernal',' EXTernal', ':AUTO ON', ':AUTO OFF'});
            if not(checkMapObj.isKey(value))
                error('');
            end
            
			gpib_string = [':SENSE:ROSCillator:SOURce' checkMapObj(value)];
			obj.write(gpib_string);
			obj.source_oscillator = value;
        end
        
        % Gate command accessors
        function set.freq_arm_start(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:FREQuency:ARM:STARt';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map({'immediate', 'external'},...
                    {'IMMediate','EXTernal'});
            else
                error('');
            end

            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];
            obj.write(gpib_string);
            obj.freq_arm_start = value;
        end
        function set.freq_arm_stop(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:FREQuency:ARM:STOP';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map(...
                    {'immediate', 'timer', 'digits', 'external'},...
                    {'IMMediate','TIMer', 'DIGits', 'EXTernal'});
            else
                error('');
            end
            
            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];
            obj.write(gpib_string);
            obj.freq_arm_stop = value;
        end
        function set.phase_arm_start(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:PHASe:ARM:STARt';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map({'immediate', 'external'},...
                    {'IMMediate','EXTernal'});
            else
                error('');
            end

            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];
            obj.write(gpib_string);
            obj.phase_arm_start = value;
        end
        function set.tot_arm_start(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:TOTalize:ARM:STARt';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map({'immediate', 'external'},...
                    {'IMMediate','EXTernal'});
            else
                error('');
            end

            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];
            obj.write(gpib_string);
            obj.tot_arm_start = value;
        end
        function set.tot_arm_stop(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:TOTalize:ARM:STOP';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map(...
                    {'immediate', 'timer', 'digits', 'external'},...
                    {'IMMediate','TIMer', 'DIGits', 'EXTernal'});
            else
                error('');
            end
            
            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];
            obj.write(gpib_string);
            obj.tot_arm_stop = value;
        end
        function set.tint_arm_start(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:TINTerval:ARM:STARt';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map(...
                    {'immediate', 'external'}, {'IMMediate', 'EXTernal'});
            else
                error('');
            end
            
            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];

            obj.write(gpib_string);
            obj.tint_arm_start = value;
        end		
        function set.tint_arm_stop(obj, value)
            if not(isa(value, 'struct'))
                error('');
            end
            
            gpib_string = ':SENSe:TINTerval:ARM:STOP';
            names = fieldnames(value);
            if strcmp(names{1}, 'slope')
                gpib_string = [gpib_string ':SLOPe '];
                checkMapObj = containers.Map({'positive', 'negative'},...
                    {'POSitive','NEGative'});
            elseif strcmp(names{1}, 'source')
                gpib_string = [gpib_string ':SOURce '];
                checkMapObj = containers.Map(...
                    {'immediate', 'timer'}, {'IMMediate','TIMer'});
            else
                error('');
            end
            
            if not(checkMapObj.isKey(value.(names{1})))
                error('');
            end
            
            gpib_string = [gpib_string checkMapObj(value.(names{1}))];

            obj.write(gpib_string);
            obj.tint_arm_stop = value;
        end		
	end % end method definitions 
end % end class definition
