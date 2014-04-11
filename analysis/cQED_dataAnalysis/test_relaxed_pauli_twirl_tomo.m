function test_relaxed_pauli_twirl_tomo()

numTilts = 10;
for ct = 1:numTilts
    Utilts{ct} = qip.random.unitary(2);
end

X = [0, 1;1 0]; Y = [0 -1i;1i 0]; Z = [1 0;0 -1];

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

% construct choi matrix for X90
myop = kron(eye(2), expm(-1j*pi/4*X));
%myop = kron(eye(2), qip.random.unitary(2))
choi = 0.5*myop * [1, 0, 0, 1; 0, 0, 0, 0; 0, 0, 0, 0; 1, 0, 0, 1] * myop';

results = zeros(3, 3*numTilts);

for tiltct = 1:numTilts
    %Tilt the Paulis
    pauliTilts = cellfun(@(x) Utilts{tiltct}'*x*Utilts{tiltct}, {eye(2), X, Y, Z}, 'UniformOutput', false);

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
    results(:, 3*(tiltct-1)+1) = selector * SSrho2TiltedPauli * pauliSSOps * shuffleMat * choi(:);
    % preceded by relaxation
    results(:, 3*(tiltct-1)+2) = selector * SSrho2TiltedPauli * pauliSSOps * kron(relax.', eye(4)) * shuffleMat * choi(:);
    % followed by relaxation
    results(:, 3*(tiltct-1)+3) = selector * SSrho2TiltedPauli * pauliSSOps * kron(eye(4), relax) * shuffleMat * choi(:);
end

outchoi = relaxed_pauli_twirl_tomo(real(results), Utilts)

outpauli = Choi2PauliMap_(outchoi)

theorypauli = Choi2PauliMap_(choi)

end