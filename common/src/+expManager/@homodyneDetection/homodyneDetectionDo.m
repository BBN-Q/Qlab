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

if isempty(figureHandle) || ~ishandle(figureHandle)
    figureHandle = figure;
end
if isempty(figureHandle2D) || ~ishandle(figureHandle2D)
        figureHandle2D = figure;
end
% Loop is a reparsing of the strucutres LoopParams and TaskParams that we
% will use in this method
Loop = obj.populateLoopStructure;


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
            case 'deviceDrivers.AgilentAP240'
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

% Setup the plot handles
%Get the x-axis for the plot and initialize it
x_range = Loop.one.sweep.points;

axesHandle1DAmp = subplot(2,1,1,'Parent', figureHandle);
grid(axesHandle1DAmp, 'on')
axesHandle1DPhase = subplot(2,1,2,'Parent', figureHandle);
grid(axesHandle1DPhase, 'on')

plotHandle1DAmp = plot(axesHandle1DAmp, x_range, nan(1,Loop.one.steps));
ylabel(axesHandle1DAmp, 'Amplitude (V)');
xlabel(axesHandle1DAmp, 'Frequency (GHz)');
plotHandle1DPhase = plot(axesHandle1DPhase, x_range, nan(1,Loop.one.steps));
ylabel(axesHandle1DPhase, 'Phase (degrees)');
xlabel(axesHandle1DPhase, 'Frequency (GHz)');

if Loop.two.steps > 1
    axesHandle2DAmp = subplot(2,1,1,'Parent', figureHandle2D);
    axesHandle2DPhase = subplot(2,1,2,'Parent', figureHandle2D);
    ylabel(axesHandle2DPhase, 'Phase');
    if isfield(Loop.two,'plotRange')
        y_range = Loop.two.plotRange;
    else
        y_range = 1:Loop.two.sweep.points;
    end
    plotHandle2DAmp = imagesc(x_range, y_range, nan(Loop.two.steps, Loop.one.steps), 'Parent', axesHandle2DAmp);
    xlabel(axesHandle2DAmp, 'Frequency (GHz)');
    ylabel(axesHandle2DAmp, Loop.two.sweep.name);
    plotHandle2DPhase = imagesc(x_range, y_range, nan(Loop.two.steps, Loop.one.steps), 'Parent', axesHandle2DPhase);
    xlabel(axesHandle2DPhase, 'Frequency (GHz)');
    ylabel(axesHandle2DPhase, Loop.two.sweep.name);
end

for loop3_index = 1:Loop.three.steps
    Loop.three.sweep.step(loop3_index);
    
    %Initialize the arrays for the 2D plotting
    Amp2D = nan(Loop.two.steps, Loop.one.steps);
    Phase2D = nan(Loop.two.steps, Loop.one.steps);
    for loop2_index = 1:Loop.two.steps
        Loop.two.sweep.step(loop2_index);
        fprintf('Loop 2: Step %d of %d\n', [loop2_index, Loop.two.steps]);
        if ~SD_mode
            amp = nan(1,Loop.one.steps);
            phase = nan(1,Loop.one.steps);
        end
        fprintf('Loop 1: %d steps\n', Loop.one.steps);
            
        for loop1_index = 1:Loop.one.steps
            Loop.one.sweep.step(loop1_index);
            
            if ~SD_mode
                
                % measure I and Q
                [iavg, qavg] = homodyneMeasure(scope, ExpParams.digitalHomodyne, displayScope);
                % convert I/Q to Amp/Phase
                amp(loop1_index) = sqrt(iavg.^2 + qavg.^2);
                phase(loop1_index) = (180.0/pi) * atan2(qavg, iavg);
                
                % Next we write the data to our data file
                fprintf(fid,'%d+%di,\n',[iavg;qavg]);
                % And then update the plots for the user
                set(plotHandle1DAmp, 'YData', amp)
                set(plotHandle1DPhase, 'YData', phase)
                
            else
                percentComplete = 100*(loop1_index-1 + (loop2_index)/Loop.two.steps)/Loop.one.steps;
                fprintf(fid,'%d\n',percentComplete);
            end
        end
        
        Amp2D(loop2_index,:) = amp;
        Phase2D(loop2_index,:) = phase;
        % Update the 2D plots if there is a 2D loop
        if Loop.two.steps > 1
            set(plotHandle2DAmp, 'CData', Amp2D);
            set(plotHandle2DPhase, 'CData', Phase2D);
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
