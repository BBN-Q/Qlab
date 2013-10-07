function choiLSQ = QPT_LSQ(expResults, invVarMat, measOps, measMap, U_preps, U_meas, nbrQubits)

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

%Remove the identity component from measurements and data
for ct=1:length(measOps)
    m = trace(measOps{ct})/d;
    measOps{ct} = measOps{ct} - m*eye(size(measOps{ct}));
    % the next line only works for the particular case where measurements
    % are constant along columns of expResults. In general, need to lookup
    % in measMap all indices where measMap == ct
    expResults(:,ct) = expResults(:,ct) - m;
end

%Transform the measurement operators by the measurement pulses
measurementoptsset = cell(numMeas,1);
for ct=1:length(measOps) 
    for measPulsect = 1:numMeas
        measurementoptsset{ct}{measPulsect}= U_meas{measPulsect}'*measOps{ct}*U_meas{measPulsect};
    end
end

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

% choiLSQ = predictorMat\(sqrt(invVarMat(:)).*expResults(:));
% choiLSQ = pinv(predictorMat) * (sqrt(invVarMat(:)).*expResults(:));
choiLSQ = factorize(predictorMat) \ (sqrt(invVarMat(:)).*expResults(:));
choiLSQ = reshape(choiLSQ,d2,d2);
% fix (1,1) component in Pauli representation by making sure choi has trace == 1
choiLSQ = choiLSQ + (1-trace(choiLSQ))/d2*eye(d2);
end
