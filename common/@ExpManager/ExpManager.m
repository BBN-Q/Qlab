classdef ExpManager < handle
   properties
      
      dataFileHandler
      instruments = struct();
      measurements = {}
      sweeps = {}
      name
      scopes
      AWGs

   end
   
   methods
        %Constructor
        function obj = expManager(name)
            obj.name = name;
        end
        
        %Destructor
        
        %Initialize
        function init(obj, settings)
            
           %For each instrument: connect, setAll
           instrNames = fieldnames(obj.instruments);
           for instr = instrNames'
               instrName= instr{1};
               instrHandle = obj.instruments.(instrName);
               instrHandle.connect(settings.(instrName).address);
               instrHandle.setAll(settings.(instrName));
               if is_scope(instr)
                   obj.scopes{end+1} = instr;
               end
               if is_AWG(instr)
                   obj.AWGs{end+1} = instr;
                   if settings.(instrName).isMaster
                       masterAWGIndex = length(obj.AWGs);
                   end
               end
           end
           
           %Rearrange the AWG list to put the Master first
           obj.awg([1, masterAWGIndex]) = obj.awg([masterAWGIndex, 1]);

           %Open data file
           obj.dataFileHandler.open();
           
           %Connect measurment data to processing callback
           addlistener(obj.scopes{1}, 'DataReady', obj.process_data);
            
        end
        
        %Runner
        function run(obj)
            %Loop over all the sweeps
            for sweepct1 = 1:obj.sweeps{1}.numSteps
                obj.sweeps{1}.step(sweepct1);
                for sweepct2 = 1:obj.sweeps{2}.numSteps
                    obj.sweeps{2}.step(sweepct2);
                    
                    obj.take_data()
                    
                end
            end
            
        end
   
        %Helper function to take data (basically, start/stop AWGs and
        %digitizers)
        function take_data(obj)
            %Stop all the AWGs
            cellfun(stop, obj.AWGs);

            %Ready the digitizers
            cellfun(acquire, obj.scopes);
            
            %Start the slaves up again
            if (length(obj.AWGs) > 1)
                cellfun(run, obj.AWGs{2:end});
            end
            %And the master
            obj.AWGs{1}.run()
            
            %Wait for data taking to finish
            obj.scopes{1}.wait_for_acquisition(120);
           
        end

        %Helper function to apply measurement filters and store data
        function process_data(obj, data)
           %Apply measurment filters in turn
           for measct = 1:length(obj.measurements)
              apply(obj.measurements{measct}, data);
           end
           
        end
        
        %Helpers to flesh out properties
        function add_instrument(obj, instr)
            obj.instruments.(instr.name) = instr;
        end
        
        function add_measurement(obj, meas)
            obj.measurements{end+1} = meas;
        end
        
        function add_sweep(obj, sweep)
            obj.sweeps{end+1} = sweep;
        end
        
        
        
   end
   
    
end