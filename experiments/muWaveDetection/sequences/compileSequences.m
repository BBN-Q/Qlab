function compileSequences(seqParams, patternDict, measChannels, awgs, makePlot)
% inputs:
% seqParams - structure of:
%   basename - string specifying the target folder and file name
%   suffix - string to tack onto the end of the basename
%   numSteps
%   nbrRepeats
%   fixedPt
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
nbrPatterns = length(tempPatterns.patseq);
calPatterns = length(tempPatterns.calseq);
numSegments = nbrPatterns*seqParams.numSteps + calPatterns;
fprintf('Number of sequences: %i\n', numSegments*seqParams.nbrRepeats);

% inject measurement sequences
measLength = 0;
for measCh = measChannels
    measCh = measCh{1};
    IQkey = qubitMap.(measCh).IQkey;
    ChParams = params.(IQkey);
    %Override the SSBFreq for constant autodyne phase
    mFreq = params.(measCh).SSBFreq;
    pgM = PatternGen(measCh, 'SSBFreq', 0);    
    % shift the delay to include the measurement length
    params.(IQkey).delay = ChParams.delay + pgM.pulseLength;
    measSeq = {{pgM.pulse('M', 'modFrequency',mFreq)}};
    measLength = max(measLength, pgM.pulseLength);
    patternDict(IQkey) = struct('pg', pgM, 'patseq', {repmat(measSeq, 1, nbrPatterns)}, 'calseq', {repmat(measSeq,1,calPatterns)}, 'channelMap', qubitMap.(measCh));
end

%Setup appropriate cycleLength with buffer for trailing blips
seqParams.cycleLength = seqParams.fixedPt + measLength + 240;

