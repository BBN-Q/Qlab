function homodyneDetection2DDo(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [errorMsg] = homodyneDetection2DDo(obj)
%
% Description: This method conducts an experiemnt of the type
% homodyneDetection.
%
% v1.1 25 JUNE 2009 William Kelly <wkelly@bbn.com>
% v1.2 25 JULY 2010 Tom Ohki
% v1.3 08 OCT 2010 Blake Johnson
% v1.4 12 OCT 2011 Blake Johnson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ExpParams = obj.inputStructure.ExpParams;
Instr = obj.Instr;
SD_mode = obj.inputStructure.SoftwareDevelopmentMode;
displayScope = obj.inputStructure.displayScope;

persistent figureHandle;
persistent figureHandle2D;
persistent scopeHandle;

if isempty(figureHandle) || ~ishandle(figureHandle)
	figureHandle = figure('HandleVisibility', 'callback');
end
if isempty(figureHandle2D) || ~ishandle(figureHandle2D)
        figureHandle2D = figure('HandleVisibility', 'callback');
end
if isempty(scopeHandle) && displayScope
    scopeHandle = figure('HandleVisibility', 'callback');
end

% stop the master and make sure it stopped
masterAWG = obj.awg{1};
masterAWG.stop();
masterAWG.operationComplete();
% start all the slave AWGs
for i = 2:length(obj.awg)
    awg = obj.awg{i};
    awg.run();
    [success_flag_AWG] = awg.waitForAWGtoStartRunning();
    if success_flag_AWG ~= 1, error('AWG %d timed out', i), end
end

% for each loop we use the function iterateLoop to set the relevent
% parameters.  For now hard coding in one loop is fine, someday we might
% want to change this.
Amp2D = nan(obj.Loop.two.steps, obj.Loop.one.steps);
Phase2D = nan(obj.Loop.two.steps, obj.Loop.one.steps);
% loop "1" contains the step information in the pattern file segments
% so, we iterate over loop 2

x_range = obj.Loop.one.sweep.points;

multiChMode = strcmpi(ExpParams.digitalHomodyne.channel, 'Both');

if ~multiChMode
    axesHandle1DAmp = subplot(2,1,1,'Parent', figureHandle);
    grid(axesHandle1DAmp, 'on')
    axesHandle1DPhase = subplot(2,1,2,'Parent', figureHandle);
    grid(axesHandle1DPhase, 'on')
    
    plotHandle1DAmp = plot(axesHandle1DAmp, x_range, nan(1,obj.Loop.one.steps));
    ylabel(axesHandle1DAmp, 'Amplitude');
    plotHandle1DPhase = plot(axesHandle1DPhase, x_range, nan(1,obj.Loop.one.steps));
    ylabel(axesHandle1DPhase, 'Phase');
else
    % fix Loop one size
    x_range = x_range(1:obj.nbrSequences);
    tmpAxes = subplot(2,3,1,'Parent', figureHandle);
    grid(tmpAxes, 'on')
    plotHandle1DAmp1 = plot(tmpAxes, x_range, nan(1,obj.nbrSequences));
    ylabel(tmpAxes, 'Amplitude');
    title(tmpAxes, 'Channel 1')
    
    tmpAxes = subplot(2,3,4,'Parent', figureHandle);
    grid(tmpAxes, 'on')
    plotHandle1DPhase1 = plot(tmpAxes, x_range, nan(1,obj.nbrSequences));
    ylabel(tmpAxes, 'Phase');
    
    tmpAxes = subplot(2,3,2,'Parent', figureHandle);
    grid(tmpAxes, 'on')
    plotHandle1DAmp2 = plot(tmpAxes, x_range, nan(1,obj.nbrSequences));
    ylabel(tmpAxes, 'Amplitude');
    title(tmpAxes, 'Channel 2')
    
    tmpAxes = subplot(2,3,5,'Parent', figureHandle);
    grid(tmpAxes, 'on')
    plotHandle1DPhase2 = plot(tmpAxes, x_range, nan(1,obj.nbrSequences));
    ylabel(tmpAxes, 'Phase');
    
    tmpAxes = subplot(2,3,3,'Parent', figureHandle);
    grid(tmpAxes, 'on')
    plotHandle1DAmp3 = plot(tmpAxes, x_range, nan(1,obj.nbrSequences));
    ylabel(tmpAxes, 'Amplitude');
    title(tmpAxes, 'Correlation Ch')
    
    tmpAxes = subplot(2,3,6,'Parent', figureHandle);
    grid(tmpAxes, 'on')
    plotHandle1DPhase3 = plot(tmpAxes, x_range, nan(1,obj.nbrSequences));
    ylabel(tmpAxes, 'Phase');
end

if obj.Loop.two.steps > 1
    axesHandle2DAmp = subplot(2,1,1,'Parent', figureHandle2D);
    axesHandle2DPhase = subplot(2,1,2,'Parent', figureHandle2D);
    ylabel(axesHandle2DPhase, 'Phase');
    if isfield(obj.Loop.two, 'plotRange')
        y_range = obj.Loop.two.plotRange;
    else
        y_range = 1:obj.Loop.two.sweep.points;
    end
    plotHandle2DAmp = imagesc(x_range, y_range, Amp2D, 'Parent', axesHandle2DAmp);
    ylabel(axesHandle2DAmp, 'Amplitude');
    plotHandle2DPhase = imagesc(x_range, y_range, Phase2D, 'Parent', axesHandle2DPhase);
    ylabel(axesHandle2DPhase, 'Phase');
end

for loop2_index = 1:obj.Loop.two.steps
    obj.Loop.two.sweep.step(loop2_index);
    fprintf('Loop 1: Step %d of %d\n', [loop2_index, obj.Loop.two.steps]);
    
    if ~SD_mode
        softAvgs = ExpParams.softAvgs;
        for avg_index = 1:softAvgs
            fprintf('Soft average %d\n', avg_index);

            % set the card to acquire
            obj.scope.acquire();

            % set the Tek to run and wait and wait and wait for it to go
            masterAWG.run();
            masterAWG.operationComplete();
            
            %Poll the digitizer until it has all the data
            success = obj.scope.wait_for_acquisition(120);
            if success ~= 0
                error('Failed to acquire waveform.')
            end

            % Then we retrieve our data
            Amp_I = obj.scope.transfer_waveform(1);
            Amp_Q = obj.scope.transfer_waveform(2);
            if numel(Amp_I) ~= numel(Amp_Q)
                error('I and Q outputs have different lengths.')
            end

            % signal processing and analysis
            if multiChMode
                [iavg, qavg, iqavg] = obj.processSignal(Amp_I, Amp_Q);
                
                 % update the averages
                if avg_index == 1
                    isoftAvg = iavg;
                    qsoftAvg = qavg;
                    iqsoftAvg = iqavg;
                else
                    isoftAvg = (isoftAvg .* (avg_index - 1) + iavg)./(avg_index);
                    qsoftAvg = (qsoftAvg .* (avg_index - 1) + qavg)./(avg_index);
                    iqsoftAvg = (iqsoftAvg .* (avg_index - 1) + iqavg)./(avg_index);
                end
                
                amp1 = abs(isoftAvg);
                amp2 = abs(qsoftAvg);
                amp12 = abs(iqsoftAvg);
                phase1 = 180/pi*angle(isoftAvg);
                phase2 = 180/pi*angle(qsoftAvg);
                phase12 = 180/pi*angle(iqsoftAvg);
                
                %update plots
                set(plotHandle1DAmp1, 'YData', amp1)
                set(plotHandle1DPhase1, 'YData', phase1)
                set(plotHandle1DAmp2, 'YData', amp2)
                set(plotHandle1DPhase2, 'YData', phase2)
                set(plotHandle1DAmp3, 'YData', amp12)
                set(plotHandle1DPhase3, 'YData', phase12)
            else
                %For the first soft average initialize, otherwise sum
                if avg_index == 1
                    isoftAvg = Amp_I;
                    qsoftAvg = Amp_Q;
                else
                    isoftAvg = (isoftAvg .* (avg_index - 1) + Amp_I)./(avg_index);
                    qsoftAvg = (qsoftAvg .* (avg_index - 1) + Amp_Q)./(avg_index);
                end
            
                [iavg, qavg] = obj.processSignal(isoftAvg, qsoftAvg);
                
                % convert I/Q to Amp/Phase
                amp = sqrt(iavg.^2 + qavg.^2);
                phase = (180.0/pi) * atan2(qavg, iavg);
                
                % Update the plots
                set(plotHandle1DAmp, 'YData', amp)
                set(plotHandle1DPhase, 'YData', phase)
            end
            
            if displayScope
                figure(scopeHandle);
                foo = subplot(2,1,1);
                imagesc(isoftAvg');
                xlabel('Time');
                ylabel('Segment');
                set(foo, 'YDir', 'normal');
                title('Ch 1 (I)');
                foo = subplot(2,1,2);
                imagesc(qsoftAvg');
                xlabel('Time');
                ylabel('Segment');
                set(foo, 'YDir', 'normal');
                title('Ch 2 (Q)');
            end

            masterAWG.stop();
            % restart the slave AWGs so we can resync
            for i = 2:length(obj.awg)
                awg = obj.awg{i};
                awg.stop();
                awg.run();
            end
            pause(0.2);
        end

        % write the data to file
        % in multiChMode, the data is in isoftAvg, otherwise it is in iavg,
        % etc...
        if ~multiChMode
            obj.DataFileHandler.write({iavg + 1i*qavg});
            
            %Store in the 2D array
            Amp2D(loop2_index,:) = amp;
            Phase2D(loop2_index,:) = phase;
            
            % display 2D data sets if there is a loop
            if obj.Loop.two.steps > 1
                set(plotHandle2DAmp, 'CData', Amp2D);
                set(plotHandle2DPhase, 'CData', Phase2D);
            end
        else
            obj.DataFileHandler.write({isoftAvg, qsoftAvg, iqsoftAvg});
        end
        
    else
        percentComplete = 100*(loop2_index-1 + (loop2_index)/obj.Loop.two.steps)/obj.Loop.one.steps;
        fprintf('%d\n',percentComplete);
    end
end

end
