% Module Name :  singleShotFidelity.m
%
% Author/Date : Colm Ryan  / 9 April, 2012
%
% Description : Analyses single shot readout fidelity

% Restrictions/Limitations : UNRESTRICTED
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%
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

classdef singleShotFidelity < expManager.expBase
    
    properties
        ExpParams
        channelMap
        scope
        awg
    end
    
    methods
        %% Class constructor
        function obj = singleShotFidelity(data_path, cfgFileName, basename, filenumber)
            if ~exist('filenumber', 'var')
                filenumber = 1;
            end
            if ~exist('basename', 'var')
                basename = 'pulseCalibration';
            end
            
            script = mfilename('fullpath');
            sindex = strfind(script, 'common');
            script = [script(1:sindex) 'experiments/muWaveDetection/'];
            
            if ~exist('data_path','var')
                data_path = [script 'data/'];
            end
            
            if ~exist('basename', 'var')
                basename = 'homodyneDetection2D';
            end
            
			% finally we inherit methods and properties from the experiment class
            obj = obj@expManager.expBase(basename, data_path, cfgFileName, filenumber);
        end

        function Init(obj)
            obj.parseExpcfgFile();
            obj.ExpParams = obj.inputStructure.ExpParams;
            
            obj.channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
            
            %Create the sequence of two QId two inversion pulses
            obj.SingleShotSequence()

           % Open all instruments
            obj.openInstruments();

            % Prepare all instruments for measurement
            obj.initializeInstruments();
            
            % find AWG instrument and scope
            numAWGs = 0;
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                InstrName = InstrumentNames{Instr_index};
                DriverName = class(obj.Instr.(InstrName));
                switch DriverName
                    case {'deviceDrivers.Tek5014', 'deviceDrivers.APS'}
                        numAWGs = numAWGs + 1;
                        obj.awg{numAWGs} = obj.Instr.(InstrName);
                    case 'deviceDrivers.AgilentAP240'
                        obj.scope = obj.Instr.(InstrName);
                end
            end
%             % create a generic 'time' sweep
%             timeSweep = struct('type', 'sweeps.Time', 'number', 1, 'start', 0, 'step', 1);
%             obj.inputStructure.SweepParams = struct('time', timeSweep);
        end
        
        function Do(obj)
            obj.singleShotFidelityDo();
        end
        
        function CleanUp(obj)
            %Close all instruments
            obj.closeInstruments;
        end
        
        function errorCheckExpParams(obj)
            % call super class method
            errorCheckExpParams@expManager.homodyneDetection2D(obj);

            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'OffsetNorm')
                ExpParams.OffsetNorm = 2;
            end
        end
        
    end
    
    methods (Static)
        % Forward reference the digitalHomodyne function defined in
        % separate file
        [DI DQ] =  digitalHomodyne(signal, IFfreq, sampInterval, integrationStart, integrationWindow)
    
    end    
    
end
