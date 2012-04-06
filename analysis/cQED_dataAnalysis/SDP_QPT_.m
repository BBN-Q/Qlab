function [chitheory, chicorrected, pauliMapTheory, pauliMapMLE, choi_SDP] = SDP_QPT_(measmat,measurementoperators, pauliopts, U_preps, U_meas, Gate, nbrQubits)
%  This programs uses semidefinite programming to work out the QPT
% Input 
%   rhoRaw = a cell of raw rhos
%   pauliopts = a cell of the pauliopts
%   nbrAnalysisPulses = the number of pre rotations   
%   Gate = a string representing the gate
%   Corrections = to apply single qubit corrections or not
%   plot = 


sm = destroy_(2);
sp = sm';
sx = sp+sm;
sy = +1i*sp-1i*sm;
sz = sparse([1 0;0 -1]);
si = speye(2);

% construct Uideal
switch Gate
    case 'CNOT12'
        Uideal =  expm(-1i*kron(sz,si)*pi/4)*expm(-1i*pi*kron(si,sx)/4)*expm(+1i*pi*kron(sz,sx)/4);
    case '1QId'
        Uideal = speye(2);
    case '1QX90p'
        Uideal = expm(-1i*pi*sx/4);
    case '1QX90m'
        Uideal = expm(1i*pi*sx/4);
    case '1QY90p'
        Uideal = expm(-1i*pi*sy/4);
    case '1QY90m'
        Uideal = expm(1i*pi*sy/4);
    case '1QXp'
        Uideal = expm(-1i*pi*sx/2);
    case '1QYp'
        Uideal = expm(-1i*pi*sy/2);
    case '1QX45p'
        Uideal = expm(-1i*pi*sx/8);
    case '1QX22p'
        Uideal = expm(-1i*pi*sx/16);
    case '1QHad'
        Uideal = expm(-1i*(pi/2)*(1/sqrt(2))*(sx+sz));
    case 'Id'
        Uideal = speye(4);
    case 'XI'
        Uideal = expm(-1i*kron(sx,si)*pi/2);
    case 'IX'
        Uideal = expm(-1i*kron(si,sx)*pi/2);
    case 'YI'
        Uideal = expm(-1i*kron(sy,si)*pi/2);
    case 'IY'
        Uideal = expm(-1i*kron(si,sy)*pi/2);
    case 'X_2I'
        Uideal = expm(-1i*kron(sx,si)*pi/4);
    case 'IX_2'
        Uideal = expm(-1i*kron(si,sx)*pi/4);
    case 'Y_2I'
        Uideal = expm(-1i*kron(sy,si)*pi/4);
    case 'IY_2'
        Uideal = expm(-1i*kron(si,sy)*pi/4);
    case 'X_8I'
        Uideal = expm(-1i*kron(sx,si)*pi/16);
    case 'X_4I'
        Uideal = expm(-1i*kron(sx,si)*pi/8);
    case 'IX_8'
        Uideal = expm(-1i*kron(si,sx)*pi/16);
    case 'IX_4'
        Uideal = expm(-1i*kron(si,sx)*pi/8);
    otherwise
        error('Unrecognized gate');
end

%choi_SDP = SDPTomoMeasMat_(measmat, measurementoperators, U_preps, U_meas, pauliopts, nbrQubits);
choi_SDP = SimpleSDPTomoMeasMat_(measmat, measurementoperators, U_preps, U_meas, nbrQubits);
choi_th  = Unitary2Choi_(Uideal, nbrQubits);

% Without ML
choi_correct = choi_SDP; % no correction
chicorrected = Choi2Chi_(choi_correct, pauliopts, nbrQubits);
chitheory = Choi2Chi_(choi_th, pauliopts, nbrQubits);

pauliMapMLE = Choi2PauliMap_(choi_correct, pauliopts, nbrQubits);
pauliMapTheory = Choi2PauliMap_(choi_th, pauliopts, nbrQubits);

end