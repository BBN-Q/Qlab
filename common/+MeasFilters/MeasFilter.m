% MeasFilter defines the generic interface for measurements that can be
% added to ExpManager instances. To define a new measurement type, inherit
% from this class and implement the apply() method and store the result in
% obj.latestData.

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

classdef MeasFilter < handle
    
    properties
        channel
        latestData
        accumulatedData
        accumulatedVar
        avgct = 0
        varct = 0
        childFilter
        plotScope = false
        scopeHandle
        plotMode = 'amp/phase' %allowed enums are 'amp/phase', 'real/imag', 'quad'
        axesHandles
        plotHandles
        
    end
    
    methods
        function obj = MeasFilter(varargin)
            % MeasFilter(filter, settings) or MeasFilter(settings)
            if nargin == 1
                settings = varargin{1};
                obj.channel = sprintf('ch%d',settings.channel);
                filter = [];
            elseif nargin == 2
                [filter, settings] = varargin{:};
            end
            if isfield(settings, 'plotScope')
                obj.plotScope = settings.plotScope;
            end
            if isfield(settings, 'plotMode')
                obj.plotMode = settings.plotMode;
            end
            if ~isempty(filter)
                obj.childFilter = filter;
            end
        end
        
        function out = apply(obj, data)
            if ~isempty(obj.childFilter)
                out = apply(obj.childFilter, data);
            else
                out = data.(obj.channel);
            end
            if obj.plotScope
                obj.plot_scope(out);
            end
            
        end
        
        function reset(obj)
            obj.avgct = 0;
            obj.accumulatedData = [];
        end
        
        function accumulate(obj)
            % data comes back from the scope as either 2D (time x segment)
            % or 4D (time x waveforms x segment x roundRobinsPerBuffer)
            % in the 4D case, we want to average over waveforms and round
            % robins
            if ndims(obj.latestData) == 4
                tmpData = squeeze(mean(mean(obj.latestData, 4), 2));
                tmpVar = struct();
                tmpVar.real = squeeze(sum(sum(real(obj.latestData).^2, 4), 2));
                tmpVar.imag = squeeze(sum(sum(imag(obj.latestData).^2, 4), 2));
                tmpVar.prod = squeeze(sum(sum(real(obj.latestData).*imag(obj.latestData), 4), 2));
                obj.varct = obj.varct + size(obj.latestData,2)*size(obj.latestData,4);
            else
                tmpData = obj.latestData;
                tmpVar = [];
            end
            
            if isempty(obj.accumulatedData)
                obj.accumulatedData = tmpData;
                obj.accumulatedVar = tmpVar;
            else
                obj.accumulatedData = obj.accumulatedData + tmpData;
                if ndims(obj.latestData) == 4
                    obj.accumulatedVar.real = obj.accumulatedVar.real + tmpVar.real;
                    obj.accumulatedVar.imag = obj.accumulatedVar.real + tmpVar.imag;
                    obj.accumulatedVar.prod = obj.accumulatedVar.real + tmpVar.prod;
                end
            end
            obj.avgct = obj.avgct + 1;
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData / obj.avgct;
        end
        
        function out = get_var(obj)
            out = struct();
            if ~isempty(obj.accumulatedVar)
                out.realvar = (obj.accumulatedVar.real - real(get_data(obj)).^2)/(obj.varct-1);
                out.imagvar = (obj.accumulatedVar.imag - imag(get_data(obj)).^2)/(obj.varct-1);
                out.prodvar = (obj.accumulatedVar.prod - real(get_data(obj)).*imag(get_data(obj)))/(obj.varct-1);
            end
        end
        
        function plot_scope(obj, data)
            %Helper function to plot raw data to check timing and what not
            if isempty(obj.scopeHandle)
                fh = figure();
                obj.scopeHandle = axes('Parent', fh);
            end
            if ndims(obj.latestData) == 4
                dims = size(data);
                imagesc(reshape(data, dims(1), prod(dims(2:end))), 'Parent', obj.scopeHandle);
                xlabel('Segment');
                ylabel('Time');
            elseif ndims(obj.latestData) == 2
                imagesc(data, 'Parent', obj.scopeHandle);
                xlabel('Segment');
                ylabel('Time');
            else
                error('Unable to handle data with these dimensions.')
            end
        end
        
        function plot(obj, figH)
            %Given a figure handle plot the most recent data
            plotMap = struct();
            plotMap.abs = struct('label','Amplitude', 'func', @abs);
            plotMap.phase = struct('label','Phase (degrees)', 'func', @(x) (180/pi)*angle(x));
            plotMap.real = struct('label','Real Quad.', 'func', @real);
            plotMap.imag = struct('label','Imag. Quad.', 'func', @imag);
            
            
            switch obj.plotMode
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
            
            if isempty(obj.axesHandles)
                obj.axesHandles = cell(length(toPlot),1);
                obj.plotHandles = cell(length(toPlot),1);
            end
            
            measData = obj.get_data();
            if ~isempty(measData)
                for ct = 1:length(toPlot)
                    if isempty(obj.axesHandles{ct}) || ~ishandle(obj.axesHandles{ct})
                        obj.axesHandles{ct} = subplot(numRows, numCols, ct, 'Parent', figH);
                        obj.plotHandles{ct} = plot(obj.axesHandles{ct}, toPlot{ct}.func(measData));
                        ylabel(obj.axesHandles{ct}, toPlot{ct}.label)
                    else
                        set(obj.plotHandles{ct}, 'YData', toPlot{ct}.func(measData));
                    end
                end
            end
        end
    end
    
end