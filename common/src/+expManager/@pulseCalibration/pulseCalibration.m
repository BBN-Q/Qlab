%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  pulseCalibration.m
%
% Author/Date : Blake Johnson / Aug 24, 2011
%
% Description : Loops over a set of homodyneDetection2D experiments to
% optimize qubit operations
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

classdef pulseCalibration < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
    end
    methods (Static)
        %% Class constructor
        function obj = pulseCalibration(data_path, cfgFileName, basename, filenumber)
            script = mfilename('fullpath');
            sindex = strfind(script, 'qlab');
            script = [script(1:sindex) 'qlab/experiments/muWaveDetection/'];
            
            if ~exist('data_path','var')
                data_path = [script 'data/'];
            end
            
            if ~exist('basename', 'var')
                basename = 'pulseCalibration';
            end
            
            obj.pulseParamPath = [script 'cfg/pulseParams.mat'];
            
			% finally we inherit methods and properties from the experiment class
            obj = obj@expManager.expBase(basename, data_path, cfgFileName, filenumber);
        end
    end
    methods
        %% Base functions
        function errorMsg = Init(obj)
            errorMsg = '';
            % Open all instruments
            errorMsg = obj.openInstruments(errorMsg);
            %%% The next two functions are experiment specific %%%
            % Check params for errors
            errorMsg = obj.errorCheckExpParams(errorMsg);
            % Prepare all instruments for measurement
            errorMsg = obj.initializeInstruments(errorMsg);
            % Set initial Exp parameters
            errorMsg = obj.prepareForExperiment(errorMsg);
            
            % find AWG instrument(s)
            numAWGs = 0;
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                InstrName = InstrumentNames{Instr_index};
                if strcmp( class(obj.Instr.(InstrName)), 'deviceDrivers.Tek5014' )
                    numAWGs = numAWGs + 1;
                    obj.awg(numAWGs) = obj.Instr.(InstrName);
                end
            end
        end
        function errorMsg = Do(obj)
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
			obj.pulseCalibrationDo;
        end
        function errorMsg = CleanUp(obj)
            %Close all instruments
            errorMsg = obj.closeInstruments;
        end
        %% Class destructor
        function delete(obj)
        end
        %% error checking method
        function errorMsg = errorCheckExpParams(obj,errorMsg)
            % Error checking goes here or in homodyneDetection.init.
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'digitalHomodyne')
                ExpParams.digitalHomodyne = struct({'DHmode', 'IFfreq'},{'OFF', 0});
            end
        end
    end
end
