classdef AlazarATS9870 < deviceDrivers.lib.deviceDriverBase
    % Class driver file for Alazar Tech ATS9870 PCI digitizer
    %
    % Author(s): Colm Ryan
    % Code started: 29 November 2011
    
    properties (Access = public)
        
        model_number = 'ATS9870';
        
        %Location of the Matlab include files with the SDK
        includeDir = getpref('qlab','AlazarDir','C:\AlazarTech\ATS-SDK\6.0.3\Samples_MATLAB\Include');
        
        %Dictionary of defined variables
        defs = containers.Map()
        
        %Assume for now we have only one board in the computer so hardcode
        %the system and board identifiers
        systemId = 1
        address = 1
        name = '';
        
        %Handle to the board for the C API
        boardHandle
        
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
        
        %The single-shot or averaged data (depending on the acquireMode)
        data
        
        %Acquire mode controls whether we return single-shot results or
        %averaged data
        acquireMode = 'averager';
        
        %The size of the memory of the card
        onBoardMemory = 256e6;
        
        %How long to wait for a buffer to fill (seconds)
%         timeOut = 10;
        timeOut = 30;
        % timeout increased from 10 seconds to 30 seconds on 1/30/14
        % overnight scans of repeated T1 crapped out, with the error 
        % Error: AlazarWaitAsyncBufferComplete timeout -- Verify trigger!
        % this is an attempt to fix this issue
        
        %All the settings for the device
        settings
        
        %Vertical scale
        verticalScale
        
    end
    
    properties (Dependent = true)
        horizontal; 
        
        vertical;   
        
        trigger;   
        
        
        averager;  
        %ditherRange %needs to be implemented in software
        
        
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
        
        %Stopper for OnCleanUp
        function stop(obj)
            obj.call_API('AlazarAbortAsyncRead', obj.boardHandle);
            %Release any buffers
            for ct = 1:obj.buffers.numBuffers
                clear obj.buffers.bufferPtrs{ct}
            end
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
            %Basically we call the scipt and then save every variable in a
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
            obj.boardHandle = calllib('ATSApi','AlazarGetBoardBySystemID', obj.systemId, address);
        end
        
        function disconnect(obj)
            delete(obj.boardHandle);
        end
        
        %Helper function to make an API call and error check
        function call_API(obj, functionName, varargin)
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
            
            %Post all the buffers to the board
            for ct = 1:obj.buffers.numBuffers
                obj.call_API('AlazarPostAsyncBuffer', obj.boardHandle, obj.buffers.bufferPtrs{ct}, obj.buffers.bufferSize)
            end
            
            %Arm the board
            obj.call_API('AlazarStartCapture', obj.boardHandle);
            
        end
        
        %Wait for the acquisition to complete and average in software
        function status = wait_for_acquisition(obj, timeOut)
            %Dummy status for compatiblity with AP240 driver
            status = 0;
            if ~exist('timeOut','var')
                timeOut = obj.timeOut;
            end
            
            %Total number of buffers to process
            bufferct = 0;
            totNumBuffers = round(obj.settings.averager.nbrRoundRobins/obj.buffers.roundRobinsPerBuffer);
            
            if strcmp(obj.acquireMode, 'averager')
                sumDataA = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments]);
                sumDataB = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments]);
            end
            
            %If we are only getting partial round robins per buffer
            %initialize some indices
            if (obj.buffers.roundRobinsPerBuffer < 1)
                partialBufs = true;
                idx = 1;
                bufStride = obj.buffers.recordsPerBuffer*obj.settings.averager.recordLength;
                obj.data{1} = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, 1], 'single');
                obj.data{2} = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, 1], 'single');

            else
                partialBufs = false;
            end
            
            %Loop until all are processed
            while bufferct < totNumBuffers
                
                %Move to the next buffer
                bufferNum = mod(bufferct, obj.buffers.numBuffers) + 1;
                
                bufferOut = wait_for_buffer(obj, bufferNum, timeOut);
                
                %If we have a full buffer then map the data and add it
                % Since we have turned off interleaving, records are arranged in the buffer as follows:
                % R0A, R1A, R2A ... RnA, R0B, R1B, R2B ...
                %
                % Samples values are arranged contiguously in each record.
                % An 8-bit sample code is stored in each 8-bit sample value.
                
                %Cast the pointer to the right type
                setdatatype(bufferOut, 'uint8Ptr', 1, obj.buffers.bufferSize);
                
                %scale data to floating point using MEX function, i.e. map (0,255) to (-Vs,Vs)
                if strcmp(obj.acquireMode, 'digitizer')
                    if partialBufs
                        [obj.data{1}(idx:idx+bufStride-1), obj.data{2}(idx:idx+bufStride-1)] = ...
                            obj.processBuffer(bufferOut.Value, obj.verticalScale);
                        idx = idx + bufStride;
                        if ((idx-1) == numel(obj.data{1}))
                            idx = 1;
                            notify(obj, 'DataReady');
                        end
                    else
                        [obj.data{1}, obj.data{2}] = obj.processBuffer(bufferOut.Value, obj.verticalScale);
                        obj.data{1} = reshape(obj.data{1}, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer]);
                        obj.data{2} = reshape(obj.data{2}, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer]);
                        notify(obj, 'DataReady');
                    end
                else
                    %scale with averaging over repeats (waveforms and round robins)
                    [obj.data{1}, obj.data{2}] = obj.processBufferAvg(bufferOut.Value, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer], obj.verticalScale);
                    sumDataA = sumDataA + obj.data{1};
                    sumDataB = sumDataB + obj.data{2};
                    notify(obj, 'DataReady');
                end
                
                % Make the buffer available to be filled again by the board
                post_buffer(obj, bufferNum);
                
                bufferct = bufferct+1;
            end
            
            if strcmp(obj.acquireMode, 'averager')
                %Average the summed data
                obj.data{1} = sumDataA/totNumBuffers;
                obj.data{2} = sumDataB/totNumBuffers;
            end

            %Try to abort any in progress acquisitions and transfers
            obj.call_API('AlazarAbortAsyncRead', obj.boardHandle);
            
            %Clear and reallocate the buffer ptrs
            cleanup_buffers(obj);
        end
        
        %Dummy function for consistency with Acqiris card where average
        %data is stored on card
        function [avgWaveform, times] = transfer_waveform(obj, channel)
            avgWaveform = obj.data{channel};
            times = (1/obj.horizontal.samplingRate)*(0:obj.averager.recordLength-1);
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
        
        function download_buffer(obj, timeOut,bufferNum)
            if ~exist('timeOut','var')
                timeOut = obj.timeOut;
            end
            
            % Wait for the first available buffer to be filled by the board
            bufferOut = wait_for_buffer(obj, bufferNum, timeOut);
            
            %If we have a full buffer then map the data and add it
            % Since we have turned off interleaving, records are arranged in the buffer as follows:
            % R0A, R1A, R2A ... RnA, R0B, R1B, R2B ...
            %
            % Samples values are arranged contiguously in each record.
            % An 8-bit sample code is stored in each 8-bit sample value.
            
            %Cast the pointer to the right type
            setdatatype(bufferOut, 'uint8Ptr', 1, obj.buffers.bufferSize);
            
            %scale data to floating point using MEX function, i.e. map (0,255) to (-Vs,Vs)
            if strcmp(obj.acquireMode, 'digitizer')
                [obj.data{1}, obj.data{2}] = obj.processBuffer(bufferOut.Value, obj.verticalScale);
                obj.data{1} = reshape(obj.data{1}, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer]);
                obj.data{2} = reshape(obj.data{2}, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer]);
            else
                %scale with averaging over repeats (waveforms and round robins)
                [obj.data{1}, obj.data{2}] = obj.processBufferAvg(bufferOut.Value, [obj.settings.averager.recordLength, obj.settings.averager.nbrWaveforms, obj.settings.averager.nbrSegments, obj.buffers.roundRobinsPerBuffer], obj.verticalScale);
            end
        end
      
        function post_buffer(obj, bufferNum)
            % Make the buffer available to be filled again by the board
            obj.call_API('AlazarPostAsyncBuffer', obj.boardHandle, obj.buffers.bufferPtrs{bufferNum}, obj.buffers.bufferSize);
        end
        
        function cleanup_buffers(obj)
            %Clear and reallocate the buffer ptrs
            for ct = 1:obj.buffers.numBuffers
                clear obj.buffers.bufferPtrs{ct}
            end
            obj.buffers.bufferPtrs = cell(1, obj.buffers.numBuffers);
            for ct = 1:obj.buffers.numBuffers
                obj.buffers.bufferPtrs{ct} = libpointer('uint8Ptr', zeros(obj.buffers.bufferSize,1));
            end
        end
            
        function status = wait_for_acquisition2(obj, timeOut)
            %Dummy status for compatiblity with AP240 driver
            status = 0;
            if ~exist('timeOut','var')
                timeOut = obj.timeOut;
            end
            
            %Total number of buffers to process
            bufferct = 0;
            totNumBuffers = round(obj.settings.averager.nbrRoundRobins/obj.buffers.roundRobinsPerBuffer);
            
            if strcmp(obj.acquireMode, 'averager')
                sumDataA = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments]);
                sumDataB = zeros([obj.settings.averager.recordLength, obj.settings.averager.nbrSegments]);
            end
            
            while bufferct < totNumBuffers
                
                %Move to the next buffer
                bufferNum = mod(bufferct, obj.buffers.numBuffers) + 1;
                download_buffer(obj, timeOut,bufferNum);
                if strcmp(obj.acquireMode, 'averager')
                    sumDataA = sumDataA + obj.data{1};
                    sumDataB = sumDataB + obj.data{2};
                end
                notify(obj, 'DataReady');
                post_buffer(obj,bufferNum);
                
                %Increment the buffer ct and see if it was the last one
                bufferct = bufferct+1;
                
            end
            
            if strcmp(obj.acquireMode, 'averager')
                %Average the summed data
                obj.data{1} = sumDataA/totNumBuffers;
                obj.data{2} = sumDataB/totNumBuffers;
            end
            %Try to abort any in progress acquisitions and transfers
            obj.call_API('AlazarAbortAsyncRead', obj.boardHandle);
            
            cleanup_buffers(obj);
            
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

            if (guessRecsPerBuffer > recordsPerRoundRobin)
                %Our first guess is just the rounded division
                %However, we also need it to divide into the total number
                %of round robins
                %So find the integer factors of the total (see
                %http://www.mathworks.com/matlabcentral/fileexchange/18364-list-factors)
                factorNumRoundRobins = avgSet.nbrRoundRobins./(1:ceil(sqrt(avgSet.nbrRoundRobins)));
                factorNumRoundRobins = factorNumRoundRobins(factorNumRoundRobins==fix(factorNumRoundRobins)).';
                factorNumRoundRobins  = unique([factorNumRoundRobins; avgSet.nbrRoundRobins./factorNumRoundRobins]);
                
                obj.buffers.roundRobinsPerBuffer = round(guessRecsPerBuffer / recordsPerRoundRobin);
                obj.buffers.roundRobinsPerBuffer = factorNumRoundRobins(find(factorNumRoundRobins < round(guessRecsPerBuffer / recordsPerRoundRobin), 1,  'last'));

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
            
            %Initialize the memory buffers
            %We shouldn't need more than 16 buffers
            obj.buffers.numBuffers = min(numRecords/obj.buffers.recordsPerBuffer, 16);
            obj.buffers.bufferPtrs = cell(1,obj.buffers.numBuffers);
            for ct = 1:obj.buffers.numBuffers
                obj.buffers.bufferPtrs{ct} = libpointer('uint8Ptr', zeros(obj.buffers.bufferSize,1));
            end
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
    end
end %classdef
