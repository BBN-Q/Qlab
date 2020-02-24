function fidvec = get_fidelity_GHZ(rho_in, parity)
%parity: 1=odd, 0=even
nqubits=log(size(rho_in,1))/log(2);
phi=0;
%rho_in = rho2; %eye(2^nqubits)/2^nqubits; %rhoP2;
if parity == 0
    rho_GHZ = [1 zeros(1,2^nqubits-2) exp(i*phi) ; zeros(2^nqubits-2,2^nqubits); exp(-i*phi) zeros(1,2^nqubits-2) 1]/2; %even
else
    rho_GHZ = [zeros((2^nqubits-2)/2, 2^nqubits); zeros(1,(2^nqubits-2)/2) 1 exp(-i*phi) zeros(1,(2^nqubits-2)/2); zeros(1,(2^nqubits-2)/2) exp(i*phi) 1 zeros(1,(2^nqubits-2)/2); zeros((2^nqubits-2)/2, 2^nqubits)]/2; %odd
end
phvec = linspace(0,2*pi,100);
fidvec = zeros(1,length(phvec));

for k=1:length(phvec)
    phi = phvec(k);
    if parity == 0
        rho_GHZ = [1 zeros(1,2^nqubits-2) exp(i*phi) ; zeros(2^nqubits-2, 2^nqubits); exp(-i*phi) zeros(1,2^nqubits-2) 1]/2;
    else
        rho_GHZ = [zeros((2^nqubits-2)/2, 2^nqubits); zeros(1,(2^nqubits-2)/2) 1 exp(-i*phi) zeros(1,(2^nqubits-2)/2); zeros(1,(2^nqubits-2)/2) exp(i*phi) 1 zeros(1,(2^nqubits-2)/2); zeros((2^nqubits-2)/2, 2^nqubits)]/2; %odd
    end
    fidvec(k) = rho2pauli(rho_GHZ)'*rho2pauli(rho_in)/2^nqubits;
end
end
