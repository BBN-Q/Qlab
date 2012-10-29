%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  homodyneDetection.m
%
% Author/Date : William Kelly / 27-Jul-09
%
% Description : This is the class used for taking a homodyne or heterodyne
% microwave measurement
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
%    10/6/10     BRJ   Cleanup
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

classdef homodyneDetection < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
        Loop
    end
    methods (Static)
        %% Class constructor
        function obj = homodyneDetection(data_path, cfgFileName, basename, filenumber)
            if ~exist('data_path','var')
                data_path = ''; % default value
            end
            
            if ~exist('basename', 'var')
                basename = 'homodyneDetection';
            end
            
			% finally we inherit methods and properties from the experiment class
            obj = obj@expManager.expBase(basename, data_path, cfgFileName, filenumber);
        end
    end
    methods
        %% Base functions
        function Init(obj)
            % parse cfg file
            obj.parseExpcfgFile();

            % Check params for errors
            obj.errorCheckExpParams();
            
            % Open all instruments
            obj.openInstruments();
            
            % Prepare all instruments for measurement
            obj.initializeInstruments();
            
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
            obj.openDataFile(dimension, header);
        end
        function Do(obj)
			obj.homodyneDetectionDo();
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
            obj.CleanUp();
        end
        %% error checking method
        function errorCheckExpParams(obj)
            % Error checking goes here or in homodyneDetection.init.
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'digitalHomodyne')
                ExpParams.digitalHomodyne = struct('DHmode', 'OFF', 'IFfreq', 0);
            end
        end
    end
end
