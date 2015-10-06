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
        sweep_callbacks = {}
        data = struct();
        scopes
        AWGs
        listeners = {}
        plotScopeTimer
        CWMode = false
        saveVariances = false
        dataFileHeader = struct();
        dataTimeout = 10 % timeout in seconds
        saveAllSettings = true;
        saveData = true;
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

            %Stop all the AWGs if not in CWMode
            if(~obj.CWMode)
                cellfun(@(awg) stop(awg), obj.AWGs);
            else
                cellfun(@(awg) run(awg), obj.AWGs);
            end

            if ~isempty(obj.dataFileHandler)
                %Construct data file header and info structs
                labels = cellfun(@(s) s.axisLabel, obj.sweeps, 'UniformOutput', false);
                xyz = {'x', 'y', 'z'};
                points = cellfun(@(s) s.points, obj.sweeps, 'UniformOutput', false);
                dataInfo = struct();
                for ct = 1:length(obj.sweeps)
                    xyzIdx = length(obj.sweeps)-ct+1;
                    dataInfo.([xyz{xyzIdx}, 'label']) = labels{ct};
                    dataInfo.([xyz{xyzIdx}, 'points']) = points{ct};
                end
                dataInfo.dimension = length(obj.sweeps);
                % add measurement names to dataInfo structs
                measNames = fieldnames(obj.measurements);
                dataInfos = {};
                openDataFile = false;
                for ct = 1:length(measNames)
                    if obj.measurements.(measNames{ct}).saved
                        dataInfos{end+1} = dataInfo;
                        dataInfos{end}.name = measNames{ct};
                        openDataFile = true;
                    end
                end
                %Open data file
                if openDataFile
                    obj.dataFileHandler.open(obj.dataFileHeader, dataInfos, obj.saveVariances);
                end
            end

        end

        function connect_meas_to_source(obj, meas)
            instrNames = fieldnames(obj.instruments);
            function connect_to_source(meas, src)
                %First look for an instrument (scope)
                if (~isempty(find(strcmp(src, instrNames))))
                    obj.listeners{end+1} = addlistener(obj.instruments.(src), 'DataReady', @meas.apply);
                %Otherwise assume another measurement
                else
                    obj.listeners{end+1} = addlistener(obj.measurements.(src), 'DataReady', @meas.apply);
                end
            end
            %Correlators have mulitple sources
            if isa(meas, 'MeasFilters.Correlator')
                cellfun(@(x) connect_to_source(meas, x), strsplit(meas.dataSource, ','))
            else
                connect_to_source(meas, meas.dataSource);
            end
        end

        %Runner
        function run(obj)
            %Connect a polling scope plotter
            obj.plotScopeTimer = timer('TimerFcn', @obj.plot_scope_callback, 'StopFcn', @obj.plot_scope_callback, 'Period', 0.5, 'ExecutionMode', 'fixedSpacing');

            %Connect measurement consumers to producers
            structfun(@(x) obj.connect_meas_to_source(x), obj.measurements);

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
            obj.data = structfun(@(x) struct('mean', complex(nan(sizes),nan(sizes)), 'realvar', nan(sizes), 'imagvar', nan(sizes), 'prodvar', nan(sizes)),...
                obj.measurements, 'UniformOutput', false);

            fprintf('Taking data....\n');

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
                    if ~isempty(obj.sweep_callbacks{idx})
                        feval(obj.sweep_callbacks{idx}, obj);
                    end
                    if idx < length(ct)
                        idx = idx + 1;
                    else % inner most loop... take data
                        obj.take_data();
                        % pull data out of measurements
                        stepData = structfun(@(m) m.get_data(), obj.measurements, 'UniformOutput', false);
                        stepVar = structfun(@(m) m.get_var(), obj.measurements, 'UniformOutput', false);
                        for measName = fieldnames(stepData)'
                            if ~obj.measurements.(measName{1}).saved
                                continue
                            end
                            if isa(obj.sweeps{end}, 'sweeps.SegmentNum')
                                % we are sweeping segment number, so we
                                % have an entire row of data
                                % what we want to do is:
                                % obj.data.(measNames{ct})(ct(1), ct(2), ..., ct(n-1), :) = stepData{ct};
                                % lacking an idiomatic way to build the generic
                                % assignment, we manually call subsasgn
                                indexer = struct('type', '()', 'subs', {[num2cell(ct(1:end-1)), ':']});
                                obj.data.(measName{1}).mean = subsasgn(obj.data.(measName{1}).mean, indexer, stepData.(measName{1}));
                                if obj.saveVariances
                                    obj.data.(measName{1}).realvar = subsasgn(obj.data.(measName{1}).realvar, indexer, stepVar.(measName{1}).realvar);
                                    obj.data.(measName{1}).imagvar = subsasgn(obj.data.(measName{1}).imagvar, indexer, stepVar.(measName{1}).imagvar);
                                    obj.data.(measName{1}).prodvar = subsasgn(obj.data.(measName{1}).prodvar, indexer, stepVar.(measName{1}).prodvar);
                                end
                            else
                                % we have a single point
                                indexer = struct('type', '()', 'subs', {num2cell(ct)});
                                obj.data.(measName{1}).mean = subsasgn(obj.data.(measName{1}).mean, indexer, stepData.(measName{1}));
                            end
                        end
                        plotResetFlag = all(ct == 1);
                        obj.plot_data(plotResetFlag);
                        if obj.saveData
                            obj.save_data(stepData, stepVar);
                        end
                    end
                else
                    %We've rolled over so reset this sweeps counter and
                    %step back to the next sweep
                    ct(idx) = 0;
                    idx = idx - 1;
                end
            end

            if ~isempty(obj.dataFileHandler)
                % close data file
                obj.dataFileHandler.close();

                if obj.saveAllSettings
                   %saves json settings files
                   fileName = obj.dataFileHandler.fileName;
                   [pathname,basename,~] = fileparts(fileName);
                   mkdir(fullfile(pathname,strcat(basename,'_cfg')));
                   copyfile(getpref('qlab','CurScripterFile'),fullfile(pathname,strcat(basename,'_cfg'),'DefaultExpSettings.json'));
                   copyfile(getpref('qlab','ChannelParamsFile'),fullfile(pathname,strcat(basename,'_cfg'),'ChannelParams.json'));
                   copyfile(getpref('qlab','InstrumentLibraryFile'),fullfile(pathname,strcat(basename,'_cfg'),'Instruments.json'));
                   copyfile(strrep(getpref('qlab','InstrumentLibraryFile'),'Instruments','Measurements'),fullfile(pathname,strcat(basename,'_cfg'),'Measurements.json'));
                   copyfile(strrep(getpref('qlab','InstrumentLibraryFile'),'Instruments','Sweeps'),fullfile(pathname,strcat(basename,'_cfg'),'Sweeps.json'));
                   %copyfile(strrep(getpref('qlab','InstrumentLibraryFile'),'Instruments','QuickPicks'),fullfile(pathname,strcat(basename,'_cfg'),'QuickPicks.json'));
                end
            end


        end

        function cleanUp(obj)
            % stop the scopes
            cellfun(@(scope) stop(scope), obj.scopes);
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
            obj.scopes{1}.wait_for_acquisition(obj.dataTimeout);

            if(~obj.CWMode)
                %Stop all the AWGs
                cellfun(@(awg) stop(awg), obj.AWGs);
            end
        end

        function save_data(obj, stepData, stepVar)
            if isempty(obj.dataFileHandler) || obj.dataFileHandler.fileOpen == 0
                return
            end
            measNames = fieldnames(stepData)';
            savect = 1;
            for ct = 1:length(measNames)
                if ~obj.measurements.(measNames{ct}).saved
                    continue
                end
                measData = squeeze(stepData.(measNames{ct}));
                obj.dataFileHandler.write(measData, savect);
                if obj.saveVariances
                    obj.dataFileHandler.writevar(stepVar.(measNames{ct}), savect);
                end
                savect = savect + 1;
            end
        end

        function plot_data(obj, reset)
            %Plot the accumulated swept data
            %We keep track of figure handles to not pop new ones up all the
            %time

            %TODO: Handle changes in data size
            persistent figHandles plotHandles
            if isempty(figHandles)
                figHandles = struct();
                plotHandles = struct();
            end

            % available plotting modes
            plotMap = struct();
            plotMap.abs = struct('label','Amplitude', 'func', @abs);
            plotMap.phase = struct('label','Phase (degrees)', 'func', @(x) (180/pi)*angle(x));
            plotMap.real = struct('label','Real Quad.', 'func', @real);
            plotMap.imag = struct('label','Imag. Quad.', 'func', @imag);

            for measName = fieldnames(obj.data)'
                measData = squeeze(obj.data.(measName{1}).mean);
                if isempty(measData)
                    continue;
                end

                switch obj.measurements.(measName{1}).plotMode
                    case 'amp/phase'
                        toPlot = {plotMap.abs, plotMap.phase};
                        numRows = 2; numCols = 1;
                    case 'real/imag'
                        toPlot = {plotMap.real, plotMap.imag};
                        numRows = 2; numCols = 1;
                    case 'quad'
                        toPlot = {plotMap.abs, plotMap.phase, plotMap.real, plotMap.imag};
                        numRows = 2; numCols = 2;
                    otherwise
                        toPlot = {};
                end

                %Check whether we have an open figure handle to plot to
                if ~isfield(figHandles, measName{1}) || ~ishandle(figHandles.(measName{1}))
                    %If we've closed the figure then we probably
                    %need to reset the axes and plot handles too
                    if isfield(figHandles, measName{1})
                       plotHandles.(measName{1}) = cell(length(toPlot),1);
                    end
                    figHandles.(measName{1}) = figure('WindowStyle', 'docked', 'HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', [measName{1} ' - Data']);
                end
                figHandle = figHandles.(measName{1});

                for ct = 1:length(toPlot)
                    if reset || isempty(plotHandles.(measName{1}){ct}) || ~ishandle(plotHandles.(measName{1}){ct})
                        axesH = subplot(numRows, numCols, ct, 'Parent', figHandle);
                        sizes = cellfun(@(x) length(x.points), obj.sweeps);
                        switch nsdims(measData)
                            case 1
                                %Find non-singleton sweep dimension
                                goodSweepIdx = find(sizes ~= 1, 1);
                                plotHandles.(measName{1}){ct} = plot(axesH, obj.sweeps{goodSweepIdx}.plotPoints, toPlot{ct}.func(measData));
                                xlabel(axesH, obj.sweeps{goodSweepIdx}.axisLabel);
                                ylabel(axesH, toPlot{ct}.label)

                            case 2
                                goodSweepIdx = find(sizes ~= 1, 2);
                                xPoints = obj.sweeps{goodSweepIdx(2)}.plotPoints;
                                yPoints = obj.sweeps{goodSweepIdx(1)}.plotPoints;
                                plotHandles.(measName{1}){ct} = imagesc(xPoints, yPoints, toPlot{ct}.func(measData), 'Parent', axesH);
                                title(axesH, toPlot{ct}.label)
                                xlabel(axesH, obj.sweeps{goodSweepIdx(2)}.axisLabel);
                                ylabel(axesH, obj.sweeps{goodSweepIdx(1)}.axisLabel);
                            case 3
                                goodSweepIdx = find(sizes ~= 1, 2);
                                xPoints = obj.sweeps{goodSweepIdx(1)}.plotPoints;
                                yPoints = obj.sweeps{goodSweepIdx(2)}.plotPoints;
                                plotHandles.(measName{1}){ct} = imagesc(xPoints, yPoints, toPlot{ct}.func(squeeze(measData(1,:,:))), 'Parent', axesH);
                                title(axesH, toPlot{ct}.label)
                                xlabel(axesH, obj.sweeps{goodSweepIdx(1)}.axisLabel);
                                ylabel(axesH, obj.sweeps{goodSweepIdx(2)}.axisLabel);
                        end
                    else
                        switch nsdims(measData)
                            case 1
                                set(plotHandles.(measName{1}){ct}, 'YData', toPlot{ct}.func(measData));
                            case 2
                                set(plotHandles.(measName{1}){ct}, 'CData', toPlot{ct}.func(measData));
                            case 3
                                %Here we'll try to plot the last updated
                                %slice
                                curSliceIdx = find(~isnan(measData(:,1,1)), 1, 'last');
                                curSlice = measData(curSliceIdx,:,:);
                                set(plotHandles.(measName{1}){ct}, 'CData', toPlot{ct}.func(squeeze(curSlice)));
                        end
                    end
                end
            end
            drawnow()
        end

        function plot_scope_callback(obj, ~, ~)
            %We keep track of figure handles to not pop new ones up all the
            %time
            persistent figHandles
            if isempty(figHandles)
                figHandles = struct();
            end

            for measName = fieldnames(obj.measurements)'
                if obj.measurements.(measName{1}).plotScope
                    if ~isfield(figHandles, measName{1}) || ~ishandle(figHandles.(measName{1}))
                        figHandles.(measName{1}) = figure('WindowStyle', 'docked', 'HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', [measName{1} ' - Scope']);
                    end
                    figHandle = figHandles.(measName{1});
                    obj.measurements.(measName{1}).plot(figHandle);
                end
            end
            drawnow()
        end

        %Helpers to flesh out properties
        function add_instrument(obj, name, instr, settings)
            obj.instruments.(name) = instr;
            obj.instrSettings.(name) = settings;
        end

        function remove_instrument(obj, name)
            obj.instruments = rmfield(obj.instruments,name);
            obj.instrSettings = rmfield(obj.instrSettings,name);
        end

        function add_measurement(obj, name, meas)
            obj.measurements.(name) = meas;
        end

        function add_sweep(obj, order, sweep, callback)
            % order = 1-indexed position to insert the sweep in the list of sweeps
            % sweep = a sweep object
            % callback = a method to call after each sweep.step()
            obj.sweeps{order} = sweep;
            if exist('callback', 'var')
                obj.sweep_callbacks{order} = callback;
            else
                obj.sweep_callbacks{order} = [];
            end
        end

        function clear_sweeps(obj)
            obj.sweeps = {};
            obj.sweep_callbacks = {};
        end

    end

    methods (Static)
        %forward reference static methods
        out = is_scope(instr)
        out = is_AWG(instr)
    end

end
