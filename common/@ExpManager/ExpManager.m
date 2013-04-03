% The ExpManager is a fairly generic framework for experiments involving
% swept parameters and digitizing scopes. It creates an asynchronous event
% loop such that data acquisition can happen in a separate thread, and we
% only process the data when it becomes available.
%
% Example usage:
%   exp = ExpManager();
%   exp.dataFileHandler = HDF5DataFileHandler('outfile.h5');
%   % need to add at least one scope
%   exp.add_instrument(InstrumentFactory('scope'));
%   % need to add at least one AWG
%   exp.add_instrument(InstrumentFactory('awg'));
%   % need to add at least one sweep
%   exp.add_sweep(SweepFactory('segmentNum', exp.instruments));
%   % need to add at least one measurement
%   import MeasFilters.*
%   exp.add_measurement(
%       DigitalHomodyne(struct('IFfreq', 10e6, 'channel', 'ch1',
%       'integrationStart', 100, 'integrationPts', 300, 'samplingRate',
%       100e6)));
%
%   % then initialize everything and run
%   exp.init();
%   exp.run();

% Author/Date : Blake Johnson and Colm Ryan / February 4, 2013

% Copyright 2013 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

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
        CWMode = false
    end
    
    methods
        %Constructor
        function obj = ExpManager()
        end
        
        %Destructor
        function delete(obj)
            % turn off uW sources
            function turn_uwave_off(instr)
                if isa(instr, 'deviceDrivers.lib.uWSource')
                    instr.output = 0;
                end
            end
            structfun(@turn_uwave_off, obj.instruments); 
            
            %If we botched something and ctrl-c'd out then mark the file as
            %incomplete
            if isa(obj.dataFileHandler, 'HDF5DataHandler') && obj.dataFileHandler.fileOpen == 1
                obj.dataFileHandler.close();
                obj.dataFileHandler.markAsIncomplete();
            end
            
            %clean up DataReady listeners and plot timer
            cellfun(@delete, obj.listeners);
            delete(obj.plotScopeTimer);
            fprintf('ExpManager Finished!\n');
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
            
            %Stop all the AWGs
            if(~obj.CWMode)
                cellfun(@(awg) stop(awg), obj.AWGs);
            end

            if ~isempty(obj.dataFileHandler)
                %Construct data file header and info structs
                labels = cellfun(@(s) s.label, obj.sweeps, 'UniformOutput', false);
                xyz = {'x', 'y', 'z'};
                points = cellfun(@(s) s.points, obj.sweeps, 'UniformOutput', false);
                dataInfo = struct();
                for ct = 1:length(obj.sweeps)
                    xyzIdx = length(obj.sweeps)-ct+1;
                    dataInfo.([xyz{xyzIdx}, 'label']) = labels{ct};
                    dataInfo.([xyz{xyzIdx}, 'points']) = points{ct};
                end
                dataInfo.dimension = length(obj.sweeps);
                header = struct();
                header.instrSettings = obj.instrSettings;
                dataInfos = repmat({dataInfo}, 1, length(fieldnames(obj.measurements)));
                % add measurement names to dataInfo structs
                measNames = fieldnames(obj.measurements);
                for ct = 1:length(measNames)
                    dataInfos{ct}.name = measNames{ct};
                end
                %Open data file
                obj.dataFileHandler.open(header, dataInfos);
            end
            
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
            ct = zeros(1, length(obj.sweeps));
            stops = cellfun(@(x) x.numSteps, obj.sweeps);
            sizes = cellfun(@(x) length(x.points), obj.sweeps);
            if length(sizes) == 1
                sizes = [sizes 1];
            end
            % initialize data storage
            obj.data = structfun(@(x) nan(sizes), obj.measurements, 'UniformOutput', false);
            
            % generic nested loop sweeper through "stack"
            while idx > 0 && ct(1) <= stops(1)
                if ct(idx) < stops(idx)
                    ct(idx) = ct(idx) + 1;
                    if stops(idx) > 1
                        % print one status message on the inner sweep
                        if idx == length(stops)
                            if ct(idx) == 1
                              fprintf('Stepping sweep %d: %d points       ', idx, stops(idx));
                            else
                              fprintf('\b\b\b\b\b\b(%3d%%)',round(100*ct(idx)/stops(idx)));
                            end
                            if ct(idx) == stops(idx)
                                fprintf('\n');
                            end
                        elseif idx < length(stops)
                            fprintf('Stepping sweep %d: %d of %d\n', idx, ct(idx), stops(idx));
                        end
                    end
                    obj.sweeps{idx}.step(ct(idx));
                    if idx < length(ct)
                        idx = idx + 1;
                    else % inner most loop... take data
                        obj.take_data();
                        % pull data out of measurements
                        stepData = structfun(@(m) m.get_data(), obj.measurements, 'UniformOutput', false);
                        for measName = fieldnames(stepData)'
                            if isa(obj.sweeps{end}, 'sweeps.SegmentNum')
                                % we are sweeping segment number, so we
                                % have an entire row of data
                                % what we want to do is:
                                % obj.data.(measNames{ct})(ct(1), ct(2), ..., ct(n-1), :) = stepData{ct};
                                % lacking an idiomatic way to build the generic
                                % assignment, we manually call subsasgn
                                indexer = struct('type', '()', 'subs', {[num2cell(ct(1:end-1)), ':']});
                                obj.data.(measName{1}) = subsasgn(obj.data.(measName{1}), indexer, stepData.(measName{1}));
                            else
                                % we have a single point
                                indexer = struct('type', '()', 'subs', {num2cell(ct)});
                                obj.data.(measName{1}) = subsasgn(obj.data.(measName{1}), indexer, stepData.(measName{1}));
                            end
                        end
                        plotResetFlag = all(ct == 1);
                        obj.plot_data(plotResetFlag);
                        obj.save_data(stepData);
                    end
                else
                    %We've rolled over so reset this sweeps counter and
                    %step back to the next sweep
                    ct(idx) = 0;
                    idx = idx - 1;
                end
            end
            
            % close data file
            if ~isempty(obj.dataFileHandler)
                obj.dataFileHandler.close();
            end
            
        end
        
        function cleanUp(obj)
            % stop AWGs
            cellfun(@(awg) stop(awg), obj.AWGs);
            % stop plot timer and clear it
            stop(obj.plotScopeTimer);
            delete(obj.plotScopeTimer);
            %clean up DataReady listeners
            cellfun(@delete, obj.listeners);
            
        end
        
        %Helper function to take data (basically, start/stop AWGs and
        %digitizers)
        function take_data(obj)
            
            %Clear all the measurement filters
            structfun(@(m) reset(m), obj.measurements);
            
            %Ready the digitizers
            cellfun(@(scope) acquire(scope), obj.scopes);
            
            if(~obj.CWMode)
                %Start the slaves up again
                cellfun(@(awg) run(awg), obj.AWGs(2:end))
                %And the master
                run(obj.AWGs{1});
            end
            
            %Wait for data taking to finish
            obj.scopes{1}.wait_for_acquisition(1000);
            
            if(~obj.CWMode)
                %Stop all the AWGs
                cellfun(@(awg) stop(awg), obj.AWGs);
            end
        end
        
        %Helper function to apply measurement filters and store data
        function process_data(obj, src, ~)
            % download data from src
            measData = struct('ch1', src.transfer_waveform(1), 'ch2', src.transfer_waveform(2));
            %Apply measurment filters in turn
            structfun(@(m) apply(m, measData), obj.measurements, 'UniformOutput', false);
        end
        
        function save_data(obj, stepData)
            if isempty(obj.dataFileHandler) || obj.dataFileHandler.fileOpen == 0
                return
            end
            measNames = fieldnames(stepData)';
            for ct = 1:length(measNames)
                measData = squeeze(stepData.(measNames{ct}));
                obj.dataFileHandler.write(measData, ct);
            end
        end
        
        function plot_data(obj, reset)
            %Plot the accumulated swept data
            %We keep track of figure handles to not pop new ones up all the
            %time
            
            %TODO: Handle changes in data size 
            persistent figHandles axesHandles plotHandles
            if isempty(figHandles)
                figHandles = struct();
                axesHandles = struct();
                plotHandles = struct();
            end
            
            for measName = fieldnames(obj.data)'
                measData = squeeze(obj.data.(measName{1}));
                
                if ~isempty(measData)
                    %Check whether we have an open figure handle to plot to
                    if ~isfield(figHandles, measName{1}) || ~ishandle(figHandles.(measName{1}))
                        %If we've closed the figure then we probably
                        %need to reset the axes and plot handles too
                        if isfield(figHandles, measName{1})
                           axesHandles = rmfield(axesHandles, [measName{1} '_abs']); 
                           axesHandles = rmfield(axesHandles, [measName{1} '_phase']); 
                           plotHandles = rmfield(plotHandles, [measName{1} '_abs']); 
                           plotHandles = rmfield(plotHandles, [measName{1} '_phase']); 
                        end
                        figHandles.(measName{1}) = figure('WindowStyle', 'docked', 'HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', [measName{1} ' - Data']);
                    end
                    figHandle = figHandles.(measName{1});
                    
                    if reset || ~isfield(axesHandles, [measName{1} '_abs']) || ~isfield(plotHandles, [measName{1} '_abs']) || ~ishandle(axesHandles.([measName{1} '_abs']))
                        axesHandles.([measName{1} '_abs']) = subplot(2,1,1, 'Parent', figHandle);
                        axesHandles.([measName{1} '_phase']) = subplot(2,1,2, 'Parent', figHandle);
                        sizes = cellfun(@(x) length(x.points), obj.sweeps);
                        switch nsdims(measData)
                            case 1
                                %Find non-singleton sweep dimension
                                goodSweepIdx = find(sizes ~= 1, 1);
                                plotHandles.([measName{1} '_abs']) = plot(axesHandles.([measName{1} '_abs']), obj.sweeps{goodSweepIdx}.plotPoints, abs(measData));
                                xlabel(axesHandles.([measName{1} '_abs']), obj.sweeps{goodSweepIdx}.label);
                                ylabel(axesHandles.([measName{1} '_abs']), 'Amplitude')
                                plotHandles.([measName{1} '_phase']) = plot(axesHandles.([measName{1} '_phase']), obj.sweeps{goodSweepIdx}.plotPoints, (180/pi)*angle(measData));
                                ylabel(axesHandles.([measName{1} '_phase']), 'Phase')
                                xlabel(axesHandles.([measName{1} '_phase']), obj.sweeps{goodSweepIdx}.label);
                                
                            case 2
                                goodSweepIdx = find(sizes ~= 1, 2);
                                xPoints = obj.sweeps{goodSweepIdx(2)}.plotPoints;
                                yPoints = obj.sweeps{goodSweepIdx(1)}.plotPoints;
                                plotHandles.([measName{1} '_abs']) = imagesc(xPoints, yPoints, abs(measData), 'Parent', axesHandles.([measName{1} '_abs']));
                                title(axesHandles.([measName{1} '_abs']), 'Amplitude')
                                xlabel(axesHandles.([measName{1} '_abs']), obj.sweeps{goodSweepIdx(2)}.label);
                                ylabel(axesHandles.([measName{1} '_abs']), obj.sweeps{goodSweepIdx(1)}.label);
                                plotHandles.([measName{1} '_phase']) = imagesc(xPoints, yPoints, (180/pi)*angle(measData), 'Parent', axesHandles.([measName{1} '_phase']));
                                title(axesHandles.([measName{1} '_phase']), 'Phase')
                                xlabel(axesHandles.([measName{1} '_phase']), obj.sweeps{goodSweepIdx(2)}.label);
                                ylabel(axesHandles.([measName{1} '_phase']), obj.sweeps{goodSweepIdx(1)}.label);
                            case 3
                                goodSweepIdx = find(sizes ~= 1, 2);
                                xPoints = obj.sweeps{goodSweepIdx(2)}.plotPoints;
                                yPoints = obj.sweeps{goodSweepIdx(1)}.plotPoints;
                                plotHandles.([measName{1} '_abs']) = imagesc(xPoints, yPoints, abs(squeeze(measData(1,:,:))), 'Parent', axesHandles.([measName{1} '_abs']));
                                title(axesHandles.([measName{1} '_abs']), 'Amplitude')
                                xlabel(axesHandles.([measName{1} '_abs']), obj.sweeps{goodSweepIdx(2)}.label);
                                ylabel(axesHandles.([measName{1} '_abs']), obj.sweeps{goodSweepIdx(1)}.label);
                                plotHandles.([measName{1} '_phase']) = imagesc(xPoints, yPoints, (180/pi)*angle(squeeze(measData(1,:,:))), 'Parent', axesHandles.([measName{1} '_phase']));
                                title(axesHandles.([measName{1} '_phase']), 'Phase')
                                xlabel(axesHandles.([measName{1} '_phase']), obj.sweeps{goodSweepIdx(2)}.label);
                                ylabel(axesHandles.([measName{1} '_phase']), obj.sweeps{goodSweepIdx(1)}.label);
                        end
                    else
                        switch length(setdiff(size(measData), 1))
                            case 1
                                set(plotHandles.([measName{1} '_abs']), 'YData', abs(measData));
                                set(plotHandles.([measName{1} '_phase']), 'YData', (180/pi)*angle(measData));
                            case 2
                                set(plotHandles.([measName{1} '_abs']), 'CData', abs(measData));
                                set(plotHandles.([measName{1} '_phase']), 'CData', (180/pi)*angle(measData));
                            case 3
                                %Here we'll try to plot the last updated
                                %slice
                                curSliceIdx = find(~isnan(measData(:,1,1)), 1, 'last');
                                curSlice = measData(curSliceIdx,:,:);
                                set(plotHandles.([measName{1} '_abs']), 'CData', abs(squeeze(curSlice)));
                                set(plotHandles.([measName{1} '_phase']), 'CData', (180/pi)*angle(squeeze(curSlice)));
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
                measData = obj.measurements.(measName{1}).get_data();
                
                if ~isempty(measData)
                    if ~isfield(figHandles, measName{1}) || ~ishandle(figHandles.(measName{1}))
                        figHandles.(measName{1}) = figure('WindowStyle', 'docked', 'HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', [measName{1} ' - Scope']);
                    end
                    figHandle = figHandles.(measName{1});
                    
                    if ~isfield(axesHandles, [measName{1} '_abs']) || ~ishandle(axesHandles.([measName{1} '_abs'])) || ~isfield(plotHandles, [measName{1} '_abs'])
                        axesHandles.([measName{1} '_abs']) = subplot(2,1,1, 'Parent', figHandle);
                        plotHandles.([measName{1} '_abs']) = plot(axesHandles.([measName{1} '_abs']), abs(measData));
                        ylabel(axesHandles.([measName{1} '_abs']), 'Amplitude')
                        axesHandles.([measName{1} '_phase']) = subplot(2,1,2, 'Parent', figHandle);
                        plotHandles.([measName{1} '_phase']) = plot(axesHandles.([measName{1} '_phase']), (180/pi)*angle(measData));
                        ylabel(axesHandles.([measName{1} '_phase']), 'Phase')
                    else
                        set(plotHandles.([measName{1} '_abs']), 'YData', abs(measData));
                        set(plotHandles.([measName{1} '_phase']), 'YData', (180/pi)*angle(measData));
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