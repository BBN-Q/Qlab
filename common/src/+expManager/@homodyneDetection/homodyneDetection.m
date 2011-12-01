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
    end
    methods (Static)
        %% Class constructor
        function obj = homodyneDetection(data_path, cfgFileName, basename, filenumber)
            if ~exist('data_path','var')
                data_path = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\'; % default value
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
            % Check params for errors
            obj.errorCheckExpParams();
            
            % Open all instruments
            obj.openInstruments();
            
            % Prepare all instruments for measurement
            obj.initializeInstruments();
        end
        function Do(obj)
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
			obj.homodyneDetectionDo;
        end
        function CleanUp(obj)
            %Close all instruments
            obj.closeInstruments;
        end
        %% Class destructor
        function delete(obj) %#ok<MANU>
        end
        %% error checking method
        function errorCheckExpParams(obj)
            % Error checking goes here or in homodyneDetection.init.
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'digitalHomodyne')
                ExpParams.digitalHomodyne = struct({'DHmode', 'IFfreq'},{'OFF', 0});
            end
        end
    end
end
