function [choi] = PauliMap2Choi_(raulicoef,pauliopts,n)
% Jay Gambetta, March 1st 2011
% 
% takes in a vector of coef and the opts and makes the choi state for for n
% qubits
% Input 
%	raulicoef = a matrix of dim 4^nx4^n containing the expectationd of the pauliopts
%	pauliopts = a cell of dim 4^n containing the pauliopts
%	n = number of qubits
% Output
%   choi = the choi matrix
d=2^n;
d2=4^n;


choi = zeros(d2,d2);
for ii=1:d2
	for jj=1:d2 
 	choi = choi + 1/(d2)*raulicoef(jj,ii)*kron(pauliopts{ii}.',pauliopts{jj});
	end
end

end

