classdef X6 < hgsetget
    
    properties (Constant)
        library_path = '../../build/';
    end
    
    properties
        samplingRate = 1000;
        triggerSource
        reference
        bufferSize = 0;
        is_open = 0;
        deviceID = 0;
    end
    
    methods
        function obj = X6()
            obj.load_library();
        end

        function val = connect(obj, id)
            val = calllib('libx6adc', 'connect_by_ID', id);
            if (val == 0)
                obj.is_open = 1;
                obj.deviceID = id;
            end
        end

        function val = disconnect(obj)
            val = obj.libraryCall('disconnect');
            obj.is_open = 0;
        end

        function delete(obj)
            if (obj.is_open)
                obj.disconnect();
            end
        end

        function val = num_devices(obj)
            val = calllib('libx6adc', 'get_num_devices');
        end

        function val = init(obj)
            val = obj.libraryCall('initX6');
        end

        function val = get.samplingRate(obj)
            val = obj.libraryCall('get_sampleRate');
        end

        function set.samplingRate(obj, rate)
            val = obj.libraryCall('set_sampleRate', rate);
        end

        function val = get.triggerSource(obj)
            val = obj.libraryCall('get_trigger_source');
        end

        function set.triggerSource(obj, source)
            obj.libraryCall('set_trigger_source', source);
        end
        
        function set.reference(obj, reference)
            valMap = containers.Map({'int', 'internal', 'ext', 'external'}, {0, 0, 1, 1});
            obj.libraryCall('set_reference_source', valMap(lower(reference)));
        end
        
        function val = get.reference(obj)
            val = obj.libraryCall('get_reference_source');
        end
        
        function val = set_channel_enable(obj, channel, enable)
            val = obj.libraryCall('set_channel_enable', channel-1, enable);
        end
        
        function val = get_channel_enable(obj, channel)
            val = obj.libraryCall('get_channel_enable', channel-1);
        end

        function val = set_averager_settings(obj, recordLength, numSegments, waveforms, roundRobins)
            val = obj.libraryCall('set_averager_settings', recordLength, numSegments, waveforms, roundRobins);
            obj.bufferSize = recordLength * numSegments * waveforms * roundRobins;
        end

        function val = acquire(obj)
            val = obj.libraryCall('acquire');
        end

        function val = wait_for_acquisition(obj, timeout)
            val = obj.libraryCall('wait_for_acquisition', timeout);
        end

        function val = stop(obj)
            val = obj.libraryCall('stop');
        end

        function wf = transfer_waveform(obj, ch)
            % possibly more efficient to pass a libpointer, but this is easiest for now
            bufferPtr = libpointer('int16Ptr', zeros(obj.bufferSize, 1, 'int16'));
            success = obj.libraryCall('transfer_waveform', ch, bufferPtr, obj.bufferSize);
            if success ~= 0
                error('transfer_waveform failed');
            end
            wf = bufferPtr.Value;
        end
        
        function val = writeRegister(obj, addr, offset, data)
            % get temprature using method one based on Malibu Objects
            val = obj.libraryCall('write_register', addr, offset, data);
        end

        function val = readRegister(obj, addr, offset)
            % get temprature using method one based on Malibu Objects
            val = obj.libraryCall('read_register', addr, offset);
        end

        
        function val = getLogicTemperature(obj)
            % get temprature using method one based on Malibu Objects
            val = obj.libraryCall('get_logic_temperature', 0);
        end
    end
    
    methods (Access = protected)
        % overide APS load_library
        function load_library(obj)
            %Helper functtion to load the platform dependent library
            switch computer()
                case 'PCWIN64'
                    libfname = 'libx6adc.dll';
                    libheader = '../X6ADC/libx6adc.h';
                    %protoFile = @obj.libaps64;
                otherwise
                    error('Unsupported platform.');
            end
            % build library path and load it if necessary
            if ~libisloaded('libx6adc')
                loadlibrary(fullfile(obj.library_path, libfname), libheader );
                %Initialize the APSRack in the library
                calllib('libx6adc', 'init');
            end
        end

        function val = libraryCall(obj,func,varargin)
            %Helper function to pass through to calllib with the X6 device ID first 
            if ~(obj.is_open)
                error('X6:libraryCall','X6 is not open');
            end
                        
            if size(varargin,2) == 0
                val = calllib('libx6adc', func, obj.deviceID);
            else
                val = calllib('libx6adc', func, obj.deviceID, varargin{:});
            end
        end
    end
    
    methods (Static)
        
        function setDebugLevel(level)
            % sets logging level in libx6.log
            % level = {logERROR=0, logWARNING, logINFO, logDEBUG, logDEBUG1, logDEBUG2, logDEBUG3, logDEBUG4}
            calllib('libx6adc', 'set_logging_level', level);
        end
        
        function UnitTest()
            
            fprintf('BBN X6-1000 Test Executable\n')
            
            x6 = X6();
            
            x6.setDebugLevel(5);
            
            x6.connect(0);
            
            if (~x6.is_open)
                error('Could not open aps')
            end
            x6.init();

            fprintf('current logic temperature = %.1f\n', x6.getLogicTemperature());
            
            fprintf('current PLL frequency = %.2f GHz\n', x6.samplingRate/1e9);
            fprintf('Setting clock reference to external\n');
            x6.reference = 'external';
            
            x6.set_channel_enable(2, 0);
            
            phase_increment = 4/50;
            fprintf('Setting NCO phase offset to %.3f\n', phase_increment);
            x6.writeRegister(hex2dec('700'), 16, round(4 * phase_increment * 2^16));
            
            fprintf('setting averager parameters to record 10 segments of 2048 samples\n');
            x6.set_averager_settings(2048, 10, 1, 1);
            x6.writeRegister(hex2dec('700'), 0, 2048);
            x6.writeRegister(hex2dec('700'), 1, 512);
            x6.writeRegister(hex2dec('700'), 2, 512);
%             fprintf('setting averager parameters to record 1 segment of 1024 samples\n');
%             x6.set_averager_settings(1024, 1, 1, 1);

            fprintf('Acquiring\n');
            x6.acquire();

            success = x6.wait_for_acquisition(1);
            fprintf('Wait for acquisition returned %d\n', success);

            fprintf('Stopping\n');
            x6.stop();

            fprintf('Transferring waveform channels 1 and 2\n');
            wf1 = x6.transfer_waveform(1);
            wf2 = x6.transfer_waveform(11);
            wf3 = x6.transfer_waveform(12);
            figure();
            subplot(3,1,1);
            plot(wf1);
            title('ch1');
            subplot(3,1,2);
            plot(wf2, 'r');
            title('ch2');
            subplot(3,1,3);
            plot(wf3, 'r');
            title('ch3');
            
            x6.disconnect();
            unloadlibrary('libx6adc')
        end
        
    end
    
end