% keep track of whether all channels on all AWGs are used
awgChannels = struct();
for awg = awgs
    awg = awg{1};
    awgChannels.([awg '_12']) = [];
    awgChannels.([awg '_34']) = [];
    if strcmpi(awg(1:3), 'tek') % create marker channels if a TekAWG
        awgChannels.([awg '_1m1']) = [];
        awgChannels.([awg '_2m1']) = [];
        awgChannels.([awg '_3m1']) = [];
        awgChannels.([awg '_4m1']) = [];
        awgChannels.([awg '_1m2']) = [];
        awgChannels.([awg '_2m2']) = [];
        awgChannels.([awg '_3m2']) = [];
        awgChannels.([awg '_4m2']) = [];
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
    %Update to have uniform cycleLength's
    pg.cycleLength = seqParams.cycleLength;
    patseq = patternDict(IQkey).patseq;
    calseq = patternDict(IQkey).calseq;
    
    % if not in link list mode, allocate memory for patterns
    if (~pg.linkListMode)
        chI = zeros(numSegments, seqParams.cycleLength, 'int16');
        chQ = chI;
        chBuffer = zeros(numSegments, seqParams.cycleLength, 'uint8');
        
        for n = 1:nbrPatterns;
            for stepct = 1:seqParams.numSteps
                [patx paty] = pg.getPatternSeq(patseq{n}, stepct, ChParams.delay, seqParams.fixedPt);
                
                chI((n-1)*seqParams.numSteps + stepct, :) = patx + ChParams.offset;
                chQ((n-1)*seqParams.numSteps + stepct, :) = paty + ChParams.offset;
                chBuffer((n-1)*seqParams.numSteps + stepct, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
            end
        end
        
        for n = 1:calPatterns;
            [patx paty] = pg.getPatternSeq(calseq{n}, 1, ChParams.delay, seqParams.fixedPt);
            
            chI(nbrPatterns*seqParams.numSteps + n, :) = patx + ChParams.offset;
            chQ(nbrPatterns*seqParams.numSteps + n, :) = paty + ChParams.offset;
            chBuffer(nbrPatterns*seqParams.numSteps + n, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
        end
        
        awgChannels.(IQkey) = {chI, chQ};
        if isempty(awgChannels.(bufferIQkey))
            awgChannels.(bufferIQkey) = chBuffer;
        else
            awgChannels.(bufferIQkey) = awgChannels.(bufferIQkey) | chBuffer;
        end
    else % otherwise, we are constructing a link list
        IQ_seq = cell(nbrPatterns+calPatterns, 1);
        % decide whether to buffer on a TekAWG or on an APS
        if strcmpi(bufferIQkey(1:3), 'tek')
            chBuffer = zeros(numSegments, seqParams.cycleLength, 'uint8');
            gated = false;
        else
            gated = true;
        end
        for n = 1:nbrPatterns;
            IQ_seq{n} = pg.build(patseq{n}, seqParams.numSteps, ChParams.delay, seqParams.fixedPt, gated);
            
            if ~gated
                for stepct = 1:seqParams.numSteps
                    [patx, paty] = pg.linkListToPattern(IQ_seq{n}{stepct});
                    
                    % remove difference of delays
                    patx = circshift(patx, [0, ChParams.delayDiff]);
                    paty = circshift(paty, [0, ChParams.delayDiff]);
                    chBuffer((n-1)*seqParams.numSteps + stepct, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
                end
            end
        end
        
        for n = 1:calPatterns;
            IQ_seq{nbrPatterns + n} = pg.build(calseq{n}, 1, ChParams.delay, seqParams.fixedPt, gated);
            [patx, paty] = pg.linkListToPattern(IQ_seq{nbrPatterns + n}{1});
            
            if ~gated
                % remove difference of delays
                patx = circshift(patx, [0, ChParams.delayDiff]);
                paty = circshift(paty, [0, ChParams.delayDiff]);
                chBuffer(nbrPatterns*seqParams.numSteps + n, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
            end
        end
        
        %Flatten the linklist cell array
        awgChannels.(IQkey) = struct('waveforms', pg.pulseCollection, 'linkLists', {[IQ_seq{:}]});

        if ~gated
            if isempty(awgChannels.(bufferIQkey))
                awgChannels.(bufferIQkey) = chBuffer;
            else
                awgChannels.(bufferIQkey) = awgChannels.(bufferIQkey) | chBuffer;
            end
        end
    end
end

% setup digitizer and slave AWG triggers 
digitizerTrigChan = qubitMap.digitizerTrig.channel;
slaveTrigChan = qubitMap.slaveTrig.channel;

%Helper function to map out IQ channel and marker number for BBNAPS units
    function [markerIQkey, markerNum] = map_APS_digital(chanStr)
        %Extract the AWG and channel
        channelInfo = regexp(chanStr, '(?<AWGName>[\w\d]+)_(?<chNum>\d)m(?<markerNum>\d)', 'names');
        %Associate it with the correct IQ pair
        chNum = str2double(channelInfo.chNum);
        channelPairs = {'12', '34'};
        markerIQkey = [channelInfo.AWGName, '_' channelPairs{1+floor((chNum-1)/2)}];
        markerNum = 2 - mod(chNum,2);
    end

if (strncmp(digitizerTrigChan,'TekAWG', 6))
    awgChannels.(digitizerTrigChan) = repmat(uint8(pg.makePattern([], seqParams.fixedPt-500, ones(100,1), seqParams.cycleLength)), 1, numSegments)';
elseif (strncmp(digitizerTrigChan,'BBNAPS', 6))
    [tmpIQkey, tmpMarkerNum] = map_APS_digital(digitizerTrigChan);
    %If there is nothing on the channel then we need to add something
    if isempty(awgChannels.(tmpIQkey))
        create_empty_APS_channel(tmpIQkey);
    end
    awgChannels.(tmpIQkey).linkLists = PatternGen.addTrigger(awgChannels.(tmpIQkey).linkLists, seqParams.fixedPt-500, 1, tmpMarkerNum);
end

if (strncmp(slaveTrigChan,'TekAWG', 6))
    awgChannels.(slaveTrigChan) = repmat(uint8(pg.makePattern([], 5, ones(100,1), seqParams.cycleLength)), 1, numSegments)';
elseif (strncmp(slaveTrigChan,'BBNAPS', 6))
    [tmpIQkey, tmpMarkerNum] = map_APS_digital(slaveTrigChan);
    %If there is nothing on the channel then we need to add something
    if isempty(awgChannels.(tmpIQkey))
        create_empty_APS_channel(tmpIQkey);
    end
    awgChannels.(tmpIQkey).linkLists = PatternGen.addTrigger(awgChannels.(tmpIQkey).linkLists, 1, 0, tmpMarkerNum);
end

% check for empty channels and fill them
%If the entire AWG is empty then drop it 
removeAWGs = [];
for awgct = 1:length(awgs)
    allAWGChannelNames = fieldnames(awgChannels);
    curAWGChannelNames = allAWGChannelNames(strncmp(allAWGChannelNames, awgs{awgct}, length(awgs{awgct})));
    if all(cellfun(@(x) isempty(awgChannels.(x)), curAWGChannelNames));
        for tmpChan = curAWGChannelNames'
            awgChannels = rmfield(awgChannels, tmpChan{1});
        end
        removeAWGs(end+1) = awgct;
    end
end
awgs(removeAWGs) = [];    

for awgChannel = fieldnames(awgChannels)'
    awgChannel = awgChannel{1};
    if isempty(awgChannels.(awgChannel))
        % look for a marker channel
        if (awgChannel(end-1) == 'm')
            awgChannels.(awgChannel) = zeros(numSegments, seqParams.cycleLength, 'uint8');
        elseif strcmpi(awgChannel(1:3), 'tek')
            ChParams = params.(awgChannel);
            awgChannels.(awgChannel) = repmat({ChParams.offset*ones(numSegments, seqParams.cycleLength, 'int16')}, 1, 2);
        else
            create_empty_APS_channel(awgChannel)
        end
    end
end




awgFiles = {};
for awg = awgs
    awg = awg{1};
    basename = [seqParams.basename '-' awg seqParams.suffix];
    % create the directory if it doesn't exist
    if ~exist(fullfile(getpref('qlab', 'awgDir'), seqParams.basename), 'dir')
        mkdir(fullfile(getpref('qlab', 'awgDir'), seqParams.basename));
    end
    if strcmpi(awg(1:3), 'tek')
        % export Tek
        % hack... really ought to store this info somewhere or be able to
        % change in from the user interface, rather than writing it to file
        options = struct('m11_high', 2.5, 'm12_high', 2.5, 'm21_high', 2.5, 'm22_high', 2.5, 'm31_high', 2.5,...
            'm32_high', 2.5, 'm41_high', 2.5, 'm42_high', 2.5, 'nbrRepeats', seqParams.nbrRepeats);
        TekPattern.exportTekSequence(tempdir, basename, extract_Tek_channel(awg), options);
        disp(['Moving AWG ' awg ' file to destination']);
        pathAWG = fullfile(getpref('qlab', 'awgDir'), seqParams.basename, [basename '.awg']);
        movefile([tempdir basename '.awg'], pathAWG);
        awgFiles{end+1} = fullfile(getpref('qlab', 'awgDir'), seqParams.basename, [basename '.h5']);
        
        if makePlot
            %Dump the pulses to a h5 file
            TekPattern.waveforms2h5(fullfile(getpref('qlab', 'awgDir'), seqParams.basename, [basename '.h5']), extract_Tek_channel(awg));
        end
    else
        % export APS
        APSPattern.exportAPSConfig(tempdir, basename, seqParams.nbrRepeats, awgChannels.([awg, '_12']), awgChannels.([awg, '_34']))
        disp(['Moving APS ' awg ' file to destination']);
        pathAPS = fullfile(getpref('qlab', 'awgDir'), seqParams.basename, [basename '.h5']);
        movefile([tempdir basename '.h5'], pathAPS);
        awgFiles{end+1} = pathAPS;
        
    end
end

%If we are plotting then call the Python plotter GUI
if makePlot
    pythonPathCmd = sprintf('set PYTHONPATH=%s & ',getpref('qlab', 'PyQLabDir'));
    if ispc
        pythonLauncher = 'pythonw';
    else
        pythonLauncher = 'python';
    end
    [status, result] = system([pythonPathCmd,  pythonLauncher, ' "', fullfile(getpref('qlab', 'PyQLabDir'), 'QGL',...
                    'PulseSequencePlotter.py'), '" --AWGFiles ', sprintf('"%s" ', awgFiles{:}), ' & exit &']);
end

    %Helper function to extract a particular Tek's channels from the AWGChannel
    function tmpAWGChannels = extract_Tek_channel(tekName)
        tmpAWGChannels = struct();
        tmpIQ = awgChannels.([tekName '_12']);
        tmpAWGChannels.('ch1') = tmpIQ{1};
        tmpAWGChannels.('ch2') = tmpIQ{2};
        tmpIQ = awgChannels.([tekName '_34']);
        tmpAWGChannels.('ch3') = tmpIQ{1};
        tmpAWGChannels.('ch4') = tmpIQ{2};
        
        tmpAWGChannels.('ch1m1') = awgChannels.([tekName '_1m1']);
        tmpAWGChannels.('ch1m2') = awgChannels.([tekName '_1m2']);
        tmpAWGChannels.('ch2m1') = awgChannels.([tekName '_2m1']);
        tmpAWGChannels.('ch2m2') = awgChannels.([tekName '_2m2']);
        tmpAWGChannels.('ch3m1') = awgChannels.([tekName '_3m1']);
        tmpAWGChannels.('ch3m2') = awgChannels.([tekName '_3m2']);
        tmpAWGChannels.('ch4m1') = awgChannels.([tekName '_4m1']);
        tmpAWGChannels.('ch4m2') = awgChannels.([tekName '_4m2']);
    end

    %Helper function to create an empty APS channel
    function create_empty_APS_channel(awgChannel)
        pg = PatternGen('linkListMode', 1, 'cycleLength', seqParams.cycleLength);
        patternDict(awgChannel) = struct('pg', pg);
        awgChannels.(awgChannel).linkLists = pg.build({pg.pulse('QId')}, 1, 0, seqParams.fixedPt, false);
        awgChannels.(awgChannel).waveforms = pg.pulseCollection;
    end

end




