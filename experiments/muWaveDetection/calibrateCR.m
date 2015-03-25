function [optlen, optphase] = calibrateCR()
%function to calibrate length and phase of CR pulse. 
CalParams = struct();
CalParams.control = 'q2';
CalParams.target = 'q1';
CalParams.CR = 'CR';
CalParams.channel = 2; %meas. channel for target qubit
CalParams.lenstep = 30; %step in length calibration (in ns)

%create a sequence with desired range of CR pulse lengths

CRcalSequence(CalParams.control, CalParams.target, CalParams.CR, 1, CalParams.lenstep)

%updates sweep settings 
cfgpath=(getpref('qlab','ChannelParamsFile'));
sweepPath=strrep(cfgpath,'ChannelParams','Sweeps');
sweepLib = json.read(sweepPath);
sweepLib.sweepDict.SegmentNumWithCals.start = CalParams.lenstep*2;
sweepLib.sweepDict.SegmentNumWithCals.stop = CalParams.lenstep*40;
sweepLib.sweepDict.numPoints = 38;
sweepLib.sweepDict.numCals = 8;
sweepLib.sweepDict.SegmentNumWithCals.axisLabel = 'Pulse top length (ns)';
json.write(sweepLib, sweepPath, 'indent', 2);

%run the sequence
ExpScripter('CRcal_len');

%analyze the sequence and updates CR pulse
data=load_data('latest');
optlen = analyzeCalCR(1,data,CalParams.channel);

%create a sequence with calibrated length and variable phase

CRcalSequence(CalParams.control, CalParams.target, CalParams.CR, 2, optlen)

%updates sweep settings

cfgpath=(getpref('qlab','ChannelParamsFile'));
sweepPath=strrep(cfgpath,'ChannelParams','Sweeps');
sweepLib = json.read(sweepPath);
sweepLib.sweepDict.SegmentNumWithCals.start = 0;
sweepLib.sweepDict.SegmentNumWithCals.stop = 720;
sweepLib.sweepDict.numPoints = 38;
sweepLib.sweepDict.numCals = 8;
sweepLib.sweepDict.SegmentNumWithCals.axisLabel = 'Pulse phase (deg)';
json.write(sweepLib, sweepPath, 'indent', 2);

%run the sequence
ExpScripter('CRcal_ph');

%analyze the sequence and updates CR pulse
data=load_data('latest');
optphase = analyzeCalCR(2,data,CalParams.channel);
