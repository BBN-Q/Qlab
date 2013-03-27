classdef X6 < APS
    
    properties (Constant)
        TEST_MODE_RAMP = 0;
        TEST_MODE_SINE = 1;
    end
    
    methods
        function obj = libx6()
            % call parent contstructor
            obj.library_path = '../../build/';
            obj.samplingRate = 1000;
        end
        
        
        function val = getLogicTemperature(aps)
            val = aps.libraryCall('get_logic_temperature');
        end
        
        function val = enableTestGenerator(mode,rate)
            val = aps.libraryCall('enable_test_generator', mode,rate);
        end
        
        function val = disableTestGenerator(id)
            val = aps.libraryCall('disable_test_generator');
        end
        
    end
    
    methods (Access = protected)
        % overide APS load_library
        function load_library(obj)
            %Helper functtion to load the platform dependent library
            switch computer()
                case 'PCWIN64'
                    libfname = 'libx6.dll';
                    libheader = '../APS/libaps.h';
                    obj.library_name = 'libx6';
                    %protoFile = @obj.libaps64;
                case 'PCWIN'
                    error('Currently on Win64 is supported');
                case 'MACI64'
                    libfname = 'libaps.dylib';
                    error('Need prototype file setup for OS X');
                case 'GLNXA64'
                    libfname = 'libaps.so';
                    error('Need prototype file setup for Linux');
                otherwise
                    error('Unsupported platform.');
            end
            obj.library_path = '../../build/';
            % build library path and load it if necessary
            if ~libisloaded(obj.library_name)
                loadlibrary([obj.library_path libfname], libheader );
                %Initialize the APSRack in the library
                calllib(obj.library_name, 'init');
            end
        end
    end
    
    methods (Static)
        
        function UnitTest()
            
            fprintf('BBN X6-1000 Test Executable\n')
            
            x6 = X6();
            
            x6.connect(0);
            
            if (~aps.is_open)
                error('Could not open aps')
            end
            
            x6.init();
            
            fprintf('current logic temperature = %.2f\n', x6.getLogicTemperature(0));
            
            fprintf('current PLL frequency = %.2f\n', x6.samplingRate);
            
            fprintf('setting trigger source = INTERNAL\n');
            
            aps.triggerSource = 'internal';
            aps.setDebugLevel(5);
            
            
            fprintf('set channel(0) enabled = 1\n');
            
            x6.setEnabled(1,true);
            
            fprintf('enable ramp output\n');
            
            x6.enableTestGenerator(x6.TEST_MODE_RAMP,0.001);
            
            pause(5);
            
            fprintf('enable sine wave output\n');
            
            x6.disableTestGenerator();
            
            x6.enableTest_generator(x6.TEST_MODE_SINE,0.001);
            
            pause(5);
            
            fprintf('disabling channel\n');
            x6.disableTestGenerator();
            
            %Load a square wave
            wf = [zeros([1,2000]) 0.8*ones([1,2000])];
            for ch = 1
                aps.loadWaveform(ch, wf);
                aps.setRunMode(ch, aps.RUN_WAVEFORM);
            end
            
            aps.run();
            keyboard
            aps.stop();
            
            x6.setEnabled(1,false);
            
            x6.disconnect();
            unloadlibrary('libx6')
        end
        
    end
    
end