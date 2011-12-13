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
        pulseParams
        pulseParamPath
        mixerCalPath
        channelMap
    end
    methods (Static)
        %% Class constructor
        function obj = pulseCalibration(data_path, cfgFileName, basename, filenumber)
			% superclass constructor
            obj = obj@expManager.homodyneDetection2D(data_path, cfgFileName, basename, filenumber);
            
            script = mfilename('fullpath');
            sindex = strfind(script, 'common');
            script = [script(1:sindex-1) 'experiments/muWaveDetection/'];
            
            obj.mixerCalPath = [script 'cfg/mixercal.mat'];
            obj.pulseParamPath = [script 'cfg/pulseParamBundles.mat'];
            
            % to do: load channel mapping from file
            obj.channelMap = containers.Map();
            obj.channelMap('q1') = {1,2,'3m1'};
            obj.channelMap('q2') = {3,4,'4m1'};
            obj.channelMap('q1q2') = {5,6,'2m1'};
        end
        
        function UnitTest()
            script = java.io.File(mfilename('fullpath'));
            path = char(script.getParent());
            % create object instance
            pulseCal = expManager.pulseCalibration(path, '', 'unit_test', 1);
            
            pulseCal.pulseParams = struct('piAmp', 6000, 'pi2Amp', 3000, 'delta', -0.5, 'T', eye(2,2), 'pulseType', 'drag',...
                                     'i_offset', 0, 'q_offset', 0);
            pulseCal.Pi2CalChannelSequence('q1', 'X', true);
            pulseCal.Pi2CalChannelSequence('q2', 'Y', false);
        end
    end
    methods

    end
end
