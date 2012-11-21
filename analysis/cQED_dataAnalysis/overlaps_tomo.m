function out = overlaps_tomo(expResults)
% Extract a Pauli map from a set of interleaved RB overlap experiments
%Take-in:
%  1. measured process fidelities for each overlap: expResults

%Plan:
% 1. Work from Choi matrix
% 2. Transformation chain: Choi -> Shuffle -> Liouville
% 3. Form inner product of overlap Unitary super-super operator with
% Liouville

% Default to quiet
if ~exist('verbose', 'var')
    verbose = 0;
end

d = 2; % dimension

%Transform expResults fidelities back to trace overlaps assuming positive
%global phase
expResults = (d^2-1)*expResults+1;

%Choi matrix 
choiSDP = sdpvar(4, 4, 'hermitian', 'complex');

% the linearly independent set of cliffords we are comparing against
li_cliffords = [1 2 4 6 7 8 9 11 14];

%Shuffle matrix for Choi -> Liouville (cannonical column stack basis)
shuffleMat = zeros(d^4,d^4);
for ct1 = 1:2
    for ct2 = 1:2
        tmpMat = zeros(d,d);
        tmpMat(ct1,ct2) = 1;
        shuffleMat = shuffleMat + kron(kron(kron(eye(d), tmpMat.'), tmpMat), eye(d));
    end
end

%Normalization
shuffleMat = 2*shuffleMat;

%Construct the unitary super-super-operator
UnitarySSOp = zeros(length(li_cliffords),d^4);
for ct = 1:length(li_cliffords)
    UnitarySOp = kron(conj(local_clifford(li_cliffords(ct))), local_clifford(li_cliffords(ct)));
    UnitarySSOp(ct,:) = conj(UnitarySOp(:));
end

predictorMat = UnitarySSOp * shuffleMat;

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

choiPseudoInv = pinv(predictorMat)*expResults(:);

pauliMapPseudoInv = choi2pauliMap(reshape(choiPseudoInv,4,4));
[~, pauliStrs] = paulis(1);
cmap = [hot(50); 1-hot(50)];
cmap = cmap(18:18+63,:); % make a 64-entry colormap
figure()
imagesc(pauliMapPseudoInv,[-1,1])
colormap(cmap)
colorbar()
set(gca, 'XTick', 1:4);
set(gca, 'XTickLabel', pauliStrs);
set(gca, 'YTick', 1:4);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');


% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
sym = solvesdp(constraint, norm(predictorMat*choiSDP(:) - expResults(:), 2), sdpsettings('verbose',verbose));

% then out of the set of maximum likelihood solutions, find the solution
% that minimizes the purity
ll = norm(predictorMat*double(choiSDP(:)) - expResults(:), 2);
% constraint = [ constraint, norm(predictorMat*choiSDP(:) - expResults(:), 2) == ll ];

% solvesdp(constraint, norm(choiSDP(:),2), sdpsettings('verbose',verbose));

out = double(choiSDP);

% plot the result

pauliMap = choi2pauliMap(double(choiSDP));
[~, pauliStrs] = paulis(1);
cmap = [hot(50); 1-hot(50)];
cmap = cmap(18:18+63,:); % make a 64-entry colormap
figure()
imagesc(pauliMap,[-1,1])
colormap(cmap)
colorbar()
set(gca, 'XTick', 1:4);
set(gca, 'XTickLabel', pauliStrs);
set(gca, 'YTick', 1:4);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');

end
