% A single-channel digital homodyne measurement filter.

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
classdef DigitalHomodyne < MeasFilters.MeasFilter
   
    properties
        IFfreq
        samplingRate
        boxCarStart
        boxCarStop
        affine
        phase
    end
    
    methods
        function obj = DigitalHomodyne(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.IFfreq = settings.IFfreq;
            obj.samplingRate = settings.samplingRate;
            obj.boxCarStart = settings.boxCarStart;
            obj.boxCarStop = settings.boxCarStop;
            obj.phase = settings.phase;
            measAffines = getpref('qlab','MeasAffines');
            if isfield(measAffines, settings.name)
                obj.affine = measAffines.(settings.name);
            else
                obj.affine = [];
            end
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
            
            [demodSignal, decimFactor] = digitalDemod(data, obj.IFfreq, obj.samplingRate);
            
%             save(['SSRecords_', datestr(now, 'yymmdd-HH-MM-SS-FFF'), '.mat'], 'demodSignal');
            
            %Apply the affine transformation to unwind things
            if ~isempty(obj.affine)
                demodSignal = bsxfun(@times, bsxfun(@minus, demodSignal, obj.affine.centres), exp(-1j*obj.affine.angles));
            end

            %Box car the demodulated signal
            if ndims(demodSignal) == 2
                demodSignal = demodSignal(floor(obj.boxCarStart/decimFactor):floor(obj.boxCarStop/decimFactor),:);
            elseif ndims(demodSignal) == 4
                demodSignal = demodSignal(floor(obj.boxCarStart/decimFactor):floor(obj.boxCarStop/decimFactor),:,:,:);
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end
            
%             figure()
%             gData = squeeze(mean(demodSignal(:,:,1,:),4));
%             eData = squeeze(mean(demodSignal(:,:,2,:),4));
%             plot((gData));
%             hold on
%             plot((eData),'r');
            
            %Integrate and rotate
            obj.latestData = exp(1j*obj.phase) * 2 * mean(demodSignal,1);
                
            obj.accumulate();
            out = obj.latestData;
        end
    end
    
    
end