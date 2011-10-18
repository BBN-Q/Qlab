function [rho] = Pauli2Chi_(paulicoef,pauliopts,n)
% Jay Gambetta, March 1st 2011
% 
% takes in a vector of coef and the opts and makes the state rho for n
% qubits
% Input 
%	paulicoef = a vector of dim 4^n containing the expectationd of the pauliopts
%	pauliopts = a cell of dim 4^n containing the pauliopts
%	n = number of qubits

d=2^n;
d2=4^n;

rho = zeros(d,d);
for j=1:d2 
 rho = rho + 1/(d)*paulicoef(j)*pauliopts{j};
end

end

