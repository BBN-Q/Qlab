function single_shot_measurement_runner(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

path = fileparts(mfilename('fullpath'));
cfg_path = [path '/../cfg/'];

cfg_name = fullfile(cfg_path, 'TimeDomain.cfg');
if exist(cfg_name, 'file')
    commonSettings = parseParamFile(cfg_name);
else
    commonSettings = struct('InstrParams', struct());
end

%Update some relevant parameters
channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
commonSettings.InstrParams.TekAWG.seqfile = ['U:\AWG\SingleShot\SingleShot', channelMap.(qubit).IQkey, '.awg'];
commonSettings.InstrParams.TekAWG.seqforce = 1;
commonSettings.InstrParams.scope.averager.nbrSegments = 4000;
commonSettings.InstrParams.scope.averager.nbrRoundRobins = 1;

% construct minimal cfg file
ExpParams = struct();
ExpParams.softAvgs = 5;
ExpParams.digitalHomodyne = commonSettings.ExpParams.digitalHomodyne;
ExpParams.filter = commonSettings.ExpParams.filter;

Sweeps = struct();
Sweeps.frequency = struct('type','sweeps.Frequency', 'start', 8.331, 'stop', 8.3335, 'step', 50e-6, 'genID', 'RFgen', 'number', 1);
Sweeps.power = struct('type','sweeps.Power', 'start', 0, 'stop', 0, 'step', 1, 'units', 'dBm', 'genID', 'RFgen', 'number', 2);

cfg = struct('ExpParams', ExpParams, ...
    'SoftwareDevelopmentMode', 0, ...
    'displayScope', 0, ...
    'InstrParams', commonSettings.InstrParams, ...
    'SweepParams', Sweeps);

writeCfgFromStruct(fullfile(cfg_path, 'singleShotFidelity.cfg'), cfg);

% create object instance
SSMeasurement = expManager.singleShotFidelity(path, fullfile(cfg_path, 'singleShotFidelity.cfg'), 'singleShotFidelity', 1);
SSMeasurement.qubit = qubit;
SSMeasurement.Init();
SSMeasurement.Do();
SSMeasurement.CleanUp();

end