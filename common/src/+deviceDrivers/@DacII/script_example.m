% Scripted DAC Control
% Example of controling dac 

programFpga = false;

% DAC USB ID to open starts at 0
dacId = 1;

% TOP of path from which file name are relative
fpath = 'c:\Documents and Settings\Administrator\Desktop\DAC II\src\matlab';

bitfile = [fpath '\BitFiles\cbl_dac2_r3gamma.bit'];

% file names to load waveforms
dac0wf = '\Waveforms\long_pulse.mat';
dac1wf = '\Waveforms\short_pulse.mat';
dac2wf = '';
dac3wf = '';

% waveform parameters
wfScaleFactors = [1,1,1,1];
wfOffsets = [0,0,0,0];
wfSampleRates = [1200,1200,1200,1200];

% simultaneous both DACs on the same FPGA
simultaneous = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End config
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create DACII control object
dac = dacii();

% open dac over usb
dac.open(dacId);

% check to see if dac is open
% if it is not Matlab may have the handle 
% so close and then open again
% if we still can't get the handle 
% give up and error
if (~dac.is_open)
    dac.close();
    dac.open(dacId);
    if (~dac.is_open)
        error('Could not open dac')
    end
end

if (programFpga)
    % load FPGA bit file
    dac.loadBitFile(bitfile);
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
%     wfFile = eval(sprintf('dac%iwf', id));
%     wf = waveforms(i);
%     if (~isempty(wfFile))
%         wf.set_file(wfFile,fpath);
%         wf.set_scale_factor(wfScaleFactors(i));
%         wf.set_offset(wfOffsets(i));
%         wf.set_sample_rate(wfSampleRates(i));
%         dac.loadWaveform(id,wf.get_vector(), wf.offset);
%         trigger(i) = 1;
%     end
% end

% triggering example
% trigger, wait 2 seconds and pause ...

% If we want to change the dac frequency this should be done
% prior to triggering
% Note that DAC 0 & 1 must have the same frequency
% Same for DAC 2 & 3

trigger = [1,1,0,0];

for cnt = 1:5
    
    wf = waveform();
    ln = cnt * 400;
    
    wf.data = [zeros([1,2000 - ln]) ones([1,ln])];
    wf.set_scale_factor(cnt/10+.5);
    
    dac.loadWaveform(0, wf.get_vector(), wf.offset);
    
    ln = (5-cnt) * 400;
    
    wf.data = [zeros([1,2000 - ln]) ones([1,ln]) zeros([1,1000])];
    wf.set_scale_factor((20-cnt)/10+.5);
    
    tic
    dac.loadWaveform(1, wf.get_vector(), wf.offset);
    toc
    
    if (simultaneous)
        if (trigger(1) && trigger(2))
            dac.setFrequency(0,waveforms(1).sample_rate);
            dac.triggerFpga(0, 1); % 0 -  dac number 1 - software trigger
        end
        if (trigger(3) && trigger(4))
            dac.setFrequency(2,waveforms(1).sample_rate);
            dac.triggerFpga(2, 1); % 2 -  dac number 1 - software trigger
        end
    else
        for i = 1:4
            if (trigger(i))
                dac.setFrequency(i-1,waveforms(i).sample_rate);
                dac.triggerWaveform(i-1, waveforms(i).trigger_type);
            end
        end
    end
    
    pause(2);
    
    if (simultaneous)
        dac.pauseFpga(0);
        dac.pauseFpga(2);
    else
        for i = 1:4
            dac.pauseWaveform(i-1);
        end
    end
        
end

dac.close();
