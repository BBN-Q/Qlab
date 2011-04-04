% Scripted DAC Control
% Example of controling aps 

programFpga = false;

% DAC USB ID to open starts at 0
apsId = 1;

% TOP of path from which file name are relative
fpath = PWD;

bitfile = [fpath '\BitFiles\cbl_aps2_r3gamma.bit'];

% file names to load waveforms
aps0wf = '\Waveforms\long_pulse.mat';
aps1wf = '\Waveforms\short_pulse.mat';
aps2wf = '';
aps3wf = '';

% waveform parameters
wfScaleFactors = [1,1,1,1];
wfOffsets = [0,0,0,0];
wfSampleRates = [1200,1200,1200,1200];

% simultaneous both DACs on the same FPGA
simultaneous = true;
simultaneous = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End config
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create APS control object
aps = APS();

% open aps over usb
aps.open(apsId);

% check to see if aps is open
% if it is not Matlab may have the handle 
% so close and then open again
% if we still can't get the handle 
% give up and error
if (~aps.is_open)
    aps.close();
    aps.open(apsId);
    if (~aps.is_open)
        error('Could not open aps')
    end
end

if (programFpga)
    % load FPGA bit file
    aps.loadBitFile(bitfile);
end

% create waveform objects
% these objects have all of the logic 
% to load, scale and pad the waveform
% as well as default parameters 
waveforms = [waveform(), waveform(), waveform(), waveform()];

% keep tracks of if we should trigger a given channel
% if the file was empty above we won't trigger
trigger = zeros([4,1]);
% 
% for i = 1:4
%     id = i - 1;
%     wfFile = eval(sprintf('aps%iwf', id));
%     wf = waveforms(i);
%     if (~isempty(wfFile))
%         wf.set_file(wfFile,fpath);
%         wf.set_scale_factor(wfScaleFactors(i));
%         wf.set_offset(wfOffsets(i));
%         wf.set_sample_rate(wfSampleRates(i));
%         aps.loadWaveform(id,wf.get_vector(), wf.offset);
%         trigger(i) = 1;
%     end
% end

% triggering example
% trigger, wait 2 seconds and pause ...

% If we want to change the aps frequency this should be done
% prior to triggering
% Note that DAC 0 & 1 must have the same frequency
% Same for DAC 2 & 3

trigger = [1,1,0,0];

for cnt = 1:5
    
    wf = waveform();
    ln = cnt * 400;
    
    wf.data = [zeros([1,2000 - ln]) ones([1,ln])];
    wf.set_scale_factor(cnt/10+.5);
    
    aps.loadWaveform(0, wf.get_vector(), wf.offset);
    
    ln = (5-cnt) * 400;
    
    wf.data = [zeros([1,2000 - ln]) ones([1,ln]) zeros([1,1000])];
    wf.set_scale_factor((20-cnt)/10+.5);
    
    tic
    aps.loadWaveform(1, wf.get_vector(), wf.offset);
    toc
    
    if (simultaneous)
        if (trigger(1) && trigger(2))
            aps.setFrequency(0,waveforms(1).sample_rate);
            aps.triggerFpga(0, 1); % 0 -  aps number 1 - software trigger
        end
        if (trigger(3) && trigger(4))
            aps.setFrequency(2,waveforms(1).sample_rate);
            aps.triggerFpga(2, 1); % 2 -  aps number 1 - software trigger
        end
    else
        for i = 1:4
            if (trigger(i))
                aps.setFrequency(i-1,waveforms(i).sample_rate);
                aps.triggerWaveform(i-1, waveforms(i).trigger_type);
            end
        end
    end
    
    pause(2);
    
    if (simultaneous)
        aps.pauseFpga(0);
        aps.pauseFpga(2);
    else
        for i = 1:4
            aps.pauseWaveform(i-1);
        end
    end
        
end

aps.close();
