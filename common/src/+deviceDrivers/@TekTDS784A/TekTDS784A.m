classdef TekTDS784A < deviceDrivers.lib.GPIB
%TekTDS784A
%
%
% Author(s): wkelly
% 02/10/2010



    % Class-specific constant properties
    properties (Constant = true)

    end % end constant properties


    % Class-specific private properties
    properties (Access = private)

    end % end private properties


    % Class-specific public properties
    properties (Access = public)

    end % end public properties


    % Device properties correspond to instrument parameters
    properties (Access = public)
        identity;
        model_number = '784A'; %{644A, 784A}

        channel_on; % sets or queries which channels are currently on
        channel_control; % sets or queries wich channel is currently being controlled
                         % I'm not sure if it's necessary to ever use this
        
        record_length; % number of points in a full waveform
        horz_scale; % time in seconds coresponding to 50 points of a waveform
        trigger_position; % relative position of trigger on horizontal trace (0-100%)
        
        ch1 % repository for all ch1 vertical parameters
        ch2 % repository for all ch2 vertical parameters
        ch3 % repository for all ch3 vertical parameters
        ch4 % repository for all ch4 vertical parameters
        
        vert_scale; % amplitude scale in volts, range = 10*scale
        vert_position; % pre-digitization offset
        vert_offset; % post-digitization offset
        vert_coupling; % {AC, DC, GND}
        vert_impedance; % {fifty, meg}
        
        trigger_ch; % which channel supplies the trigger, may or may not be
                    % the same as 'control_ch'
        trigger_slope; % {rise, fall}
        trigger_coupling; % {DC, AC}
        trigger_level; % trigger level in volts, or 'auto' for 50% level
        
        acquire_state; % {Run, Stop}
        acquire_mode; % {sample, average, envelope}
        num_avg; % number of waveforms to average
        num_env; % number of waveforms to use for envelope
        acquire_repetition; % {off, on} enables use of multiple sweeps 
                            % to acquire a single acquisition
        acquire_stopafter; %{Sequence, runstop, limit}
        num_acq; % number of waveforms acquired, query only
        
        data_encoding; %{ascii, ...} manual page 2-88
        data_width; % bytes per point, use 2 for average mode, 1 otherwise
        data_start; % point to start from, value between 1 and record_length
        data_stop; % point to stop at, value between 1 and record_length
        data_source; % channel from which data will be acquired
        wfm_header; % reads waveform header from device, query only
        wfm_num_points; % returns number of points in waveform, query only
        wfm_time_incr; % returns time increment, query only
        wfm_time_offset; % returns time offset, query only
        wfm_volt_scale; % return volt scale factor, query only
        wfm_y_offset; % returns pre-digitization offset
        wfm_volt_offset; % returns post-digitization offset
        
        time_unit = 1e-6; % unit of time for outputting data (in seconds)
        bufferSize = 2^14; % max number of bytes that can be read from buffer
        
        map_Num2Ch = containers.Map({1,2,3,4},...
                {'CH1','CH2','CH3','CH4'});
        map_Ch2Num = containers.Map({'CH1','CH2','CH3','CH4'},...
            {1,2,3,4});
    end % end device properties



    % Class-specific private methods
    methods (Access = private)

    end % end private methods


    methods (Access = public)
        function obj = TekTDS784A()
        %TekTDS784A
