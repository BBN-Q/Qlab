%convert pulse params to dictionaries

% qubit-specific params
params = {'piAmp', 'pi2Amp', 'sigma', 'delta', 'pulseType', 'buffer', 'pulseLength'};

for k = 1:length(params)
    param = params{k};
    eval([param 's = containers.Map();']);
    eval([param 's(''q1'') = ' param]);
    eval([param 's(''q2'') = ' param '2']);
    eval([param 's(''q1q2'') = ' param '3']);
end

% channel-specific params
params2 = {'delay', 'offset', 'bufferPadding', 'bufferReset', 'bufferDelay', 'T'};

for k = 1:length(params2)
    param = params2{k};
    eval([param 's = containers.Map();']);
    eval([param 's(''12'') = ' param]);
    eval([param 's(''34'') = ' param '2']);
    eval([param 's(''56'') = ' param '3']);
end

saveparams = {'piAmps', 'pi2Amps', 'sigmas', 'deltas', 'pulseTypes', 'buffers', 'pulseLengths', '-v7.3'};
saveparams2 = {'delays', 'offsets', 'bufferPaddings', 'bufferResets', 'bufferDelays', 'Ts', '-append', '-v7.3'};

save('pulseParamsBundles.mat', saveparams{:});
save('pulseParamsBundles.mat', saveparams2{:});