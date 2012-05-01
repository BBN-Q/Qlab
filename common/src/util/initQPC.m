% QPC initialization
%
% Author(s): TAO
% Date created: April 26 2012
% function initQPC(mrknum1, mrknum2, mrknum3,...
%                   sernum1,sernum2,sernum3,...
%                       fr1,fr2,fr3)...
% mrknum# is APS marker number connected to Switch TRIG   eg. 1,2,3
% sernum# is LabBrick serial for associated Switch TRIG   eg. 1692
% fr# is the LabBrick frequency(GHZ)used for each sernum# eg. 5.1

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
function initQPC(mrknum1, mrknum2, mrknum3,sernum1,sernum2,sernum3,fr1,fr2,fr3)
%%
temp = instrfind;
if ~isempty(temp)
    fclose(temp)
    delete(temp)
end
clear temp

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
%open spectrum analyzer (must modify this for individual setups eg address,cmds etc.)
%BBN is currently using a HP71000 SA GPIB 18
speca=gpib('ni',0,18);
fopen(speca)
%open Labricks
out1=deviceDrivers.Labbrick();
out2=deviceDrivers.Labbrick();
out3=deviceDrivers.Labbrick();
%connect to Labricks
try
connect(out1,sernum1)
catch
    disp('error connecting')
end
try
connect(out2,sernum2)
catch
    disp('error connecting')
end
try
connect(out3,sernum3)
catch
    disp('error connecting')
end
%set frequencies
frset=[fr1 fr2 fr3];
out1.frequency=fr1;
out2.frequency=fr2;
out3.frequency=fr3;
%open AWG
chan=[mrknum1 mrknum2 mrknum3];
awg = deviceDrivers.APS();
awg.open(0,1);
if ~awg.is_open
    error('Fail')
end
awg.stop()
forceLoadBitFile = 0;
awg.init(forceLoadBitFile);
awg.setAll(settings);
ch_fields = {['chan_' num2str(mrknum1)], ['chan_' num2str(mrknum2)], ['chan_' num2str(mrknum3)]};
for i = 1:length(ch_fields)
    ch = ch_fields{i};
    awg.setLinkListMode(chan(i)-1, awg.LL_ENABLE, awg.LL_ONESHOT);
    awg.(ch).enabled= true;
    disp(['measuring_chan_' num2str(chan(i))])
    for j=1:2
        fprintf(speca,sprintf('CF %dMHz',frset(i)*1000)) % in MHz
        fprintf(speca,sprintf('SP %dKHz',20))%100 KHz span
        pause(1.5)
        fprintf(speca,sprintf('MKPK HI;'))
        %keyboard
        awg.run();
        awg.stop();
        %measure leakage amplitude for each generator
        pause(1) 
        fprintf(speca,sprintf('MKA?;'))
        a(j)=str2num(fscanf(speca,'%s'));
        
    end
    if a(2)<a(1)
        display('inverted')
        awg.run();
        awg.stop();
        disp(['isolation ' num2str(a(1)-a(2)) 'dB'])
    else 
        disp(['isolation ' num2str(a(2)-a(1)) 'dB'])
    end
    awg.(ch).enabled = false;
    disp([ch '_initialized'])
end
disp(['QPC initialization complete'])
awg.close();disconnect(out1);disconnect(out2);disconnect(out3)
fclose(speca)
delete(awg);delete(out1);delete(out2);delete(out3);delete(speca)
clear awg out1 out2 out3 speca

