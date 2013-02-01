classdef ExpManager < handle
    properties
        dataFileHandler
        instruments = struct();
        instrSettings = struct();
        measurements = struct();
        sweeps = {}
        data = struct();
        scopes
        AWGs
        listeners = {}
        plotScopeTimer
    end
    
    methods
        %Constructor
        function obj = ExpManager()
        end
        
        %Destructor
        function delete(obj)
            %Clean up the output file
            if isa(obj.dataFileHandler, 'HDF5DataHandler') && obj.dataFileHandler.fileOpen == 1
                obj.dataFileHandler.close();
                obj.dataFileHandler.markAsIncomplete();
            end
            
            %clean up DataReady listeners and plot timer
            cellfun(@delete, obj.listeners);
            delete(obj.plotScopeTimer);
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
        end
        
        %Runner
        function run(obj)
            %Connect measurment data to processing callbacks
            obj.listeners{1} = addlistener(obj.scopes{1}, 'DataReady', @obj.process_data);
            obj.plotScopeTimer = timer('TimerFcn', @obj.plot_scope_callback, 'StopFcn', @obj.plot_scope_callback, 'Period', 0.5, 'ExecutionMode', 'fixedSpacing');
            
            %Set the cleanup function so that even if we ctrl-c out we
            %correctly cleanup
            c = onCleanup(@() obj.cleanUp());
            
            %Start the plot timer
            start(obj.plotScopeTimer);
            
            %Loop over all the sweeps
            idx = 1;
            ct = zeros(length(obj.sweeps));
            stops = cellfun(@(x) x.numSteps, obj.sweeps);
            
            % generic nested loop sweeper through "stack"
            while idx > 0 && ct(1) <= stops(1)
                if ct(idx) < stops(idx)
                    ct(idx) = ct(idx) + 1;
                    fprintf('Stepping sweep %d: %d of %d\n', idx, ct(idx), stops(idx));
                    obj.sweeps{idx}.step(ct(idx));
                    if idx < length(ct)
                        idx = idx + 1;
                    else % inner most loop... take data
                        obj.take_data();
                        % pull data out of measurements
                        stepData = structfun(@(m) m.get_data(), obj.measurements, 'UniformOutput', false);
                        for measName = fieldnames(stepData)'
                            % what we want to do is:
                            % obj.data.(measNames{ct})(ct(1), ct(2), ..., ct(n), :) = stepData{ct};
                            % lacking an idiomatic way to build the generic
                            % assignment, we manually call subsasgn
                            indexer = struct('type', '()', 'subs', {[num2cell(ct), ':']});
                            if ~isfield(obj.data, measName{1})
                                obj.data.(measName{1}) = nan([stops, length(stepData.(measName{1}))]);
                            end
                            obj.data.(measName{1}) = subsasgn(obj.data.(measName{1}), indexer, stepData.(measName{1}));
                        end
                        obj.plot_data()
                    end
                else
                    ct(idx) = 1;
                    idx = idx - 1;
                end
            end
            
        end
        
        function cleanUp(obj)
            % perform any task necessary to clean up (e.g. stop AWGs, turn
            % of uW sources, etc.)
            stop(obj.plotScopeTimer);
            delete(obj.plotScopeTimer);
            %clean up DataReady listeners and plot timer
            cellfun(@delete, obj.listeners);
            % close data file
            obj.dataFileHandler.close();
        end
        
        %Helper function to take data (basically, start/stop AWGs and
        %digitizers)
        function take_data(obj)
            
            %Clear all the measurement filters
            structfun(@(m) reset(m), obj.measurements);
            
            %Stop all the AWGs
            cellfun(@(awg) stop(awg), obj.AWGs);
            
            %Ready the digitizers
            cellfun(@(scope) acquire(scope), obj.scopes);
            
            %Start the slaves up again
            cellfun(@(awg) run(awg), obj.AWGs(2:end))
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
            structfun(@(m) apply(m, data), obj.measurements, 'UniformOutput', false);
        end
        
        function plot_data(obj)
           %Plot the accumulated swept data
            %We keep track of figure handles to not pop new ones up all the
            %time
            persistent figHandles axesHandles plotHandles 
            if isempty(figHandles)
                figHandles = struct();
                axesHandles = struct();
                plotHandles = struct();
            end
            
            for measName = fieldnames(obj.data)'
                measData = squeeze(obj.data.(measName{1}));
                
                if ~isempty(measData)
                    if ~isfield(figHandles, measName{1}) || ~ishandle(figHandles.(measName{1}))
                        figHandles.(measName{1}) = figure('HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', [measName{1} ' - Data']);
                    end
                    figHandle = figHandles.(measName{1});

                    if ~isfield(axesHandles, [measName{1} '_abs']) || ~isfield(plotHandles, [measName{1} '_abs'])
                        axesHandles.([measName{1} '_abs']) = subplot(2,1,1, 'Parent', figHandle);
                        axesHandles.([measName{1} '_phase']) = subplot(2,1,2, 'Parent', figHandle);
                        if length(setdiff(size(measData), 1)) == 1
                            plotHandles.([measName{1} '_abs']) = plot(axesHandles.([measName{1} '_abs']), abs(measData));
                            plotHandles.([measName{1} '_phase']) = plot(axesHandles.([measName{1} '_phase']), (180/pi)*angle(measData));
                        elseif length(setdiff(size(measData), 1)) == 2
                            plotHandles.([measName{1} '_abs']) = imagesc(abs(measData), 'Parent', axesHandles.([measName{1} '_abs']));
                            plotHandles.([measName{1} '_phase']) = imagesc((180/pi)*angle(measData), 'Parent', axesHandles.([measName{1} '_phase']));
                        end
                    else
                        if length(setdiff(size(measData), 1)) == 1
                            set(plotHandles.([measName{1} '_abs']), 'YData', abs(measData));
                            set(plotHandles.([measName{1} '_phase']), 'YData', (180/pi)*angle(measData));
                        elseif length(setdiff(size(measData), 1)) == 2
                            set(plotHandles.([measName{1} '_abs']), 'CData', abs(measData));
                            set(plotHandles.([measName{1} '_phase']), 'CData', (180/pi)*angle(measData));
                        end
                    end
                end
            end
            drawnow()
        end
        
        function plot_scope_callback(obj, ~, ~)
            %We keep track of figure handles to not pop new ones up all the
            %time
            persistent figHandles axesHandles plotHandles 
            if isempty(figHandles)
                figHandles = struct();
                axesHandles = struct();
                plotHandles = struct();
            end
            
            for measName = fieldnames(obj.measurements)'
                data = obj.measurements.(measName{1}).get_data();
                
                if ~isempty(data)
                    if ~isfield(figHandles, measName{1}) || ~ishandle(figHandles.(measName{1}))
                        figHandles.(measName{1}) = figure('HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', [measName{1} ' - Scope']);
                    end
                    figHandle = figHandles.(measName{1});

                    if ~isfield(axesHandles, [measName{1} '_abs']) || ~isfield(plotHandles, [measName{1} '_abs'])
                        axesHandles.([measName{1} '_abs']) = subplot(2,1,1, 'Parent', figHandle);
                        plotHandles.([measName{1} '_abs']) = plot(axesHandles.([measName{1} '_abs']), abs(data));
                        axesHandles.([measName{1} '_phase']) = subplot(2,1,2, 'Parent', figHandle);
                        plotHandles.([measName{1} '_phase']) = plot(axesHandles.([measName{1} '_phase']), (180/pi)*angle(data));
                    else
                        set(plotHandles.([measName{1} '_abs']), 'YData', abs(data));
                        set(plotHandles.([measName{1} '_phase']), 'YData', (180/pi)*angle(data));
                    end
                end
            end
            drawnow()
        end
        
        %Helpers to flesh out properties
        function add_instrument(obj, name, instr, settings)
            obj.instruments.(name) = instr;
            obj.instrSettings.(name) = settings;
        end
        
        function add_measurement(obj, name, meas)
            obj.measurements.(name) = meas;
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