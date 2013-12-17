classdef X6 < hgsetget
    
    properties (Constant)
        library_path = '../../build/';
    end
    
    properties
        samplingRate = 1000;
        triggerSource
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
            [val, wf] = obj.libraryCall('transfer_waveform', ch, zeros(obj.bufferSize, 1, 'int16'), obj.bufferSize);
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
            
            x6.connect(0);
            
            if (~x6.is_open)
                error('Could not open aps')
            end
            
            x6.init();
            
            fprintf('current logic temperature = %.2f\n', x6.getLogicTemperature());
            
            fprintf('current PLL frequency = %.2f\n', x6.samplingRate);
            
            % fprintf('setting trigger source = INTERNAL\n');
            
            % x6.triggerSource = 'internal';
            x6.setDebugLevel(5);
            
            fprintf('setting averager parameters to record 10 segments of 1024 samples\n');
            x6.set_averager_settings(1024, 10, 1, 1);

            fprintf('Acquiring\n');
            x6.acquire();

            success = x6.wait_for_acquisition(1);

            fprintf('Wait for acquisition returned %d\n', success);

            fprintf('Stopping\n');
            x6.stop();

            fprintf('Transferring waveform channel 1\n');
            wf = x6.transfer_waveform(1);
            
            x6.disconnect();
            unloadlibrary('libx6adc')
        end
        
    end
    
end