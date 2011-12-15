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

ExpParams = obj.inputStructure.ExpParams;
InstrParams = obj.inputStructure.InstrParams;
QubitSpec = obj.Instr.(ExpParams.QubitSpec);
QubitNumStr = ExpParams.Qubit(end-1:end);

% load pulse parameters for the relevant qubit
load(obj.pulseParamPath, ['piAmp' QubitNumStr], ['pi2Amp' QubitNumStr], ['delta' QubitNumStr], ['T' QubitNumStr]);
piAmp  = eval(['piAmp' QubitNumStr]);
pi2Amp = eval(['pi2Amp' QubitNumStr]);
delta  = eval(['delta' QubitNumSTr]);
T      = eval(['T' QubitNumStr]);

obj.pulseParams = struct('piAmp', piAmp, 'pi2Amp', pi2Amp, 'delta', delta, 'T', T, 'pulseType', 'drag',...
    'i_offset', 0, 'q_offset', 0);

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
    
    % update channel offsets
    IQchannels = obj.channelMap(qubit);
    Instr.awg.(['chan_' num2str(IQchannels(1))]).offset = i_offset;
    Instr.awg.(['chan_' num2str(IQchannels(2))]).offset = q_offset;
end

%% Rabi
if ExpParams.DoRabiAmp
   filename = obj.rabiAmpChannelSequence(ExpParams.Qubit);
   obj.loadSequence(filename);
   
   obj.homodyneDetection2DDo();
   obj.pulseParams.piAmp = obj.analyzeRabiAmp();
   obj.pulseParams.pi2Amp = obj.pulseParams.piAmp/2;
end

%% Ramsey
if ExpParams.DoRamsey
    % generate Ramsey sequence (TODO)
    filename = obj.RamseyChannelSequence(ExpParams.Qubit);
    obj.loadSequence(filename);
    
    % adjust drive frequency
    freq = QubitSpec.frequency + ExpParams.RamseyDetuning;
    QubitSpec.frequency = freq;

    % measure
    obj.homodyneDetection2DDo();

    % analyze
    detuning = obj.analyzeRamsey();

    % adjust drive frequency
    freq = QubitSpec.frequency - detuning;
    QubitSpec.frequency = freq;
end

%% Pi/2 Calibration
if ExpParams.DoPi2Cal
    % calibrate amplitude and offset for +/- X90
    % Todo: test and adjust these parameters
    options = optimset('TolX', 1e-3, 'TolFun', 1e-2, 'MaxIter', 20, 'Display', 'iter');
    x0 = [obj.pulseParams.pi2Amp, obj.pulseParams.i_offset];
    lowerBound = [0.5*x0(1) -1];
    upperBound = [1.5*x0(1) +1];
    
    [X90Amp, i_offset] = fminsearchbnd(@obj.Xpi2ObjectiveFnc, x0, lowerBound, upperBound, options);
    
    % calibrate amplitude and offset for +/- Y90
    % assume a tighter search range for Y since we have already calibrated X
    x0(1) = [X90Amp, obj.pulseParams.q_offset];
    lowerBound = [0.75*x0(1) -1];
    upperBound = [1.25*x0(1) +1];
    
    [Y90Amp, q_offset] = fminsearchbnd(@obj.Ypi2ObjectiveFnc, x0, lowerBound, upperBound, options);
    
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
    options = optimset('TolX', 1e-3, 'TolFun', 1e-2, 'MaxIter', 20, 'Display', 'iter');
    x0 = [obj.pulseParams.pi2Amp, obj.pulseParams.i_offset];
    lowerBound = [0.5*x0(1) -1];
    upperBound = [1.5*x0(1) +1];
    
    [X180Amp, i_offset] = fminsearchbnd(@obj.XpiObjectiveFnc, x0, lowerBound, upperBound, options);
    
    % calibrate amplitude and offset for +/- Y180
    % assume a tighter search range for Y since we have already calibrated X
    x0(1) = [X90Amp, obj.pulseParams.q_offset];
    lowerBound = [0.75*x0(1) -1];
    upperBound = [1.25*x0(1) +1];
    
    [Y180Amp, q_offset] = fminsearchbnd(@obj.YpiObjectiveFnc, x0, lowerBound, upperBound, options);
    
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
    for loop_index = 1:Loop.DRAGCal.steps
        % generate DRAG calibration sequence
        filename = obj.DRAGSequence(ExpParams.Qubit);
        obj.loadSequence(filename);

        % measure
        obj.homodyneDetection2DDo();
    end
    % analyze
    obj.pulseParams.delta = obj.analyzeDRAG();
end

% TODO: save updated parameters to file

end

