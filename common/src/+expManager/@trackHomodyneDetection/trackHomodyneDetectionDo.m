function [errorMsg] = trackHomodyneDetectionDo(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [errorMsg] = trackHomodyneDetectionDo(obj)
%
% Description: This method conducts an experiemnt of the type
% homodyneDetection.  Note that the only instrument we have hard coded in
% is triggerSource.  If there is not an instrument called triggerSource
% with a method 'trigger' the experiment will not start.
%
% v1.0 18 NOV 2010 Blake Johnson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ExpParams = obj.inputStructure.ExpParams;
Instr = obj.Instr;
fid = obj.DataFileHandle;
trackedfid = obj.TrackedDataFileHandle;
SD_mode = obj.inputStructure.SoftwareDevelopmentMode;
displayScope = obj.inputStructure.displayScope;

errorMsg = '';

persistent figureHandle;
persistent figureHandle2D;
persistent trackedFigureHandle2D;

if isempty(figureHandle)
	figureHandle = figure;
	figureHandle2D = figure;
    trackedFigureHandle2D = figure;
end

% Loop is a reparsing of the strucutres LoopParams and TaskParams that we
% will use in this method
Loop = obj.populateLoopStructure;
% if isempty(Loop.one)
%     Loop.one.steps = 1;
% else
%     setLoop1Params = true;
% end
% if isempty(Loop.two)
%     Loop.two.steps = 1;
%     setLoop2Params = false;
% else
%     setLoop2Params = true;
% end

%pre allocate memory
%% Main Loop

fprintf('\n******BEGINNING OF EXPERIMENT*****\n\n')
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
            case 'deviceDrivers.AgilentAP120'
                scope = Instr.(InstrName); % we're going to need this later
            otherwise
                % don't need to do anything with this instrument
        end
    end
end

% each inner loop has to do a cavity sweep to find the resonator frequency

Amp2D = [];
Phase2D = [];
TrackAmp2D = [];
TrackPhase2D = [];
for loop2_index = 1:Loop.two.steps
    Loop.two.sweep.step(loop2_index);
    fprintf('Loop 2: Step %d of %d\n', [loop2_index, Loop.two.steps]);

    if ~SD_mode
        %Amp_volts = zeros(Loop.one.steps,scope.averager.record_length);
        amp = zeros(Loop.track.steps,1);
        phase = zeros(Loop.track.steps,1);
    end
    
    % do the tracked loop
    fprintf('Track scan: %d steps\n', Loop.track.steps);
    x_range = Loop.track.sweep.points;
    for loop1_index = 1:Loop.track.steps
        Loop.track.sweep.step(loop1_index);

        if ~SD_mode
            % measure I and Q
            [iavg, qavg] = homodyneMeasure(scope, ExpParams.digitalHomodyne, displayScope);
            % convert I/Q to Amp/Phase
            amp(loop1_index) = sqrt(iavg.^2 + qavg.^2);
            phase(loop1_index) = (180.0/pi) * atan2(qavg, iavg);

            % Next we write the data to our data file
            fprintf(trackedfid,'%d+%di,',[iavg;qavg]);
            fprintf(trackedfid,'\n');
            
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
            percentComplete = 100*(loop1_index-1 + (loop2_index)/Loop.two.steps)/Loop.track.steps;
            fprintf(trackedfid,'%d\n',percentComplete);
        end
    end
    % add current slice to 2D data sets
    TrackAmp2D = [TrackAmp2D amp];
    TrackPhase2D = [TrackPhase2D phase];
    % display 2D data sets if there is a 2D loop
    if Loop.two.steps > 1
        y_range = Loop.two.sweep.points;
        figure(trackedFigureHandle2D);
        subplot(2,1,1);
        imagesc(x_range, y_range(1:loop2_index), TrackAmp2D');
        ylabel(Loop.two.sweep.name);
        title('Amplitude');
        axis tight;
        subplot(2,1,2);
        imagesc(x_range, y_range(1:loop2_index), TrackPhase2D');
        ylabel(Loop.two.sweep.name);
        title('Phase');
        axis tight;
    end
    
    % find the new cavity frequency and set it
    [minamp freq_index] = min(amp);
    freq = x_range(freq_index);
    Instr.RFgen.frequency = freq;
    Instr.LOgen.frequency = freq + ExpParams.digitalHomodyne.IFfreq*1e-3; % IF frequency is in MHz
    
    % do loop one
    fprintf('Loop 1: %d steps\n', Loop.one.steps);
    amp = zeros(Loop.one.steps,1);
    phase = zeros(Loop.one.steps,1);
    
    x_range = Loop.one.sweep.points;
    for loop1_index = 1:Loop.one.steps
        Loop.one.sweep.step(loop1_index);

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
            %imagesc(time_usec.array(firstPoint:lastPoint),x_range,abs(Amp_volts));
            plot(x_range(1:loop1_index),amp(1:loop1_index));
            ylabel('Amplitude');
            grid on
            %axis tight
            subplot(2,1,2)
            %cla
            plot(x_range(1:loop1_index),phase(1:loop1_index));
            ylabel('Phase');
            %plot(time_usec.array(firstPoint:lastPoint),abs(Amp_volts(loop1_index,:)),'linewidth',3);
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
        if isfield(Loop.one,'plotRange')
            y_range = linspace(Loop.two.plotRange.start,Loop.two.plotRange.end,...
                Loop.two.steps);
        else
            y_range = 1:Loop.two.steps;
        end
        figure(figureHandle2D);
        subplot(2,1,1);
        imagesc(x_range, y_range(1:loop2_index), Amp2D.');
        ylabel(Loop.two.sweep.name);
        title('Amplitude');
        axis tight;
        subplot(2,1,2);
        imagesc(x_range, y_range(1:loop2_index), Phase2D.');
        ylabel(Loop.two.sweep.name);
        title('Phase');
        axis tight;
    end

    if loop2_index < Loop.two.steps
        fprintf(fid,'\n### iterating loop2_index \n');
    end
end

fprintf('\n******END OF EXPERIMENT*****\n\n')
%% Output Data

end
