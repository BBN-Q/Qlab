function waveform(obj,wfParams,Params)

[pulseData] = initializeWaveform(wfParams,obj.samplingRate,obj.waveformDuration);

taskName_i = Params.taskParameters.taskName;
wf_name =  taskName_i;
wf_ch   = Params.taskParameters.pulseCH;

obj.sendWaveformReal(wf_name,pulseData);
if ~isfield(Params.taskParameters,'marker')
    Params.taskParameters.marker = [0;0];
end
marker = zeros(2,numel(pulseData));
for marker_index = 1:2
    if Params.taskParameters.marker(marker_index)
        if marker_index == 1
            marker(marker_index,wfParams.marker1Start:(wfParams.marker1Start+wfParams.marker1Length-1)) = 1;
        elseif marker_index == 2
            marker(marker_index,wfParams.marker2Start:(wfParams.marker2Start+wfParams.marker1Length-1)) = 1;
        end
    else
    end
end
ch_string = ['chan_' num2str(wf_ch)];

if ~isempty(strfind(obj.runMode,'SEQ'))
    obj.waveformName = {wf_ch ['"' wf_name '"']};
elseif ~isempty(strfind(obj.runMode,'TRIG')) ...
        || ~isempty(strfind(obj.runMode,'CONT'))
    obj.(ch_string).outputWaveformName = wf_name;
else
    error('unknown run mode type')
end

obj.sendMarkerData(wf_name,marker(1,:),marker(2,:),0)
obj.(ch_string).Enabled = 'on';

end