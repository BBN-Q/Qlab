function newRBTomography(qubit, makePlot)

basename = 'RBT';
fixedPt = 7000;
cycleLength = 9000;
nbrRepeats = 1;

delta = -0.64;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

% load in random Clifford sequences from text file
FID = fopen('RBT_ISeqs.txt');
if ~FID
    error('Could not open Clifford sequence list')
end

% Read in each line
tmpArray = textscan(FID, '%s','delimiter','\n');
fclose(FID);
% Split each line
seqStrings = cellfun(@(x) textscan(x,'%d','Delimiter',','), tmpArray{1});

%Create the pulse library
CliffLibrary = cell(1,24);
for ct = 1:24
    CliffLibrary{ct} = CliffPulse(ct);
end

% convert sequence strings into pulses
pulseLibrary = containers.Map();
for ii = 1:length(seqStrings)
    currentSeq = cell(1,length(seqStrings{ii}));
    for jj = 1:length(seqStrings{ii})
        pulseName = seqStrings{ii}(jj);
        currentSeq{jj} = CliffLibrary{pulseName};
    end
    patseq{ii} = currentSeq(1:jj);
end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};

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

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

    function outPulse = CliffPulse(cliffNum)
        %Create a pulse from a clifford Number.  Cliffords are numbered with 1 based indexing:
        
        %Figure out the approximate nutation frequency calibration from the
        %X180 and the the samplingRate
        Xp = pg.pulse('Xp');
        xpulse = Xp.getPulse(1,0);
        nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);
        
        defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', delta};
        
        switch cliffNum
            case 1
                %Identity gate
                outPulse = pg.pulse('QId');
            case 2
                %X90
                outPulse = pg.pulse('X90p');
            case 3
                %X180
                outPulse = pg.pulse('Xp');
            case 4
                %Xm90
                outPulse = pg.pulse('X90m');
            case 5
                %Y90
                outPulse = pg.pulse('Y90p');
            case 6
                %Y180
                outPulse = pg.pulse('Yp');
            case 7
                %Ym90
                outPulse = pg.pulse('Y90m');
            case 8
                %Z90
                outPulse = pg.pulse('QId', 'rotAngle', pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
            case 9
                %Z180
                outPulse = pg.pulse('QId', 'rotAngle', pi, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
            case 10
                %Z90m
                outPulse = pg.pulse('QId', 'rotAngle', -pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
            case 11
                %X+Y 180
                outPulse = pg.pulse('Up', 'angle', pi/4);
            case 12 
                %X-Y 180
                outPulse = pg.pulse('Up', 'angle', -pi/4);
            case 13
                %X+Z (Hadamard)
                outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', 0, defaultParams{:});
            case 14
                %X-Z (Hadamard)
                outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi, defaultParams{:});
            case 15
                %Y+Z (Hadamard)
                outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi/2, defaultParams{:});
            case 16
                %Y-Z (Hadamard)
                outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', -pi/2, defaultParams{:});
            case 17
                %X+Y+Z 120
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
            case 18
                %X+Y+Z -120 (equivalent to -X-Y-Z 120)
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
            case 19
                %X-Y+Z 120
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
            case 20
                %X-Y+Z -120 (equivalent to -X+Y-Z 120)
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
            case 21
                %X+Y-Z 120
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
            case 22
                %X+Y-Z -120 (equivalent to -X-Y+Z 120
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
            case 23
                %-X+Y+Z 120
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
            case 24
                %-X+Y+Z -120 (equivalent to X-Y-Z 120
                outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
            otherwise
                error('Cliffords must be numbered between 1 and 24');
        end
        
    end

end