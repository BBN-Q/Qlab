classdef AlazarATS9870 < deviceDrivers.lib.deviceDriverBase
    % Class driver file for Alazar Tech ATS9870 PCI digitizer
    %
    % Author(s): Colm Ryan
    % Code started: 29 November 2011
    
    properties (Access = public)
        %Assume un-synced boards so that address = 1
        systemId = 1
        address = 1
        name = '';
        
        %The single-shot or averaged data (depending on the acquireMode)
        data
        
        %Acquire mode controls whether we return single-shot results or
        %averaged data
        acquireMode = 'averager';
        
        %How long to wait for a buffer to fill (seconds)
        timeOut = 30;
        lastBufferTimeStamp = 0;
        
        %All the settings for the device
        settings
        
        %Vertical scale
        verticalScale
    end
    
    properties (Access = private)
        %Handle to the board for the C API
        boardHandle
        
        %Dictionary of defined enums
        defs = containers.Map()
        
        %Buffer properties
        %Rough estimate of the buffer size in bytes
        %Notes from Alazar ATS_Average_Sample_0.0.4.pdf
        % Each DMA buffer should be between about 1MB and 16MB to allow for efficient DMA
        % transfers from the digitizer.
        % The DLL requires at least two DMA buffers so that the digitizer can DMA into one
        % buffer while, at the same time, the DLL sums records in another buffer.
        % The DMA buffers form a FIFO between the digitizer and the application. The digitizer
        % fills this FIFO in real-time as it receives triggers, while the DLL empties the FIFO as is
        % sums records and calculates average records. Increasing the number of DMA buffers
        % increases the amount of time that the digitizer can continue to acquire while the
        % application is busy or suspended, and not consuming buffers.
        
        %A structure for the buffers and info
        buffers = struct('guessBufferSize',4*(2^20), 'bufferSize', 0, 'maxBufferSize', 0, 'recordsPerBuffer', 0,...
            'roundRobinsPerBuffer', 0, 'numBuffers', 0, 'bufferPtrs',cell(1));
        
        %variables used by process_buffer
        initializeProcessing
        done
        processingTimer
        bufferct
        idx
        sumDataA
        sumDataB
    end
    
    properties (Dependent = true)
        horizontal; 
        
        vertical;   
        
        trigger;
        
        averager;  
        %ditherRange %needs to be implemented in software
    end
    
    properties (Constant = true)
        model_number = 'ATS9870';
        
        %Location of the Matlab include files with the SDK
        includeDir = getpref('qlab','AlazarDir','C:\AlazarTech\ATS-SDK\6.0.3\Samples_MATLAB\Include');
        
        % The size of the memory of the card
        onBoardMemory = 256e6;
    end
    
    events
        DataReady
    end
    
    methods (Access = public)
        %Constuctor which loads definitions and dll
        function obj = AlazarATS9870()
            
            %Add the include directory to the path
            addpath(obj.includeDir)
            
            %Load the definitions
            obj.load_defs();
            
            %Load the interface DLL
            %Alazar provides a precompiled thunk helper and prototype file
            %for speed so we'll use their helper function
            if ~alazarLoadLibrary()
                error('ATSApi.dll is not loaded\n');
            end
            
            %Assert that we want to be able to use at least two buffers
            obj.buffers.maxBufferSize = obj.onBoardMemory/2;
        end
        
        %Destructor
        function delete(obj)
            obj.stop();
            obj.disconnect();
        end
        
        function load_defs(obj)
            %Parse the definition file and return everything in a structure
            %This is a bit of a hack but I want to leave the defs file
            %untounched so we can easily update the SDK.
            %Basically we call the script and then save every variable in a
            %dictionary
            AlazarDefs
            defNames = who();
            %Matlab could really use a foreach
            for ct = 1:length(defNames)
                if ~strcmp(defNames{ct},'obj')
                    obj.defs(defNames{ct}) = eval(defNames{ct});
                end
            end
            
        end
        
        function connect(obj, address)
            %Get the handle to the board
            %If only one board is installed, address = 1
            if ~isnumeric(address)
                address = str2double(address);
            end
            obj.systemId = address;
            obj.boardHandle = calllib('ATSApi','AlazarGetBoardBySystemID', obj.systemId, obj.address);
        end
        
        function disconnect(obj)
            delete(obj.boardHandle);
        end
        
        %Helper function to make an API call and error check
        function retCode = call_API(obj, functionName, varargin)
            %Make the call
            retCode = calllib('ATSApi', functionName, varargin{:});
            %Check for success
            assert(retCode == obj.defs('ApiSuccess'), 'Error: %s failed -- %s', functionName, errorToText(retCode));
        end
        
        %Function to flash the LED (at least then we know something works).
        function flash_LED(obj, numTimes, period)
            if nargin < 3
                period = 1;
            end
            if nargin < 2
                numTimes = 10;
            end
            for ct = 1:numTimes
                obj.call_API('AlazarSetLED', obj.boardHandle, obj.defs('LED_ON'));
                pause(period/2);
                obj.call_API('AlazarSetLED', obj.boardHandle, obj.defs('LED_OFF'));
                pause(period/2);
            end
        end
        
        %Instrument meta-setter that sets all parameters
        function setAll(obj, settings)
            obj.settings = settings;
            fields = fieldnames(settings);
            for tmpName = fields'
                switch tmpName{1}
                    case 'horizontal'
                        obj.horizontal = settings.horizontal;
                    case 'vertical'
                        obj.vertical = settings.vertical;
                    case 'trigger'
                        obj.trigger = settings.trigger;
                    case 'averager'
                        obj.averager = settings.averager;
                    otherwise
                        if ismember(tmpName{1}, methods(obj))
                            feval(['obj.' tmpName{1}], settings.(tmpName{1}));
                        elseif ismember(tmpName{1}, properties(obj))
                            obj.(tmpName{1}) = settings.(tmpName{1});
                        end
                end
            end
        end
        
        %Setup and start an acquisition
        function acquire(obj)
            %Zero the stored data
            obj.data = cell(2);
            
            %Setup the dual-port asynchronous AutoDMA with NPT mode
            %The acquisition starts automatically because I don't set the
            %ADMA_EXTERNAL_STARTCAPTURE flag
            obj.call_API('AlazarBeforeAsyncRead', obj.boardHandle, obj.defs('CHANNEL_A') + obj.defs('CHANNEL_B'), ...
                -int32(0), obj.settings.averager.recordLength, obj.buffers.recordsPerBuffer, obj.buffers.recordsPerAcquisition, obj.defs('ADMA_NPT') + obj.defs('ADMA_EXTERNAL_STARTCAPTURE'));
            
            %Allocate buffers and post them to the board
            obj.allocate_buffers();
            for ct = 1:obj.buffers.numBuffers
                obj.post_buffer(ct);
            end
            
            %Arm the board
            obj.call_API('AlazarStartCapture', obj.boardHandle);
            
            obj.initializeProcessing = true;
            obj.done = false;
            obj.lastBufferTimeStamp = tic();
            obj.processingTimer = timer('TimerFcn', @obj.process_buffer, 'StopFcn', @(~,~)obj.stop, 'Period', 0.01, 'ExecutionMode', 'fixedDelay');
            start(obj.processingTimer);
        end
        
        function stop(obj)
            delete(obj.processingTimer);
            obj.call_API('AlazarAbortAsyncRead', obj.boardHandle);
            obj.cleanup_buffers();
            obj.done = true;
        end
        
        function process_buffer(obj, ~, ~)
            persistent partialBufs bufStride
            % first call initialization
            if obj.initializeProcessing
                obj.initializeProcessing = false;
                obj.bufferct = 0;
                
                if strcmp(obj.acquireMode, 'averager')
                    obj.sumDataA = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments]);
                    obj.sumDataB = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments]);
                else
                    obj.sumDataA = [];
                    obj.sumDataB = [];
                end
                
                %If we are only getting partial round robins per buffer
                %initialize some indices
                if (obj.buffers.roundRobinsPerBuffer < 1)
                    partialBufs = true;
                    obj.idx = 1;
                    bufStride = obj.buffers.recordsPerBuffer*obj.settings.averager.recordLength;
                    switch obj.acquireMode
                        case 'digitizer'
                            obj.data{1} = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments], 'single');
                            obj.data{2} = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments], 'single');

                        case 'averager'
                            obj.data{1} = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments], 'single');
                            obj.data{2} = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments], 'single');
                    end
                else
                    partialBufs = false;
                end
            end
            
            %Total number of buffers to process
            totNumBuffers = round(obj.settings.averager.nbrRoundRobins/obj.buffers.roundRobinsPerBuffer);
            if obj.bufferct >= totNumBuffers
                if strcmp(obj.acquireMode, 'averager')
                    %Average the summed data
                    obj.data{1} = obj.sumDataA/totNumBuffers;
                    obj.data{2} = obj.sumDataB/totNumBuffers;
                end
                obj.done = true;
                stop(obj.processingTimer);
                return
            end
            
            % continue checking for new data until there are no more
            % waiting buffers to process
            while true
                bufferNum = mod(obj.bufferct, obj.buffers.numBuffers) + 1;
                [retCode, ~, bufferOut] = ...
                    calllib('ATSApi', 'AlazarWaitAsyncBufferComplete', obj.boardHandle, obj.buffers.bufferPtrs{bufferNum}, 0);
                if retCode == obj.defs('ApiWaitTimeout')
                    % no data waiting, bail out
                    return
                elseif retCode ~= obj.defs('ApiSuccess')
                    % The acquisition failed
                    stop(obj.processingTimer);
                    error('Error: AlazarWaitAsyncBufferComplete failed -- %s\n', errorToText(retCode));
                end
            
                % we have a new buffer to process
                
                % set the last buffer timestamp
                obj.lastBufferTimeStamp = tic();
                
                % convert from DAC values to reals and accumulate
                % Since we have turned off interleaving, records are arranged in the buffer as follows:
                % R0A, R1A, R2A ... RnA, R0B, R1B, R2B ...
                %
                % Samples values are arranged contiguously in each record.
                % An 8-bit sample code is stored in each 8-bit sample value.

                % Cast the pointer to the right type
                setdatatype(bufferOut, 'uint8Ptr', 1, obj.buffers.bufferSize);

                % scale data to floating point using MEX function, i.e. map (0,255) to (-Vs,Vs)
                if strcmp(obj.acquireMode, 'digitizer')
                    if partialBufs
                        [obj.data{1}(obj.idx:obj.idx+bufStride-1), obj.data{2}(obj.idx:obj.idx+bufStride-1)] = ...
                            obj.processBuffer(bufferOut.Value, obj.verticalScale);
                        obj.idx = obj.idx + bufStride;
                        if ((obj.idx-1) == numel(obj.data{1}))
                            obj.idx = 1;
                            notify(obj, 'DataReady');
                        end
                    else
                        [obj.data{1}, obj.data{2}] = obj.processBuffer(bufferOut.Value, obj.verticalScale);
                        obj.data{1} = reshape(obj.data{1}, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer]);
                        obj.data{2} = reshape(obj.data{2}, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer]);
                        notify(obj, 'DataReady');
                    end
                else
                    % scale with averaging over repeats (waveforms and round robins)
                    if partialBufs
                        [obj.data{1}(obj.idx:obj.idx+bufStride-1), obj.data{2}(obj.idx:obj.idx+bufStride-1)] = obj.processBufferAvg(bufferOut.Value, [obj.settings.averager.recordLength,...
                            obj.settings.averager.nbrWaveforms, round(obj.settings.averager.nbrSegments*obj.buffers.roundRobinsPerBuffer), 1], obj.verticalScale);
                        obj.idx = obj.idx + bufStride;
                        if ((obj.idx-1) == numel(obj.data{1}))
                            obj.idx = 1;
                            obj.sumDataA = obj.sumDataA + obj.data{1};
                            obj.sumDataB = obj.sumDataB + obj.data{2};
                            notify(obj, 'DataReady');
                        end
                    else
                        [obj.data{1}, obj.data{2}] = obj.processBufferAvg(bufferOut.Value, [obj.settings.averager.recordLength,...
                            obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer], obj.verticalScale);
                        obj.sumDataA = obj.sumDataA + obj.data{1};
                        obj.sumDataB = obj.sumDataB + obj.data{2};
                        notify(obj, 'DataReady');
                    end
                end

                % Make the buffer available to be filled again by the board
                status = post_buffer(obj, bufferNum);
                if status ~= obj.defs('ApiSuccess');
                    stop(obj.processingTimer);
                end

                obj.bufferct = obj.bufferct+1;
            end
        end
        
        %Wait for the acquisition to complete and average in software
        function status = wait_for_acquisition(obj, timeOut)
            if ~exist('timeOut','var')
                timeOut = obj.timeOut;
            end
            
            %Loop until all are processed
            while toc(obj.lastBufferTimeStamp) < timeOut
                if obj.done
                    status = 0;
                    return
                else
                    pause(0.2);
                end
            end
            status = -1;
            warning('AlazarATS9870:TIMEOUT', 'AlazarATS9870 timed out while waiting for acquisition');
        end
        
        % Dummy function for consistency with Acqiris card where average
        % data is stored on card
        function [avgWaveform, times] = transfer_waveform(obj, channel)
            avgWaveform = obj.data{channel};
            times = (1/obj.horizontal.samplingRate)*(0:obj.averager.recordLength-1);
        end
        
        function allocate_buffers(obj)
            obj.cleanup_buffers();
            obj.buffers.bufferPtrs = cell(1,obj.buffers.numBuffers);
            for ct = 1:obj.buffers.numBuffers
                obj.buffers.bufferPtrs{ct} = libpointer('uint8Ptr', zeros(obj.buffers.bufferSize,1));
            end
        end
      
        function status = post_buffer(obj, bufferNum)
            % Make the buffer available to be filled again by the board
            status = obj.call_API('AlazarPostAsyncBuffer', obj.boardHandle, obj.buffers.bufferPtrs{bufferNum}, obj.buffers.bufferSize);
        end
        
        function cleanup_buffers(obj)
            %Clear the buffer ptrs
            for ct = 1:length(obj.buffers.bufferPtrs)
                clear obj.buffers.bufferPtrs{ct}
            end
        end
        
        function buffer = wait_for_buffer(obj, bufferNum, timeOut)
            % Wait for the buffer to be filled by the board
            [retCode, ~, buffer] = ...
                calllib('ATSApi', 'AlazarWaitAsyncBufferComplete', obj.boardHandle, obj.buffers.bufferPtrs{bufferNum}, timeOut*1000);
            if retCode == obj.defs('ApiWaitTimeout');
                % The wait timeout expired before this buffer was filled.
                % The board may not be triggering, or the timeout period may be too short.
                error('Error: AlazarWaitAsyncBufferComplete timeout -- Verify trigger!\n');
            elseif retCode ~= obj.defs('ApiSuccess')
                % The acquisition failed
                error('Error: AlazarWaitAsyncBufferComplete failed -- %s\n', errorToText(retCode));
            end
        end
        
        function acquireStream(obj, samples, triggered)
            c = onCleanup(@() stop(obj));
            %Setup the dual-port asynchronous AutoDMA with triggered
            %streaming mode.
            obj.data = {zeros(samples,1), zeros(samples,1)};
            obj.buffers.bufferSize = min(2*samples, 16*2^20);
            fprintf('Using bufferSize = %d\n', obj.buffers.bufferSize);
            samplesPerBuffer = obj.buffers.bufferSize / 2;
            fprintf('Samples per buffer = %d\n', samplesPerBuffer);
            buffersPerAcquisition = ceil(samples/samplesPerBuffer);
            fprintf('Buffers per acquisition = %d\n', buffersPerAcquisition);
            obj.call_API('AlazarBeforeAsyncRead',...
                         obj.boardHandle, ...
                         obj.defs('CHANNEL_A') + obj.defs('CHANNEL_B'), ...
                         0, ...
                         samplesPerBuffer, ...
                         1, ...
                         buffersPerAcquisition, ...
                         obj.defs('ADMA_EXTERNAL_STARTCAPTURE') + obj.defs('ADMA_TRIGGERED_STREAMING'));
            % allocate and post 16 buffers
            for ct = 1:length(obj.buffers.bufferPtrs)
                clear obj.buffers.bufferPtrs{ct}
            end
            
            obj.buffers.numBuffers = 16;
            obj.buffers.bufferPtrs = cell(1,16);
            for ct = 1:16
                obj.buffers.bufferPtrs{ct} = libpointer('uint8Ptr', zeros(obj.buffers.bufferSize,1));
                post_buffer(obj, ct);
            end
            
            %Arm the board
            obj.call_API('AlazarStartCapture', obj.boardHandle);
            
            idx = 1;
            bufferct = 0;
            stride = samplesPerBuffer;

            disp('Starting');
            while bufferct < buffersPerAcquisition
                bufferNum = mod(bufferct, 16) + 1;
                try
                    bufferOut = wait_for_buffer(obj, bufferNum, 1);
                catch exception
                    stop(obj);
                    rethrow(exception);
                end
                setdatatype(bufferOut, 'uint8Ptr', 1, obj.buffers.bufferSize);
                
                if (idx + stride - 1 > samples)
                    [fullBufferA, fullBufferB] = obj.processBuffer(bufferOut.Value, obj.verticalScale);
                    obj.data{1}(idx:end) = fullBufferA(1:(samples-idx+1));
                    obj.data{2}(idx:end) = fullBufferB(1:(samples-idx+1));
                else
                    [obj.data{1}(idx:idx+stride-1), obj.data{2}(idx:idx+stride-1)] = ...
                        obj.processBuffer(bufferOut.Value, obj.verticalScale);
