function [chi] = Choi2Chi_(choi,pauliopts,n)
% Colm and Blake, Feb 15th 2012
% 
% takes in a vector of coef and the opts and makes the choi state for for n
% qubits
% Input 
%	choi = the choi matrix
%	pauliopts = a cell of dim 4^n containing the pauliopts
%	n = number of qubits
% Output
%   chi = the chi matrix
d=2^n;
d2 = 4^n;

%Get the Krauss operators from the eigen decomposition
[vecs, vals] = eig(choi);

chi = zeros(d2,d2);

%Transform from the Krauss basis to the Pauli basis
for k = 1:length(vals)
    KraussOp = reshape(vecs(:,k), d,d)*sqrt(d); % Krauss operator should have norm of d
    for ii = 1:d2
        pauliLeft = trace(pauliopts{ii}*KraussOp)/d;
        for jj = 1:d2
            pauliRight = trace(pauliopts{jj}*KraussOp')/d;
            chi(ii,jj) = chi(ii,jj) +  vals(k,k)*pauliLeft*pauliRight;
        end
    end
end



end

