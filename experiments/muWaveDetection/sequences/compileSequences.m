function compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotIdx)
% inputs:
% seqParams - structure of:
%   basename - string specifying the target folder and file name
%   suffix - string to tack onto the end of the basename
%   numSteps
%   nbrRepeats
%   fixedPt
%   cycleLength
%   measLength
% patternDict - containers.Map object that is keyed on IQkey. It contains:
%   pg - PatternGen object
%   patseq - experiment pattern sequence (will unroll over numsteps)
%   calseq - calibration pattern sequence (assumed to be 'flat')
%   channelMap - data from the qubit2ChannelMap
% measChannels - cell array of measurement channel strings
% awgs - cell array of strings of AWGs to build for

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

channelNames = keys(patternDict);
tempPatterns = patternDict(channelNames{1});
% note: this breaks if the patterns have different lengths, may want to
% assert this
nbrPatterns = length(tempPatterns.patseq)*seqParams.nbrRepeats;
calPatterns = length(tempPatterns.calseq)*seqParams.nbrRepeats;
numSegments = nbrPatterns*seqParams.numSteps + calPatterns;
fprintf('Number of sequences: %i\n', numSegments);

% inject measurement sequences
for measCh = measChannels
    measCh = measCh{1};
    IQkey = qubitMap.(measCh).IQkey;
    SSBFreq = +10e6;
    ChParams = params.(IQkey);
    % shift the delay to include the measurement length
    params.(IQkey).delay = ChParams.delay + seqParams.measLength;
    % force link list mode to true when constructing this PatternGen object
    pgM = PatternGen('correctionT', ChParams.T,'bufferDelay',ChParams.bufferDelay,'bufferReset',ChParams.bufferReset,'bufferPadding',ChParams.bufferPadding, 'cycleLength', seqParams.cycleLength, 'linkList', 1, 'dmodFrequency',SSBFreq);
    
    measSeq = {{pgM.pulse('Xtheta', 'pType', 'tanh', 'sigma', 1, 'buffer', 0, 'amp', 4000, 'width', seqParams.measLength)}};
    patternDict(IQkey) = struct('pg', pgM, 'patseq', {repmat(measSeq, 1, nbrPatterns)}, 'calseq', {repmat(measSeq,1,calPatterns)}, 'channelMap', qubitMap.(measCh));
end

% keep track of whether all channels on all AWGs are used
awgChannels = containers.Map();
for awg = awgs
    awg = awg{1};
    awgChannels([awg '_12']) = [];
    awgChannels([awg '_34']) = [];
    if strcmpi(awg(1:3), 'tek') % create marker channels if a TekAWG
        awgChannels([awg '_1m1']) = [];
        awgChannels([awg '_2m1']) = [];
        awgChannels([awg '_3m1']) = [];
        awgChannels([awg '_4m1']) = [];
        awgChannels([awg '_1m2']) = [];
        awgChannels([awg '_2m2']) = [];
        awgChannels([awg '_3m2']) = [];
        awgChannels([awg '_4m2']) = [];
    end
end

