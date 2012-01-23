function [errorMsg] = homodyneDetectionDo(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [errorMsg] = homodyneDetectionDo(obj)
%
% Description: This method conducts an experiemnt of the type
% homodyneDetection.  Note that the only instrument we have hard coded in
% is triggerSource.  If there is not an instrument called triggerSource
% with a method 'trigger' the experiment will not start.
%
% v1.1 25 JUNE 2009 William Kelly <wkelly@bbn.com>
% v1.2 25 JULY 2010 Tom Ohki
% v1.3 18 NOV 2010 Blake Johnson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TaskParams = obj.inputStructure.TaskParams;
ExpParams = obj.inputStructure.ExpParams;
Instr = obj.Instr;
fid = obj.DataFileHandle;
SD_mode = obj.inputStructure.SoftwareDevelopmentMode;
displayScope = obj.inputStructure.displayScope;

errorMsg = '';

persistent figureHandle;
persistent figureHandle2D;

if isempty(figureHandle)
	figureHandle = figure;
	figureHandle2D = figure;
end

% Loop is a reparsing of the strucutres LoopParams and TaskParams that we
% will use in this method
Loop = obj.populateLoopStructure;
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

if Loop.two.steps > 1 && ~exist('figureHandle2D','var')
	figureHandle2D = figure(2);
end

%pre allocate memory
%% Main Loop
tic

%% If there's anything thats particular to any device do it here

InstrumentNames = fieldnames(Instr);
if ~SD_mode
    for Instr_index = 1:numel(InstrumentNames)
        InstrName = InstrumentNames{Instr_index};
        switch class(Instr.(InstrName))
            case 'deviceDrivers.Tek5014'
                %Instr.(InstrName).stop; % just to be safe
                tekInstrName = InstrName; % so we have this later
				% set the tek awg running, and make sure that it actually
                % starts running.
				Instr.(tekInstrName).run();
                [success_flag_AWG] = Instr.(tekInstrName).waitForAWGtoStartRunning();
                if success_flag_AWG ~= 1, error('AWG timed out'), end
            case 'deviceDrivers.APS'
                Instr.(InstrName).run();
            case 'deviceDrivers.AgilentAP120'
                scope = Instr.(InstrName); % we're going to need this later
            otherwise
                % don't need to do anything with this instrument
        end
    end
end

%%
% for each loop we use the function iterateLoop to set the relevent
% parameters.  For now hard coding in three loops is fine, someday we might
% want to change this.
for loop3_index = 1:Loop.three.steps
    if setLoop3Params
		Loop.three.sweep.step(loop3_index);
	end
	Amp2D = [];
	Phase2D = [];
    for loop2_index = 1:Loop.two.steps
        if setLoop2Params
			Loop.two.sweep.step(loop2_index);
			fprintf('Loop 2: Step %d of %d\n', [loop2_index, Loop.two.steps]);
        end
        if ~SD_mode
			amp = zeros(Loop.one.steps,1);
			phase = zeros(Loop.one.steps,1);
		end
		fprintf('Loop 1: %d steps\n', Loop.one.steps);
        for loop1_index = 1:Loop.one.steps
            if setLoop1Params
				Loop.one.sweep.step(loop1_index);
            end
            % get the x-axis for the plot
            x_range = Loop.one.sweep.points;
            
            if ~SD_mode
                
                % measure I and Q
                [iavg, qavg] = homodyneMeasure(scope, ExpParams.digitalHomodyne, displayScope);
                % convert I/Q to Amp/Phase
                amp(loop1_index) = sqrt(iavg.^2 + qavg.^2);
                phase(loop1_index) = (180.0/pi) * atan2(qavg, iavg);

                % Next we write the data to our data file
                fprintf(fid,'%d+%di,',[iavg;qavg]);
                fprintf(fid,'\n');
                % and plot it for the user
                figure(figureHandle);
                subplot(2,1,1)
				plot(x_range(1:loop1_index),amp(1:loop1_index));
				ylabel('Amplitude');
				grid on
                %axis tight
                subplot(2,1,2)
                %cla
				plot(x_range(1:loop1_index),phase(1:loop1_index));
				ylabel('Phase');
                grid on
            else
                percentComplete = 100*(loop1_index-1 + (loop2_index)/Loop.two.steps)/Loop.one.steps;
                fprintf(fid,'%d\n',percentComplete);
            end
		end
		
		Amp2D = [Amp2D amp];
		Phase2D = [Phase2D phase];
		% display 2D data sets if there is a 2D loop
		if Loop.two.steps > 1
			if isfield(Loop.two,'plotRange')
				y_range = Loop.two.plotRange;
			else
				y_range = 1:Loop.two.sweep.points;
			end
			figure(figureHandle2D);
			subplot(2,1,1);
			imagesc(x_range, y_range(1:loop2_index), Amp2D.');
			ylabel('Amplitude');
			axis tight;
			subplot(2,1,2);
			imagesc(x_range, y_range(1:loop2_index), Phase2D.');
			ylabel('Phase');
			axis tight;
		end
		
        if loop2_index < Loop.two.steps
            fprintf(fid,'\n### iterating loop2_index \n');
        end
    end
    if loop3_index <Loop.three.steps
        fprintf(fid,'\n### iterating loop3_index \n');
    end
end
fprintf('\n******END OF EXPERIMENT*****\n\n')

end
