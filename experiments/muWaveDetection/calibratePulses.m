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
ExpParams.DoRamsey = 0;
ExpParams.DoPi2Cal = 1;
ExpParams.DoPiCal = 1;
ExpParams.DoDRAGCal = 1;
ExpParams.DRAGparams = linspace(0,2,11);
ExpParams.DoSPAMCal = 1;
ExpParams.OffsetNorm = 6;
ExpParams.offset2amp = 8192/1; % divisor should be the max output voltage of the AWG
ExpParams.dataType = 'phase'; %or 'phase';

ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
ExpParams.SoftwareDevelopmentMode = 0;

% create object instance
pulseCal = PulseCalibration();

pulseCal.Init(ExpParams);
pulseCal.Do();

end