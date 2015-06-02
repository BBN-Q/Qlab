function SSData = single_shot_measurement(qubit, expName)

deviceName = 'IBM_v112037W3';
ExpParams.fileName = DataNamer.get_data_filename(deviceName, expName);

ExpParams.qubit = qubit;
ExpParams.dataSource = strcat('M',qubit(2),'Demod');
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 50000;
ExpParams.logisticRegression = false;
ExpParams.saveKernel = true;

%Whether to auto-enable only the relevant AWGs
ExpParams.autoSelectAWGs = true;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = true;

ExpParams.sweeps = struct();
ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'BBNAPS2', 'channel', '1&2', 'mode', 'amp.', 'start', 0.4, 'stop', 0.5, 'step', 0.02);
%ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'BBNAPS4', 'channel', '3&4', 'mode', 'amp.', 'start', 0.4, 'stop', 0.5, 'step', 0.02);
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.3531, 'stop', 6.3538, 'step', 0.0001, 'instr', 'Autodyne_Mq3');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();
end