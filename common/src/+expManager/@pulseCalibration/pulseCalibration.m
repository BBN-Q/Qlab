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

classdef pulseCalibration < expManager.homodyneDetection2D
    properties
        pulseParamPath
    end
    methods (Static)
        %% Class constructor
        function obj = pulseCalibration(data_path, cfgFileName, basename, filenumber)
			% superclass constructor
            obj = obj@expManager.homodyneDetection2D(data_path, cfgFileName, basename, filenumber);
            
            script = mfilename('fullpath');
            sindex = strfind(script, 'common');
            script = [script(1:sindex) 'experiments/muWaveDetection/'];
            
            obj.pulseParamPath = [script 'cfg/pulseParams.mat'];
        end
    end
    methods

    end
end
