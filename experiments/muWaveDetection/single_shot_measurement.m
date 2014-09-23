function SSData = single_shot_measurement(qubit, expName)

deviceName = 'IBM_v7_a2';
ExpParams.fileName = DataNamer.get_data_filename(deviceName, expName);

ExpParams.qubit = qubit;
ExpParams.measurement = 'M1_demod';
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 10000;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = false;

ExpParams.sweeps = struct();
% ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'BBNAPS2', 'channel', '1&2', 'mode', 'amp.', 'start', 0.1, 'stop', 0.7, 'step', 0.025);
% ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.573, 'stop', 6.577, 'step', 0.0001, 'instr', 'Autodyne1');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();
end