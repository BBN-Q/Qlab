function waveform(obj, channel, buffer, marker1, marker2)

wf_name = ['ch' num2str(channel)];
if nargin == 5
    obj.sendWaveform(wf_name, buffer, marker1, marker2);
else
    obj.sendWaveform(wf_name, buffer)
end

ch_string = ['chan_' num2str(channel)];

if ~isempty(strfind(obj.runMode,'SEQ'))
    obj.waveformName = {wf_ch wf_name};
elseif ~isempty(strfind(obj.runMode,'TRIG')) ...
        || ~isempty(strfind(obj.runMode,'CONT'))
    obj.(ch_string).outputWaveformName = wf_name;
else
    error('unknown run mode type')
end

obj.(ch_string).Enabled = 'on';

end