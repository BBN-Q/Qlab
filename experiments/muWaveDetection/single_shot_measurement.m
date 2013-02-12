function single_shot_measurement(qubit)

ExpParams.qubit = qubit;
ExpParams.measurement = 'M1';
ExpParams.cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'scripter.json');
%Update some relevant parameters
channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
ExpParams.seqFile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-', channelMap.(qubit).awg, '.h5']);
ExpParams.numShots = 80000;

Sweeps = struct();
Sweeps.AWGChannel = struct('type', 'sweeps.AWGChannel', 'AWGName', 'BBNAPS2', 'channel', '3&4', 'mode', 'amp', 'start', 0.025, 'stop', 0.6, 'step', 0.025, 'number', 1);
% Sweeps.frequency = struct('type','sweeps.Frequency', 'start', 6.552, 'stop', 6.552, 'step', 50e-6, 'genID', 'RFgen', 'lockLOtoRF', false, 'number', 1);
% Sweeps.power = struct('type','sweeps.Power', 'start', -10, 'stop', 6, 'step', 0.5, 'units', 'dBm', 'genID', 'RFgen', 'number', 2);

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSMeasurement.Do();

end