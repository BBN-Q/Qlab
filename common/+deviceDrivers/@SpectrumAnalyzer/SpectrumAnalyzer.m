% Module Name : SpectrumAnalyzer
%
% Author/Date : Blake R. Johnson
%
% Description : Object to manage access to the BBN simple spectrum
% analyzer. Borrows most of its code from the DigitalAttenuator driver.

% Copyright 2012 Raytheon BBN Technologies
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

classdef (Sealed) SpectrumAnalyzer < deviceDrivers.lib.Serial
    properties
        serial = 0; % ID of the device to distinguish multiple instances
        LOsource 
        centerFreq
        span
        numSweepPts
        sweepPts
        sweepData
    end
    
    properties ( Access=private)
        IFfreq = 0.0107; % 10.7 MHz notch filter
        notchWidth = 0.0001;
    end
    methods
        
        function obj = SpectrumAnalyzer()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
        end
        
        %Override the connect method to set a shorter timeout becaues the
        %Arduino flakes out sometimes
        function connect(obj, address)
            connect@deviceDrivers.lib.Serial(obj, address)
            obj.interface.Timeout = 0.1;
        end
        
%         function val = get.serial(obj)
%             % poll device for its serial number
%             obj.write('ID?');
%             val = obj.readUntilEND();
%             val = str2double(val);
%             obj.serial = val;
%         end

        function out = get_voltage(obj)
            tryct = 0;
            while tryct < 10
                out = str2double(obj.query('READ '));
                if ~isempty(out)
                    break
                else
                    tryct = tryct+1;
                end
            end
        end
        
        function set.LOsource(obj, sourceName)
            obj.LOsource= InstrumentFactory(sourceName);
        end 
        
        function set.centerFreq(obj, value)
            obj.LOsource.frequency = value-obj.IFfreq;
        end
        
        function value = get.centerFreq(obj)
            value = obj.LOsource.frequency + obj.IFfreq;
        end
        
        function sweep(obj)
%             %Work out the frequencies 
%             obj.sweepPts = linspace(obj.centerFreq-obj.span/2,  obj.centerFreq+obj.span/2, obj.numSweepPts);
%             obj.sweepData = nan(1, obj.numSweepPts);
%             rawData = nan(1,obj.numSweepPts);
%             h = waitbar(0, 'Taking sweep data....');
%             for ct = 1:obj.numSweepPts
%                 waitbar(ct/obj.numSweepPts);
%                 obj.LOsource.frequency = obj.sweepPts(ct)-obj.IFfreq;
%                 rawData(ct) = obj.peakAmplitude();
%             end
%             close(h);
%             
%             %Now deconvolve the filter function
%             freqStep = obj.sweepPts(2) - obj.sweepPts(1);
%             freqPts = -1.5*obj.IFfreq:freqStep:1.5*obj.IFfreq;
%             lorentzian = @(xpts, x0) (1/pi)*0.5*obj.notchWidth/((xpts-x0).^2 - (0.5*obj.notchWidth)^2);
%             notchFilter = lorentzian(freqPts, -obj.IFfreq) + lorentzian(freqPts, obj.IFfreq);
%             deconvData = deconv(rawData, notchFilter);
        end
        
        function value = peakAmplitude(obj)
            adcValue = obj.get_voltage();
            %linear interpolation
            value = interp1([75, 525], [-100, -20], adcValue);
        end
        
    end % Methods
    
end % Class