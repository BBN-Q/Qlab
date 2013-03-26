function calibratePulses(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qubit;
ExpParams.measurement = 'M1';
ExpParams.DoMixerCal = 0;
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 1;
ExpParams.DoPi2Cal = 0;
ExpParams.DoPiCal = 0;
ExpParams.DoDRAGCal = 0;
ExpParams.DRAGparams = linspace(-1,1,11);
ExpParams.DoSPAMCal = 0;
ExpParams.OffsetNorm = 6;
ExpParams.offset2amp = 8192/1; % divisor should be the max output voltage of the AWG
ExpParams.dataType = 'phase'; %or 'phase';

%ExpParams.cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json');
ExpParams.cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'scripter.json');
ExpParams.SoftwareDevelopmentMode = 0;

% create object instance
pulseCal = PulseCalibration();

pulseCal.Init(ExpParams);
pulseCal.Do();

end