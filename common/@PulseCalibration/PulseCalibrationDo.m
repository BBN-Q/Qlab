function PulseCalibrationDo(obj)
% Does the following:
% - find initial pulse amplitudes with a Rabi amplitude experiment
% - zeroes the detuning by measuring it with a Ramsey experiment
% - calibrates Pi/2 pulses with sequences of concatenated Pi/2's
% - calibrates Pi pulses with sequences of concatenated Pi's with an
%   initial Pi/2
% - calibrates DRAG parameter with an APE sequence
%
% v1.0 Aug 24, 2011 Blake Johnson

c = onCleanup(@() obj.cleanup());

settings = obj.settings;

%% MixerCal
if settings.DoMixerCal
    % TODO update parameter passing to optimize_mixers
    QubitNum = str2double(settings.Qubit(end:end));
    if ~obj.testMode
        obj.closeInstruments();
        optimize_mixers(QubitNum);
        obj.openInstruments();
        obj.initializeInstruments();
    end
    % update pulseParams (TODO: FIXME!)
    load(obj.mixerCalPath, 'i_offset', 'q_offset', 'T');
    obj.channelParams.T = T;
    obj.channelParams.i_offset = i_offset;
    obj.channelParams.q_offfset = q_offset;
end

%% Rabi
if settings.DoRabiAmp
   [filenames, segmentPoints] = obj.rabiAmpChannelSequence(settings.Qubit);
   if ~obj.testMode
       obj.loadSequence(filenames, 1);
   end
   
   piAmpGuesses = zeros([3,1]);
   offsetPhases = zeros([3,1]);
   
   %Run a sequence and fit it
   data = obj.homodyneMeasurement(segmentPoints);
   % analyze X data
   [piAmpGuesses(1), offsetPhases(1)] = obj.analyzeRabiAmp(data(1:end/2));
   % analyze Y data
   [piAmpGuesses(2), offsetPhases(2)] = obj.analyzeRabiAmp(data(end/2+1:end));
   %Arbitary extra division by two so that it doesn't push the offset too far. 
   amp2offset = 0.5/obj.settings.offset2amp;
   
   obj.channelParams.piAmp = piAmpGuesses(1);
   obj.channelParams.pi2Amp = obj.channelParams.piAmp/2;
   obj.channelParams.i_offset = obj.channelParams.i_offset + offsetPhases(1)*amp2offset;
   obj.channelParams.q_offset = obj.channelParams.q_offset + offsetPhases(2)*amp2offset;
   fprintf('Initial guess for X180Amp: %.0f\n', obj.channelParams.piAmp);
   fprintf('Shifting i_offset by: %.3f\n', offsetPhases(1)*amp2offset);
   fprintf('Shifting q_offset by: %.3f\n', offsetPhases(2)*amp2offset);
end

%% Ramsey
if settings.DoRamsey
    % generate Ramsey sequence (TODO)
    [filenames, segmentPoints] = obj.RamseyChannelSequence(settings.Qubit);
    obj.loadSequence(filenames, 1);
    
    %Approach is to take one point, move half-way there and then see if
    %frequency moves in desired direction
    qubitSource = obj.experiment.instruments.(obj.channelMap.(settings.Qubit).source);
    
    %Deliberately shift off by 1MHz
    origFreq = qubitSource.frequency;
    qubitSource.frequency = origFreq - 0.001;

    % measure
    data = obj.homodyneMeasurement(segmentPoints);

    quick_scale = @(d) 2*(d-mean(d))/(max(d)-min(d));
    
    % analyze
    [~, detuningA] = fitramsey(segmentPoints, quick_scale(data));

    % adjust drive frequency
    qubitSource.frequency = origFreq - 0.001 + detuningA/2;

    % measure
    data = obj.homodyneMeasurement(segmentPoints);

    % analyze
    [~, detuningB] = fitramsey(segmentPoints, quick_scale(data));
    
    %If we have gotten smaller we are moving in the right direction
    %Average the two fits
    if detuningB < detuningA
        qubitSource.frequency = origFreq - 0.001 + 0.5*(detuningA + detuningA/2+detuningB);
    else
        qubitSource.frequency = origFreq - 0.001 - 0.5*(detuningA - detuningA/2+detuningB);
    end
        
end

