function calibratePulses(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParent());
cfg_path = [path '/cfg/'];

cfg_name = [cfg_path 'common.cfg'];
if exist(cfg_name, 'file')
    commonSettings = parseParamFile(cfg_name);
else
    commonSettings = struct('InstrParams', struct());
end

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qubit;
ExpParams.DoMixerCal = 1;
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 0;
ExpParams.DoPi2Cal = 1;
ExpParams.DoPiCal = 0;
ExpParams.DoDRAGCal = 0;

cfg = struct('ExpParams', ExpParams, 'SoftwareDevelopmentMode', 1, 'InstrParams', commonSettings.InstrParams);
cfg_name = [cfg_path 'pulseCalibration.cfg'];
writeCfgFromStruct(cfg_name, cfg);

% create object instance
pulseCal = expManager.pulseCalibration(path, cfg_name, 'pulseCalibration', 1);

pulseCal.Init();
pulseCal.Do();
pulseCal.CleanUp();

end