%             obj = obj@dev.DAObject.GPIB.GPIBWrapper();
            switch obj.model_number
                case '784A'
                case '644A'
                otherwise
                    error('unknown model number')
            end
        end % end constructor
        
        % Instrument-specific methods
        function clear(obj)
            %CLEAR
            gpib_string = '*CLS';
            obj.Write(gpib_string);
        end
        function reset(obj)
            %RESET
            gpib_string = '*RST';
            obj.Write(gpib_string);
            pause(6)
        end
        function wait(obj)
            %WAIT
            gpib_string = '*WAI';
            obj.Write(gpib_string);
        end
        function [success numAcq obj] = acquireSingleTrace(obj)
            
            stopAfter_state = obj.acquire_stopafter;
            if ~strcmp(stopAfter_state(1:3),'SEQ')
                obj.acquire_stopafter = 'sequence';
                fprintf('changing ''acquire_stopafter'' to ''sequence'' for single trace caputre\n')
            end
            
            % start acquisition
            if obj.acquire_state ~= 1
                obj.acquire_state = 'run';
                fprintf('changing ''acquire_state'' to ''run'' for single trace capture\n')
            end
            counter = 0;
            success = 0;
            while 1
                pause(0.3)
                numAcq = obj.num_acq;
                temp = obj.acquire_mode;
                switch temp(1:3)
                    case {'AVE'}
                        if numAcq == obj.num_avg;
                            success = 1;
                            break
                        end
                    case {'ENV'}
                        if numAcq == obj.num_env;
                            success = 1;
                            break
                        end
                    case {'SAM'}
                        if numAcq == 1;
                            success = 1;
                            break
                        end
                    otherwise
                        error('unknown acquisition type')
                end
                counter = counter + 1;
                if counter > 75
                    break
                end
            end
            
        end
        function [time_usec Amp_Volts obj] = transfer_waveform(obj)
            
            obj.data_encoding = 'ascii';
            
            % Specify the number of bytes per data point using DATa:WIDth.
            temp = obj.acquire_mode;
            acqMode = temp(1:3);
            switch acqMode
                case 'AVE'
                    obj.data_width = 2;
                case {'ENV','SAM'}
                    obj.data_width = 1;
                otherwise
                    error('unknown acquisition type')
            end
            
            % parameters for scaling input data
            numPoints = obj.wfm_num_points;
            time_incr = obj.wfm_time_incr;
            x_offset = obj.wfm_time_offset;
            volt_scale = obj.wfm_volt_scale;
            y_offset = obj.wfm_y_offset;
            volt_offset = obj.wfm_volt_offset;
            
            % Transfer waveform data from the digitizing oscilloscope using the ?
            % query.
            gpib_string = 'CURVe';
            temp = obj.Query([gpib_string '?']);
            % replace commas with spaces and convert to a numeric array
            temp2 = regexprep(temp,',',' ');
            data = str2num(temp2); %#ok<ST2NM>
            
            num_sources = numel(obj.data_source);
            data_cell = cell(1,num_sources);
            time_usec = cell(1,num_sources);
            Amp_Volts = cell(1,num_sources);
            for index = 1:num_sources
                
                data_cell{index} = data(1:numPoints(index));
                data(1:numPoints(index)) = [];
                time_usec{index} = obj.time_unit^-1*time_incr(index)*((1:numPoints) - x_offset(index));
                Amp_Volts{index} = volt_scale(index)*(data_cell{index} - y_offset(index)) + volt_offset(index);
            end
        end
        
    end % end methods

    methods % Class-specific private property accessors

    end % end private property accessors

    methods % Class-specific public property accessors

    end % end public property accessors

    methods % Instrument parameter accessors
        %% get
        function val = get.identity(obj)
            gpib_string = '*IDN';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.channel_on(obj)
            val = zeros(4,1);
            gpib_string = 'SELect:CH1';
            temp = obj.Query([gpib_string '?']);
            if isnan(str2double(temp))
                pause(0.3)
                temp = obj.Query([gpib_string '?']);
                if ~isnan(str2double(temp))
                    fprintf('don''t worry, everything is fine\n')
                end
            end
            val(1) = str2double(temp);
            gpib_string = 'SELect:CH2';
            temp = obj.Query([gpib_string '?']);
            val(2) = str2double(temp);
            gpib_string = 'SELect:CH3';
            temp = obj.Query([gpib_string '?']);
            val(3) = str2double(temp);
            gpib_string = 'SELect:CH4';
            temp = obj.Query([gpib_string '?']);
            val(4) = str2double(temp);
        end
        function val = get.channel_control(obj)
            gpib_string = 'SELect:CONTROl';
            temp = obj.Query([gpib_string '?']);
            val = obj.map_Ch2Num(temp(1:3));
        end
        function val = get.record_length(obj)
            gpib_string = 'HORizontal:RECOrdlength';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.horz_scale(obj)
            gpib_string = 'HORizontal:SCAle';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.trigger_position(obj)
            gpib_string = 'HORizontal:TRIGger';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.ch1(obj)
            obj.channel_control = 1;
            val.vert_scale     = obj.vert_scale;
            val.vert_position  = obj.vert_position;
            val.vert_offset    = obj.vert_offset;
            val.vert_coupling  = obj.vert_coupling;
            val.vert_impedance = obj.vert_impedance;
        end
        function val = get.ch2(obj)
            obj.channel_control = 2;
            val.vert_scale     = obj.vert_scale;
            val.vert_position  = obj.vert_position;
            val.vert_offset    = obj.vert_offset;
            val.vert_coupling  = obj.vert_coupling;
            val.vert_impedance = obj.vert_impedance;
        end
        function val = get.ch3(obj)
            obj.channel_control = 3;
            val.vert_scale     = obj.vert_scale;
            val.vert_position  = obj.vert_position;
            val.vert_offset    = obj.vert_offset;
            val.vert_coupling  = obj.vert_coupling;
            val.vert_impedance = obj.vert_impedance;
        end
        function val = get.ch4(obj)
            obj.channel_control = 4;
            val.vert_scale     = obj.vert_scale;
            val.vert_position  = obj.vert_position;
            val.vert_offset    = obj.vert_offset;
            val.vert_coupling  = obj.vert_coupling;
            val.vert_impedance = obj.vert_impedance;
        end
        function val = get.vert_scale(obj)
            ch_string = obj.map_Num2Ch(obj.channel_control);
            gpib_string = [ch_string ':SCAle'];
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.vert_position(obj)
            ch_string = obj.map_Num2Ch(obj.channel_control);
            gpib_string = [ch_string ':POSition'];
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.vert_offset(obj)
            ch_string = obj.map_Num2Ch(obj.channel_control);
            gpib_string = [ch_string ':OFFSet'];
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.vert_coupling(obj)
            ch_string = obj.map_Num2Ch(obj.channel_control);
            gpib_string = [ch_string ':COUPling'];
            val = obj.Query([gpib_string '?']);
        end
        function val = get.vert_impedance(obj)
            ch_string = obj.map_Num2Ch(obj.channel_control);
            gpib_string = [ch_string ':IMPedance'];
            val = obj.Query([gpib_string '?']);
        end
        function val = get.trigger_ch(obj)
            gpib_string = 'TRIGger:MAIn:EDGE:SOUrce';
            temp = obj.Query([gpib_string '?']);
            val = obj.map_Ch2Num(temp(1:3));
        end
        function val = get.trigger_slope(obj)
            gpib_string = 'TRIGger:MAIn:EDGE:SLOpe';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.trigger_coupling(obj)
            gpib_string = 'TRIGger:MAIn:EDGE:COUPling';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.trigger_level(obj)
            gpib_string = 'TRIGger:MAIn:LEVel';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.acquire_state(obj)
            gpib_string = 'ACQuire:STATE';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.acquire_mode(obj)
            gpib_string = 'ACQuire:MODe';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.num_avg(obj)
            gpib_string = 'ACQuire:NUMAVg';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.num_env(obj)
            gpib_string = 'ACQuire:NUMEnv';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.acquire_repetition(obj)
            if strcmp(obj.model_number,'644A')
                warning('scope:warning','repetitive signal cannot be controlled for 644A model')
                return
            end
            
            gpib_string = 'ACQuire:REPEt';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.acquire_stopafter(obj)
            gpib_string = 'ACQuire:STOPAfter';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.num_acq(obj)
            gpib_string = 'ACQuire:NUMACq';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.data_encoding(obj)
            gpib_string = 'DATa:ENCdg';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.data_width(obj)
            gpib_string = 'DATa:WIDth';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.data_start(obj)
            gpib_string = 'DATa:STARt';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.data_stop(obj)
            gpib_string = 'DATa:STOP';
            temp = obj.Query([gpib_string '?']);
            val = str2double(temp);
        end
        function val = get.data_source(obj)
            gpib_string = 'DATa:SOUrce';
            temp = obj.Query([gpib_string '?']);
            numsources = numel(regexp(temp,',')) + 1;
            val = zeros(1,numsources);
            for index = 1:numsources
                val(index) = obj.map_Ch2Num(temp(4*index-3:4*index-1));
            end
        end
        function val = get.wfm_header(obj)
            ch_on = obj.channel_on;
            if ~ch_on(obj.data_source)
                warning('scope:warning','header cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            gpib_string = 'WFMPre';
            val = obj.Query([gpib_string '?']);
        end
        function val = get.wfm_num_points(obj)
            ch_on = obj.channel_on;
            ch_source = obj.data_source;
            if ~ch_on(ch_source)
                warning('scope:warning','num_points cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            val = zeros(1,numel(ch_source));
            for index = 1:numel(ch_source)
                ch_string = obj.map_Num2Ch(ch_source(index));
                gpib_string = ['WFMPre:' ch_string ':NR_Pt'];
                temp = obj.Query([gpib_string '?']);
                val(index) = str2double(temp);
            end
        end
        function val = get.wfm_time_incr(obj)
            ch_on = obj.channel_on;
            ch_source = obj.data_source;
            if ~ch_on(ch_source)
                warning('scope:warning','time_increment cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            val = zeros(1,numel(ch_source));
            for index = 1:numel(ch_source)
                ch_string = obj.map_Num2Ch(ch_source(index));
                gpib_string = ['WFMPre:' ch_string ':Xincr'];
                temp = obj.Query([gpib_string '?']);
                val(index) = str2double(temp);
            end
        end
        function val = get.wfm_time_offset(obj)
            ch_on = obj.channel_on;
            ch_source = obj.data_source;
            if ~ch_on(ch_source)
                warning('scope:warning','time_offset cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            val = zeros(1,numel(ch_source));
            for index = 1:numel(ch_source)
                ch_string = obj.map_Num2Ch(ch_source(index));
                gpib_string = ['WFMPre:' ch_string ':Pt_Off'];
                temp = obj.Query([gpib_string '?']);
                val(index) = str2double(temp);
            end
        end
        function val = get.wfm_volt_scale(obj)
            ch_on = obj.channel_on;
            ch_source = obj.data_source;
            if ~ch_on(ch_source)
                warning('scope:warning','volt_scale cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            val = zeros(1,numel(ch_source));
            for index = 1:numel(ch_source)
                ch_string = obj.map_Num2Ch(ch_source(index));
                gpib_string = ['WFMPre:' ch_string ':YMUlt'];
                temp = obj.Query([gpib_string '?']);
                val(index) = str2double(temp);
            end
        end
        function val = get.wfm_y_offset(obj)
            ch_on = obj.channel_on;
            ch_source = obj.data_source;
            if ~ch_on(ch_source)
                warning('scope:warning','y_offset cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            val = zeros(1,numel(ch_source));
            for index = 1:numel(ch_source)
                ch_string = obj.map_Num2Ch(ch_source(index));
                gpib_string = ['WFMPre:' ch_string ':YOFf'];
                temp = obj.Query([gpib_string '?']);
                val(index) = str2double(temp);
            end
        end
        function val = get.wfm_volt_offset(obj)
            ch_on = obj.channel_on;
            ch_source = obj.data_source;
            if ~ch_on(ch_source)
                warning('scope:warning','volt_offset cannot be returned unless a the data source channel is turned on');
                val = [];
                return
            end
            val = zeros(1,numel(ch_source));
            for index = 1:numel(ch_source)
                ch_string = obj.map_Num2Ch(ch_source(index));
                gpib_string = ['WFMPre:' ch_string ':YZero'];
                temp = obj.Query([gpib_string '?']);
                val(index) = str2double(temp);
            end
        end
        
        %% set
        function obj = set.channel_on(obj, value)
            gpib_string_base = ':SELect';
            
            if ~ (isvector(value) && isnumeric(value))
                error('Invalid input')
            end
            
            gpib_string = [gpib_string_base ':CH1 ' num2str(value(1))];
            obj.Write(gpib_string);
            gpib_string = [gpib_string_base ':CH2 ' num2str(value(2))];
            obj.Write(gpib_string);
            gpib_string = [gpib_string_base ':CH3 ' num2str(value(3))];
            obj.Write(gpib_string);
            gpib_string = [gpib_string_base ':CH4 ' num2str(value(4))];
            obj.Write(gpib_string);
            
        end
        function obj = set.channel_control(obj, value)
            gpib_string = 'SELect:CONTRol';
            % Validate input
            checkMapObj = obj.map_Num2Ch;
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.record_length(obj, value)
            gpib_string = 'HORizontal:RECOrdlength';
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','record length cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
            if ~(isscalar(value) && isnumeric(value))
                error('input value must be numerica and scalar')
            end
            switch obj.model_number
                case '784A'
                    range = [500,1000,2500,5000,...
                        15000,50000];
                case '644A'
                    range = [500,1000,2000];
                otherwise
                    error('unknown model number')
            end
            
            if min(abs(value-range)) > 1e-10
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.horz_scale(obj, value)
            gpib_string = 'HORizontal:SCAle';
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','horizontal scale cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
           
            switch obj.model_number
                case '784A'
                    temp = [1 2 5]'*logspace(-10,0,11);
                    temp = sort(reshape(temp,[1 numel(temp)]));
                    temp = [temp(2:end) 10];
                    temp = temp(temp ~= 10e-9);
                    temp = [temp 12.5e-9]; %this particular value is an oddball
                    range = sort(temp);
%                     checkMapObj = containers.Map(range,range);
                case '644A'
                    temp = [1 2.5 5]'*logspace(-10,0,11);
                    temp = sort(reshape(temp,[1 numel(temp)]));
                    range = temp(3:end);
%                     checkMapObj = containers.Map(range,range);
                otherwise
                    error('unknown model number')
            end
            if  min(abs(range-value)) > 10e-10
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.trigger_position(obj, value)
            gpib_string = 'HORizontal:TRIGger:POSition';
            
            % Validate input
           
            if ~(isscalar(value) && isnumeric(value))
                error('trigger_position must be a numeric scalar');
            end
            
            if value < 0 || value > 100
                error('trigger_position must be between 0 and 100')
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.vert_scale(obj, value)
            gpib_string = [obj.map_Num2Ch(obj.channel_control) ':SCAle'];
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','vertical scale cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
           
            switch obj.model_number
                case '784A'
                    temp = [1 2 5]'*logspace(-3,0,4);
                    temp = sort(reshape(temp,[1 numel(temp)]));
                    range = [temp 10];
%                     checkMapObj = containers.Map(range,range);
                case '644A'
                    temp = [1 2 5]'*logspace(-3,0,4);
                    temp = sort(reshape(temp,[1 numel(temp)]));
                    range = [temp 10];
%                     checkMapObj = containers.Map(range,range);
                otherwise
                    error('unknown model number')
            end
            if  min(abs(range-value)) > 10e-10
                error('Invalid input');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.ch1(obj,value)
            if isfield(value,{'vert_scale','vert_position',...
                    'vert_offset','vert_coupling','vert_impedance'})
                % then everything is ok
            else
                error('all vertical parameters must be specified')
            end
            obj.channel_control = 1;
            obj.vert_scale     = value.vert_scale;
            obj.vert_position  = value.vert_position;
            obj.vert_offset    = value.vert_offset;
            obj.vert_coupling  = value.vert_coupling;
            obj.vert_impedance = value.vert_impedance;
        end
        function obj = set.ch2(obj,value)
            if isfield(value,{'vert_scale','vert_position',...
                    'vert_offset','vert_coupling','vert_impedance'})
                % then everything is ok
            else
                error('all vertical parameters must be specified')
            end
            obj.channel_control = 2;
            obj.vert_scale     = value.vert_scale;
            obj.vert_position  = value.vert_position;
            obj.vert_offset    = value.vert_offset;
            obj.vert_coupling  = value.vert_coupling;
            obj.vert_impedance = value.vert_impedance;
        end
        function obj = set.ch3(obj,value)
            if isfield(value,{'vert_scale','vert_position',...
                    'vert_offset','vert_coupling','vert_impedance'})
                % then everything is ok
            else
                error('all vertical parameters must be specified')
            end
            obj.channel_control = 3;
            obj.vert_scale     = value.vert_scale;
            obj.vert_position  = value.vert_position;
            obj.vert_offset    = value.vert_offset;
            obj.vert_coupling  = value.vert_coupling;
            obj.vert_impedance = value.vert_impedance;
        end
        function obj = set.ch4(obj,value)
            if isfield(value,{'vert_scale','vert_position',...
                    'vert_offset','vert_coupling','vert_impedance'})
                % then everything is ok
            else
                error('all vertical parameters must be specified')
            end
            obj.channel_control = 4;
            obj.vert_scale     = value.vert_scale;
            obj.vert_position  = value.vert_position;
            obj.vert_offset    = value.vert_offset;
            obj.vert_coupling  = value.vert_coupling;
            obj.vert_impedance = value.vert_impedance;
        end
        function obj = set.vert_position(obj, value)
            gpib_string = [obj.map_Num2Ch(obj.channel_control) ':POSition'];
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','vertical scale cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input');
            end
            if  abs(value) > 5
                error('Input out of range, (+/- 5)');
            end

            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.vert_offset(obj, value)
            gpib_string = [obj.map_Num2Ch(obj.channel_control) ':OFFSet'];
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','vertical scale cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input');
            end
            
            v_scale = obj.vert_scale;
            
            if v_scale < 100e-3
                max_offset = 1;
            elseif v_scale < 1
                max_offset = 10;
            else
                max_offset = 100;
            end
            
            if  abs(value) > max_offset
                error('Input out of range');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.vert_coupling(obj, value)
            gpib_string = [obj.map_Num2Ch(obj.channel_control) ':COUPling'];
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','vertical scale cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
            checkMapObj = containers.Map({'AC','ac','Ac','DC','dc','Dc','GND','gnd','Gnd'},...
                {'ac','ac','ac','dc','dc','dc','gnd','gnd','gnd'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.vert_impedance(obj, value)
            gpib_string = [obj.map_Num2Ch(obj.channel_control) ':IMPedance'];
            
            if sum(obj.channel_on) == 0
                warning('scope:warning','vertical scale cannot be set unless at least one channel is on')
                return
            end
            
            % Validate input
            checkMapObj = containers.Map({'FIFTY','fifty','Fifty','FIF','fif','Fif',...
                'MEG','meg','Meg'},...
                {'fifty','fifty','fifty','fifty','fifty','fifty',...
                'meg','meg','meg'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.trigger_ch(obj, value)
            gpib_string = 'TRIGger:MAIn:EDGE:SOUrce';
            % Validate input
            checkMapObj = obj.map_Num2Ch;
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.trigger_slope(obj, value)
            gpib_string = 'TRIGger:MAIn:EDGE:SLOpe';
            % Validate input
            checkMapObj = containers.Map({'RISE','rise','Rise','FALL','fall','Fall'},...
                {'rise','rise','rise','fall','fall','fall'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.trigger_coupling(obj, value)
            gpib_string = 'TRIGger:MAIn:EDGE:COUPling';
            
            % Validate input
            checkMapObj = containers.Map({'AC','ac','Ac','DC','dc','Dc'},...
                {'ac','ac','ac','dc','dc','dc'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.trigger_level(obj, value)
            gpib_string = 'TRIGger:MAIn:LEVel';
            
            t_channel = obj.trigger_ch;
            
            v_scale = str2double(obj.Query([obj.map_Num2Ch(t_channel) ':SCAle?']));
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input');
            end
            
            max_level = 12*v_scale;
            
            if  abs(value) > max_level
                error('Input out of range');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.acquire_state(obj, value)
            gpib_string = 'ACQuire:STATE';
            
            % Validate input
            if isscalar(value) && isnumeric(value)
                if value == 1 || value == 0
                    value = num2str(value);
                else
                    error('Invalid input, valid inputs are 1, 0, ''run'', ''stop'', ''on'', and ''off''');
                end
            else
                checkMapObj = containers.Map({'ON','on','On','RUN','run','Run',...
                    'OFF','off','Off','STOP','stop','Stop'},...
                    {'1','1','1','1','1','1','0','0','0','0','0','0'});
                if not (checkMapObj.isKey(value))
                    error('Invalid input, valid inputs are 1, 0, ''run'', ''stop'', ''on'', and ''off''');
                end
                value = checkMapObj(value);
            end
            
            gpib_string = [gpib_string ' ' value];
            obj.Write(gpib_string);
            
        end
        function obj = set.acquire_mode(obj, value)
            gpib_string = 'ACQuire:MODe';
            
            % Validate input
            checkMapObj = containers.Map({'SAMPLE','sample','Sample','SAM',...
                'ENVELOPE','envelope','Envelope','ENV',...
                'AVERAGE','average','Average','AVE'},...
                {'sample','sample','sample','sample','envelope',...
                'envelope','envelope','envelope',...
                'average','average','average','average'});
            if not (checkMapObj.isKey(value))
                error('Invalid input, valid inputs are ''sample'',''envelope'', and ''average''');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.num_avg(obj, value)
            gpib_string = 'ACQuire:NUMAVg';
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input, input must be integer between 2 and 10,000');
            end
            
            if mod(value,1) > 1e-10
                warning('scope:warning','value is not an integer, rounding')
                value = round(value);
            end
            
            if  value < 2 || value > 10000
                error('Input out of range, input must be integer between 2 and 10,000');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.num_env(obj, value)
            gpib_string = 'ACQuire:NUMENv';
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input, input must be integer between 1 and 2,000');
            end
            
            if mod(value,1) > 1e-10
                warning('scope:warning','value is not an integer, rounding')
                value = round(value);
            end
            
            if  value < 1 || value > 2000
                error('Input out of range, input must be integer between 1 and 2,000');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.acquire_repetition(obj, value)
            gpib_string = 'ACQuire:REPEt';
            
            if strcmp(obj.model_number,'644A')
                warning('scope:warning','repetitive signal cannot be controlled for 644A model')
                return
            end
            
            % Validate input
            if isscalar(value) && isnumeric(value)
                if value == 1 || value == 0
                    value = num2str(value);
                else
                    error('Invalid input, valid inputs are 1, 0, ''on'', and ''off''');
                end
            else
                checkMapObj = containers.Map({'ON','on','On',...
                    'OFF','off','Off'},{'1','1','1','0','0','0'});
                if not (checkMapObj.isKey(value))
                    error('Invalid input, valid inputs are 1, 0, ''on'', and ''off''');
                end
                value = checkMapObj(value);
            end
            
            gpib_string = [gpib_string ' ' value];
            obj.Write(gpib_string);
            
        end
        function obj = set.acquire_stopafter(obj, value)
            gpib_string = 'ACQuire:STOPAfter';
            
            % Validate input
            checkMapObj = containers.Map({'RUNSTOP','runstop','Runstop','RUNST'...
                'SEQUENCE','sequence','Sequence','SEQ'},...
                {'runstop','runstop','runstop','runstop',...
                'sequence','sequence','sequence','sequence'});
            if not (checkMapObj.isKey(value))
                error('Invalid input, valid inputs are ''runstop'', and ''sequence''');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.num_acq(obj, value) %#ok<INUSD>
            warning('scope:warning','num_acq is a query only command, it cannot be set');
        end
        function obj = set.data_encoding(obj, value)
            gpib_string = 'DATA:ENCdg';
            
            % Validate input
            checkMapObj = containers.Map({'ASCII','ascii','Ascii','ASCI',...
                'ribinary','rpbinary','sribinary','srpbinary'},...
                {'ascii','ascii','ascii','ascii',...
                'RIB','RPB','SRI','SRP'});
            if not (checkMapObj.isKey(value))
                error('Invalid input, valid inputs are ''ascii'', ''ribinary'', ''rpbinary'', ''sribinary'', ''srpbinary''');
            end
            
            gpib_string = [gpib_string ' ' checkMapObj(value)];
            obj.Write(gpib_string);
        end
        function obj = set.data_width(obj, value)
            gpib_string = 'DATa:WIDth';
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input, input must be 1 or 2');
            end
            
            if mod(value,1) > 1e-10
                warning('scope:warning','value is not an integer, rounding')
                value = round(value);
            end
            
            if  value ~= 1 && value ~= 2
                error('Invalid input, input must be 1 or 2');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.data_start(obj, value)
            gpib_string = 'DATa:STARt';
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input, input must be between 1 and record_length');
            end
            
            if mod(value,1) > 1e-10
                warning('scope:warning','value is not an integer, rounding')
                value = round(value);
            end
            
            if  value < 1
                warning('scope:warning','Input out of range, changing data_start to 1');
                value = 1;
            end
            
            if  value > obj.record_length
                warning('scope:warning','Input out of range, changing data_start to record length');
                value = obj.record_length;
            end
            
            if value > obj.data_stop
                warning('scope:warning','new start value is greater than old stop value');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
            
        end
        function obj = set.data_stop(obj, value)
            gpib_string = 'DATa:STOP';
            
            % Validate input
            if ~(isscalar(value) || isnumeric(value))
                error('Invalid input, input must be between 1 and record_length');
            end
            
            if mod(value,1) > 1e-10
                warning('scope:warning','value is not an integer, rounding')
                value = round(value);
            end
            
            if  value < 1
                warning('scope:warning','Input out of range, changing data_stop to 1');
                value = 1;
            end
            
            if  value > obj.record_length
                warning('scope:warning','Input out of range, changing data_stop to record length');
                value = obj.record_length;
            end
            
            if value < obj.data_start
                warning('scope:warning','new stop value is less than old start value');
            end
            
            gpib_string = [gpib_string ' ' num2str(value)];
            obj.Write(gpib_string);
        end
        function obj = set.data_source(obj, value)
            gpib_string = 'DATa:SOUrce';
            
            if ~(isvector(value) && isnumeric(value))
                error('data_source must be a numeric vector')
            end
            
            output_string = [];
            checkMapObj = obj.map_Num2Ch;
            for index = 1:numel(value)
                % Validate input
                if not (checkMapObj.isKey(value(index)))
                    error('Invalid input');
                end
                output_string = [output_string checkMapObj(value(index))]; %#ok<AGROW>
                if index ~= numel(value)
                    output_string = [output_string ',']; %#ok<AGROW>
                end
            end
            
            gpib_string = [gpib_string ' ' output_string];
            obj.Write(gpib_string);
        end
        function obj = set.wfm_header(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_header is a query only command, it cannot be set');
        end
        function obj = set.wfm_num_points(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_num_points is a query only command, it cannot be set');
        end
        function obj = set.wfm_time_incr(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_time_incr is a query only command, it cannot be set');
        end
        function obj = set.wfm_time_offset(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_time_offset is a query only command, it cannot be set');
        end
        function obj = set.wfm_volt_scale(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_volt_scale is a query only command, it cannot be set');
        end
        function obj = set.wfm_y_offset(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_y_offset is a query only command, it cannot be set');
        end
        function obj = set.wfm_volt_offset(obj, value) %#ok<INUSD>
            warning('scope:warning','wfm_volt_offset is a query only command, it cannot be set');
        end
        
    end % end instrument parameter accessors

end % end classdef

%---END OF FILE---%

