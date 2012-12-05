function newRBTomography(qubit1, qubit2, makePlot)

basename = 'RBT';
nbrRepeats = 1;

expct = 1;
for overlapct = 2:10
    %     if overlapct == 1
    %         numFiles = 2;
    %     else
    numFiles = 5;
    %     end;
    
    % if using SSB, set the frequency here
    SSBFreq = 0e6;
    pg1 = PatternGen(qubit1, 'SSBFreq', SSBFreq);
    pg2 = PatternGen(qubit2, 'SSBFreq', SSBFreq);
    
    %Create the pulse library
    CliffLibrary1 = cell(1,25);
    for ct = 1:25
        CliffLibrary1{ct} = CliffPulse1(ct);
    end
    
    CliffLibrary2 = cell(1,25);
    for ct = 1:25
        CliffLibrary2{ct} = CliffPulse2(ct);
    end
    
    
    for filect = 1:numFiles
        for q2tomoct = 1:2
            % load in random Clifford sequences from text file
            FID = fopen(sprintf('U:\\Marcus\\coherent-noise\\RBT_Seqs_fast_%d_F%d.txt', overlapct, filect));
            if ~FID
                error('Could not open Clifford sequence list')
            end
            
            % Read in each line
            tmpArray = textscan(FID, '%s','delimiter','\n');
            fclose(FID);
            % Split each line
            seqStrings = cellfun(@(x) textscan(x,'%d','Delimiter',','), tmpArray{1});
            
            % convert sequence strings into pulses
            patseq1 = cell(1, length(seqStrings));
            patseq2 = cell(1, length(seqStrings),1);
            for ii = 1:length(seqStrings)
                if q2tomoct == 1
                    currentSeq1 = cell(1,length(seqStrings{ii}));
                    currentSeq2 = cell(1,length(seqStrings{ii}));
                else
                    currentSeq1 = cell(1,length(seqStrings{ii})+1);
                    currentSeq2 = cell(1,length(seqStrings{ii})+1);
                end
                
                for jj = 1:length(seqStrings{ii})
                    pulseName = seqStrings{ii}(jj);
                    currentSeq1{jj} = CliffLibrary1{pulseName};
                    currentSeq2{jj} = CliffLibrary2{pulseName};
                end
                if q2tomoct == 2
                    currentSeq1{end} = pg1.pulse('QId');
                    currentSeq2{end} = pg2.pulse('Xp');
                end
                patseq1{ii} = currentSeq1;
                patseq2{ii} = currentSeq2;
            end
            
            %         calseq = arrayfun(@(x) CliffLibrary(x), [1 3 6 9 17 18 19 20 21 22 1 1 3 3], 'UniformOutput', false);
            calseq1 = {{pg1.pulse('QId')},{pg1.pulse('QId')},{pg1.pulse('QId')},{pg1.pulse('QId')},{pg1.pulse('Xp')},{pg1.pulse('Xp')},{pg1.pulse('Xp')},{pg1.pulse('Xp')}};
            calseq2 = {{pg2.pulse('QId')},{pg2.pulse('QId')},{pg2.pulse('Xp')},{pg2.pulse('Xp')},{pg2.pulse('QId')},{pg2.pulse('QId')},{pg2.pulse('Xp')},{pg2.pulse('Xp')}};
            
            % calculate an appropriate fixedPt and cycleLength
            longestSeq = max(cellfun(@length, seqStrings));
            % fixedPt should be at least 500 to accomodate the digitizer trigger
            fixedPt = max(600, longestSeq*(pg1.buffer + pg1.pulseLength)+100);
            % force fixedPt to be a multiple of 4
            fixedPt = fixedPt + mod(-fixedPt, 4);
            cycleLength = fixedPt + 2100;
            % update the pg object
            pg1.cycleLength = cycleLength;
            pg2.cycleLength = cycleLength;
            
            seqParams = struct(...
                'basename', basename, ...
                'suffix', ['_' num2str(expct)], ...
                'numSteps', 1, ...
                'nbrRepeats', nbrRepeats, ...
                'fixedPt', fixedPt, ...
                'cycleLength', cycleLength, ...
                'measLength', 2000);
            patternDict = containers.Map();
            if ~isempty(calseq1), calseq1 = {calseq1}; end
            if ~isempty(calseq2), calseq2 = {calseq2}; end
            
            qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
            IQkey1 = qubitMap.(qubit1).IQkey;
            IQkey2 = qubitMap.(qubit2).IQkey;
            
            patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patseq1}, 'calseq', calseq1, 'channelMap', qubitMap.(qubit1));
            patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patseq2}, 'calseq', calseq2, 'channelMap', qubitMap.(qubit2));
            measChannels = {'M1'};
            awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};
            
            compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
            expct = expct+1;
        end
        
    end
