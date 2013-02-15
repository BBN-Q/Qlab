function optimize_mixers(channel)
    assert(~isempty(channel), 'Oops! You must specify a channel to optimize.')
    % create a mixer optimizer object
    cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'optimize_mixer.json');
    optimizer = MixerOptimizer();
    optimizer.Init(cfgFile, channel);
    optimizer.Do();
end