classdef ExpManager < handle
    properties
        dataFileHandler
        instruments = struct();
        instrSettings = struct();
        measurements = {}
        sweeps = {}
        name
        scopes
        AWGs
        listeners = {}
    end
   
   methods
        %Constructor
        function obj = expManager(name)
            obj.name = name;
        end
        
        %Destructor
        function delete(obj)
            %Clean up the output file
            if isa(obj.dataFileHandler, 'HDF5DataHandler') && obj.dataFileHandler.fileOpen == 1
                obj.dataFileHandler.close();
                obj.dataFileHandler.markAsIncomplete();
            end
            
            %clean up DataReady listeners
            for listener = obj.listeners
                delete(listener{1});
            end
        end
        
        %Initialize
        function init(obj)
            
           %For initialize each instrument via setAll()
           instrNames = fieldnames(obj.instruments);
           for instr = instrNames'
               instrName= instr{1};
               instrHandle = obj.instruments.(instrName);
               instrHandle.setAll(obj.instrSettings.(instrName));
               % keep track of digitizers and AWGs
               if obj.is_scope(instrHandle)
                   obj.scopes{end+1} = instrHandle;
               end
               if obj.is_AWG(instrHandle)
                   obj.AWGs{end+1} = instrHandle;
                   if obj.instrSettings.(instrName).isMaster
                       masterAWGIndex = length(obj.AWGs);
                   end
               end
           end
           
           %Rearrange the AWG list to put the Master first
           obj.AWGs([1, masterAWGIndex]) = obj.AWGs([masterAWGIndex, 1]);

           %Open data file
           % FIX ME
%            header = struct();
%            obj.dataFileHandler.open(header);
           
           %Connect measurment data to processing callback
           obj.listeners{1} = addlistener(obj.scopes{1}, 'DataReady', @obj.process_data);
            
        end
        
        %Runner
        function run(obj)
            %Loop over all the sweeps
            idx = 1;
            ct = zeros(length(obj.sweeps));
            stops = cellfun(@(x) x.numSteps, obj.sweeps);

            while idx > 0 && ct(1) <= stops(1)
                if ct(idx) < stops(idx)
                    ct(idx) = ct(idx) + 1;
                    obj.sweeps{idx}.step(ct(idx));
                    if idx < length(ct)
                        idx = idx + 1;
                    else % inner most loop... take data
                        obj.take_data();
                    end
                else
                    ct(idx) = 1;
                    idx = idx - 1;
                end
            end
            
            obj.cleanUp();
        end
        
        function cleanUp(obj)
            % perform any task necessary to clean up (e.g. stop AWGs, turn
            % of uW sources, etc.)
            obj.dataFileHandler.close();
        end
   
        %Helper function to take data (basically, start/stop AWGs and
        %digitizers)
        function take_data(obj)
            
            %Clear all the measurement filters
            for filter = obj.measurements
                reset(filter{1});
            end
            
            %Stop all the AWGs
            for awg = obj.AWGs
                stop(awg{1});
            end

            %Ready the digitizers
            for scope = obj.scopes
                acquire(scope{1});
            end
            
            %Start the slaves up again
            if length(obj.AWGs) > 1
                for slaveAWG = obj.AWGs{2:end}
                    run(slaveAWG);
                end
            end
            %And the master
            run(obj.AWGs{1});
            
            %Wait for data taking to finish
            obj.scopes{1}.wait_for_acquisition(120);
           
        end

        %Helper function to apply measurement filters and store data
        function process_data(obj, src, ~)
            % download data from src
            data = struct('ch1', src.transfer_waveform(1), 'ch2', src.transfer_waveform(2));
            %Apply measurment filters in turn
            for measct = 1:length(obj.measurements)
                apply(obj.measurements{measct}, data);
                
                figure(measct);
                subplot(2,1,1)
                plot(abs(obj.measurements{measct}.get_data()));
                subplot(2,1,2);
                plot(angle(obj.measurements{measct}.get_data()));
                drawnow()
            end
        end
        
        %Helpers to flesh out properties
        function add_instrument(obj, name, instr, settings)
            obj.instruments.(name) = instr;
            obj.instrSettings.(name) = settings;
        end
        
        function add_measurement(obj, meas)
            obj.measurements{end+1} = meas;
        end
        
        function add_sweep(obj, sweep)
            obj.sweeps{end+1} = sweep;
        end

   end
   
   methods (Static)
       %forward reference static methods
       out = is_scope(instr)
       out = is_AWG(instr)
   end
    
end