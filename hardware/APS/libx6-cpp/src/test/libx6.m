classdef libx6 < handle
    
    properties (Constant)
        EXTERNAL = 0;
        INTERNAL = 1;
    end
    
    methods (Static)
        
        function val = numDevices()
            val = calllib('libx6', 'get_numDevices');
        end
        
        function val = init()
            val = calllib('libx6', 'init');
        end
        
        function val = connect_by_ID(id)
            val = calllib('libx6', 'connect_by_ID', id);
        end
        
        function val = disconnect_by_ID(id)
            val = calllib('libx6', 'disconnect_by_ID', id);
        end
        
        function val = get_logic_temperature(id)
            val = calllib('libx6', 'get_logic_temperature', id);
        end
        
        function val = get_sampleRate(id)
            val = calllib('libx6', 'get_sampleRate', id);
        end
        
        function val = set_trigger_source(id, source)
            val = calllib('libx6', 'set_trigger_source', id, source);
        end
        
        function val = get_trigger_source(id)
            val = calllib('libx6', 'get_trigger_source', id);
        end
        
        function val = get_channel_enabled(id, channel)
            val = calllib('libx6', 'get_channel_enabled', id, channel);
        end
        
        function val = set_channel_enabled(id,channel , val)
            val = calllib('libx6', 'set_channel_enabled', id, channel, val);
        end
        
        function val = enable_test_generator(id,channel , mode,rate)
            val = calllib('libx6', 'enable_test_generator', id, channel, mode,rate);
        end
        
        function val = disable_test_generator(id)
            val = calllib('libx6', 'disable_test_generator', id);
        end
        
        
        function test()
            if libisloaded('libx6')
                unloadlibrary('libx6')
            end
            
            loadlibrary( ...
                ['../../build/libx6.dll'], ...
                ['../APS/libaps.h']);
            
            fprintf('BBN X6-1000 Test Executable\n')
            
            numDevics = libx6.numDevices();
            fprintf('%i X6 device found\n', numDevices);
            
            if (numDevices < 1) return;
                
                fprintf('Attempting to initialize libaps\n');
                
                libx6.init();
                
                fprintf('connect_by_ID(0) returned %i\n', libx6.connect_by_ID(0));
                
                fprintf('current logic temperature = %.2f\n', libx6.get_logic_temperature(0));
                
                fprintf('current PLL frequency = %.2f\n', libx6.get_sampleRate(0));
                
                fprintf('setting trigger source = EXTERNAL\n');
                
                libx6.set_trigger_source(0, EXTERNAL);
                
                fprintf('get trigger source returns %i\n', libx6.get_trigger_source(0));
                
                ibx6.set_trigger_source(0, INTERNAL);
                
                fprintf('get trigger source returns %i\n', libx6.get_trigger_source(0));
                
                fprintf('get channel(0) enable: %i\n', libx6.get_channel_enabled(0,0));
                
                fprintf('set channel(0) enabled = 1\n');
                
                libx6.set_channel_enabled(0,0,1);
                
                fprintf('enable ramp output\n');
                
                libx6.enable_test_generator(0,0,0.001);
                
                pause(5);
                
                fprintf('enable sine wave output\n');
                
                libx6.disable_test_generator(0);
                libx6.enable_test_generator(0,1,0.001);
                
                pause(5);
                
                fprintf('disabling channel\n');
                libx6.disable_test_generator(0);
                libx6.set_channel_enabled(0,0,false);
                
                libx6.disconnect_by_ID(0);
            end
            
        end
        
    end
end