function [pauliMap] = Choi2PauliMap_(choi)
% Jay Gambetta, feb 28th 2011
% Patched by Colm and Blake
% 
% Input 
%	numberofqubits = number of qubits
%   pauliopts = a cell containing the pauliopts
%   choi = the state in matrix form
% Return
%   raulicoef = a matrix containing the paulicoef
% 
%
% 

d2=size(choi,1);

%Create the pauli operators
tmpStruct = PauliOperators_(log2(sqrt(d2)));
pauliOps = tmpStruct.opt;

pauliMap = zeros(d2,d2);
for ii=1:d2
	for jj=1:d2 
 	pauliMap(jj,ii)= real(trace(choi*kron(pauliOps{ii}.',pauliOps{jj}))); 
	end
end

