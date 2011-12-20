function [errorMsg] = pulseCalibrationDo(obj)
% USAGE: [errorMsg] = pulseCalibrationDo(obj)
%
% Does the following:
% - find initial pulse amplitudes with a Rabi amplitude experiment
% - zeroes the detuning by measuring it with a Ramsey experiment
% - calibrates Pi/2 pulses with sequences of concatenated Pi/2's
% - calibrates Pi pulses with sequences of concatenated Pi's with an
%   initial Pi/2
% - calibrates DRAG parameter with an APE sequence
%
% v1.0 Aug 24, 2011 Blake Johnson

ExpParams = obj.ExpParams;

%% MixerCal
if ExpParams.DoMixerCal
    % TODO update parameter passing to optimize_mixers
    QubitNum = double(ExpParams.Qubit(end-1:end));
    optimize_mixers(QubitNum);
    % update pulseParams
    load(obj.mixerCalPath, 'i_offset', 'q_offset', 'T');
    obj.pulseParams.T = T;
    obj.pulseParams.i_offset = i_offset;
    obj.pulseParams.q_offfset = q_offset;
end

%% Rabi
if ExpParams.DoRabiAmp
   [filenames, nbrSegments] = obj.rabiAmpChannelSequence(ExpParams.Qubit);
   if ~obj.testMode
       obj.loadSequence(filenames);
   end
   
   data = obj.homodyneMeasurement(nbrSegments);
   obj.pulseParams.piAmp = obj.analyzeRabiAmp(data);
   obj.pulseParams.pi2Amp = obj.pulseParams.piAmp/2;
end

%% Ramsey
if ExpParams.DoRamsey
    % generate Ramsey sequence (TODO)
    [filenames, nbrSegments] = obj.RamseyChannelSequence(ExpParams.Qubit);
    obj.loadSequence(filename);
    
    % adjust drive frequency
    freq = QubitSpec.frequency + ExpParams.RamseyDetuning;
    QubitSpec = obj.Instr.(ExpParams.QubitSpec);
    QubitSpec.frequency = freq;

    % measure
    data = obj.homodyneMeasurement(nbrSegments);

    % analyze
    detuning = obj.analyzeRamsey(data);

    % adjust drive frequency
    freq = QubitSpec.frequency - detuning;
    QubitSpec.frequency = freq;
end

%% Pi/2 Calibration
if ExpParams.DoPi2Cal
    % calibrate amplitude and offset for +/- X90
    % Todo: test and adjust these parameters
    options = optimset('TolX', 1e-2, 'TolFun', 1e-3, 'MaxIter', 40, 'Display', 'iter');
    x0 = [obj.pulseParams.pi2Amp, obj.pulseParams.i_offset];
    lowerBound = [0.5*x0(1), max(x0(2)-0.05, -0.5)];
    upperBound = [min(1.5*x0(1), 8192), min(x0(2)+0.05, 0.5)];
    
    x0 = fminsearchbnd(@obj.Xpi2ObjectiveFnc, x0, lowerBound, upperBound, options);
    X90Amp = x0(1);
    i_offset = x0(2);
    fprintf('Found X90Amp: %.0f\n', X90Amp);
    fprintf('Found I offset: %.3f\n', i_offset);
    
    % calibrate amplitude and offset for +/- Y90
    x0(2) = obj.pulseParams.q_offset;
    lowerBound = [0.5*x0(1), max(x0(2)-0.05, -0.5)];
    upperBound = [min(1.5*x0(1), 8192), min(x0(2)+0.05, 0.5)];
    
    x0 = fminsearchbnd(@obj.Ypi2ObjectiveFnc, x0, lowerBound, upperBound, options);
    Y90Amp = x0(1);
    q_offset = x0(2);
    fprintf('Found Y90Amp: %.0f\n', Y90Amp);
    fprintf('Found Q offset: %.3f\n', q_offset);
    
    % update pulseParams
    obj.pulseParams.pi2Amp = Y90Amp;
    obj.pulseParams.i_offset = i_offset;
    obj.pulseParams.q_offset = q_offset;
    % update T matrix with ratio X90Amp/Y90Amp
    ampFactor = X90Amp/Y90Amp;
    theta = atand(obj.pulseParams.T(2,2));
    T = [ampFactor, -ampFactor*tand(theta); 0, secd(theta)]; % check this
    obj.pulseParams.T = T;
end

%% Pi Calibration
if ExpParams.DoPiCal
    % calibrate amplitude and offset for +/- X180
    % Todo: test and adjust these parameters
    options = optimset('TolX', 1e-2, 'TolFun', 1e-3, 'MaxIter', 40, 'Display', 'iter');
    x0 = [obj.pulseParams.piAmp, obj.pulseParams.i_offset];
    lowerBound = [0.5*x0(1), max(x0(2)-0.05, -0.5)];
    upperBound = [min(1.5*x0(1), 8192), min(x0(2)+0.05, 0.5)];
    
    x0 = fminsearchbnd(@obj.XpiObjectiveFnc, x0, lowerBound, upperBound, options);
    X180Amp = x0(1);
    i_offset = x0(2);
    fprintf('Found X180Amp: %.0f\n', X180Amp);
    fprintf('Found I offset: %.3f\n', i_offset);
    
    % calibrate amplitude and offset for +/- Y180
    x0(2) = obj.pulseParams.q_offset;
    lowerBound = [0.5*x0(1), max(x0(2)-0.05, -0.5)];
    upperBound = [min(1.5*x0(1), 8192), min(x0(2)+0.05, 0.5)];
    
    x0 = fminsearchbnd(@obj.YpiObjectiveFnc, x0, lowerBound, upperBound, options);
    Y180Amp = x0(1);
    q_offset = x0(2);
    fprintf('Found Y180Amp: %.0f\n', Y180Amp);
    fprintf('Found Q offset: %.3f\n', q_offset);
    
    % update pulseParams
    obj.pulseParams.piAmp = Y180Amp;
    obj.pulseParams.i_offset = i_offset;
    obj.pulseParams.q_offset = q_offset;
    % update T matrix with ratio X180Amp/Y180Amp
    ampFactor = X180Amp/Y180Amp;
    theta = atand(obj.pulseParams.T(2,2));
    T = [ampFactor, -ampFactor*tand(theta); 0, secd(theta)]; % check this
    obj.pulseParams.T = T;
end

%% DRAG calibration    
if ExpParams.DoDRAGCal
    % generate DRAG calibration sequence
    [filenames, nbrSegments] = obj.DRAGSequence(ExpParams.Qubit);
    obj.loadSequence(filenames);

    % measure
    data = obj.homodyneMeasurement(nbrSegments);
    % analyze
    obj.pulseParams.delta = obj.analyzeDRAG(data);
end

% TODO: save updated parameters to file

end

