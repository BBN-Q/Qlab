function SingleQProcess(qubit, makePlot)

basename = 'SingleQProcess';
fixedPt = 1000;
cycleLength = 5000;
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);
pg2 = PatternGen('q2', 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);
patseq = {};

pulses = {'QId', 'Xp', 'X90p', 'Y90p', 'X90m', 'Y90m'};
pulseLib = struct();
for i = 1:length(pulses)
    pulseLib.(pulses{i}) = pg.pulse(pulses{i});
end

%The map we want to characterize
%Figure out the approximate nutation frequency calibration from the
%X180 and the the samplingRate
% Xp = pg.pulse('Xp');
% xpulse = Xp(1,0);
% nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);
% 
% % process = pg.pulse('Utheta', 'rotAngle', -2*pi/3, 'polarAngle', acos(1/sqrt(3)) , 'aziAngle', pi/4, 'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', 0);
% process = pg.pulse('QId', 'rotAngle', pi/2, 'polarAngle', 0, 'aziAngle', 0,'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', 0);
%process = pg.pulse('Xtheta', 'amp', qParams.pi2Amp*(1.2));
process = pg.pulse('QId');
for ii = 1:6
    for jj = 1:6
        patseq{end+1} = { pulseLib.(pulses{ii}), process, pulseLib.(pulses{jj}), pg.pulse('QId') };
        patseq{end+1} = { pulseLib.(pulses{ii}), process, pulseLib.(pulses{jj}), pg.pulse('QId') };
    end
end
               
patseq2 = repmat({{pg2.pulse('Xp'), pg2.pulse('QId'), pg2.pulse('QId')}, {pg2.pulse('Xp'), pg2.pulse('QId'), pg2.pulse('Xp')}}, 1, 36);

calseq = {};
calseq{end+1} = {pg.pulse('QId')};
calseq{end+1} = {pg.pulse('QId')};
calseq{end+1} = {pg.pulse('Xp')};
calseq{end+1} = {pg.pulse('Xp')};

calseq2 = {};
calseq2{end+1} = {pg2.pulse('QId')};
calseq2{end+1} = {pg2.pulse('Xp')};
calseq2{end+1} = {pg2.pulse('QId')};
calseq2{end+1} = {pg2.pulse('Xp')};

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
if ~isempty(calseq2), calseq2 = {calseq2}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;
IQkey2 = qubitMap.('q2').IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patseq2}, 'calseq', calseq2, 'channelMap', qubitMap.('q2'));

measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

end
