classdef AgilentAP120 < handle
%Agilent Acqiris AP120
%
%
% Author(s): rrhain
% 04/14/2010



    % Class-specific constant properties
    properties (Constant = true)
        clockTypes = containers.Map({'int', 'ext', 'ref'}, {0, 1, 2});
    end % end constant properties


    % Class-specific private properties
    properties (Access = private)

    end % end private properties


    % Class-specific public properties
    properties (Access = public)

    end % end public properties


    % Device properties correspond to instrument parameters
    properties (Access = private)
        
    end

    properties (Access = public)
        instrID; %
        resourceName = 'PCI::INSTR0';
        model_number = 'AP120'; 
        options = '';
        Address;
        channel_on; % sets or queries which channels are currently on
        trigger_ch; % which channel supplies the trigger
        acquire_mode;  %fieldnames of value and flags
        clockType; % internal, external, or external reference

        memory;  %fields of record_length and nbrSegments 
	         %record_length - Nominal number of samples to record 
	         %(per segment!) 
	         %nbrSegments - Number of segments to acquire. 
	         %1 corresponds to the normal single-trace acquisition mode. 
			 % though averager config values take precedence


        horizontal;   %fields of sampleInterval and delayTime
	              %sampleInterval Sampling interval in seconds
	              %delayTime 
                  %Trigger delay time in seconds, with respect to the 
	              %beginning of the record. A positive number 
                  %corresponds to a trigger before the beginning of the 
                  %record (post-trigger recording). A negative number
                  %corresponds to pre-trigger recording. It can’t be less
                  %than -(sampInterval * record_length), which
                  %corresponds to 100% pre-trigger.

        vertical;   %Configures the vertical control parameters 
	            %for a specified channel of the digitizer. 
                %fields of vert_channel, vert_scale, offset, vert_coupling, bandwidth
	            %vert_channel - 1...Nchan, or –1,… for the External Input
                %vert_scale - in Volts, but see triggerSource below
	            %offset - in Volts
                %vert_coupling - = 0 Ground (Averagers ONLY)
				%				 = 1 DC, 1 MΩ
                %				 = 2 AC, 1 MΩ
                %				 = 3 DC, 50 Ω
                %				 = 4 AC, 50 Ω


        triggerSource;   %Configures the trigger source control parameters 
                %for the specified trigger source
                %(channel or External).
                %fields of trigChannel, trigger_coupling, trigger_slope,
                %trigger_level, trigger_level2

                %trigChannel - > 1 for internal, <-1 for exernal

                %trigger_coupling - 0 DC, 1 AC, 2 HF (if available),
                %3 DC 50W, 4 AC 50W both external trigger only

                %trigger_slope - 0  Positive, 1  Negative,
                %2 out of Window, 3  into Window, 4  HF divide,
                %5  Spike Stretcher

                %trigger_level  Trigger threshold in % of the
                %vertical Full Scale of the channel
                %or in mV if using an External trigger src

                %trigger_level2 Trigger threshold 2 (as above) for
                %use when Window trigger is selected


        triggerClass;  %Configures the trigger class control 
	            %parameters of the digitizer. 
                %fields of trigClass, sourcePattern

                %trigClass - 0 edge trigger,
                %1 TV trigger (12-bit-FAMILY External only)

                %sourcePattern - = 0x000n0001 for Channel 1,
                % 0x000n0002 for Channel 2,
                % 0x000n0004 for Channel 3,
                % 0x000n0008 for Channel 4 etc.
                % 0x800n0000 for External Trigger 1,
                % 0x400n0000 for External Trigger 2.
                %where n is 0 for single instruments

        averager;  %Configures the averager
	            %fields of record_length, nbrSegments, num_avg, 
                %ditherRange, trigResync, data_start, data_stop

                %record_length  - Number of data samples per waveform segment.
                %May assume values between 16 or 32 and the available
                %memory length, in multiples of 16 or 32 as ref to manual
                
                %nbrSegments - Number of waveform segments to acquire.
                %May assume values between 1 and 8192.
				
				%nbrWaveforms - Number of waveforms to average before going to
				%next segment. Values 1 - 65535

                %num_avg - Alias for nbrWaveforms to maintain backward
                %compatibility
				
				%nbrRoundRobins - Number of times to perform the full
                %segment cycle during data accumulation.

                %ditherRange -
                %Range of offset dithering, in ADC LSB’s. May assume
                %values v = 0, 1…15 for AP units and 31 for U1084A
                %units. The offset is dithered over the range
                % [ -v, + v] in steps of ~1/8 LSB. For Averagers ONLY.
                
                %trigResync - 0 (no resync), 1 (resync) and 2 (free run)

                %data_start - point to start from, value between 16 and
                %record_length, in samples, need to be multiple of 16

                %data_stop - point to stop at, value between 16 and
                %record_length ,in samples, need to be multiple of 16

        timeout = 10000;   %Timeout for acquisition in milliseconds 



        %horz_scale; % time in seconds coresponding to 50 points of a waveform
        %trigger_position; % relative position of trigger on horizontal trace (0-100%)
        
        %vert_position; % pre-digitization offset
        %vert_offset; % post-digitization offset
        %vert_impedance; % {fifty, meg}

        %refer to page 192 Programmer's Reference Manual        
        %wfm_num_points; % returns number of points in waveform, query only
             %could be returnedSamplesPerSeg 
             %Total number of data samples actually returned. 

        %wfm_time_incr; % returns time increment, query only
             %sampTime Sampling interval in seconds.?


        %wfm_time_offset; % returns time offset, query only
        %wfm_volt_scale; % return volt scale factor, query only
        %wfm_y_offset; % returns pre-digitization offset
        %wfm_volt_offset; % returns post-digitization offset
        
        


    end % end device properties



    % Class-specific private methods
    methods (Access = private)

    end % end private methods


    methods (Access = public)

	%%constructor
        function obj = AgilentAP120()
            %initialization of the device, middle two args currently
            %ignored
            AqRoot=getenv('AcqirisDxRoot');
            addpath([AqRoot,'\bin']);
            %addpath([AqRoot,'\MATLAB\mex'],[AqRoot,'\MATLAB\mex\functions']);
            addpath([AqRoot,'\MATLAB\mex']);
            addpath([AqRoot,'\MATLAB\mex\help']);
            addpath([AqRoot,'\MATLAB\mex\functions']);
            obj.channel_on = 1;
            obj.trigger_ch = -1;
            [status instrumentID] = Aq_InitWithOptions(obj.resourceName, 0, 0, obj.options);
            if (status ~= 0)
                disp(sprintf('Error in Aq_InitWithOptions: %d', status));
            end
	  
            obj.instrID  = instrumentID;

            % Retrieve digitizer position
            [status name, serial, bus, slot] = Aq_getInstrumentData(instrumentID);
            if (status ~= 0)
                disp(sprintf('Error in Aq_getInstrumentData: %d', status));
            end
        end % end constructor

        function connect(obj, Address)
            if nargin > 1
                % if we specify an new address, use it.
                obj.Address    = Address;
            end
        end
        
	%%reset the device
        function obj = reset(obj)
            %initialization of the device, middle two args currently
            %ignored
            [status instrumentID] = Aq_InitWithOptions(obj.resourceName, 0, 0, obj.options);
            if (status ~= 0)
                disp(sprintf('Error in Aq_InitWithOptions: %d', status));
            end
	  
            obj.instrID  = instrumentID;

            % Retrieve digitizer position
            [status name, serial, bus, slot] = Aq_getInstrumentData(instrumentID);
            if (status ~= 0)
                disp(sprintf('Error in Aq_getInstrumentData: %d', status));
            end

	 
        end % end reset

	%%destructor the device
        function status=delete(obj)
            disp('Cleaning up Agilent Test Card');    
            % Close the instrument
			status = Aq_close(obj.instrID);
            if (status ~= 0)
               %disp(sprintf('Error in Aq_close (not sure why we need this?): %d', status));
               disp(sprintf('Acqiris card is already closed'));
            end

            % Free remaining resources
            status = Aq_closeAll();
            if (status ~= 0)
               %disp(sprintf('Error in Aq_closeAll: %d', status));
               disp(sprintf('Acqiris card is already closed'));
            end
        end 
        
        % disconnect device
        function disconnect(obj)
            status=delete(obj);
            if (status ~= 0)
               %disp(sprintf('Error in Aq_close (not sure why we need this?): %d', status));
               disp(sprintf('Acqiris card is already closed'));
            end
		end
		
		% instrument meta-setter
		function setAll(obj, settings)
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
				switch name
					case 'acquire_mode'
						obj.acquire_mode = settings.acquire_mode;
					case 'horizontal'
						obj.horizontal = settings.horizontal;
					case 'vertical'
						obj.vertical = settings.vertical;
					case 'trigger'
						obj.trigger_ch = settings.trigger.trigger_ch;
						obj.triggerSource = settings.trigger;
						obj.triggerClass = 0; % 'edge' class is only one available for the AP120/240'
					case 'averager'
						obj.averager = settings.averager;
					otherwise
						if ismember(name, methods(obj))
							feval(['obj.' name], settings.(name));
						elseif ismember(name, properties(obj))
							obj.(name) = settings.(name);
						end
				end
			end
			% pause to let the card settle
			pause(0.1);
		end

        %% Instrument-specific methods
        function status = config_parameter(obj, parameterString, value)
            status = AqD1_configAvgConfigInt32(obj.instrID, obj.channel_on, parameterString, value);
            if (status ~= 0)
            disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
            end
        end

        %%put in acquisition mode
        function status = acquire(obj)
            % Start the acquisition
            status = AqD1_acquire(obj.instrID);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_acquire: %d', status));
            end
        end
        
        %%wait for acquisition - will timeout in timeout seconds if it
        %fails to acquire
        function status = wait_for_acquisition(obj, timeout)
            if ~exist('timeout', 'var')
                timeout = obj.timeout/1000;
            end
            
            % maximum timeout value for AqD1_waitForEndOfAcquisition is 10
            % seconds. If caller wants to wait longer, need to loop
            numRepeats = max(1, floor(timeout/10));
            if numRepeats > 1
                timeout = 10;
            end
            %Wait for end of acquisition
            for n = 1:numRepeats
                status = AqD1_waitForEndOfAcquisition(obj.instrID, timeout*1000);
                if status == 0
                    break; % we don't have to continue looping if we are already done
                end
            end
            if (status ~= 0)
                disp(sprintf('Error in AqD1_waitForEndOfAcquisition: %d', status));
                status = AqD1_stopAcquisition(obj.instrID);
                error('The acquisition has been stopped - data invalid!');
            end
        end
        
        %%do a single acquisition of an averaged waveform
        function status = acquireSingleTrace(obj)
            status = acquire(obj);

            %should probably check status before waiting for acquisition;
            status = wait_for_acquisition(obj);
        end
        
		 %%get data acquired
         function [AqDataBuffer times] = transfer_waveform(obj, channel)
            AqReadParameters.dataType = 3; % 64 bit real data
            % SC: readMode = 2 for averaged waveform -  5 is for short averager waveform
            AqReadParameters.readMode = 2; % averaged waveform read mode
            AqReadParameters.firstSegment = 0;
            AqReadParameters.nbrSegments = obj.averager.nbrSegments;
            AqReadParameters.firstSampleInSeg = 0;
            AqReadParameters.nbrSamplesInSeg = obj.averager.record_length;
            AqReadParameters.segmentOffset = obj.averager.record_length;
            % SC: dataArraySize should be at least record_length * nbrSegments *
            % size_of_dataType - see the discusiion of AcqrsD1_readData function in the
            % Programmer Reference

            AqReadParameters.dataArraySize = (obj.averager.record_length + 32) * obj.averager.nbrSegments * 8;

            % SC: Segment Descriptor for Averaged Waveforms (readMode = 2,5,6) in AqSegmentDescriptorAvg
            AqReadParameters.segDescArraySize = 40 * obj.averager.nbrSegments; 
    
            AqReadParameters.flags = 0;
            AqReadParameters.reserved = 0;
            AqReadParameters.reserved2 = 0.0;
            AqReadParameters.reserved3 = 0.0;

            % Read the channel waveform
            [status dataDesc segDescArray AqDataBuffer] = AqD1_readData(obj.instrID, channel, AqReadParameters);
			
			% chop off initial unused points
			nbrSamples = obj.averager.record_length * obj.averager.nbrSegments;
            % fix off-by-one error in indexFirstPoint
            %firstPt = dataDesc.indexFirstPoint + 1;
            firstPt = dataDesc.indexFirstPoint;
			subrange = 1+firstPt:firstPt+nbrSamples;
			AqDataBuffer = AqDataBuffer(subrange);
			
			% if more than one segment, reshape into 2D array
			if obj.averager.nbrSegments > 1
				AqDataBuffer = reshape(AqDataBuffer, obj.averager.record_length, obj.averager.nbrSegments);
			end

			times = linspace(0,double(obj.averager.record_length - 1) * double(dataDesc.sampTime),obj.averager.record_length);
			
            if (status ~= 0)
				disp(sprintf('Error in AqD1_readData: %d', status));
			end
		 end

    end % end methods

    methods % Class-specific private property accessors

    end % end private property accessors

    methods % Class-specific public property accessors

    end % end public property accessors

    methods % Instrument parameter accessors
        %% get - gets query the card - no parameters really stored in the object
        function val = get.acquire_mode(obj)
            [status mode modifiers flags] = AqD1_getMode(obj.instrID);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getMode: %d', status));
                val.value = -10;
                val.flags = -10;
            else
                val.value = mode;
                val.flags = flags;
            end
            
        end
        
        function val = get.clockType(obj)
           [status clock inputThreshold delayNbrSamples inputFrequency sampFrequency] = AqD1_getExtClock(obj.instrID);
           clockTypesInv = invertMap(obj.clockTypes);
           val = clockTypesInv(clock);
        end

        function val = get.memory(obj)
            [status record_length nbrSegments] = AqD1_getMemory(obj.instrID);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getMemory: %d', status));
                val.record_length = -10;
                val.nbrSegments = -10;
            else
                val.record_length = record_length;
                val.nbrSegments = nbrSegments;
            end
            
        end
        
       function val = get.horizontal(obj)
            [status sampleInterval delayTime] = AqD1_getHorizontal(obj.instrID);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getHorizontal: %d', status));
            else
                val.sampleInterval = sampleInterval;
                val.delayTime = delayTime;
            end
       end

       function val = get.vertical(obj)
           %worry about channel specification
		   channel = 1;
           [status vert_scale offset vert_coupling bandwidth]= AqD1_getVertical(obj.instrID, channel);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getVertical: %d', status));
            else
                %have to be carefule about keeping channel_on == vertical.vert_channel
                val.vert_scale = vert_scale;
                val.offset = offset;
                val.vert_coupling = vert_coupling;
                val.bandwidth = bandwidth;
            end
       end
       
       	function val = get.triggerSource(obj)
            %get trigger source
            [status trigger_coupling trigger_slope trigger_level trigger_level2] = AqD1_getTrigSource(obj.instrID, obj.trigger_ch);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getTrigSource: %d', status));
            else
                val.trigger_coupling = trigger_coupling;
                val.trigger_slope = trigger_slope;
                val.trigger_level = trigger_level;
                val.trigger_level2 = trigger_level2;
            end
        end
        
        function val = get.triggerClass(obj)
            [status trigClass sourcePattern validatePattern holdType holdoffTime reserved] = AqD1_getTrigClass(obj.instrID);
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getTrigSource: %d', status));
            else
