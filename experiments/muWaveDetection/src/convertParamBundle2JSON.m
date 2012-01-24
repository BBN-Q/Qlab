function out = convertParamBundle2JSON
    paramNames = {'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths'}; % 'passThrus'
    qubitParams = {'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength'};
    channelParams = {'T', 'delay', 'bufferDelay', 'bufferReset', 'bufferPadding'}; %passThru
    load('cfg/pulseParamBundles.mat', paramNames{:});
    
    qubits = {'q1', 'q2', 'q1q2'};
    %channels = {'TekAWG12', 'TekAWG34', 'BBNAPS12'};
    channels = {'12', '34', '56'};
    newchannels = {'Tek12', 'Tek34', 'BBN12'};
    
    params = struct();
    for ii = 1:length(qubits)
        q = qubits{ii};
        for jj = 1:length(qubitParams)
            p = qubitParams{jj};
            pVal = eval([p 's(''' q ''')']);
            params.(q).(p) = pVal;
        end
    end
    
    for ii = 1:length(channels);
        ch = channels{ii};
        for jj = 1:length(channelParams)
            p = channelParams{jj};
            pVal = eval([p 's(''' ch ''')']);
            params.(newchannels{ii}).(p) = pVal;
        end
    end
    
    out = jsonlab.savejson('', params);
end