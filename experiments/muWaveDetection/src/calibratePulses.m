function calibratePulses(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qubit;
ExpParams.DoMixerCal = 0;
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 0;
ExpParams.DoPi2Cal = 1;
ExpParams.DoPiCal = 1;
ExpParams.DoDRAGCal = 1;
ExpParams.DRAGparams = linspace(-1,1,11);
ExpParams.DoSPAMCal = 1;
ExpParams.OffsetNorm = 6;
ExpParams.offset2amp = 8192/2; % divisor should be the max output voltage of the AWG
ExpParams.dataType = 'amp'; %or 'phase';

%ExpParams.cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json');
ExpParams.cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'scripter.json');
ExpParams.SoftwareDevelopmentMode = 0;

% create object instance
pulseCal = PulseCalibration();

pulseCal.Init(ExpParams);
pulseCal.Do();

end