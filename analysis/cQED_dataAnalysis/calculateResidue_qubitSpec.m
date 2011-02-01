function residue = calculateResidue_qubitSpec(params,Phi,Frequency,SimParameters,Constants,transition)

fitParameters.Ic        = params(1);
fitParameters.Cq        = params(2);
fitParameters.alpha     = params(3);
fitParameters.CsdCj     = params(4); %ratio of C_shunt to C_josephson, dimensionless

if ~iscell(Phi)
    Phi = {Phi};
end

%% Parameters

Ic              = fitParameters.Ic;
Cq              = fitParameters.Cq;
alpha           = fitParameters.alpha;
CsdCj           = fitParameters.CsdCj; %ratio of C_shunt to C_josephson, dimensionless

phi_min         = SimParameters.phi_min; % min value for qubit potential
phi_max         = SimParameters.phi_max; % max "
LatticePoints   = SimParameters.LatticePoints;
% Phi_min         = min(Phi); %in units of Phi0
% Phi_max         = max(Phi); %in units of Phi0
numQubitLevels  = SimParameters.numQubitLevels;

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

numTransitions = numel(transition);
simFrequency = cell(1,numTransitions);
residue = 0;
for transition_i = 1:numTransitions

    Phi_vector  = Phi0*Phi{transition_i};
    numPhiSteps = numel(Phi_vector);

    H_diag    = @(Phi) diag(U_qubit(Phi)+2*LatticeCoupling);
    H_offdiag = LatticeCoupling*(diag((ones(1,LatticePoints-1)),1)+diag((ones(1,LatticePoints-1)),-1));

    qubitEnergies = zeros(numQubitLevels-1,numPhiSteps);

    for Phi_i = 1:numPhiSteps

        H_qubit =  H_diag(Phi_vector(Phi_i)) + H_offdiag;
        temp = sort(eig(H_qubit));
        qubitEnergies(:,Phi_i) = diff(temp(1:numQubitLevels));

    end

    switch transition{transition_i}
        case '01'
            simFrequency{transition_i} = qubitEnergies(1,:)/2/pi/hbar*1e-9;
        case '02'
            simFrequency{transition_i} = sum(qubitEnergies(1:2,:)/2)/2/pi/hbar*1e-9;
        case '12'
            simFrequency{transition_i} = qubitEnergies(2,:)/2/pi/hbar*1e-9;
        otherwise
            error('unrecognized value for ''transtion''')
    end

    numPoints = numel(Phi{transition_i});
    residue = sum((Frequency{transition_i}-simFrequency{transition_i}).^2)/numPoints + residue;
end

end