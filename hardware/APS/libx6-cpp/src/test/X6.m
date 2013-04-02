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
        
        function val = enableTestGenerator(aps,mode,rate)
            val = aps.libraryCall('enable_test_generator', mode,rate);
        end
        
        function val = disableTestGenerator(aps)
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
            
            if (~x6.is_open)
                error('Could not open aps')
            end
            
            x6.init();
            
            fprintf('current logic temperature = %.2f\n', x6.getLogicTemperature());
            
            fprintf('current PLL frequency = %.2f\n', x6.samplingRate);
            
            fprintf('setting trigger source = INTERNAL\n');
            
            x6.triggerSource = 'internal';
            x6.setDebugLevel(5);
            
            
            fprintf('set channel(0) enabled = 1\n');
            
            x6.setEnabled(1,true);
            
            
            fprintf('enable ramp output\n');
            x6.samplingRate = 1000;
            x6.enableTestGenerator(x6.TEST_MODE_RAMP,0.001);
            
            pause(5);
            
            fprintf('enable sine wave output\n');
            
            x6.disableTestGenerator();
            x6.samplingRate = 100;
            x6.enableTestGenerator(x6.TEST_MODE_SINE,0.1);
            
            pause(5);
            
            fprintf('disabling channel\n');
            x6.disableTestGenerator();

            fprintf('Load Square Wavew\n');
            %Load a square wave
            wf = [1*ones([1,500]) -1*ones([1,500])];
            for ch = 1
                x6.loadWaveform(ch, wf);
                x6.setRunMode(ch, x6.RUN_WAVEFORM);
            end
            x6.samplingRate = 50;
            fprintf('Run\n');
            x6.run();
            %keyboard
            pause(10)
            fprintf('Stop\n');
            x6.stop();
            
            x6.setEnabled(1,false);
            
            x6.disconnect();
            unloadlibrary('libx6')
        end
        
    end
    
end