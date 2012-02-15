function [pauliMap] = Choi2PauliMap_(choi,pauliopts,numberofqubits)
% Jay Gambetta, feb 28th 2011
% 
% takes a rho matrix and list the pauli components for n qubits
% Input 
%	numberofqubits = number of qubits
%   pauliopts = a cell containing the pauliopts
%   choi = the state in matrix form
% Return
%   raulicoef = a matrix containing the paulicoef
% 
%
% 
d2=4^numberofqubits;

for ii=1:d2
	for jj=1:d2 
 	pauliMap(jj,ii)= trace(choi*kron(pauliopts{ii}.',pauliopts{jj})); 
	end
end

