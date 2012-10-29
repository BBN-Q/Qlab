function [pauliOps, pauliStrs ] = paulis(numQubits)
%paulis Returns the pauli product operators and corresponding strings. 
% 
% [pauliOps, pauliStrs ] = paulis(numQubits)


%Basic Pauli operators
X = [0, 1;  1,0];
Y = [0,-1i;1i,0];
Z = [1, 0;  0,-1];
I = eye(2);

%Start with the single qubit
pauliOps1Q = cell(4,1);
pauliOps1Q{1} = I;
pauliOps1Q{2} = X;
pauliOps1Q{3} = Y;
pauliOps1Q{4} = Z;

pauliStrs1Q = {'I','X','Y','Z'};

%Create matrix where each row gives which terms are to be tensored together
numPaulis = 4^numQubits;
kronMat = zeros([numPaulis, numQubits], 'uint8');
for qubitct = 1:numQubits
    kronMat(:,qubitct) = reshape(repmat(1:4, 4^(numQubits-qubitct), 4^(qubitct-1)), numPaulis, 1);
end

pauliOps = cell(4^numQubits, 1);
pauliStrs = cell(4^numQubits, 1);

for paulict = 1:numPaulis
    pauliOps{paulict} = 1;
    pauliStrs{paulict} = '';
    for qubitct = 1:numQubits
        pauliOps{paulict} = kron(pauliOps{paulict}, pauliOps1Q{kronMat(paulict, qubitct)});
        pauliStrs{paulict} = [pauliStrs{paulict} pauliStrs1Q{kronMat(paulict, qubitct)}];
    end
end



