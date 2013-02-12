function optimize_mixers(channel)
    assert(~isempty(channel), 'Must specify a channel to optimize')
    % create a mixer optimizer object
    cfg_path = fullfile(getpref('qlab', 'cfgDir'), 'optimize_mixer.json');
    optimizer = MixerOptimizer(cfg_path, channel);
    optimizer.Run();
end