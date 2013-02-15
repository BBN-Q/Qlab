function output = LinkListSequences(sequence)

%% APS Enhanced Link List Unit Test
%%
%% Gets Pattern Generator and produces link lists from pattern generator
%% And ELL link lists and plots for comparision
%% May be Called Using Some Varient of deviceDrivers.APS.LinkListFormatUnitTest

%% A number of the sequences in this script are broken as of 5/15/12
%
%  1 - Works
%  2 - Works
%  3 - No output
%  4 - Works
%  5 - crash in pg.build
%  6 - crash in pg.build
%  7 - Entry count < 3 no output


% Uses PatternGen Link List Generator to develop link lists

if exist('../../common/src/','dir')
    % part of experiment framework
    addpath('../../common/src/','-END');
    addpath('../../common/src/util/','-END');
else
    % standalone
    addpath('../','-END');
end

if ~exist('sequence', 'var') || isempty(sequence)
    sequence = 1;
end

% common sequency parameteres
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
cycleLength = 10000;
fixedPt = 6000;
offset = 8192;

switch sequence
    case 1
        % Echo Sequence
        
        piAmp = 8000;
        piWidth = 40;
        pi2Width = 20;
        buffer = 0;
        
        pulseType = 'gaussian';
        pg = PatternGen('dPulseType', pulseType, 'dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, ...
                        'dPulseLength', piWidth, 'dBuffer', buffer, 'cycleLength', cycleLength, ...
                        'linkList', 1);
        
        numsteps = 50;
        %numsteps = 4;
        %delay = -12;
        stepsize = 15;
        delaypts = 0:stepsize:(numsteps-1)*stepsize;
        
        patSeqLL = {{
            pg.pulse('X90p'), ...
            pg.pulse('QId', 'width', delaypts), ...
            pg.pulse('Xp'), ...
            pg.pulse('QId', 'width', delaypts), ...
            pg.pulse('X90p')},...
            };
        
        pg2 = PatternGen('dPulseType', pulseType, 'dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, ...
                         'dPulseLength', piWidth, 'dBuffer', buffer, 'cycleLength', cycleLength, ...
                         'linkList', 0);
        patseq = {
            pg2.pulse('X90p'), ...
            pg2.pulse('QId', 'width', delaypts), ...
            pg2.pulse('Xp'), ...
            pg2.pulse('QId', 'width', delaypts), ...
            pg2.pulse('X90p')...
        };
    case 2
        % Rabi Amp Sequence
        
        piAmp = 8000; % not in orginal script
        
        numsteps = 41;
        stepsize = 200;
        sigma = 10;
        pulseLength = 4*sigma;
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, ...
                        'dPulseLength', pulseLength, 'cycleLength', cycleLength, 'linkList', 1);
        
        amps = 0:stepsize:(numsteps-1)*stepsize;
        patSeqLL = {
            {pg.pulse('Xtheta', 'amp', amps)}};
        
        pg2 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma,...
                         'dPulseLength', pulseLength, 'cycleLength', cycleLength, 'linkList', 0);
                     
        patseq = {{pg.pulse('Xtheta', 'amp', amps)}};
            
    case 3
        % Ramsey
        
        numsteps = 100;
        piWidth = 27;
        piAmp = 8000;
        pi2Width = 14;
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dPulseLength', piWidth, ...
                        'cycleLength', cycleLength, 'linkList', 1);
        
        stepsize = 5;
        delaypts = 0:stepsize:(numsteps-1)*stepsize;
        patSeqLL = {...
            {pg.pulse('X90p', 'pType', 'square'), ...
            pg.pulse('QId', 'width', delaypts), ...
            pg.pulse('X90p', 'pType', 'square')} ...
            };
        
        pg2 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dPulseLength', piWidth, ...
                        'cycleLength', cycleLength, 'linkList', 0);
        patseq = {...
            {pg.pulse('X90p', 'pType', 'square'), ...
            pg.pulse('QId', 'width', delaypts), ...
            pg.pulse('X90p', 'pType', 'square')} ...
            };
    
    case 4
        % URamseySequence
        
        numsteps = 50;
        piAmp = 8000;
        sigma = 6;
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, 'dPulseLength', 6*sigma, ...
                        'cycleLength', cycleLength, 'linkList', 1);
        
        stepsize = 10;
        delaypts = 0:stepsize:(numsteps-1)*stepsize;
        anglepts = 0:pi/8:(numsteps-1)*pi/8;
        
        idx = 1:10;
        numsteps = length(idx);
        delaypts = delaypts(idx);
        anglepts = anglepts(idx);
        
        patSeqLL = {...
            {pg.pulse('X90p'), ...
            pg.pulse('QId', 'width', delaypts), ...
            pg.pulse('U90p', 'angle', anglepts)} ...
            };
        
        pg2 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, 'dPulseLength', 6*sigma, ...
                        'cycleLength', cycleLength, 'linkList', 0);

        patseq = {...
            {pg.pulse('X90p'), ...
            pg.pulse('QId', 'width', delaypts), ...
            pg.pulse('U90p', 'angle', anglepts)} ...
            };
    case 5
        % AllXY Sequencce
        
        bufferPadding = 20;
        
        numsteps = 1;
        piAmp = 6300;
        pi2Amp = 3150;
        sigma = 4;
        pulseLength = 4*sigma;
        delay = -12; % unit test fails with delay = -10
        buffer = 4;
        
        T = [1 0; 0 1.15];
        
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, ...
            'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, ...
            'cycleLength', cycleLength, 'linkList', 1);
        
        pg2 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, ...
            'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, ...
            'cycleLength', cycleLength, 'linkList', 0);
        
        % ground state:
        % QId
        % Xp Xm
        % Yp Ym
        % Xp Xp
        % Yp Yp
        % Xp Yp
        % Yp Xp
        % Yp Xm
        % Xp Ym
        
        patSeqLL{1} = {{'QId'}};
        patSeqLL{2} = {{'Xp'},{'Xm'}};
        patSeqLL{3} = {{'Yp'},{'Ym'}};
        patSeqLL{4} = {{'Xp'},{'Xp'}};
        patSeqLL{5} = {{'Yp'},{'Yp'}};
        
        
        patSeqLL{6} = {{'Xp'},{'Yp'}};
        patSeqLL{7} = {{'Yp'},{'Xp'}};
        
        patSeqLL{8} = {{'Yp'},{'Xm'}};
        patSeqLL{9} = {{'Xp'},{'Ym'}};
        
        % superposition state:
        % -1 * eps error
        % X90p
        % Y90p
        % X90m
        % Y90m
        
        % 0 * eps error (phase sensitive)
        % X90p Y90p
        % Y90p X90p
        % X90m Y90m
        % Y90m X90m
        
        % +1 * eps error
        % Xp Y90p
        % Yp X90p
        % Xp Y90m
        % Yp X90m
        % X90p Yp
        % Y90p Xp
        
        % +3 * eps error
        % Xp X90p
        % Yp Y90p
        % Xm X90m
        % Ym Y90m
        
        
        patSeqLL{10} = {{'X90p'}};
        patSeqLL{11} = {{'Y90p'}};
        patSeqLL{12} = {{'X90m'}};
        patSeqLL{13} = {{'Y90m'}};
        
        patSeqLL{14} = {{'X90p'},{'Y90p'}};
        patSeqLL{15} = {{'Y90p'},{'X90p'}};
        patSeqLL{16} = {{'X90m'},{'Y90m'}};
        patSeqLL{17} = {{'Y90m'},{'X90m'}};
        
        patSeqLL{18} = {{'Xp'},{'Y90p'}};
        patSeqLL{19} = {{'Yp'},{'X90p'}};
        patSeqLL{20} = {{'Xp'},{'Y90m'}};
        patSeqLL{21} = {{'Yp'},{'X90m'}};
        patSeqLL{22} = {{'X90p'},{'Yp'}};
        patSeqLL{23} = {{'Y90p'},{'Xp'}};
        
        patSeqLL{24} = {{'Xp'},{'X90p'}};
        patSeqLL{25} = {{'Yp'},{'X90p'}};
        patSeqLL{26} = {{'Xm'},{'X90m'}};
        patSeqLL{27} = {{'Ym'},{'X90m'}};
        
        % excited state;
        % Xp
        % Xm
        % Yp
        % Ym
        % X90p X90p
        % X90m X90m
        % Y90p Y90p
        % Y90m Y90m
        
        patSeqLL{28} = {{'QId'},{'Xp'}};
        patSeqLL{29} = {{'QId'},{'Xm'}};
        patSeqLL{30} = {{'QId'},{'Yp'}};
        patSeqLL{31} = {{'QId'},{'Ym'}};
        
        patSeqLL{32} = {{'X90p'},{'X90p'}};
        patSeqLL{33} = {{'X90m'},{'X90m'}};
        patSeqLL{34} = {{'Y90p'},{'Y90p'}};
        patSeqLL{35} = {{'Y90m'},{'Y90m'}};
        
        patseq = patSeqLL;
        
        
    case 6
        fixedPt = 7000; % override fixedPt
        numsteps = 50;
        
        piAmp = 6000;
        pi2Amp = 3000;
        
        sigma = 6;
        pulseLength = 6*sigma;

        T = eye(2);
        
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', 'drag', ...
                        'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength, ...
                         'linkList', 1);
                     
        pg2 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', 'drag', ...
                        'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength, ...
                         'linkList', 0);
                     
        sequenceFile = 'RBsequences.txt';
        
        % check for sequence file in current directory
        if ~exist(sequenceFile, 'file')
            % if not there assume that we are in the experiment
            % framework and look via a relative path;
            srcPath =  '../../experiments/muWaveDetection/sequences/';
            sequenceFile = [srcPath sequenceFile];
            if ~exist(sequenceFile,'file')
                error('Cound not find Randomized Benchmarking Sequence File');
            end
        end
        
        % if we are here we have found the file @ sequenceFile
        
        % read file and create pulse library
        %pulseLibrary = containers.Map();
        filedata =  fileread(sequenceFile);
        patSeqLL = {};
        while ~isempty(filedata)
            % must use sprintf to convert \n to actual new line
            [line filedata] = strtok(filedata,sprintf('\n'));
            pulseList = {};
        %    pulseFunctions = {};
            while ~isempty(line)
                [pulseName line] = strtok(line,char(9));
                pulseList{end+1} = {pulseName};
                
          %       if ~isKey(pulseLibrary, pulseName)
          %          pulseLibrary(pulseName) = pg.pulse(pulseName);
          %      end
                %pulseFunctions{end+1} = pulseLibrary(pulseName);
            end
            patSeqLL{end+1} = pulseList;
            %allPatseq{end+1} = pulseFunctions;
        end
        
        patseq = patSeqLL;
    case 7
        % Rabi width sequence        
        fixedPt = 7000;
        cycleLength = 12000;
        piAmp = 8000;
        buffer = 4;

        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dBuffer', buffer, 'cycleLength', cycleLength, ...
                        'linkList', 1);
                    
        pg2 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dBuffer', buffer, 'cycleLength', cycleLength, ...
                        'linkList', 0);

        numsteps = 10;
        minWidth = 0;
        stepsize = 8;
        pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

        patSeqLL = {...
            {pg.pulse('Xp', 'width', pulseLength, 'pType', 'square')}...
            };
        
        patseq = {...
            {pg2.pulse('Xp', 'width', pulseLength, 'pType', 'square')}...
            };
        
end

% build as patern generator link list


numSequences = length(patSeqLL);
output = [];
h = waitbar(0,'Buildling Sequence Link List');
for seq = 1:numSequences
    waitbar(seq/numSequences,h);

    llpatxy = pg.build(patSeqLL{seq}, numsteps, delay, fixedPt);
    
    
    flds = {'llpatxy','patseq','numsteps','cycleLength','patseq','delay','fixedPt', ...
        'pg','bufferPadding','bufferReset','bufferDelay','offset'};
    
    
    for i = 1:length(flds)
        output{seq}.(flds{i}) = eval(flds{i});
    end
end
close(h);
end
