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
    end
    methods (Static)
        %% Class constructor
        function obj = homodyneDetection2D(data_path, cfgFileName, basename, filenumber)
            if ~exist('data_path','var')
                data_path = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\'; % default value
            end
            
            if ~exist('basename', 'var')
                basename = 'homodyneDetection2D';
            end
            
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
                DriverName = class(obj.Instr.(InstrName));
                if strcmp(DriverName, 'deviceDrivers.Tek5014') || strcmp(DriverName, 'deviceDrivers.APS')
                    numAWGs = numAWGs + 1;
                    obj.awg(numAWGs) = obj.Instr.(InstrName);
                end
            end
        end
        function errorMsg = Do(obj)
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
			obj.homodyneDetection2DDo;
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
