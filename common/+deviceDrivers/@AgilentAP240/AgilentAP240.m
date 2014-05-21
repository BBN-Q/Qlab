classdef AgilentAP240 < hgsetget
    %Agilent Acqiris AP120
    %
    %
    % Author(s): rrhain
    % 04/14/2010
    % Refactored: Colm Ryan 19 March 2012
    
    events
        DataReady
    end
    
    
    % Class-specific constant properties
    properties (Constant = true)
        clockTypes = containers.Map({'int', 'ext', 'ref'}, {0, 1, 2});
        maxAveragingSamples = 8000*1024;
    end % end constant properties
    
    properties (Access = public)
        instrID; %
        resourceName = 'PCI::INSTR0';
        model_number = 'AP120';
        name; 
        Address;
        channel_on; % sets or queries which channels are currently on
        triggerSource; % which channel supplies the trigger
        acquireMode;  %fieldnames of value and flags
        clockType; % internal, external, or external reference
        settings; % Cache everything!  Huzzah!
        buffers;
        data; % Dummy to make us look like an alazar
        
        memory;  %fields of recordLength and nbrSegments
        %recordLength - Nominal number of samples to record
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
        %than -(sampInterval * recordLength), which
        %corresponds to 100% pre-trigger.
        
        vertical;   %Configures the vertical control parameters
        %for a specified channel of the digitizer.
        %fields of vert_channel, verticalScale, offset, verticalCoupling, bandwidth
        %vert_channel - 1...Nchan, or –1,… for the External Input
        %verticalScale - in Volts, but see triggerSource below
        %offset - in Volts
        %verticalCoupling - = 0 Ground (Averagers ONLY)
        %				 = 1 DC, 1 MΩ
        %				 = 2 AC, 1 MΩ
        %				 = 3 DC, 50 Ω
        %				 = 4 AC, 50 Ω
        
        
        trigger;   %Configures the trigger source control parameters
        %for the specified trigger source
        %(channel or External).
        %fields of trigChannel, triggerCoupling, trigger_slope,
        %triggerLevel, triggerLevel2
        
        %trigChannel - > 1 for internal, <-1 for exernal
        
        %triggerCoupling - 0 DC, 1 AC, 2 HF (if available),
        %3 DC 50W, 4 AC 50W both external trigger only
        
        %trigger_slope - 0  Positive, 1  Negative,
        %2 out of Window, 3  into Window, 4  HF divide,
        %5  Spike Stretcher
        
        %triggerLevel  Trigger threshold in % of the
        %vertical Full Scale of the channel
        %or in mV if using an External trigger src
        
        %triggerLevel2 Trigger threshold 2 (as above) for
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
        %fields of recordLength, nbrSegments, num_avg,
        %ditherRange, trigResync, data_start, data_stop
        
        %recordLength  - Number of data samples per waveform segment.
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
        %recordLength, in samples, need to be multiple of 16
        
        %data_stop - point to stop at, value between 16 and
        %recordLength ,in samples, need to be multiple of 16
        
        timeout = 10000;   %Timeout for acquisition in milliseconds
        
        
        
        %horz_scale; % time in seconds coresponding to 50 points of a waveform
        %trigger_position; % relative position of trigger on horizontal trace (0-100%)
        
        %vert_position; % pre-digitization offset
        %verticalOffset; % post-digitization offset
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
        function obj = AgilentAP240()
            AqRoot=getenv('AcqirisDxRoot');
            if isempty(AqRoot)
                error('It seems the Agilent AP240 is not installed on this computer.')
            end
            addpath([AqRoot,'\bin']);
            addpath([AqRoot,'\MATLAB\mex'],[AqRoot,'\MATLAB\mex\functions']);
            obj.channel_on = 1;
            obj.triggerSource = -1;
            obj.reset();
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
            persistent AcquirisBeenCalibrated
            AcquirisBeenCalibrated = false;
            if isempty(AcquirisBeenCalibrated) || ~AcquirisBeenCalibrated
                options = 'CAL=TRUE';
            else
                options = 'CAL=FALSE';
            end
            [status instrumentID] = Aq_InitWithOptions(obj.resourceName, 0, 0, options);
            obj.error_check(status);
            AcquirisBeenCalibrated = false;
            
            obj.instrID  = instrumentID;
            
            % Retrieve digitizer position
            status = Aq_getInstrumentData(instrumentID);
            assert(status == 0, 'Error in Aq_getInstrumentData: %d', status);
            
        end % end reset
        
        %%destructor the device
        function delete(obj)
            disp('Cleaning up Agilent Test Card');
            % Close the instrument
            Aq_close(obj.instrID);
            
            % Free remaining resources
            Aq_closeAll();
        end
        
        % disconnect device
        function disconnect(obj)
            if isvalid(obj)
                delete(obj);
            end
        end
        
        % instrument meta-setter
        function setAll(obj, settings)
            obj.stop();            
            obj.settings = settings;
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
                        obj.trigger = settings.trigger;
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
            obj.error_check(status);            
        end
        
        %%put in acquisition mode
        function status = acquire(obj)
            % Start the acquisition
            status = AqD1_acquire(obj.instrID);
            assert(status == 0, 'Error in AqD1_acquire: %d', status);
        end
        
        %%wait for acquisition - will timeout in timeout seconds if it
        %fails to acquire
        function status = wait_for_acquisition(obj, timeout)
            
            %Convert default to seconds
            if ~exist('timeout', 'var')
                timeout = obj.timeout/1000;
            end
            
            % maximum timeout value for AqD1_waitForEndOfAcquisition is 10
            % seconds. If caller wants to wait longer, need to loop
            % However, this locks the whole GUI which is an irritation so we'll
            % check every half second and redraw
            
            recheck_time=0.01;
            strt=now();
            %Wait for end of acquisition
            while now() < strt+timeout
                status = AqD1_waitForEndOfAcquisition(obj.instrID, min(timeout,recheck_time)*1000);
                if status == 0
                    break; % we don't have to continue looping if we are already done
                else
                    %Flush the event queue
                    drawnow;
                end
            end
            obj.error_check(status);            
        end
        
        %%do a single acquisition of an averaged waveform
        function status = acquireSingleTrace(obj)
            acquire(obj);
            
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
            AqReadParameters.nbrSamplesInSeg = obj.averager.recordLength;
            AqReadParameters.segmentOffset = obj.averager.recordLength;
            % SC: dataArraySize should be at least recordLength * nbrSegments *
            % size_of_dataType - see the discusiion of AcqrsD1_readData function in the
            % Programmer Reference
            
            AqReadParameters.dataArraySize = (obj.averager.recordLength + 32) * obj.averager.nbrSegments * 8;
            
            % SC: Segment Descriptor for Averaged Waveforms (readMode = 2,5,6) in AqSegmentDescriptorAvg
            AqReadParameters.segDescArraySize = 40 * obj.averager.nbrSegments;
            
            AqReadParameters.flags = 0;
            AqReadParameters.reserved = 0;
            AqReadParameters.reserved2 = 0.0;
            AqReadParameters.reserved3 = 0.0;
            
            % Read the channel waveform
            [status dataDesc , ~, AqDataBuffer] = AqD1_readData(obj.instrID, channel, AqReadParameters);
            
            % chop off initial unused points
            nbrSamples = obj.averager.recordLength * obj.averager.nbrSegments;
            % fix off-by-five(?) error in indexFirstPoint
            firstPt = 6;
            %firstPt = dataDesc.indexFirstPoint;
            AqDataBuffer = single(reshape(AqDataBuffer(1:nbrSamples), obj.averager.recordLength, obj.averager.nbrSegments));
            % lop off first 5 points from each segment
            AqDataBuffer = AqDataBuffer(firstPt:end, :);
            
            times = linspace(firstPt*double(dataDesc.sampTime),double(obj.averager.recordLength - 1) * double(dataDesc.sampTime),obj.averager.recordLength-firstPt+1);
            obj.error_check(status);            
        end
        function download_buffer(obj, timeout,~) % For compatibility with alazar card
           wait_for_acquisition(obj,timeout);                    
           obj.data{1} = single(obj.transfer_waveform(1));
           obj.data{2} = single(obj.transfer_waveform(2));
        end
    end % end methods
    methods % Instrument parameter accessors
        %% get - gets query the card - no parameters really stored in the object
        function stop(obj)
            status = AqD1_stopAcquisition(obj.instrID);
            obj.error_check(status);
        end
        
        %% fake method for ATS9870 compatibility.
        function clear_buffer(obj, num)
           % We don't have no steenking buffers 
        end
        function cleanup_buffers(obj)
           % We don't have no steenking buffers 
        end
        
        function val = get.acquireMode(obj)
            modeMap = containers.Map({0,2},{'digitizer', 'averager'});

            [status mode , ~, flags] = AqD1_getMode(obj.instrID);
            if (status ~= 0)
                fprintf('Error in AqD1_getMode: %d', status);
                val.value = -10;
                val.flags = -10;
            else
                val.value = mode;
                val.flags = flags;
            end
            val=modeMap(val.value);
        end
        
        function val = get.clockType(obj)
            [~, clock] = AqD1_getExtClock(obj.instrID);
            clockTypesInv = invertMap(obj.clockTypes);
            val = clockTypesInv(clock);
        end
        
        function val = get.memory(obj)
            [status recordLength nbrSegments] = AqD1_getMemory(obj.instrID);
            if (status ~= 0)
                fprintf('Error in AqD1_getMemory: %d', status);
                val.recordLength = -10;
                val.nbrSegments = -10;
            else
                val.recordLength = recordLength;
                val.nbrSegments = nbrSegments;
            end
            
        end
        
        function val = get.horizontal(obj)
            [status sampleInterval delayTime] = AqD1_getHorizontal(obj.instrID);
            assert(status == 0, 'Error in AqD1_getHorizontal: %d', status);
            val.sampleInterval = sampleInterval;
            val.samplingRate = 1/sampleInterval;
            val.delayTime = delayTime;
        end
        
        function val = get.vertical(obj)
            %worry about channel specification
            channel = 1;
            [status verticalScale offset verticalCoupling bandwidth]= AqD1_getVertical(obj.instrID, channel);
            assert(status == 0, 'Error in AqD1_getVertical: %d', status);
            %have to be carefull about keeping channel_on == vertical.vert_channel
            val.verticalScale = verticalScale;
            val.offset = offset;
            val.verticalCoupling = verticalCoupling;
            val.bandwidth = bandwidth;
        end
        
        function val = get.trigger(obj)
            %get trigger source
            [status triggerCoupling triggerSlope triggerLevel triggerLevel2] = AqD1_getTrigSource(obj.instrID, obj.triggerSource);
            assert(status == 0, 'Error in AqD1_getTrigSource: %d', status);
            val.triggerCoupling = triggerCoupling;
            val.triggerSlope = triggerSlope;
            val.triggerLevel = triggerLevel;
            val.triggerLevel2 = triggerLevel2;
        end
        
        function val = get.triggerClass(obj)
            [status trigClass sourcePattern] = AqD1_getTrigClass(obj.instrID);
            assert(status == 0, 'Error in AqD1_getTrigSource: %d', status);
            val.trigClass = trigClass;
            val.sourcePattern = dec2hex(-sourcePattern);
        end
        
        function val = get.averager(obj)
            %Metafunction which gets all of the averaging parameters
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'NbrSamples');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.recordLength = -10;
            else
                val.recordLength = retVal;
            end
            
            % SC: configure the number of segments
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'NbrSegments');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.nbrSegments = -10;
            else
                val.nbrSegments = retVal;
            end
            
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'NbrWaveforms');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.nbrWaveforms = -10;
                val.num_avg = -10;
            else
                val.nbrWaveforms = retVal;
                val.num_avg = retVal;
            end
            
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'DitherRange');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.ditherRange = -10;
            else
                val.ditherRange = retVal;
            end
            
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'TrigResync');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.trigResync = -10;
            else
                val.trigResync = retVal;
            end
            
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'StartDelay');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.data_start = -10;
            else
                val.data_start = retVal;
            end
            
            [status retVal] = AqD1_getAvgConfigInt32(obj.instrID, obj.channel_on, 'StopDelay');
            if (status ~= 0)
                fprintf('Error in AqD1_getAvgConfigInt32: %d', status);
                val.data_stop = -10;
            else
                val.data_stop = retVal;
            end
            
        end
        
        %% set - sets parameters on the card almost instantaneously -
        % no parameters really stored in the object
        
        function obj = set.acquireMode(obj, mode)
            assert(isa(mode, 'char'), 'mode must be "digitizer" or "averager"');
            modeMap = containers.Map({'digitizer', 'averager'}, {0, 2});
            status = AqD1_configMode(obj.instrID, modeMap(lower(mode)), 0, 0);
            obj.error_check(status);
            obj.acquireMode = mode;
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
            assert(status==0, 'Error in AqD1_configExtClock: %d', status);
        end
        
        %%not really useful for the averager mode - left it in anyway
        function obj = set.memory(obj, memVal)
            if (isfield(memVal, 'recordLength') && isfield(memVal, 'nbrSegments'))
                status = AqD1_configMemory(obj.instrID, memVal.recordLength, memVal.nbrSegments);
                assert(status == 0, 'Error in AqD1_configMemory: %d', status);
            else
                error('Error in set memory - arg should be struct with fields of recordLength and nbrSegments');
            end
        end
        
        function obj = set.horizontal(obj, horzVal)
            if (isfield(horzVal, 'samplingRate') && isfield(horzVal, 'delayTime'))
                %Set horizontal timing (sampleInterval and delayTime)
                status = AqD1_configHorizontal(obj.instrID, 1/horzVal.samplingRate, horzVal.delayTime);
                assert(status == 0, 'Error in AqD1_configHorizontal: %d', status);
            else
                error('Error in set horizontal - arg should be struct with fields of samplingRate and delayTime');
            end
        end
                
        function obj = set.vertical(obj, vertVal)
            couplings=struct('Ground',0,'DC_highZ',1,'AC_highZ',2,'DC',3,'AC',4);
            bandwidthMap = containers.Map({'Full','25MHz','700MHz','200MHz','20MHz','35MHz'}, {0,1,2,3,4,5});          
			if ~isfield(vertVal,'verticalOffset')
				vertVal.verticalOffset = 0; % Give reasonable defaults
			end
            if (isfield(vertVal, 'verticalScale') && isfield(vertVal, 'verticalOffset')&& isfield(vertVal, 'verticalCoupling') && isfield(vertVal, 'bandwidth'))
                %Configure vertical settings, should vert_channel be obj or vertVal
                %status = AqD1_configVertical(obj.instrID, obj.channel_on, vertVal.verticalScale, vertVal.offset, vertVal.verticalCoupling, vertVal.bandwidth);
                % hard coded to set both channels identically, though this
                % is not required by the hardware
                status = AqD1_configVertical(obj.instrID, 1, vertVal.verticalScale, vertVal.verticalOffset, couplings.(vertVal.verticalCoupling), bandwidthMap(vertVal.bandwidth));
                obj.error_check(status);
                
                status = AqD1_configVertical(obj.instrID, 2, vertVal.verticalScale, vertVal.verticalOffset, couplings.(vertVal.verticalCoupling), bandwidthMap(vertVal.bandwidth));
                obj.error_check(status);
            else
                error('Error in set vertical - arg should be struct with fields of verticalScale, offset, verticalCoupling, and bandwidth');
            end
        end
                
        function obj = set.trigger(obj, trigSrcVal)
            couplings = struct('DC',0,'AC',1,'HFreject',2);      
            sources = struct('Ext',-1,'Int',1);
            slopes=struct('rising',0);
            if (isfield(trigSrcVal, 'triggerCoupling')&& isfield(trigSrcVal, 'triggerSlope') && isfield(trigSrcVal, 'triggerLevel'))
                if (~isfield(trigSrcVal, 'triggerLevel2'))
                    trigSrcVal.triggerLevel2 = trigSrcVal.triggerLevel;
                end
                %Configure trigger source
                if isfield(trigSrcVal, 'triggerSource')
                    obj.triggerSource = trigSrcVal.triggerSource;
                end                
                status = AqD1_configTrigSource(obj.instrID, sources.(obj.triggerSource), couplings.(trigSrcVal.triggerCoupling), slopes.(trigSrcVal.triggerSlope), trigSrcVal.triggerLevel, trigSrcVal.triggerLevel2);
                obj.error_check(status);
            else
                error('Error in set trigger - arg should be struct with fields of triggerCoupling, trigger_slope, triggerLevel, triggerLevel2');
            end
        end
        
        function obj = set.triggerClass(obj, trigClsVal)
            if isscalar(trigClsVal)
                %status = AqD1_configTrigClass(obj.instrID, 0,  hex2dec('80000000'), 0, 0, 0, 0);
                %last 4 args unused - set to 0
                switch obj.triggerSource
                    case -1
                    case 'Ext'
                        sourcePattern = hex2dec('80000000');
                    case 1
                        sourcePattern = 1;
                    case 2
                        sourcePattern = 2;
                    otherwise
                        error('unexpected value for triggerSource')
                end
                status = AqD1_configTrigClass(obj.instrID, trigClsVal, sourcePattern, 0, 0, 0, 0);
                assert(status==0, 'Error in AqD1_configTrigClass: %d', status);
            else
                error('Error in set triggerClass - arg should be struct with fields of trigClass and sourcePattern');
            end
        end
        
        function obj = set.averager(obj, avgVal)
            avgVal=obj.def(avgVal,'ditherRange',15);
            avgVal=obj.def(avgVal,'trigResync',1);
            avgVal=obj.def(avgVal,'data_stop',0);
            obj.buffers.roundRobinsPerBuffer=avgVal.nbrRoundRobins/avgVal.nbrSoftAverages;
            obj.buffers.numBuffers=1;
            if(isfield(avgVal, 'recordLength') && isfield(avgVal, 'nbrSegments') && (isfield(avgVal, 'num_avg') || isfield(avgVal, 'nbrWaveforms')) && isfield(avgVal, 'nbrRoundRobins') &&isfield(avgVal, 'ditherRange') && isfield(avgVal, 'trigResync'))
                
                %Check we fit the memory of the board
                assert(avgVal.recordLength*avgVal.nbrSegments < obj.maxAveragingSamples, 'Oops! You have asked for too many total samples: %d where the card can only store %d', avgVal.recordLength*avgVal.nbrSegments, obj.maxAveragingSamples);
                
                %Metafunction which configures all of the averaging parameters
                obj.channel_on = 0;
                status = obj.config_parameter('NbrSamples', avgVal.recordLength);
                assert(status==0, 'Error in AqD1_configAvgConfigInt32: %d', status);
                
                % SC: configure the number of segments
                assert(avgVal.nbrSegments < 8192, 'Maximum number of segments is 8192');
                status = obj.config_parameter('NbrSegments', avgVal.nbrSegments);
                assert(status == 0, 'Error in AqD1_configAvgConfigInt32: %d', status);
                
                % use either num_avg or nbrWaveforms (whichever was set)
                if (isfield(avgVal, 'nbrWaveforms'))
                    nbrWaveforms = avgVal.nbrWaveforms;
                else
                    nbrWaveforms = avgVal.num_avg;
                end
                assert(nbrWaveforms < 65535, 'Maximum number of waveforms is 65535');
                status = obj.config_parameter('NbrWaveforms', nbrWaveforms);
                assert(status == 0, 'Error in AqD1_configAvgConfigInt32: %d', status);
                
                obj.config_parameter('NbrRoundRobins', avgVal.nbrRoundRobins/avgVal.nbrSoftAverages);
                
                status = obj.config_parameter('DitherRange', avgVal.ditherRange);
                assert(status == 0, 'Error in AqD1_configAvgConfigInt32: %d', status);
                
                status = obj.config_parameter('TrigResync', avgVal.trigResync);
                assert(status == 0, 'Error in AqD1_configAvgConfigInt32: %d', status);
                
                % compute delay points (must be an multiple of 16 of the
                % sample interval)
                delayPts = round(obj.horizontal.delayTime / obj.horizontal.sampleInterval);
                delayPts = delayPts - mod(delayPts, 16);
                
                avgVal.data_start = delayPts;
                avgVal.data_stop = 0;
                
                status = obj.config_parameter('StartDelay', avgVal.data_start);
                assert(status == 0, 'Error in AqD1_configAvgConfigInt32: %d', status);
                
                status = obj.config_parameter('StopDelay', avgVal.data_stop);
                assert(status == 0, 'Error in AqD1_configAvgConfigInt32: %d', status);
            else
                error('Error in set averager - arg should be struct with fields of recordLength, nbrSegments, num_avg, ditherRange, trigResync, data_start, and data_stop');
            end
        end
        
    end % end instrument parameter accessors
        methods(Static)
        function o=def(o,n,v)  % Apply a default
            if ~isfield(o,n)
                o.(n)=v;
            end
        end
        
        function error_check(status)
            switch status
                case 0
                    ;
                case -1074116402
                    fprintf('AgilentAP240: Acqiris calibration failed.  Continuing\n');
                case 1073368576
                    warning('AgilentAP240: Acqiris is adaptable. Be warned');
                otherwise
                    [st,msg]=Aq_errorMessage(0,status);
                    error(sprintf('Error in AgilentAP240 (%d): %s\n',status,msg));
            end
        end
        
    end

end % end classdef

%---END OF FILE---%

