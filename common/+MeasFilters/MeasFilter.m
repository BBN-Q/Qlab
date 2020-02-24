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
        label
        dataSource
        latestData
        accumulatedData
        accumulatedVar
        avgct = 0
        varct = 0
        scopeavgct = 0
        plotScope = false
        scopeHandle
        plotMode = 'amp/phase' %allowed enums are 'amp/phase', 'real/imag', 'quad'
        axesHandles
        plotHandles
        saved = true
    end
    
    events
        DataReady
    end

    methods (Abstract)
        %Consume a DataReady event
        apply(obj, src, ~)
    end
    
    methods
        function obj = MeasFilter(label, settings)
            obj.label = label;
            % MeasFilter(settings)
            if isfield(settings, 'plotScope')
                obj.plotScope = settings.plotScope;
            end
            if isfield(settings, 'plotMode')
                obj.plotMode = settings.plotMode;
            end
            if isfield(settings, 'dataSource')
                obj.dataSource = settings.dataSource;
            end
            if isfield(settings, 'saved')
                obj.saved = settings.saved;
            end
        end
        
        function reset(obj)
            obj.avgct = 0;
            obj.varct = 0;
            obj.accumulatedData = [];
            obj.scopeavgct = 0;
        end
        
        function accumulate(obj)
            % data comes back from the scope as either 2D (time x segment)
            % or 4D (time x waveforms x segment x roundRobinsPerBuffer)
            % in the 4D case, we want to average over waveforms and round
            % robins
            % if there is only 1 roundRobinPerBuffer then Matlab has no
            % concept of a singleton trailing dimension and so returns a 3D
            % object
            if isempty(obj.latestData)
                return
            end
            if (ndims(obj.latestData) == 4) || (ndims(obj.latestData) == 3)
                tmpData = squeeze(mean(mean(obj.latestData, 4), 2));
                tmpVar = struct();
                tmpVar.real = squeeze(sum(sum(real(obj.latestData).^2, 4), 2));
                tmpVar.imag = squeeze(sum(sum(imag(obj.latestData).^2, 4), 2));
                tmpVar.prod = squeeze(sum(sum(real(obj.latestData).*imag(obj.latestData), 4), 2));
                obj.varct = obj.varct + size(obj.latestData,2)*size(obj.latestData,4);
            else
                tmpData = obj.latestData;
                tmpVar.real = real(obj.latestData).^2;
                tmpVar.imag = imag(obj.latestData).^2;
                tmpVar.prod = imag(obj.latestData).*real(obj.latestData);
                obj.varct = obj.varct + 1;
            end
            
            if isempty(obj.accumulatedData)
                obj.accumulatedData = tmpData;
                obj.accumulatedVar = tmpVar;
            else
                obj.accumulatedData = obj.accumulatedData + tmpData;
                obj.accumulatedVar.real = obj.accumulatedVar.real + tmpVar.real;
                obj.accumulatedVar.imag = obj.accumulatedVar.imag + tmpVar.imag;
                obj.accumulatedVar.prod = obj.accumulatedVar.prod + tmpVar.prod;
            end
            obj.avgct = obj.avgct + 1;
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData / obj.avgct;
        end
        
        function out = get_var(obj)
            out = struct();
            if ~isempty(obj.accumulatedVar) && ~isempty(get_data(obj))
                out.realvar = obj.accumulatedVar.real/(obj.varct) - real(get_data(obj)).^2;
                out.imagvar = obj.accumulatedVar.imag/(obj.varct) - imag(get_data(obj)).^2;
                out.prodvar = obj.accumulatedVar.prod/(obj.varct) - real(get_data(obj)).*imag(get_data(obj));
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
            dims = nsdims(measData);
            if ~isempty(measData)
                for ct = 1:length(toPlot)
                    if isempty(obj.axesHandles{ct}) || ~ishandle(obj.axesHandles{ct})
                        obj.axesHandles{ct} = subplot(numRows, numCols, ct, 'Parent', figH);
                        if dims < 2
                            obj.plotHandles{ct} = plot(obj.axesHandles{ct}, toPlot{ct}.func(measData));
                        else
                            obj.plotHandles{ct} = imagesc(toPlot{ct}.func(measData), 'Parent', obj.axesHandles{ct});
                        end
                        ylabel(obj.axesHandles{ct}, toPlot{ct}.label)
                    else
                        if dims < 2
                            prop = 'YData';
                        else
                            prop = 'CData';
                        end
                        set(obj.plotHandles{ct}, prop, toPlot{ct}.func(measData));
                    end
                end
            end
        end
    end
    
end