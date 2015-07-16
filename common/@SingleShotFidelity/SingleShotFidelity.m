% Module Name :  SingleShotFidelity.m
%
% Author/Date : Colm Ryan  / 9 April, 2012
%
% Description : Analyses single shot readout fidelity

%
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

classdef SingleShotFidelity < handle
    
    properties
        experiment % an instance of the ExpManager class
        settings % a structure of instrument/measurement/sweep settings
        qubit %which qubit we are on
        controlAWG
        readoutAWG
        autoSelectAWGs;
    end
    
    methods
        %Class constructor
        function obj = SingleShotFidelity()
        end
        
        function Init(obj, settings)
            obj.settings = settings;   
            obj.qubit = obj.settings.qubit;
            
            % create an ExpManager object
            obj.experiment = ExpManager();
            
            obj.experiment.dataFileHandler = HDF5DataHandler(settings.fileName);
            
            % load ExpManager settings
            expSettings = json.read(obj.settings.cfgFile);
            instrSettings = expSettings.instruments;
            
            % construct data file header
            headerStruct = expSettings;
            headerStruct.singleshot = settings;
            obj.experiment.dataFileHeader = headerStruct;
                     
            warning('off', 'json:fieldNameConflict');
            channelLib = json.read(getpref('qlab','ChannelParamsFile'));
            warning('on', 'json:fieldNameConflict');
            channelLib = channelLib.channelDict;
            
            tmpStr = regexp(channelLib.(obj.qubit).physChan, '-', 'split');
            obj.controlAWG = tmpStr{1};
            tmpStr = regexp(channelLib.(strcat(genvarname('M-'),obj.qubit)).physChan, '-', 'split'); 
            obj.readoutAWG = tmpStr{1};
            
            obj.autoSelectAWGs = settings.autoSelectAWGs;
            
            % add instruments
            for instrument = fieldnames(instrSettings)'
                fprintf('Connecting to %s\n', instrument{1});
                instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
                %If it is an AWG, point it at the correct file
                if ExpManager.is_AWG(instr)
                    if obj.autoSelectAWGs
                        if ~strcmp(instrument,obj.controlAWG) && ~strcmp(instrument,obj.readoutAWG) && ~instrSettings.(instrument{1}).isMaster
                        %ignores the AWGs which are not either driving or reading this qubit
                        continue
                        end
                    end
                    if isa(instr, 'deviceDrivers.APS') || isa(instr, 'APS2') || isa(instr, 'APS')
                        ext = 'h5';
                    else
                        ext = 'awg';
                    end
                    fprintf('Enabling %s\n', instrument{1});
                %To get a different sequence loaded into the APS1 when used as a slave for the msm't only.
                    %if isa(instr,'deviceDrivers.APS') && instrSettings.(instrument{1}).isMaster == 0
                    %    instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), 'Reset', ['MeasReset-' instrument{1} '.' ext]);
                    %else
                        instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-' instrument{1} '.' ext]);
                    %end
                end
                if ExpManager.is_scope(instr)
                    scopeName = instrument{1};
                end
                add_instrument(obj.experiment, instrument{1}, instr, instrSettings.(instrument{1}));
                if ExpManager.is_scope(instr)
                    % set scope to digitizer mode
                    obj.experiment.instrSettings.(scopeName).acquireMode = 'digitizer';
                    % set digitizer with the appropriate number of segments and
                    % round robins
                    obj.experiment.instrSettings.(scopeName).averager.nbrSegments = settings.numShots;
                    obj.experiment.instrSettings.(scopeName).averager.nbrRoundRobins = 1;
                end
            end          
            
            %Add the instrument sweeps
            sweepSettings = settings.sweeps;
            sweepNames = fieldnames(sweepSettings);
            for sweepct = 1:length(sweepNames)
                add_sweep(obj.experiment, sweepct, SweepFactory(sweepSettings.(sweepNames{sweepct}), obj.experiment.instruments));
            end
            if isempty(sweepct)
                % create a generic SegmentNum sweep
                %Even though there really is two segments there only one data
                %point (SS fidelity) being returned at each step.
                add_sweep(obj.experiment, 1, sweeps.SegmentNum(struct('axisLabel', 'Segment', 'start', 0, 'step', 1, 'numPoints', 1)));
            end

            % add single-shot measurement filter
            measSettings = expSettings.measurements;
            add_measurement(obj.experiment, 'SingleShot',...
                MeasFilters.SingleShot('SingleShot', struct('dataSource', obj.settings.dataSource, 'plotMode', 'real/imag', 'plotScope', true, 'logisticRegression', obj.settings.logisticRegression, 'saveKernel', obj.settings.saveKernel, 'optIntegrationTime', obj.settings.optIntegrationTime)));
            curSource = obj.settings.dataSource;
            while (true)
               sourceParams = measSettings.(curSource);
               curFilter = MeasFilters.(sourceParams.filterType)(curSource, sourceParams);
               add_measurement(obj.experiment, curSource, curFilter);
               if isa(curFilter, 'MeasFilters.RawStream') || isa(curFilter, 'MeasFilters.StreamSelector')
                   break;
               end
               curSource = sourceParams.dataSource;
            end
            
            %Create the sequence of alternating QId, 180 inversion pulses
            if obj.settings.createSequence
                obj.SingleShotSequence(obj.qubit)
            end
            
            % intialize the ExpManager
            init(obj.experiment);
        end
        
        function SSData = Do(obj)
            obj.experiment.run();
            drawnow();
            SSData = obj.experiment.data.SingleShot;
        end
        
    end
    
end
