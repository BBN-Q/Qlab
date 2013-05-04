function PauliTwirl(varargin)
%Single qubit randomized benchmarking with Atomic Cliffords

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

basename = 'RB';
fixedPt = 19000; %15000
cycleLength = 29000; %19000
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

%Figure out the approximate nutation frequency calibration from the
%X180 and the the samplingRate
Xp = pg.pulse('Xp');
xpulse = Xp(1,0);
nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);


% load in random Pauli sequences from text file
FID = fopen('PauliTwirl_ISeqs.txt');
if ~FID
    error('Could not open Clifford sequence list')
end

%Read in each line
tmpArray = textscan(FID, '%s','delimiter','\n');
fclose(FID);
%Split each line
seqStrings = cellfun(@(x) textscan(x,'%d','delimiter',','), tmpArray{1});

%Pull out the target gate
targetGate = pg.pulse('QId');

%Create the pulse library in a potentially tilted frame

%Define the frame tilt as a quaternion style vector axis and rotation angle.
PauliLibrary = cell(1,4);

%QId
PauliLibrary{1} = pg.pulse('QId');

rotAngle = pi/8;
rotVec = sin(rotAngle/2)*[0,1,0];

%Euler-Rodgrigues formula
tilter = @(x) x + 2*cos(rotAngle/2)*cross(rotVec,x) + 2*cross(rotVec,cross(rotVec,x));

%Tilted Z
origZ = [0,0,1];
tiltedZ = tilter(origZ);
defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', 0};
PauliLibrary{4} =  pg.pulse('Up', 'polarAngle', acos(tiltedZ(3)), 'aziAngle', atan2(tiltedZ(2), tiltedZ(1)), defaultParams{:});

%Tilted X
origX = [1,0,0];
tiltedX = tilter(origX);
PauliLibrary{2} =  pg.pulse('Up', 'polarAngle', acos(tiltedX(3)), 'aziAngle', atan2(tiltedX(2), tiltedX(1)), defaultParams{:});

%Tilted Y
origY = [0,1,0];
tiltedY = tilter(origY);
PauliLibrary{3} =  pg.pulse('Up', 'polarAngle', acos(tiltedY(3)), 'aziAngle', atan2(tiltedY(2), tiltedY(1)), defaultParams{:});

%Convert sequence strings into pulses
patSeqs = cell(1,length(seqStrings));
for seqct = 1:length(seqStrings)
    currentSeq = cell(1,2*length(seqStrings{seqct})-1);
    %Follow each Pauli with the gate of interest
    for pulsect = 1:length(seqStrings{seqct})-1
        currentSeq{2*pulsect-1} = PauliLibrary{seqStrings{seqct}(pulsect)};
        currentSeq{2*pulsect} = targetGate;
    end
    currentSeq{end} = PauliLibrary{seqStrings{seqct}(end)};
    %Z input state
     patSeqs{seqct} = currentSeq;
    %X input state
%     patSeqs{seqct} = [PauliLibrary(5), currentSeq, PauliLibrary(7)];
    %Y input state
%    patSeqs{seqct} = [PauliLibrary(4), currentSeq, PauliLibrary(2)];

end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patSeqs, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot, 43};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end

 
end

