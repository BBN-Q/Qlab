function SSData = single_shot_measurement(qubit, expName)

deviceName = 'IBM_v112037W3';
ExpParams.fileName = DataNamer.get_data_filename(deviceName, expName);

ExpParams.qubit = qubit;
ExpParams.dataSource = strcat('M',qubit(2),'Demod'); %'Ch1Raw'; %'M1Demod';
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 30000;
ExpParams.logisticRegression = false;
ExpParams.saveKernel = true;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = true;  

ExpParams.sweeps = struct();
%ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'BBNAPS4', 'channel', '3&4', 'mode', 'amp.', 'start', 0.1, 'stop', 0.8, 'step', 0.05);
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.351, 'stop', 6.355, 'step', 0.0002, 'instr', 'Autodyne_Mq3');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();
end