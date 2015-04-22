function [optlen, optphase] = calibrateCR(control, target, CR, chan)
%function to calibrate length and phase of CR pulse. It assumes that the
%sequence EchoCR is loaded
CalParams = struct();
CalParams.control = control;
CalParams.target = target;
CalParams.CR = CR;
CalParams.channel = chan; %meas. channel for target qubit
CalParams.lenstep = 20; %step in length calibration (in ns)

cfgpath=getpref('qlab','CurScripterFile');
%sweepPath=strrep(cfgpath,'ChannelParams','Sweeps');

%create a sequence with desired range of CR pulse lengths

CRCalSequence(CalParams.control, CalParams.target, CalParams.CR, 1, CalParams.lenstep)

%updates sweep settings 
cfgLib = json.read(cfgpath);
%cfgLib.sweepOrder='SegmentNumWithCals';
cfgLib.sweeps.SegmentNumWithCals.start = CalParams.lenstep*2;
cfgLib.sweeps.SegmentNumWithCals.stop = CalParams.lenstep*40-CalParams.lenstep;
cfgLib.sweeps.SegmentNumWithCals.numPoints = 46;
cfgLib.sweeps.SegmentNumWithCals.numCals = 8;
cfgLib.sweeps.SegmentNumWithCals.step = (cfgLib.sweeps.SegmentNumWithCals.stop-cfgLib.sweeps.SegmentNumWithCals.start)/(cfgLib.sweeps.SegmentNumWithCals.numPoints-cfgLib.sweeps.SegmentNumWithCals.numCals-1);
cfgLib.sweeps.SegmentNumWithCals.axisLabel = 'Pulse top length (ns)';
json.write(cfgLib, cfgpath, 'indent', 2);  

%run the sequence
ExpScripter('CRcal_len', 'lockSegments');

%analyze the sequence and updates CR pulse
data=load_data('latest');
optlen = analyzeCalCR(1,data,CalParams.channel, CalParams.CR);

%create a sequence with calibrated length and variable phase

CRCalSequence(CalParams.control, CalParams.target, CalParams.CR, 2, optlen) 

%updates sweep settings

cfgLib = json.read(cfgpath);
cfgLib.sweeps.SegmentNumWithCals.start = 0;
cfgLib.sweeps.SegmentNumWithCals.stop = 720;
cfgLib.sweeps.SegmentNumWithCals.numPoints = 46;
cfgLib.sweeps.SegmentNumWithCals.numCals = 8;
cfgLib.sweeps.SegmentNumWithCals.step = (cfgLib.sweeps.SegmentNumWithCals.stop-cfgLib.sweeps.SegmentNumWithCals.start)/(cfgLib.sweeps.SegmentNumWithCals.numPoints-cfgLib.sweeps.SegmentNumWithCals.numCals-1);
cfgLib.sweeps.SegmentNumWithCals.axisLabel = 'Pulse phase (deg)';
json.write(cfgLib, cfgpath, 'indent', 2);

%run the sequence
ExpScripter('CRcal_ph', 'lockSegments');

%analyze the sequence and updates CR pulse
data=load_data('latest');
optphase = analyzeCalCR(2,data,CalParams.channel,CalParams.CR, 102);