% re-assign channels names to pick up injected measurement channels
channelNames = keys(patternDict);
for IQkey = channelNames
    IQkey = IQkey{1}; % convert to a string
    channelMap = patternDict(IQkey).channelMap;
    bufferIQkey = channelMap.marker;
    ChParams = params.(IQkey);
    pg = patternDict(IQkey).pg;
    patseq = patternDict(IQkey).patseq;
    calseq = patternDict(IQkey).calseq;

    % if not in link list mode, allocate memory for patterns
    if (~pg.linkList)
        chI = zeros(numSegments, seqParams.cycleLength, 'int16');
        chQ = chI;
        chBuffer = zeros(numSegments, seqParams.cycleLength, 'uint8');

        for n = 1:nbrPatterns;
            for stepct = 1:seqParams.numSteps
                [patx paty] = pg.getPatternSeq(patseq{floor((n-1)/seqParams.nbrRepeats)+1}, stepct, ChParams.delay, seqParams.fixedPt);

                chI((n-1)*seqParams.numSteps + stepct, :) = patx + ChParams.offset;
                chQ((n-1)*seqParams.numSteps + stepct, :) = paty + ChParams.offset;
                chBuffer((n-1)*seqParams.numSteps + stepct, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
            end
        end

        for n = 1:calPatterns;
            [patx paty] = pg.getPatternSeq(calseq{floor((n-1)/seqParams.nbrRepeats)+1}, 1, ChParams.delay, seqParams.fixedPt);

            chI(nbrPatterns*seqParams.numSteps + n, :) = patx + ChParams.offset;
            chQ(nbrPatterns*seqParams.numSteps + n, :) = paty + ChParams.offset;
            chBuffer(nbrPatterns*seqParams.numSteps + n, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
        end
        
        awgChannels(IQkey) = {chI, chQ};
        awgChannels(bufferIQkey) = chBuffer;
    else % otherwise, we are constructing a link list
        IQ_seq = cell(nbrPatterns+calPatterns, 1);
        % decide whether to buffer on a TekAWG or on an APS
        if strcmpi(IQkey(1:3), 'tek')
            chBuffer = zeros(numSegments, seqParams.cycleLength, 'uint8');
            gated = false;
        else
            gated = false; % turn me back on when I work!
        end
        for n = 1:nbrPatterns;
            IQ_seq{n} = pg.build(patseq{floor((n-1)/seqParams.nbrRepeats)+1}, seqParams.numSteps, ChParams.delay, seqParams.fixedPt, gated);
            
            if ~gated
                for stepct = 1:seqParams.numSteps
                    [patx, paty] = pg.linkListToPattern(IQ_seq{n}, stepct);

                    % remove difference of delays
                    patx = circshift(patx, [0, ChParams.delayDiff]);
                    paty = circshift(paty, [0, ChParams.delayDiff]);
                    chBuffer((n-1)*stepct + stepct, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
                end
            end
        end
        
        for n = 1:calPatterns;
            IQ_seq{nbrPatterns + n} = pg.build(calseq{floor((n-1)/seqParams.nbrRepeats)+1}, 1, ChParams.delay, seqParams.fixedPt, gated);
            [patx, paty] = pg.linkListToPattern(IQ_seq{nbrPatterns + n}, 1);
            
            if ~gated
                % remove difference of delays
                patx = circshift(patx, [0, ChParams.delayDiff]);
                paty = circshift(paty, [0, ChParams.delayDiff]);
                chBuffer(nbrPatterns*seqParams.numSteps + n, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
            end
        end
        
        awgChannels(IQkey) = IQ_seq;
        if ~gated, awgChannels(bufferIQkey) = chBuffer; end
    end
end

% setup digitizer and slave AWG triggers (hardcoded for now)
awgChannels('TekAWG_1m1') = repmat(pg.makePattern([], seqParams.fixedPt-500, ones(100,1), seqParams.cycleLength), 1, numSegments)';
awgChannels('TekAWG_4m2') = repmat(pg.makePattern([], 5, ones(100,1), seqParams.cycleLength), 1, numSegments)';

% check for empty channels and fill them
for awgChannel = keys(awgChannels)
    awgChannel = awgChannel{1};
    
    if isempty(awgChannels(awgChannel))
        % look for a marker channel
        if (awgChannel(end-1) == 'm')
            awgChannels(awgChannel) = zeros(numSegments, seqParams.cycleLength, 'uint8');
        elseif strcmpi(awgChannel(1:3), 'tek')
            ChParams = params.(awgChannel);
            awgChannels(awgChannel) = repmat({ChParams.offset*ones(numSegments, seqParams.cycleLength, 'int16')}, 1, 2);
        else
            pg = PatternGen('linkList', 1, 'cycleLength', seqParams.cycleLength);
            patternDict(awgChannel) = struct('pg', pg);
            awgChannels(awgChannel) = {pg.build({pg.pulse('QId')}, 1, 0, seqParams.fixedPt, false)};
        end
    end
end

% plotting variables
plotColors = {'r', 'b', 'g', 'c', 'm', 'k'};
colorIdx = 0;
markerPlotColors = {'r-', 'b-', 'g-', 'c-', 'm-', 'k-'};
markerColorIdx = 0;
if makePlot
    figure();
    hold on
end

for awg = awgs
    awg = awg{1};
    basename = [seqParams.basename '-' awg seqParams.suffix];
    % create the directory if it doesn't exist
    if ~exist(['U:\AWG\' seqParams.basename '\'], 'dir')
        mkdir(['U:\AWG\' seqParams.basename '\']);
    end
    if strcmpi(awg(1:3), 'tek')
        % export Tek
        % hack... really ought to store this info somewhere or be able to
        % change in from the user interface, rather than writing it to file
        options = struct('m21_high', 2.0, 'm41_high', 2.0);
        ch12 = awgChannels([awg '_12']);
        ch34 = awgChannels([awg '_34']);
        ch1m1 = awgChannels([awg '_1m1']);
        ch1m2 = awgChannels([awg '_1m2']);
        ch2m1 = awgChannels([awg '_2m1']);
        ch2m2 = awgChannels([awg '_2m2']);
        ch3m1 = awgChannels([awg '_3m1']);
        ch3m2 = awgChannels([awg '_3m2']);
        ch4m1 = awgChannels([awg '_4m1']);
        ch4m2 = awgChannels([awg '_4m2']);
        TekPattern.exportTekSequence(tempdir, basename, ch12{1}, ch1m1, ch1m2, ch12{2}, ch2m1, ch2m2, ch34{1}, ch3m1, ch3m2, ch34{2}, ch4m1, ch4m2, options);
        disp(['Moving AWG ' awg ' file to destination']);
        pathAWG = ['U:\AWG\' seqParams.basename '\' basename '.awg'];
        movefile([tempdir basename '.awg'], pathAWG);
        
        if makePlot
            plot(ch12{1}(plotIdx,:), plotColors{ 1+mod(colorIdx, length(plotColors)) });
            plot(ch12{2}(plotIdx,:), plotColors{ 1+mod(colorIdx+1, length(plotColors)) });
            plot(ch34{1}(plotIdx,:), plotColors{ 1+mod(colorIdx+2, length(plotColors)) });
            plot(ch34{2}(plotIdx,:), plotColors{ 1+mod(colorIdx+3, length(plotColors)) });
            colorIdx = colorIdx + 4;
            plot(5000*int32(ch1m1(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx, length(markerPlotColors)) });
            plot(5000*int32(ch1m2(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+1, length(markerPlotColors)) });
            plot(5000*int32(ch2m1(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+2, length(markerPlotColors)) });
            plot(5000*int32(ch2m2(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+3, length(markerPlotColors)) });
            plot(5000*int32(ch3m1(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+4, length(markerPlotColors)) });
            plot(5000*int32(ch3m2(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+5, length(markerPlotColors)) });
            plot(5000*int32(ch4m1(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+6, length(markerPlotColors)) });
            plot(5000*int32(ch4m2(plotIdx,:)), markerPlotColors{ 1+mod(markerColorIdx+7, length(markerPlotColors)) });
        end
    else
        % export APS
        % concatenate link lists
        ch12seqs = awgChannels([awg '_12']);
        ch12seq = ch12seqs{1};
        for n = 2:length(ch12seqs)
            for m = 1:length(ch12seqs{n}.linkLists)
                ch12seq.linkLists{end+1} = ch12seqs{n}.linkLists{m};
            end
        end
        
        ch34seqs = awgChannels([awg '_34']);
        ch34seq = ch34seqs{1};
        for n = 2:length(ch34seqs)
            for m = 1:length(ch34seqs{n}.linkLists)
                ch34seq.linkLists{end+1} = ch34seqs{n}.linkLists{m};
            end
        end
        
        % export the file
        exportAPSConfig(tempdir, basename, ch12seq, ch34seq);
        disp(['Moving APS ' awg ' file to destination']);
        pathAPS = ['U:\AWG\' seqParams.basename '\' basename '.h5'];
        movefile([tempdir basename '.h5'], pathAPS);
        
        if makePlot
            pg = patternDict([awg '_12']).pg;
            [patx, paty] = pg.linkListToPattern(ch12seq, 1+mod(plotIdx-1, length(ch12seq.linkLists)));
            plot(patx, plotColors{ 1+mod(colorIdx, length(plotColors)) });
            plot(paty, plotColors{ 1+mod(colorIdx+1, length(plotColors)) });
            [patx, paty] = pg.linkListToPattern(ch34seq, 1+mod(plotIdx-1, length(ch34seq.linkLists)));
            plot(patx, plotColors{ 1+mod(colorIdx+2, length(plotColors)) });
            plot(paty, plotColors{ 1+mod(colorIdx+3, length(plotColors)) });
            colorIdx = colorIdx + 4;
        end
    end
end

end
