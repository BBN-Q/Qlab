function rhoSDP2 = SDP_state_tomography(data, n)

%Function to perform constrained SDP optimization of the density matrix
%that fits the measured data. It is assumed that the first 2^n points are
%the computational basis state calibration points.

%First construct the measurement operator
measOp = diag(data(1:2^n));

X = [0, 1;1 0]; Y = [0 -1i;1i 0]; Z = [1 0;0 -1];
singleQubitPulses = cell(4,1);
singleQubitPulses{1} = eye(2);
singleQubitPulses{2} = X;
singleQubitPulses{3} = expm(-1i*pi/4*X);
singleQubitPulses{4} = expm(-1i*pi/4*Y);

%Create the readout pulses
numSQPulses = length(singleQubitPulses);
numReadoutPulses = numSQPulses^n;
readoutPulses = cell(numReadoutPulses,1);
for ct = 0:numReadoutPulses
    tmpStr = dec2base(ct,numSQPulses,n);
    readoutPulses{ct+1} = 1;
    for ct2 = 1:n
        readoutPulses{ct+1} = kron(readoutPulses{ct+1}, singleQubitPulses{str2num(tmpStr(ct2))+1});
    end
end

%Create the effective measurement operators
measOps = cell(numReadoutPulses,1);
for ct = 1:numReadoutPulses
    measOps{ct} = readoutPulses{ct}'*measOp*readoutPulses{ct};
end

%Setup the SDP program
yalmip('clear');
rhoSDP = sdpvar(2^n, 2^n, 'hermitian', 'complex');
predictedMeasMat = sdpvar(numReadoutPulses, 1, 'full', 'real');

for ct = 1:numReadoutPulses
    predictedMeasMat(ct) = real(trace(rhoSDP*measOps{ct}));
end

% Constrain the Choi matrix to be positive semi-definite
constraint = rhoSDP >= 0;

% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
solvesdp(constraint, norm(predictedMeasMat - data(2^n+1:end), 2), sdpsettings('verbose',0));

% Extract the matrix values from the result
rhoSDP2 = double(rhoSDP);





