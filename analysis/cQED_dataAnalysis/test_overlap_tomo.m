function out = test_overlap_tomo

% Paulis
X = [0, 1;1, 0];
Y = [0, -1i;1i, 0];
Z = [1, 0;0, -1];

% overlap unitaries
numOverlaps = 10;
d = 2;
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
    UnitarySSOp(ct,:) = UnitarySOp(:);
end

% construct the theoretical choi map for an X90 gate
pauliMaptheory = [1,0,0,0;0,1,0,0;0,0,0,1;0,0,-1,0];
choitheory = PauliMap2Choi_(pauliMaptheory,{eye(2), X, Y, Z},1);

cmap = [hot(50); 1-hot(50)];
cmap = cmap(18:18+63,:); % make a 64-entry colormap
figure()
imagesc(real(pauliMaptheory'),[-1,1])
colormap(cmap)
colorbar()
set(gca, 'XTick', 1:4);
set(gca, 'XTickLabel', {'I','X','Y','Z'});
set(gca, 'YTick', 1:4);
set(gca, 'YTickLabel', {'I','X','Y','Z'});
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');

out = real(1/d^2 * UnitarySSOp * shuffleMat * choitheory(:));

end