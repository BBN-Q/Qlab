function sweep_calibrateCR(control, target, CR, chan, lenstep, ampvec)
%calibrate CR wrapper
persistent figHandles
if isempty(figHandles)
    figHandles = struct();
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
    expSettings.instruments.(tmpStr{1}).chan_1.amplitude = amp;
    expSettings.instruments.(tmpStr{1}).chan_2.amplitude = amp;
    [optlen, ~, contrast] = calibrateCR(control, target, CR, chan, lenstep, expSettings);
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



