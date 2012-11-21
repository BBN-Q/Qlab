function SweepPulseBuffer(qubit, sweepPts, makePlot)
%SweepBufferPulse Sweep the pulse buffer to find the optimum value
% SweepBufferPulse(qubit, sweepPts, makePlot)
%   qubit - target qubit e.g. 'q1'
%   sweepPts - sweep points for the buffer delay
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)


basename = 'SweepBuffer';
fixedPt = 1000;
cycleLength = 3200;
nbrRepeats = 1;


% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

patseq = {{pg.pulse('QId')}, {pg.pulse('QId')},...
    {pg.pulse('Xtheta', 'pType', 'square', 'amp', 3400)}, {pg.pulse('Xtheta', 'pType', 'square', 'amp', 3400)}};
calseq = [];

% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;
curBufferDelay = params.(IQkey).bufferDelay;

expct = 1;
for bufferDelay = sweepPts
    
    %Write the buffer delay to file
    %     params.(IQkey).bufferDelay = bufferDelay;
    params.(IQkey).bufferDelay = bufferDelay;
    FID = fopen(getpref('qlab', 'pulseParamsBundleFile'),'wt'); %open in text mode
    fprintf(FID, jsonlab.savejson('',params));
    fclose(FID);
    
    % prepare parameter structures for the pulse compiler
    seqParams = struct(...
        'basename', basename, ...
        'suffix', ['_', num2str(expct)], ...
        'numSteps', 1, ...
        'nbrRepeats', nbrRepeats, ...
        'fixedPt', fixedPt, ...
        'cycleLength', cycleLength, ...
        'measLength', 2000);
    patternDict = containers.Map();
    if ~isempty(calseq), calseq = {calseq}; end
    
    patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
    measChannels = {'M1'};
    awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};
    
    compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
    expct = expct+1;
end


%Write the original delay back to the file
params.(IQkey).bufferDelay = curBufferDelay;
FID = fopen(getpref('qlab', 'pulseParamsBundleFile'),'wt'); %open in text mode
fprintf(FID, jsonlab.savejson('',params));
fclose(FID);

end
