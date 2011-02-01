function [errorMsg] = homodyneDetection2DDo(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [errorMsg] = homodyneDetection2DDo(obj)
%
% Description: This method conducts an experiemnt of the type
% homodyneDetection.  Note that the only instrument we have hard coded in
% is triggerSource.  If there is not an instrument called triggerSource
% with a method 'trigger' the experiment will not start.
%
% v1.1 25 JUNE 2009 William Kelly <wkelly@bbn.com>
% v1.2 25 JULY 2010 Tom Ohki
% v1.3 08 OCT 2010 Blake Johnson
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
persistent scopeHandle;
if isempty(figureHandle)
	figureHandle = figure;
end

if isempty(scopeHandle) && displayScope
    scopeHandle = figure;
end

% Loop is a reparsing of the strucutres LoopParams and TaskParams that we
% will use in this method
Loop = obj.populateLoopStructure;
if isempty(Loop.one)
    Loop.one.steps = 1;
else
    setLoop1Params = true;
    if isempty(figureHandle2D), figureHandle2D = figure; end
end

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
                tekInstrName = InstrName; % so we have this later
				% set the tek awg running, and make sure that it actually
                % starts running.
				Instr.(tekInstrName).run();
                [success_flag_AWG] = Instr.(tekInstrName).waitForAWGtoStartRunning();
                if success_flag_AWG ~= 1, error('AWG timed out'), end
                
                Instr.(tekInstrName).stop(); % to sync Tek and Acqiris card
                pause(0.5);
            case 'deviceDrivers.Agilent33220A'
            case 'deviceDrivers.AgilentE8363C'
                %Instr.(InstrName).output = 'on'; % this is necessary
                % turning on the cwSources could be done in Init, but for 
                % now, I prefer to do it here.
            case 'deviceDrivers.HP8673B'
                %Instr.(InstrName).output = 'on'; % this is necessary
            case 'deviceDrivers.HP8340B'
                %Instr.(InstrName).output = 'on'; % this is necessary
            %case 'deviceDrivers.TekTDS784A'
               % scopeInstrName = InstrName; % we're going to need this later
            case 'deviceDrivers.AgilentAP120'
                scope = Instr.(InstrName); % we're going to need this later
			case 'deviceDrivers.DCBias'
            otherwise
                % unknown instrument type, for now do nothing
        end
    end
end

%%
% for each loop we use the function iterateLoop to set the relevent
% parameters.  For now hard coding in one loop is fine, someday we might
% want to change this.
%         I2D = zeroes(xpts,Loop.one.steps);
%         Q2D = zeroes(xpts,Loop.one.steps);
I2D = [];
Q2D = [];
for loop1_index = 1:Loop.one.steps
    if setLoop1Params
        Loop.one.sweep.step(loop1_index);
        fprintf('Loop 1: Step %d of %d\n', [loop1_index, Loop.one.steps]);
    end
    
    if ~SD_mode
        softAvgs = ExpParams.softAvgs;
        if softAvgs < 1, softAvgs = 1; end
        isoftAvg = [];
        qsoftAvg = [];
        for avg_index = 1:softAvgs
            fprintf('Soft average %d\n', avg_index);

            % set the card to acquire
            success = scope.acquire();

            % set the Tek to run
            Instr.(tekInstrName).run();
            pause(0.5);

            % triggerSource is still hard coded
            %Instr.triggerSource.trigger();
            success = scope.wait_for_acquisition(30);
            if success ~= 0
                error('failed to acquire waveform')
            end

            % Then we retrive our data
            [Amp_I timesI] = scope.transfer_waveform(1);
            [Amp_Q timesQ] = scope.transfer_waveform(2);
            if numel(Amp_I) ~= numel(Amp_Q)
                error('I and Q outputs have different lengths')
            end
            
            if avg_index == 1
                isoftAvg = Amp_I;
                qsoftAvg = Amp_Q;
            else
                isoftAvg = (isoftAvg .* (avg_index - 1) + Amp_I)./(avg_index);
                qsoftAvg = (qsoftAvg .* (avg_index - 1) + Amp_Q)./(avg_index);
            end

            if displayScope
                %scope_y = 1:size(Amp_I,2);
                figure(scopeHandle);
                foo = subplot(2,1,1);
                %imagesc(timesI,scope_y,Amp_I');
                imagesc(isoftAvg');
                xlabel('Time');
                ylabel('Segment');
                set(foo, 'YDir', 'normal');
                title('Ch 1 (I)');
                foo = subplot(2,1,2);
                %imagesc(timesQ,scope_y,Amp_Q');
                imagesc(qsoftAvg');
                xlabel('Time');
                ylabel('Segment');
                set(foo, 'YDir', 'normal');
                title('Ch 2 (Q)');
            end

            % signal processing and analysis
            range = ExpParams.filter.start:ExpParams.filter.start+ExpParams.filter.length - 1;
            switch (ExpParams.digitalHomodyne.DHmode)
                case 'OFF'
                    % calcuate average amplitude and phase
                    iavg = mean(isoftAvg(range,:))';
                    qavg = mean(qsoftAvg(range,:))';
                case 'DH1'
                    % TODO: update digital homodyne to do point by
                    % point conversion
                    [iavg qavg] = obj.digitalHomodyne(isoftAvg(range,:), ...
                        ExpParams.digitalHomodyne.IFfreq*1e6, ...
                        scope.horizontal.sampleInterval);
                case 'DIQ'
                    [iavg qavg] = obj.digitalHomodyneIQ(isoftAvg(range,:), qsoftAvg(range,:), ...
                        ExpParams.digitalHomodyne.IFfreq*1e6, ...
                        scope.horizontal.sampleInterval);
            end
            % convert I/Q to Amp/Phase
            amp = sqrt(iavg.^2 + qavg.^2);
            phase = (180.0/pi) * atan2(qavg, iavg);
            %amp=iavg;
            %phase=qavg;

            fprintf(fid,'\n');
            % and plot it for the user
            figure(figureHandle);
            subplot(2,1,1)
            %plot(iavg);
            plot(amp);
            ylabel('I Voltage');
            grid on
            %axis tight
            subplot(2,1,2)
            %cla
            %plot(qavg);
            plot(phase);
            ylabel('Q Voltage');
            grid on
            
            % stop the Tek so we can resync
            Instr.(tekInstrName).stop();
            pause(0.2);
        end

        % write the data to file
        for i = 1:length(iavg)
            fprintf(fid,'%d+%di ',[iavg(i);qavg(i)]);
        end
        
        I2D = [I2D amp];
        Q2D = [Q2D phase];
        
        % display 2D data sets if there is a loop
        if Loop.one.steps > 1
            y_range = Loop.one.sweep.points;
            figure(figureHandle2D);
            subplot(2,1,1);
            imagesc(1:length(iavg), y_range(1:loop1_index), I2D');
            title('I')
            xlabel('Segment number')
            ylabel(Loop.one.sweep.name)
            axis tight;
            subplot(2,1,2);
            imagesc(1:length(iavg), y_range(1:loop1_index), Q2D');
            title('Q')
            xlabel('Segment number')
            ylabel(Loop.one.sweep.name)
            axis tight;
        end
        
    else
        percentComplete = 100*(loop1_index-1 + (loop2_index)/Loop.two.steps)/Loop.one.steps;
        fprintf(fid,'%d\n',percentComplete);
    end
end

fprintf('\n******END OF EXPERIMENT*****\n\n')
%% Output Data

%% If there's anything thats particular to any device do it here

if ~SD_mode
    InstrumentNames = fieldnames(Instr);
    for Instr_index = 1:numel(InstrumentNames)
        InstrName = InstrumentNames{Instr_index};
        switch class(Instr.(InstrName))
            case 'deviceDrivers.Tek5014'
            case 'deviceDrivers.Agilent33220A'
            case 'deviceDrivers.AgilentE8363C'
                Instr.(InstrName).output = 'off';
            case 'deviceDrivers.HP8673B'
                Instr.(InstrName).output = 'off';
            case 'deviceDrivers.HP8340B'
                Instr.(InstrName).output = 'off';
            case 'deviceDrivers.TekTDS784A'
			case 'deviceDrivers.AgilentAP120'
			case 'deviceDrivers.DCBias'
            otherwise
                % unknown instrument type, for now do nothing
        end
    end
end

end
