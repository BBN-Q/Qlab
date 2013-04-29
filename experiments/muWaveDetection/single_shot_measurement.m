function SSData = single_shot_measurement(qubit, expName)

global dataNamer
deviceName = 'IBMV5_mod2';
if ~isa(dataNamer, 'DataNamer')
    dataNamer = DataNamer(getpref('qlab', 'dataDir'), deviceName);
end
if ~strcmp(dataNamer.deviceName, deviceName)
    dataNamer.deviceName = deviceName;
    reset(dataNamer);
end
ExpParams.fileName = dataNamer.get_name(expName);
ExpParams.qubit = qubit;
ExpParams.measurement = 'M1';
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 40000;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = true;

ExpParams.sweeps = struct();
ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'BBNAPS1', 'channel', '3&4', 'mode', 'amp', 'start', 0.125, 'stop', 0.5, 'step', 0.025);
ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.958, 'stop', 6.962, 'step', 200e-6, 'instr', 'Source5');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();

end