%                 val = trigClass;
                val.trigClass = trigClass;
                val.sourcePattern = dec2hex(-sourcePattern);
% 				val.sourcePattern = sourcePattern;
                %all other fields unused
            end
        end
        
        function val = get.averager(obj)
            %Metafunction which gets all of the averaging parameters
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'NbrSamples');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.record_length = -10;
            else
                val.record_length = retVal;
            end

            % SC: configure the number of segments
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'NbrSegments');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.nbrSegments = -10;
            else
                val.nbrSegments = retVal;
            end

            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'NbrWaveforms');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.nbrWaveforms = -10;
				val.num_avg = -10;
            else
                val.nbrWaveforms = retVal;
				val.num_avg = retVal;
            end

            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'DitherRange');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.ditherRange = -10;
            else
                val.ditherRange = retVal;
            end

            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'TrigResync');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.trigResync = -10;
            else
                val.trigResync = retVal;
            end

            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'StartDelay');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.data_start = -10;
            else
                val.data_start = retVal;
            end

            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'StopDelay');
            if (status ~= 0)
                disp(sprintf('Error in AqD1_getAvgConfigInt32: %d', status));
                val.data_stop = -10;
            else
                val.data_stop = retVal;
            end
          
       end

        %% set - sets parameters on the card almost instantaneously - 
		% no parameters really stored in the object
	 
        function obj = set.acquire_mode(obj, modeP)
			% to do, also accept a non-struct input
            if isstruct(modeP) && isfield(modeP, 'value')
				
				% use default value for flags if it is not specified
				if (~isfield(modeP, 'flags'))
					modeP.flags = 0;
				end
            
                status = AqD1_configMode(obj.instrID, modeP.value, 0, modeP.flags);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configMode: %d', status));
                end
			elseif isnumeric(modeP)
				status = AqD1_configMode(obj.instrID, modeP, 0, 0);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configMode: %d', status));
				end
			else
                disp(sprintf('Error in set acquire_mode - modeP should be struct with fields of value and flags'));
            end
        end
        
        % set clock type
        % valid modes are: 'int', 'ext', and 'ref'
        function obj = set.clockType(obj, mode)
            mode = obj.clockTypes(mode); % convert mode to integer
            threshold = 500; % in mV for mode = 'ext'
            delay = 0; % delay in number of points for mode = 'ext'
            inputFrequency = 500e6; % input frequency of external clock for mode = 'ext'
            sampFrequency = 500e6; % sampling frequency for mode = 'ext'
            status = AqD1_configExtClock(obj.instrID, mode, threshold, delay, inputFrequency, sampFrequency);
            if status ~= 0
                fprintf('Error in AqD1_configExtClock: %d', status);
            end
        end

		%%not really useful for the averager mode - left it in anyway
        function obj = set.memory(obj, memVal)
            if (isfield(memVal, 'record_length') && isfield(memVal, 'nbrSegments'))
                status = AqD1_configMemory(obj.instrID, memVal.record_length, memVal.nbrSegments);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configMemory: %d', status));
                end
            else
                disp(sprintf('Error in set memory - arg should be struct with fields of record_length and nbrSegments'));
            end
        end

        function obj = set.horizontal(obj, horzVal)
            if (isfield(horzVal, 'sampleInterval') && isfield(horzVal, 'delayTime'))
                %Set horizontal timing (sampleInterval and delayTime)
                status = AqD1_configHorizontal(obj.instrID, horzVal.sampleInterval, horzVal.delayTime);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configHorizontal: %d', status));
                end
            else
                disp(sprintf('Error in set horizontal - arg should be struct with fields of sampleInterval and delayTime'));
            end
        end

        function obj = set.vertical(obj, vertVal)
            if (isfield(vertVal, 'vert_scale') && isfield(vertVal, 'offset')&& isfield(vertVal, 'vert_coupling') && isfield(vertVal, 'bandwidth'))
                %Configure vertical settings, should vert_channel be obj or vertVal
				%status = AqD1_configVertical(obj.instrID, obj.channel_on, vertVal.vert_scale, vertVal.offset, vertVal.vert_coupling, vertVal.bandwidth);
				% hard coded to set both channels identically, though this
				% is not required by the hardware
                status = AqD1_configVertical(obj.instrID, 1, vertVal.vert_scale, vertVal.offset, vertVal.vert_coupling, vertVal.bandwidth);
				status = AqD1_configVertical(obj.instrID, 2, vertVal.vert_scale, vertVal.offset, vertVal.vert_coupling, vertVal.bandwidth);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configVertical: %d', status));
                end
            else
                disp(sprintf('Error in set vertical - arg should be struct with fields of vert_scale, offset, vert_coupling, and bandwidth'));
            end
        end
        
        
        function obj = set.triggerSource(obj, trigSrcVal)
            if (isfield(trigSrcVal, 'trigger_coupling')&& isfield(trigSrcVal, 'trigger_slope') && isfield(trigSrcVal, 'trigger_level'))
				if (~isfield(trigSrcVal, 'trigger_level2'))
					trigSrcVal.trigger_level2 = trigSrcVal.trigger_level;
				end
                %Configure trigger source
				if isfield(trigSrcVal, 'trigger_ch')
					obj.trigger_ch = trigSrcVal.trigger_ch;
				end
                status = AqD1_configTrigSource(obj.instrID, obj.trigger_ch, trigSrcVal.trigger_coupling, trigSrcVal.trigger_slope, trigSrcVal.trigger_level, trigSrcVal.trigger_level2);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configTrigSource: %d', status));
                end
            else
                disp(sprintf('Error in set triggerSource - arg should be struct with fields of trigger_coupling, trigger_slope, trigger_level, trigger_level2'));
            end
        end

        function obj = set.triggerClass(obj, trigClsVal)
            if isscalar(trigClsVal)
                %status = AqD1_configTrigClass(obj.instrID, 0,  hex2dec('80000000'), 0, 0, 0, 0);
                %last 4 args unused - set to 0
                switch obj.trigger_ch
					
                    case -1
                        sourcePattern = hex2dec('80000000');
                    case 1
                        sourcePattern = 1;
                    case 2
                        sourcePattern = 2;
                    otherwise
                        error('unexpected value for trigger_ch')
                end
                status = AqD1_configTrigClass(obj.instrID, trigClsVal, sourcePattern, 0, 0, 0, 0);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configTrigClass: %d', status));
                end
            else
                disp(sprintf('Error in set triggerClass - arg should be struct with fields of trigClass and sourcePattern'));
                
            end
        end
        
        function obj = set.averager(obj, avgVal)
            if(isfield(avgVal, 'record_length') && isfield(avgVal, 'nbrSegments') && (isfield(avgVal, 'num_avg') || isfield(avgVal, 'nbrWaveforms')) && isfield(avgVal, 'nbrRoundRobins') &&isfield(avgVal, 'ditherRange') && isfield(avgVal, 'trigResync'))
                %Metafunction which configures all of the averaging parameters
				obj.channel_on = 0;
                status = obj.config_parameter('NbrSamples', avgVal.record_length);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
                else
                    obj.averager.record_length = avgVal.record_length;
                end

                % SC: configure the number of segments
				if (avgVal.nbrSegments > 8192)
					warning('Maximum number of segments is 8192');
					avgVal.nbrSegments = 8192;
				end
                status = obj.config_parameter('NbrSegments', avgVal.nbrSegments);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
				else
					obj.averager.nbrSegments = avgVal.nbrSegments;
				end

				% use either num_avg or nbrWaveforms (whichever was set)
				if (isfield(avgVal, 'nbrWaveforms'))
					nbrWaveforms = avgVal.nbrWaveforms;
				else
					nbrWaveforms = avgVal.num_avg;
				end
				if (nbrWaveforms > 65535)
					warning('Maximum number of waveforms is 65535');
					nbrWaveforms = 65535;
				end
                status = obj.config_parameter('NbrWaveforms', nbrWaveforms);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
				end
				
				status = obj.config_parameter('NbrRoundRobins', avgVal.nbrRoundRobins);

                status = obj.config_parameter('DitherRange', avgVal.ditherRange);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
                end

                status = obj.config_parameter('TrigResync', avgVal.trigResync);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
				end

				% compute delay points (must be an multiple of 16 of the
				% sample interval)
				horizontal = obj.horizontal;
				delayPts = round(horizontal.delayTime / horizontal.sampleInterval);
				delayPts = delayPts - mod(delayPts, 16);

				avgVal.data_start = delayPts;
				avgVal.data_stop = 0;
				
                status = obj.config_parameter('StartDelay', avgVal.data_start);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
                end

                status = obj.config_parameter('StopDelay', avgVal.data_stop);
                if (status ~= 0)
                    disp(sprintf('Error in AqD1_configAvgConfigInt32: %d', status));
                end
            else
                disp(sprintf('Error in set averager - arg should be struct with fields of record_length, nbrSegments, num_avg, ditherRange, trigResync, data_start, and data_stop'));
            end
       end

    end % end instrument parameter accessors

end % end classdef

%---END OF FILE---%

