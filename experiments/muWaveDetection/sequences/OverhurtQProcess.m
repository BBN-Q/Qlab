function OverhurtQProcess(varargin)

%varargin assumes qubit and then makePlot
qubit = 'q1';
makePlot = true;

if length(varargin) == 1
    qubit = varargin{1};
elseif length(varargin) == 2
    qubit = varargin{1};
    makePlot = varargin{2};
elseif length(varargin) > 2
    error('Too many input arguments.')
end

basename = 'OverhurtQProcess';
fixedPt = 3000;
cycleLength = 20000;
nbrRepeats = 2;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

patseq = {};

%Tomography gate sets

%4-Pulse Set (QId, Xp, X90p, Y90p)
gateSet = [1, 3, 2, 5];

%6-Pulse Set ('QId', 'Xp', 'X90p', 'Y90p', 'X90m', 'Y90m')
gateSet = [1, 3, 2, 5, 4, 7];

%12-Pulse Set 
gateSet = [1, 3, 6, 9, 21, 19, 23, 18, 17, 20, 24, 22];

pulseLib = cell(length(gateSet),1);
for ct = 1:length(gateSet)
    pulseLib{ct} = CliffPulse(gateSet(ct));
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
process = pg.pulse('X90p');

for prepct = 1:length(gateSet)
    for measct = 1:length(gateSet)
        patseq{end+1} = { pulseLib{prepct}, process, pulseLib{measct} };
    end
end
                

calseq = {};
calseq{end+1} = {pg.pulse('QId')};
calseq{end+1} = {pg.pulse('Xp')};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot, 31};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end

  function outPulse = CliffPulse(cliffNum)
        %Create a pulse from a clifford Number.  Cliffords are numbered with 1 based indexing:
        
        %Figure out the approximate nutation frequency calibration from the
        %X180 and the the samplingRate
        Xp = pg.pulse('Xp');
        xpulse = Xp(1,0);
        nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);
        
        defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', 0};
        
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
