function out = pauli_twirl_tomo(expResults, Utilts)
% Optimize Pauli Twirl Tomography
%Assume we measure decay rate of X,Y,Z input states for each experiment
%Take-in:
%  1. measured decay rates: expResults (3 X number of Frames)
%  2. Tranformation to each tilted Pauli frame: Utilts (cell array of matrices)
%      Utilt transforms original basis to tilted basis 

numTilts = length(Utilts);
assert(size(expResults,2) == numTilts)

%Plan:
% 1. Work from Choi matrix
% 2. Transformation chain: Choi -> Shuffle -> Liouville -> BasisChange ->
% Twirl map -> BasisChange -> Projector

% Default to quiet
if ~exist('verbose', 'var')
    verbose = 0;
end

%Choi matrix 
%choiSDP = sdpvar(4, 4, 'hermitian', 'complex');

pauliOps = cell(4,1);
pauliOps{1} = eye(2);
pauliOps{2} = [0, 1;1, 0];
pauliOps{3} = [0, -1i;1i, 0];
pauliOps{4} = [1, 0;0, -1];

%Shuffle matrix for Choi -> Liouville (cannonical column stack basis)
shuffleMat = zeros(16,16);
for ct1 = 1:2
    for ct2 = 1:2
        tmpMat = zeros(2,2);
        tmpMat(ct1,ct2) = 1;
        shuffleMat = shuffleMat + kron(kron(kron(eye(2), tmpMat.'), tmpMat), eye(2));
    end
end

%Normalization
shuffleMat = 2*shuffleMat;


%predictedResults = sdpvar(3, numTilts, 'full', 'real');
predictorMat = zeros(3*numTilts, 16);

for tiltct = 1:numTilts
    %Tilt the Paulis
    pauliTilts = cellfun(@(x) Utilts{tiltct}'*x*Utilts{tiltct}, pauliOps, 'UniformOutput', false);

    %Construct the Pauli super-super-operator twirl
    pauliSSOps = zeros(16,16);
    tiltedPauli2rho = zeros(4,4);
    for paulict = 1:4
        pauliSSOps = pauliSSOps + 1/4 * kron(kron(kron(pauliTilts{paulict}, conj(pauliTilts{paulict})), conj(pauliTilts{paulict})), pauliTilts{paulict});
        tiltedPauli2rho(:,paulict) = pauliTilts{paulict}(:);
    end
    
    % Construct the super-super rho2pauli operator
    SSrho2TiltedPauli = kron(transpose(tiltedPauli2rho), inv(tiltedPauli2rho));
    
    % selector matrix
    selector = zeros(3,16);
    selector(1,6) = 1;
    selector(2,11) = 1;
    selector(3,16) = 1;
    
    predictorMat(3*tiltct-2:3*tiltct,:) = selector * SSrho2TiltedPauli * pauliSSOps * shuffleMat;
    
end

% Constrain the Choi matrix to be positive definite
%constraint = choiSDP > 0;

% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
%solvesdp(constraint, norm(predictedResults(:) - expResults(:), 2), sdpsettings('verbose',verbose));

%out = double(choiSDP);
out = expResults(:) \ predictorMat;

    function cohVec = pauli_decompose(inputMat)
        cohVec = zeros(4,1);
        for ct = 1:4
            cohVec(ct) = trace(inputMat*pauliOps{ct})/2;
        end
    end
end