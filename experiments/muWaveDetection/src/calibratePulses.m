function calibratePulses(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParent());
cfg_path = [path '/cfg/'];

cfg_name = [cfg_path 'TimeDomain.cfg'];
if exist(cfg_name, 'file')
    commonSettings = parseParamFile(cfg_name);
else
    commonSettings = struct('InstrParams', struct());
end

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qubit;
ExpParams.DoMixerCal = 0;
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 0;
ExpParams.DoPi2Cal = 1;
ExpParams.DoPiCal = 1;
ExpParams.DoDRAGCal = 0;
ExpParams.digitalHomodyne = commonSettings.ExpParams.digitalHomodyne;
ExpParams.filter = commonSettings.ExpParams.filter;
ExpParams.softAvgs = 3;

cfg = struct('ExpParams', ExpParams, ...
    'SoftwareDevelopmentMode', 0, ...
    'displayScope', 0, ...
    'InstrParams', commonSettings.InstrParams);

cfg_name = [cfg_path 'pulseCalibration.cfg'];
writeCfgFromStruct(cfg_name, cfg);

% create object instance
pulseCal = expManager.pulseCalibration(path, cfg_name, 'pulseCalibration', 1);

pulseCal.Init();
pulseCal.Do();
pulseCal.CleanUp();

end