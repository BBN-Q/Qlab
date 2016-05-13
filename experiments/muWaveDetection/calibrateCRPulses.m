function calibrateCRPulses(qc, qt, CR, varargin)
%Use phase estimation to calibrate the amplitude of CR pulses.
%Replace cal. step 3 in calibrateCR.m
%TODO: to be integrated with steps 1 and 2 for length and phase calibration

%optional inputs:
%expSettingsIn - full or partial ExpSettings structure

%currently supports CR cal with a separate function call per gate, 
%as the measurement channel is different for each target

p = inputParser;
addParameter(p,'expSettings', {}, @isstruct)
parse(p, varargin{:});
expSettingsIn = p.Results.expSettings;

% construct minimal cfg file
ExpParams = struct();
ExpParams.Qubit = qc; %control qubit
ExpParams.measurement = ['M' qt(end) 'Kernel'];
ExpParams.DoZXPi2PhaseCal = 1;  
ExpParams.NumPi2s = 5;
ExpParams.dataType = 'real'; %'amp', 'phase', 'real', or 'imag';
ExpParams.CRpulses = {qt, CR}; 

ExpParams.DoMixerCal = 0; %for compatibility with PulseCalibrationDo
ExpParams.DoRabiAmp = 0;
ExpParams.DoRamsey = 0;
ExpParams.DoPi2Cal = 0;
ExpParams.DoPiCal = 0;
ExpParams.DoPiPhaseCal = 0;
ExpParams.DoPi2PhaseCal = 0;
ExpParams.DoDRAGCal = 0;
ExpParams.DoSPAMCal = 0;


ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
ExpParams.SoftwareDevelopmentMode = 0;

%optional logging of frequency and amplitudes over time
ExpParams.dolog = true;
ExpParams.calpath = 'C:\Users\qlab\Documents\data\Cal_Logs';

if ~isempty(expSettingsIn) %updates ExpParams with optional input settings
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