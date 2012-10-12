% pumpProbe.m
% Performs a pump-probe experiment with a network analyzer and a source.

% Authors: Blake Johnson and Hanhee Paik was just watching and learning.
% (but later did some debugging)
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
            pumpPowers = obj.expSettings.pumpPowers;
            naPowers = obj.expSettings.naPowers;
            naStartCenterFreq = obj.expSettings.naStartCenterFreq;
            naSpan = obj.expSettings.naSpan;
            
% 			% step the flux bias
% %             for ii = 1:length(fluxBiases)
%                 obj.Instr.dcbias.offset = fluxBiases(1);
%                 fprintf('Setting flux bias to: %f\n', fluxBiases(1));
%                 %obj.Instr.dcbias.offset = fluxBiases(ii);
%                 obj.Instr.dcbias.offset = fluxBiases(1);
% %                 turn off the pump
%                  obj.Instr.source.output = 0;
%                 % set the NA to a 1 GHz span
%                 obj.Instr.na.sweep_span = 1.4e9;
%                 % set NA center frequency
%                  obj.Instr.na.sweep_center = naStartCenterFreq;
%                 % step NA power
%                  for jj = 1:length(naPowers)
%                      fprintf('Setting NA power to: %f\n', naPowers(jj));
%                     obj.Instr.na.power = naPowers(jj);
%                     % take a NA trace
%                     [~, data] = obj.Instr.na.getTrace();
                        % write data to file
                        % obj.DataFileHandler.write({data});
%                 end
%                 
                % turn on the pump
                obj.Instr.source.output = 1;
                % set the NA center frequency and span
                obj.Instr.na.sweep_span = naSpan;
                % set NA power
                obj.Instr.na.power = -20;
                % step the pump frequency = na center frequency
%                 for jj = 1:length(pumpFreqs)
                    obj.Instr.na.sweep_center = naStartCenterFreq;
                    obj.Instr.source.frequency = naStartCenterFreq;
%                     fprintf('Setting pump and network analyzer center f to: %f\n', pumpFreqs(jj));
                    for kk = 1:length(pumpPowers)
                        fprintf('Setting pump power to: %f\n', pumpPowers(kk));
                        obj.Instr.source.power = pumpPowers(kk);
                        % take a NA trace
                        [~, data] = obj.Instr.na.getTrace();
                        % write data to file
                        obj.DataFileHandler.write({data});
                    end
%                 end
                  % turn off source and take the background
%                   obj.Instr.source.output = 0;
%                   [~, databackground] = obj.Instr.na.getTrace();
%                 % set the NA to a 200 MHz span
%                 obj.Instr.na.sweep_span = 0.2e9;
%                 % step the pump frequency and NA center frequency
%                 for jj = 1:length(pumpFreqs)
%                     obj.Instr.source.frequency = pumpFreqs(jj);
%                     obj.Instr.na.sweep_center = pumpFreqs(jj);
%                     % take a NA trace
%                     [~, data] = obj.Instr.na.getTrace();
% write data to file
% %                       obj.DataFileHandler.write({data});
%                 end
            %end
            
            %save(obj.DataFileName, 'data1', 'data2', 'data3', 'fluxBiases', 'pumpFreqs', 'naPowers');
            %save(obj.DataFileName, 'data2', 'fluxBiases', 'naPowers');
            %save(obj.DataFileName, 'data2', 'databackground','fluxBiases', 'pumpFreqs', 'pumpPowers');
            %save(obj.DataFileName, 'data1', 'fluxBiases', 'pumpFreqs', 'naPowers');

        end

        function Init(obj)
            % parse cfg file
            obj.parseExpcfgFile();

            % Check params for errors
            obj.errorCheckExpParams();
            
            % Open all instruments
            obj.openInstruments();
            
            % Prepare all instruments for measurement
            obj.initializeInstruments();

            header = obj.inputStructure;
            naCenterFreq = header.expParams.naStartCenterFreq;
            naSpan = header.expParams.naSpan;
            naPoints = header.InstrParams.na.sweep_points;
            header.xpoints = linspace(naCenterFreq - naSpan/2, naCenterFreq + naSpan/2, naPoints);
            header.xlabel = 'Frequency (Hz)';
            header.ypoints = obj.expSettings.naPowers;
            header.ylabel = 'NA powers (dBm)';
            
            % open data file
            dataDimension = 2;
            obj.openDataFile(dataDimension, header);
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
