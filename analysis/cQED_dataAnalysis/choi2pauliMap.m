function pauliMap = choi2pauliMap(choi)
%choi2pauliMap Converts a Choi representation to a Pauli Map representation.

%Dimension of superoperator
d2=size(choi,1);

%Create the Pauli opearators for n qubits
pauliOps = paulis(log2(sqrt(d2)));

pauliMap = zeros(d2,d2);
for ct1=1:d2
	for ct2=1:d2 
    	pauliMap(ct2,ct1)= real(trace(choi*kron(pauliOps{ct1}.',pauliOps{ct2}))); 
	end
end

