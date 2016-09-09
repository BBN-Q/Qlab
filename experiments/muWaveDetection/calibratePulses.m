function calibratePulses(qubit, varargin)
%optional input: an ExpParams structure with any number of cal. settings,
%overwriting those in the list below

if ~exist('qubit', 'var')
    qubit = 'q1';
end

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qubit;
ExpParams.measurement = ['M' qubit(end) 'Kernel'];
ExpParams.DoMixerCal = 0;
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 1;
ExpParams.Ramsey2f = 1;
ExpParams.RamseyStop = 60000; %in ns
ExpParams.RamseyDetuning =  -150; %in kHz
ExpParams.NumRamseySteps = 101;
ExpParams.NumPi2s = 8;
ExpParams.DoPi2Cal = 0;
ExpParams.DoPi2PhaseCal = 1;
ExpParams.NumPis = 8;
ExpParams.DoPiCal = 0;
ExpParams.DoPiPhaseCal = 1;
ExpParams.DoDRAGCal = 0;
ExpParams.DRAGparams = linspace(-1,1,11);
ExpParams.DoSPAMCal = 0;
ExpParams.OffsetNorm = 6;
ExpParams.offset2amp = 1/1; % divisor should be the max output voltage of the AWG
ExpParams.dataType = 'real'; %'amp', 'phase', 'real', or 'imag';
ExpParams.tuneSource = false;

ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
ExpParams.SoftwareDevelopmentMode = 0;

%optional logging of frequency and amplitudes over time
ExpParams.dolog = false;
ExpParams.calpath = 'C:\Users\qlab\Documents\data\Cal_Logs';

if nargin>1 %updates ExpParams with optional input settings
%Remove overlapping fields from default ExpParams
ExpParams = rmfield(ExpParams, intersect(fieldnames(ExpParams), fieldnames(varargin{1})));
%Obtain all unique names of remaining fields
names = [fieldnames(ExpParams); fieldnames(varargin{1})];
%// Merge both structs
ExpParams = cell2struct([struct2cell(ExpParams); struct2cell(varargin{1})], names, 1);
end

% create object instance
pulseCal = PulseCalibration();

pulseCal.Init(ExpParams);
pulseCal.Do();

end