function SSData = single_shot_measurement(qubit)

ExpParams.qubit = qubit;
ExpParams.measurement = 'M3';
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 40000;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = false;

ExpParams.sweeps = struct();
%ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'AWGName', 'BBNAPS1', 'channel', '3&4', 'mode', 'amp', 'start', 0.0, 'stop', 1, 'step', 0.02);
% ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.8317, 'stop', 6.8320, 'step', 50e-6, 'genID', 'Source1');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();

end