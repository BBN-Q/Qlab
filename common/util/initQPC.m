% QPC initialization
%
% Authors: TAO, CAR
% Date created: April 26 2012
% function initQPC(mrkNums, serialNums, freqs)
%
% mrknums is an array APS marker channels connected to Switch TRIG   eg. [1, 3]
% serialNums is an array of LabBrick serial numbers for associated Switch
% TRIG eg. [1692, 1685] 
% freqs is an array the LabBrick frequencies to be used eg. [5.1, 6.2]

% Copyright 2012 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
function initQPC(mrkNums, serialNums, freqs)

%Clean up any old instruments (not particularly friendly to other
%programs)
delete(instrfind);

assert(length(mrkNums) == length(serialNums), 'Oops! We need the same number of marker channels as LabBrick serial numbers.');
assert(length(serialNums) == length(freqs), 'Oops!, We need the same number of frequencies as LabBrick serial numbers.');

numChannels = length(mrkNums);


%Setup some basic settings for the APS with all the channels off 
fprintf('Initializing APS\n');
settings = struct();
settings.chan_1.enabled = false;
settings.chan_1.amplitude = 1.0;
settings.chan_1.offset = 0;
settings.chan_2.enabled = false;
settings.chan_2.amplitude = 1.0;
settings.chan_2.offset = 0;
settings.chan_3.enabled = false;
settings.chan_3.amplitude = 1.0;
settings.chan_3.offset = 0;
settings.chan_4.enabled = false;
settings.chan_4.amplitude = 1.0;
settings.chan_4.offset = 0;
settings.samplingRate = 1200;
settings.triggerSource = 'internal';
settings.seqfile = 'U:\APS\initQPC\initQPCBBNAPS12.mat';
settings.seqforce = true;


%Open and connect to spectrum analyzer (must modify this for individual setups eg address,cmds etc.)
%BBN is currently using a HP71000 SA GPIB 18
speca= deviceDrivers.HP71000();
speca.connect(18);
% speca= deviceDrivers.AnritsuMS271xB();
% speca.connect('9.2.178.135');

%Open Labricks

labBricks(numChannels,1) = deviceDrivers.Labbrick();
for ct = 1:numChannels
    try
        labBricks(ct).connect(serialNums(ct))
    catch exception
        fprintf('Error connecting to Labbrick %s.', exception.message)
    end
    labBricks(ct).frequency = freqs(ct);
end

%open AWG
awg = deviceDrivers.APS();
awg.open(0,1);
if ~awg.is_open
    error('Fail')
end
awg.stop()
forceLoadBitFile = 0;
awg.init(forceLoadBitFile);
awg.setAll(settings);
ch_fields = arrayfun(@(x) ['chan_' int2str(x)], mrkNums, 'UniformOutput', false);
a = zeros(2,1);
for ct = 1:numChannels
    ch = ch_fields{ct};
    awg.setLinkListMode(mrkNums(ct)-1, awg.LL_ENABLE, awg.LL_ONESHOT);
    awg.(ch).enabled= true;
    disp(['Measuring chan_' num2str(mrkNums(ct))])
    %Now flip the switch 
    for j=1:2
        speca.center_frequency = freqs(ct)*1e9;
        speca.span = 100e3;
        pause(1.5)
        %keyboard
        awg.run();
        awg.stop();
        %measure leakage amplitude for each generator
        pause(1) 
        a(j) = speca.peakAmplitude();
    end
    %Check to see which direction had the switch open or closed
    if a(2)<a(1)
        display('Channel was inverted')
        awg.run();
        awg.stop();
        disp(['Isolation: ' num2str(a(1)-a(2)) 'dB'])
    else 
        disp(['Isolation ' num2str(a(2)-a(1)) 'dB'])
    end
    awg.(ch).enabled = false;
    disp([ch ' initialized'])
end
disp('QPC initialization complete')
for ct = 1:numChannels
    labBricks(ct).disconnect();
end
awg.close();
speca.disconnect();

