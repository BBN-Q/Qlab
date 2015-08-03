function optimize_mixers(channel, overrideSSBFreq,  varargin)
    %optional input: 1 for prompt window
    assert(~isempty(channel), 'Oops! You must specify a channel to optimize.')
    % create a mixer optimizer object
    cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'optimize_mixer.json');
    optimizer = MixerOptimizer();
    optimizer.Init(cfgFile, channel, nargin>2 && varargin{1}==1, overrideSSBFreq);
    optimizer.Do();
end