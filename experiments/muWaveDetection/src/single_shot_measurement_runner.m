function single_shot_measurement_runner(qubit1, qubit2)

if ~exist('qubit1', 'var')
    qubit1 = 'q1';
end

path = fileparts(mfilename('fullpath'));
cfgPath = getpref('qlab', 'cfgDir');
cfg_name = fullfile(cfgPath, 'TimeDomain.json');
if exist(cfg_name, 'file')
    commonSettings = jsonlab.loadjson(cfg_name);
else
    commonSettings = struct('InstrParams', struct());
end

%Update some relevant parameters
channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
if ~exist('qubit2','var')
    commonSettings.InstrParams.(channelMap.(qubit1).awg).seqfile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-', channelMap.(qubit1).awg, '.h5']);
else
    error('TODO: Make work!')
    commonSettings.InstrParams.(channelMap.(qubit1).awg).seqfile = ['U:\AWG\SingleShot\SingleShot.h5'];
end    
commonSettings.InstrParams.TekAWG.seqforce = 1;
commonSettings.InstrParams.scope.averager.nbrSegments = 8000;
commonSettings.InstrParams.scope.averager.nbrRoundRobins = 1;

% construct minimal cfg file
ExpParams = struct();
ExpParams.softAvgs = 5;
ExpParams.digitalHomodyne = commonSettings.ExpParams.digitalHomodyne;
ExpParams.filter = commonSettings.ExpParams.filter;

% Sweeps = struct();
Sweeps.AWGChannel = struct('type', 'sweeps.AWGChannel', 'AWGName', 'BBNAPS2', 'channel', '3&4', 'mode', 'amp', 'start', 0.025, 'stop', 0.6, 'step', 0.025, 'number', 1);
% Sweeps.frequency = struct('type','sweeps.Frequency', 'start', 6.552, 'stop', 6.552, 'step', 50e-6, 'genID', 'RFgen', 'lockLOtoRF', false, 'number', 1);
% Sweeps.power = struct('type','sweeps.Power', 'start', -10, 'stop', 6, 'step', 0.5, 'units', 'dBm', 'genID', 'RFgen', 'number', 2);

cfg = struct('ExpParams', ExpParams, ...
    'SoftwareDevelopmentMode', 0, ...
    'displayScope', 0, ...
    'InstrParams', commonSettings.InstrParams, ...
    'SweepParams', Sweeps);

writeCfgFromStruct(fullfile(cfgPath, 'singleShotFidelity.json'), cfg);

% create object instance
if ~exist('qubit2','var')
    SSMeasurement = expManager.singleShotFidelity(path, fullfile(cfgPath, 'singleShotFidelity.json'), 'singleShotFidelity', 1);
    SSMeasurement.qubit = qubit1;
else
    SSMeasurement = expManager.singleShotFidelityMultiQ(path, fullfile(cfgPath, 'singleShotFidelity.cfg'), 'singleShotFidelity', 1);
    SSMeasurement.qubit1 = qubit1;
    SSMeasurement.qubit2 = qubit2;
end    
SSMeasurement.Init();
SSMeasurement.Do();
SSMeasurement.CleanUp();

end