 function [Data errorMsg] = SwitchingCurve_do(obj,ExpParams,LoopParams,Instr,fid,figureHandle)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [Data] = SwitchingCurve_do(ExpParams,fid)
%
% Description: This function will caputre a single SQUID switching curve
% for a particular flux bias.  Time and Amp will each be fields in the inputStructure
% that are used to construct the waveform.  paramsToVary is a matrix that
% speciefies which values get varied and Ranges will give the range of values over
% which the pulse is varied.  This function operates over a single loop, so all
% parameter will be varied together.
%
% See SwitchingCurve_v1_001.cfg for ExpParam values and descriptions
%
% v1.1 25 JUNE 2009 William Kelly <wkelly@bbn.com>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

errorMsg = '';

if ~exist('figureHandle','var')
    figure;
    figureHandle = gcf;
end

InstrParams = obj.inputStructure.InstrParams;
[Loop ExpParams] = populateLoopStrucutre(obj,LoopParams,ExpParams,InstrParams);

if isempty(Loop.one)
    Loop.two.steps = 1;
else
    setLoop1Params = true;
end
if isempty(Loop.two)
    Loop.two.steps = 1;
    setLoop2Params = false;
else
    setLoop2Params = true;
end
if isempty(Loop.three)
    Loop.three.steps = 1;
    setLoop3Params = false;
else
    setLoop3Params = true;
end

%pre allocate memory
counts = zeros(Loop.one.steps,Loop.two.steps,Loop.three.steps);
%% Main Loop
pause_length = max(1.2*obj.inputStructure.InitParams.triggerSource.WaveformDuration *...
    obj.inputStructure.InitParams.triggerSource.numWaveforms,0.25);
InitParams = obj.inputStructure.InitParams;
fprintf('\n******BEGINNING OF EXPERIMENT*****\n\n')
tic
obj.Instr.fluxPulse.stop(); % just to be safe
for loop3_index = 1:Loop.three.steps
    if setLoop3Params
        setParameter(Loop.three,ExpParams,InitParams,Instr,loop3_index);
    end
    for loop2_index = 1:Loop.two.steps
        if setLoop2Params
            setParameter(Loop.two,ExpParams,InitParams,Instr,loop2_index);
        end
        if isfield(Loop.two,'plotRange')
            y_range = linspace(Loop.two.plotRange.start,Loop.two.plotRange.end,...
                Loop.two.steps);
        else
            y_range = 1:Loop.two.steps;
        end
        for loop1_index = 1:Loop.one.steps
 
            if setLoop1Params
                setParameter(Loop.one,ExpParams,InitParams,Instr,loop1_index)
            end
            if isfield(Loop.one,'plotRange')
                x_range = linspace(Loop.one.plotRange.start,Loop.one.plotRange.end,...
                    Loop.one.steps);
            else
                x_range = 1:Loop.one.steps;
            end
            fprintf('parameters set\n')
            toc
            fprintf('\n')
            fprintf('ready to acquire data\n')
            tic;
            startCounting(Instr);

            obj.Instr.fluxPulse.run();
            [success] = waitForAWGtoStartRunning(obj.Instr.fluxPulse);
            if success == 0, error('AWG timed out'), end
            fprintf(Instr.triggerSource,'*TRG')
            pause(pause_length);
            stopCounting(Instr);
            [counts(loop1_index,loop2_index,loop3_index)] = acquireCounts(Instr);
            obj.Instr.fluxPulse.stop();
            fprintf('finished Acquiring data\n')
            toc
            fprintf('\n')
            tic;
            fprintf(fid,'%d,',counts(loop1_index,loop2_index,loop3_index));
            figure(figureHandle);
            subplot(2,1,1)
            imagesc(x_range,y_range,counts(:,:,loop3_index).',[0,obj.inputStructure.InitParams.triggerSource.numWaveforms]);
            axis tight
            subplot(2,1,2)
            hold on
            plot(x_range(loop1_index),counts(loop1_index,loop2_index,loop3_index),'o');
            grid on
            hold on
        end
        if loop2_index < Loop.two.steps
            fprintf(fid,'\n');
        end
    end
    if loop3_index <Loop.three.steps
        fprintf(fid,'\n### iterating loop3_index \n');
    end
end
fprintf('\n******END OF EXPERIMENT*****\n\n')
%% Output Data
Data = counts;