%% Pi/2 Calibration
if settings.DoPi2Cal
    % calibrate amplitude and offset for +/- X90
    x0 = [obj.channelParams.pi2Amp, obj.channelParams.i_offset];

    % options for Levenberg-Marquardt (seed small lambda to make it more
    % like Gauss-Newton)
    options = optimset('TolX', 2e-3, 'TolFun', 1e-4, 'MaxFunEvals', 5, 'OutputFcn', @obj.LMStoppingCondition, 'Jacobian', 'on', 'Algorithm', {'levenberg-marquardt',1e-4}, 'ScaleProblem', 'Jacobian', 'Display', 'none');
    
    x0 = lsqnonlin(@obj.Xpi2ObjectiveFnc,x0,[],[],options);
    X90Amp = real(x0(1));
    i_offset = real(x0(2));
    obj.channelParams.i_offset = i_offset;
    fprintf('Found X90Amp: %.4f\n', X90Amp);
    fprintf('Found I offset: %.4f\n\n\n', i_offset);
    
    % calibrate amplitude and offset for +/- Y90
    x0(2) = obj.channelParams.q_offset;
    
    x0 = lsqnonlin(@obj.Ypi2ObjectiveFnc,x0,[],[],options);
    Y90Amp = real(x0(1));
    q_offset = real(x0(2));
    fprintf('Found Y90Amp: %.4f\n', Y90Amp);
    fprintf('Found Q offset: %.4f\n\n\n', q_offset);
    
    % update channelParams
    obj.channelParams.pi2Amp = Y90Amp;
    obj.channelParams.q_offset = q_offset;
    % update T matrix with ratio X90Amp/Y90Amp
    obj.channelParams.ampFactor = obj.channelParams.ampFactor*X90Amp/Y90Amp;
    fprintf('ampFactor: %.3f\n', obj.channelParams.ampFactor);
    % update QGL library
    updateQubitPulseParams(obj.settings.Qubit, obj.channelParams);
end

%% Pi Calibration
if settings.DoPiCal
    % calibrate amplitude and offset for +/- X180
    x0 = [obj.channelParams.piAmp, obj.channelParams.i_offset];
    
    % options for Levenberg-Marquardt
    options = optimset('TolX', 2e-3, 'TolFun', 1e-4, 'MaxFunEvals', 5, 'OutputFcn', @obj.LMStoppingCondition, 'Jacobian', 'on', 'Algorithm', {'levenberg-marquardt',1e-4}, 'ScaleProblem', 'Jacobian', 'Display', 'none');
    
    x0 = lsqnonlin(@obj.XpiObjectiveFnc,x0,[],[],options);
    X180Amp = real(x0(1));
    i_offset = real(x0(2));
    fprintf('Found X180Amp: %.4f\n\n\n', X180Amp);
    
    % update channelParams
    obj.channelParams.piAmp = X180Amp;
    obj.channelParams.i_offset = i_offset;
    updateQubitPulseParams(obj.settings.Qubit, obj.channelParams);
end

%% DRAG calibration    
if settings.DoDRAGCal
    % generate DRAG calibration sequence
    if isfield(settings,'DRAGparams')
        deltas = settings.DRAGparams(:);
    else
        deltas = linspace(-2,0,11)';
    end
    [filenames, segmentPoints] = obj.APEChannelSequence(settings.Qubit, deltas);
    obj.loadSequence(filenames, 1);

    % measure
    data = obj.homodyneMeasurement(segmentPoints);

    % analyze for the best value to two digits
    numPsQId = 8; % number pseudoidentities
    
    obj.channelParams.dragScaling = round(100*obj.analyzeSlopes(data, numPsQId, deltas, obj.numShots))/100;
    
    title('DRAG Parameter Calibration');
    text(10, 0.8, sprintf('Found best DRAG parameter of %.2f', obj.channelParams.dragScaling), 'FontSize', 12);

    % update QGL library
    updateQubitPulseParams(obj.settings.Qubit, obj.channelParams);
end

%% SPAM calibration    
if settings.DoSPAMCal
    % generate DRAG calibration sequence
    [filenames, segmentPoints] = obj.SPAMChannelSequence(settings.Qubit);
    obj.loadSequence(filenames, 1);

    % measure
    data = obj.homodyneMeasurement(segmentPoints);
    
    % analyze for the best value to two digits
    numPsQId = 10; % number pseudoidentities
    angleShifts = (-3:0.75:3)';
    phaseSkew = round(100*obj.analyzeSlopes(data, numPsQId, angleShifts, obj.numShots))/100;
    title('SPAM Phase Skew Calibration');
    text(10, 0.8, sprintf('Found best phase Skew of %.2f', phaseSkew), 'FontSize', 12);

    obj.channelParams.phaseSkew = obj.channelParams.phaseSkew - phaseSkew;
end


%% Save updated parameters to file
updateAmpPhase(obj.channelParams.physChan, obj.channelParams.ampFactor, obj.channelParams.phaseSkew);
updateQubitPulseParams(obj.settings.Qubit, obj.channelParams);

% update i and q offsets in the instrument library
instrLib = json.read(getpref('qlab', 'InstrumentLibraryFile'));
iChan = str2double(obj.channelParams.physChan(end-1));
qChan = str2double(obj.channelParams.physChan(end));
instrLib.instrDict.(obj.controlAWG).channels(iChan).offset = round(1e4*obj.channelParams.i_offset)/1e4;
instrLib.instrDict.(obj.controlAWG).channels(qChan).offset = round(1e4*obj.channelParams.q_offset)/1e4;
%Drive frequency from Ramsey
if settings.DoRamsey
    channelLib = json.read(getpref('qlab','ChannelParamsFile'));
    sourceName = channelLib.channelDict.(mangledPhysChan).generator;
    instrLib.instrDict.(sourceName).frequency = qubitSource.frequency;
end

json.write(instrLib, getpref('qlab', 'InstrumentLibraryFile'), 'indent', 2);

% Display the final results
obj.channelParams

obj.finished = true;

end

