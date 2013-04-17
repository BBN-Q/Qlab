function rhoSDP = QST_SDP(expResults, measPulseMap, measOpMap, measPulseUs, measOps, n)

%Function to perform constrained SDP optimization of a physical density matrix
%consitent with the data.
%
% expResults : structure array (length total number of experiments)
%   each structure containts fields data, measPulse, measOperator
% measPulses : cell array of unitaries of measurment pulses
% measOps : cell array of measurment operators
% n : number of qubits

%Construct the predictor matrix.  Each row is an experiment.  The number of
%columns is 4^n for the size of the vectorized density matrix.
%First transform the measurement operators by the readout pulses to create
%the effective measurement operators and then flatten into row of the
%predictor matrix
fprintf('Setting up predictor matrix....');
predictorMat = zeros(length(expResults), 4^n);
for expct = 1:length(expResults)
    tmp = conj(measPulseUs{measPulseMap(expct)}'*measOps{measOpMap(expct)}*measPulseUs{measPulseMap(expct)});
    predictorMat(expct,:) = tmp(:);
end
fprintf('Done!\n.')

fprintf('SDP optimizing...')

%Setup the SDP program
yalmip('clear');
rhoSDP = sdpvar(2^n, 2^n, 'hermitian', 'complex');

% Constrain the density matrix to be positive semi-definite, trace 1
constraint = [rhoSDP >= 0, trace(rhoSDP)==1];

%We want to minimize the difference between predicted results and experimental results
optGoal = norm(predictorMat*rhoSDP(:) - expResults,2);
solvesdp(constraint, optGoal, sdpsettings('verbose',false));
fprintf('Done\n')

% Extract the matrix values from the result
rhoSDP = double(rhoSDP);

if (nargout == 2)
    rhoLSQ = predictorMat\expResults;
    rhoLSQ = reshape(rhoLSQ,4,4);
end





