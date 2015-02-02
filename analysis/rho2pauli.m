function pauliVec = rho2pauli(rho)
%converts a density matrix to a Pauli set (aka vector of coherences)

nbrQubits = log2(size(rho,1));

[pauliOps, ~] = paulis(nbrQubits);
pauliVec = ones(length(pauliOps),1);
for ii = 1:length(pauliOps)
    pauliVec(ii) = real(trace(rho*pauliOps{ii}));
end

end
