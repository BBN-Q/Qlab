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
    QubitNum = str2double(ExpParams.Qubit(end:end));
    if ~obj.testMode
        obj.closeInstruments();
        optimize_mixers(QubitNum);
        obj.openInstruments();
        obj.initializeInstruments();
    end
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
   
   piAmpGuesses = zeros([3,1]);
   offsetPhases = zeros([3,1]);
   
   %Run a sequence and fit it
   data = obj.homodyneMeasurement(nbrSegments);
   [piAmpGuesses(1), offsetPhases(1)] = obj.analyzeRabiAmp(data);
   
   obj.pulseParams.piAmp = piAmpGuesses(1);
   obj.pulseParams.pi2Amp = obj.pulseParams.piAmp/2;
   fprintf('Initial guess for X180Amp: %.0f\n', obj.pulseParams.piAmp);
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
    x0 = [obj.pulseParams.pi2Amp, obj.pulseParams.i_offset];

    % options for Levenberg-Marquardt (seed small lambda to make it more
    % like Gauss-Newton)
    options = optimset('TolX', 5e-4, 'TolFun', 5e-2, 'Jacobian', 'on', 'Algorithm', {'levenberg-marquardt',1e-4}, 'ScaleProblem', 'Jacobian', 'Display', 'none');
    
    x0 = lsqnonlin(@obj.Xpi2ObjectiveFnc,x0,[],[],options);
    X90Amp = x0(1);
    i_offset = x0(2);
    fprintf('Found X90Amp: %.0f\n', X90Amp);
    fprintf('Found I offset: %.3f\n', i_offset);
    
    % calibrate amplitude and offset for +/- Y90
    x0(2) = obj.pulseParams.q_offset;
    
    x0 = lsqnonlin(@obj.Ypi2ObjectiveFnc,x0,[],[],options);
    Y90Amp = x0(1);
    q_offset = x0(2);
    Y90Amp = X90Amp;
    fprintf('Found Y90Amp: %.0f\n', Y90Amp);
    fprintf('Found Q offset: %.3f\n', q_offset);
    
    % update pulseParams
    obj.pulseParams.pi2Amp = Y90Amp;
    obj.pulseParams.i_offset = i_offset;
    obj.pulseParams.q_offset = q_offset;
    % update T matrix with ratio X90Amp/Y90Amp
    ampFactor = obj.pulseParams.T(1,1)*X90Amp/Y90Amp;
    fprintf('ampFactor: %.3f\n', ampFactor);
    theta = asec(obj.pulseParams.T(2,2));
    T = [ampFactor, -ampFactor*tan(theta); 0, sec(theta)];
    obj.pulseParams.T = T;
end

%% Pi Calibration
if ExpParams.DoPiCal
    % calibrate amplitude and offset for +/- X180
    x0 = [obj.pulseParams.piAmp, obj.pulseParams.i_offset];
    
    % options for Levenberg-Marquardt
    options = optimset('TolX', 5e-4, 'TolFun', 5e-2, 'Jacobian', 'on', 'Algorithm', {'levenberg-marquardt',1e-4}, 'ScaleProblem', 'Jacobian', 'Display', 'none');
    
    x0 = lsqnonlin(@obj.XpiObjectiveFnc,x0,[],[],options);
    X180Amp = x0(1);
    i_offset = x0(2);
    fprintf('Found X180Amp: %.0f\n', X180Amp);
    
    % update pulseParams
    obj.pulseParams.piAmp = X180Amp;
    obj.pulseParams.i_offset = i_offset;
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

% save updated parameters to file
load(obj.pulseParamPath, 'piAmps', 'pi2Amps', 'deltas', 'Ts');
piAmps(obj.ExpParams.Qubit)  = obj.pulseParams.piAmp;
pi2Amps(obj.ExpParams.Qubit) = obj.pulseParams.pi2Amp;
deltas(obj.ExpParams.Qubit)  = obj.pulseParams.delta;

IQchannels = obj.channelMap(obj.ExpParams.Qubit);
IQkey = [num2str(IQchannels{1}) num2str(IQchannels{2})];
Ts(IQkey) = obj.pulseParams.T;

save(obj.pulseParamPath, 'piAmps', 'pi2Amps', 'deltas', 'Ts', '-append', '-v7.3');
% TODO: save I/Q offsets

% for now, just display the results
obj.pulseParams

end

