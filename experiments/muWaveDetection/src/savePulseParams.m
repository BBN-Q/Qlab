%function savePulseParams
    params = {'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength'};
    script = java.io.File(mfilename('fullpath'));
    parent_path = char(script.getParentFile.getParent());
    cfg_path = [parent_path '/cfg/'];
    
    for i = 1:length(params)
        p = params{i};
        %eval(sprintf('global %s', p)); % declare global
        %val = eval(p); % get the current value
        %if isempty(val)
        if ~exist(p, 'var')
            %fprintf('Loading %s\n', p);
            load([cfg_path 'pulseParams.mat'], p);
        end
        %fprintf('Saving %s, Current value: ', p);
        %disp(eval(p));
        save([cfg_path 'pulseParams.mat'], p, '-append', '-v7.3');
    end
    
    clear params script parent_path cfg_path i p
%end