function single_shot_measurement(qubit)

ExpParams.qubit = qubit;
ExpParams.measurement = 'M1';
ExpParams.cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'scripter.json');
%Update some relevant parameters
channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
ExpParams.seqFile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-', channelMap.(qubit).awg, '.h5']);
ExpParams.numShots = 20000;

ExpParams.sweeps = struct();
% Sweeps.AWGChannel = struct('type', 'AWGChannel', 'AWGName', 'BBNAPS2', 'channel', '3&4', 'mode', 'amp', 'start', 0.025, 'stop', 0.6, 'step', 0.025);
ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.8317, 'stop', 6.8320, 'step', 50e-6, 'genID', 'Source1');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSMeasurement.Do();

end