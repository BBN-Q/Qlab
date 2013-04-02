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
    end
    
    methods
        %% Class constructor
        function obj = SingleShotFidelity()
        end
        
        function Init(obj, settings)
            obj.settings = settings;   
            obj.qubit = obj.settings.qubit;
            
            % create an ExpManager object
            obj.experiment = ExpManager();
            
            % load ExpManager settings
            expSettings = jsonlab.loadjson(obj.settings.cfgFile);
            instrSettings = expSettings.instruments;
            
            % add instruments
            for instrument = fieldnames(instrSettings)'
                instr = InstrumentFactory(instrument{1});
                %If it is an AWG, point it at the correct file
                if ExpManager.is_AWG(instr)
                    if isa(instr, 'deviceDrivers.APS')
                        ext = 'h5';
                    else
                        ext = 'awg';
                    end
                    instrSettings.(instrument{1}).seqfile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-' instrument{1} '.' ext]);
                end
                add_instrument(obj.experiment, instrument{1}, instr, instrSettings.(instrument{1}));
            end
            
            % set scope to digitizer mode
            obj.experiment.instrSettings.scope.acquireMode = 'digitizer';
            
            % set digitizer with the appropriate number of segments and
            % round robins
            obj.experiment.instrSettings.scope.averager.nbrSegments = 2;
            obj.experiment.instrSettings.scope.averager.nbrRoundRobins = settings.numShots/2;
            
            %Add the instrument sweeps
            sweepSettings = settings.sweeps;
            for sweep = fieldnames(sweepSettings)'
                add_sweep(obj.experiment, SweepFactory(sweepSettings.(sweep{1}), obj.experiment.instruments));
            end

            % create a generic SegmentNum sweep
            add_sweep(obj.experiment, sweeps.SegmentNum(struct('label', 'Segment', 'start', 0, 'step', 1, 'numPoints', 2)));
            
            % add single-shot measurement filter
            import MeasFilters.*
            measSettings = expSettings.measurements;
            dh = DigitalHomodyne(measSettings.(obj.settings.measurement));
            add_measurement(obj.experiment, 'single_shot', SingleShot(dh));
            
            %Create the sequence of alternating QId, 180 inversion pulses
            obj.SingleShotSequence(obj.qubit)
            
            % intialize the ExpManager
            init(obj.experiment);
        end
        
        function Do(obj)
            obj.SingleShotFidelityDo();
        end
        
    end
    
end
