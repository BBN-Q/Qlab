function out = overlaps_tomo(expResults)
% Extract a Pauli map from a set of interleaved RB overlap experiments
%Take-in:
%  1. measured process fidelities for each overlap: expResults (12 overlaps)

%Plan:
% 1. Work from Choi matrix
% 2. Transformation chain: Choi -> Shuffle -> Liouville
% 3. Form inner product of overlap Unitary super-super operator with
% Liouville

numOverlaps = 10;
assert(length(expResults) == numOverlaps, 'Input does not have numOverlaps entries');

% Default to quiet
if ~exist('verbose', 'var')
    verbose = 0;
end

%Choi matrix 
choiSDP = sdpvar(4, 4, 'hermitian', 'complex');

% Paulis
X = [0, 1;1, 0];
Y = [0, -1i;1i, 0];
Z = [1, 0;0, -1];

% overlap unitaries
Uoverlaps = cell(numOverlaps,1);
Uoverlaps{1} = eye(2);
Uoverlaps{2} = expm(-1i*pi/4*X);
Uoverlaps{3} = expm(-1i*pi/2*X);
Uoverlaps{4} = expm(-1i*pi/4*Y);
Uoverlaps{5} = expm(-1i*pi/2*Y);
Uoverlaps{6} = expm(-1i*pi/4*Z);
Uoverlaps{7} = expm(-1i*pi/2*Z);
Uoverlaps{8} = expm(-1i*pi/2*(X+Y)/sqrt(2));
Uoverlaps{9} = expm(-1i*pi/2*(X+Z)/sqrt(2));
Uoverlaps{10} = expm(-1i*pi/2*(Y+Z)/sqrt(2));

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

predictorMat = zeros(numOverlaps, 16);

%Construct the unitary super-super-operator
UnitarySSOp = zeros(numOverlaps,16);
for ct = 1:numOverlaps
    UnitarySOp = kron(conj(Uoverlaps{ct}), Uoverlaps{ct});
    UnitarySSOp(ct,:) = conj(UnitarySOp(:));
end

d = 2;
predictorMat = 1/d^2 * UnitarySSOp * shuffleMat;

fprintf('Rank of predictorMat is %d\n', rank(predictorMat));

% Constrain the Choi matrix to be positive definite
constraint = choiSDP > 0;

%Trace preservation condition: partial trace over input space gives
%identity
constraint = [constraint, ...
              choiSDP(1,1)+choiSDP(2,2)==0.5, ...
              choiSDP(1,3)+choiSDP(2,4)==0, ...
              choiSDP(3,1)+choiSDP(4,2)==0, ...
              choiSDP(3,3)+choiSDP(4,4)==0.5];

pinv(predictorMat)*expResults

% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
sym = solvesdp(constraint, norm(predictorMat*choiSDP(:) - expResults(:), 2), sdpsettings('verbose',verbose));

ll = norm(predictorMat*double(choiSDP(:)) - expResults(:), 2);

constraint = [ constraint, norm(predictorMat*choiSDP(:) - expResults(:), 2) == ll ];

solvesdp(constraint, 1-norm(choiSDP(:),2), sdpsettings('verbose',verbose));

out = double(choiSDP);

end
