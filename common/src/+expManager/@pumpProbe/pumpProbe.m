% pumpProbe.m
% Performs a pump-probe experiment with a network analyzer and a source.

% Authors: Blake Johnson and Hanhee Paik
% Date: Oct 4, 2012

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

classdef pumpProbe < expManager.homodyneDetection
    
    properties
        expSettings
    end
    
    methods (Static)
        % Class constructor
        function obj = pumpProbe(data_path, cfgFileName, ~, expSettings, fileNumber)
            % call superclass constructor
            obj = obj@expManager.homodyneDetection(data_path, cfgFileName, 'pumpProbe', fileNumber);
            obj.expSettings = expSettings;
        end
    end
    methods
        function Do(obj)
            fluxBiases = obj.expSettings.fluxBiases;
            pumpFreqs = obj.expSettings.pumpFreqs;
            %pumpPowers = obj.expSettings.pumpPowers;
            naPowers = obj.expSettings.naPowers;
            naStartCenterFreq = obj.expSettings.naStartCenterFreq;
            
			% step the flux bias
            for ii = 1:length(fluxBiases)
                fprintf('Setting flux bias to: %f\n', fluxBiases(ii));
                obj.Instr.dcbias.offset = fluxBiases(ii);
                % turn off the pump
                obj.Instr.source.output = 0;
                % set the NA to a 1 GHz span
                obj.Instr.na.sweep_span = 1e9;
                % set NA center frequency
                obj.Instr.na.sweep_center = naStartCenterFreq;
                % step NA power
                for jj = 1:length(naPowers)
                    fprintf('Setting NA power to: %f\n', naPowers(jj));
                    obj.Instr.na.power = naPowers(jj);
                    % take a NA trace
                    [~, data1(ii,jj,:)] = obj.Instr.na.getTrace();
                end
                
%                 % turn on the pump
%                 obj.Instr.source.output = 1;
%                 % set the NA center frequency and span
%                 
%                 obj.Instr.na.sweep_span = 1e9;
%                 % step the pump frequency independent of the NA
%                 for jj = 1:length(pumpFreqs)
%                     obj.Instr.source.frequency = pumpFreqs(jj);
%                     % take a NA trace
%                     [~, data2(ii,jj,:)] = obj.Instr.na.getTrace();
%                 end
%             
%                 % set the NA to a 200 MHz span
%                 obj.Instr.na.sweep_span = 0.2e9;
%                 % step the pump frequency and NA center frequency
%                 for jj = 1:length(pumpFreqs)
%                     obj.Instr.source.frequency = pumpFreqs(jj);
%                     obj.Instr.na.sweep_center = pumpFreqs(jj);
%                     % take a NA trace
%                     [~, data3(ii,jj,:)] = obj.Instr.na.getTrace();
%                 end
            end
            
            %save(obj.DataFileName, 'data1', 'data2', 'data3', 'fluxBiases', 'pumpFreqs', 'naPowers');
            save(obj.DataFileName, 'data1', 'fluxBiases', 'naPowers');
        end
        
        function createDataFileName(obj)
            obj.DataFileName = sprintf('%03d_%s.mat', obj.filenumber, obj.Name);
        end
        
        function errorCheckExpParams(obj)
            % Error checking goes here
            inputStructure = obj.inputStructure;
            if ~isfield(inputStructure, 'InstrParams')
                obj.inputStructure.InstrParams = struct();
            end
        end
    end
end
