function [choiSDP, choiLSQ] = QPT_SDP_Var(expResults, invVarMat, measOps, measMap, U_preps, U_meas, nbrQubits)

%Clear yalmip (why?)
yalmip('clear')

%Some useful dimensions
d = 2^nbrQubits;
d2 = 4^nbrQubits;
d4 = 16^nbrQubits;
numPrep = length(U_preps);
numMeas = length(U_meas);

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
        predictorMat(rowct, :) = d*sqrt(invVarMat(measct, prepct))*tmpMat(:); 
        rowct = rowct+1;
    end
end

%We want to minimize the difference between predicted results and experimental results
optGoal = norm(predictorMat*choiSDP_yalmip(:) - sqrt(invVarMat(:)).*expResults(:),2);
fprintf('Done!\n.')

% Constrain the Choi matrix to be positive semi-definite and
% trace-preserving
ptrace = partialTraceOp(nbrQubits);
I = speye(d);
constraint = [choiSDP_yalmip >= 0 ptrace*choiSDP_yalmip(:) == 1/d*I(:)];

% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
fprintf('SDP optimizing...')
solvesdp(constraint, optGoal, sdpsettings('verbose',false));
fprintf('Done\n')

% Extract the matrix values from the result
choiSDP = double(choiSDP_yalmip);

choiLSQ = predictorMat\(sqrt(invVarMat(:)).*expResults(:));
% choiLSQ = pinv(predictorMat) * (sqrt(invVarMat(:)).*expResults(:));
choiLSQ = reshape(choiLSQ,d2,d2);
end