end

    function outPulse = CliffPulse1(cliffNum)
        %Create a pulse from a clifford Number.  Cliffords are numbered with 1 based indexing:
        
        %Figure out the approximate nutation frequency calibration from the
        %X180 and the the samplingRate
        Xp = pg1.pulse('Xp');
        xpulse = Xp.getPulse(1,0);
        nutFreq = 0.5/(sum(xpulse)/pg1.samplingRate);
        
        defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq};
        
        switch cliffNum
            case 1
                %Identity gate
                outPulse = pg1.pulse('QId');
            case 2
                %X90
                outPulse = pg1.pulse('X90p');
            case 3
                %X180
                outPulse = pg1.pulse('Xp');
            case 4
                %Xm90
                outPulse = pg1.pulse('X90m');
            case 5
                %Y90
                outPulse = pg1.pulse('Y90p');
            case 6
                %Y180
                outPulse = pg1.pulse('Yp');
            case 7
                %Ym90
                outPulse = pg1.pulse('Y90m');
            case 8
                %Z90
                outPulse = pg1.pulse('QId', 'rotAngle', pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
            case 9
                %Z180
                outPulse = pg1.pulse('QId', 'rotAngle', pi, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
            case 10
                %Z90m
                outPulse = pg1.pulse('QId', 'rotAngle', -pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
            case 11
                %X+Y 180
                outPulse = pg1.pulse('Up', 'angle', pi/4);
            case 12
                %X-Y 180
                outPulse = pg1.pulse('Up', 'angle', -pi/4);
            case 13
                %X+Z (Hadamard)
                outPulse = pg1.pulse('Up', 'polarAngle', pi/4, 'aziAngle', 0, defaultParams{:});
            case 14
                %X-Z (Hadamard)
                outPulse = pg1.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi, defaultParams{:});
            case 15
                %Y+Z (Hadamard)
                outPulse = pg1.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi/2, defaultParams{:});
            case 16
                %Y-Z (Hadamard)
                outPulse = pg1.pulse('Up', 'polarAngle', pi/4, 'aziAngle', -pi/2, defaultParams{:});
            case 17
                %X+Y+Z 120
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
            case 18
                %X+Y+Z -120 (equivalent to -X-Y-Z 120)
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
            case 19
                %X-Y+Z 120
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
            case 20
                %X-Y+Z -120 (equivalent to -X+Y-Z 120)
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
            case 21
                %X+Y-Z 120
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
            case 22
                %X+Y-Z -120 (equivalent to -X-Y+Z 120
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
            case 23
                %-X+Y+Z 120
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
            case 24
                %-X+Y+Z -120 (equivalent to X-Y-Z 120
                outPulse = pg1.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
            case 25
                % 25 is a placeholder for whatever gate we wish to
                % interrogate
                outPulse = CliffPulse1(1);
            otherwise
                error('Cliffords must be numbered between 1 and 24');
        end
        
    end

    function outPulse = CliffPulse2(cliffNum)
        if cliffNum == 25
            outPulse = pg2.pulse('Xp');
        else
            outPulse = pg2.pulse('QId');
        end
    end

end