function sweep_calibrateCR(control, target, CR, chan, lenstep, ampvec, calSteps, varargin)
%calibrate CR wrapper
%calSteps = [a,b,c] 0/1 a: length, b: phase c: amplitude 
persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

%optional input: amplitude sweep 0: channel amp., 1: pulse amp.
if isempty(varargin)
    sweep_mode = 0;
else
    sweep_mode = varargin{1};
end

warning('off', 'json:fieldNameConflict');
chanSettings = json.read(getpref('qlab', 'ChannelParamsFile'));
chanSettings = chanSettings.channelDict;
expSettings = json.read(getpref('qlab', 'CurScripterFile'));
warning('on', 'json:fieldNameConflict');
tmpStr = regexp(chanSettings.(CR).physChan, '-', 'split');

optlenvec = nan(length(ampvec),1);
contrastvec = nan(length(ampvec),1);

for k = 1:length(ampvec)
    amp  = ampvec(k);
    if sweep_mode == 0
        expSettings.instruments.(tmpStr{1}).chan_1.amplitude = amp;
        expSettings.instruments.(tmpStr{1}).chan_2.amplitude = amp;
        pulseAmp = 0.8;
    else
        pulseAmp = amp;
    end
    [optlen, ~, contrast] = calibrateCR(control, target, CR, chan, lenstep, 'expSettings', expSettings, 'calSteps', calSteps, 'amplitude', pulseAmp);
    optlenvec(k) = optlen;
    contrastvec(k) = contrast;
    if ~isfield(figHandles, 'CRsweep') || ~ishandle(figHandles.( 'CRsweep'))
        figHandles.( 'CRsweep') = figure('Name',  'CRsweep');
    else
        figure(figHandles.( 'CRsweep')); clf;
    end
    [ax,~,~]=plotyy(ampvec,optlenvec,ampvec, contrastvec);
    ylabel(ax(1),'Length (ns)')
    ylabel(ax(2),'Contrast')
    xlabel([CR ' amplitude']) 
end



