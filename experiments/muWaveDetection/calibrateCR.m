function [optlen, optphase, contrast, optamp] = calibrateCR(control, target, CR, chan, lenstep, varargin)
%function to calibrate length and phase of CR pulse. It assumes that the
%sequence EchoCR is loaded. Need to change it to load all sequences.
%optional arguments:
% - expSettings
% - calSteps: calibration types. A list of 0,1 to calibrate [a,b,c], with a = length,
% b = phase, c = amplitude
p = inputParser;
addParameter(p,'expSettings', json.read(getpref('qlab', 'CurScripterFile')), @isstruct)
addParameter(p,'calSteps', [1,1,0])
addParameter(p,'amplitude',0.8)
parse(p, varargin{:});
expSettings = p.Results.expSettings;
calSteps = p.Results.calSteps;
amplitude = p.Results.amplitude;

optphase = NaN;
contrast = NaN;
optamp = NaN;

CalParams = struct();
CalParams.control = control;
CalParams.target = target;
CalParams.CR = CR;
CalParams.channel = chan; %meas. channel for target qubit
CalParams.lenstep = lenstep; %step in length calibration (in ns)
CalParams.amp = amplitude; %starting pulse amplitude

warning('off', 'json:fieldNameConflict');
chanSettings = json.read(getpref('qlab', 'ChannelParamsFile'));
instrSettings = expSettings.instruments;
warning('on', 'json:fieldNameConflict');
chanSettings = chanSettings.channelDict;

expSettings.AWGs = {};
expSettings.AWGfilename = 'EchoCR';

%selects the relevant AWGs
tmpStr = regexp(chanSettings.(target).physChan, '-', 'split');
expSettings.AWGs{1} = tmpStr{1};
tmpStr = regexp(chanSettings.(CR).physChan, '-', 'split');
expSettings.AWGs{2} = tmpStr{1};
tmpStr = regexp(chanSettings.(strcat(genvarname('M-'),target)).physChan, '-', 'split');
expSettings.AWGs{3} = tmpStr{1};
tmpStr = regexp(chanSettings.(control).physChan, '-', 'split');
expSettings.AWGs{4} = tmpStr{1};
tmpStr = regexp(chanSettings.(strcat(genvarname('M-'),control)).physChan, '-', 'split');
expSettings.AWGs{5} = tmpStr{1};
for instr = fieldnames(instrSettings)'
    if isfield(instrSettings.(instr{1}),'isMaster') && instrSettings.(instr{1}).isMaster
        expSettings.AWGs{6} = instr{1};
        break
    end
end
expSettings.AWGs = unique(expSettings.AWGs); %remove duplicates

%disable unused measurements, including correlators
for measname = fieldnames(expSettings.measurements)'
    if (sum(strfind(measname{1},strcat('M',target(2))))+sum(strfind(measname{1},strcat('M',control(2))))==0 && ~isempty(strfind(measname{1},'M')))...
            || sum(strfind(measname{1},'M'))>1
        expSettings.measurements = rmfield(expSettings.measurements, measname{1});
    end
end

expSettings.instruments = instrSettings;
expSettings.saveAllSettings = false;

if calSteps(1)
    %create a sequence with desired range of CR pulse lengths
    CRCalSequence(CalParams.control, CalParams.target, 1, CalParams.lenstep, CalParams.amp)  

    %run the sequence
    ExpScripter2('CRcal_len', expSettings, 'EchoCR/EchoCR');

    %analyze the sequence and updates CR pulse
    data=load_data('latest');
    optlen = analyzeCalCR(1,data,CalParams.channel, CalParams.CR)*1e3;
else
    optlen = chanSettings.(CR).pulseParams.length*1e9;
end

if calSteps(2)
    %create a sequence with calibrated length and variable phase

    CRCalSequence(CalParams.control, CalParams.target, 2, optlen, CalParams.amp)

    %run the sequence
    ExpScripter2('CRcal_ph', expSettings, 'EchoCR/EchoCR');

    %analyze the sequence and updates CR pulse
    data=load_data('latest');
    [optphase, contrast] = analyzeCalCR(2,data,CalParams.channel,CalParams.CR);
end

if calSteps(3)
    %create a sequence with desired range of CR pulse amplitudes
    CRCalSequence(CalParams.control, CalParams.target, 3, optlen, CalParams.amp)

    %run the sequence
    ExpScripter2('CRcal_amp', expSettings, 'EchoCR/EchoCR');

    %analyze the sequence and updates CR pulse
    data=load_data('latest');
    optamp = analyzeCalCR(3,data,CalParams.channel, CalParams.CR);
    
    calpath = fullfile(getpref('qlab','dataDir'),'Cal_Logs');
    expSettings = json.read(getpref('qlab', 'CurScripterFile'));
    warning('off', 'json:fieldNameConflict');
    chanSettings = json.read(getpref('qlab', 'ChannelParamsFile'));
    warning('on', 'json:fieldNameConflict');
    CRcalvec = [optlen, optphase, optamp];
    CRfile = fopen(fullfile(calpath, ['CRvec_' control(2) target(2) '.csv']), 'at');
    fprintf(CRfile, '%s\t%.4f\t%.4f\t%.4f\n', datestr(now,31), CRcalvec(1), CRcalvec(2), CRcalvec(3));
    fclose(CRfile);
end
