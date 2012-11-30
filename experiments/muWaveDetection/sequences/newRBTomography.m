function newRBTomography(qubit, makePlot)

basename = 'RBT';
nbrRepeats = 1;

expct = 1;
for overlapct = 1:10
%     if overlapct == 1
%         numFiles = 2;
%     else
        numFiles = 8;
%     end;

    % if using SSB, set the frequency here
    SSBFreq = 0e6;
    pg = PatternGen(qubit, 'SSBFreq', SSBFreq);

    %Create the pulse library
    CliffLibrary = cell(1,25);
    for ct = 1:25
        CliffLibrary{ct} = CliffPulse(ct);
    end

    for filect = 1:numFiles
        % load in random Clifford sequences from text file
        FID = fopen(sprintf('U:\\Marcus\\RBT_Seqs_fast_%d_F%d.txt', overlapct, filect));
        if ~FID
            error('Could not open Clifford sequence list')
        end
        
        % Read in each line
        tmpArray = textscan(FID, '%s','delimiter','\n');
        fclose(FID);
        % Split each line
        seqStrings = cellfun(@(x) textscan(x,'%d','Delimiter',','), tmpArray{1});
        
        % convert sequence strings into pulses
        for ii = 1:length(seqStrings)
            currentSeq = cell(1,length(seqStrings{ii}));
            for jj = 1:length(seqStrings{ii})
                pulseName = seqStrings{ii}(jj);
                currentSeq{jj} = CliffLibrary{pulseName};
            end
            patseq{ii} = currentSeq(1:jj);
        end
        
%         calseq = arrayfun(@(x) CliffLibrary(x), [1 3 6 9 17 18 19 20 21 22 1 1 3 3], 'UniformOutput', false);
        calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};
        
        % calculate an appropriate fixedPt and cycleLength
        longestSeq = max(cellfun(@length, seqStrings));
        % fixedPt should be at least 500 to accomodate the digitizer trigger
        fixedPt = max(600, longestSeq*(pg.buffer + pg.pulseLength)+100);
        % force fixedPt to be a multiple of 4
        fixedPt = fixedPt + mod(-fixedPt, 4);
        cycleLength = fixedPt + 2100;
        % update the pg object
        pg.cycleLength = cycleLength;
        
        seqParams = struct(...
            'basename', basename, ...
            'suffix', ['_' num2str(expct)], ...
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
        expct = expct+1;
    end
    
end

    function outPulse = CliffPulse(cliffNum)
        %Create a pulse from a clifford Number.  Cliffords are numbered with 1 based indexing:
        
        %Figure out the approximate nutation frequency calibration from the
        %X180 and the the samplingRate
        Xp = pg.pulse('Xp');
        xpulse = Xp.getPulse(1,0);
        nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);
        
        defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq};
        
        switch cliffNum
            case 1
                %Identity gate
                outPulse = pg.pulse('QId', 'width', 0);
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
                outPulse = pg.pulse('QId', 'rotAngle', pi/2, 'polarAngle', 0, 'aziAngle', 0, 'width', 0, defaultParams{:});
            case 9
                %Z180
                outPulse = pg.pulse('QId', 'rotAngle', pi, 'polarAngle', 0, 'aziAngle', 0, 'width', 0, defaultParams{:});
            case 10
                %Z90m
                outPulse = pg.pulse('QId', 'rotAngle', -pi/2, 'polarAngle', 0, 'aziAngle', 0, 'width', 0, defaultParams{:});
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
            case 25
                % 25 is a placeholder for whatever gate we wish to
                % interrogate
                outPulse = CliffPulse(13);
            otherwise
                error('Cliffords must be numbered between 1 and 24');
        end
        
    end

end