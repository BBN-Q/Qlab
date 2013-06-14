function rhoLSQ = QST_LSQ(expResults, varMat, measPulseMap, measOpMap, measPulseUs, measOps, n)

%Function to perform least-squares inversion of state tomography data
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
    tmp = transpose(measPulseUs{measPulseMap(expct)}'*measOps{measOpMap(expct)}*measPulseUs{measPulseMap(expct)});
    predictorMat(expct,:) = tmp(:);
end
fprintf('Done!\n')

invVarMat = inverse(varMat);

rhoLSQ = (predictorMat'*invVarMat*predictorMat) \ predictorMat'*invVarMat*expResults;

rhoLSQ = reshape(rhoLSQ, 2^n, 2^n);
