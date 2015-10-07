function [optlen, optphase] = calibrateCR(control, target, CR, chan, lenstep)
%function to calibrate length and phase of CR pulse. It assumes that the
%sequence EchoCR is loaded. Need to change it to load all sequences. 
CalParams = struct();
CalParams.control = control;
CalParams.target = target;
CalParams.CR = CR;
CalParams.channel = chan; %meas. channel for target qubit
CalParams.lenstep = lenstep; %step in length calibration (in ns)

warning('off', 'json:fieldNameConflict');
chanSettings = json.read(getpref('qlab', 'ChannelParamsFile'));
expSettings = json.read(getpref('qlab', 'CurScripterFile'));
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
expSettings.AWGs = unique(expSettings.AWGs); %remove duplicates

%disable unused measurements. Not sure if this is useful yet. Warning: it
%doesn't work with correlators (it leaves all enabled)
for measname = fieldnames(expSettings.measurements)'
    if sum(strfind(measname{1},strcat('M',target(2))))+sum(strfind(measname{1},strcat('M',control(2))))==0 && ~isempty(strfind(measname{1},'M'))
        expSettings.measurements = rmfield(expSettings.measurements, measname{1});
    end
end

%create a sequence with desired range of CR pulse lengths
CRCalSequence(CalParams.control, CalParams.target, 1, CalParams.lenstep)

%updates sweep settings 
expSettings.sweeps.SegmentNumWithCals.start = CalParams.lenstep*2;
expSettings.sweeps.SegmentNumWithCals.stop = CalParams.lenstep*40-CalParams.lenstep;
expSettings.sweeps.SegmentNumWithCals.numPoints = 46;
expSettings.sweeps.SegmentNumWithCals.numCals = 8;
expSettings.sweeps.SegmentNumWithCals.step = (expSettings.sweeps.SegmentNumWithCals.stop-expSettings.sweeps.SegmentNumWithCals.start)/(expSettings.sweeps.SegmentNumWithCals.numPoints-expSettings.sweeps.SegmentNumWithCals.numCals-1);
expSettings.sweeps.SegmentNumWithCals.axisLabel = 'Pulse top length (ns)';

expSettings.instruments = instrSettings;
expSettings.saveAllSettings = false;

%run the sequence
ExpScripter2('CRcal_len', expSettings, 'lockSegments');

%analyze the sequence and updates CR pulse
data=load_data('latest');
optlen = analyzeCalCR(1,data,CalParams.channel, CalParams.CR);

%create a sequence with calibrated length and variable phase

CRCalSequence(CalParams.control, CalParams.target, 2, optlen) 

%updates sweep settings
%instrSettings = json.read(cfgpath);
expSettings.sweeps.SegmentNumWithCals.start = 0;
expSettings.sweeps.SegmentNumWithCals.stop = 720;
expSettings.sweeps.SegmentNumWithCals.numPoints = 46;
expSettings.sweeps.SegmentNumWithCals.numCals = 8;
expSettings.sweeps.SegmentNumWithCals.step = (expSettings.sweeps.SegmentNumWithCals.stop-expSettings.sweeps.SegmentNumWithCals.start)/(expSettings.sweeps.SegmentNumWithCals.numPoints-expSettings.sweeps.SegmentNumWithCals.numCals-1);
expSettings.sweeps.SegmentNumWithCals.axisLabel = 'Pulse phase (deg)';

%run the sequence
ExpScripter2('CRcal_ph', expSettings, 'lockSegments');

%analyze the sequence and updates CR pulse
data=load_data('latest');
optphase = analyzeCalCR(2,data,CalParams.channel,CalParams.CR, 102);
