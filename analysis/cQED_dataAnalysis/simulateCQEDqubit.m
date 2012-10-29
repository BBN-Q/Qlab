function output = simulateCQEDqubit(fitParameters,SimParameters,Constants)

%% Parameters

Ic              = fitParameters.Ic;
Cq              = fitParameters.Cq;
alpha           = fitParameters.alpha;
CsdCj           = fitParameters.CsdCj; %ratio of C_shunt to C_josephson, dimensionless
g               = fitParameters.g;
f_r             = fitParameters.f_r;

phi_min         = SimParameters.phi_min; % min value for qubit potential
phi_max         = SimParameters.phi_max; % max "
LatticePoints   = SimParameters.LatticePoints;
Phi_min         = SimParameters.Phi_min; %in units of Phi0
Phi_max         = SimParameters.Phi_max; %in units of Phi0
numPhiSteps     = SimParameters.numPhiSteps;
numQubitLevels  = SimParameters.numQubitLevels;
maxPhotonNumber = SimParameters.maxPhotonNumber;

hbar            = Constants.hbar; % J*s
Phi0            = Constants.Phi0; % Wb

%% derived parameters

beta    = alpha+CsdCj;
Ej      = Phi0/2/pi*Ic; 
meff    = (Phi0/2/pi)^2*(1+2*beta)/2*Cq;

%% Solve the potentail

phi_vector = linspace(phi_min,phi_max,LatticePoints);
U_qubit = @(Phi) Ej*(-2*cos(phi_vector/2)-alpha*cos(2*pi*Phi/Phi0-phi_vector));
phi_step = abs(phi_max-phi_min)/(LatticePoints-1);
LatticeCoupling = hbar^2/2/meff/phi_step^2;

Phi_vector = Phi0*linspace(Phi_min,Phi_max,numPhiSteps);

H_diag    = @(Phi) diag(U_qubit(Phi)+2*LatticeCoupling);
H_offdiag = LatticeCoupling*(diag((ones(1,LatticePoints-1)),1)+diag((ones(1,LatticePoints-1)),-1));

qubitEnergies = zeros(numQubitLevels-1,numPhiSteps);

for Phi_i = 1:numPhiSteps

    H_qubit =  H_diag(Phi_vector(Phi_i)) + H_offdiag;
    temp = sort(eig(H_qubit));
    qubitEnergies(:,Phi_i) = diff(temp(1:numQubitLevels));

end

% qubitEnergies_interp = cell(1,numQubitLevels);
% for qubit_level = 1:numQubitLevels
%     qubitEnergies_interp{qubit_level} = @(Phi) interp1(Phi_vector,qubitEnergies(qubit_level,:),Phi);
% end

qubitEnergies_interp = @(Phi) qubitEnergies_interp_fun(Phi,Phi_vector,qubitEnergies,numQubitLevels);

%% JC Hamiltonian

% as a convention, the cavity operators will always come first in the
% kronecker product

IdAtom   = eye(numQubitLevels);
IdCavity = eye(maxPhotonNumber+1);

sigma_p_atom = zeros(numQubitLevels);
sigma_m_atom = zeros(numQubitLevels);
for qubit_level = 1:numQubitLevels
    % for now we approximate that the dipole moments between atomic states
    % scale as in a harmonic oscillator
    sigma_p_atom = sqrt(qubit_level)*diag(ones(1,numQubitLevels-qubit_level), qubit_level)...
        + sigma_p_atom;
    sigma_m_atom = sqrt(qubit_level)*diag(ones(1,numQubitLevels-qubit_level),-qubit_level)...
        + sigma_m_atom;

end

sigma_p = kron(IdCavity,diag(ones(1,numQubitLevels-1), 1));
sigma_m = kron(IdCavity,diag(ones(1,numQubitLevels-1),-1));
% sigma_p = kron(IdCavity,sigma_p_atom);
% sigma_m = kron(IdCavity,sigma_m_atom);

a    = kron(diag(sqrt(1:maxPhotonNumber), 1),IdAtom);
adag = kron(diag(sqrt(1:maxPhotonNumber),-1),IdAtom);

H_atom = @(Phi) kron(IdCavity,diag(sort(cumsum([0;qubitEnergies_interp(Phi)]),'descend')));

H_cavity = hbar*2*pi*f_r*adag*a;

H_coupling = hbar*2*pi*g*(a*sigma_p + adag*sigma_m);

H_JC = @(Phi) H_atom(Phi) + H_cavity + H_coupling;

%% Find eigenvalues of H_JC

JCFrequencies = zeros(numQubitLevels*(maxPhotonNumber+1),numPhiSteps);

for Phi_i = 1:numPhiSteps

    JCFrequencies(:,Phi_i) = sort(eig(H_JC(Phi_vector(Phi_i))))/2/pi/hbar;

end

JCFrequencies = JCFrequencies(2:end,:); % the first level is always zero energy, no point in carrying it along

%% Assign output

output.Phi_vector               = Phi_vector;
output.JCFrequencies            = JCFrequencies;
output.H_JC                     = H_JC;
output.qubitEnergies_interp     = qubitEnergies_interp;

end

function qubitEnergies_interp = qubitEnergies_interp_fun(Phi,Phi_vector,qubitEnergies,numQubitLevels)

qubitEnergies_interp = zeros(numQubitLevels-1,numel(Phi));

for qubit_level = 1:numQubitLevels-1
    
    qubitEnergies_interp(qubit_level,:) = interp1(Phi_vector,qubitEnergies(qubit_level,:),Phi);
    
end
        
end
