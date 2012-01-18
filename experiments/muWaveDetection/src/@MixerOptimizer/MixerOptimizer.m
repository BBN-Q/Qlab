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
%
% File: MixerOptimizer.m
%
% Author: Blake Johnson, BBN Technologies
%
% Description: Corrects for carrier leakage, amplitude imbalance, and phase
% skew of an I/Q mixer.
%

classdef MixerOptimizer < expManager.expBase
   properties
       % instruments
       sa % spectrum analyzer
       specgen % the LO source of the mixer to calibrate
       awg % the AWG driving the I/Q ports of the mixer
       cfg_path;
       costFunctionGoal = -70;
       testMode = false
   end
   
   methods
       % constructor
       function obj = MixerOptimizer(cfg_file_path)
           if ~exist('cfg_file_path', 'var')
               cfg_file_path = '../../cfg/optimize_mixer.cfg';
           end
           % call super class
           obj = obj@expManager.expBase('optimize_mixer', '', cfg_file_path, 1);
           obj.cfg_path = fileparts(cfg_file_path);
       
           % load config
           obj.parseExpcfgFile();
       end
       
       %% class methods
       function Init(obj)
            obj.errorCheckExpParams();
            obj.openInstruments();
            obj.initializeInstruments();
            
            if isfield(obj.inputStructure, 'SoftwareDevelopmentMode') && obj.inputStructure.SoftwareDevelopmentMode
                obj.testMode = true;
            end
            
            if ~obj.testMode
                obj.sa = obj.Instr.spectrum_analyzer;
                obj.specgen = obj.Instr.Specgen;
                obj.awg = obj.Instr.AWG;
            end
        end
        function Do(obj)
            try
                %i_offset = -.006;
                %q_offset = -.076;
                [i_offset, q_offset] = obj.optimize_mixer_offsets();
                T = obj.optimize_mixer_ampPhase(i_offset, q_offset);
                % save transformation and offsets to file
                save([obj.cfg_path '/mixercal.mat'], 'i_offset', 'q_offset', 'T', '-v7.3');
            catch exception
                warning(exception.identifier, 'Error in MixerOptimizer.Do()\n%s', exception.message);
            end
        end
        function CleanUp(obj)
            %Close all instruments
            obj.closeInstruments();
        end
        
        function errorCheckExpParams(obj)
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'SpecAnalyzer')
                error('Must provide ExpParams.SpecAnalyzer struct');
            end
            if ~isfield(ExpParams, 'Mixer')
                error('Must provide ExpParams.Mixer struct');
            end
            if ~isfield(ExpParams, 'SSBFreq')
                error('Must specify ExpParams.SSBFreq');
            end
        end
        
        function Run(obj)
            obj.Init();
            obj.Do();
            obj.CleanUp();
        end

        function stop = LMStoppingCondition(obj, x, optimValues, state)
            if 10*log10(optimValues.resnorm) < obj.costFunctionGoal
                stop = true;
            else
                stop = false;
            end
        end
   end
end