%                     obj.data{1}(idx:idx+stride-1) = bufferOut.Value(1:end/2);
%                     obj.data{2}(idx:idx+stride-1) = bufferOut.Value(end/2+1:end);
                end
                idx = idx + stride;
                bufferct = bufferct + 1;
                post_buffer(obj, bufferNum);
%                 disp(bufferNum);
            end
            disp('Finished');
        end
        
    end %methods
    %Getter/setters must be in an methods block without attributes
    methods
        %Setters for the card parameters
        function set.horizontal(obj, horzSettings)
            %Set horizontal timing (sampleInterval and delayTime)
            
            %Assume for now that we are using a 10MHz external clock
            %TODO: handle internal/external clock rates
            % values for (int, ext, ref) are (1, 5, 7)
            %Calculate the decimation factor
            decimationFac = round(1e9/horzSettings.samplingRate);
            obj.call_API('AlazarSetCaptureClock', obj.boardHandle, obj.defs('EXTERNAL_CLOCK_10MHz_REF'),1e9,obj.defs('CLOCK_EDGE_RISING'),decimationFac);
            
            %Calculate the trigger delay in sample units
            trigDelayPts = round(horzSettings.delayTime*horzSettings.samplingRate);
            obj.call_API('AlazarSetTriggerDelay', obj.boardHandle, trigDelayPts);
            obj.settings.horizontal = horzSettings;
        end
        
        function set.vertical(obj, vertSettings)
            %Configure vertical settings, should vert_channel be obj or vertSettings
            % hard coded to set both channels identically, though this
            % is not required by the hardware
            %We are always 50Ohm coupled for the ATS9870
            scaleMap = containers.Map({.04, .1, .2, .4, 1, 2, 4}, {2, 5, 6, 7, 10, 11, 12});
            couplingMap = containers.Map({'AC','DC'}, {1, 2});
            
            obj.call_API('AlazarInputControl',obj.boardHandle, obj.defs('CHANNEL_A'), couplingMap(vertSettings.verticalCoupling),...
                                scaleMap(vertSettings.verticalScale), obj.defs('IMPEDANCE_50_OHM'));
            obj.call_API('AlazarInputControl',obj.boardHandle, obj.defs('CHANNEL_B'), couplingMap(vertSettings.verticalCoupling),...
                                scaleMap(vertSettings.verticalScale), obj.defs('IMPEDANCE_50_OHM'));
            
            %Set the bandwidth
            bandwidthMap = containers.Map({'Full','20MHz'}, {0,1}); 
            obj.call_API('AlazarSetBWLimit',obj.boardHandle, obj.defs('CHANNEL_A'), bandwidthMap(vertSettings.bandwidth));
            obj.call_API('AlazarSetBWLimit',obj.boardHandle, obj.defs('CHANNEL_B'), bandwidthMap(vertSettings.bandwidth));
            
            % update obj property
            obj.verticalScale = vertSettings.verticalScale;
            obj.settings.vertical = vertSettings;
        end
        
        function set.trigger(obj, trigSettings)
            
            %If the trigger channel is external then we also need to setup
            %that channel
            couplingMap = containers.Map({'AC','DC'}, {1, 2});
            if(strcmpi(trigSettings.triggerSource, 'Ext'))
                %We can only choose 5V range and triggerLevel comes
                %in mV
                extTrigLevel = obj.defs('ETR_5V');
                trigChannelRange = 5;

                obj.call_API('AlazarSetExternalTrigger',obj.boardHandle,...
                            couplingMap(trigSettings.triggerCoupling), extTrigLevel);
                
                %Otherwise setup the channel
            else
                trigChannelRange = obj.settings.vertical.verticalScale;
                %TODO: implement
                error('Channel triggers not implemented')
            end
            
            %We need to set the trigger level as a percentage of the full
            %range so figure that out
            trigLevelCode = uint8(128 + 127*(trigSettings.triggerLevel/1000/trigChannelRange));
            
            %Set the rest of the trigger parameters
            %We'll default to trigger engine J and single condition for
            %now
            triggerSourceMap = containers.Map({'A', 'B', 'EXT'}, {0, 1, 2});
            triggerSlopeMap = containers.Map({'rising', 'falling'}, {1, 2});
            obj.call_API('AlazarSetTriggerOperation', obj.boardHandle, obj.defs('TRIG_ENGINE_OP_J'), obj.defs('TRIG_ENGINE_J'),...
                        triggerSourceMap(upper(trigSettings.triggerSource)), triggerSlopeMap(trigSettings.triggerSlope), trigLevelCode, ...
                        obj.defs('TRIG_ENGINE_K'), obj.defs('TRIG_DISABLE'), obj.defs('TRIGGER_SLOPE_POSITIVE'), 128);
            
            %We'll wait forever for a trigger
            obj.call_API('AlazarSetTriggerTimeOut', obj.boardHandle, 0);
            obj.settings.trigger = trigSettings;
        end
        
        function set.averager(obj, avgSet)
            %The averaging processing is done in software but we'll use this
            %to allocate the buffers and set the record size etc.

            %Some parameter checking 
            assert(avgSet.recordLength > 256, 'Alazar 9870 requires more than 256 samples.')
            assert(mod(avgSet.recordLength,64) == 0, 'Alazar 9870 requires record length be multiple of 64.')
           
            obj.call_API('AlazarSetRecordSize', obj.boardHandle, 0, avgSet.recordLength);
            
            %Sort out how to allocate the buffer memory
            %Plan is to 
            % 1) See how many records fit into the ideal buffer size. 
            % 2) If this is greater than the number of records in a round
            % robin this is easy as we can then work out an integer number
            % of complete round robins in a buffer.
            % 3) Otherwise, we work out a number of records close to the
            % guess such that an integral number of buffers will give a
            % full round robin.
            
            %The minimum unit we want to deal with is 1 record
            %Since this is a 8 bit digitizer there is one bytes per sample
            %Assume for now we'll always record both channels
            numChannels = 2;
            bytesPerRecord =  numChannels*avgSet.recordLength;

            %See roughly how many records fit into a buffer
            guessRecsPerBuffer = obj.buffers.guessBufferSize / bytesPerRecord;
            
            %Sort out whether we can fit full round robins into the buffer
            recordsPerRoundRobin = avgSet.nbrSegments*avgSet.nbrWaveforms;

            if (guessRecsPerBuffer >= recordsPerRoundRobin)
                %Our first guess is just the rounded division
                %However, we also need it to divide into the total number
                %of round robins
                %So find the integer factors of the total (see
                %http://www.mathworks.com/matlabcentral/fileexchange/18364-list-factors)
                factorNumRoundRobins = avgSet.nbrRoundRobins./(1:ceil(sqrt(avgSet.nbrRoundRobins)));
                factorNumRoundRobins = factorNumRoundRobins(factorNumRoundRobins==fix(factorNumRoundRobins)).';
                factorNumRoundRobins  = unique([factorNumRoundRobins; avgSet.nbrRoundRobins./factorNumRoundRobins]);
                
                obj.buffers.roundRobinsPerBuffer = factorNumRoundRobins(find(factorNumRoundRobins <= round(guessRecsPerBuffer / recordsPerRoundRobin), 1,  'last'));

                %But make sure we have enough round robins to need at least one
                obj.buffers.roundRobinsPerBuffer = min(obj.buffers.roundRobinsPerBuffer, avgSet.nbrRoundRobins);
                obj.buffers.recordsPerBuffer = recordsPerRoundRobin*obj.buffers.roundRobinsPerBuffer;
            else
                factorRecs = recordsPerRoundRobin./(1:ceil(sqrt(recordsPerRoundRobin)));
                factorRecs = factorRecs(factorRecs==fix(factorRecs)).';
                factorRecs  = unique([factorRecs; recordsPerRoundRobin./factorRecs]);
                
                obj.buffers.recordsPerBuffer = factorRecs( find(factorRecs < guessRecsPerBuffer, 1, 'last'));
                obj.buffers.roundRobinsPerBuffer = obj.buffers.recordsPerBuffer / recordsPerRoundRobin;
            end
                
            %The total number of records we want to record
            numRecords = avgSet.nbrSegments*avgSet.nbrWaveforms*avgSet.nbrRoundRobins;
            obj.buffers.recordsPerAcquisition = numRecords;
            
            %Update the buffer size from the guess
            obj.buffers.bufferSize = bytesPerRecord*obj.buffers.recordsPerBuffer;
            
            %Record the number of buffers to use
            obj.buffers.numBuffers = min(numRecords/obj.buffers.recordsPerBuffer, 32);
            
            obj.settings.averager = avgSet;
        end
        
        function val = get.averager(obj)
            %Here the averaging is done in software so we just return the
            %settings passed in. 
            val = obj.settings.averager;
        end
        
        function val = get.horizontal(obj)
            %Alazar doesn't seem to provide a way to get settings out of
            %the card so just return the input settings
            %Fake the sampleInterval
            val = obj.settings.horizontal;
            val.sampleInterval = 1/val.samplingRate;
        end
    end %methods
    methods (Static)
        % externally defined methdos
        [dataA, dataB] = processBuffer(buffer, verticalScale);
        [dataA, dataB] = processBufferAvg(buffer, bufferDims, verticalScale);
        
        function unit_test()
            scope = deviceDrivers.AlazarATS9870();
            scope.connect(0);

            scope.horizontal = struct('samplingRate', 500e6, 'delayTime', 0);
            scope.vertical = struct('verticalScale', 1.0, 'verticalCoupling', 'AC', 'bandwidth', 'Full');
            scope.trigger = struct('triggerLevel', 100, 'triggerSource', 'ext', 'triggerCoupling', 'DC', 'triggerSlope', 'rising');
            scope.averager = struct('recordLength', 4096, 'nbrSegments', 1, 'nbrWaveforms', 1, 'nbrRoundRobins', 1000, 'ditherRange', 0);
            
            scope.acquire();
            success = scope.wait_for_acquisition(10);
            scope.stop();
            
            if success == 0
                [wfm, tpts] = scope.transfer_waveform(1);
                figure();
                plot(tpts, wfm);
            end
            
            scope.disconnect();
        end
    end
end %classdef
