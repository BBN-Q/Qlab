function [choiSDP, choiLSQ] = QPT_SDP(expResults, measOps, measMap, U_preps, U_meas, nbrQubits)
%QPT_SDP SDP constrained maximum liklihood quantum process tomography. 
% QPT_SDP finds the closest physical map that minimizes the error between the 
% predicted and measured results. Trace preservation is not contstrained. We work
% with the Choi representation of the superoperator because the CP condition is
% easy to enforce. It also return the direct unconstrained inversion result. 
%
% [choiSDP, choiLSQ] = QPT_SDP(expResults, measOps, measMap, U_preps, U_meas, nbrQubits)
%	expResults: matrix of experimental results (numPrep x numMeas)
%   measOps: measurement operators in real units e.g. measuring 1V for the ground state and 1.23V for the excited state gives [[1, 0],[0,1.23]] 
%   measMap: matrix mapping of each experiment to associated measurement operator
%   U_preps: cell array of the preparation unitaries 
%   U_meas: cell array of read-out unitaries 
%   nbrQubits: the number of qubits
% Returns
%	choiSDP = the constrained physical process Choi matrix
% 
% Authors: Colm Ryan and Blake Johnson 
% Inspired by code from Jay Gambetta and Seth Merkel.

%Clear yalmip (why?)
yalmip('clear')

%Some useful dimensions
d = 2^nbrQubits;
d2 = 4^nbrQubits;
d4 = 16^nbrQubits;
numMeas = length(U_preps);
numPrep = length(U_meas);

%Assume perfect preparation in the ground state
rhoIn = zeros(d,d);
rhoIn(1,1) = 1;

%Transform the initial state by the preparation pulse
rhoPreps = cell(numPrep,1);
for ct = 1:length(U_preps)
    rhoPreps{ct} = U_preps{ct}*rhoIn*U_preps{ct}';
end

%Transform the measurement operators by the measurement pulses
measurementoptsset = cell(numMeas,1);
for ct=1:length(measOps) 
    for measPulsect = 1:numMeas
        measurementoptsset{ct}{measPulsect}= U_meas{measPulsect}'*measOps{ct}*U_meas{measPulsect};
    end
end

% Set up the SDP problem with Yalmip
% First the Choi matrix in square form
choiSDP_yalmip = sdpvar(d2, d2, 'hermitian', 'complex');

% Now each measurement result corresponds to a linear combination of Choi
% matrix (S) elements: for a given rhoIn and measOp then measResult = Tr(S*kron(rhoIn.', measOp))
fprintf('Setting up predictor matrix....');
predictorMat = zeros(numPrep*numMeas, d4, 'double');
rowct = 1;
for prepct = 1:numPrep
    for measct = 1:numMeas
        % Have to multiply by d to match Jay's convention of dividing the
        % Choi matrix by d
        % We can use the usual trick that trace(A*B) = trace(B*A) = sum(tranpose(B).*A)
        % predictorMat(prepct, measct) = trace(choiSDP*kron(rhoPreps{prepct}.', measurementoptsset{measMap(prepct,measct)}{measct}))*d;
        tmpMat = transpose(kron(rhoPreps{prepct}.', measurementoptsset{measMap(measct,prepct)}{measct}));
        predictorMat(rowct, :) = d*tmpMat(:); 
        rowct = rowct+1;
    end
end

%We want to minimize the difference between predicted results and experimental results
optGoal = norm(predictorMat*choiSDP_yalmip(:) - expResults(:),2);
fprintf('Done!\n.')

% Constrain the Choi matrix to be positive semi-definite
constraint = choiSDP_yalmip >= 0;

% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
fprintf('SDP optimizing...')
solvesdp(constraint, optGoal, sdpsettings('verbose',false));
fprintf('Done\n')

% Extract the matrix values from the result
choiSDP = double(choiSDP_yalmip);

if (nargout == 2)
    choiLSQ = predictorMat\expResults(:);
end
