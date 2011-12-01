%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  trackHomodyneDetection.m
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
%    11/19/10    BRJ   Copied homodyneDetection class to this.
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

classdef trackHomodyneDetection < expManager.expBase
    properties %This is only for properties not defined in the 'experiment' superlcass
        % need a second file for the tracked quantity
        TrackedDataFileHandle
        TrackedDataFileName
    end
    methods (Static)
        %% Class constructor
        function obj = trackHomodyneDetection(data_path, cfgFileName, basename, filenumber)
            if ~exist('data_path','var')
                data_path = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\'; % default value
            end
            
            if ~exist('basename', 'var')
                basename = 'trackHomodyneDetection';
            end
                        
			% call base class constructor
            obj = obj@expManager.expBase(basename, data_path, cfgFileName, filenumber);
            
            obj.TrackedDataFileName = sprintf('%03d_%s_tracked.out', obj.filenumber, obj.Name);
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
			obj.trackHomodyneDetectionDo;
        end
        function CleanUp(obj)
            %Close all instruments
            obj.closeInstruments;
        end
        %% Class destructor
        function delete(obj)
        end
        %% error checking method
        function errorCheckExpParams(obj)
            % Error checking goes here or in homodyneDetection.init.
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'digitalHomodyne')
                ExpParams.digitalHomodyne = struct({'DHmode', 'IFfreq'},{'OFF', 0});
            end
        end
        
        % overload base methods
        function [errorMsg] = openDataFile(obj)
            % This function will open the secondary data file with write permission
            % in the desired directory.
            
            % First we make sure the filename exists
            if isempty(obj.TrackedDataFileName)
                errorMsg = 'FileNameNotFound';
                return
            end

			fullname = [obj.DataPath '/' obj.TrackedDataFileName];
            % open up the file with write/create permission
            [obj.TrackedDataFileHandle errorMsg] = fopen(fullname,'w');
            % call parent method to open main file handle
            openDataFile@expManager.expBase(obj);
        end
        
        function [errorMsg] = finalizeData(obj)
            fid = obj.TrackedDataFileHandle;
            fprintf(fid,'\n$$$ End of Data\n');
            fprintf(fid,'# Data taking finished at %s\n',datestr(now,0));
            errorFlag = fclose(obj.TrackedDataFileHandle);
            if errorFlag ~= 0
                errorMsg = sprintf('Error: Failed to close file %s',obj.TrackedDataFileName);
            end
            % call parent method
            finalizeData@expManager.expBase(obj);
        end
    end
end
