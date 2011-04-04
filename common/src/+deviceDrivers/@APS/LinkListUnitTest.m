function LinkListUnitTest(sequence)

%% APS Enhanced Link List Unit Test
%%
%% Gets Pattern Generator and produces link lists from pattern generator
%% Downloads resulting waveform library and banks into APS memory
%% Test Status
%% Last Tested: Not yet tested
%% $Rev$
%%
%% Sequence 1: Echo:
%% Sequence 2: Rabi Amp:
%% Sequence 3: Ramsey:
%% Sequency 4: URamseySequence

% Uses PatternGen Link List Generator to develop link lists

addpath('../../common/src/','-END');
addpath('../../common/src/util/','-END');

%% Open APS Device

% work around for not knowing full name
% of class - can not use simply APS when in
% experiment framework
classname = mfilename('class');

% tests channel 0 & 1 output for basic bit file testing
aps = eval(sprintf('%s();', classname));

apsId = 0;

aps.open(apsId);

if (~aps.is_open)
    aps.close();
    aps.open(apsId);
    if (~aps.is_open)
        error('Could not open aps')
    end
end

%% Load Bit File

ver = aps.readBitFileVersion();
fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
if ver ~= aps.expected_bit_file_ver
    aps.loadBitFile();
    ver = aps.readBitFileVersion();
    fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
end

aps.verbose = 0;

%% Get Link List Sequency and Convert To APS Format
if ~exist('sequence', 'var') || isempty(sequence)
    sequence = 1;
end

useVarients = 1;

sequence = deviceDrivers.APS.LinkListSequences(sequence);
[wf, banks] = aps.convertLinkListFormat(sequence.llpatx,useVarients);


% load waveform for trigger

wf2 = APSWaveform();
wf2.data = [ones([1,100]) zeros([1,3000])];
wf3 = APSWaveform();
wf3.data = [ones([1,100]) zeros([1,1000])];

aps.setFrequency(2,300);
aps.loadWaveform(2,wf3.get_vector(),0);

aps.setFrequency(3,300);
aps.loadWaveform(3,wf2.get_vector(),0);

aps.triggerWaveform(2,aps.TRIGGER_HARDWARE);
aps.triggerWaveform(3,aps.TRIGGER_SOFTWARE);

aps.setFrequency(0,wf.sample_rate);
aps.loadWaveform(0, wf.data, wf.offset);  

%aps.triggerWaveform(0,aps.TRIGGER_SOFTWARE);
%aps.disableWaveform(0);

cb = banks{1};
APSbank = 0;
validate = 1;

% use only TA z
idx = [3 5 3]+1;

cb.offset = cb.offset(idx);
cb.count = cb.count(idx);
cb.trigger = cb.trigger(idx);
cb.repeat = cb.repeat(idx);
cb.length = length(idx);

aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, APSbank, validate)

aps.setLinkListRepeat(0,10000);

aps.setLinkListMode(0,aps.LL_ENABLE,aps.LL_CONTINUOUS);


aps.triggerWaveform(0,aps.TRIGGER_HARDWARE);
keyboard

%{
[wf, banks] = aps.convertLinkListFormat(sequence.llpaty,useVarients);
aps.setFrequency(1,wf.sample_rate);
aps.loadWaveform(1, wf.get_vector(), wf.offset);
cb = banks{1};
aps.loadLinkListELL(1,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, APSbank, validate)
aps.setLinkListMode(0,1,0);
aps.triggerFpga(0,1);
keyboard
%}

aps.pauseFpga(0);
aps.pauseFpga(2);
aps.close()


end