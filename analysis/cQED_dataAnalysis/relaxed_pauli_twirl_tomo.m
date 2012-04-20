function out = relaxed_pauli_twirl_tomo(expResults, Utilts)
% Optimize Pauli Twirl Tomography
%Assume we measure decay rate of X,Y,Z input states for each experiment
%Take-in:
%  1. measured decay rates: expResults (3 X number of Frames)
%  2. Tranformation to each tilted Pauli frame: Utilts (cell array of matrices)
%      Utilt transforms original basis to tilted basis 

numTilts = length(Utilts);
assert(size(expResults,2) == 3*numTilts)

%Plan:
% 1. Work from Choi matrix
% 2. Transformation chain: Choi -> Shuffle -> Liouville -> BasisChange ->
% Twirl map -> BasisChange -> Projector

% Default to quiet
if ~exist('verbose', 'var')
    verbose = 0;
end

%Choi matrix 
choiSDP = sdpvar(4, 4, 'hermitian', 'complex');

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

% relaxation operator
sigma_m = [0, 1; 0, 0];
tau = 0.1; % relaxation fraction of T1
relax = expm(tau*qip.open_systems.dissipator(sigma_m));


%predictedResults = sdpvar(3, numTilts, 'full', 'real');
predictorMat = zeros(9*numTilts, 16);

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

    % without relaxation
    predictorMat(9*(tiltct-1)+1:9*(tiltct-1)+3,:) = selector * SSrho2TiltedPauli * pauliSSOps * shuffleMat;
    % preceded by relaxation
    predictorMat(9*(tiltct-1)+4:9*(tiltct-1)+6,:) = selector * SSrho2TiltedPauli * pauliSSOps * kron(relax.', eye(4)) * shuffleMat;
    % followed by relaxation
    predictorMat(9*(tiltct-1)+7:9*(tiltct-1)+9,:) = selector * SSrho2TiltedPauli * pauliSSOps * kron(eye(4), relax) * shuffleMat;
end

fprintf('Rank of predictorMat is %d\n', rank(predictorMat));

% Constrain the Choi matrix to be positive definite
constraint = choiSDP > 0;

%Trace preservation condition: partial trace over input space gives
%identity
constraint = [constraint, choiSDP(1,1)+choiSDP(2,2)==0.5, choiSDP(1,3)+choiSDP(2,4)==0, choiSDP(3,1)+choiSDP(4,2)==0, choiSDP(3,3)+choiSDP(4,4)==0.5];



% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
solvesdp(constraint, norm(predictorMat*choiSDP(:) - expResults(:), 2), sdpsettings('verbose',verbose));

out = double(choiSDP);
% out = expResults(:) \ predictorMat;

end