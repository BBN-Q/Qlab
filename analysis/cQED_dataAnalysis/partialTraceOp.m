function A = partialTraceOp(nbrQubits)
% return the superoperator that performs the partial trace over the second
% subsystem on Choi matrix for nbrQubits

d = 2^nbrQubits;
A = sparse(d^2, d^4);
I = speye(d);
for kk = 1:d
    A = A + qip.tensor(I, sparse(1,kk,1,1,d), I, sparse(1,kk,1,1,d));
end

end