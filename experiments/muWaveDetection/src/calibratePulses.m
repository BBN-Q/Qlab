function calibratePulses(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

srcPath = fileparts(mfilename('fullpath'));
cfgPath = getpref('qlab', 'cfgDir');

cfg_name = fullfile(cfgPath, 'TimeDomain.json');
if exist(cfg_name, 'file')
    commonSettings = jsonlab.loadjson(cfg_name);
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
ExpParams.DRAGparams = linspace(-1,1,11);
ExpParams.DoSPAMCal = 0;
ExpParams.OffsetNorm = 6;
ExpParams.offset2amp = 8192/2; % divisor should be the max output voltage of the AWG
ExpParams.digitalHomodyne = commonSettings.ExpParams.digitalHomodyne;
ExpParams.filter = commonSettings.ExpParams.filter;
ExpParams.softAvgs = 5;
ExpParams.dataType = 'amp'; %or 'phase';
ExpParams.SSBFreq = -100e6;

% force AWGs to use a simple sequence file
if isfield(commonSettings.InstrParams, 'TekAWG')
    commonSettings.InstrParams.TekAWG.seqfile = 'U:\AWG\Trigger\Trigger.awg';
end
if isfield(commonSettings.InstrParams, 'BBNAPS')
    commonSettings.InstrParams.BBNAPS.seqfile = 'U:\APS\Trigger\Trigger.h5';
end

cfg = struct('ExpParams', ExpParams, ...
    'SoftwareDevelopmentMode', 0, ...
    'displayScope', 0, ...
    'InstrParams', commonSettings.InstrParams);

cfg_name = fullfile(cfgPath, 'pulseCalibration.json');
writeCfgFromStruct(cfg_name, cfg);

% create object instance
pulseCal = expManager.pulseCalibration(srcPath, cfg_name, 'pulseCalibration', 1);

pulseCal.Init();
pulseCal.Do();

end