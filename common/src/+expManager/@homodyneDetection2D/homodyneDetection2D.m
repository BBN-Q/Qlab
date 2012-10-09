%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  homodyneDetection2D.m
%
% Author/Date : Blake Johnson / Nov 8, 2010
%
% Description : This is the class used for taking a 2D homodyne or heterodyne
% microwave measurement. Copied from homodynceDetection.
%
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
% Copyright 2010 Raytheon BBN Technologies
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef homodyneDetection2D < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
        awg = [];
        scope
        nbrSequences
        Loop
    end
    methods 
        %% Class constructor
        function obj = homodyneDetection2D(data_path, cfgFileName, basename, filenumber)
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
        
        %% Base functions
        function Init(obj)
            % parse cfg file
            obj.parseExpcfgFile();
            
            % Check params for errors
            obj.errorCheckExpParams();

            % Open all instruments
            obj.openInstruments();
            
            % if taking multi-cavity measurements, calculate appropriate
            % digitizer and softAvg settings to maximize the number of shots
            % collected in one go, while roughly preserving the total number of
            % averages
            DHchannels = obj.inputStructure.ExpParams.digitalHomodyne.channel;
            if isa(DHchannels, 'char') && strcmpi(DHchannels, 'Both')
                obj.nbrSequences = obj.inputStructure.InstrParams.scope.averager.nbrSegments;
                softAvgs = obj.inputStructure.ExpParams.softAvgs;
                roundRobins = obj.inputStructure.InstrParams.scope.averager.nbrRoundRobins;
                nbrAverages = roundRobins * softAvgs;
                % find the largest number of segments that will fit on the card
                % that is less than the hardware max of 8191
                multiplier = floor(8191/obj.nbrSequences);
                newSegments = multiplier*obj.nbrSequences;
                newSoftAvgs = ceil(nbrAverages/multiplier);
                % update parameters
                obj.inputStructure.InstrParams.scope.averager.nbrRoundRobins = 1;
                obj.inputStructure.InstrParams.scope.averager.nbrSegments = newSegments;
                obj.inputStructure.ExpParams.softAvgs = newSoftAvgs;
                nbrDataSets = 3;
            else
                obj.nbrSequences = obj.inputStructure.InstrParams.scope.averager.nbrSegments;
                nbrDataSets = 1;
            end

            % Prepare all instruments for measurement
            obj.initializeInstruments();
            
            % find AWG instrument(s) and digitizer
            numAWGs = 0;
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                InstrName = InstrumentNames{Instr_index};
                DriverName = class(obj.Instr.(InstrName));
                switch DriverName
                    case {'deviceDrivers.Tek5014', 'deviceDrivers.APS'}
                        numAWGs = numAWGs + 1;
                        obj.awg{numAWGs} = obj.Instr.(InstrName);
                    case {'deviceDrivers.AgilentAP240', 'deviceDrivers.AlazarATS9870'}
                        obj.scope = obj.Instr.(InstrName);
                end
            end

            % construct loop object and file header
            [obj.Loop, dimension] = obj.populateLoopStructure();
            header = obj.inputStructure;
            switch dimension
                case 1
                    header.xpoints = obj.Loop.one.sweep.points;
                    header.xlabel = obj.Loop.one.sweep.name;
                case 2
                    header.xpoints = obj.Loop.one.sweep.points;
                    header.xlabel = obj.Loop.one.sweep.name;
                    header.ypoints = obj.Loop.two.sweep.points;
                    header.ylabel = obj.Loop.two.sweep.name;
                case 3
                    header.xpoints = obj.Loop.one.sweep.points;
                    header.xlabel = obj.Loop.one.sweep.name;
                    header.ypoints = obj.Loop.two.sweep.points;
                    header.ylabel = obj.Loop.two.sweep.name;
                    header.zpoints = obj.Loop.three.sweep.points;
                    header.zlabel = obj.Loop.three.sweep.name;
                otherwise
                    error('Loop dimension is larger than 3')
            end
            
            % open data file
            obj.openDataFile(dimension, header, nbrDataSets);
        end
        function Do(obj)
			obj.homodyneDetection2DDo;
        end
        function CleanUp(obj)
            % turn off all microwave sources and stop all AWGs
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                InstrName = InstrumentNames{Instr_index};
                DriverName = class(obj.Instr.(InstrName));
                if isa(obj.Instr.(InstrName), 'deviceDrivers.lib.uWSource')
                    obj.Instr.(InstrName).output = 0;
                end
                
                if strcmp(DriverName, 'deviceDrivers.Tek5014') || strcmp(DriverName, 'deviceDrivers.APS')
                    obj.Instr.(InstrName).stop();
                end
            end

            % close all instruments
            obj.closeInstruments();

            % close data file
            obj.finalizeData();
        end
        %% Class destructor
        function delete(obj)
            obj.CleanUp()
        end
        %% error checking method
        function errorCheckExpParams(obj)
            % Error checking goes here or in homodyneDetection.init.
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'digitalHomodyne')
                ExpParams.digitalHomodyne = struct('DHmode', 'OFF', 'IFfreq', 0);
            end
            
            %Check whether the AWG file exists before we start things up
            if (isfield(obj.inputStructure.InstrParams, 'TekAWG') && obj.inputStructure.InstrParams.TekAWG.enable)
                assert(logical(exist(obj.inputStructure.InstrParams.TekAWG.seqfile,'file')), 'Oops! The AWG file for the TekAWG does not exist.')
            end
            if (isfield(obj.inputStructure.InstrParams, 'BBNAPS') && obj.inputStructure.InstrParams.BBNAPS.enable)
                assert(logical(exist(obj.inputStructure.InstrParams.BBNAPS.seqfile,'file')), 'Oops! The AWG file for the BBNAWG does not exist.')
            end
            
        end
        
        function [DI, DQ, DIQ] = processSignal(obj, isignal, qsignal)
            ExpParams = obj.inputStructure.ExpParams;
            switch ExpParams.digitalHomodyne.DHmode
                case 'OFF'
                    % calcuate average amplitude and phase
                    range = ExpParams.filter.start:ExpParams.filter.start+ExpParams.filter.length - 1;
                    DI = mean(isignal(range,:))';
                    DQ = mean(qsignal(range,:))';
                case 'DH1'
                    switch ExpParams.digitalHomodyne.channel
                        case {1, '1'}
                            [DI DQ] = obj.digitalHomodyne(isignal, ...
                                ExpParams.digitalHomodyne.IFfreq*1e6, ...
                                obj.scope.horizontal.sampleInterval, ExpParams.filter.start, ExpParams.filter.length);
                        case {2, '2'}
                            [DI DQ] = obj.digitalHomodyne(qsignal, ...
                                ExpParams.digitalHomodyne.IFfreq*1e6, ...
                                obj.scope.horizontal.sampleInterval, ExpParams.filter.start, ExpParams.filter.length);
                        case 'Both'
                            [DI DQ DIQ] = obj.digitalHomodyne(isignal, qsignal, obj.nbrSequences,...
                                ExpParams.digitalHomodyne.IFfreq*1e6, ...
                                obj.scope.horizontal.sampleInterval, ExpParams.filter.start, ExpParams.filter.length);
                    end
                case 'DIQ'
                    [DI DQ] = obj.digitalHomodyneIQ(isignal, qsignal, ...
                        ExpParams.digitalHomodyne.IFfreq*1e6, ...
                        obj.scope.horizontal.sampleInterval, ExpParams.filter.start, ExpParams.filter.length);
            end
        end
    end
    
    methods (Static)
        % Forward reference the digitalHomodyne function defined in
        % separate file
        [DI DQ DIQ] =  digitalHomodyne(varargin)
        
    end

end
