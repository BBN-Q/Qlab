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
commonSettings.InstrParams.TekAWG.seqfile = 'U:\AWG\SingleShot\SingleShotTekAWG12.awg';
commonSettings.InstrParams.TekAWG.seqforce = 1;
commonSettings.InstrParams.scope.averager.nbrSegments = 8000;
commonSettings.InstrParams.scope.averager.nbrRoundRobins = 1;

% construct minimal cfg file
ExpParams = struct();
ExpParams.softAvgs = 10;
ExpParams.digitalHomodyne = commonSettings.ExpParams.digitalHomodyne;
ExpParams.filter = commonSettings.ExpParams.filter;

Sweeps = struct();
Sweeps.frequency = struct('type','sweeps.Frequency', 'start', 8.18715, 'stop', 8.18715, 'step', 50e-6, 'genID', 'RFgen', 'number', 1);
Sweeps.power = struct('type','sweeps.Power', 'start', 6, 'stop', 6, 'step', 0.5, 'units', 'dBm', 'genID', 'RFgen', 'number', 2);

cfg = struct('ExpParams', ExpParams, ...
    'SoftwareDevelopmentMode', 0, ...
    'displayScope', 0, ...
    'InstrParams', commonSettings.InstrParams, ...
    'SweepParams', Sweeps);

writeCfgFromStruct(fullfile(cfg_path, 'singleShotFidelity.cfg'), cfg);

% create object instance
SSMeasurement = expManager.singleShotFidelity(path, fullfile(cfg_path, 'singleShotFidelity.cfg'), 'singleShotFidelity', 1);

SSMeasurement.Init();
SSMeasurement.Do();
SSMeasurement.CleanUp();

end