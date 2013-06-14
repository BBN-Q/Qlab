function calibratePulses(qubit)

if ~exist('qubit', 'var')
    qubit = 'q1';
end

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qubit;
ExpParams.measurement = 'M2';
ExpParams.DoMixerCal = 0;
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 0;
ExpParams.NumPi2s = 11;
ExpParams.DoPi2Cal = 1;
ExpParams.NumPis = 11;
ExpParams.DoPiCal = 0;
ExpParams.DoDRAGCal = 0;
ExpParams.DRAGparams = linspace(-1,1,11);
ExpParams.DoSPAMCal = 0;
ExpParams.OffsetNorm = 6;
ExpParams.offset2amp = 8192/1; % divisor should be the max output voltage of the AWG
ExpParams.dataType = 'phase'; %'amp', 'phase', 'real', or 'imag';

ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
ExpParams.SoftwareDevelopmentMode = 0;

% create object instance
pulseCal = PulseCalibration();

pulseCal.Init(ExpParams);
pulseCal.Do();

end