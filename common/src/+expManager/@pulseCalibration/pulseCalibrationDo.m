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
   % analyze X data
   [piAmpGuesses(1), offsetPhases(1)] = obj.analyzeRabiAmp(data(1:end/2));
   % analyze Y data
   [piAmpGuesses(2), offsetPhases(2)] = obj.analyzeRabiAmp(data(end/2+1:end));
   %Arbitary extra division by two so that it doesn't push the offset too far. 
   amp2offset = 2.0/8192/obj.ExpParams.OffsetNorm/2;
   
   obj.pulseParams.piAmp = piAmpGuesses(1);
   obj.pulseParams.pi2Amp = obj.pulseParams.piAmp/2;
   obj.pulseParams.i_offset = obj.pulseParams.i_offset + offsetPhases(1)*amp2offset;
   obj.pulseParams.q_offset = obj.pulseParams.q_offset + offsetPhases(2)*amp2offset;
   fprintf('Initial guess for X180Amp: %.0f\n', obj.pulseParams.piAmp);
   fprintf('Shifting i_offset by: %.3f\n', offsetPhases(1)*amp2offset);
   fprintf('Shifting q_offset by: %.3f\n', offsetPhases(2)*amp2offset);
end

%% Ramsey
if ExpParams.DoRamsey
    % generate Ramsey sequence (TODO)
    [filenames, nbrSegments] = obj.RamseyChannelSequence(ExpParams.Qubit);
    obj.loadSequence(filenames);
    
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
    options = optimset('TolX', 2e-3, 'TolFun', 1e-4, 'MaxFunEvals', 5, 'OutputFcn', @obj.LMStoppingCondition, 'Jacobian', 'on', 'Algorithm', {'levenberg-marquardt',1e-4}, 'ScaleProblem', 'Jacobian', 'Display', 'none');
    
    x0 = lsqnonlin(@obj.Xpi2ObjectiveFnc,x0,[],[],options);
    X90Amp = real(x0(1));
    i_offset = real(x0(2));
    obj.pulseParams.i_offset = i_offset;
    fprintf('Found X90Amp: %.0f\n', X90Amp);
    fprintf('Found I offset: %.3f\n\n\n', i_offset);
    
    % calibrate amplitude and offset for +/- Y90
    x0(2) = obj.pulseParams.q_offset;
    
    x0 = lsqnonlin(@obj.Ypi2ObjectiveFnc,x0,[],[],options);
    Y90Amp = real(x0(1));
    q_offset = real(x0(2));
    fprintf('Found Y90Amp: %.0f\n', Y90Amp);
    fprintf('Found Q offset: %.3f\n\n\n', q_offset);
    
    % update pulseParams
    obj.pulseParams.pi2Amp = Y90Amp;
    obj.pulseParams.q_offset = q_offset;
    % update T matrix with ratio X90Amp/Y90Amp
    ampFactor = obj.pulseParams.T(1,1)*X90Amp/Y90Amp;
    fprintf('ampFactor: %.3f\n', ampFactor);
    theta = sign(obj.pulseParams.T(1,2))*asec(obj.pulseParams.T(2,2));
    T = [ampFactor, ampFactor*tan(theta); 0, sec(theta)];
    obj.pulseParams.T = T;
end

%% Pi Calibration
if ExpParams.DoPiCal
    % calibrate amplitude and offset for +/- X180
    x0 = [obj.pulseParams.piAmp, obj.pulseParams.i_offset];
    
    % options for Levenberg-Marquardt
    options = optimset('TolX', 1e-3, 'TolFun', 1e-4, 'MaxFunEvals', 5, 'OutputFcn', @obj.LMStoppingCondition, 'Jacobian', 'on', 'Algorithm', {'levenberg-marquardt',1e-4}, 'ScaleProblem', 'Jacobian', 'Display', 'none');
    
    x0 = lsqnonlin(@obj.XpiObjectiveFnc,x0,[],[],options);
    X180Amp = real(x0(1));
    i_offset = real(x0(2));
    fprintf('Found X180Amp: %.0f\n\n\n', X180Amp);
    
    % update pulseParams
    obj.pulseParams.piAmp = X180Amp;
    obj.pulseParams.i_offset = i_offset;
end

%% DRAG calibration    
if ExpParams.DoDRAGCal
    % generate DRAG calibration sequence
    if isfield(ExpParams,'DRAGparams')
        deltas = ExpParams.DRAGparams(:);
    else
        deltas = linspace(-2,0,11)';
    end
    [filenames, nbrSegments] = obj.APEChannelSequence(ExpParams.Qubit, deltas);
    obj.loadSequence(filenames);

    % measure
    data = obj.homodyneMeasurement(nbrSegments);

    % analyze for the best value to two digits
    numPsQId = 8; % number pseudoidentities
    
    obj.pulseParams.delta = round(100*obj.analyzeSlopes(data, numPsQId, deltas))/100;
    
    title('DRAG Parameter Calibration');
    text(10, 0.8, sprintf('Found best DRAG parameter of %.2f', obj.pulseParams.delta), 'FontSize', 12);

    
end

%% SPAM calibration    
if ExpParams.DoSPAMCal
    % generate DRAG calibration sequence
    [filenames, nbrSegments] = obj.SPAMChannelSequence(ExpParams.Qubit);
    obj.loadSequence(filenames);

    % measure
    data = obj.homodyneMeasurement(nbrSegments);
    
    % analyze for the best value to two digits
    numPsQId = 10; % number pseudoidentities
    angleShifts = (-2:0.5:2)';
    phaseSkew = round(100*obj.analyzeSlopes(data, numPsQId, angleShifts))/100;
    title('SPAM Phase Skew Calibration');
    text(10, 0.8, sprintf('Found best phase Skew of %.2f', phaseSkew), 'FontSize', 12);
    
    tmpT = obj.pulseParams.T;
    ampFactor = tmpT(1,1);
    curSkew = atand(tmpT(1,2)/tmpT(1,1));
    curSkew = curSkew - phaseSkew;
    obj.pulseParams.T = [ampFactor, ampFactor*tand(curSkew); 0, secd(curSkew)];
end



%% Save updated parameters to file

%First the pulse parameters
% Load the previous parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));

% Update the relevant variables
params.(ExpParams.Qubit).piAmp = obj.pulseParams.piAmp;
params.(ExpParams.Qubit).pi2Amp = obj.pulseParams.pi2Amp;
params.(ExpParams.Qubit).delta = obj.pulseParams.delta;

channelMap = obj.channelMap.(obj.ExpParams.Qubit);
IQkey = channelMap.IQkey;

params.(IQkey).T = obj.pulseParams.T;

FID = fopen(getpref('qlab', 'pulseParamsBundleFile'),'wt'); %open in text mode
fprintf(FID, jsonlab.savejson('',params));
fclose(FID);

%Now the offsets
params = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json'));
params.InstrParams.(channelMap.instr).(sprintf('chan_%d', channelMap.i)).offset = obj.pulseParams.i_offset;
params.InstrParams.(channelMap.instr).(sprintf('chan_%d', channelMap.q)).offset = obj.pulseParams.q_offset;
FID = fopen(fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json'),'wt'); %open in text mode
fprintf(FID, jsonlab.savejson('',params));
fclose(FID);


% Display the final results
obj.pulseParams

end

