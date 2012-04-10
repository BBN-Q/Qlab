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

cfg = struct('ExpParams', ExpParams, ...
    'SoftwareDevelopmentMode', 0, ...
    'displayScope', 0, ...
    'InstrParams', commonSettings.InstrParams);

writeCfgFromStruct(fullfile(cfg_path, 'singleShotFidelity.cfg'), cfg);

% create object instance
SSMeasurement = expManager.singleShotFidelity(path, fullfile(cfg_path, 'singleShotFidelity.cfg'), 'singleShotFidelity', 1);

SSMeasurement.Init();
SSMeasurement.Do();
SSMeasurement.CleanUp();

end