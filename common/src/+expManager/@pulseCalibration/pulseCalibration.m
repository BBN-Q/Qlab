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
            if ~exist('filenumber', 'var')
                filenumber = 1;
            end
            if ~exist('basename', 'var')
                basename = 'pulseCalibration';
            end
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
        
        % externally defined static methods
        cost = Pi2CostFunction(data);
        cost = PiCostFunction(data);
        
        function UnitTest()
            script = java.io.File(mfilename('fullpath'));
            path = char(script.getParent());
            % create object instance
            pulseCal = expManager.pulseCalibration(path, '', 'unit_test', 1);
            
            pulseCal.pulseParams = struct('piAmp', 6000, 'pi2Amp', 3000, 'delta', -0.5, 'T', eye(2,2), 'pulseType', 'drag',...
                                     'i_offset', 0, 'q_offset', 0);
            pulseCal.rabiAmpChannelSequence('q1', false);
            pulseCal.rabiAmpChannelSequence('q2', false);
            pulseCal.Pi2CalChannelSequence('q1', 'X', false);
            pulseCal.Pi2CalChannelSequence('q2', 'Y', false);
            pulseCal.PiCalChannelSequence('q1', 'Y', false);
            pulseCal.PiCalChannelSequence('q2', 'X', false);
            
            % perfect Pi2Cal data
            data = [0 0 .5*ones(1,36)];
            cost = pulseCal.Pi2CostFunction(data);
            fprintf('Pi2Cost for ''perfect'' data: %f\n', cost);
            
            % data representing amplitude error
            n = 1:9;
            data = 0.65 + 0.1*(-1).^n .* n./10;
            data = data(floor(1:.5:9.5));
            data = [0.5 0.5 data data];
            cost = pulseCal.Pi2CostFunction(data);
            fprintf('Pi2Cost for more realistic data: %f\n', cost);
            cost = pulseCal.PiCostFunction(data);
            fprintf('PiCost for more realistic data: %f\n', cost);
        end
    end
    methods
        function out = homodyneMeasurement(obj)
            % homodyneMeasurement calls homodyneDetection2DDo and returns
            % the amplitude data
            
            % create file
            obj.openDataFile();
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
            obj.homodyneDetection2DDo();
            % finish and close file
            fprintf(obj.DataFileHandle,'\n$$$ End of Data\n');
            fclose(obj.DataFileHandle);
            data = obj.parseDataFile(false);
            
            % delete the file
            filename = [obj.DataPath '/' obj.DataFileName];
            delete(filename);
            
            % return the amplitude data
            out = data.abs_Data;
        end

        function cost = Xpi2ObjectiveFnc(obj, x0)
            cost = obj.pi2ObjectiveFnc(x0, obj.inputStructure.ExpParams.Qubit, 'X');
        end
        function cost = Ypi2ObjectiveFnc(obj, x0)
            cost = obj.pi2ObjectiveFnc(x0, obj.inputStructure.ExpParams.Qubit, 'Y');
        end
        function cost = XpiObjectiveFnc(obj, x0)
            cost = obj.piObjectiveFnc(x0, obj.inputStructure.ExpParams.Qubit, 'X');
        end
        function cost = YpiObjectiveFnc(obj, x0)
            cost = obj.piObjectiveFnc(x0, obj.inputStructure.ExpParams.Qubit, 'Y');
        end
        
        function Init(obj)
            obj.parseExpcfgFile();
            Init@super(obj);
        end
    end
end
